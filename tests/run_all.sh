#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

agentskills validate academic-beamer

export LC_ALL=C
printf '==> %s\n' tests/test_docs.sh
bash tests/test_docs.sh

for test_script in tests/test_*.sh; do
  [ "$test_script" = tests/test_docs.sh ] && continue
  printf '==> %s\n' "$test_script"
  bash "$test_script"
done

printf 'All Academic Beamer Skill checks passed.\n'
