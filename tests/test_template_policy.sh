#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE="$ROOT_DIR/academic-beamer"
SKILL="$PACKAGE/SKILL.md"
VERIFY="$PACKAGE/scripts/verify-deck.sh"
STARTER="$PACKAGE/assets/template/presentation.tex"
TEST_WORKFLOW="$ROOT_DIR/.github/workflows/test.yml"
SYNC_WORKFLOW="$ROOT_DIR/.github/workflows/sync-template.yml"
RUN_ALL="$ROOT_DIR/tests/run_all.sh"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

rg --fixed-strings --quiet 'must not be replaced by another Beamer theme' "$SKILL" || fail 'theme rejection is missing'
rg --multiline --quiet 'Do not draft the complete deck\s+until the user approves' "$SKILL" || fail 'outline approval gate is missing'
rg --fixed-strings --quiet 'latexmk -lualatex' "$SKILL" || fail 'SKILL.md lacks latexmk -lualatex'
rg --fixed-strings --quiet 'latexmk -lualatex' "$VERIFY" || fail 'verify-deck.sh lacks latexmk -lualatex'
rg --fixed-strings --quiet 'command -v lualatex' "$VERIFY" || fail 'verify-deck.sh does not require lualatex'
rg --fixed-strings --quiet "grep -Eq '^This is Lua(HB)?TeX([, ]|$)'" "$VERIFY" || fail 'verify-deck.sh does not validate LuaTeX or LuaHBTeX logs'
[ -f "$TEST_WORKFLOW" ] || fail 'test.yml is missing'
for workflow in "$TEST_WORKFLOW" "$SYNC_WORKFLOW"; do
  rg --fixed-strings --quiet 'texlive-luatex' "$workflow" || fail "$workflow does not install LuaLaTeX"
  rg --fixed-strings --quiet 'python3 -m pip install skills-ref' "$workflow" || fail "$workflow does not install the skill validator"
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

for option in \
  '\providecommand{\presentationaspectratio}{43}' \
  '\providecommand{\presentationmode}{light}' \
  '\providecommand{\presentationfontsize}{12pt}' \
  '{presentation}'; do
  rg --fixed-strings --quiet "$option" "$STARTER" || fail "starter is missing $option"
done

[ ! -d "$PACKAGE/tests" ] || fail 'runtime package contains tests'
if find "$PACKAGE" -type f -name '*.pdf' -print -quit | rg --quiet '.'; then
  fail 'runtime package contains a generated PDF'
fi
[ "$(wc -l < "$STARTER" | tr -d ' ')" -le 100 ] || fail 'runtime starter appears to be the comprehensive demo'

for script in "$PACKAGE"/scripts/*.sh; do
  [ -x "$script" ] || fail "$script is not executable"
  bash -n "$script"
done

printf 'Template policy checks passed.\n'
