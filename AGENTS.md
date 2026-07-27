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
