# Architecture

> **WIFM:** You can understand Exo in one diagram and three sentences.

Exo runs in two surfaces (Claude Code and Claude Desktop), shares one local data layer (`~/Exo/`), and does its real work in three loops: capture, consolidate, promote. Everything else is wiring around those three things.

---

## The dual-shipping diagram

```
+---------------------------+        +---------------------------+
|     Claude Code           |        |     Claude Desktop        |
|  (full Exo: hooks +       |        |  (lite mode: MCP +        |
|   slash commands +        |<------>|   Project Instructions    |
|   shell + skills)         |        |   + dream-by-hand)        |
+-----------+---------------+        +---------------+-----------+
            |                                        |
            |       both surfaces read/write         |
            |       through the same data layer      |
            v                                        v
            +----------------------------------------+
            |              ~/Exo/                    |
            |  people/   accounts/   decisions/      |
            |  intel/    observations/   projects/   |
            |  personality/   skills/   hooks/       |
            +----------------------------------------+
                              ^
                              |
            +----------------------------------------+
            |          exo-mcp server                |
            |  (read/write the data layer from any   |
            |   client that speaks MCP)              |
            +----------------------------------------+
```

The data layer is the source of truth. Surfaces are interchangeable. Lose either one, you still have your Exo state.

---

## The data layer (`~/Exo/`)

Plain markdown plus a few JSON files. No SQLite, no proprietary format, no daemon. You can read everything with `cat` and edit everything with any text editor.

| Directory | What's in it | Owned by |
|---|---|---|
| `people/<firstname-lastname>.md` | One file per key contact. Frontmatter + Context bullets + Interactions log. | Capture (auto-append), wrap/prep (structured update). |
| `accounts/<company-name>.md` | One file per active account or prospect. Frontmatter + Why-OPAQUE + Key People + Timeline. | Capture + account-related skills. |
| `decisions/YYYY-MM-DD-<topic>.md` | One file per significant decision (RFD or ADR style). | You (manual create), Exo (suggested create). |
| `intel/YYYY-MM-DD-<source>-<topic>.md` | Captured signals from competitive research, market reads, customer calls. | Capture skills. |
| `observations/YYYY-MM-DD.md` | The raw capture stream. One file per day. Bullet per observation. | Capture hooks + the user (TIL command). |
| `projects/<project>/PULSE.md` | One project tracker per active project. Frontmatter + status + next actions + last stop. | You (manual update), Exo (auto-bump fields). |
| `personality/exo-personality.md` | The shipped Exo personality. Swap or fork freely. | You (only edit through RFC if you're contributing back). |

Everything is version-control-friendly. Most users put `~/Exo/` under git (or iCloud + a sidecar git directory) and treat it like a personal monorepo.

---

## Loop 1 — Capture

> Signal lands as a side effect of working. You don't structure it in the moment.

Triggers:

- **SessionStart hook** — renders the active-project dashboard, asks you to declare focus, and seeds the day's observation file.
- **PreToolUse / PostToolUse hooks** — append targeted signals (file edits across project boundaries, MCP calls worth logging).
- **User-initiated TIL** — typing `TIL: <thing>` in any session appends to today's observation file immediately.
- **End-of-day prompt** — when you signal you're wrapping (`EOD`, `done for today`, `signing off`), Exo proposes 2–5 TIL candidates from the session.

All captures land in two places: `observations/YYYY-MM-DD.md` (raw stream) and the relevant typed file (people, account, project) if the signal mentions one.

---

## Loop 2 — Consolidate (the dream pass)

> Acknowledgment: cross-session memory consolidation is a small but real wave right now. Anthropic shipped Dreaming for Managed Agents in early May 2026; OpenClaw Dreaming and `claude-memory-compiler` ship adjacent patterns. Exo's contribution is the discipline around the loop, not the loop itself.

Triggers:

- Manual: `/dream`.
- Scheduled (optional): a background launchd job nightly.

What the dream pass does:

1. **Read the five-source corpus.** Today's observations, auto-memory snapshots, all active PULSEs, the REVIEW-LOG ledger, and the skill-gotchas registry.
2. **Apply the echo-chamber guard.** Filter out anything that originated as a user-authored rule (CLAUDE.md entries, prior corrections, locked memories). Without this filter, the consolidator mostly rediscovers what you already told it.
3. **Detect patterns.** Cross-source, cross-day. A signal that appears N times in M days, across at least two source types, qualifies as a candidate.
4. **Generate proposals.** Each candidate becomes a proposed change with a diff (where it would land, what it would say).
5. **Apply the cap + watch list.** Cap proposals per dream pass to prevent flooding. Anything over the cap goes onto a watch list with an age counter that survives across runs.
6. **Write the dream report.** A single markdown file you can read in five minutes. Approve, defer, or reject per proposal.

---

## Loop 3 — Promote

> Proposals become rules only with your approval. Defaults bias toward conservative.

Approved proposals land as edits to the right file:

- A new behavioral rule → into the matching skill file's gate or the matching `CLAUDE.md`.
- A new gotcha → into `skill-gotchas.md`.
- A people/account update → into the typed file.
- A new decision → into `decisions/`.

Every promotion gets a row in `REVIEW-LOG.md` (timestamp, what graduated, what file). This is the audit trail and the dedup source for future dream passes.

**Demote, don't delete.** When a rule stops being useful, Exo proposes demotion — moving it to an archived section, not removing it. The history of how Exo got smarter stays inspectable.

---

## Hooks

| Hook | Fires on | Job |
|---|---|---|
| `session-start` | New Claude Code session | Render dashboard, seed today's observation file, clear focus lock. |
| `focus-gate` | PreToolUse on Edit/Write | If you're editing outside your declared focus project, inject a context-switch warning. |
| `til-flow` | User types `TIL:` | Append immediately to today's observation file. |
| `stop-dream` | End of a dream pass | Compact the dream report, update REVIEW-LOG, age the watch list. |

Hooks live in `~/.claude/hooks/exo-*.sh`. Each is small (≤100 lines), inspectable, and safe to disable individually.

---

## MCP integration

Exo treats MCP servers as the integration surface for everything outside the local data layer. The shipped wizard offers OAuth setup for the common ones (Google Calendar, Gmail, Notion). Adding a new MCP:

1. Install the MCP server (npm, pip, or binary).
2. Add it to `~/.claude.json` under `mcpServers`.
3. Restart Claude Code.
4. Add a one-line capture rule in the relevant skill file telling Exo when to read from it.

See `docs/customization.md` for examples.

---

## Why this shape

Three design decisions drove the architecture:

1. **Local-first, always.** The data layer is on your machine. There is no Exo cloud, no Exo account, no telemetry. If Exo as a project goes away tomorrow, your `~/Exo/` directory keeps working with any text editor.

2. **Plain markdown, plain git.** Every Exo artifact is human-readable and human-editable. The system has to remain inspectable. If you ever need to know why Exo did something, the answer is in a file you can open.

3. **Hooks over prompts.** Behavioral rules embedded in prompts degrade after compaction. Hooks fire mechanically. Anything that has to survive a long session goes in a hook, not in `CLAUDE.md`.
