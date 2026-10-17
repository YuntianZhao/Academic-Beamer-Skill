#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ASSET_DIR="$ROOT_DIR/academic-beamer/assets/template"
VERIFY="$ROOT_DIR/academic-beamer/scripts/verify-deck.sh"
BUILD_DIR="$ROOT_DIR/.test-tmp/build-matrix"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

build_variant() {
  local fontsize=$1
  local aspectratio=$2
  local mode=$3
  local job="presentation_${fontsize}_${aspectratio}_${mode}"
  local output="$BUILD_DIR/$job"
  mkdir "$output"
  cat > "$output/$job.tex" <<EOF
\\newcommand{\\presentationfontsize}{$fontsize}
\\newcommand{\\presentationaspectratio}{$aspectratio}
\\newcommand{\\presentationmode}{$mode}
\\input{$ASSET_DIR/presentation.tex}
EOF
  TEXINPUTS="$ASSET_DIR:" latexmk -lualatex -interaction=nonstopmode -halt-on-error \
    -file-line-error -outdir="$output" "$output/$job.tex"
  rg --quiet '^This is Lua(HB)?TeX(?:,| |$)' "$output/$job.log"
}

for fontsize in 10pt 11pt 12pt; do
  for aspectratio in 43 1610 169; do
    build_variant "$fontsize" "$aspectratio" light
  done
done
for aspectratio in 43 1610 169; do
  build_variant 12pt "$aspectratio" dark
done

RICH_DIR="$BUILD_DIR/rich-content"
mkdir "$RICH_DIR"
cp "$ASSET_DIR/presentation.sty" "$RICH_DIR/presentation.sty"
python3 - "$RICH_DIR/figure.png" <<'PY'
import pathlib
import struct
import sys
import zlib

path = pathlib.Path(sys.argv[1])
raw = b"\x00" + b"\x09\x69\xda" * 20


def chunk(kind, data):
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", 20, 1, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(raw))
png += chunk(b"IEND", b"")
path.write_bytes(png)
PY
cat > "$RICH_DIR/references.bib" <<'EOF'
@article{sample2026,
  author = {Example, Alice},
  title = {A Reproducible Academic Result},
  journaltitle = {Journal of Examples},
  date = {2026}
}
EOF
# Keep listings on their own slide so template typography changes do not
# turn the rich-content compatibility fixture into an overcrowded slide.
cat > "$RICH_DIR/presentation.tex" <<'EOF'
\providecommand{\presentationaspectratio}{169}
\providecommand{\presentationmode}{light}
\providecommand{\presentationfontsize}{12pt}
\edef\presentationclassoptions{\presentationfontsize,aspectratio=\presentationaspectratio,xcolor={dvipsnames},usepdftitle=false}
\expandafter\documentclass\expandafter[\presentationclassoptions]{beamer}
\usepackage[light,pagenumbers]{presentation}
\addbibresource{references.bib}
\title{Fixture Deck}
\author{Test Author}
\date{2026}
\begin{document}
\frame{\titlepage}
\begin{frame}
  \frametitle{Result patterns}
  Evidence follows \parencite{sample2026}.
  \begin{equation*} y=\alpha+\beta x+\varepsilon \end{equation*}
  \begin{columns}[T,onlytextwidth]
    \begin{column}{0.47\textwidth}
      \includegraphics[width=\textwidth,height=8mm]{figure.png}
    \end{column}
    \begin{column}{0.47\textwidth}
      \begin{tabular}{lr}\toprule Case & Value\\\midrule A & 1\\B & 2\\\bottomrule\end{tabular}
    \end{column}
  \end{columns}
\end{frame}
\begin{frame}[fragile]
  \frametitle{Code listing}
  \begin{lstlisting}[language=Python]
value = 1
  \end{lstlisting}
\end{frame}
\begin{frame}[allowframebreaks]
  \frametitle{References}
  \printbibliography[heading=none]
\end{frame}
\end{document}
EOF
"$VERIFY" "$RICH_DIR/presentation.tex"

printf 'LuaLaTeX build matrix passed.\n'
