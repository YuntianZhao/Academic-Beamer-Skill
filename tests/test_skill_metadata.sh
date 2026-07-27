#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SKILL_FILE="$ROOT_DIR/academic-beamer/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[ -f "$SKILL_FILE" ] || fail 'academic-beamer/SKILL.md is missing'
rg --fixed-strings --quiet 'name: academic-beamer' "$SKILL_FILE" || fail 'skill name is missing'
rg --fixed-strings --quiet 'bundled template is mandatory' "$SKILL_FILE" || fail 'mandatory template contract is missing'
rg --fixed-strings --quiet 'compatibility: Requires latexmk and LuaLaTeX' "$SKILL_FILE" || fail 'LuaLaTeX compatibility prerequisite is missing'
rg --fixed-strings --quiet 'latexmk -lualatex' "$SKILL_FILE" || fail 'LuaLaTeX latexmk workflow is missing'
if rg --quiet '^(argument-hint|allowed-tools|disable-model-invocation):' "$SKILL_FILE"; then
  fail 'SKILL.md contains harness-specific frontmatter'
fi

printf 'Skill metadata checks passed.\n'
