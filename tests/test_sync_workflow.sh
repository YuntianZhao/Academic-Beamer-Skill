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
  'contents: read' \
  'contents: write' \
  'pull-requests: write' \
  'ref: ${{ github.event.repository.default_branch }}' \
  'persist-credentials: false' \
  'python3 -m pip install skills-ref==0.1.1' \
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
  '.github/scripts/select-sync-branch.sh "$TAG"' \
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
import re
import sys

lines = pathlib.Path(sys.argv[1]).read_text().splitlines()
workflow = "\n".join(lines)
token = "${{ github.token }}"


def fail(message):
    raise SystemExit(f"FAIL: {message}")


def indentation(line):
    return len(line) - len(line.lstrip())


def block(source, marker):
    try:
        start = source.index(marker)
    except ValueError:
        fail(f"workflow structure is missing: {marker.strip()}")
    indent = indentation(marker)
    end = len(source)
    for index in range(start + 1, len(source)):
        line = source[index]
        if line.strip() and indentation(line) <= indent:
            end = index
            break
    return source[start:end]


def action_step(source, name):
    pattern = re.compile(
        rf"^\s*(?:-\s+)?uses: {re.escape(name)}@[0-9a-f]{{40}}\s+#\s+v[0-9].*$"
    )
    matches = [line for line in source if pattern.fullmatch(line)]
    if len(matches) != 1:
        fail(f"expected one immutable {name} action with a release comment")
    return block(source, matches[0])


def job(name):
    return block(lines, f"  {name}:")


def step(job_lines, name):
    return block(job_lines, f"      - name: {name}")


def text(source):
    return "\n".join(source)


def permissions(job_lines):
    permission_lines = block(job_lines, "    permissions:")[1:]
    return [line.strip() for line in permission_lines if line.strip()]


def script(step_lines):
    try:
        start = step_lines.index("        run: |")
    except ValueError:
        fail(f"step has no shell script: {step_lines[0].strip()}")
    return [line.strip() for line in step_lines[start + 1:] if line.strip()]


prepare = job("prepare")
publish = job("publish")
prepare_text = text(prepare)
publish_text = text(publish)

if any(line == "permissions:" for line in lines):
    fail("workflow must not grant top-level permissions")
if permissions(prepare) != ["contents: read"]:
    fail("prepare job permissions must be exactly contents: read")
if permissions(publish) != ["contents: write", "pull-requests: write"]:
    fail("publish job must have only contents and pull-request write permissions")
if "    needs: prepare" not in publish:
    fail("publish job must depend on prepare")
if "    if: needs.prepare.outputs.changed == 'true'" not in publish:
    fail("publish job must be skipped when prepare reports no change")

for job_name, job_lines in (("prepare", prepare), ("publish", publish)):
    checkout = action_step(job_lines, "actions/checkout")
    checkout_text = text(checkout)
    for required in (
        "ref: ${{ github.event.repository.default_branch }}",
        "persist-credentials: false",
    ):
        if required not in checkout_text:
            fail(f"{job_name} checkout policy is missing: {required}")

action_step(prepare, "actions/setup-python")
if "actions/setup-python@" in publish_text:
    fail("publish job must not set up dependency runtimes")

prepare_token_steps = (
    "Resolve latest upstream release",
    "Download allowlisted assets",
    "Update provenance",
)
if prepare_text.count(token) != len(prepare_token_steps):
    fail("prepare token must be limited to three read-only API steps")
for name in prepare_token_steps:
    if token not in text(step(prepare, name)):
        fail(f"prepare token is not scoped to step: {name}")
if token in text(step(prepare, "Verify synchronized package")):
    fail("prepare validation must not receive even the read-only token")
if publish_text.count(token) != 1:
    fail("publish token must appear only in the PR publication step")
if token not in text(step(publish, "Open update pull request")):
    fail("publish token is not scoped to PR publication")

for name in (
    "Install skill validator",
    "Install build dependencies",
    "Download allowlisted assets",
    "Update provenance",
    "Verify synchronized package",
):
    step(prepare, name)
    if f"      - name: {name}" in publish:
        fail(f"downloaded-source or dependency step appears in publish: {name}")
for forbidden in (
    "pip install",
    "apt-get",
    "latexmk",
    "lualatex",
    "agentskills validate",
    "tests/run_all.sh",
    "gh release download",
):
    if forbidden in publish_text:
        fail(f"publish job executes forbidden content: {forbidden}")

patterns = [line.strip() for line in prepare if line.strip().startswith("--pattern ")]
if patterns != [
    "--pattern presentation.sty \\",
    "--pattern presentation-minimal.tex \\",
    "--pattern LICENSE.txt",
]:
    fail("release download patterns must exactly match the three-file allowlist")

download_script = text(step(prepare, "Download allowlisted assets"))
for required in (
    "cp .template-import/presentation.sty academic-beamer/assets/template/presentation.sty",
    "cp .template-import/presentation-minimal.tex academic-beamer/assets/template/presentation.tex",
    "cp .template-import/LICENSE.txt academic-beamer/assets/template/LICENSE.txt",
    "printf '%s\\n' \"$TAG\" > academic-beamer/assets/template/VERSION",
):
    if required not in download_script:
        fail(f"prepare asset update is missing: {required}")
provenance_script = text(step(prepare, "Update provenance"))
for required in (
    'licenses = root / "THIRD_PARTY_LICENSES.md"',
    'text = re.sub(r"release `[^`]+`", f"release `{tag_name}`", text, count=1)',
):
    if required not in provenance_script:
        fail(f"prepare provenance update is missing: {required}")

changed_condition = "if: steps.release.outputs.changed == 'true'"
for name in (
    "Download allowlisted assets",
    "Update provenance",
    "Verify synchronized package",
    "Upload prepared update",
):
    if changed_condition not in text(step(prepare, name)):
        fail(f"no-change run does not skip prepare step: {name}")
if prepare_text.count(changed_condition) != 4:
    fail("only the four prepare update steps may be gated on a changed release")

upload = step(prepare, "Upload prepared update")
action_step(upload, "actions/upload-artifact")
try:
    path_start = upload.index("          path: |")
except ValueError:
    fail("prepared artifact must use an explicit multiline path allowlist")
artifact_paths = []
for line in upload[path_start + 1:]:
    if line.strip() and indentation(line) <= 10:
        break
    if line.strip():
        artifact_paths.append(line.strip())
expected_paths = [
    "academic-beamer/assets/template/presentation.sty",
    "academic-beamer/assets/template/presentation.tex",
    "academic-beamer/assets/template/LICENSE.txt",
    "academic-beamer/assets/template/VERSION",
    "template-source.json",
    "THIRD_PARTY_LICENSES.md",
]
if artifact_paths != expected_paths:
    fail("prepared artifact must contain exactly the six synchronized files")

download = step(publish, "Download prepared update")
action_step(download, "actions/download-artifact")
apply_commands = script(step(publish, "Apply prepared files"))
expected_copies = [f"cp .template-update/{path} {path}" for path in expected_paths]
if apply_commands != expected_copies:
    fail("publish must copy exactly the six prepared files to fixed destinations")

publish_steps = [
    line.strip()
    for line in publish
    if indentation(line) == 6 and line.lstrip().startswith("- ")
]
if len(publish_steps) != 4 or not re.fullmatch(
    r"- uses: actions/checkout@[0-9a-f]{40}\s+#\s+v[0-9].*", publish_steps[0]
) or publish_steps[1:] != [
    "- name: Download prepared update",
    "- name: Apply prepared files",
    "- name: Open update pull request",
]:
    fail("publish job contains an unexpected step")

publication = text(step(publish, "Open update pull request"))
for required in (
    '.github/scripts/select-sync-branch.sh "$TAG"',
    "exit 0",
    "gh auth setup-git --hostname github.com --force",
    "git push --set-upstream origin \"$branch\"",
    "gh pr create",
):
    if required not in publication:
        fail(f"publication policy is missing: {required}")
for forbidden in (".template-update", "git push --force", "git push -f"):
    if forbidden in publication:
        fail(f"publication executes or force-pushes prepared content: {forbidden}")
PY

printf 'Synchronization workflow checks passed.\n'
