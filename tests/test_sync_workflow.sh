#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW="$ROOT_DIR/.github/workflows/sync-template.yml"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -f "$WORKFLOW" ] || fail 'sync-template.yml is missing'

for required in \
  'schedule:' \
  'cron: "17 8 * * 1"' \
  'workflow_dispatch:' \
  'concurrency:' \
  'group: sync-beamer-template-${{ github.repository }}' \
  'cancel-in-progress: false' \
  'contents: write' \
  'pull-requests: write' \
  'actions/checkout@v4' \
  'ref: ${{ github.event.repository.default_branch }}' \
  'persist-credentials: false' \
  'actions/setup-python@v5' \
  'python3 -m pip install skills-ref' \
  'presentation.sty' \
  'presentation-minimal.tex' \
  'LICENSE.txt' \
  'template-source.json' \
  'biber' \
  'latexmk' \
  'poppler-utils' \
  'texlive-bibtex-extra' \
  'texlive-fonts-extra' \
  'texlive-latex-extra' \
  'texlive-luatex' \
  'texlive-science' \
  'source_commit' \
  'sha256' \
  'imported_at' \
  'licenses = root / "THIRD_PARTY_LICENSES.md"' \
  'printf '\''changed=false\n'\'' >> "$GITHUB_OUTPUT"' \
  'agentskills validate academic-beamer' \
  'bash tests/run_all.sh' \
  'canonical_branch="automation/template-$TAG"' \
  'gh pr list --state open' \
  'matching-refs/heads/$canonical_branch' \
  'GITHUB_RUN_ID' \
  'GITHUB_RUN_ATTEMPT' \
  'gh auth setup-git --hostname github.com --force' \
  'gh pr create'; do
  rg --fixed-strings --quiet "$required" "$WORKFLOW" || fail "workflow is missing: $required"
done

for forbidden in \
  'skills-ref validate academic-beamer' \
  'persist-credentials: true' \
  'x-access-token' \
  'git push --force' \
  'git push -f' \
  'git push origin main' \
  'git push origin master' \
  'gh release create' \
  'raw.githubusercontent.com/YuntianZhao/Beamer-Template/main'; do
  if rg --fixed-strings --quiet "$forbidden" "$WORKFLOW"; then
    fail "workflow contains forbidden behavior: $forbidden"
  fi
done

python3 - "$WORKFLOW" <<'PY'
import pathlib
import sys

workflow = pathlib.Path(sys.argv[1]).read_text()
token = "${{ github.token }}"


def fail(message):
    raise SystemExit(f"FAIL: {message}")


def step(name):
    marker = f"      - name: {name}\n"
    start = workflow.find(marker)
    if start < 0:
        fail(f"workflow step is missing: {name}")
    end = workflow.find("\n      - ", start + len(marker))
    return workflow[start:] if end < 0 else workflow[start:end]


allowed_token_steps = {
    "Resolve latest upstream release",
    "Download allowlisted assets",
    "Update provenance",
    "Open update pull request",
}
if workflow.count(token) != len(allowed_token_steps):
    fail("GitHub token must appear only in the four API/publication steps")
for name in allowed_token_steps:
    if token not in step(name):
        fail(f"GitHub token is not scoped to step: {name}")
if "\n    env:\n" in workflow:
    fail("workflow must not define a job-wide environment")
if token in step("Verify synchronized package"):
    fail("synchronized package tests must run without a GitHub token")

checkout_start = workflow.find("      - uses: actions/checkout@v4\n")
checkout_end = workflow.find("\n      - ", checkout_start + 1)
checkout = workflow[checkout_start:checkout_end]
for required in (
    "ref: ${{ github.event.repository.default_branch }}",
    "persist-credentials: false",
):
    if required not in checkout:
        fail(f"checkout policy is missing: {required}")

patterns = [
    line.strip()
    for line in workflow.splitlines()
    if line.strip().startswith("--pattern ")
]
expected_patterns = [
    "--pattern presentation.sty \\",
    "--pattern presentation-minimal.tex \\",
    "--pattern LICENSE.txt",
]
if patterns != expected_patterns:
    fail("release download patterns must exactly match the three-file allowlist")

for required in (
    "cp .template-import/presentation.sty academic-beamer/assets/template/presentation.sty",
    "cp .template-import/presentation-minimal.tex academic-beamer/assets/template/presentation.tex",
    "cp .template-import/LICENSE.txt academic-beamer/assets/template/LICENSE.txt",
    "printf '%s\\n' \"$TAG\" > academic-beamer/assets/template/VERSION",
    'licenses = root / "THIRD_PARTY_LICENSES.md"',
    'text = re.sub(r"release `[^`]+`", f"release `{tag_name}`", text, count=1)',
):
    if required not in workflow:
        fail(f"synchronization update is missing: {required}")

changed_condition = "if: steps.release.outputs.changed == 'true'"
for name in (
    "Download allowlisted assets",
    "Update provenance",
    "Verify synchronized package",
    "Open update pull request",
):
    if changed_condition not in step(name):
        fail(f"no-change run does not skip step: {name}")
if workflow.count(changed_condition) != 4:
    fail("only the four update steps may be gated on a changed release")

publication = step("Open update pull request")
for required in (
    "gh pr list --state open",
    "exit 0",
    'canonical_branch="automation/template-$TAG"',
    "matching-refs/heads/$canonical_branch",
    "GITHUB_RUN_ID",
    "GITHUB_RUN_ATTEMPT",
    "gh auth setup-git --hostname github.com --force",
):
    if required not in publication:
        fail(f"publication retry policy is missing: {required}")
PY

printf 'Synchronization workflow checks passed.\n'
