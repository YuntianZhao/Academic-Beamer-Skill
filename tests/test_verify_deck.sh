#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT="$ROOT_DIR/academic-beamer/scripts/verify-deck.sh"
CREATE="$ROOT_DIR/academic-beamer/scripts/create-deck.sh"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-verify.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_line() {
  grep --fixed-strings --line-regexp --quiet -- "$1" "$2" || fail "$3"
}

[ -x "$SCRIPT" ] || fail 'verify-deck.sh is missing or not executable'

if "$SCRIPT" >"$TMP_DIR/no-args.out" 2>"$TMP_DIR/no-args.err"; then
  fail 'invocation without an argument should fail'
else
  exit_code=$?
fi
[ "$exit_code" -eq 2 ] || fail 'missing argument should exit 2'
assert_line 'Usage: verify-deck.sh <tex-file>' "$TMP_DIR/no-args.err" 'missing-argument usage is absent'

if "$SCRIPT" one.tex two.tex >"$TMP_DIR/extra-args.out" 2>"$TMP_DIR/extra-args.err"; then
  fail 'invocation with extra arguments should fail'
else
  exit_code=$?
fi
[ "$exit_code" -eq 2 ] || fail 'extra arguments should exit 2'
assert_line 'Usage: verify-deck.sh <tex-file>' "$TMP_DIR/extra-args.err" 'extra-argument usage is absent'

missing_tex="$TMP_DIR/deck with spaces/absent.tex"
if "$SCRIPT" "$missing_tex" >"$TMP_DIR/missing-tex.out" 2>"$TMP_DIR/missing-tex.err"; then
  fail 'nonexistent TeX path should fail verification'
fi
assert_line "ERROR: TeX file not found: $missing_tex" "$TMP_DIR/missing-tex.err" \
  'nonexistent-TeX diagnostic is absent'

mkdir "$TMP_DIR/no-tools"
printf '\\documentclass{article}\n\\begin{document}x\\end{document}\n' > "$TMP_DIR/no-tools/presentation.tex"
if PATH="$TMP_DIR/no-tools" /bin/bash "$SCRIPT" "$TMP_DIR/no-tools/presentation.tex" \
    >"$TMP_DIR/no-tools.out" 2>"$TMP_DIR/no-tools.err"; then
  fail 'missing latexmk should fail verification'
fi
assert_line 'ERROR: latexmk is required' "$TMP_DIR/no-tools.err" 'missing-latexmk diagnostic is absent'

mkdir "$TMP_DIR/latexmk-only"
cat > "$TMP_DIR/latexmk-only/latexmk" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "$TMP_DIR/latexmk-only/latexmk"
if PATH="$TMP_DIR/latexmk-only" /bin/bash "$SCRIPT" "$TMP_DIR/no-tools/presentation.tex" \
    >"$TMP_DIR/lualatex.out" 2>"$TMP_DIR/lualatex.err"; then
  fail 'missing lualatex should fail verification'
fi
assert_line 'ERROR: LuaLaTeX is required' "$TMP_DIR/lualatex.err" 'missing-lualatex diagnostic is absent'

mkdir "$TMP_DIR/real deck"
"$CREATE" "$TMP_DIR/real deck/slides"
output=$("$SCRIPT" "$TMP_DIR/real deck/slides/presentation.tex")
[ -f "$TMP_DIR/real deck/slides/presentation.pdf" ] || fail 'real build did not create PDF'
[[ "$output" == *"Pages: 3"* ]] || fail 'real build did not report three pages'

mkdir "$TMP_DIR/rc isolation"
"$CREATE" "$TMP_DIR/rc isolation/slides"
cat > "$TMP_DIR/rc isolation/slides/.latexmkrc" <<'RC'
system('touch', 'latexmkrc-executed');
RC
output=$("$SCRIPT" "$TMP_DIR/rc isolation/slides/presentation.tex")
[ -f "$TMP_DIR/rc isolation/slides/presentation.pdf" ] || fail 'RC-isolated build did not create PDF'
[[ "$output" == *"Pages: 3"* ]] || fail 'RC-isolated build did not report three pages'
[ ! -e "$TMP_DIR/rc isolation/slides/latexmkrc-executed" ] || fail 'verification executed the project .latexmkrc'

mkdir "$TMP_DIR/leading dash"
"$CREATE" "$TMP_DIR/leading dash/slides"
mv "$TMP_DIR/leading dash/slides/presentation.tex" "$TMP_DIR/leading dash/slides/-deck.tex"
output=$(
  cd "$TMP_DIR/leading dash/slides"
  "$SCRIPT" -deck.tex
)
[ -f "$TMP_DIR/leading dash/slides/-deck.pdf" ] || fail 'leading-dash TeX path did not create PDF'
[[ "$output" == *"Pages: 3"* ]] || fail 'leading-dash TeX path did not report three pages'

mkdir "$TMP_DIR/real missing input"
printf '\\documentclass{article}\n\\begin{document}\n\\input{missing-source.tex}\n\\end{document}\n' \
  > "$TMP_DIR/real missing input/presentation.tex"
if "$SCRIPT" "$TMP_DIR/real missing input/presentation.tex" \
    >"$TMP_DIR/real-missing.out" 2>"$TMP_DIR/real-missing.err"; then
  fail 'real fatal missing input should fail verification'
fi
assert_line 'ERROR: referenced source file is missing' "$TMP_DIR/real-missing.err" \
  'real missing-file diagnostic is absent'

LOG_DIR="$TMP_DIR/logs"
FAKE_ROOT="$TMP_DIR/fake cases"
mkdir "$LOG_DIR" "$FAKE_ROOT"

cat > "$LOG_DIR/luatex.log" <<'LOG'
This is LuaTeX, Version 1.17.0
Output written on presentation.pdf (17 pages, 12345 bytes).
LOG
cat > "$LOG_DIR/underfull.log" <<'LOG'
This is LuaHBTeX, Version 1.17.0
Underfull \hbox (badness 10000) in paragraph at lines 1--2
Underfull \vbox (badness 10000) has occurred while \output is active
Output written on presentation.pdf (4 pages, 12345 bytes).
LOG
cat > "$LOG_DIR/unknown-pages.log" <<'LOG'
This is LuaTeX, Version 1.17.0
LOG
cat > "$LOG_DIR/overfull.log" <<'LOG'
This is LuaHBTeX, Version 1.17.0
Overfull \hbox (12.0pt too wide) in paragraph at lines 10--12
Output written on presentation.pdf (2 pages, 12345 bytes).
LOG
cat > "$LOG_DIR/rerun.log" <<'LOG'
This is LuaTeX, Version 1.17.0
LaTeX Warning: Label(s) may have changed. Rerun to get cross-references right.
Output written on presentation.pdf (2 pages, 12345 bytes).
LOG
cat > "$LOG_DIR/generic-failure.log" <<'LOG'
This is LuaHBTeX, Version 1.17.0
! Emergency stop.
LOG
cat > "$LOG_DIR/wrong-engine.log" <<'LOG'
This is pdfTeX, Version 3.141592653
Output written on presentation.pdf (1 page, 1 byte).
LOG

setup_fake_case() {
  CASE_DIR="$FAKE_ROOT/$1"
  CASE_BIN="$CASE_DIR/bin"
  CASE_DECK="$CASE_DIR/deck with spaces"
  mkdir -p "$CASE_BIN" "$CASE_DECK"
  printf '\\documentclass{article}\n\\begin{document}x\\end{document}\n' > "$CASE_DECK/presentation.tex"
  cat > "$CASE_BIN/latexmk" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$FAKE_ARGS"
last=
for argument in "$@"; do last=$argument; done
job=${last%.tex}
if [ "${FAKE_CREATE_LOG:-1}" = 1 ]; then cp "$FAKE_LOG" "$job.log"; fi
if [ "${FAKE_CREATE_PDF:-1}" = 1 ]; then : > "$job.pdf"; fi
exit "${FAKE_STATUS:-0}"
SCRIPT
  cat > "$CASE_BIN/lualatex" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
  chmod +x "$CASE_BIN/latexmk" "$CASE_BIN/lualatex"
}

run_fake_case() {
  PATH="$CASE_BIN:/usr/bin:/bin" \
    FAKE_LOG="$2" \
    FAKE_ARGS="$CASE_DIR/latexmk.args" \
    FAKE_CREATE_LOG="${3:-1}" \
    FAKE_CREATE_PDF="${4:-1}" \
    FAKE_STATUS="${5:-0}" \
    "$SCRIPT" "$CASE_DECK/presentation.tex"
}

setup_fake_case 'exact arguments'
output=$(run_fake_case 'exact arguments' "$ROOT_DIR/tests/fixtures/good.log")
cat > "$CASE_DIR/expected.args" <<'ARGS'
-lualatex
-norc
-interaction=nonstopmode
-halt-on-error
-file-line-error
presentation.tex
ARGS
cmp "$CASE_DIR/expected.args" "$CASE_DIR/latexmk.args" >/dev/null || \
  fail 'latexmk did not receive the exact mandatory arguments'
[[ "$output" == *"Pages: 3"* ]] || fail 'LuaHBTeX fixture did not report three pages'

setup_fake_case 'page extraction'
output=$(run_fake_case 'page extraction' "$LOG_DIR/luatex.log")
[[ "$output" == *"Pages: 17"* ]] || fail 'page extraction did not report 17 pages'

setup_fake_case 'underfull count'
output=$(run_fake_case 'underfull count' "$LOG_DIR/underfull.log")
[[ "$output" == *"Underfull box warnings: 2"* ]] || fail 'underfull count did not report two warnings'

setup_fake_case 'unknown pages'
output=$(run_fake_case 'unknown pages' "$LOG_DIR/unknown-pages.log")
[[ "$output" == *"Pages: unknown"* ]] || fail 'missing page record did not report unknown'

setup_fake_case 'undefined references'
if run_fake_case 'undefined references' "$ROOT_DIR/tests/fixtures/warnings.log" \
    >"$CASE_DIR/verify.out" 2>"$CASE_DIR/verify.err"; then
  fail 'undefined-reference fixture should fail verification'
fi
assert_line 'ERROR: undefined citation or reference remains' "$CASE_DIR/verify.err" \
  'undefined-reference diagnostic is absent'

setup_fake_case 'overfull box'
if run_fake_case 'overfull box' "$LOG_DIR/overfull.log" \
    >"$CASE_DIR/verify.out" 2>"$CASE_DIR/verify.err"; then
  fail 'overfull box should fail verification'
fi
assert_line 'ERROR: meaningful overfull box warning remains' "$CASE_DIR/verify.err" \
  'overfull-box diagnostic is absent'

setup_fake_case 'rerun request'
if run_fake_case 'rerun request' "$LOG_DIR/rerun.log" \
    >"$CASE_DIR/verify.out" 2>"$CASE_DIR/verify.err"; then
  fail 'rerun request should fail verification'
fi
assert_line 'ERROR: unresolved rerun request remains' "$CASE_DIR/verify.err" \
  'rerun-request diagnostic is absent'

setup_fake_case 'wrong engine'
if run_fake_case 'wrong engine' "$LOG_DIR/wrong-engine.log" \
    >"$CASE_DIR/verify.out" 2>"$CASE_DIR/verify.err"; then
  fail 'pdfTeX fixture should fail verification'
fi
assert_line 'ERROR: build log does not identify LuaTeX or LuaHBTeX' "$CASE_DIR/verify.err" \
  'wrong-engine diagnostic is absent'

setup_fake_case 'absent log'
if run_fake_case 'absent log' /dev/null 0 1 \
    >"$CASE_DIR/verify.out" 2>"$CASE_DIR/verify.err"; then
  fail 'absent build log should fail verification'
fi
assert_line 'ERROR: build log was not created' "$CASE_DIR/verify.err" 'absent-log diagnostic is missing'

setup_fake_case 'absent PDF'
if run_fake_case 'absent PDF' "$ROOT_DIR/tests/fixtures/good.log" 1 0 \
    >"$CASE_DIR/verify.out" 2>"$CASE_DIR/verify.err"; then
  fail 'absent PDF should fail verification'
fi
assert_line 'ERROR: PDF was not created' "$CASE_DIR/verify.err" 'absent-PDF diagnostic is missing'

setup_fake_case 'generic failure'
if run_fake_case 'generic failure' "$LOG_DIR/generic-failure.log" 1 0 9 \
    >"$CASE_DIR/verify.out" 2>"$CASE_DIR/verify.err"; then
  fail 'unclassified latexmk failure should fail verification'
fi
assert_line 'ERROR: LuaLaTeX build failed (latexmk exit status 9)' "$CASE_DIR/verify.err" \
  'generic build-failed diagnostic is absent'

printf 'Deck verification tests passed.\n'
