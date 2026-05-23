# Exo Architecture — one-page picture

**What this is for you:** A single picture that shows how Exo's pieces fit together — and where the actual magic lives — so you can decide if the architecture matches how you work before you install anything. Read the diagram, read the "why the KB is the magic" note, decide.

ASCII rendered version below — designed to read cleanly at a glance, with no rendering dependency. (Mermaid source archived at `architecture-diagram-mermaid.md` if you ever want to regenerate an image; PNG is no longer load-bearing for the marketplace listing.)

---

```
                           +-----------+
                           |    YOU    |
                           +-----+-----+
                                 |
              daily work         |         occasional use
          +----------------------+---------------------+
          |                                            |
          v                                            v
   +--------------------+                    +--------------------+
   |    Claude Code     |                    |   Claude Desktop   |
   |  (full experience) |                    |     (lite mode)    |
   +---------+----------+                    +----------+---------+
             |                                          |
             | 13 skills · 5 slash cmds · 4 hooks       | exo-mcp server
             |                                          | (8 MCP tools)
             +---------------------+--------------------+
                                   | read + write
                                   v
   +-------------------------------------------------------------------+
   |        ***  ~/Exo/  --  THIS IS THE MAGIC  ***                    |
   |                                                                   |
   |   plain text · markdown · on your machine · never leaves          |
   |   maintains state + context · outlives every tool that reads it   |
   |                                                                   |
   |   projects/<name>/pulse.md                                        |
   |   people/<name>.md                                                |
   |   accounts/<company>.md                                           |
   |   decisions/<date>-<topic>.md                                     |
   |   intel/<date>-<source>-<topic>.md                                |
   |   observations/<date>.md                                          |
   +---------------------------+---------------------------------------+
                               |
                       observations accumulate
                       as a side effect of work
                               |
                               v
                  +-----------------------------+
                  |     DREAM  (weekly)         |
                  |                             |
                  |  5 sources                  |
                  |    -> echo-chamber filter   |
                  |    -> cross-day patterns    |
                  |    -> cap + watch-list      |
                  |    -> graduation candidates |
                  +--------------+--------------+
                                 |
                       you approve what survives
                                 |
                                 v
                  +-----------------------------+
                  |    rules layer updates      |
                  |                             |
                  |  CLAUDE.md  ·  MEMORY.md    |
                  |  skills/*.md                |
                  +--------------+--------------+
                                 |
                       read at next session start;
                       the next session is smarter
                       than the last
                                 |
                                 +-----> loop closes; back to Code
```

---

## Why the `~/Exo/` Knowledge Base is the magic (not the surfaces)

Look at the diagram again. Both surfaces (Claude Code, Claude Desktop) and all the tools (Skills, Commands, Hooks, MCP) exist in service of one thing: writing to and reading from `~/Exo/`. The KB is the hub. Everything else is a spoke.

This is deliberate. The surfaces will change — Anthropic will ship new tools, plugins, modes; the MCP server will get rewritten; the skill bodies will evolve. But your `~/Exo/` is plain markdown. It outlives every tool that reads it. It's the only part of Exo that is unambiguously yours.

Two reasons this matters:

**One — it's where the mental model lives.** KM systems (wikis, Notion, every SaaS knowledge tool) are really information storage and retrieval. They hold text; they don't hold a model of *you*. Your `~/Exo/` is different — it accumulates a working model of your projects, your people, your decisions, your patterns. Every skill reads it before acting. Every meeting wrap updates it. Every weekly dream consolidates it. The KB isn't a database for tools; it's the instantiated mental model that the tools augment.

**Two — it's portable across surfaces and decades.** Today you use Claude Code; tomorrow you use Claude Desktop; next year you use something Anthropic hasn't shipped yet. As long as it can read markdown, it can read your Exo. Try saying that about any SaaS KB you've used in the last decade.

---

## Legend

- **YOU** — the operator-builder. You drive both surfaces; Exo accumulates the model.
- **Surfaces** — where you interact with Exo. **Claude Code** is the full experience (13 skills + 5 slash commands + 4 hooks, all running locally). **Claude Desktop** is lite mode via the `exo-mcp` MCP server (8 tools mirroring the most-used skills, for users who don't live in Claude Code).
- **Tools (skills, slash commands, hooks, MCP)** — the functional layer; what fires when you type a trigger phrase or when a hook event fires. All of them read/write `~/Exo/`.
- **The Knowledge Base (`~/Exo/`)** — your local data layer. Plain markdown. Never leaves your machine. The star marks this as the load-bearing piece. Lose any tool above it, you still have the Knowledge Base. Lose the Knowledge Base, the tools have nothing to operate on.
- **DREAM loop** — weekly consolidation. The dream pass reads accumulated observations through five filters, proposes graduation candidates, you approve, the rules flow back into Claude Code as updates to your CLAUDE.md / skill files / MEMORY.md for the next session.

That last loop — the one returning to the top of the diagram — is what makes "week 3 better than week 1." Captures pile up, dream consolidates, your rules layer gets sharper each cycle, the next session is smarter than the last.

---

## What this picture is NOT showing

- Individual skill bodies — see [docs/customization.md](https://github.com/AaronRoeF/exo/blob/main/docs/customization.md) for swap/extend patterns
- The setup wizard flow — see [docs/wizard.md](https://github.com/AaronRoeF/exo/blob/main/docs/wizard.md) for the 13 questions
- Hook wiring into `~/.claude/settings.json` — handled automatically by `install.sh`
- Security/privacy posture — see [docs/security.md](https://github.com/AaronRoeF/exo/blob/main/docs/security.md) for the local-first guarantees
- Obsidian integration — `~/Exo/` IS an Obsidian vault by default; see the blog post's Obsidian section for the deliberately-minimal plugin build Aaron runs
