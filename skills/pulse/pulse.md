---
name: pulse
description: >
  Project tracker management — read and update per-project pulse.md state files,
  set the current focus project, list projects by status/health, surface stale
  projects, and create new projects from the template.
  Trigger on "pulse", "pulse status", "set focus", "/projects", "show projects",
  "what am I working on", "list my projects", "create project [name]", or any
  request to view or modify project portfolio state.
  For raw observation capture, use `capture`. For consolidation across
  observations, use `dream`.
---

<!--
SKILL SUMMARY: pulse
==========================
Per-project state management for Exo.

WHAT IT DOES:
  Reads, writes, and surfaces project tracker (pulse.md) state across the user's
  active projects. Each project lives in ~/Exo/projects/<slug>/ and has a
  pulse.md with frontmatter (status, health, completion, priority, owner,
  last_touched, blocked_on, tags) plus a body with Current Phase, What
  Finishing Looks Like, Last Stop, Next Actions.

WHEN TO USE:
  - "pulse" / "/projects" / "show projects" — portfolio dashboard
  - "set focus to <project>" — write focus lock
  - "create project <name>" — scaffold new project dir + pulse.md
  - "pulse stale" — list projects untouched recently
  - "pulse <project>" — read one project's pulse.md
  - "update <project>" — guided edit of one project's pulse.md

WHEN NOT TO USE:
  - Capturing in-session learnings (use `capture`)
  - Consolidating across observations (use `dream`)
  - Vault-wide health-check (use `lint`)

DATA SOURCES:
  - ~/Exo/projects/<slug>/pulse.md (per-project state files)
  - ~/Exo/projects/<slug>/* (project working files, optional)
  - ~/.claude/current-focus.txt (current focus lock; one line, project slug)
  - templates/pulse.md (the scaffold template for new projects)

KEY RULES:
  - The dashboard is the default view. Show it on bare `pulse` or `/projects`.
  - Focus lock is a single project slug in ~/.claude/current-focus.txt.
  - The focus-gate hook reads this file to warn on context-switching edits.
  - pulse.md frontmatter is the source of truth for status/health/completion.
  - Stale = last_touched > 21 days ago.
-->

# pulse — Project Tracker

**WHY:** Without a shared state file, projects exist only in memory. Restarting a project mid-stream requires re-explaining what was done, what's next, and what's blocked. `pulse.md` files persist that state so the next session — yours or a fresh one — boots oriented.

---

## Commands

| Command | What It Does |
|---|---|
| `pulse` / `pulse status` / `/projects` | Portfolio dashboard — all active projects with status/health/completion |
| `pulse <project>` | Read and display one project's pulse.md (full body) |
| `pulse focus <project>` | Set the current focus lock to this project |
| `pulse focus clear` | Clear the focus lock (no current focus) |
| `pulse focus` (no arg) | Show current focus lock |
| `pulse new <name>` | Scaffold new project dir + pulse.md from template |
| `pulse update <project>` | Guided update of one pulse.md (status, completion, last stop, next actions) |
| `pulse stale` | List projects untouched > 21 days |
| `pulse stale full` | Full stale list including counts |

---

## Mode: Portfolio Dashboard (`pulse` / `/projects`)

The default and most-used view. Render a compact table of all projects in `~/Exo/projects/<slug>/`.

### Procedure

1. **Scan** `~/Exo/projects/*/pulse.md` (one per project subdir).
2. **Parse frontmatter** from each: `status`, `health`, `completion`, `priority`, `owner`, `last_touched`, `blocked_on`.
3. **Group by status**: active first, then sub-plan-N-complete, then stable, then idea, then archived (skip).
4. **Within each group**, sort by completion descending (highest first).
5. **Render** the dashboard:

```
=====================================================================================
 PULSE Portfolio — <today's date>    (<active count> active / <total count> total)
=====================================================================================
  PROJECT                           STATUS      HEALTH   DONE   BLOCKED ON
  --------------------------------  ----------  -------  -----  ------------------
  <project-1>                       active      green    78%
  <project-2>                       active      yellow   45%    <blocker, truncated>
  <project-3>                       active      green    25%
  ...
=====================================================================================
```

6. **Finisher signal**: if any active project is at >=90% completion, highlight it as the natural closer.
7. **Stale signal**: if any active project's `last_touched` is >21 days ago, show count + top few names.
8. **Focus signal**: read `~/.claude/current-focus.txt`. If set, surface "Current focus: <project>". If empty, prompt: "No focus declared. Set one with `pulse focus <project>`."

The dashboard is also rendered automatically by the `exo-session-start.sh` hook at session start.

---

## Mode: Read One Project (`pulse <project>`)

1. Resolve `<project>` to a slug (case-insensitive match against `~/Exo/projects/*/`).
2. If multiple matches, list them and ask user to pick.
3. Read and display the full `pulse.md` for that project (frontmatter + body).

---

## Mode: Set Focus (`pulse focus <project>`)

1. Resolve `<project>` to a slug (case-insensitive match).
2. Write the slug to `~/.claude/current-focus.txt` (overwrite any prior content).
3. Confirm: `Focus set to: <project>. focus-gate will warn on edits outside this project.`

The focus-gate hook (`exo-focus-gate.sh`) reads `~/.claude/current-focus.txt` on every Edit/Write and surfaces a CONTEXT SWITCH DETECTED warning if the edited file is in a different `~/Exo/projects/<other>/` directory than the declared focus.

### `pulse focus clear`

Empty out `~/.claude/current-focus.txt` (or remove it). Confirm: `Focus cleared.`

### `pulse focus` (no argument)

Read `~/.claude/current-focus.txt`. Display: `Current focus: <project>` or `No focus set.`

---

## Mode: Create New Project (`pulse new <name>`)

1. Slugify `<name>` (lowercase, hyphenate). Show the slug and ask for confirmation if it's not obvious.
2. Create `~/Exo/projects/<slug>/`.
3. Copy `templates/pulse.md` to `~/Exo/projects/<slug>/pulse.md`.
4. Fill in the template frontmatter from the user's intent:
   - `project: <name>` (display name)
   - `status: idea` (default for new projects)
   - `priority: p3` (default; user can override)
   - `health: green`
   - `completion: 0`
   - `owner: <user-name>` (from /exo setup or ask)
   - `last_touched: <today>`
5. Ask the user one question to seed "What Finishing Looks Like" — a one-sentence definition of done. Write it into the body.
6. Confirm: `Created: ~/Exo/projects/<slug>/pulse.md`. Suggest `pulse focus <slug>` if the user wants to start working on it now.

---

## Mode: Guided Update (`pulse update <project>`)

1. Resolve `<project>` to a slug.
2. Read the current pulse.md.
3. Walk through 4 fields, showing current value, asking for new:
   - `status` (active / sub-plan-N-complete / stable / blocked / idea / archived)
   - `completion` (0-100%)
   - `health` (green / yellow / red — and why if yellow/red)
   - `blocked_on` (optional, one-line description)
4. Ask: "Add a Last Stop entry? (y/N)" — if yes, prompt for a 2-4 sentence summary of what was done this session.
5. Ask: "Update Next Actions? (y/N)" — if yes, show current list and let user add/remove items.
6. Update `last_touched: <today>` automatically.
7. Write the updated pulse.md.
8. Confirm: `Updated: ~/Exo/projects/<slug>/pulse.md`.

---

## Mode: Stale (`pulse stale`)

1. Scan all `~/Exo/projects/*/pulse.md`.
2. For each, compute days since `last_touched`.
3. Filter: > 21 days ago.
4. Sort by staleness (most stale first).
5. Render:

```
Stale projects (>21 days untouched):
  <project-1>    (35d)
  <project-2>    (28d)
  <project-3>    (24d)
  ...

Total: <N>
```

`pulse stale full` shows the same with `pulse status` summaries for each.

---

## pulse.md template structure

The canonical template (in `templates/pulse.md`) has this shape:

```markdown
---
project: <display name>
status: <active | sub-plan-N-complete | stable | blocked | idea | archived>
health: <green | yellow | red>
completion: <0-100>
priority: <p1 | p2 | p3>
owner: <user>
last_touched: <date>
sessions_estimate: <TBD | N | multi-week>
blocked_on: "<optional one-line blocker>"
tags: [<tag1>, <tag2>]
related:
  - "[[../<other-project>/pulse]]"
---

## Current Phase

<One paragraph describing what's actively happening on this project right now.>

## What Finishing Looks Like

<One sentence definition of done. Specific enough that you can tell when you're there.>

## Last Stop (<date> — <one-line title>)

<2-4 sentences: what was done in the most recent session, what's the cliff-edge for resume.>

## Next Actions

- [ ] <action 1>
- [ ] <action 2>

## Key References

- <link to related file>
- <link to external doc>
```

New "Last Stop" entries are prepended (newest first) so the most recent state is at the top.

---

## Guardrails

- **Don't auto-mark stale projects archived.** Stale is a signal, not a verdict. The user decides whether to close, defer, or revive.
- **Don't update `last_touched` on a read.** Only `pulse update <project>` and `pulse new <project>` write `last_touched`.
- **Don't move or delete project dirs.** This skill manages pulse.md state, not the project files. If the user wants to archive, they can move the dir manually (or via a separate vault-ops command).
- **Respect the focus lock.** When reading or updating projects, don't silently clear or change the focus lock unless the user explicitly asks.
- **Frontmatter is source of truth.** If the dashboard and the pulse.md body disagree about status, frontmatter wins.

---

## Integration

- **`exo-session-start.sh` hook** renders the dashboard at session start (calls this skill in dashboard mode).
- **`exo-focus-gate.sh` hook** reads `~/.claude/current-focus.txt` on every Edit/Write to detect context switches.
- **`/exo setup` wizard** asks for the user's top 2-3 priority projects and creates pulse.md stubs for each.
- **`dream`** can update a project's pulse.md when a consolidated learning is project-specific.
