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
