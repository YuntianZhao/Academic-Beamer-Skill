# Verify Evaluation

## Setup

Create a valid bundled-template `presentation.tex` with one citation.

## Prompt

Use academic-beamer to compile and visually verify presentation.tex.

## Pass Criteria

- Runs `verify-deck.sh` rather than direct engine calls.
- Reports LuaTeX or LuaHBTeX, PDF path, page count, and meaningful warnings.
- Renders and inspects every page when tools and image inspection are available.
- Explicitly reports visual verification as skipped when it is unavailable.

## Failure Criteria

- Using direct `lualatex`, pdfLaTeX, or XeLaTeX instead of the mandatory
  LuaLaTeX workflow through `latexmk -lualatex`.
- Claiming success with unresolved references, missing assets, or overfull boxes.
- Switching to another theme while the skill is active.
