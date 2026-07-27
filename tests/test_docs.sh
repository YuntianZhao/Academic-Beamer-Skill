#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"
RUN_ALL="$ROOT_DIR/tests/run_all.sh"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -f "$README" ] || fail 'README.md is missing'

for heading in '## Requirements' '## Installation' '## Usage' '## How Verification Works' '## Template Updates' '## Licensing'; do
  rg --fixed-strings --quiet "$heading" "$README" || fail "README is missing $heading"
done
for path in '.agents/skills/academic-beamer' '.claude/skills/academic-beamer'; do
  rg --fixed-strings --quiet "$path" "$README" || fail "README is missing $path"
done

docs_match=$(rg --line-number --fixed-strings 'bash tests/test_docs.sh' "$RUN_ALL" || true)
loop_match=$(rg --line-number --fixed-strings 'for test_script in tests/test_*.sh' "$RUN_ALL" || true)
[ -n "$docs_match" ] || fail 'aggregate runner does not run documentation checks first'
[ "$(rg --fixed-strings --count-matches 'bash tests/test_docs.sh' "$RUN_ALL")" -eq 1 ] || fail 'aggregate runner invokes documentation checks more than once explicitly'
[ -n "$loop_match" ] || fail 'aggregate runner does not dynamically discover test scripts'
[ "${docs_match%%:*}" -lt "${loop_match%%:*}" ] || fail 'aggregate runner does not run documentation checks before dynamic tests'
rg --fixed-strings --quiet '[ "$test_script" = tests/test_docs.sh ] && continue' "$RUN_ALL" || fail 'aggregate runner does not skip the already-run documentation test'

rg --fixed-strings --quiet 'bash tests/run_all.sh' "$ROOT_DIR/CONTRIBUTING.md" || fail 'contributor test command is missing'
rg --fixed-strings --quiet '`latexmk` and LuaLaTeX' "$ROOT_DIR/CONTRIBUTING.md" || fail 'contributor prerequisites omit latexmk or LuaLaTeX'
rg --fixed-strings --quiet 'v1.0.0' "$ROOT_DIR/CHANGELOG.md" || fail 'skill release is missing from changelog'
rg --fixed-strings --quiet 'Beamer-Template` v1.0.0' "$ROOT_DIR/CHANGELOG.md" || fail 'template release is missing from changelog'
rg --fixed-strings --quiet 'mandatory LuaLaTeX' "$ROOT_DIR/CHANGELOG.md" || fail 'changelog omits the mandatory LuaLaTeX workflow'
rg --fixed-strings --quiet -- '- LuaLaTeX' "$README" || fail 'README does not require LuaLaTeX'
rg --fixed-strings --line-regexp --quiet -- '- Biber' "$README" || fail 'README does not require Biber for every verified build'
rg --fixed-strings --quiet 'latexmk -lualatex' "$README" || fail 'README lacks the mandatory LuaLaTeX command'

for action in create revise migrate verify; do
  file="$ROOT_DIR/tests/prompt-evals/$action.md"
  [ -s "$file" ] || fail "prompt evaluation is missing: $action.md"
  rg --fixed-strings --quiet '## Failure Criteria' "$file" || fail "$action.md lacks failure criteria"
  rg --fixed-strings --quiet 'Switching to another theme while the skill is active.' "$file" || fail "$action.md lacks theme enforcement"
  rg --fixed-strings --quiet 'LuaLaTeX' "$file" || fail "$action.md lacks the LuaLaTeX runtime policy"
done

printf 'Documentation checks passed.\n'
