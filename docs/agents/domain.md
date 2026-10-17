# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY-MAP.md`**, if present at the repo root: follow its links to each `GLOSSARY.md` relevant to the topic. Otherwise, read the root **`GLOSSARY.md`**.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in. For contexts identified by a glossary map, also check their context-local `docs/adr/` directories.

If any of these documents don't exist, **proceed silently**. Don't flag their absence or suggest creating them upfront. The `/domain-modeling` skill creates domain docs lazily when terms or decisions actually get resolved.

## File structure

This is a single-context repo:

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── 0001-example-decision.md
│   └── 0002-another-decision.md
└── academic-beamer/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, or a test name), use the term as defined in the relevant `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (example decision) — but worth reopening because…_
