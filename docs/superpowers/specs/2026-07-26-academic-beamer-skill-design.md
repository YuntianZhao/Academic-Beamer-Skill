# Academic Beamer Skill Design

**Date:** 2026-07-26
**Status:** Approved
**Planned repository:** `YuntianZhao/Academic-Beamer-Skill`
**Upstream template:** <https://github.com/YuntianZhao/Beamer-Template>

## Summary

Create a public, cross-agent project that packages the existing minimalist
Beamer template as an Agent Skill. The skill creates and revises academic slide
decks from prompts and local source files, compiles them with LuaLaTeX through
`latexmk`, checks meaningful warnings and errors, and performs visual inspection
when PDF rendering and multimodal image inspection are available.

Installing or discovering the skill does not force a user to use it for every
presentation. Once the skill is invoked, however, its bundled template is
mandatory. The skill must not replace it with another Beamer theme.

The skill is developed in a repository separate from the upstream template.
Selected files from tagged template releases are vendored into the skill through
automated, reviewable update pull requests.

## Goals

- Follow the open Agent Skills specification.
- Work across OpenCode, Codex, Claude Code, and other compatible harnesses.
- Create new decks and revise existing skill-created decks.
- Accept a prompt plus relevant local papers, notes, TeX, figures, data, and
  bibliography files.
- Keep the upstream template's visual language fixed and expose only supported
  document-level options.
- Compile every completed deck with `latexmk -lualatex` and inspect its log.
- Render and inspect every slide visually when the environment supports it.
- Keep generated decks reproducible and independent of network access.
- Track the exact upstream template release included in each skill release.

## Non-Goals

- Taking over all presentation tasks merely because the skill is installed.
- Supporting PowerPoint or other non-Beamer output in the first release.
- Searching for or substituting university, corporate, or third-party themes.
- Downloading the latest template while creating a deck.
- Importing the upstream template's tests or generated PDFs into the skill.
- Automatically installing TeX or other system packages.
- Reproducing every feature or policy from other Beamer skills.

## Prior Art

The design draws on two public projects:

- <https://github.com/Faust-Donf/beamer-academic>
- <https://github.com/Noi1r/beamer-skill>

Useful patterns to retain are input-first material analysis, an outline approval
gate, duration-aware slide planning, source-aware figure handling, iterative
compilation, per-slide visual inspection, and a final quality loop.

Patterns to avoid are alternative-theme fallback, hard-coded institution
defaults, treating XeLaTeX as a substitute for the mandatory skill runtime,
oversized all-in-one skill files,
non-portable frontmatter, and arbitrary quality scores that can imply confidence
without objective evidence.

## Repository Layout

The repository name uses title case, while the installable skill package uses a
lowercase directory whose name matches the Agent Skills `name` field.

```text
Academic-Beamer-Skill/
|-- academic-beamer/
|   |-- SKILL.md
|   |-- assets/
|   |   `-- template/
|   |       |-- LICENSE.txt
|   |       |-- presentation.sty
|   |       |-- presentation.tex
|   |       |-- references.bib
|   |       `-- VERSION
|   |-- references/
|   |   |-- authoring-guide.md
|   |   |-- content-patterns.md
|   |   |-- input-handling.md
|   |   |-- quality-checklist.md
|   |   `-- visual-review.md
|   `-- scripts/
|       |-- create-deck.sh
|       |-- render-slides.sh
|       `-- verify-deck.sh
|-- docs/
|   `-- superpowers/
|       `-- specs/
|-- tests/
|   |-- fixtures/
|   |-- prompt-evals/
|   `-- test_*.sh
|-- .github/
|   `-- workflows/
|       |-- sync-template.yml
|       `-- test.yml
|-- CHANGELOG.md
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- THIRD_PARTY_LICENSES.md
`-- template-source.json
```

The nested package keeps repository-level documentation, CI, and development
tests out of users' skill context. Installation copies or links only the
`academic-beamer/` directory into a harness skill directory.

## Skill Metadata

`academic-beamer/SKILL.md` starts with portable Agent Skills frontmatter:

```yaml
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
```

Harness-specific fields such as `argument-hint`, invocation controls, and tool
allowlists are omitted. Experimental or unknown fields would reduce portability.
The exact bundled template version belongs in `template-source.json` rather than
duplicated frontmatter that can drift.

## `SKILL.md` Contents

The skill body should remain below 300 lines. Detailed examples and checklists
belong in `references/` and are loaded only when needed.

### 1. Purpose and Template Contract

State that the skill handles creation, revision, migration, compilation, and
review. Once invoked, it must copy or preserve the bundled `presentation.sty`
and starter. It must not switch to Madrid, Metropolis, a university theme, a
user-provided theme, or another design system.

Users may choose only options supported by the upstream template:

- Font size: `10pt`, `11pt`, or `12pt`.
- Aspect ratio: `43`, `1610`, or `169`.
- Mode: `light` or `dark`.
- Page numbers: enabled or disabled through the package option.

If the user has no preference, use the upstream defaults rather than inventing
new defaults.

### 2. Determine the Task

Classify the request as one of the following:

- Create a new deck.
- Revise an existing deck already using the bundled template.
- Migrate a nonconforming Beamer deck onto the bundled template.
- Compile and verify a deck.

New decks use the complete planning gate. Targeted revisions and verification
do not require the user to approve a new outline. Migration creates a separate
template-based destination unless the user explicitly chooses otherwise.

### 3. Inspect Inputs Before Asking Questions

Read the prompt and relevant local files before interviewing the user. Supported
inputs include `.tex`, `.bib`, `.pdf`, `.md`, `.docx`, images, and structured
data. Prefer original LaTeX, vector figures, and structured data over screenshots
or reconstruction from rendered pages.

Preserve factual claims, notation, citations, quotations, figure attribution,
and numerical results. Never invent missing evidence, references, or data.

### 4. Requirements Interview

Ask only for information not inferable from the inputs:

- Presentation purpose and talk type.
- Audience and assumed background.
- Duration and desired emphasis.
- Output language.
- Title, authors, date, and location.
- Supported template options when the defaults are unsuitable.

Questions should be derived from the supplied material rather than a generic
questionnaire.

### 5. New-Deck Outline Gate

For a new full deck, propose a narrative and slide-by-slide outline. Each entry
contains the frame title, purpose, content pattern, and source material. Estimate
slide count from duration as guidance, not as a rigid quota.

Do not generate the complete deck until the user explicitly approves the
outline. Small revisions, compilation, and review skip this gate.

### 6. Initialize or Preserve the Project

For a new deck, run `scripts/create-deck.sh <target-directory>`. The script
copies the bundled style, minimal starter, and bibliography placeholder without
overwriting existing files.

For revisions, preserve the user's filenames and project organization. Do not
silently rename, move, or delete user assets.

### 7. Authoring Rules

Follow the bundled template rather than creating a second design system:

- Keep one primary message per frame.
- Prefer sparse, readable slides and concise supporting text.
- Use demonstrated list, column, equation, figure, table, theorem, code,
  reference, and backup-slide patterns.
- Keep citation and figure attribution faithful to sources.
- Use `singlespace` only as a local density escape hatch.
- Use frame breaking for genuinely long references, code, tables, or
  derivations when splitting would damage comprehension.
- Avoid solving overflow with `\tiny`, arbitrary negative spacing, or package
  changes that alter the template globally.

Detailed guidance and LaTeX examples live in `references/content-patterns.md`
and `references/authoring-guide.md`.

### 8. Compilation

Use LuaLaTeX through `latexmk`:

```sh
latexmk -lualatex -interaction=nonstopmode -halt-on-error -file-line-error presentation.tex
```

Do not substitute direct `lualatex` calls, pdfLaTeX, or XeLaTeX. `latexmk`
handles bibliography processing and required reruns. Confirm from the build log
that `latexmk` actually selected LuaTeX or LuaHBTeX; fail verification if local
configuration redirected the build to another engine. pdfLaTeX and XeLaTeX
remain upstream Beamer-Template compatibility concerns only, not supported skill
runtime alternatives.

Inspect the log for compilation errors, missing files, undefined citations or
references, meaningful overfull or underfull boxes, and unresolved rerun
requests. Fix issues and rerun until the build passes or a concrete external
blocker remains.

### 9. Visual Verification

When PDF rendering and image inspection are available, run
`scripts/render-slides.sh <pdf-file> <output-directory>`. Inspect every numbered
slide image for clipping, overlap, unreadably small text, distorted figures,
poor contrast, inconsistent alignment, excessive density, and unintended blank
pages.

Fix visual defects and repeat compilation and inspection. If visual inspection
is unavailable, report that source and log verification passed but visual
verification was skipped.

### 10. Revision Loop

Apply feedback by frame title or page number. Recompile after each coherent
batch. Reinspect affected slides and nearby slides whose numbering or pagination
may have changed. Never resolve a defect by abandoning the bundled template.

### 11. Completion Report

Report:

- Source path and PDF path.
- Page count.
- Selected template options.
- LuaLaTeX compilation status and the LuaTeX or LuaHBTeX engine identified in
  the log.
- Remaining meaningful warnings.
- Visual-review status.
- Assumptions that still require user review.

## Supporting References

`content-patterns.md` distills reusable examples from the upstream demonstration
deck without copying the 608-line demo into each generated project.

`input-handling.md` defines how to inspect TeX, PDF, Word, Markdown, figures,
tables, data, and bibliographies. PDF figure extraction must prefer embedded or
vector assets. Full-page screenshots must not be presented as extracted figures.

`authoring-guide.md` covers narrative, density, timing, citation fidelity,
accessibility, and the supported template options.

`visual-review.md` defines deterministic per-slide visual checks and the
temporary image-rendering workflow.

`quality-checklist.md` contains the final acceptance criteria and distinguishes
required checks from optional checks that depend on installed tools or model
capabilities.

## Runtime Scripts

### `create-deck.sh`

- Accept exactly one target directory.
- Resolve paths relative to the script directory, not the caller's directory.
- Support target paths containing spaces.
- Create the target directory if its parent exists.
- Refuse to overwrite any destination template file.
- Copy only runtime template assets.
- Print the files created and the upstream template version.

### `verify-deck.sh`

- Accept one `.tex` file.
- Verify `latexmk` and `lualatex` are available.
- Run `latexmk -lualatex` from the deck directory.
- Confirm the build log identifies LuaTeX or LuaHBTeX as the engine, accepting
  log banners beginning with either `This is LuaTeX` or `This is LuaHBTeX`.
- Preserve and inspect the generated log.
- Fail on compilation errors, missing assets, unresolved citations or
  references, and meaningful overfull boxes.
- Print PDF path, page count, and a concise warning summary.

### `render-slides.sh`

- Accept a PDF and output directory.
- Require `pdftoppm` in the first release.
- Render numbered images at a resolution suitable for multimodal inspection.
- Refuse to overwrite an unrelated nonempty output directory.
- Confirm that rendered image count equals PDF page count.
- Keep rendering separate from interpretation; the invoking agent inspects the
  images.

## Data Flow

```text
Prompt + local source files
        |
        v
Input inspection and requirements interview
        |
        v
Approved slide-by-slide outline (new decks only)
        |
        v
Bundled template copied into destination
        |
        v
Deck content authored or revised
        |
        v
latexmk -lualatex -> PDF + log
        |
        v
Log checks -> PDF-to-images -> per-slide visual checks
        |
        v
Fix and repeat until accepted or concretely blocked
```

No network access is required during this runtime flow.

## Template Synchronization

The upstream template repository must publish tagged releases. The release
import set is:

- `presentation.sty`
- `presentation-minimal.tex`
- `LICENSE.txt`

`presentation-minimal.tex` is a new upstream distributable asset. Keeping it
upstream prevents package-interface changes from drifting away from the skill's
starter. During import it is renamed to
`academic-beamer/assets/template/presentation.tex`.

The skill owns its minimal `references.bib` placeholder because the upstream
demonstration bibliography is example content, not a runtime dependency.

`.github/workflows/sync-template.yml` runs on a weekly schedule and by manual
dispatch. It:

1. Queries the latest upstream GitHub release.
2. Compares its tag with `template-source.json`.
3. Downloads only the allowlisted files.
4. Calculates and records SHA-256 checksums.
5. Updates the provenance manifest and vendored assets.
6. Creates a branch and opens a pull request.

It never pushes directly to the default branch and never publishes a skill
release. A maintainer reviews and merges the synchronization PR after CI passes.

`template-source.json` records the upstream repository, release tag, source
commit, import timestamp, destination paths, and checksums.

The synchronization workflow also writes the release tag to
`academic-beamer/assets/template/VERSION`. This small runtime file lets the
installed `create-deck.sh` report the bundled version without depending on the
repository-level provenance manifest.

## Distribution and Installation

The portable package is the `academic-beamer/` subdirectory. README installation
instructions must use the locations currently supported by each harness:

- Codex and OpenCode: `~/.agents/skills/academic-beamer/`
- Claude Code: `~/.claude/skills/academic-beamer/`
- Project-local Codex/OpenCode: `.agents/skills/academic-beamer/`
- Project-local Claude Code: `.claude/skills/academic-beamer/`

Installation copies or links the package subdirectory, not repository-level
tests, documentation, or workflows. The first release documents installation
commands rather than modifying global agent instructions. A common ecosystem
installer may be documented later after compatibility is verified.

The README, skill frontmatter, and all other public runtime documentation state
that verified deck creation requires both `latexmk` and LuaLaTeX.

## Licensing

Original skill instructions, scripts, tests, and documentation use the MIT
license. Vendored template files retain the upstream LPPL-1.3c license and all
required copyright and maintainer notices.

`THIRD_PARTY_LICENSES.md` identifies the vendored template, source repository,
bundled release, and license. The upstream template should add explicit
copyright, maintenance status, current maintainer, and work-manifest notices as
required by LPPL before the first public skill release.

## Failure Handling

### Missing Build Tools

Do not install system packages automatically. Identify the missing command and
provide setup guidance. In particular, `verify-deck.sh` reports missing
`latexmk` and missing `lualatex` separately. Source generation may continue only
with user agreement, and completion must state that the deck was not compiled
with the mandatory LuaLaTeX workflow.

### Missing Bibliography or Figures

Treat the deck as unverified. Identify the referencing frame and path. Ask for
the source or remove the reference only with user approval.

### Existing Destination Files

Refuse to overwrite them. For migration, create a separate template-based deck
unless the user explicitly selects another destination.

### Compilation Failure

Preserve the log, fix source-level causes, and rerun `latexmk`. Never suppress
errors or switch engines or themes to pass the build.

### Persistent Warnings

Distinguish harmless package noise from undefined references, clipping risks,
and overfull boxes. Report every unresolved meaningful warning.

### Visual Tools Unavailable

Compilation can pass, but visual verification is recorded as skipped rather
than implied.

### Visual Defects

Revise content or layout within supported patterns. Do not hide overflow with
unreadable fonts, arbitrary negative spacing, or theme replacement.

## Verification and Tests

CI runs on Ubuntu and includes:

- `skills-ref validate academic-beamer`.
- TeX Live packages providing LuaLaTeX, including `texlive-luatex`, plus
  `latexmk`, Biber, and the template's LaTeX package dependencies.
- Shell tests for clean creation, paths containing spaces, repeated invocation,
  missing tools, and overwrite refusal.
- LuaLaTeX fixture builds covering citations, figures, equations, tables, code,
  light and dark modes, supported font sizes, and all three aspect ratios.
- Log-parser fixtures with representative errors and warnings.
- Renderer tests confirming one numbered image per PDF page.
- Static policy tests confirming the mandatory-template and LuaLaTeX contracts
  and rejecting pdfLaTeX or XeLaTeX as skill-runtime substitutes.
- License and provenance checks for every vendored file.

The skill repository does not duplicate the upstream multi-engine test suite.
Its 12-option fixture matrix tests the skill's mandatory LuaLaTeX workflow.
pdfLaTeX and XeLaTeX remain covered only by the separate upstream
Beamer-Template compatibility plan and checks. Optional macOS CI can be added
later if actual portability defects justify the cost.

Small prompt evaluations cover:

- Creating a new deck waits for outline approval.
- Targeted revision skips the new-deck outline gate.
- Migration retains content but adopts the bundled template.
- Verification uses `latexmk -lualatex`, confirms LuaTeX or LuaHBTeX in the log,
  and reports visual-check availability.
- A request for another theme is rejected while the skill is active.

Prompt evaluations may remain a documented manual release check if automated
model evaluation is too expensive or nondeterministic.

## Deck Acceptance Criteria

A completed deck:

- Uses the bundled, provenance-tracked `presentation.sty`.
- Uses only supported document-level template options.
- Contains no unreplaced placeholders.
- Builds successfully with `latexmk -lualatex`, with the log identifying LuaTeX
  or LuaHBTeX.
- Has no unresolved citations, references, missing assets, or rerun requests.
- Has no meaningful overfull box warnings.
- Passes every-slide visual inspection when rendering and multimodal inspection
  are available.
- Preserves source attribution and does not invent claims, results, or citations.
- Reports paths, page count, options, LuaLaTeX build and engine status, warnings,
  and visual status.

## Skill Release Acceptance Criteria

A public skill release:

- Passes all repository CI checks.
- Includes a valid `academic-beamer/SKILL.md` under 300 lines.
- Contains only runtime files inside the installable package.
- Identifies and checksums every upstream template asset.
- Compiles the bundled starter with the mandatory LuaLaTeX workflow.
- Documents installation for OpenCode, Codex, and Claude Code.
- Records both the skill version and bundled template version in the changelog.

## Upstream Prerequisites

Before the first automated synchronization, the Beamer template repository must:

1. Add and test `presentation-minimal.tex`.
2. Complete the LPPL copyright, maintainer, and work-manifest notices.
3. Publish a tagged GitHub release containing the approved import files.

These changes remain upstream template work. The skill repository consumes them
only from reviewed releases.
