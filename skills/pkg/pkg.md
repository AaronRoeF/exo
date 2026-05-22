---
name: pkg
description: >
  Use this skill when the user says "pkg release", "pkg build", "pkg test", or "release <project>".
  Release pipeline for a personal package or repo — runs tests, builds a distributable ZIP, commits/pushes,
  tags, and reports a SHA-256 hash.
---

<!--
SKILL SUMMARY: pkg
==========================
Release pipeline for a maintained package or repo — automated test, build, and release workflow.

WHAT IT DOES:
  Automates a release pipeline: runs the project's test suite, builds a
  distributable ZIP via git archive, commits and pushes changes, creates
  release tags, and produces a release report with SHA-256 hash. Supports
  four modes from test-only to full release.

WHEN TO USE:
  - pkg test — run the project's test suite, report results
  - pkg build — run tests + create ZIP (no push, no upload)
  - pkg release — full pipeline: test + commit/push + ZIP + tag + report
  - pkg status — show current state: git status, last release tag, test results
  - release <project> — alias for pkg release

WHEN NOT TO USE:
  - Modifying source files outside the release process (this skill only packages)
  - Releasing to branches other than main (configurable per project)
  - Any changes to Exo itself

DATA SOURCES:
  Project repo (path provided by user or auto-detected from cwd)
  Test suite (project-defined runner — e.g. tests/run-tests.sh, npm test, pytest)
  Release script (project-defined — e.g. release.sh, npm pack, git archive)

KEY RULES:
  - Never release if tests fail (unless the user explicitly overrides)
  - Never modify source files during a release
  - Never push to a branch other than the configured release branch
  - Always show the user what will be committed before committing
-->

# pkg — Release Pipeline

**WHY:** Releasing a package manually means remembering a dozen steps — test, build, tag, hash, upload, publish. This skill automates the pipeline so releases are consistent and nothing gets missed.
**WHO:** The maintainer of a package or repo who ships their own releases.
**HOW:** `pkg <command>` — runs tests, builds artifact, commits/pushes, tags, and reports.
**WHAT:** Test suite execution, artifact creation, git tagging, SHA-256 verification, release reports.

---

## Commands

| Trigger | Mode | What It Does |
|---------|------|-------------|
| `pkg test` | **Test Only** | Run the project's test suite, report results |
| `pkg build` | **Build Only** | Run tests + create artifact (no push, no upload) |
| `pkg release` | **Full Release** | Test + build + commit + push + create artifact + tag + report |
| `pkg status` | **Status Check** | Show current state: git status, last release tag, test results |

Also triggers on: "release <project>", "package <project>", "ship it".

---

## Step 1 — Mode Detection

Match user input to one of the four modes above.

| If the user says... | Mode |
|---|---|
| "pkg test" / "test <project>" / "run the tests" | Test Only |
| "pkg build" / "build <project>" / "create the artifact" | Build Only |
| "pkg release" / "release <project>" / "ship it" / "package and release" | Full Release |
| "pkg status" / "release status" / "where are we" | Status Check |

If ambiguous, default to **Full Release**.

### Status Check Output

When the user runs `pkg status`, gather and display:

```
## Release Status — <project>

**Branch:** [current branch]
**Working tree:** [clean / N uncommitted changes]
**Last release tag:** [tag] ([date])
**Commits since last release:** [N]

### Recent Commits
[git log --oneline -5]
```

Then stop — no further steps.

---

## Step 2 — Pre-flight (all modes)

### 2.1 — Set working directory

Use the project directory provided by the user, or auto-detect from the current working directory. Example:

```bash
cd ~/<project>/
```

Confirm the directory exists and is a git repo. If not, stop and report.

### 2.2 — Run test suite

Run whatever test command the project defines. Common examples:

```bash
bash tests/run-tests.sh    # shell-based suite
npm test                    # node project
pytest                      # python project
```

### 2.3 — Parse results

Extract pass/fail count from test output. Look for the summary line.

### 2.4 — Evaluate failures

- If the project has known/expected failures (documented in the repo), report them but do not block.
- If all other tests pass, proceed.
- If there are **unexpected failures**:
  - Display the failures clearly
  - Ask the user: "Fix now or release anyway?"
  - If the user says fix: help them fix, then re-run tests
  - If the user says release anyway: proceed with a warning in the final report

### 2.5 — Test Only mode stops here

If mode is **Test Only**, output a test report and stop:

```
## Test Results — <project>

**Result:** [X]/[Y] passed
**Known failures:** [list any known/expected failures]
**Unexpected failures:** [list or "None"]

### Details
[relevant test output]
```

---

## Step 3 — Build (Build + Release modes)

### 3.1 — Check git status

```bash
git status
```

- If there are uncommitted changes, list them and warn the user.
- If **Release mode**: show the user what will be committed and ask for confirmation before proceeding.
- If **Build Only mode**: warn but do not commit (untracked/modified files will be excluded from an archive built with `git archive`).

### 3.2 — Commit and push (Release mode only)

Only if there are staged or unstaged changes AND the user confirms:

1. Show the diff: `git diff` and `git diff --cached`
2. Stage changes: `git add` the relevant files (never `git add -A` blindly — show the user first)
3. Commit with a descriptive message
4. Push to the release branch (typically `main`): `git push origin main`

**Never push to a branch other than the configured release branch.**

### 3.3 — Create artifact

Run the project's release/build command. Common examples:

```bash
bash release.sh    # git archive ZIP creation
npm pack           # node tarball
python -m build    # python sdist/wheel
```

### 3.4 — Verify artifact

1. Confirm the artifact file exists
2. Report file size: `ls -lh <artifact>`
3. Compute SHA-256: `shasum -a 256 <artifact>`

### 3.5 — Build Only mode stops here

If mode is **Build Only**, output a build report and stop:

```
## Build Report — <project>

**Tests:** [X]/[Y] passed ([known failures noted])
**Artifact:** <name> ([size])
**SHA-256:** [hash]

Note: No commit, push, or tag was created (build-only mode).
```

---

## Step 4 — Release (Release mode only)

### 4.1 — Create git tag

Default tag format: `release/YYYY-MM-DD`. If your project uses semver, use `vX.Y.Z` instead.

If the tag already exists (multiple releases in one day), use `release/YYYY-MM-DD-N` where N increments (2, 3, etc.).

```bash
git tag release/YYYY-MM-DD
git push origin release/YYYY-MM-DD
```

For npm packages, also publish:

```bash
npm version patch    # or minor / major
npm publish
```

For GitHub releases, optionally create one with the changelog:

```bash
gh release create release/YYYY-MM-DD --notes "$(cat CHANGELOG.md)"
```

### 4.2 — Generate changelog

```bash
git log --oneline [previous-release-tag]..HEAD
```

If no previous release tag exists, use the last 10 commits.

### 4.3 — Post-release distribution (optional)

If the project distributes through a separate channel (Notion page, internal share, registry), tell the user the exact steps to upload — including the artifact path and the destination URL.

---

## Step 5 — Report

Output a release summary for every mode that reaches this point:

```markdown
## Release — <project> — [date]

**Tests:** [X]/[Y] passed ([known failures noted])
**Artifact:** <name> ([size])
**SHA-256:** [hash]
**Commit:** [short hash] — [message]
**Tag:** release/[date]

### Changes Since Last Release
[git log --oneline output]

### Manual Steps Remaining
- [ ] Any post-release distribution steps
- [ ] Announcement / changelog publication
```

---

## Configuration

The skill is project-agnostic. Configure per-project by either:

1. Passing context inline: "pkg release <your-username>/<your-repo>"
2. Running from inside the project directory (cwd auto-detection)
3. Defining a small per-project config (see `ref-release-pipeline.md` for the template)

Example projects this skill works well for:
- MCP servers (e.g., `<your-username>/<your-repo>-mcp`)
- npm packages
- Personal CLI tools
- Skill packs distributed as ZIPs

---

## Error Handling

**Repo not found:** "Project repo not found at <path>. Is it cloned?"

**Test suite missing:** "Test command not found. Has the project's test runner been defined?"

**Release script missing:** "Release script not found. Cannot create artifact without a build command."

**Git push fails:** Show the error. Common causes: auth expired, branch protection, network. Do not retry automatically.

**Tag already exists:** Increment the suffix: `release/YYYY-MM-DD-2`, `-3`, etc.

**npm publish fails:** Show the error. Common causes: not logged in (`npm login`), version already published, 2FA required.

---

## Guardrails

- **Never release if tests fail** (unless the user explicitly overrides after seeing the failures).
- **Never modify source files during a release** — this skill only packages.
- **Never push to a branch other than the configured release branch.**
- **Never overwrite a published version** without explicit user confirmation.
- **Always show the user what will be committed** before committing.
- **No emojis.** Direct, clear output.
