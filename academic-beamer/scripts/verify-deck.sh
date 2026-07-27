#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <tex-file>\n' "${0##*/}" >&2
  exit 2
fi

TEX_PATH=$1
case "$TEX_PATH" in
  -*) TEX_PATH="./$TEX_PATH" ;;
esac
[ -f "$TEX_PATH" ] || { printf 'ERROR: TeX file not found: %s\n' "$TEX_PATH" >&2; exit 1; }
command -v latexmk >/dev/null 2>&1 || { printf 'ERROR: latexmk is required\n' >&2; exit 1; }
command -v lualatex >/dev/null 2>&1 || { printf 'ERROR: LuaLaTeX is required\n' >&2; exit 1; }

TEX_DIR=$(CDPATH= cd -- "$(dirname "$TEX_PATH")" && pwd)
TEX_NAME=$(basename "$TEX_PATH")
LATEXMK_JOBNAME=
case "$TEX_NAME" in
  -*)
    TEX_NAME="./$TEX_NAME"
    LATEXMK_JOBNAME="-jobname=${TEX_NAME%.tex}"
    ;;
esac
JOB_NAME=${TEX_NAME%.tex}

BUILD_STATUS=0
(
  cd "$TEX_DIR"
  set -- "$TEX_NAME"
  if [ -n "$LATEXMK_JOBNAME" ]; then
    set -- "$LATEXMK_JOBNAME" "$@"
  fi
  latexmk -lualatex -norc -e '$biber = "biber %O -- %B";' \
    -interaction=nonstopmode -halt-on-error -file-line-error \
    "$@"
) || BUILD_STATUS=$?

LOG_PATH="$TEX_DIR/$JOB_NAME.log"
PDF_PATH="$TEX_DIR/$JOB_NAME.pdf"
[ -f "$LOG_PATH" ] || { printf 'ERROR: build log was not created\n' >&2; exit 1; }

grep -Eq '^This is Lua(HB)?TeX([, ]|$)' "$LOG_PATH" || {
  printf 'ERROR: build log does not identify LuaTeX or LuaHBTeX\n' >&2
  exit 1
}

if grep -Eiq 'undefined citations?|undefined references?|Citation .* undefined|Reference .* undefined' "$LOG_PATH"; then
  printf 'ERROR: undefined citation or reference remains\n' >&2
  exit 1
fi
if grep -Eq 'LaTeX Warning: File .* not found|! LaTeX Error: File .* not found' "$LOG_PATH"; then
  printf 'ERROR: referenced source file is missing\n' >&2
  exit 1
fi
if grep -Eq 'Overfull \\[hv]box' "$LOG_PATH"; then
  printf 'ERROR: meaningful overfull box warning remains\n' >&2
  exit 1
fi
if grep -Eiq 'Rerun to get|Label\(s\) may have changed|Please rerun' "$LOG_PATH"; then
  printf 'ERROR: unresolved rerun request remains\n' >&2
  exit 1
fi

if [ "$BUILD_STATUS" -ne 0 ]; then
  printf 'ERROR: LuaLaTeX build failed (latexmk exit status %s)\n' "$BUILD_STATUS" >&2
  exit 1
fi
[ -f "$PDF_PATH" ] || { printf 'ERROR: PDF was not created\n' >&2; exit 1; }

PAGES=$(
  awk '
    match($0, /Output written on .+ \([0-9]+ pages?/) {
      record = substr($0, RSTART, RLENGTH)
      sub(/^.*\(/, "", record)
      sub(/ pages?$/, "", record)
      pages = record
    }
    END { if (pages != "") print pages }
  ' "$LOG_PATH"
)
UNDERFULL=$(awk '/Underfull \\[hv]box/ { count++ } END { print count + 0 }' "$LOG_PATH")
printf 'PDF: %s\n' "$PDF_PATH"
printf 'Pages: %s\n' "${PAGES:-unknown}"
printf 'Underfull box warnings: %s\n' "${UNDERFULL:-0}"
