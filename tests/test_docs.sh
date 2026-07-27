#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -f "$README" ] || fail 'README.md is missing'

for heading in '## Requirements' '## Installation' '## Usage' '## How Verification Works' '## Template Updates' '## Licensing'; do
  rg --fixed-strings --quiet "$heading" "$README" || fail "README is missing $heading"
done
for path in '.agents/skills/academic-beamer' '.claude/skills/academic-beamer'; do
  rg --fixed-strings --quiet "$path" "$README" || fail "README is missing $path"
done

rg --fixed-strings --quiet 'bash tests/run_all.sh' "$ROOT_DIR/CONTRIBUTING.md" || fail 'contributor test command is missing'
rg --fixed-strings --quiet '`latexmk` and LuaLaTeX' "$ROOT_DIR/CONTRIBUTING.md" || fail 'contributor prerequisites omit latexmk or LuaLaTeX'
rg --fixed-strings --quiet 'v1.0.0' "$ROOT_DIR/CHANGELOG.md" || fail 'skill release is missing from changelog'
rg --fixed-strings --quiet 'Beamer-Template` v1.0.0' "$ROOT_DIR/CHANGELOG.md" || fail 'template release is missing from changelog'
rg --fixed-strings --quiet 'mandatory LuaLaTeX' "$ROOT_DIR/CHANGELOG.md" || fail 'changelog omits the mandatory LuaLaTeX workflow'
rg --fixed-strings --quiet -- '- LuaLaTeX' "$README" || fail 'README does not require LuaLaTeX'
rg --fixed-strings --quiet 'latexmk -lualatex' "$README" || fail 'README lacks the mandatory LuaLaTeX command'

for action in create revise migrate verify; do
  file="$ROOT_DIR/tests/prompt-evals/$action.md"
  [ -s "$file" ] || fail "prompt evaluation is missing: $action.md"
  rg --fixed-strings --quiet '## Failure Criteria' "$file" || fail "$action.md lacks failure criteria"
  rg --fixed-strings --quiet 'Switching to another theme while the skill is active.' "$file" || fail "$action.md lacks theme enforcement"
  rg --fixed-strings --quiet 'LuaLaTeX' "$file" || fail "$action.md lacks the LuaLaTeX runtime policy"
done

printf 'Documentation checks passed.\n'
