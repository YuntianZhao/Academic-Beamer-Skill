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
