#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT="$ROOT_DIR/academic-beamer/scripts/create-deck.sh"
ASSET_DIR="$ROOT_DIR/academic-beamer/assets/template"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-create.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[ -x "$SCRIPT" ] || fail 'create-deck.sh is missing or not executable'

INSTALL_DIR="$TMP_DIR/installed skill with spaces/academic-beamer"
mkdir -p "$INSTALL_DIR/scripts" "$INSTALL_DIR/assets"
cp "$SCRIPT" "$INSTALL_DIR/scripts/create-deck.sh"
cp -R "$ASSET_DIR" "$INSTALL_DIR/assets/template"

mkdir "$TMP_DIR/unrelated working directory"
mkdir "$TMP_DIR/no-network-bin"
for command in curl wget git gh; do
  cat > "$TMP_DIR/no-network-bin/$command" <<'EOF'
#!/usr/bin/env bash
printf 'FAIL: network command invoked: %s\n' "${0##*/}" >&2
exit 99
EOF
  chmod +x "$TMP_DIR/no-network-bin/$command"
done

output=$(
  cd "$TMP_DIR/unrelated working directory"
  PATH="$TMP_DIR/no-network-bin:$PATH" \
    "$INSTALL_DIR/scripts/create-deck.sh" "$TMP_DIR/deck with spaces"
)
for file in presentation.sty presentation.tex references.bib LICENSE.txt; do
  [ -f "$TMP_DIR/deck with spaces/$file" ] || fail "$file was not copied"
  cmp "$ASSET_DIR/$file" "$TMP_DIR/deck with spaces/$file" >/dev/null || fail "$file differs from bundled asset"
done
[[ "$output" == *"v1.0.0"* ]] || fail 'output does not report template version'

if ! (
  cd "$TMP_DIR/unrelated working directory"
  "$SCRIPT" -leading-dash-deck
) >"$TMP_DIR/leading-dash.out" 2>"$TMP_DIR/leading-dash.err"; then
  fail 'leading-dash target should be created'
fi
for file in presentation.sty presentation.tex references.bib LICENSE.txt; do
  [ -f "$TMP_DIR/unrelated working directory/-leading-dash-deck/$file" ] || fail "$file was not copied to leading-dash target"
done

printf 'user content\n' > "$TMP_DIR/deck with spaces/presentation.tex"
if "$SCRIPT" "$TMP_DIR/deck with spaces" >"$TMP_DIR/repeat.out" 2>"$TMP_DIR/repeat.err"; then
  fail 'repeat invocation should refuse overwrite'
fi
[ "$(cat "$TMP_DIR/deck with spaces/presentation.tex")" = 'user content' ] || fail 'existing file was changed'

mkdir "$TMP_DIR/partial deck"
printf 'existing bibliography\n' > "$TMP_DIR/partial deck/references.bib"
if "$SCRIPT" "$TMP_DIR/partial deck" >"$TMP_DIR/partial.out" 2>"$TMP_DIR/partial.err"; then
  fail 'invocation should refuse any existing runtime file'
fi
[ "$(cat "$TMP_DIR/partial deck/references.bib")" = 'existing bibliography' ] || fail 'existing runtime file was changed'
for file in presentation.sty presentation.tex LICENSE.txt; do
  [ ! -e "$TMP_DIR/partial deck/$file" ] || fail "$file was copied before overwrite refusal"
done

mkdir "$TMP_DIR/dangling symlink deck"
ln -s "$TMP_DIR/missing symlink target/presentation.tex" "$TMP_DIR/dangling symlink deck/presentation.tex"
if "$SCRIPT" "$TMP_DIR/dangling symlink deck" >"$TMP_DIR/symlink.out" 2>"$TMP_DIR/symlink.err"; then
  fail 'dangling destination symlink should refuse overwrite'
fi
[ -L "$TMP_DIR/dangling symlink deck/presentation.tex" ] || fail 'dangling destination symlink was changed'
for file in presentation.sty references.bib LICENSE.txt; do
  [ ! -e "$TMP_DIR/dangling symlink deck/$file" ] || fail "$file was copied before symlink refusal"
done

if "$SCRIPT" "$TMP_DIR/missing-parent/deck" >"$TMP_DIR/parent.out" 2>"$TMP_DIR/parent.err"; then
  fail 'missing parent should fail'
fi
[ ! -e "$TMP_DIR/missing-parent" ] || fail 'missing parent was created'

printf 'Deck creation tests passed.\n'
