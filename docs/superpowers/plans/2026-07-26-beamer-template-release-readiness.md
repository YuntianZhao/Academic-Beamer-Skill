# Beamer Template Release Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare `YuntianZhao/Beamer-Template` to publish tagged releases containing a tested minimal starter and properly identified LPPL runtime template files.

**Architecture:** Keep `presentation.tex` as the comprehensive demonstration deck and add `presentation-minimal.tex` as the small distributable starter consumed by the separate skill repository. Identify `presentation.sty` and `presentation-minimal.tex` as the author-maintained LPPL work, test the starter independently, and document an exact release procedure that runs all existing compatibility checks before creating a GitHub release.

**Tech Stack:** LaTeX Beamer, pdfLaTeX, LuaLaTeX, XeLaTeX, `latexmk`, Bash, `biber`, ripgrep, GitHub CLI.

## Global Constraints

- Work in `/Users/yuntianzhao/Documents/tex/Beamer-Template`.
- Preserve the current visual behavior of `presentation.sty`.
- Preserve `presentation.tex` as the full demonstration and regression deck.
- Add `presentation-minimal.tex` as a runtime source file, not a generated file.
- Keep upstream defaults at `12pt`, aspect ratio `43`, and `light` mode.
- Define the LPPL work as exactly `presentation.sty` and `presentation-minimal.tex` so the skill can redistribute the complete runtime work.
- Use `latexmk`, not direct engine calls, for every compile verification.
- Do not leave generated PDFs at the repository root.
- Do not modify or delete unrelated uncommitted work in the current dirty worktree.
- Commit, tag, push, or create a GitHub release only when the user explicitly requests that action.

---

### Task 1: Add the Minimal Starter Deck

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Beamer-Template/presentation-minimal.tex`
- Modify: `/Users/yuntianzhao/Documents/tex/Beamer-Template/tests/template_checks.sh`

**Interfaces:**
- Consumes: package options and commands exported by `presentation.sty`.
- Produces: `presentation-minimal.tex`, the upstream source imported as `academic-beamer/assets/template/presentation.tex` by the skill synchronization workflow.

- [ ] **Step 1: Add failing textual checks for the minimal starter**

Append these assertions before `exit "$fail"` in `tests/template_checks.sh`:

```bash
check_present '\providecommand{\presentationaspectratio}{43}' presentation-minimal.tex 'minimal starter should default to 4:3'
check_present '\providecommand{\presentationmode}{light}' presentation-minimal.tex 'minimal starter should default to light mode'
check_present '\providecommand{\presentationfontsize}{12pt}' presentation-minimal.tex 'minimal starter should default to 12pt'
check_present '\expandafter\usepackage\expandafter[\presentationpackageoptions]{presentation}' presentation-minimal.tex 'minimal starter should load presentation.sty'
check_present '\frame{\titlepage}' presentation-minimal.tex 'minimal starter should include a title frame'
check_present '\lastslide' presentation-minimal.tex 'minimal starter should demonstrate the template closing slide'
check_absent '\addbibresource{references.bib}' presentation-minimal.tex 'minimal starter should compile before bibliography content is added'
```

- [ ] **Step 2: Run the textual checks and confirm the expected failure**

Run:

```sh
bash tests/template_checks.sh
```

Expected: nonzero exit with failures naming missing `presentation-minimal.tex` content.

- [ ] **Step 3: Create the minimal starter**

Create `presentation-minimal.tex` with this exact initial content:

```tex
\providecommand{\presentationaspectratio}{43}
\providecommand{\presentationmode}{light}
\providecommand{\presentationfontsize}{12pt}
\edef\presentationclassoptions{\presentationfontsize,aspectratio=\presentationaspectratio,xcolor={dvipsnames},usepdftitle=false}
\expandafter\documentclass\expandafter[\presentationclassoptions]{beamer}
\edef\presentationpackageoptions{\presentationmode,pagenumbers}
\expandafter\usepackage\expandafter[\presentationpackageoptions]{presentation}

\hypersetup{
  pdfpagemode=UseNone,
  hidelinks,
  pdfdisplaydoctitle=true,
  pdftitle={Presentation Title}
}

\title{Presentation Title}
\author{Author Name}
\date{Location -- Date}

\begin{document}

\frame{\titlepage}

\begin{frame}
  \frametitle{Main result}
  Replace this text with the presentation's main result.
\end{frame}

\lastslide

\end{document}
```

- [ ] **Step 4: Run textual checks and compile the starter with all supported engines**

Run:

```sh
bash tests/template_checks.sh
mkdir -p .engine-check/minimal-lualatex .engine-check/minimal-pdflatex .engine-check/minimal-xelatex
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-lualatex presentation-minimal.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-pdflatex presentation-minimal.tex
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-xelatex presentation-minimal.tex
```

Expected: textual checks pass and all three commands produce `presentation-minimal.pdf` in their respective ignored output directories.

- [ ] **Step 5: Review the three PDFs**

Open or read:

```text
.engine-check/minimal-lualatex/presentation-minimal.pdf
.engine-check/minimal-pdflatex/presentation-minimal.pdf
.engine-check/minimal-xelatex/presentation-minimal.pdf
```

Expected: identical structure, legible title/content slides, and the intended blank closing slide with no clipping or unexpected page.

- [ ] **Step 6: Conditionally commit the starter task**

Only if the user explicitly requested commits:

```sh
git add presentation-minimal.tex tests/template_checks.sh
git commit -m "feat: add minimal presentation starter"
```

### Task 2: Identify the LPPL Runtime Work

**Files:**
- Modify: `/Users/yuntianzhao/Documents/tex/Beamer-Template/presentation.sty`
- Modify: `/Users/yuntianzhao/Documents/tex/Beamer-Template/presentation-minimal.tex`
- Modify: `/Users/yuntianzhao/Documents/tex/Beamer-Template/README.md`
- Modify: `/Users/yuntianzhao/Documents/tex/Beamer-Template/tests/template_checks.sh`

**Interfaces:**
- Consumes: the unmodified LPPL 1.3c text in `LICENSE.txt`.
- Produces: complete copyright, license, maintenance, and work-identification notices that travel with both files imported by the skill.

- [ ] **Step 1: Add failing checks for the LPPL notices**

Append before `exit "$fail"` in `tests/template_checks.sh`:

```bash
for file in presentation.sty presentation-minimal.tex; do
  check_present 'Copyright 2026 Yuntian Zhao' "$file" "$file should identify the copyright holder"
  check_present 'LaTeX Project Public License' "$file" "$file should identify the LPPL"
  check_present "maintenance status 'author-maintained'" "$file" "$file should identify maintenance status"
  check_present 'Current Maintainer of this work is Yuntian Zhao' "$file" "$file should identify the current maintainer"
  check_present 'presentation.sty and presentation-minimal.tex' "$file" "$file should identify the complete LPPL work"
done
check_present '## License' README.md 'README should explain template licensing'
check_present 'presentation.sty' README.md 'README license section should name the runtime work'
check_present 'presentation-minimal.tex' README.md 'README license section should name the runtime work'
```

- [ ] **Step 2: Run checks and confirm they fail**

Run:

```sh
bash tests/template_checks.sh
```

Expected: nonzero exit with missing copyright, maintenance, work, and README license messages.

- [ ] **Step 3: Add the LPPL header to both runtime files**

Insert this block at the beginning of both `presentation.sty` and `presentation-minimal.tex`:

```tex
%% Copyright 2026 Yuntian Zhao
%
% This work may be distributed and/or modified under the conditions of
% the LaTeX Project Public License, either version 1.3c of this license
% or (at your option) any later version. The latest version is at
% https://www.latex-project.org/lppl.txt and version 1.3c or later is
% part of all distributions of LaTeX version 2008 or later.
%
% This work has the LPPL maintenance status 'author-maintained'.
% The Current Maintainer of this work is Yuntian Zhao.
% This work consists of presentation.sty and presentation-minimal.tex.
```

- [ ] **Step 4: Add the README license section**

Append this section to `README.md`:

```markdown
## License

The runtime template work consists of `presentation.sty` and
`presentation-minimal.tex`. It is distributed under the LaTeX Project Public
License, version 1.3c or later, with author-maintained status. The Current
Maintainer is Yuntian Zhao. See `LICENSE.txt` for the complete license.
```

- [ ] **Step 5: Run textual and compile verification**

Run:

```sh
bash tests/template_checks.sh
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-pdflatex presentation-minimal.tex
```

Expected: all checks pass and comments do not affect the generated PDF.

- [ ] **Step 6: Conditionally commit the licensing task**

Only if the user explicitly requested commits:

```sh
git add presentation.sty presentation-minimal.tex README.md tests/template_checks.sh
git commit -m "docs: identify LPPL runtime template work"
```

### Task 3: Document and Validate the Release Contract

**Files:**
- Create: `/Users/yuntianzhao/Documents/tex/Beamer-Template/RELEASING.md`
- Modify: `/Users/yuntianzhao/Documents/tex/Beamer-Template/AGENTS.md`
- Modify: `/Users/yuntianzhao/Documents/tex/Beamer-Template/tests/template_checks.sh`

**Interfaces:**
- Consumes: `presentation.sty`, `presentation-minimal.tex`, `LICENSE.txt`, and all existing verification commands.
- Produces: a release contract consumed by maintainers and by `Academic-Beamer-Skill/.github/workflows/sync-template.yml`.

- [ ] **Step 1: Add failing release-document checks**

Append before `exit "$fail"` in `tests/template_checks.sh`:

```bash
check_present 'presentation.sty' RELEASING.md 'release instructions should list presentation.sty'
check_present 'presentation-minimal.tex' RELEASING.md 'release instructions should list presentation-minimal.tex'
check_present 'LICENSE.txt' RELEASING.md 'release instructions should list LICENSE.txt'
check_present 'bash tests/template_checks.sh' RELEASING.md 'release instructions should require textual checks'
check_present './compile_all.sh' RELEASING.md 'release instructions should require the variant matrix'
check_present 'latexmk -pdf' RELEASING.md 'release instructions should require pdfLaTeX verification'
check_present 'gh release create' RELEASING.md 'release instructions should document GitHub release creation'
check_present 'RELEASING.md' AGENTS.md 'agent instructions should point to the release checklist'
```

- [ ] **Step 2: Run checks and confirm they fail**

Run:

```sh
bash tests/template_checks.sh
```

Expected: nonzero exit because `RELEASING.md` does not exist and `AGENTS.md` does not reference it.

- [ ] **Step 3: Create `RELEASING.md`**

Create the file with this content:

````markdown
# Releasing

Tagged releases are the source of runtime assets consumed by
`YuntianZhao/Academic-Beamer-Skill`.

## Runtime Release Files

- `presentation.sty`
- `presentation-minimal.tex`
- `LICENSE.txt`

Do not rename or remove a runtime release file without coordinating a matching
skill synchronization change.

## Verification

Run from the repository root:

```sh
bash tests/template_checks.sh
mkdir -p .engine-check/lualatex .engine-check/pdflatex .engine-check/xelatex .engine-check/minimal-lualatex .engine-check/minimal-pdflatex .engine-check/minimal-xelatex
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/lualatex presentation.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=.engine-check/pdflatex presentation.tex
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/xelatex presentation.tex
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-lualatex presentation-minimal.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-pdflatex presentation-minimal.tex
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-xelatex presentation-minimal.tex
./compile_all.sh
```

Review all command output and visually inspect the three minimal-starter PDFs.
Treat an engine or variant failure as a release blocker.

## Publish

After verification, create the initial annotated semantic-version tag and push
it. Then create the GitHub release and attach the runtime files:

```sh
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
gh release create v1.0.0 presentation.sty presentation-minimal.tex LICENSE.txt --generate-notes --verify-tag
```

Tagging, pushing, and release creation require explicit user approval.
````

- [ ] **Step 4: Add release guidance to `AGENTS.md`**

Append:

```markdown
## Releases

Follow `RELEASING.md` for the required runtime files, compatibility matrix, and
GitHub release procedure. Never tag, push, or create a release without explicit
user approval.
```

- [ ] **Step 5: Run the complete upstream verification matrix**

Run:

```sh
bash tests/template_checks.sh
mkdir -p .engine-check/lualatex .engine-check/pdflatex .engine-check/xelatex .engine-check/minimal-lualatex .engine-check/minimal-pdflatex .engine-check/minimal-xelatex
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/lualatex presentation.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=.engine-check/pdflatex presentation.tex
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/xelatex presentation.tex
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-lualatex presentation-minimal.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-pdflatex presentation-minimal.tex
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=.engine-check/minimal-xelatex presentation-minimal.tex
./compile_all.sh
```

Expected: every command exits zero, bibliography and cross-references resolve, and all generated PDFs remain in ignored output directories.

- [ ] **Step 6: Inspect the intended release diff**

Run:

```sh
git status --short
git diff -- presentation-minimal.tex presentation.sty README.md AGENTS.md RELEASING.md tests/template_checks.sh
```

Expected: only intended release-readiness changes appear in this diff. Existing unrelated worktree changes remain untouched.

- [ ] **Step 7: Conditionally commit the release-contract task**

Only if the user explicitly requested commits:

```sh
git add RELEASING.md AGENTS.md tests/template_checks.sh
git commit -m "docs: add template release procedure"
```

- [ ] **Step 8: Stop before publishing unless separately authorized**

Report that the upstream repository is release-ready. Do not execute `git tag`, `git push`, or `gh release create` unless the user explicitly provides the release version and requests publication.
