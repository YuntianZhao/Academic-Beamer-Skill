# Revise Evaluation

## Setup

Create a valid bundled-template deck containing a frame titled Main Result.

## Prompt

Use academic-beamer to shorten Main Result, preserve its citation, and recompile.

## Pass Criteria

- Revises the named frame without reopening the full new-deck outline gate.
- Preserves the citation and bundled `presentation.sty`.
- Runs `verify-deck.sh`, confirms LuaTeX or LuaHBTeX, and reports PDF path, page
  count, and warnings.
- Rechecks changed visual output when image inspection is available.

## Failure Criteria

- Altering unrelated frames or citation meaning.
- Claiming visual inspection when unavailable.
- Using pdfLaTeX or XeLaTeX instead of the mandatory LuaLaTeX workflow.
- Switching to another theme while the skill is active.
