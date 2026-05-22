<!--
SKILL SUMMARY
lint — Vault health-check. Scans Exo KB for orphan pages, broken wikilinks,
stale files, missing cross-references, and knowledge gaps. Uses Obsidian MCP.
Triggers: "lint vault", "vault health", "vault check", "check the vault"
-->

---
name: lint
description: Vault health-check — orphans, broken links, stale files, knowledge gaps
triggers: lint vault, vault health, vault check, check the vault
mcp_dependencies: obsidian
output: inline (terminal display)
---

# lint — Vault Health Check

## Triggers
- `lint vault`, `vault health`, `vault check`, `check the vault`

## What It Does
Periodic health-check of the Exo KB Obsidian vault. Inspired by Karpathy's "Lint" operation in the LLM Wiki pattern — find contradictions, orphan pages, stale claims, missing cross-references, and knowledge gaps.

## Steps

### 1. Orphan Scan
Use `obsidian_orphans` to find pages with no inbound links.
- Exclude: daily notes (`YYYY-MM-DD.md`), INDEX files, LOG.md, README.md, CLAUDE.md, templates/
- Report: list of orphan pages with file size and last modified date
- Flag pages >1KB as "worth connecting or archiving"

### 2. Broken Links
Use `obsidian_unresolved` to find wikilinks that point to non-existent pages.
- Report: each broken link with the source file that references it
- Suggest: create the missing page, or fix the link

### 3. Stale File Detection
Use `obsidian_recents` inverted — find files NOT modified in 90+ days.
- Focus on: `ExecOS/people/`, `ExecOS/accounts/`, `projects/`
- Exclude: `analyses/`, `observations/`, templates, reference files
- Report: stale files sorted by staleness, with last-modified date
- Flag accounts with status != archived that haven't been touched in 90 days

### 4. Cross-Reference Density
Use `obsidian_backlinks` on key hub pages (INDEX files, priority files, active project files).
- Report: pages that should be hubs but have <3 inbound links
- Suggest: which files should link to them

### 5. Provenance Audit
Spot-check 10 recent files for `origin:` frontmatter field.
- Report: percentage of recent files with provenance metadata
- Suggest: files missing the field that should have it

### 6. Activity Log Check
Read `LOG.md` and report:
- Total entries, entries in last 7 days, entries in last 30 days
- Most active verbs (create, update, graduate, etc.)
- Days with zero activity in the last 30 days

## Output Format

Display inline as a health report card:

```
VAULT HEALTH
═══════════════════════════
Orphans:        12 pages (3 worth connecting)
Broken Links:   4 unresolved wikilinks
Stale Files:    8 files untouched >90 days
Hub Density:    2 hub pages under-linked
Provenance:     70% of recent files have origin: field
Activity:       15 log entries this month

ACTIONS RECOMMENDED:
1. Connect or archive: [list top 3 orphans]
2. Fix broken links: [list]
3. Review stale accounts: [list]
```

## Guardrails
- Read-only. Never modify, delete, or archive files automatically.
- All recommendations require user approval before action.
- Do not report on files in `.obsidian/` or `.git/`.
