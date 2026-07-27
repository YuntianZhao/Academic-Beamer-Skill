# Quality Checklist

## Required

- Bundled `presentation.sty` is used.
- Only supported template options are used.
- No unreplaced placeholders remain.
- `latexmk -lualatex` succeeds and the log identifies LuaTeX or LuaHBTeX.
- No unresolved citations or references remain.
- No source asset is missing.
- No meaningful overfull box warning remains.
- Claims, results, citations, and attribution match supplied sources.

## When Visual Inspection Is Available

- Every slide image has been inspected.
- No clipping, overlap, distortion, unreadable text, or unintended blank page remains.
- Visual verification status is included in the completion report.

## Completion Report

Report source path, PDF path, page count, selected options, LuaLaTeX build status
and the LuaTeX or LuaHBTeX engine found in the log, remaining meaningful
warnings, visual-review status, and assumptions.
