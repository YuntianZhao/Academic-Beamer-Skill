#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <target-directory>\n' "${0##*/}" >&2
  exit 2
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ASSET_DIR="$SCRIPT_DIR/../assets/template"
TARGET_DIR=${1%/}
[ -n "$TARGET_DIR" ] || TARGET_DIR=/
PARENT_DIR=$(dirname "$TARGET_DIR")

if [ ! -d "$PARENT_DIR" ]; then
  printf 'ERROR: parent directory does not exist: %s\n' "$PARENT_DIR" >&2
  exit 1
fi

for file in presentation.sty presentation.tex references.bib LICENSE.txt; do
  if [ -e "$TARGET_DIR/$file" ]; then
    printf 'ERROR: refusing to overwrite %s\n' "$TARGET_DIR/$file" >&2
    exit 1
  fi
done

mkdir -p "$TARGET_DIR"
for file in presentation.sty presentation.tex references.bib LICENSE.txt; do
  cp "$ASSET_DIR/$file" "$TARGET_DIR/$file"
  printf 'Created %s\n' "$TARGET_DIR/$file"
done

printf 'Bundled template: %s\n' "$(tr -d '\r\n' < "$ASSET_DIR/VERSION")"
