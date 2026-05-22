---
name: vault
description: >
  Use this skill when the user says "search my vault for [X]", "create a note about [X]",
  "what am I looking at?", "what's related to this?", "open [note] in Obsidian",
  "daily note", "add to today's note", "vault search", "graph search",
  "what links to [X]?", "show me orphans", "vault stats", "unresolved links",
  "create a [ref/wip/out] note", "create a person file", "create an account file",
  or references Obsidian, the vault, the knowledge graph, or note connections.
  Unified access to the Obsidian vault as a knowledge graph.
  Do NOT use for Apple Notes (use apple skill instead).
  Do NOT use for Things tasks (use things skill instead).
---

<!--
SKILL SUMMARY: vault
=========================
Knowledge graph operations on the Obsidian vault via the Obsidian CLI MCP server.

WHAT IT DOES:
  Searches, reads, creates, and navigates notes in the Obsidian vault.
  Goes beyond filesystem operations by using Obsidian's search index,
  backlinks, tags, frontmatter properties, and graph structure. Can create
  notes from templates (person, account, ref, wip, out, observation,
  decision, intel). Manages the daily note as a session log.

WHEN TO USE:
  - Search: vault search with line context, tag search, property search
  - Read: file contents, metadata, heading outline, frontmatter properties
  - Create: new notes from templates (person, account, ref, wip, out, etc.)
  - Graph: backlinks, outgoing links, orphans, unresolved links
  - Daily: read/append/prepend to today's daily note
  - Tasks: list open/completed tasks across the vault

WHEN NOT TO USE:
  - Apple Notes, Reminders, Calendar, Contacts (use apple)
  - Things 3 tasks (use things)
  - iMessage analysis (use imessage)
  - Files outside the vault (use filesystem tools directly)

DATA SOURCES:
  Obsidian MCP server (22 tools: 3 Search + 10 Files + 5 Graph + 4 Daily)
  Requires Obsidian app running with CLI enabled.

KEY RULES:
  - Always use obsidian_search (not grep) for vault content — it respects
    .obsidian ignore rules and uses Obsidian's index
  - Obsidian search operators: avoid "type:" and other reserved operators
    in query text — use plain text queries
  - For note creation, prefer template-based creation when a template exists
  - Daily note is the session log — append session milestones there
  - File resolution works by name (like wikilinks) or exact path
  - obsidian_move updates all wikilinks across the vault automatically
-->

# vault — Obsidian Knowledge Graph Operations

**WHY:** An Exo knowledge base can grow to thousands of files. Filesystem tools (grep, read, write) treat it as flat files. This skill navigates the vault as a knowledge graph — with backlinks, tags, semantic search, and template-based creation.
**WHO:** The user (personal knowledge base)
**HOW:** 22 tools via the Obsidian MCP server, wrapping the Obsidian CLI
**WHAT:** Vault search, graph navigation, template-based creation, daily note management, frontmatter operations

---

## Commands & Triggers

| Trigger | Category | What It Does |
|---|---|---|
| "search my vault for [X]", "vault search [X]" | **Search** | Search vault with line context |
| "what tags exist", "show me tags" | **Search** | List tags with counts |
| "what properties are used", "frontmatter stats" | **Search** | List YAML properties with counts |
| "read [note]", "show me [note]" | **Files** | Read a vault file by name or path |
| "what am I looking at?", "current file" | **Files** | Read the currently open file |
| "outline of [note]", "headings in [note]" | **Files** | Show heading structure |
| "create a note about [X]" | **Files** | Create with content |
| "create a [ref/wip/out] note" | **Files** | Create from template |
| "create a person file for [X]" | **Files** | Create from person template in `people/` folder |
| "create an account file for [X]" | **Files** | Create from account template in `accounts/` folder |
| "add [content] to [note]" | **Files** | Append to existing file |
| "move [note] to [folder]" | **Files** | Move file, update all wikilinks |
| "set [property] on [note]" | **Files** | Set frontmatter property |
| "what links to [X]?", "backlinks for [X]" | **Graph** | Incoming links (backlinks) |
| "what does [X] link to?" | **Graph** | Outgoing links |
| "show me orphans", "disconnected notes" | **Graph** | Files with no incoming links |
| "unresolved links", "broken links" | **Graph** | Wikilinks pointing to nonexistent files |
| "vault tasks", "open tasks" | **Graph** | Checkbox tasks across vault |
| "daily note", "today's note" | **Daily** | Read today's daily note |
| "add to today's note [content]" | **Daily** | Append to daily note |
| "vault stats", "vault info" | **Files** | Vault file/folder/size counts |
| "recent files", "what was I working on" | **Files** | Recently opened files |

---

## Process

### Vault Search

1. Use `obsidian_search` with the query text. Default limit 20.
2. For folder-scoped search, pass the `path` parameter (e.g. `people` or `projects`).
3. Results include file paths, line numbers, and matching text — present concisely.
4. If the user wants deeper exploration, suggest spawning a vault-research sub-agent.

**Search gotcha:** Obsidian's search language reserves operators like `type:`, `tag:`, `path:`, `file:`. Don't include these as literal text in queries. Use plain text queries and filter with the `path` parameter instead.

### Note Creation

The paths below are an example folder layout. Adapt to the user's vault structure:

1. Determine the file type from context:
   - Person → template: `person`, path: `people/<firstname-lastname>.md`
   - Account → template: `account`, path: `accounts/<company-name>.md`
   - Reference → template: `ref`, path: `projects/<project>/ref-<name>.md`
   - Work in progress → template: `wip`, path: `projects/<project>/wip-<name>.md`
   - Deliverable → template: `out`, path: `projects/<project>/out-<name>.md`
   - Observation → template: `observation`, path: `observations/YYYY-MM-DD.md`
   - Decision → template: `decision`, path: `decisions/YYYY-MM-DD-<topic>.md`
   - Intel → template: `intel`, path: `intel/YYYY-MM-DD-<source>-<topic>.md`
2. Use `obsidian_create` with `template` and `path` parameters.
3. If additional content beyond the template, use `obsidian_append` after creation.
4. For people and accounts, update the corresponding `INDEX.md` if one exists.

### Graph Navigation

1. Start with `obsidian_backlinks` for "what links to this?"
2. Use `obsidian_links` for "what does this link to?"
3. For neighborhood exploration: get backlinks → read each linking file's context → summarize the connections.
4. `obsidian_orphans` shows disconnected notes — useful for finding files that should be linked but aren't.
5. `obsidian_unresolved` shows broken wikilinks that need fixing.

### Daily Note

The daily note is the session log. Use it for:
- Session milestones ("Phase 2 complete")
- Quick captures that don't need their own file
- Links to files created during the session

Format: append with `## Section Header\n- bullet point` structure.

---

## Available Templates

These are example templates. The user's vault may include a subset, or additional templates not listed here.

| Template | For | Key Frontmatter |
|---|---|---|
| `person` | People files | name, org, title, type, email, linkedin, last_updated |
| `account` | Account/company files | name, type, tier, motion, status, hq, parent, last_updated |
| `ref` | Reference/context files | title, status, created |
| `wip` | Work in progress | title, status, created, author |
| `out` | Deliverables | title, status, created, author, notion_url, notion_db, notion_asset_type |
| `observation` | Daily TIL captures | (no frontmatter — heading-based) |
| `decision` | Decision records | title, status, created, owner, related |
| `intel` | Competitive/market signals | title, source, created, companies, tags |

---

## MCP Dependencies

- **Obsidian MCP** (`obsidian` in `~/.claude.json`) — 22 tools
- Requires Obsidian app running with CLI enabled
- Env: `OBSIDIAN_VAULT_NAME=<your-vault-name>`

---

## Output

- Search results → displayed inline (not written to files)
- Created notes → written to vault at appropriate path
- Daily note updates → appended to today's daily note
- Graph queries → displayed inline

---

## Learning Loop Integration

**Capture channel:** `vault-ops`
**What to capture:**
- Search patterns that don't return expected results (query syntax issues)
- Template gaps (file types that need templates but don't have one)
- Graph insights (unexpected connections or missing links)
- CLI behaviors that differ from documentation

**Graduation targets:**
- Search query patterns → this skill file (Process > Vault Search)
- New template types → `~/Exo/templates/` + this skill file (Available Templates)
- CLI gotchas → vault-ops reference notes
