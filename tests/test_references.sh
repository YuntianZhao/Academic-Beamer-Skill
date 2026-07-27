#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REF_DIR="$ROOT_DIR/academic-beamer/references"

for file in input-handling.md content-patterns.md authoring-guide.md visual-review.md quality-checklist.md; do
  [ -s "$REF_DIR/$file" ] || { printf 'FAIL: missing %s\n' "$file" >&2; exit 1; }
  rg --fixed-strings --quiet "references/$file" "$ROOT_DIR/academic-beamer/SKILL.md" || {
    printf 'FAIL: SKILL.md does not reference %s\n' "$file" >&2
    exit 1
  }
done

rg --fixed-strings --quiet 'Do not use full-page screenshots' "$REF_DIR/input-handling.md"
rg --fixed-strings --quiet '\begin{columns}[T,onlytextwidth]' "$REF_DIR/content-patterns.md"
rg --fixed-strings --quiet 'One primary message per frame' "$REF_DIR/authoring-guide.md"
rg --fixed-strings --quiet 'Inspect every rendered slide' "$REF_DIR/visual-review.md"
rg --fixed-strings --quiet 'No unresolved citations or references' "$REF_DIR/quality-checklist.md"

printf 'Reference integrity checks passed.\n'
