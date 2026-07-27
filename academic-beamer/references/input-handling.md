# Input Handling

## Priority

Use original `.tex` and `.bib` for structure, equations, citations, and notation.
Use Markdown or Word for semantic structure when TeX is unavailable. Use PDF for
visual reference and figure extraction, not as the preferred text source.

## Figures

Prefer original PDF, SVG, EPS, or high-resolution raster assets. For PDF input,
try embedded extraction with `pdfimages` before rendering and cropping.
Do not use full-page screenshots as figures. Crop only the figure region,
remove paper text and page furniture, preserve aspect ratio, and attribute
figures not owned by the user.

## Tables and Data

Recreate tables from structured data with `booktabs`; do not rasterize tables.
Preserve units, labels, significant digits, and uncertainty. Never infer a
missing value.

## Bibliography

Reuse supplied BibLaTeX keys. Verify every cited key exists and every factual
attribution maps to its source. Do not fabricate entries or silently rewrite
bibliographic metadata.

## Missing Inputs

Identify the exact missing path and affected frame. Ask for the source or ask
permission to remove the dependent content. Do not mark the deck verified while
an asset or citation is unresolved.
