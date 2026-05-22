# Release Pipeline Reference

**WHY:** Documents the release pipeline pattern used by the `pkg` skill.
**WHO:** Any maintainer running their own package releases.
**HOW:** Referenced by the `pkg` skill during execution.
**WHAT:** Pipeline stages, file locations, configuration template.

---

## Pipeline

```
pkg test     →  Run test suite only
pkg build    →  Test + create artifact
pkg release  →  Test + commit/push + artifact + tag + report
pkg status   →  Git status + last tag + test state
```

## Per-Project Configuration

The `pkg` skill is project-agnostic. Each project typically defines a small set of conventions:

| Item | Typical Location | Purpose |
|------|------------------|---------|
| Test suite | `tests/run-tests.sh`, `package.json` scripts.test, `pytest.ini` | Pass/fail gate |
| Release script | `release.sh`, `npm pack`, `python -m build` | Artifact creation |
| Install/docs | `README.md`, `INSTALL.md`, `installer.md` | User-facing instructions |
| Hooks config | `hooks.json` (if shipping Claude Code hooks) | Deployed alongside skill files |
| Distribution | `package.json` (npm), GitHub Releases, Notion page, registry | Where the artifact lands |

A minimal convention: keep one `release.sh` at the repo root that produces a single artifact file. The skill then handles tests, commit/push, tag, and reporting around it.

## Known Test Issues

Document any expected/accepted test failures in the project README so the skill knows not to block on them. Example:

> The `<test-name>` test in `<file>` is a known acceptable failure because `<reason>`. It is the only expected failure.

If the project has zero acceptable failures, the skill blocks on any failure.

## Artifact Contents

When using `git archive` to build a ZIP:
- Only **committed** files are included (untracked/modified files are excluded).
- Automatically excludes `.git/`, but you must add a `.gitattributes` with `export-ignore` for things like:
  - `node_modules/`
  - `.claude/`, `.vscode/`, `.DS_Store`
  - The artifact file itself
  - Any internal-only directories

Example `.gitattributes`:

```
node_modules/    export-ignore
.claude/         export-ignore
.vscode/         export-ignore
.DS_Store        export-ignore
*.zip            export-ignore
```

## Distribution Channels

Common distribution patterns the skill supports:

- **npm registry** — `npm publish` after `npm version`
- **GitHub Releases** — `gh release create <tag> --notes <changelog>`
- **Notion page / internal share** — manual upload step listed in the release report
- **Direct ZIP download** — artifact attached to a GitHub release or hosted on a static URL

The skill does not push to these channels automatically (except npm if configured). It produces the artifact and reports the manual steps so the maintainer can verify before publishing.
