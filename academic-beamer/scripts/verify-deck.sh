#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <tex-file>\n' "${0##*/}" >&2
  exit 2
fi

TEX_PATH=$1
[ -f "$TEX_PATH" ] || { printf 'ERROR: TeX file not found: %s\n' "$TEX_PATH" >&2; exit 1; }
command -v latexmk >/dev/null 2>&1 || { printf 'ERROR: latexmk is required\n' >&2; exit 1; }
command -v lualatex >/dev/null 2>&1 || { printf 'ERROR: LuaLaTeX is required\n' >&2; exit 1; }

TEX_DIR=$(CDPATH= cd -- "$(dirname "$TEX_PATH")" && pwd)
TEX_NAME=$(basename "$TEX_PATH")
JOB_NAME=${TEX_NAME%.tex}

(
  cd "$TEX_DIR"
  latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error "$TEX_NAME"
)

LOG_PATH="$TEX_DIR/$JOB_NAME.log"
PDF_PATH="$TEX_DIR/$JOB_NAME.pdf"
[ -f "$LOG_PATH" ] || { printf 'ERROR: build log was not created\n' >&2; exit 1; }
[ -f "$PDF_PATH" ] || { printf 'ERROR: PDF was not created\n' >&2; exit 1; }

rg --quiet '^This is Lua(HB)?TeX(?:,| |$)' "$LOG_PATH" || {
  printf 'ERROR: build log does not identify LuaTeX or LuaHBTeX\n' >&2
  exit 1
}

if rg --ignore-case --quiet 'undefined citations?|undefined references?|Citation .* undefined|Reference .* undefined' "$LOG_PATH"; then
  printf 'ERROR: undefined citation or reference remains\n' >&2
  exit 1
fi
if rg --quiet 'LaTeX Warning: File .* not found|! LaTeX Error: File .* not found' "$LOG_PATH"; then
  printf 'ERROR: referenced source file is missing\n' >&2
  exit 1
fi
if rg --quiet 'Overfull \\[hv]box' "$LOG_PATH"; then
  printf 'ERROR: meaningful overfull box warning remains\n' >&2
  exit 1
fi
if rg --ignore-case --quiet 'Rerun to get|Label\(s\) may have changed|Please rerun' "$LOG_PATH"; then
  printf 'ERROR: unresolved rerun request remains\n' >&2
  exit 1
fi

PAGES=$(rg --only-matching 'Output written on .+ \([0-9]+ pages?' "$LOG_PATH" | rg --only-matching '[0-9]+ pages?' | rg --only-matching '[0-9]+' | tail -n 1)
UNDERFULL=$(rg --count 'Underfull \\[hv]box' "$LOG_PATH" || true)
printf 'PDF: %s\n' "$PDF_PATH"
printf 'Pages: %s\n' "${PAGES:-unknown}"
printf 'Underfull box warnings: %s\n' "${UNDERFULL:-0}"
