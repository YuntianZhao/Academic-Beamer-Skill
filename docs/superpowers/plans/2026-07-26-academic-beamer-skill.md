# Academic Beamer Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a portable Agent Skill that creates, revises,
compiles with mandatory LuaLaTeX through `latexmk`, and visually checks academic
Beamer decks using the mandatory bundled minimalist template.

**Architecture:** Keep the installable skill self-contained under `academic-beamer/`, with concise workflow instructions, progressively loaded references, deterministic runtime scripts, and vendored release assets. Keep repository-only tests, provenance, synchronization automation, and contributor documentation outside the package so they do not enter an agent's runtime context.

**Tech Stack:** Agent Skills `SKILL.md`, Markdown, POSIX-oriented Bash, LaTeX Beamer, LuaLaTeX, `latexmk`, `biber`, Poppler (`pdfinfo`, `pdftoppm`), GitHub Actions, GitHub CLI, `skills-ref`, JSON.

## Global Constraints

- Work in `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill`.
- The installable package directory and skill name are both `academic-beamer`.
- Once invoked, the skill must use the bundled `presentation.sty`; another theme is not an allowed fallback.
- Runtime deck creation must not require network access.
- The mandatory build command is `latexmk -lualatex`; direct engine calls,
  pdfLaTeX, and XeLaTeX are forbidden skill-runtime substitutes.
- Confirm from the `.log` file that LuaTeX or LuaHBTeX was the selected engine.
- pdfLaTeX and XeLaTeX compatibility belong only to the separate upstream
  Beamer-Template release-readiness plan and checks; do not modify that plan.
- New full decks require explicit outline approval; targeted revisions and verification do not.
- Visual inspection is required when PDF rendering and multimodal image inspection are available, and explicitly reported as skipped otherwise.
- Runtime scripts must support paths containing spaces and refuse destructive overwrites.
- Original skill code and documentation use MIT; vendored template files retain LPPL-1.3c.
- Import template assets only from a reviewed `YuntianZhao/Beamer-Template` GitHub release.
- Do not include upstream tests, the comprehensive demonstration deck, or generated PDFs in the skill package.
- Commit, push, or create a GitHub repository or pull request only when the user explicitly requests that action.

---

### Task 1: Scaffold the Repository and Portable Skill Metadata

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/.gitignore`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/LICENSE`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/AGENTS.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/SKILL.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_skill_metadata.sh`

**Interfaces:**
- Consumes: Agent Skills specification at `https://agentskills.io/specification`.
- Produces: valid skill identity `academic-beamer`, portable `latexmk` plus
  LuaLaTeX compatibility metadata, and repository-wide implementation
  instructions consumed by every later task.

- [ ] **Step 1: Initialize the local repository without committing**

Run:

```sh
git init
mkdir -p academic-beamer/assets/template academic-beamer/references academic-beamer/scripts tests/fixtures tests/prompt-evals .github/workflows
```

Expected: `.git/` and all package/test/workflow directories exist. Do not create a commit.

- [ ] **Step 2: Write the failing metadata test**

Create `tests/test_skill_metadata.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SKILL_FILE="$ROOT_DIR/academic-beamer/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[ -f "$SKILL_FILE" ] || fail 'academic-beamer/SKILL.md is missing'
rg --fixed-strings --quiet 'name: academic-beamer' "$SKILL_FILE" || fail 'skill name is missing'
rg --fixed-strings --quiet 'bundled template is mandatory' "$SKILL_FILE" || fail 'mandatory template contract is missing'
rg --fixed-strings --quiet 'compatibility: Requires latexmk and LuaLaTeX' "$SKILL_FILE" || fail 'LuaLaTeX compatibility prerequisite is missing'
rg --fixed-strings --quiet 'latexmk -lualatex' "$SKILL_FILE" || fail 'LuaLaTeX latexmk workflow is missing'
if rg --quiet '^(argument-hint|allowed-tools|disable-model-invocation):' "$SKILL_FILE"; then
  fail 'SKILL.md contains harness-specific frontmatter'
fi

printf 'Skill metadata checks passed.\n'
```

- [ ] **Step 3: Run the test and confirm it fails**

Run:

```sh
bash tests/test_skill_metadata.sh
```

Expected: nonzero exit with `academic-beamer/SKILL.md is missing`.

- [ ] **Step 4: Create the initial `SKILL.md` contract**

Create `academic-beamer/SKILL.md`:

````markdown
---
name: academic-beamer
description: >
  Create, revise, compile, and visually review academic LaTeX Beamer
  presentations using the bundled minimalist template. Use for research talks,
  seminars, lectures, conference presentations, thesis defenses, and slide
  decks based on local papers, notes, figures, bibliography files, data, or
  existing TeX. When this skill is invoked, the bundled template is mandatory
  and must not be replaced by another Beamer theme.
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
5. For a new full deck, present a slide-by-slide outline with each frame's title,
   purpose, content pattern, and source material. Do not draft the complete deck
   until the user approves. Targeted revisions and verification skip this gate.
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
````

- [ ] **Step 5: Add repository basics**

Create `.gitignore`:

```gitignore
.DS_Store
*.aux
*.bbl
*.bcf
*.blg
*.fdb_latexmk
*.fls
*.log
*.nav
*.out
*.run.xml
*.snm
*.synctex.gz
*.toc
*.vrb
output/
.test-tmp/
```

Create `LICENSE`:

```text
MIT License

Copyright (c) 2026 Yuntian Zhao

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Create `AGENTS.md`:

````markdown
# AGENTS.md

## Package Boundary

`academic-beamer/` is the installable Agent Skill. Keep repository tests,
workflows, plans, and contributor documentation outside that directory.

## Required Checks

Run all repository checks from the root:

```sh
bash tests/run_all.sh
```

Runtime deck verification must use `latexmk -lualatex` and confirm LuaTeX or
LuaHBTeX in the log. Do not substitute direct engine calls, pdfLaTeX, or
XeLaTeX. Generated test files belong under ignored temporary directories.

## Template Updates

Import only tagged releases from `YuntianZhao/Beamer-Template`. Never hand-edit
vendored `presentation.sty`; update it through the synchronization workflow.
````

- [ ] **Step 6: Validate metadata**

Run:

```sh
bash tests/test_skill_metadata.sh
python3 -m pip install skills-ref
skills-ref validate academic-beamer
```

Expected: both commands exit zero and `skills-ref` reports a valid skill.

- [ ] **Step 7: Conditionally commit the scaffold**

Only if the user explicitly requested commits:

```sh
git add .gitignore LICENSE AGENTS.md academic-beamer/SKILL.md tests/test_skill_metadata.sh docs/superpowers
git commit -m "feat: scaffold academic beamer skill"
```

### Task 2: Add Progressive Authoring References

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/references/input-handling.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/references/content-patterns.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/references/authoring-guide.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/references/visual-review.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/references/quality-checklist.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_references.sh`

**Interfaces:**
- Consumes: links in `academic-beamer/SKILL.md` and demonstrated patterns in upstream `presentation.tex`.
- Produces: focused, progressively loaded guidance used by create, revise, migrate, and verify workflows.

- [ ] **Step 1: Write the failing reference integrity test**

Create `tests/test_references.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REF_DIR="$ROOT_DIR/academic-beamer/references"

for file in input-handling.md content-patterns.md authoring-guide.md visual-review.md quality-checklist.md; do
  [ -s "$REF_DIR/$file" ] || { printf 'FAIL: missing %s\n' "$file" >&2; exit 1; }
  rg --fixed-strings --quiet "references/$file" "$ROOT_DIR/academic-beamer/SKILL.md" || {
    printf 'FAIL: SKILL.md does not reference %s\n' "$file" >&2
    exit 1
  }
done

rg --fixed-strings --quiet 'Do not use full-page screenshots' "$REF_DIR/input-handling.md"
rg --fixed-strings --quiet '\begin{columns}[T,onlytextwidth]' "$REF_DIR/content-patterns.md"
rg --fixed-strings --quiet 'One primary message per frame' "$REF_DIR/authoring-guide.md"
rg --fixed-strings --quiet 'Inspect every rendered slide' "$REF_DIR/visual-review.md"
rg --fixed-strings --quiet 'No unresolved citations or references' "$REF_DIR/quality-checklist.md"

printf 'Reference integrity checks passed.\n'
```

- [ ] **Step 2: Run the test and confirm it fails**

Run `bash tests/test_references.sh`.

Expected: nonzero exit naming the first missing reference file.

- [ ] **Step 3: Create `input-handling.md`**

Include these exact sections and rules:

```markdown
# Input Handling

## Priority

Use original `.tex` and `.bib` for structure, equations, citations, and notation.
Use Markdown or Word for semantic structure when TeX is unavailable. Use PDF for
visual reference and figure extraction, not as the preferred text source.

## Figures

Prefer original PDF, SVG, EPS, or high-resolution raster assets. For PDF input,
try embedded extraction with `pdfimages` before rendering and cropping. Do not
use full-page screenshots as figures. Crop only the figure region, remove paper
text and page furniture, preserve aspect ratio, and attribute figures not owned
by the user.

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
```

- [ ] **Step 4: Create `content-patterns.md`**

Create `academic-beamer/references/content-patterns.md`:

````markdown
# Content Patterns

Use only patterns supported by the bundled `presentation.sty`. Replace example
content, labels, paths, and citation keys with verified presentation material.

## Title and Section Heading

```tex
\frame{\titlepage}

\begin{frame}
  \heading{Section title}
\end{frame}
```

## List

```tex
\begin{frame}
  \frametitle{Motivation}
  \begin{itemize}
    \item First verified point
    \item Second verified point
    \item Implication for the research question
  \end{itemize}
\end{frame}
```

## Two Columns

```tex
\begin{frame}
  \frametitle{Comparison}
  \begin{columns}[T,onlytextwidth]
    \begin{column}{0.47\textwidth}
      Left-side content.
    \end{column}
    \begin{column}{0.47\textwidth}
      Right-side content.
    \end{column}
  \end{columns}
\end{frame}
```

## Equation

```tex
\begin{frame}
  \frametitle{Estimating equation}
  \begin{equation*}
    Y_{it}=\alpha_i+\lambda_t+\beta D_{it}+X_{it}'\gamma+\varepsilon_{it}
  \end{equation*}
  State the estimand and identifying variation directly below the equation.
\end{frame}
```

## Figure and Note

```tex
\begin{frame}
  \frametitle{Main pattern}
  \begin{figure}
    \centering
    \includegraphics[max width=.96\textwidth,max height=.70\textheight]{figures/result.pdf}
    \caption{Descriptive caption}
    \figurenote{Source and sample definition.}
  \end{figure}
\end{frame}
```

Preserve aspect ratio. Prefer vector originals. Do not use a full paper page as
the figure.

## Table

```tex
\begin{frame}
  \frametitle{Main estimates}
  \begin{tabular*}{\textwidth}{@{\extracolsep\fill}lrr}
    \toprule
    Specification & Estimate & Standard error\\
    \midrule
    Baseline & 0.18 & 0.04\\
    Controls & 0.15 & 0.05\\
    \bottomrule
  \end{tabular*}
\end{frame}
```

Use `booktabs`, no vertical rules, and preserve reported units and precision.

## Theorem

```tex
\begin{frame}
  \frametitle{Main result}
  \begin{theorem}[Identification]
    Under the stated assumptions, the target parameter is point identified.
  \end{theorem}
  State why the assumptions are credible in the application.
\end{frame}
```

## Code

```tex
\begin{frame}[fragile]
  \frametitle{Estimation step}
\begin{lstlisting}[language=Python]
model.fit(data)
estimate = model.effect()
\end{lstlisting}
\end{frame}
```

For long external code, use `\lstinputlisting` in an `allowframebreaks` frame.

## References

When the deck cites sources, add `\addbibresource{references.bib}` in the
preamble and add verified entries to the bundled bibliography file.

```tex
\begin{frame}[allowframebreaks=0.8]
  \frametitle{References}
  \footnotesize
  \printbibliography[heading=none]
\end{frame}
```

## Closing and Backup Navigation

```tex
\begin{frame}[label=mainResult]
  \frametitle{Main result}
  Result summary.
  \hyperlink{robustness}{\beamergotobutton{Robustness details}}
\end{frame}

\lastslide

\begin{frame}[label=robustness]
  \frametitle{Robustness details}
  Supporting analysis.
  \hyperlink{mainResult}{\beamergotobutton{Return to main result}}
\end{frame}
```

## Local Density Escape Hatch

Use `\begin{singlespace} ... \end{singlespace}` only around the content of one
dense frame. Keep the deck-wide spacing unchanged. Prefer splitting unrelated
messages before reducing spacing.
````

- [ ] **Step 5: Create `authoring-guide.md`**

Include:

```markdown
# Authoring Guide

## Narrative

Start from the audience's problem, establish only necessary background, present
the mechanism or evidence, then close with the result and implication. Allocate
slides from the requested duration, but prefer comprehension over a rigid quota.

## Density

One primary message per frame. Split competing messages. Prefer normal template
sizes; never use `\tiny` to conceal overflow. Use short prose, equations, figures,
or tables according to the content rather than forcing every frame into bullets.

## Fidelity

Define notation before use. Keep terms, units, equation symbols, citation keys,
and reported values consistent with the source. Mark interpretation separately
from reported evidence.

## Accessibility

Maintain contrast, do not rely on color alone, preserve image aspect ratios, and
keep captions and labels readable at presentation distance.

## Supported Options

Use only font sizes `10pt`, `11pt`, `12pt`; aspect ratios `43`, `1610`, `169`;
modes `light`, `dark`; and package options `pagenumbers`, `nopagenumbers`.
```

- [ ] **Step 6: Create `visual-review.md` and `quality-checklist.md`**

Create `academic-beamer/references/visual-review.md`:

```markdown
# Visual Review

Inspect every rendered slide in page order. Do not infer visual correctness from
a successful compile or an empty warning list.

For each slide, check:

- No text, equation, table, figure, block, or footline crosses an edge.
- No content overlaps another element or escapes a colored block.
- Text, labels, captions, code, and notes remain readable at presentation size.
- Figures preserve aspect ratio and have no accidental crop or paper-page border.
- Tables and equations fit without scaling text to an unreadable size.
- Foreground/background contrast is adequate and meaning does not rely on color alone.
- Columns, margins, titles, captions, and repeated slide types align consistently.
- The frame has one primary message and is not visually overloaded.
- No unintended blank, duplicate, or partially rendered page appears.

Record page number, issue, severity, and exact source fix. Rebuild after changes,
then reinspect changed pages and adjacent pages whose numbering or pagination may
have shifted. The intentional blank frame produced by `\lastslide` is allowed.
```

`quality-checklist.md` must separate required checks from capability-dependent
checks and contain this required list:

```markdown
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
```

- [ ] **Step 7: Run reference and skill validation**

Run:

```sh
bash tests/test_references.sh
skills-ref validate academic-beamer
```

Expected: both pass.

- [ ] **Step 8: Conditionally commit references**

Only if the user explicitly requested commits:

```sh
git add academic-beamer/references tests/test_references.sh
git commit -m "docs: add academic beamer workflow references"
```

### Task 3: Import the Initial Template Release and Track Provenance

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/assets/template/presentation.sty`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/assets/template/presentation.tex`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/assets/template/references.bib`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/assets/template/LICENSE.txt`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/assets/template/VERSION`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/template-source.json`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/THIRD_PARTY_LICENSES.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_provenance.sh`

**Interfaces:**
- Consumes: upstream GitHub release `v1.0.0` containing `presentation.sty`, `presentation-minimal.tex`, and `LICENSE.txt`.
- Produces: offline runtime assets, `VERSION` consumed by `create-deck.sh`, and checksummed provenance consumed by synchronization and CI.

- [ ] **Step 1: Confirm the upstream release exists**

Run:

```sh
gh release view v1.0.0 --repo YuntianZhao/Beamer-Template --json tagName,isDraft,isPrerelease
```

Expected: tag is `v1.0.0`, `isDraft` is false, and `isPrerelease` is false. If it does not exist, stop and complete the upstream release-readiness plan plus explicitly authorized release publication first.

- [ ] **Step 2: Write the failing provenance test**

Create `tests/test_provenance.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ASSET_DIR="$ROOT_DIR/academic-beamer/assets/template"
MANIFEST="$ROOT_DIR/template-source.json"

for file in presentation.sty presentation.tex references.bib LICENSE.txt VERSION; do
  [ -f "$ASSET_DIR/$file" ] || { printf 'FAIL: missing %s\n' "$file" >&2; exit 1; }
done

python3 - "$ROOT_DIR" <<'PY'
import hashlib
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
manifest = json.loads((root / "template-source.json").read_text())
version = (root / "academic-beamer/assets/template/VERSION").read_text().strip()
assert manifest["repository"] == "YuntianZhao/Beamer-Template"
assert manifest["release"] == version
assert re.fullmatch(r"[0-9a-f]{40}", manifest["source_commit"])
assert {item["source"] for item in manifest["files"]} == {
    "presentation.sty", "presentation-minimal.tex", "LICENSE.txt"
}
for item in manifest["files"]:
    path = root / item["destination"]
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    assert digest == item["sha256"], path
PY

printf 'Template provenance checks passed.\n'
```

- [ ] **Step 3: Run the provenance test and confirm it fails**

Run `bash tests/test_provenance.sh`.

Expected: nonzero exit naming `presentation.sty` as missing.

- [ ] **Step 4: Download the exact release assets**

Run:

```sh
mkdir -p .test-tmp/import-v1.0.0
gh release download v1.0.0 --repo YuntianZhao/Beamer-Template --dir .test-tmp/import-v1.0.0 --pattern presentation.sty --pattern presentation-minimal.tex --pattern LICENSE.txt
cp .test-tmp/import-v1.0.0/presentation.sty academic-beamer/assets/template/presentation.sty
cp .test-tmp/import-v1.0.0/presentation-minimal.tex academic-beamer/assets/template/presentation.tex
cp .test-tmp/import-v1.0.0/LICENSE.txt academic-beamer/assets/template/LICENSE.txt
```

Expected: exactly the three allowlisted upstream files are imported; no upstream tests or demonstration deck are copied.

- [ ] **Step 5: Add the skill-owned runtime files**

Create `academic-beamer/assets/template/references.bib` containing only:

```bibtex
% Add BibLaTeX entries used by presentation.tex here.
```

Create `academic-beamer/assets/template/VERSION` containing:

```text
v1.0.0
```

- [ ] **Step 6: Generate `template-source.json` from the imported bytes**

Run this Python command so no checksum or commit value is hand-entered:

```sh
python3 - <<'PY'
import hashlib
import json
import pathlib
import subprocess
from datetime import datetime, timezone

root = pathlib.Path.cwd()
asset_dir = root / "academic-beamer/assets/template"
ref = json.loads(subprocess.check_output([
    "gh", "api", "repos/YuntianZhao/Beamer-Template/git/ref/tags/v1.0.0"
]))
source_commit = ref["object"]["sha"]
if ref["object"]["type"] == "tag":
    tag = json.loads(subprocess.check_output([
        "gh", "api", f"repos/YuntianZhao/Beamer-Template/git/tags/{source_commit}"
    ]))
    source_commit = tag["object"]["sha"]

mapping = {
    "presentation.sty": "academic-beamer/assets/template/presentation.sty",
    "presentation-minimal.tex": "academic-beamer/assets/template/presentation.tex",
    "LICENSE.txt": "academic-beamer/assets/template/LICENSE.txt",
}
files = []
for source, destination in mapping.items():
    data = (root / destination).read_bytes()
    files.append({
        "source": source,
        "destination": destination,
        "sha256": hashlib.sha256(data).hexdigest(),
    })

manifest = {
    "repository": "YuntianZhao/Beamer-Template",
    "release": "v1.0.0",
    "source_commit": source_commit,
    "imported_at": datetime.now(timezone.utc).isoformat(),
    "files": files,
}
(root / "template-source.json").write_text(json.dumps(manifest, indent=2) + "\n")
PY
```

- [ ] **Step 7: Add third-party license documentation**

Create `THIRD_PARTY_LICENSES.md`:

```markdown
# Third-Party Licenses

## YuntianZhao/Beamer-Template

The files `academic-beamer/assets/template/presentation.sty` and
`academic-beamer/assets/template/presentation.tex` are imported from release
`v1.0.0` of <https://github.com/YuntianZhao/Beamer-Template> and distributed
under the LaTeX Project Public License, version 1.3c or later. The complete
license is bundled at `academic-beamer/assets/template/LICENSE.txt`.

Exact source paths, commit, and SHA-256 checksums are recorded in
`template-source.json`.
```

- [ ] **Step 8: Verify provenance and compile the imported starter**

Run:

```sh
bash tests/test_provenance.sh
mkdir -p .test-tmp/imported-starter
TEXINPUTS="$PWD/academic-beamer/assets/template:" latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error -outdir=.test-tmp/imported-starter academic-beamer/assets/template/presentation.tex
rg --quiet '^This is Lua(HB)?TeX(?:,| |$)' .test-tmp/imported-starter/presentation.log
```

Expected: provenance passes, starter compiles, and the log confirms LuaTeX or
LuaHBTeX.

- [ ] **Step 9: Conditionally commit vendored assets**

Only if the user explicitly requested commits:

```sh
git add academic-beamer/assets template-source.json THIRD_PARTY_LICENSES.md tests/test_provenance.sh
git commit -m "feat: vendor beamer template v1.0.0"
```

### Task 4: Implement Safe Deck Creation

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/scripts/create-deck.sh`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_create_deck.sh`

**Interfaces:**
- Consumes: `academic-beamer/assets/template/{presentation.sty,presentation.tex,references.bib,LICENSE.txt,VERSION}`.
- Produces: `create-deck.sh <target-directory>`, which creates four runtime files and prints the bundled release without overwriting existing files.

- [ ] **Step 1: Write creation tests first**

Create `tests/test_create_deck.sh` with isolated temporary directories and these assertions:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT="$ROOT_DIR/academic-beamer/scripts/create-deck.sh"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-create.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

[ -x "$SCRIPT" ] || fail 'create-deck.sh is missing or not executable'

output=$($SCRIPT "$TMP_DIR/deck with spaces")
for file in presentation.sty presentation.tex references.bib LICENSE.txt; do
  [ -f "$TMP_DIR/deck with spaces/$file" ] || fail "$file was not copied"
done
[[ "$output" == *"v1.0.0"* ]] || fail 'output does not report template version'

printf 'user content\n' > "$TMP_DIR/deck with spaces/presentation.tex"
if "$SCRIPT" "$TMP_DIR/deck with spaces" >"$TMP_DIR/repeat.out" 2>"$TMP_DIR/repeat.err"; then
  fail 'repeat invocation should refuse overwrite'
fi
[ "$(cat "$TMP_DIR/deck with spaces/presentation.tex")" = 'user content' ] || fail 'existing file was changed'

if "$SCRIPT" "$TMP_DIR/missing-parent/deck" >"$TMP_DIR/parent.out" 2>"$TMP_DIR/parent.err"; then
  fail 'missing parent should fail'
fi

printf 'Deck creation tests passed.\n'
```

- [ ] **Step 2: Run the test and confirm it fails**

Run `bash tests/test_create_deck.sh`.

Expected: nonzero exit with `create-deck.sh is missing or not executable`.

- [ ] **Step 3: Implement `create-deck.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <target-directory>\n' "${0##*/}" >&2
  exit 2
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ASSET_DIR="$SCRIPT_DIR/../assets/template"
TARGET_DIR=${1%/}
[ -n "$TARGET_DIR" ] || TARGET_DIR=/
PARENT_DIR=$(dirname "$TARGET_DIR")

if [ ! -d "$PARENT_DIR" ]; then
  printf 'ERROR: parent directory does not exist: %s\n' "$PARENT_DIR" >&2
  exit 1
fi

for file in presentation.sty presentation.tex references.bib LICENSE.txt; do
  if [ -e "$TARGET_DIR/$file" ]; then
    printf 'ERROR: refusing to overwrite %s\n' "$TARGET_DIR/$file" >&2
    exit 1
  fi
done

mkdir -p "$TARGET_DIR"
for file in presentation.sty presentation.tex references.bib LICENSE.txt; do
  cp "$ASSET_DIR/$file" "$TARGET_DIR/$file"
  printf 'Created %s\n' "$TARGET_DIR/$file"
done

printf 'Bundled template: %s\n' "$(tr -d '\r\n' < "$ASSET_DIR/VERSION")"
```

Make it executable:

```sh
chmod +x academic-beamer/scripts/create-deck.sh tests/test_create_deck.sh
```

- [ ] **Step 4: Run creation and starter build tests**

Run:

```sh
bash tests/test_create_deck.sh
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-build.XXXXXX")
academic-beamer/scripts/create-deck.sh "$tmp_dir/deck"
latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error -cd "$tmp_dir/deck/presentation.tex"
```

Expected: creation tests pass and the copied starter builds successfully.

- [ ] **Step 5: Conditionally commit deck creation**

Only if the user explicitly requested commits:

```sh
git add academic-beamer/scripts/create-deck.sh tests/test_create_deck.sh
git commit -m "feat: add safe deck creation script"
```

### Task 5: Implement LuaLaTeX Build and Log Verification

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/scripts/verify-deck.sh`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/fixtures/good.log`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/fixtures/warnings.log`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_verify_deck.sh`

**Interfaces:**
- Consumes: one existing `.tex` path, `latexmk`, `lualatex`, and the resulting `.log`.
- Produces: exit zero plus PDF/page/warning summary for a valid LuaTeX or LuaHBTeX
  deck; nonzero with an exact diagnostic for wrong engine, undefined
  references/citations, missing files, rerun requests, or overfull boxes.

- [ ] **Step 1: Create representative log fixtures**

`tests/fixtures/good.log`:

```text
This is LuaHBTeX, Version 1.17.0
Output written on presentation.pdf (3 pages, 12345 bytes).
```

`tests/fixtures/warnings.log`:

```text
This is LuaTeX, Version 1.17.0
LaTeX Warning: Citation 'missing' on page 2 undefined.
LaTeX Warning: There were undefined references.
Overfull \hbox (12.0pt too wide) in paragraph at lines 10--12
LaTeX Warning: Label(s) may have changed. Rerun to get cross-references right.
Output written on presentation.pdf (2 pages, 12345 bytes).
```

- [ ] **Step 2: Write the failing verification test**

Create `tests/test_verify_deck.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT="$ROOT_DIR/academic-beamer/scripts/verify-deck.sh"
CREATE="$ROOT_DIR/academic-beamer/scripts/create-deck.sh"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-verify.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -x "$SCRIPT" ] || fail 'verify-deck.sh is missing or not executable'

mkdir "$TMP_DIR/no-tools"
printf '\\documentclass{article}\n\\begin{document}x\\end{document}\n' > "$TMP_DIR/no-tools/presentation.tex"
if PATH="$TMP_DIR/no-tools" /bin/bash "$SCRIPT" "$TMP_DIR/no-tools/presentation.tex" >"$TMP_DIR/no-tools.out" 2>"$TMP_DIR/no-tools.err"; then
  fail 'missing latexmk should fail verification'
fi
rg --fixed-strings --quiet 'latexmk is required' "$TMP_DIR/no-tools.err" || fail 'missing-latexmk diagnostic is absent'

mkdir "$TMP_DIR/latexmk-only"
cat > "$TMP_DIR/latexmk-only/latexmk" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "$TMP_DIR/latexmk-only/latexmk"
if PATH="$TMP_DIR/latexmk-only" /bin/bash "$SCRIPT" "$TMP_DIR/no-tools/presentation.tex" >"$TMP_DIR/lualatex.out" 2>"$TMP_DIR/lualatex.err"; then
  fail 'missing lualatex should fail verification'
fi
rg --fixed-strings --quiet 'LuaLaTeX is required' "$TMP_DIR/lualatex.err" || fail 'missing-lualatex diagnostic is absent'

mkdir "$TMP_DIR/real deck"
$CREATE "$TMP_DIR/real deck/slides"
output=$($SCRIPT "$TMP_DIR/real deck/slides/presentation.tex")
[ -f "$TMP_DIR/real deck/slides/presentation.pdf" ] || fail 'real build did not create PDF'
[[ "$output" == *"Pages: 3"* ]] || fail 'real build did not report three pages'

mkdir "$TMP_DIR/fake-bin" "$TMP_DIR/fake-deck"
printf '\\documentclass{article}\n\\begin{document}x\\end{document}\n' > "$TMP_DIR/fake-deck/presentation.tex"
cat > "$TMP_DIR/fake-bin/latexmk" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
last=
for argument in "$@"; do last=$argument; done
job=${last%.tex}
cp "$FAKE_LOG" "$job.log"
: > "$job.pdf"
SCRIPT
cat > "$TMP_DIR/fake-bin/lualatex" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
chmod +x "$TMP_DIR/fake-bin/latexmk" "$TMP_DIR/fake-bin/lualatex"

output=$(PATH="$TMP_DIR/fake-bin:$PATH" FAKE_LOG="$ROOT_DIR/tests/fixtures/good.log" \
  $SCRIPT "$TMP_DIR/fake-deck/presentation.tex")
[[ "$output" == *"Pages: 3"* ]] || fail 'LuaHBTeX fixture did not pass verification'

if PATH="$TMP_DIR/fake-bin:$PATH" FAKE_LOG="$ROOT_DIR/tests/fixtures/warnings.log" \
    $SCRIPT "$TMP_DIR/fake-deck/presentation.tex" >"$TMP_DIR/warnings.out" 2>"$TMP_DIR/warnings.err"; then
  fail 'warning fixture should fail verification'
fi
rg --fixed-strings --quiet 'undefined citation or reference' "$TMP_DIR/warnings.err" || \
  fail 'undefined-reference diagnostic is missing'

printf 'This is pdfTeX, Version 3.141592653\nOutput written on presentation.pdf (1 page, 1 byte).\n' > "$TMP_DIR/wrong-engine.log"
if PATH="$TMP_DIR/fake-bin:$PATH" FAKE_LOG="$TMP_DIR/wrong-engine.log" \
    $SCRIPT "$TMP_DIR/fake-deck/presentation.tex" >"$TMP_DIR/wrong-engine.out" 2>"$TMP_DIR/wrong-engine.err"; then
  fail 'pdfTeX fixture should fail because pdfLaTeX is a forbidden skill-runtime substitute'
fi
rg --fixed-strings --quiet 'build log does not identify LuaTeX or LuaHBTeX' "$TMP_DIR/wrong-engine.err" || \
  fail 'wrong-engine diagnostic is missing'

printf 'Deck verification tests passed.\n'
```

- [ ] **Step 3: Run the test and confirm it fails**

Run `bash tests/test_verify_deck.sh`.

Expected: nonzero exit because `verify-deck.sh` is absent.

- [ ] **Step 4: Implement `verify-deck.sh`**

Implement these exact behaviors:

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <tex-file>\n' "${0##*/}" >&2
  exit 2
fi

TEX_PATH=$1
[ -f "$TEX_PATH" ] || { printf 'ERROR: TeX file not found: %s\n' "$TEX_PATH" >&2; exit 1; }
command -v latexmk >/dev/null 2>&1 || { printf 'ERROR: latexmk is required\n' >&2; exit 1; }
command -v lualatex >/dev/null 2>&1 || { printf 'ERROR: LuaLaTeX is required\n' >&2; exit 1; }

TEX_DIR=$(CDPATH= cd -- "$(dirname "$TEX_PATH")" && pwd)
TEX_NAME=$(basename "$TEX_PATH")
JOB_NAME=${TEX_NAME%.tex}

(
  cd "$TEX_DIR"
  latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error "$TEX_NAME"
)

LOG_PATH="$TEX_DIR/$JOB_NAME.log"
PDF_PATH="$TEX_DIR/$JOB_NAME.pdf"
[ -f "$LOG_PATH" ] || { printf 'ERROR: build log was not created\n' >&2; exit 1; }
[ -f "$PDF_PATH" ] || { printf 'ERROR: PDF was not created\n' >&2; exit 1; }

rg --quiet '^This is Lua(HB)?TeX(?:,| |$)' "$LOG_PATH" || {
  printf 'ERROR: build log does not identify LuaTeX or LuaHBTeX\n' >&2
  exit 1
}

if rg --ignore-case --quiet 'undefined citations?|undefined references?|Citation .* undefined|Reference .* undefined' "$LOG_PATH"; then
  printf 'ERROR: undefined citation or reference remains\n' >&2
  exit 1
fi
if rg --quiet 'LaTeX Warning: File .* not found|! LaTeX Error: File .* not found' "$LOG_PATH"; then
  printf 'ERROR: referenced source file is missing\n' >&2
  exit 1
fi
if rg --quiet 'Overfull \\[hv]box' "$LOG_PATH"; then
  printf 'ERROR: meaningful overfull box warning remains\n' >&2
  exit 1
fi
if rg --ignore-case --quiet 'Rerun to get|Label\(s\) may have changed|Please rerun' "$LOG_PATH"; then
  printf 'ERROR: unresolved rerun request remains\n' >&2
  exit 1
fi

PAGES=$(rg --only-matching 'Output written on .+ \([0-9]+ pages?' "$LOG_PATH" | rg --only-matching '[0-9]+ pages?' | rg --only-matching '[0-9]+' | tail -n 1)
UNDERFULL=$(rg --count 'Underfull \\[hv]box' "$LOG_PATH" || true)
printf 'PDF: %s\n' "$PDF_PATH"
printf 'Pages: %s\n' "${PAGES:-unknown}"
printf 'Underfull box warnings: %s\n' "${UNDERFULL:-0}"
```

Make the script executable.

- [ ] **Step 5: Run fixture and real build tests**

Run:

```sh
bash tests/test_verify_deck.sh
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-verify.XXXXXX")
academic-beamer/scripts/create-deck.sh "$tmp_dir/deck"
academic-beamer/scripts/verify-deck.sh "$tmp_dir/deck/presentation.tex"
```

Expected: fixture cases classify correctly; both accepted Lua engine banners are
covered, and the real starter reports its PDF, page count, zero meaningful
failures, and a LuaTeX or LuaHBTeX build.

- [ ] **Step 6: Conditionally commit verification**

Only if the user explicitly requested commits:

```sh
git add academic-beamer/scripts/verify-deck.sh tests/fixtures tests/test_verify_deck.sh
git commit -m "feat: verify beamer decks with lualatex"
```

### Task 6: Implement Deterministic Slide Rendering

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/academic-beamer/scripts/render-slides.sh`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_render_slides.sh`

**Interfaces:**
- Consumes: one PDF, one output directory, `pdfinfo`, and `pdftoppm`.
- Produces: `slide-001.jpg` through `slide-NNN.jpg`, one image for every PDF page.

- [ ] **Step 1: Write the failing renderer test**

Create `tests/test_render_slides.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RENDER="$ROOT_DIR/academic-beamer/scripts/render-slides.sh"
CREATE="$ROOT_DIR/academic-beamer/scripts/create-deck.sh"
VERIFY="$ROOT_DIR/academic-beamer/scripts/verify-deck.sh"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-render.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -x "$RENDER" ] || fail 'render-slides.sh is missing or not executable'

$CREATE "$TMP_DIR/deck"
$VERIFY "$TMP_DIR/deck/presentation.tex" >/dev/null
$RENDER "$TMP_DIR/deck/presentation.pdf" "$TMP_DIR/rendered slides" >/dev/null

pages=$(pdfinfo "$TMP_DIR/deck/presentation.pdf" | rg '^Pages:' | rg --only-matching '[0-9]+')
rendered=$(find "$TMP_DIR/rendered slides" -type f -name 'slide-[0-9][0-9][0-9].jpg' | wc -l | tr -d ' ')
[ "$rendered" -eq "$pages" ] || fail "rendered $rendered images for $pages pages"
[ -f "$TMP_DIR/rendered slides/slide-001.jpg" ] || fail 'first numbered slide is missing'
[ -f "$TMP_DIR/rendered slides/slide-003.jpg" ] || fail 'third numbered slide is missing'

mkdir "$TMP_DIR/nonempty"
printf 'preserve me\n' > "$TMP_DIR/nonempty/existing.txt"
if $RENDER "$TMP_DIR/deck/presentation.pdf" "$TMP_DIR/nonempty" >"$TMP_DIR/nonempty.out" 2>"$TMP_DIR/nonempty.err"; then
  fail 'nonempty output directory should be rejected'
fi
[ "$(cat "$TMP_DIR/nonempty/existing.txt")" = 'preserve me' ] || fail 'existing output was altered'

if $RENDER "$TMP_DIR/deck/presentation.pdf" "$TMP_DIR/missing/frames" >"$TMP_DIR/missing.out" 2>"$TMP_DIR/missing.err"; then
  fail 'missing output parent should be rejected'
fi

printf 'Slide rendering tests passed.\n'
```

- [ ] **Step 2: Run the test and confirm it fails**

Run `bash tests/test_render_slides.sh`.

Expected: nonzero exit because the renderer is absent.

- [ ] **Step 3: Implement `render-slides.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  printf 'Usage: %s <pdf-file> <output-directory>\n' "${0##*/}" >&2
  exit 2
fi

PDF_PATH=$1
OUTPUT_DIR=${2%/}
[ -n "$OUTPUT_DIR" ] || OUTPUT_DIR=/
[ -f "$PDF_PATH" ] || { printf 'ERROR: PDF not found: %s\n' "$PDF_PATH" >&2; exit 1; }
command -v pdfinfo >/dev/null 2>&1 || { printf 'ERROR: pdfinfo is required\n' >&2; exit 1; }
command -v pdftoppm >/dev/null 2>&1 || { printf 'ERROR: pdftoppm is required\n' >&2; exit 1; }

PARENT_DIR=$(dirname "$OUTPUT_DIR")
[ -d "$PARENT_DIR" ] || { printf 'ERROR: output parent does not exist: %s\n' "$PARENT_DIR" >&2; exit 1; }
if [ -d "$OUTPUT_DIR" ] && [ -n "$(ls -A "$OUTPUT_DIR")" ]; then
  printf 'ERROR: refusing to overwrite nonempty output directory: %s\n' "$OUTPUT_DIR" >&2
  exit 1
fi
mkdir -p "$OUTPUT_DIR"

PAGES=$(pdfinfo "$PDF_PATH" | rg '^Pages:' | rg --only-matching '[0-9]+')
for ((page = 1; page <= PAGES; page++)); do
  output="$OUTPUT_DIR/slide-$(printf '%03d' "$page")"
  pdftoppm -f "$page" -l "$page" -singlefile -jpeg -r 160 "$PDF_PATH" "$output"
done

RENDERED=$(find "$OUTPUT_DIR" -type f -name 'slide-[0-9][0-9][0-9].jpg' | wc -l | tr -d ' ')
[ "$RENDERED" -eq "$PAGES" ] || {
  printf 'ERROR: rendered %s images for %s PDF pages\n' "$RENDERED" "$PAGES" >&2
  exit 1
}
printf 'Rendered %s slides in %s\n' "$RENDERED" "$OUTPUT_DIR"
```

Make the script executable.

- [ ] **Step 4: Run rendering tests and inspect output**

Run:

```sh
bash tests/test_render_slides.sh
```

Expected: all cases pass. Read the generated test images before temporary cleanup
or rerun manually into `.test-tmp/visual-review`; confirm title, content, and
closing slides render without clipping.

- [ ] **Step 5: Conditionally commit rendering**

Only if the user explicitly requested commits:

```sh
git add academic-beamer/scripts/render-slides.sh tests/test_render_slides.sh
git commit -m "feat: render slide decks for visual review"
```

### Task 7: Add Automated Template Synchronization

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/.github/workflows/sync-template.yml`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_sync_workflow.sh`

**Interfaces:**
- Consumes: latest non-draft upstream GitHub release and the three allowlisted release assets.
- Produces: a branch and reviewable PR updating vendored assets, `VERSION`, `template-source.json`, and `THIRD_PARTY_LICENSES.md`; never writes directly to the default branch.

- [ ] **Step 1: Write failing workflow policy checks**

Create `tests/test_sync_workflow.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW="$ROOT_DIR/.github/workflows/sync-template.yml"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -f "$WORKFLOW" ] || fail 'sync-template.yml is missing'

for required in \
  'schedule:' \
  'workflow_dispatch:' \
  'contents: write' \
  'pull-requests: write' \
  'presentation.sty' \
  'presentation-minimal.tex' \
  'LICENSE.txt' \
  'template-source.json' \
  'texlive-luatex' \
  'skills-ref validate academic-beamer' \
  'gh pr create'; do
  rg --fixed-strings --quiet "$required" "$WORKFLOW" || fail "workflow is missing: $required"
done

for forbidden in 'git push origin main' 'git push origin master' 'gh release create' 'raw.githubusercontent.com/YuntianZhao/Beamer-Template/main'; do
  if rg --fixed-strings --quiet "$forbidden" "$WORKFLOW"; then
    fail "workflow contains forbidden behavior: $forbidden"
  fi
done

printf 'Synchronization workflow checks passed.\n'
```

- [ ] **Step 2: Run the test and confirm it fails**

Run `bash tests/test_sync_workflow.sh`.

Expected: nonzero exit because the workflow is absent.

- [ ] **Step 3: Create the synchronization workflow**

Create `.github/workflows/sync-template.yml`:

```yaml
name: Sync Beamer template

on:
  schedule:
    - cron: "17 8 * * 1"
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  sync:
    runs-on: ubuntu-latest
    env:
      GH_TOKEN: ${{ github.token }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install skill validator
        run: python3 -m pip install skills-ref

      - name: Install build dependencies
        run: |
          sudo apt-get update
          sudo apt-get install --yes \
            biber \
            latexmk \
            poppler-utils \
            ripgrep \
            texlive-bibtex-extra \
            texlive-fonts-extra \
            texlive-latex-extra \
            texlive-luatex \
            texlive-science

      - name: Resolve latest upstream release
        id: release
        run: |
          tag=$(gh release view --repo YuntianZhao/Beamer-Template --json tagName --jq .tagName)
          current=$(tr -d '\r\n' < academic-beamer/assets/template/VERSION)
          printf 'tag=%s\n' "$tag" >> "$GITHUB_OUTPUT"
          if [ "$tag" = "$current" ]; then
            printf 'changed=false\n' >> "$GITHUB_OUTPUT"
          else
            printf 'changed=true\n' >> "$GITHUB_OUTPUT"
          fi

      - name: Download allowlisted assets
        if: steps.release.outputs.changed == 'true'
        env:
          TAG: ${{ steps.release.outputs.tag }}
        run: |
          mkdir .template-import
          gh release download "$TAG" \
            --repo YuntianZhao/Beamer-Template \
            --dir .template-import \
            --pattern presentation.sty \
            --pattern presentation-minimal.tex \
            --pattern LICENSE.txt
          cp .template-import/presentation.sty academic-beamer/assets/template/presentation.sty
          cp .template-import/presentation-minimal.tex academic-beamer/assets/template/presentation.tex
          cp .template-import/LICENSE.txt academic-beamer/assets/template/LICENSE.txt
          printf '%s\n' "$TAG" > academic-beamer/assets/template/VERSION

      - name: Update provenance
        if: steps.release.outputs.changed == 'true'
        env:
          TAG: ${{ steps.release.outputs.tag }}
        run: |
          python3 - <<'PY'
          import hashlib
          import json
          import os
          import pathlib
          import re
          import subprocess
          from datetime import datetime, timezone

          root = pathlib.Path.cwd()
          tag_name = os.environ["TAG"]
          ref = json.loads(subprocess.check_output([
              "gh", "api", f"repos/YuntianZhao/Beamer-Template/git/ref/tags/{tag_name}"
          ]))
          source_commit = ref["object"]["sha"]
          if ref["object"]["type"] == "tag":
              tag = json.loads(subprocess.check_output([
                  "gh", "api", f"repos/YuntianZhao/Beamer-Template/git/tags/{source_commit}"
              ]))
              source_commit = tag["object"]["sha"]

          mapping = {
              "presentation.sty": "academic-beamer/assets/template/presentation.sty",
              "presentation-minimal.tex": "academic-beamer/assets/template/presentation.tex",
              "LICENSE.txt": "academic-beamer/assets/template/LICENSE.txt",
          }
          files = []
          for source, destination in mapping.items():
              data = (root / destination).read_bytes()
              files.append({
                  "source": source,
                  "destination": destination,
                  "sha256": hashlib.sha256(data).hexdigest(),
              })
          manifest = {
              "repository": "YuntianZhao/Beamer-Template",
              "release": tag_name,
              "source_commit": source_commit,
              "imported_at": datetime.now(timezone.utc).isoformat(),
              "files": files,
          }
          (root / "template-source.json").write_text(json.dumps(manifest, indent=2) + "\n")

          licenses = root / "THIRD_PARTY_LICENSES.md"
          text = licenses.read_text()
          text = re.sub(r"release `[^`]+`", f"release `{tag_name}`", text, count=1)
          licenses.write_text(text)
          PY

      - name: Verify synchronized package
        if: steps.release.outputs.changed == 'true'
        run: |
          skills-ref validate academic-beamer
          bash tests/run_all.sh

      - name: Open update pull request
        if: steps.release.outputs.changed == 'true'
        env:
          TAG: ${{ steps.release.outputs.tag }}
        run: |
          branch="automation/template-$TAG"
          existing=$(gh pr list --state open --head "$branch" --json number --jq 'length')
          if [ "$existing" -gt 0 ]; then
            printf 'An update PR already exists for %s.\n' "$TAG"
            exit 0
          fi
          git config user.name github-actions[bot]
          git config user.email 41898282+github-actions[bot]@users.noreply.github.com
          git checkout -b "$branch"
          git add \
            academic-beamer/assets/template/presentation.sty \
            academic-beamer/assets/template/presentation.tex \
            academic-beamer/assets/template/LICENSE.txt \
            academic-beamer/assets/template/VERSION \
            template-source.json \
            THIRD_PARTY_LICENSES.md
          git commit -m "chore: sync Beamer template $TAG"
          git push --set-upstream origin "$branch"
          gh pr create \
            --title "chore: sync Beamer template $TAG" \
            --body "Update vendored runtime assets to YuntianZhao/Beamer-Template $TAG. CI validates provenance, the mandatory LuaLaTeX skill workflow, and package policy." \
            --base "${{ github.event.repository.default_branch }}" \
            --head "$branch"
```

- [ ] **Step 4: Run workflow policy tests**

Run `bash tests/test_sync_workflow.sh`.

Expected: pass with no direct-default-branch or release-publication behavior.

- [ ] **Step 5: Conditionally commit synchronization**

Only if the user explicitly requested commits:

```sh
git add .github/workflows/sync-template.yml tests/test_sync_workflow.sh
git commit -m "ci: automate template synchronization prs"
```

### Task 8: Add CI, Fixture Matrix, and Policy Checks

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_template_policy.sh`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_build_matrix.sh`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/run_all.sh`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/.github/workflows/test.yml`

**Interfaces:**
- Consumes: all package files, runtime scripts, provenance, supported template
  options, and the mandatory LuaLaTeX runtime policy.
- Produces: one local test entrypoint and one Ubuntu LuaLaTeX CI gate used by
  normal pushes, PRs, and synchronization PRs.

- [ ] **Step 1: Add failing static policy checks**

Create `tests/test_template_policy.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE="$ROOT_DIR/academic-beamer"
SKILL="$PACKAGE/SKILL.md"
VERIFY="$PACKAGE/scripts/verify-deck.sh"
STARTER="$PACKAGE/assets/template/presentation.tex"
TEST_WORKFLOW="$ROOT_DIR/.github/workflows/test.yml"
SYNC_WORKFLOW="$ROOT_DIR/.github/workflows/sync-template.yml"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

rg --fixed-strings --quiet 'must not be replaced by another Beamer theme' "$SKILL" || fail 'theme rejection is missing'
rg --fixed-strings --quiet 'Do not draft the complete deck until the user approves' "$SKILL" || fail 'outline approval gate is missing'
rg --fixed-strings --quiet 'latexmk -lualatex' "$SKILL" || fail 'SKILL.md lacks latexmk -lualatex'
rg --fixed-strings --quiet 'latexmk -lualatex' "$VERIFY" || fail 'verify-deck.sh lacks latexmk -lualatex'
rg --fixed-strings --quiet 'command -v lualatex' "$VERIFY" || fail 'verify-deck.sh does not require lualatex'
rg --fixed-strings --quiet '^This is Lua(HB)?TeX(?:,| |$)' "$VERIFY" || fail 'verify-deck.sh does not validate LuaTeX or LuaHBTeX logs'
[ -f "$TEST_WORKFLOW" ] || fail 'test.yml is missing'
for workflow in "$TEST_WORKFLOW" "$SYNC_WORKFLOW"; do
  rg --fixed-strings --quiet 'texlive-luatex' "$workflow" || fail "$workflow does not install LuaLaTeX"
done

for file in "$SKILL" "$VERIFY" "$TEST_WORKFLOW" "$SYNC_WORKFLOW"; do
  if rg --quiet 'latexmk -(pdf|xelatex)|^[[:space:]]*(pdf|xe|lua)latex[[:space:]]' "$file"; then
    fail "$file contains a forbidden build command"
  fi
done

for option in \
  '\providecommand{\presentationaspectratio}{43}' \
  '\providecommand{\presentationmode}{light}' \
  '\providecommand{\presentationfontsize}{12pt}' \
  '{presentation}'; do
  rg --fixed-strings --quiet "$option" "$STARTER" || fail "starter is missing $option"
done

[ ! -d "$PACKAGE/tests" ] || fail 'runtime package contains tests'
if find "$PACKAGE" -type f -name '*.pdf' -print -quit | rg --quiet '.'; then
  fail 'runtime package contains a generated PDF'
fi
[ "$(wc -l < "$STARTER" | tr -d ' ')" -le 100 ] || fail 'runtime starter appears to be the comprehensive demo'

for script in "$PACKAGE"/scripts/*.sh; do
  [ -x "$script" ] || fail "$script is not executable"
  bash -n "$script"
done

printf 'Template policy checks passed.\n'
```

- [ ] **Step 2: Run policy checks and fix any exact failures**

Run `bash tests/test_template_policy.sh`.

Expected: nonzero with `test.yml is missing`; the policy test passes after Step 5
creates CI with the mandatory LuaLaTeX dependencies. Treat any later failure as
a policy regression, not as a test to weaken.

- [ ] **Step 3: Create the LuaLaTeX fixture matrix**

Create executable `tests/test_build_matrix.sh`:

```bash
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
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
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
\begin{frame}[fragile]
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
$VERIFY "$RICH_DIR/presentation.tex"

printf 'LuaLaTeX build matrix passed.\n'
```

- [ ] **Step 4: Create the all-tests entrypoint**

Create executable `tests/run_all.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

skills-ref validate academic-beamer
bash tests/test_skill_metadata.sh
bash tests/test_references.sh
bash tests/test_provenance.sh
bash tests/test_create_deck.sh
bash tests/test_verify_deck.sh
bash tests/test_render_slides.sh
bash tests/test_sync_workflow.sh
bash tests/test_template_policy.sh
bash tests/test_build_matrix.sh

printf 'All Academic Beamer Skill checks passed.\n'
```

- [ ] **Step 5: Create Ubuntu CI**

Create `.github/workflows/test.yml` to install LuaLaTeX and exercise only the
mandatory skill-runtime engine workflow:

```yaml
name: Test LuaLaTeX skill workflow

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install system dependencies
        run: |
          sudo apt-get update
          sudo apt-get install --yes \
            biber \
            latexmk \
            poppler-utils \
            ripgrep \
            texlive-bibtex-extra \
            texlive-fonts-extra \
            texlive-latex-extra \
            texlive-luatex \
            texlive-science

      - name: Install skill validator
        run: python3 -m pip install skills-ref

      - name: Run LuaLaTeX skill checks
        run: bash tests/run_all.sh
```

- [ ] **Step 6: Run all local checks**

Run:

```sh
bash tests/run_all.sh
```

Expected: all schema, script, policy, provenance, rendering, and 12 LuaLaTeX
matrix builds pass.

- [ ] **Step 7: Conditionally commit CI and tests**

Only if the user explicitly requested commits:

```sh
git add tests .github/workflows/test.yml
git commit -m "test: add skill validation and build matrix"
```

### Task 9: Add Public Documentation and Release Checks

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/README.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/CONTRIBUTING.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/CHANGELOG.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/prompt-evals/create.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/prompt-evals/revise.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/prompt-evals/migrate.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/prompt-evals/verify.md`
- Create: `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill/tests/test_docs.sh`

**Interfaces:**
- Consumes: finalized package paths, `latexmk` plus LuaLaTeX prerequisites,
  harness discovery locations, runtime commands, and verification entrypoint.
- Produces: public installation/usage documentation and repeatable manual
  behavior evaluations that enforce the LuaLaTeX workflow.

- [ ] **Step 1: Write failing documentation checks**

Create `tests/test_docs.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -f "$README" ] || fail 'README.md is missing'

for heading in '## Requirements' '## Installation' '## Usage' '## How Verification Works' '## Template Updates' '## Licensing'; do
  rg --fixed-strings --quiet "$heading" "$README" || fail "README is missing $heading"
done
for path in '.agents/skills/academic-beamer' '.claude/skills/academic-beamer'; do
  rg --fixed-strings --quiet "$path" "$README" || fail "README is missing $path"
done

rg --fixed-strings --quiet 'bash tests/run_all.sh' "$ROOT_DIR/CONTRIBUTING.md" || fail 'contributor test command is missing'
rg --fixed-strings --quiet '`latexmk` and LuaLaTeX' "$ROOT_DIR/CONTRIBUTING.md" || fail 'contributor prerequisites omit latexmk or LuaLaTeX'
rg --fixed-strings --quiet 'v1.0.0' "$ROOT_DIR/CHANGELOG.md" || fail 'skill release is missing from changelog'
rg --fixed-strings --quiet 'Beamer-Template` v1.0.0' "$ROOT_DIR/CHANGELOG.md" || fail 'template release is missing from changelog'
rg --fixed-strings --quiet 'mandatory LuaLaTeX' "$ROOT_DIR/CHANGELOG.md" || fail 'changelog omits the mandatory LuaLaTeX workflow'
rg --fixed-strings --quiet -- '- LuaLaTeX' "$README" || fail 'README does not require LuaLaTeX'
rg --fixed-strings --quiet 'latexmk -lualatex' "$README" || fail 'README lacks the mandatory LuaLaTeX command'

for action in create revise migrate verify; do
  file="$ROOT_DIR/tests/prompt-evals/$action.md"
  [ -s "$file" ] || fail "prompt evaluation is missing: $action.md"
  rg --fixed-strings --quiet '## Failure Criteria' "$file" || fail "$action.md lacks failure criteria"
  rg --fixed-strings --quiet 'Switching to another theme while the skill is active.' "$file" || fail "$action.md lacks theme enforcement"
  rg --fixed-strings --quiet 'LuaLaTeX' "$file" || fail "$action.md lacks the LuaLaTeX runtime policy"
done

printf 'Documentation checks passed.\n'
```

- [ ] **Step 2: Run documentation checks and confirm they fail**

Run `bash tests/test_docs.sh`.

Expected: nonzero exit because public documentation is absent.

- [ ] **Step 3: Write `README.md`**

Create `README.md`:

````markdown
# Academic Beamer Skill

An open Agent Skill for creating, revising, compiling, and visually reviewing
academic LaTeX Beamer presentations with the bundled minimalist template.

Installing the skill does not force it onto every presentation task. Once the
skill is invoked, its bundled template is mandatory; it will not substitute a
different Beamer theme.

## Requirements

Required for verified output:

- `latexmk`
- LuaLaTeX
- Biber when the deck contains citations

Visual checking additionally needs Poppler (`pdfinfo` and `pdftoppm`) and an
agent harness capable of inspecting images. Deck creation itself is offline; all
runtime template files are bundled.

## Installation

Clone the repository:

```sh
git clone https://github.com/YuntianZhao/Academic-Beamer-Skill.git
```

For Codex and OpenCode:

```sh
mkdir -p ~/.agents/skills
cp -R Academic-Beamer-Skill/academic-beamer ~/.agents/skills/academic-beamer
```

For Claude Code:

```sh
mkdir -p ~/.claude/skills
cp -R Academic-Beamer-Skill/academic-beamer ~/.claude/skills/academic-beamer
```

For project-local installation, copy the same package to
`.agents/skills/academic-beamer` or `.claude/skills/academic-beamer` in the
project. Only the `academic-beamer/` directory is the installable skill.

## Usage

Create from a prompt and local paper:

```text
Use academic-beamer to create a 20-minute seminar deck from paper.pdf for an
economics audience.
```

The skill reads inputs and asks informed questions, then presents a
slide-by-slide outline. It waits for explicit outline approval before drafting a
new full deck.

Revise an existing deck:

```text
Use academic-beamer to shorten the frame titled Identification Strategy and
recompile the deck.
```

Migrate a nonconforming Beamer deck:

```text
Use academic-beamer to migrate old-talk.tex into a separate project using the
bundled template while preserving citations and figures.
```

Verify a deck:

```text
Use academic-beamer to compile and visually check presentation.tex.
```

## How Verification Works

The skill runs LuaLaTeX through:

```sh
latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error presentation.tex
```

It confirms LuaTeX or LuaHBTeX in the log and rejects unresolved citations,
references, missing assets, rerun requests, and meaningful overfull boxes.
pdfLaTeX and XeLaTeX are upstream Beamer-Template compatibility concerns, not
skill-runtime substitutes. When visual tools and image inspection are available,
the skill renders every PDF page and checks every slide. Otherwise it reports
that visual verification was skipped.

## Template Options

- Font size: `10pt`, `11pt`, or `12pt`
- Aspect ratio: `43`, `1610`, or `169`
- Mode: `light` or `dark`
- Page numbers: enabled or disabled

The skill does not introduce a second theme or design system.

## Template Updates

Runtime assets come from tagged releases of
[`YuntianZhao/Beamer-Template`](https://github.com/YuntianZhao/Beamer-Template).
A weekly GitHub workflow detects a newer release, updates only allowlisted files,
records source checksums, runs the complete test suite, and opens a pull request.
It never changes the default branch or publishes a release directly.

See `template-source.json` for the exact bundled release, source commit, and
SHA-256 checksums.

## Development

See `CONTRIBUTING.md`. Run all checks with:

```sh
bash tests/run_all.sh
```

## Licensing

Original skill instructions, scripts, tests, and documentation are MIT licensed;
see `LICENSE`. Vendored template files retain LPPL-1.3c; see
`THIRD_PARTY_LICENSES.md` and
`academic-beamer/assets/template/LICENSE.txt`.
````

- [ ] **Step 4: Write contributor and changelog files**

Create `CONTRIBUTING.md`:

````markdown
# Contributing

## Package Boundary

Only `academic-beamer/` is installed into agent harnesses. Keep tests, workflows,
project documentation, and generated artifacts outside that directory.

## Template Assets

Do not hand-edit files under `academic-beamer/assets/template/`. Import template
changes from a tagged `YuntianZhao/Beamer-Template` release through the
synchronization workflow. Every imported byte must match `template-source.json`.

## Checks

Install `latexmk` and LuaLaTeX, plus the documented Biber, Poppler, and
`skills-ref` dependencies, then run:

```sh
bash tests/run_all.sh
```

All schema, provenance, script, rendering, policy, documentation, and LuaLaTeX
matrix checks must pass before review. pdfLaTeX and XeLaTeX checks belong to the
separate upstream Beamer-Template compatibility suite, not this skill repository.

## Prompt Evaluations

Run the four scenarios under `tests/prompt-evals/` in clean temporary projects.
Record observable evidence for every pass criterion. Do not weaken a criterion
to accommodate a model failure; improve the skill description or instructions.
````

Initialize `CHANGELOG.md` with:

```markdown
# Changelog

## v1.0.0 - 2026-07-26

- Add the portable `academic-beamer` Agent Skill.
- Bundle `YuntianZhao/Beamer-Template` v1.0.0.
- Add safe deck creation, the mandatory LuaLaTeX verification workflow, visual
  rendering, provenance, CI, and automated template update pull requests.
```

- [ ] **Step 5: Add four manual prompt evaluations**

Create `tests/prompt-evals/create.md`:

```markdown
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
```

Create `tests/prompt-evals/revise.md`:

```markdown
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
```

Create `tests/prompt-evals/migrate.md`:

```markdown
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
```

Create `tests/prompt-evals/verify.md`:

```markdown
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
  `latexmk -lualatex` workflow.
- Claiming success with unresolved references, missing assets, or overfull boxes.
- Switching to another theme while the skill is active.
```

- [ ] **Step 6: Add documentation checks to `run_all.sh` and run everything**

Insert `bash tests/test_docs.sh` before the build matrix in `tests/run_all.sh`,
then run:

```sh
bash tests/run_all.sh
```

Expected: all checks pass.

- [ ] **Step 7: Perform the manual prompt evaluation**

Run each prompt in a clean temporary project with the installed
`academic-beamer/` package. Record pass/fail and evidence in the release notes;
do not weaken a criterion to accommodate model behavior. Tighten `description`
or imperative skill instructions if invocation or template enforcement fails.

- [ ] **Step 8: Inspect final package boundaries and repository status**

Run:

```sh
git status --short
git diff --stat
find academic-beamer -type f -print
```

Expected: the package contains only `SKILL.md`, runtime assets, references, and
runtime scripts. No generated PDF, repository test, workflow, or plan is inside
`academic-beamer/`.

- [ ] **Step 9: Conditionally commit documentation**

Only if the user explicitly requested commits:

```sh
git add README.md CONTRIBUTING.md CHANGELOG.md tests/prompt-evals tests/test_docs.sh tests/run_all.sh
git commit -m "docs: add installation and release guidance"
```

### Task 10: Final Release Verification

**Files:**
- Verify: all files under `/Users/yuntianzhao/Documents/tex/Academic-Beamer-Skill`

**Interfaces:**
- Consumes: completed Tasks 1-9.
- Produces: objective evidence, including a verified LuaTeX or LuaHBTeX smoke
  build, that the project is ready for an explicitly authorized GitHub
  publication and `v1.0.0` release.

- [ ] **Step 1: Run the complete automated suite from a clean test state**

Run:

```sh
rm -rf .test-tmp
bash tests/run_all.sh
```

Expected: all checks pass from a newly created `.test-tmp` directory.

- [ ] **Step 2: Install the package into temporary harness paths**

Copy `academic-beamer/` into temporary `.agents/skills/academic-beamer` and
`.claude/skills/academic-beamer` directories. Run `skills-ref validate` against
both copies and verify all relative links and script paths resolve inside the
copied package without access to repository-level files.

- [ ] **Step 3: Create and fully verify a smoke-test deck from the installed copy**

Run the installed `create-deck.sh`, replace starter metadata/content with final
non-placeholder smoke content, run `verify-deck.sh`, render every slide, and
inspect every image. Confirm no clipping, overlap, distortion, unreadable text,
or unintended blank page except the intentional `\lastslide` closing frame.
Confirm the build used `latexmk -lualatex` and its log identifies LuaTeX or
LuaHBTeX before reporting the smoke deck complete.

- [ ] **Step 4: Verify provenance against the upstream release again**

Download the three `v1.0.0` assets into a new temporary directory and compare
their SHA-256 values with `template-source.json`. Confirm the local starter is
the renamed `presentation-minimal.tex`, not the comprehensive demonstration.

- [ ] **Step 5: Review the final diff and recent history**

Run:

```sh
git status --short
git diff
if git rev-parse --verify HEAD >/dev/null 2>&1; then git log --oneline -10; else printf 'No commits created.\n'; fi
```

Expected: no generated files are staged or tracked, no secrets appear, and all
changes belong to the approved design.

- [ ] **Step 6: Stop before remote publication unless explicitly authorized**

Report local release readiness, test evidence, the planned GitHub repository
`YuntianZhao/Academic-Beamer-Skill`, and planned tag `v1.0.0`. Do not add a
remote, commit outstanding work, push, create the GitHub repository, or publish
a release unless the user explicitly requests those actions.
