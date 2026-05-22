---
name: exo
description: >
  Exo entry point and wizard router. Trigger on "/exo", "/setup", "/exo setup",
  "hey Exo set me up", "exo settings", "configure exo", "what can exo do",
  "exo help", or any first-time / setup-related Exo interaction. Routes to
  the conversational setup wizard if state is missing, or to an actions menu
  if Exo is already configured.
---

<!--
SKILL SUMMARY: exo
==========================
The meta-skill — Exo's front door.

WHAT IT DOES:
  Detects whether the user has an existing Exo installation. If no state
  exists, routes to the conversational setup wizard (13 questions, 6 steps).
  If state exists, presents an actions menu or routes to a specific
  sub-command. Also handles settings management.

WHEN TO USE:
  - First-time install: user types "/exo", "/setup", or "hey Exo set me up"
  - Already set up: user types "/exo" to see what they can do
  - Settings change: user types "/exo settings" or "configure exo"
  - Help: user types "/exo help" or "what can exo do"

WHEN NOT TO USE:
  - Specific Exo actions — those have their own skills (capture, dream,
    pulse, lint, verify, vault, email, apple, things, health, pkg, runbook)
  - Direct skill invocation: just type "TIL: ..." or "dream" or "/daily"
    directly. The meta-skill is for entry and routing only.

DATA SOURCES:
  - ~/Exo/CLAUDE.md (existence + content marks setup complete)
  - ~/Exo/.exo/settings.json (user-tunable settings — voice profile, sign-off,
    sync target, power-surface toggles)
  - ~/Exo/.exo/setup-complete (sentinel file, written when wizard finishes)

KEY RULES:
  - First-run experience matters most. The wizard is non-coder-friendly.
  - Never auto-configure without consent. Always ask before writing settings.
  - Don't replicate other skills' work — route to them.
-->

# exo — Entry Point + Wizard Router

**WHY:** Without a single front door, new users don't know where to start, and returning users have to remember every command name. The `exo` meta-skill is the routing layer that turns "hey Exo set me up" into a guided experience and turns "/exo" into a discoverable menu.

---

## Routing Logic

When invoked, do this check first:

```
Has ~/Exo/.exo/setup-complete file?
├── NO  → ROUTE to wizard (first-run experience)
└── YES → ROUTE based on arguments:
         ├── (no args) "/exo"           → Show actions menu
         ├── "setup"                    → Re-run wizard (with existing-state
         │                                preservation)
         ├── "settings"                 → Settings management
         ├── "help" / "what can you do" → Show command reference
         ├── "<known skill name>"       → Pass through to that skill
         └── (anything else)            → Ask: did you mean <closest match>?
```

---

## Mode: First-Run Wizard

Triggered when `~/Exo/.exo/setup-complete` does not exist.

The full wizard body is documented in `docs/wizard.md`. The wizard:
- **6 steps** (Welcome, Identity, Priorities, People, Connections, Personality)
- **13 questions** total
- **Optimistic progress bar** ("Step 2 of 6...")
- **WIFM hook** on every step (one sentence explaining the payoff before each question)
- **Skip-friendly** — every question has a sensible default the user can accept
- **Step 6 (Connections)** ends with a security/privacy paragraph and a "you can add more later" footer

Outcome: writes `~/Exo/CLAUDE.md`, `~/Exo/MEMORY.md`, `~/Exo/README.md`, populates `~/Exo/people/`, `~/Exo/accounts/`, scaffolds up to 3 `~/Exo/projects/<slug>/pulse.md` files from the user's top priorities, and writes `~/Exo/.exo/setup-complete` to mark the install done.

After the wizard, suggest the user run `/daily` to see Exo's first dashboard.

---

## Mode: Actions Menu (`/exo` with no args, post-setup)

Show a compact menu of what the user can do right now:

```
What would you like to do?

CAPTURE & CONSOLIDATE
  TIL: <thing>          Capture a single observation
  capture               Scan this session for uncaptured learnings
  dream                 Consolidate observations into patterns

PROJECTS
  /projects             Portfolio dashboard
  pulse focus <name>    Set current focus
  pulse new <name>      Create a new project

DAILY DRIVERS
  /daily                Morning briefing
  /prep <name>          Meeting prep brief
  /wrap <name>          Meeting debrief + KB enrichment
  /weekly               Weekly review
  /enrich               Background enrichment for a person/account

UTILITIES
  lint                  Vault health-check
  verify <file>         Structural verification
  pkg release           Package release pipeline

CONFIG
  /exo settings         View or change settings
  /exo help             Full command reference
```

---

## Mode: Settings (`/exo settings`)

Read `~/Exo/.exo/settings.json` and present current values. Common settings:

| Setting | Description |
|---|---|
| `voice_profile` | A few sentences describing how Exo should write in your voice |
| `signoff` | What to append to email drafts (e.g., "~af", "Cheers, Aaron") |
| `primary_email` | Main email domain for the email triage skill's "never auto-archive" rule |
| `sync_target` | Where `~/Exo/` lives — `local` (default), `icloud`, or `<custom-path>` |
| `power_surfaces` | Opt-in advanced surfaces: manual TIL prompt, manual dream review, naming-convention enforcement |
| `installed_mcps` | List of MCP servers the user has connected (informational; auto-detected) |

Walk through fields the user wants to change. Confirm each before writing.

After changes, write the updated `settings.json` and confirm: `Settings updated. Restart Claude Code if you changed sync_target or installed_mcps.`

---

## Mode: Help (`/exo help` or `what can exo do`)

Print a one-page command reference summarizing all skills and the most-used commands. Pull from each skill's frontmatter description and the actions menu above. Render compactly so it fits one screen.

---

## Mode: Skill Passthrough

If the user types `/exo <skill-name>` (e.g., `/exo capture`), route to that skill. Useful for users who learned Exo through the meta-skill and don't yet remember the bare skill names.

If the user types something that's not a known skill or command, do a fuzzy match:

```
"capure" → did you mean: capture? (y/N)
"dream review" → that's just `dream` — running it now
```

---

## Re-running the Wizard

`/exo setup` (post-setup) re-runs the wizard but preserves existing state:
- Don't overwrite `~/Exo/CLAUDE.md` if it has user edits — diff and merge interactively
- Don't re-create existing people/accounts/projects files — list them and ask whether to add new ones
- Don't overwrite `settings.json` — show current values as defaults

Use case: user added a new device, wants to install a new MCP, or wants to redo the priorities step.

---

## Detecting "Hey Exo set me up" intent

Triggers that mean "first-run wizard":
- `/exo` (with no setup-complete sentinel)
- `/setup`
- `/exo setup`
- "hey Exo set me up"
- "set up exo"
- "install exo"
- "configure exo for me"
- "I'm new — what do I do"

All route to the wizard if no state exists.

---

## Guardrails

- **Don't bypass the wizard.** Even power users who could hand-edit `~/Exo/CLAUDE.md` benefit from the wizard's first-run scaffolding. Recommend the wizard before hand-editing.
- **Don't auto-write settings.** Every settings change shows the proposed value and asks for confirmation.
- **Don't replicate skill logic.** This is a router. If the user wants to capture, route to `capture`. If the user wants to see projects, route to `pulse`. Don't duplicate.
- **Don't make assumptions about non-Code environments.** The `exo-mcp` MCP server (Sub-plan 5) handles the Claude Desktop lite mode separately. This skill is Claude Code only.
- **Respect the focus lock.** If `~/.claude/current-focus.txt` is set, mention it in the actions menu ("Current focus: <project>").

---

## Integration

- **Setup wizard body** (full 13-question / 6-step flow) is in `docs/wizard.md` and the full Sub-plan 6 deliverable. This skill stubs the router that LOADS the wizard at first run.
- **All other Exo skills** are reachable via the actions menu or direct invocation.
- **`exo-mcp` MCP server** (Sub-plan 5) provides the equivalent surface for Claude Desktop users — its tools mirror these skills.
