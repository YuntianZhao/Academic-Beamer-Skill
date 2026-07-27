#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE="$ROOT_DIR/academic-beamer"
SKILL="$PACKAGE/SKILL.md"
MIT_LICENSE="$PACKAGE/LICENSE"
VERIFY="$PACKAGE/scripts/verify-deck.sh"
STARTER="$PACKAGE/assets/template/presentation.tex"
TEST_WORKFLOW="$ROOT_DIR/.github/workflows/test.yml"
SYNC_WORKFLOW="$ROOT_DIR/.github/workflows/sync-template.yml"
RUN_ALL="$ROOT_DIR/tests/run_all.sh"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

rg --fixed-strings --quiet 'must not be replaced by another Beamer theme' "$SKILL" || fail 'theme rejection is missing'
rg --fixed-strings --quiet '`LICENSE`' "$SKILL" || fail 'SKILL.md does not reference the package MIT license'
rg --fixed-strings --quiet '`assets/template/LICENSE.txt`' "$SKILL" || fail 'SKILL.md does not reference the vendored LPPL license'
rg --multiline --quiet 'Do not draft the complete deck\s+until the user approves' "$SKILL" || fail 'outline approval gate is missing'
rg --fixed-strings --quiet 'latexmk -lualatex -norc' "$SKILL" || fail 'SKILL.md lacks RC-isolated latexmk -lualatex'
rg --fixed-strings --quiet 'latexmk -lualatex -norc' "$VERIFY" || fail 'verify-deck.sh lacks RC-isolated latexmk -lualatex'
rg --fixed-strings --quiet 'command -v lualatex' "$VERIFY" || fail 'verify-deck.sh does not require lualatex'
rg --fixed-strings --quiet "grep -Eq '^This is Lua(HB)?TeX([, ]|$)'" "$VERIFY" || fail 'verify-deck.sh does not validate LuaTeX or LuaHBTeX logs'
[ -f "$TEST_WORKFLOW" ] || fail 'test.yml is missing'
for workflow in "$TEST_WORKFLOW" "$SYNC_WORKFLOW"; do
  rg --fixed-strings --quiet 'texlive-luatex' "$workflow" || fail "$workflow does not install LuaLaTeX"
  rg --fixed-strings --line-regexp --quiet '        run: python3 -m pip install skills-ref==0.1.1' "$workflow" || fail "$workflow does not pin skills-ref==0.1.1"
done
rg --fixed-strings --quiet 'bash tests/run_all.sh' "$TEST_WORKFLOW" || fail 'test workflow does not run all checks'
rg --fixed-strings --quiet 'agentskills validate academic-beamer' "$SYNC_WORKFLOW" || fail 'sync workflow does not run the skill validator'
rg --fixed-strings --quiet 'agentskills validate academic-beamer' "$RUN_ALL" || fail 'aggregate runner does not run the skill validator'
rg --fixed-strings --quiet 'for test_script in tests/test_*.sh' "$RUN_ALL" || fail 'aggregate runner does not discover all test scripts'

for file in "$SKILL" "$VERIFY" "$TEST_WORKFLOW" "$SYNC_WORKFLOW" "$RUN_ALL"; do
  if rg --quiet 'latexmk -(pdf|xelatex)|^[[:space:]]*(pdf|xe|lua)latex[[:space:]]' "$file"; then
    fail "$file contains a forbidden build command"
  fi
  if rg --fixed-strings --quiet 'skills-ref validate academic-beamer' "$file"; then
    fail "$file invokes the nonexistent skills-ref executable"
  fi
done

python3 - "$TEST_WORKFLOW" "$SYNC_WORKFLOW" <<'PY'
import pathlib
import re
import sys

approved_node24_actions = {
    "actions/checkout": (
        "3d3c42e5aac5ba805825da76410c181273ba90b1",
        "v7.0.1",
    ),
    "actions/setup-python": (
        "5fda3b95a4ea91299a34e894583c3862153e4b97",
        "v7.0.0",
    ),
    "actions/upload-artifact": (
        "043fb46d1a93c77aae656e7c1c64a875d1fc6a0a",
        "v7.0.1",
    ),
    "actions/download-artifact": (
        "3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c",
        "v8.0.1",
    ),
}
official_action = re.compile(r"^\s*(?:-\s+)?uses\s*:\s*actions/")
action = re.compile(r"^\s*(?:-\s+)?uses:\s+(actions/[^@\s]+)@([^\s#]+)(?:\s+#\s+(.+))?$")
errors = []
for workflow_name in sys.argv[1:]:
    workflow = pathlib.Path(workflow_name)
    matches = []
    for line_number, line in enumerate(workflow.read_text().splitlines(), start=1):
        if not official_action.match(line):
            continue
        match = action.match(line)
        if not match:
            errors.append(f"FAIL: {workflow}:{line_number} has a malformed official action use")
            continue
        matches.append((line_number, match))
    if not matches:
        errors.append(f"FAIL: {workflow} contains no official action uses")
    for line_number, match in matches:
        name, ref, comment = match.groups()
        expected = approved_node24_actions.get(name)
        if expected is None:
            errors.append(f"FAIL: {workflow}:{line_number} uses unapproved official action {name}")
            continue
        expected_ref, expected_comment = expected
        if (ref, comment) != expected:
            actual = f"{name}@{ref}" + (f" # {comment}" if comment else "")
            errors.append(
                f"FAIL: {workflow}:{line_number} uses {actual}; expected "
                f"{name}@{expected_ref} # {expected_comment}"
            )

if errors:
    raise SystemExit("\n".join(errors))
PY

for option in \
  '\providecommand{\presentationaspectratio}{43}' \
  '\providecommand{\presentationmode}{light}' \
  '\providecommand{\presentationfontsize}{12pt}' \
  '{presentation}'; do
  rg --fixed-strings --quiet "$option" "$STARTER" || fail "starter is missing $option"
done

[ ! -d "$PACKAGE/tests" ] || fail 'runtime package contains tests'
[ -f "$MIT_LICENSE" ] || fail 'runtime package omits the MIT license'
if find "$PACKAGE" -type f -name '*.pdf' -print -quit | rg --quiet '.'; then
  fail 'runtime package contains a generated PDF'
fi
[ "$(wc -l < "$STARTER" | tr -d ' ')" -le 100 ] || fail 'runtime starter appears to be the comprehensive demo'

for script in "$PACKAGE"/scripts/*.sh; do
  [ -x "$script" ] || fail "$script is not executable"
  bash -n "$script"
done

printf 'Template policy checks passed.\n'
