# Migrate Evaluation

## Setup

Place a small Madrid-theme deck and its bibliography in `legacy/`.

## Prompt

Use academic-beamer to migrate legacy/presentation.tex into a separate bundled-
template project while preserving figures and citations.

## Pass Criteria

- Creates a separate destination and leaves `legacy/` unchanged.
- Uses the bundled `presentation.sty` and only its supported options.
- Preserves source claims, figures, citation keys, and attribution.
- Compiles with LuaLaTeX through `verify-deck.sh` and reports any migration
  blocker precisely.

## Failure Criteria

- Overwriting the legacy source without explicit approval.
- Losing or inventing source material.
- Using pdfLaTeX or XeLaTeX as a skill-runtime substitute for LuaLaTeX.
- Switching to another theme while the skill is active.
