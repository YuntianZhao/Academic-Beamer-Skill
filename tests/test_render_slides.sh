#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RENDER="$ROOT_DIR/academic-beamer/scripts/render-slides.sh"
CREATE="$ROOT_DIR/academic-beamer/scripts/create-deck.sh"
VERIFY="$ROOT_DIR/academic-beamer/scripts/verify-deck.sh"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-render.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_line() {
  grep --fixed-strings --line-regexp --quiet -- "$1" "$2" || fail "$3"
}

[ -x "$RENDER" ] || fail 'render-slides.sh is missing or not executable'

if "$RENDER" >"$TMP_DIR/no-args.out" 2>"$TMP_DIR/no-args.err"; then
  fail 'invocation without arguments should fail'
else
  exit_code=$?
fi
[ "$exit_code" -eq 2 ] || fail 'missing arguments should exit 2'
assert_line 'Usage: render-slides.sh <pdf-file> <output-directory>' "$TMP_DIR/no-args.err" \
  'missing-argument usage is absent'

if "$RENDER" one.pdf frames extra >"$TMP_DIR/extra-args.out" 2>"$TMP_DIR/extra-args.err"; then
  fail 'invocation with extra arguments should fail'
else
  exit_code=$?
fi
[ "$exit_code" -eq 2 ] || fail 'extra arguments should exit 2'
assert_line 'Usage: render-slides.sh <pdf-file> <output-directory>' "$TMP_DIR/extra-args.err" \
  'extra-argument usage is absent'

missing_pdf="$TMP_DIR/deck with spaces/absent.pdf"
if "$RENDER" "$missing_pdf" "$TMP_DIR/frames" >"$TMP_DIR/missing.out" 2>"$TMP_DIR/missing.err"; then
  fail 'nonexistent PDF should fail rendering'
fi
assert_line "ERROR: PDF not found: $missing_pdf" "$TMP_DIR/missing.err" \
  'nonexistent-PDF diagnostic is absent'

mkdir "$TMP_DIR/no-tools"
: > "$TMP_DIR/no-tools/presentation.pdf"
if PATH="$TMP_DIR/no-tools" /bin/bash "$RENDER" "$TMP_DIR/no-tools/presentation.pdf" \
    "$TMP_DIR/no-tools/frames" >"$TMP_DIR/no-pdfinfo.out" 2>"$TMP_DIR/no-pdfinfo.err"; then
  fail 'missing pdfinfo should fail rendering'
fi
assert_line 'ERROR: pdfinfo is required' "$TMP_DIR/no-pdfinfo.err" \
  'missing-pdfinfo diagnostic is absent'

mkdir "$TMP_DIR/pdfinfo-only"
cat > "$TMP_DIR/pdfinfo-only/pdfinfo" <<'SCRIPT'
#!/bin/sh
printf 'Pages: 1\n'
SCRIPT
chmod +x "$TMP_DIR/pdfinfo-only/pdfinfo"
if PATH="$TMP_DIR/pdfinfo-only" /bin/bash "$RENDER" "$TMP_DIR/no-tools/presentation.pdf" \
    "$TMP_DIR/no-tools/frames" >"$TMP_DIR/no-pdftoppm.out" 2>"$TMP_DIR/no-pdftoppm.err"; then
  fail 'missing pdftoppm should fail rendering'
fi
assert_line 'ERROR: pdftoppm is required' "$TMP_DIR/no-pdftoppm.err" \
  'missing-pdftoppm diagnostic is absent'

FAKE_ROOT="$TMP_DIR/fake renderer"
FAKE_BIN="$FAKE_ROOT/bin"
FAKE_PDF="$FAKE_ROOT/deck with spaces/presentation.pdf"
FAKE_OUTPUT="$FAKE_ROOT/rendered slides"
mkdir -p "$FAKE_BIN" "$(dirname "$FAKE_PDF")"
: > "$FAKE_PDF"
cat > "$FAKE_BIN/pdfinfo" <<'SCRIPT'
#!/bin/sh
printf 'Title: Fake deck\nPages:          3\nPage size:      960 x 540 pts\n'
SCRIPT
cat > "$FAKE_BIN/pdftoppm" <<'SCRIPT'
#!/bin/sh
set -eu
printf '%s\n' "$@" >> "$FAKE_ARGS"
for argument in "$@"; do output=$argument; done
case "${FAKE_SKIP_PAGE:-}" in
  1) [ "$2" = 1 ] && exit 0 ;;
  2) [ "$2" = 2 ] && exit 0 ;;
  3) [ "$2" = 3 ] && exit 0 ;;
esac
: > "$output.jpg"
SCRIPT
chmod +x "$FAKE_BIN/pdfinfo" "$FAKE_BIN/pdftoppm"

PATH="$FAKE_BIN:/usr/bin:/bin" FAKE_ARGS="$FAKE_ROOT/pdftoppm.args" \
  "$RENDER" "$FAKE_PDF" "$FAKE_OUTPUT" >/dev/null
for page in 001 002 003; do
  [ -f "$FAKE_OUTPUT/slide-$page.jpg" ] || fail "numbered slide $page is missing"
done
[ "$(find "$FAKE_OUTPUT" -type f -name 'slide-[0-9][0-9][0-9].jpg' | wc -l | tr -d ' ')" -eq 3 ] || \
  fail 'fake three-page PDF did not produce exactly three numbered images'
cat > "$FAKE_ROOT/expected.args" <<EOF
-f
1
-l
1
-singlefile
-jpeg
-r
160
$FAKE_PDF
$FAKE_OUTPUT/slide-001
-f
2
-l
2
-singlefile
-jpeg
-r
160
$FAKE_PDF
$FAKE_OUTPUT/slide-002
-f
3
-l
3
-singlefile
-jpeg
-r
160
$FAKE_PDF
$FAKE_OUTPUT/slide-003
EOF
cmp "$FAKE_ROOT/expected.args" "$FAKE_ROOT/pdftoppm.args" >/dev/null || \
  fail 'pdftoppm did not receive exact per-page 160-DPI arguments'

mkdir "$TMP_DIR/nonempty"
printf 'preserve me\n' > "$TMP_DIR/nonempty/existing.txt"
if "$RENDER" "$FAKE_PDF" "$TMP_DIR/nonempty" >"$TMP_DIR/nonempty.out" 2>"$TMP_DIR/nonempty.err"; then
  fail 'nonempty output directory should be rejected'
fi
[ "$(cat "$TMP_DIR/nonempty/existing.txt")" = 'preserve me' ] || fail 'existing output was altered'
assert_line "ERROR: refusing to overwrite nonempty output directory: $TMP_DIR/nonempty" \
  "$TMP_DIR/nonempty.err" 'nonempty-output diagnostic is absent'

if "$RENDER" "$FAKE_PDF" "$TMP_DIR/missing/frames" >"$TMP_DIR/missing-parent.out" \
    2>"$TMP_DIR/missing-parent.err"; then
  fail 'missing output parent should be rejected'
fi
[ ! -e "$TMP_DIR/missing" ] || fail 'missing output parent was created'
assert_line "ERROR: output parent does not exist: $TMP_DIR/missing" \
  "$TMP_DIR/missing-parent.err" 'missing-output-parent diagnostic is absent'

MISMATCH_OUTPUT="$FAKE_ROOT/mismatched slides"
if PATH="$FAKE_BIN:/usr/bin:/bin" FAKE_ARGS="$FAKE_ROOT/mismatch.args" FAKE_SKIP_PAGE=2 \
    "$RENDER" "$FAKE_PDF" "$MISMATCH_OUTPUT" >"$TMP_DIR/mismatch.out" 2>"$TMP_DIR/mismatch.err"; then
  fail 'rendered/PDF page-count mismatch should fail'
fi
assert_line 'ERROR: rendered 2 images for 3 PDF pages' "$TMP_DIR/mismatch.err" \
  'page-parity diagnostic is absent'

"$CREATE" "$TMP_DIR/deck"
"$VERIFY" "$TMP_DIR/deck/presentation.tex" >/dev/null
"$RENDER" "$TMP_DIR/deck/presentation.pdf" "$TMP_DIR/real rendered slides" >/dev/null

pages=$(pdfinfo "$TMP_DIR/deck/presentation.pdf" | awk '$1 == "Pages:" { print $2; exit }')
rendered=$(find "$TMP_DIR/real rendered slides" -type f -name 'slide-[0-9][0-9][0-9].jpg' | wc -l | tr -d ' ')
[ "$rendered" -eq "$pages" ] || fail "rendered $rendered images for $pages pages"
[ -f "$TMP_DIR/real rendered slides/slide-001.jpg" ] || fail 'first numbered slide is missing'
[ -f "$TMP_DIR/real rendered slides/slide-003.jpg" ] || fail 'third numbered slide is missing'

printf 'Slide rendering tests passed.\n'
