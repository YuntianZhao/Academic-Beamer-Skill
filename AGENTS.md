# AGENTS.md

## Package Boundary

`academic-beamer/` is the installable Agent Skill. Keep repository tests,
workflows, plans, and contributor documentation outside that directory.

## Required Checks

Run all repository checks from the root:
Allow approximately 15 minutes for the full suite.

```sh
bash tests/run_all.sh
```

Runtime deck verification must use `latexmk -lualatex` and confirm LuaTeX or
LuaHBTeX in the log. Do not substitute direct engine calls, pdfLaTeX, or
XeLaTeX. Generated test files belong under ignored temporary directories.

## Template Updates

Import only tagged releases from `YuntianZhao/Beamer-Template`. Never hand-edit
vendored `presentation.sty`; update it through the synchronization workflow.

## Agent skills

### Issue tracker

Issues, PRDs, and specs are tracked in this repository's GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default canonical triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

Use the single-context layout: root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
