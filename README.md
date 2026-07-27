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
- Biber

Biber is required even for citation-free decks because the bundled template
loads `biblatex-chicago` with the Biber backend.

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
