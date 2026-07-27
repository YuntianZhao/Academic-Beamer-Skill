---
name: academic-beamer
description: >
  Use when creating, revising, migrating, compiling, or visually reviewing
  academic LaTeX Beamer presentations for research talks, seminars, lectures,
  conference presentations, thesis defenses, or slide decks based on local
  papers, notes, figures, bibliography files, data, or existing TeX where the
  bundled template is mandatory and must not be replaced by another Beamer theme.
license: MIT for skill code; bundled template is LPPL-1.3c. See license files.
compatibility: Requires latexmk and LuaLaTeX; visual review additionally requires pdftoppm or an equivalent PDF renderer.
metadata:
  upstream-template: https://github.com/YuntianZhao/Beamer-Template
---

# Academic Beamer

Create, revise, migrate, compile, and review academic presentations with the
bundled minimalist Beamer template.

## Template Contract

Once this skill is invoked, the bundled template is mandatory. Copy or preserve
`assets/template/presentation.sty`. Do not switch to Madrid, Metropolis, a
university theme, a user-provided theme, or another design system.

Supported choices are:

- Font size: `10pt`, `11pt`, or `12pt`.
- Aspect ratio: `43`, `1610`, or `169`.
- Mode: `light` or `dark`.
- Page numbers: `pagenumbers` or `nopagenumbers`.

Use the starter's upstream defaults when the user has no preference.

## Workflow

1. Classify the request as create, revise, migrate, or verify.
2. Read relevant local source files before asking questions. See
   `references/input-handling.md`.
3. Preserve claims, notation, citations, numerical results, and attribution.
   Never invent evidence, references, or data.
4. Ask only for requirements not inferable from the inputs: purpose, audience,
   duration, language, title metadata, emphasis, and supported template options.
5. For a new full deck, the pre-approval response must include:
   - A slide-by-slide outline with each frame's title, purpose, content pattern,
     and source material.
   - `Build (REQUIRED): The approved deck will be compiled with LuaLaTeX through
     latexmk -lualatex.`
   Do not draft the complete deck until the user approves. Targeted revisions
   and verification skip this gate.
6. For a new deck, run `scripts/create-deck.sh <target-directory>`. For migration,
   create a separate destination unless the user explicitly chooses otherwise.
7. Author or revise content using `references/content-patterns.md` and
   `references/authoring-guide.md`. Preserve user filenames and organization.
8. Run `scripts/verify-deck.sh <tex-file>`. Fix source errors and rerun until the
   build passes or a concrete external blocker remains.
9. When rendering and image inspection are available, run
   `scripts/render-slides.sh <pdf-file> <output-directory>` and follow
   `references/visual-review.md` for every slide. Fix defects and repeat.
10. Apply user feedback by frame title or page number, then recompile and reinspect
    affected and nearby slides.
11. Apply `references/quality-checklist.md` before reporting completion.

## Authoring Contract

- Keep one primary message per frame and prefer sparse, readable slides.
- Use the bundled list, column, equation, figure, table, theorem, code,
  bibliography, and backup-slide patterns.
- Use `singlespace` only as a local density escape hatch.
- Use frame breaking only for genuinely long references, code, tables, or
  derivations.
- Do not hide overflow with `\tiny`, arbitrary negative spacing, or global style
  changes.
- Prefer original TeX, vector figures, and structured data over screenshots.
- Do not use a full-page paper screenshot as an extracted figure.

## Build Contract

Build with:

```sh
latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error presentation.tex
```

Do not replace this with direct `lualatex` calls, pdfLaTeX, or XeLaTeX. Confirm
that the log identifies LuaTeX or LuaHBTeX. Resolve compilation errors, missing
files, undefined citations or references, meaningful overfull boxes, and
unresolved rerun requests.

If required build tools are absent, do not install system packages automatically.
Explain the blocker. Continue with uncompiled source only if the user agrees, and
state clearly that mandatory LuaLaTeX compilation or visual verification was
skipped.

## Completion Report

Report source path, PDF path, page count, selected template options, LuaLaTeX
compilation status, remaining meaningful warnings, visual-review status, and
assumptions that still require user review.
