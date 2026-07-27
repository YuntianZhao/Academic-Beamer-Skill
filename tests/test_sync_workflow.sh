#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW="$ROOT_DIR/.github/workflows/sync-template.yml"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -f "$WORKFLOW" ] || fail 'sync-template.yml is missing'

for required in \
  'schedule:' \
  'workflow_dispatch:' \
  'contents: write' \
  'pull-requests: write' \
  'actions/setup-python@v5' \
  'python3 -m pip install skills-ref' \
  'presentation.sty' \
  'presentation-minimal.tex' \
  'LICENSE.txt' \
  'template-source.json' \
  'biber' \
  'latexmk' \
  'poppler-utils' \
  'texlive-bibtex-extra' \
  'texlive-fonts-extra' \
  'texlive-latex-extra' \
  'texlive-luatex' \
  'texlive-science' \
  'source_commit' \
  'sha256' \
  'imported_at' \
  'agentskills validate academic-beamer' \
  'bash tests/run_all.sh' \
  'gh pr list' \
  'gh pr create'; do
  rg --fixed-strings --quiet "$required" "$WORKFLOW" || fail "workflow is missing: $required"
done

for forbidden in \
  'skills-ref validate academic-beamer' \
  'git push origin main' \
  'git push origin master' \
  'gh release create' \
  'raw.githubusercontent.com/YuntianZhao/Beamer-Template/main'; do
  if rg --fixed-strings --quiet "$forbidden" "$WORKFLOW"; then
    fail "workflow contains forbidden behavior: $forbidden"
  fi
done

printf 'Synchronization workflow checks passed.\n'
