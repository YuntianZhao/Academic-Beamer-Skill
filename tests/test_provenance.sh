#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ASSET_DIR="$ROOT_DIR/academic-beamer/assets/template"
MANIFEST="$ROOT_DIR/template-source.json"
PACKAGE_LICENSE="$ROOT_DIR/academic-beamer/LICENSE"

for file in presentation.sty presentation.tex references.bib LICENSE.txt VERSION; do
  [ -f "$ASSET_DIR/$file" ] || { printf 'FAIL: missing %s\n' "$file" >&2; exit 1; }
done

[ -f "$PACKAGE_LICENSE" ] || { printf 'FAIL: missing package MIT license\n' >&2; exit 1; }
cmp "$ROOT_DIR/LICENSE" "$PACKAGE_LICENSE" >/dev/null || {
  printf 'FAIL: package MIT license differs from repository license\n' >&2
  exit 1
}
rg --fixed-strings --quiet 'LaTeX Project Public License' "$ASSET_DIR/LICENSE.txt" || {
  printf 'FAIL: vendored template license is not LPPL\n' >&2
  exit 1
}

python3 - "$ROOT_DIR" <<'PY'
import hashlib
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
manifest = json.loads((root / "template-source.json").read_text())
version = (root / "academic-beamer/assets/template/VERSION").read_text().strip()
assert manifest["repository"] == "YuntianZhao/Beamer-Template"
assert manifest["release"] == version
assert re.fullmatch(r"[0-9a-f]{40}", manifest["source_commit"])
assert {item["source"] for item in manifest["files"]} == {
    "presentation.sty", "presentation-minimal.tex", "LICENSE.txt"
}
for item in manifest["files"]:
    path = root / item["destination"]
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    assert digest == item["sha256"], path
PY

printf 'Template provenance checks passed.\n'
