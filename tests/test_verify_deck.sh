#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT="$ROOT_DIR/academic-beamer/scripts/verify-deck.sh"
CREATE="$ROOT_DIR/academic-beamer/scripts/create-deck.sh"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-verify.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -x "$SCRIPT" ] || fail 'verify-deck.sh is missing or not executable'

mkdir "$TMP_DIR/no-tools"
printf '\\documentclass{article}\n\\begin{document}x\\end{document}\n' > "$TMP_DIR/no-tools/presentation.tex"
if PATH="$TMP_DIR/no-tools" /bin/bash "$SCRIPT" "$TMP_DIR/no-tools/presentation.tex" >"$TMP_DIR/no-tools.out" 2>"$TMP_DIR/no-tools.err"; then
  fail 'missing latexmk should fail verification'
fi
rg --fixed-strings --quiet 'latexmk is required' "$TMP_DIR/no-tools.err" || fail 'missing-latexmk diagnostic is absent'

mkdir "$TMP_DIR/latexmk-only"
cat > "$TMP_DIR/latexmk-only/latexmk" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "$TMP_DIR/latexmk-only/latexmk"
if PATH="$TMP_DIR/latexmk-only" /bin/bash "$SCRIPT" "$TMP_DIR/no-tools/presentation.tex" >"$TMP_DIR/lualatex.out" 2>"$TMP_DIR/lualatex.err"; then
  fail 'missing lualatex should fail verification'
fi
rg --fixed-strings --quiet 'LuaLaTeX is required' "$TMP_DIR/lualatex.err" || fail 'missing-lualatex diagnostic is absent'

mkdir "$TMP_DIR/real deck"
$CREATE "$TMP_DIR/real deck/slides"
output=$($SCRIPT "$TMP_DIR/real deck/slides/presentation.tex")
[ -f "$TMP_DIR/real deck/slides/presentation.pdf" ] || fail 'real build did not create PDF'
[[ "$output" == *"Pages: 3"* ]] || fail 'real build did not report three pages'

mkdir "$TMP_DIR/fake-bin" "$TMP_DIR/fake-deck"
printf '\\documentclass{article}\n\\begin{document}x\\end{document}\n' > "$TMP_DIR/fake-deck/presentation.tex"
cat > "$TMP_DIR/fake-bin/latexmk" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
last=
for argument in "$@"; do last=$argument; done
job=${last%.tex}
cp "$FAKE_LOG" "$job.log"
: > "$job.pdf"
SCRIPT
cat > "$TMP_DIR/fake-bin/lualatex" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "$TMP_DIR/fake-bin/latexmk" "$TMP_DIR/fake-bin/lualatex"

output=$(PATH="$TMP_DIR/fake-bin:$PATH" FAKE_LOG="$ROOT_DIR/tests/fixtures/good.log" \
  $SCRIPT "$TMP_DIR/fake-deck/presentation.tex")
[[ "$output" == *"Pages: 3"* ]] || fail 'LuaHBTeX fixture did not pass verification'

if PATH="$TMP_DIR/fake-bin:$PATH" FAKE_LOG="$ROOT_DIR/tests/fixtures/warnings.log" \
    $SCRIPT "$TMP_DIR/fake-deck/presentation.tex" >"$TMP_DIR/warnings.out" 2>"$TMP_DIR/warnings.err"; then
  fail 'warning fixture should fail verification'
fi
rg --fixed-strings --quiet 'undefined citation or reference' "$TMP_DIR/warnings.err" || \
  fail 'undefined-reference diagnostic is missing'

printf 'This is pdfTeX, Version 3.141592653\nOutput written on presentation.pdf (1 page, 1 byte).\n' > "$TMP_DIR/wrong-engine.log"
if PATH="$TMP_DIR/fake-bin:$PATH" FAKE_LOG="$TMP_DIR/wrong-engine.log" \
    $SCRIPT "$TMP_DIR/fake-deck/presentation.tex" >"$TMP_DIR/wrong-engine.out" 2>"$TMP_DIR/wrong-engine.err"; then
  fail 'pdfTeX fixture should fail because pdfLaTeX is a forbidden skill-runtime substitute'
fi
rg --fixed-strings --quiet 'build log does not identify LuaTeX or LuaHBTeX' "$TMP_DIR/wrong-engine.err" || \
  fail 'wrong-engine diagnostic is missing'

printf 'Deck verification tests passed.\n'
