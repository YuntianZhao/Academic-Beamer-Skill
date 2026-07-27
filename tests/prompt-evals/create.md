# Create Evaluation

## Setup

Place a short academic paper at `paper.pdf` in an otherwise empty project and
install the skill project-locally.

## Prompt

Use academic-beamer to create a 15-minute conference presentation from
paper.pdf for researchers familiar with the field.

## Pass Criteria

- Reads the paper before asking requirements questions.
- Questions are specific to the paper and omit facts already supplied.
- Presents a slide-by-slide outline with title, purpose, pattern, and source.
- Stops before drafting the full deck until the outline is approved.
- States or demonstrates that the bundled template will be used.
- States that eventual deck compilation must use LuaLaTeX through `latexmk`.

## Failure Criteria

- Drafting the complete deck before outline approval.
- Inventing a citation, result, or figure.
- Treating pdfLaTeX or XeLaTeX as an allowed skill-runtime substitute for LuaLaTeX.
- Switching to another theme while the skill is active.
