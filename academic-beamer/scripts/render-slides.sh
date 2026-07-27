#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  printf 'Usage: %s <pdf-file> <output-directory>\n' "${0##*/}" >&2
  exit 2
fi

PDF_PATH=$1
OUTPUT_DIR=${2%/}
[ -n "$OUTPUT_DIR" ] || OUTPUT_DIR=/
[ -f "$PDF_PATH" ] || { printf 'ERROR: PDF not found: %s\n' "$PDF_PATH" >&2; exit 1; }
command -v pdfinfo >/dev/null 2>&1 || { printf 'ERROR: pdfinfo is required\n' >&2; exit 1; }
command -v pdftoppm >/dev/null 2>&1 || { printf 'ERROR: pdftoppm is required\n' >&2; exit 1; }

PARENT_DIR=$(dirname "$OUTPUT_DIR")
[ -d "$PARENT_DIR" ] || {
  printf 'ERROR: output parent does not exist: %s\n' "$PARENT_DIR" >&2
  exit 1
}
if [ -e "$OUTPUT_DIR" ] || [ -L "$OUTPUT_DIR" ]; then
  [ -d "$OUTPUT_DIR" ] || {
    printf 'ERROR: output path is not a directory: %s\n' "$OUTPUT_DIR" >&2
    exit 1
  }
  if [ -n "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    printf 'ERROR: refusing to overwrite nonempty output directory: %s\n' "$OUTPUT_DIR" >&2
    exit 1
  fi
fi
mkdir -p "$OUTPUT_DIR"

if ! PAGES=$(pdfinfo "$PDF_PATH" | awk '
  $1 == "Pages:" && $2 ~ /^[0-9]+$/ { pages = $2; exit }
  END { if (pages == "") exit 1; print pages }
'); then
  printf 'ERROR: unable to determine PDF page count: %s\n' "$PDF_PATH" >&2
  exit 1
fi
if [ "$PAGES" -le 0 ]; then
  printf 'ERROR: unable to determine PDF page count: %s\n' "$PDF_PATH" >&2
  exit 1
fi

for ((page = 1; page <= PAGES; page++)); do
  printf -v output '%s/slide-%03d' "$OUTPUT_DIR" "$page"
  pdftoppm -f "$page" -l "$page" -singlefile -jpeg -r 160 "$PDF_PATH" "$output"
done

RENDERED=0
for image in "$OUTPUT_DIR"/slide-[0-9][0-9][0-9].jpg; do
  [ -f "$image" ] || continue
  RENDERED=$((RENDERED + 1))
done
if [ "$RENDERED" -ne "$PAGES" ]; then
  printf 'ERROR: rendered %s images for %s PDF pages\n' "$RENDERED" "$PAGES" >&2
  exit 1
fi
printf 'Rendered %s slides in %s\n' "$RENDERED" "$OUTPUT_DIR"
