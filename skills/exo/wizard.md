---
name: wizard
description: >
  Executable first-run wizard for Exo. Walks the user through 13 questions
  in 6 logical steps (Identity, Role/Company, People, Accounts, Priorities,
  Preferences + Connections), then writes ~/Exo/CLAUDE.md, MEMORY.md,
  README.md, scaffolds people/accounts/projects/observations dirs, and
  marks setup complete. Routed to by the exo meta-skill at first run, or
  invoked directly via "/exo wizard" / "/exo wizard <N>" to re-run.
---

<!--
SKILL SUMMARY: wizard
==========================
Executable wizard body for Exo's first-run setup.

WHAT IT DOES:
  - Walks 13 numbered questions in 6 logical steps
  - Defaults are sensible; every step is skippable
  - Writes the user's answers into ~/Exo/CLAUDE.md frontmatter +
    seed people/accounts/projects files
  - Persists progress to ~/Exo/.exo/wizard-state.json so an
    interrupted wizard can resume from the last completed step
  - At final step writes ~/Exo/.exo/setup-complete sentinel
  - Shows a closing screen with first-actions list (/daily, /prep, etc.)

WHEN TO USE:
  - First run: exo meta-skill routes here when setup-complete is absent
  - Manual re-run: "/exo wizard" replays the full flow (with state-preservation)
  - Single-step re-run: "/exo wizard 6" re-prompts step 6 only

WHEN NOT TO USE:
  - Routine config tweaks (use /exo settings instead — single-key changes
    without the full walkthrough)
  - Adding MCP connections post-setup (use /exo connect instead)

DATA SOURCES (written, not read):
  - ~/Exo/CLAUDE.md (identity, role, voice, connections summary)
  - ~/Exo/MEMORY.md (lean memory index)
  - ~/Exo/README.md (user-facing pointer to their data dir)
  - ~/Exo/people/<firstname-lastname>.md (one per Step 6 person)
  - ~/Exo/accounts/<company-slug>.md (one per Step 7 account)
  - ~/Exo/projects/<priority-slug>/pulse.md (one per Step 8 priority)
  - ~/Exo/observations/REVIEW-LOG.md (initialized empty)
  - ~/Exo/.exo/settings.json (voice, signoff, sync, power surfaces)
  - ~/Exo/.exo/wizard-state.json (per-step progress + skip log)
  - ~/Exo/.exo/setup-complete (sentinel)

KEY RULES:
  - Never block on a step. Every step is skippable; the wizard always
    reaches the end.
  - Defaults are sensible. Pick reasonable defaults so a user who hits
    "ok" through every prompt still gets a working install.
  - Local-only. The wizard NEVER calls home. It writes to disk and
    optionally triggers a Claude Code MCP OAuth flow (Step 12/13) — that's
    the only network activity, and it's the user's choice.
  - Tone is warm but not chatty. This is setup, not a sales pitch.
-->

# wizard - First-Run Setup

The full reference (with rendered progress bars and the WIFM/HOW copy for
every step) lives at `docs/wizard.md`. This skill file is the executable
version — what Claude actually runs to walk the user through setup.

---

## Invocation

| Invocation | Behavior |
|---|---|
| First-run (no `setup-complete` sentinel) | Full 13-step walkthrough |
| `/exo wizard` (post-setup) | Full 13-step walkthrough, preserves existing state — diffs and confirms before overwriting any file |
| `/exo wizard <N>` (e.g., `/exo wizard 6`) | Re-prompt step `N` only. Updates that step's outputs, leaves everything else alone |
| `/exo wizard resume` | Continue from the last completed step (per `wizard-state.json`) |

---

## State file: `~/Exo/.exo/wizard-state.json`

The wizard reads and writes this file to track progress. Format:

```json
{
  "started_at": "<iso-date>",
  "last_completed_step": 8,
  "skips": [5, 13],
  "answers": {
    "1_name": "Jane",
    "2_email": "jane@example.com",
    "3_data_dir": "~/Exo",
    "4_role": "Head of Product at a 30-person SaaS company",
    "5_company": "<skipped>",
    "6_top_people": ["Sarah Chen", "Mark Rivera"],
    "7_top_accounts": ["Acme Corp", "Globex"],
    "8_priorities": ["Launch v2 by end of quarter", "Hire two PMs"],
    "9_auto_capture": true,
    "10_consolidation": "monday 0600",
    "11_session_briefing": true,
    "12_calendar_connected": false,
    "13_email_connected": false
  }
}
```

If the wizard is killed mid-step, `/exo wizard resume` picks up where it stopped.

---

## Step Flow

Run each step in order. After each, append to `wizard-state.json` and update the progress bar in the output.

### Opening (before Step 1)

Show the welcome block from `docs/wizard.md` (the 30-second WIFM that explains why Exo exists). End with: `Ready? (yes / no)`. If `no`, exit gracefully with: "No problem. Run /exo wizard anytime."

### Step 1 — Your name

> **WIFM:** I'll use this to address you in summaries and prep notes. Nothing here gets shared.
>
> **HOW:** Your name shows up in greetings and gets used as `[USER]` placeholder when I draft anything that mentions you. First name is enough.

**Q:** What should I call you? *(First name is fine.)*

**Write:** Set `user.name` in `~/Exo/CLAUDE.md` frontmatter (create file if missing using the wizard's CLAUDE.md template, below). Set `1_name` in wizard-state.

### Step 2 — Work email

> **WIFM:** I'll use this as the default From: line on any drafts I help you write.
>
> **HOW:** Stored in your local config. Nothing sent anywhere.

**Q:** What's your work email?

**Write:** Set `user.email` in `~/Exo/CLAUDE.md` frontmatter. Set `primary_email` in `~/Exo/.exo/settings.json`. Also extract the domain and add it to `email.never_auto_archive_domains` in settings.

### Step 3 — Data directory

> **WIFM:** This is where YOUR Exo lives. A folder you can browse, edit, back up — like any other.
>
> **HOW:** I create the directory and seed it with people/accounts/decisions/observations/projects subdirs. Default is `~/Exo`.

**Q:** Where should I store your data? *(Type `ok` for default `~/Exo`, or a different path.)*

**Write:** If non-default, `mkdir -p` the new path and re-base all subsequent writes to it. Update `data_dir` in settings.json. Create the standard subdirs: `people/`, `accounts/`, `decisions/`, `observations/`, `projects/`, `intel/`, `tmp/`. Create empty `observations/REVIEW-LOG.md`.

### Step 4 — Your role

> **WIFM:** Knowing your role lets me shape outputs for your audience. A CEO needs different briefs than an analyst.
>
> **HOW:** Every draft I produce gets calibrated to the seniority and domain you operate in.

**Q:** What's your role? *(One line — e.g., "CEO of a 50-person AI startup" or "Head of Sales at a fintech.")*

**Write:** Set `user.role` in `~/Exo/CLAUDE.md` frontmatter.

### Step 5 — Company context

> **WIFM:** Lets me ground references in your actual company instead of making things up.
>
> **HOW:** One line. Industry, stage, what you sell. Optional.

**Q:** Anything specific about your company I should know? *(Type `skip` if you'd rather not.)*

**Write:** If answered, set `user.company_context` in `~/Exo/CLAUDE.md` frontmatter.

### Step 6 — Top people

> **WIFM:** I'll create people files for everyone you mention from here on. Next time you say "prep Sarah," I'll know who she is, what she cares about, what you promised her.
>
> **HOW:** One markdown file per person.

**Q:** Who are the 2-3 people you talk to most often at work? *(Names + their roles. Comma-separated. Or `skip`.)*

**Write:** For each name, create `~/Exo/people/<firstname-lastname>.md` from `templates/people.md`. Pre-fill `name:` field. Leave other fields blank (the user can fill them in via /enrich or by hand).

### Step 7 — Top accounts

> **WIFM:** Same as people, but at the account/company level.
>
> **HOW:** One file per account.

**Q:** Top 2-3 companies or accounts you're working with right now? *(Comma-separated. Or `skip`.)*

**Write:** For each name, create `~/Exo/accounts/<slug>.md` from `templates/accounts.md`. Pre-fill `name:` field.

### Step 8 — Your priorities

> **WIFM:** These seed your initial pulse.md files. Session-start dashboard shows where each priority is, what's next, and what's stale.
>
> **HOW:** Each priority becomes a state machine I track.

**Q:** What are your top 1-3 priorities this quarter? *(One per line. Or `skip`.)*

**Write:** For each priority, slugify the first 3-5 words, create `~/Exo/projects/<slug>/pulse.md` from `templates/pulse.md`. Pre-fill: `project: <full priority text>`, `status: active`, `priority: p1`, `health: green`, `completion: 0`, `owner: <Step 1 name>`, `last_touched: <today>`. Add a single Outcome bullet to "What Finishing Looks Like" using the priority text. Leave other sections as template defaults.

### Step 9 — Auto-capture

> **WIFM:** I'll watch our conversations for corrections and preferences, and save them. Stop correcting me on the same thing twice.
>
> **HOW:** Daily raw signals captured to `~/Exo/observations/`. Weekly consolidation pass.

**Q:** Auto-capture corrections + preferences? *(Default: yes. Type `no` to opt out.)*

**Write:** Set `power_surfaces.auto_capture` in settings.json (true/false).

### Step 10 — Consolidation cadence

> **WIFM:** When the weekly memory consolidation runs.
>
> **HOW:** A scheduled pass that reads observations + memory + project trackers and surfaces patterns. Default: Monday 6am.

**Q:** Weekly consolidation day/time? *(Default: Monday 6am. Type `ok` or a different time.)*

**Write:** Set `power_surfaces.dream_schedule` in settings.json (default: `monday 0600`).

### Step 11 — Session-start briefing

> **WIFM:** Whether Exo opens every new session with a portfolio dashboard.
>
> **HOW:** A SessionStart hook reads your pulse files + calendar + email and renders a one-screen briefing.

**Q:** Show a daily briefing every time we start a new session? *(Default: yes.)*

**Write:** If yes, ensure `exo-session-start.sh` is wired in `~/.claude/settings.json` under `SessionStart` hooks. (If the user installed via the install.sh from this repo, it's already wired — just confirm.) Set `power_surfaces.session_briefing` in settings.json.

### Step 12 — Connect calendar

> **WIFM:** I can prep you for meetings without being asked, and warn when something just got rescheduled.
>
> **HOW:** OAuth into your provider. Token stored locally in your Claude config — never leaves your disk. Read scope by default. *Anthropic processes your conversations to generate Claude's responses (same as a normal Claude chat), but your persistent state — files, learned patterns, OAuth tokens, connections — never leaves your machine.*

**Q:** Connect your calendar? *(yes / skip.)*

**Write:** If yes, surface the Claude Code MCP install command for the user's calendar provider (Google Calendar is the most common). The OAuth flow happens in their browser; nothing stored except the local token. Record in settings.json: `connections.calendar = <provider-name>`. If skip: record `connections.calendar = null`.

### Step 13 — Connect email

> **WIFM:** I can surface threads worth answering and avoid drafting outreach to someone you already replied to yesterday.
>
> **HOW:** OAuth into Gmail (or your provider). Read scope by default; sending drafts is a separate opt-in later. Same local-only token storage.

**Q:** Connect your email? *(yes / skip.)*

**Write:** Same pattern as Step 12. Record `connections.email = <provider-name>` or `null`.

---

## Final actions (after Step 13)

1. **Write `~/Exo/MEMORY.md`** with a minimal index (sections for: user identity, top people, top accounts, top priorities, connections). Each section is a list of links to the files just created.

2. **Write `~/Exo/README.md`** — a one-page user-facing pointer that explains what's in `~/Exo/` and which commands to try first.

3. **Touch the sentinel**: `mkdir -p ~/Exo/.exo && touch ~/Exo/.exo/setup-complete`. After this, the exo meta-skill no longer routes here on `/exo`.

4. **Show the closing screen** from `docs/wizard.md`:

```
You're set up. Your Exo lives at <data_dir>. Try:

  /daily            — your morning briefing
  /prep [name]      — pre-meeting prep on a specific person
  /wrap [name]      — post-meeting debrief
  dream             — manual memory consolidation pass

I'll get smarter every conversation. See you tomorrow morning.
```

---

## CLAUDE.md template (written by Step 1 and updated by later steps)

Initial scaffold written when Step 1 first runs. Updated in place by Steps 2, 4, 5.

```markdown
---
user:
  name: "<Step 1>"
  email: "<Step 2 or empty>"
  role: "<Step 4 or empty>"
  company_context: "<Step 5 or empty>"
exo_version: "v1"
setup_date: "<today>"
---

# Exo — Personal Assistant Configuration

This file is the canonical configuration for your Exo install.
Read by Exo at session start. Safe to edit by hand — schemas are
documented in the docs/customization.md page of the Exo repo.

## Identity
You are working with `{{user.name}}` ({{user.role}}). They prefer
direct, concise responses. Their primary email is {{user.email}}.

## Top People Schema
(see ~/Exo/people/ for actual files)

People files use the schema in `~/Exo/templates/people.md` (if you
installed the templates) or the canonical schema in
docs/architecture.md (online).

## Top Accounts Schema
(see ~/Exo/accounts/ for actual files)

Account files use the schema in `~/Exo/templates/accounts.md`.

## Project Pulse Schema
(see ~/Exo/projects/<project>/pulse.md for actual files)

Pulse files follow `~/Exo/templates/pulse.md`. The pulse skill
manages them; the exo-session-start hook reads them.

## Skill Index
The Exo skill bundle is at `~/.claude/skills/exo/`. Default skills:
exo (meta), capture, dream, pulse, plus 5 slash commands (/daily,
/prep, /wrap, /weekly, /enrich) and the per-domain skills shipped
with Exo (lint, verify, vault, pkg, apple, things, health, runbook,
email).
```

---

## Skip behavior

When the user types `skip` (or `no` for yes/no steps):

1. Record the skipped step number in `wizard-state.json` under `skips[]`.
2. Do NOT write any file outputs for that step.
3. Advance to the next step. Never re-prompt within the same wizard run.
4. At end of wizard, mention skipped steps once: "Skipped: 5, 12. Re-run `/exo wizard 5` anytime to set those up."

Nothing breaks if a step is skipped. Features that depend on it stay inert until the user comes back and connects.

---

## Re-running

`/exo wizard` (post-setup) walks all 13 steps again. Existing answers are shown as defaults. The user can:
- Press enter to accept the existing answer
- Type a new value to overwrite
- Type `skip` to keep the existing value AND record a fresh skip for the new run

**Diff-and-confirm rule:** Before overwriting a file the user has manually edited since setup, show a diff and ask: "This file has been modified since setup. Overwrite (y/N)?". Default no.

`/exo wizard <N>` re-runs only step N. All other answers are preserved untouched.

`/exo wizard resume` reads `wizard-state.json`, finds `last_completed_step`, and continues from `last_completed_step + 1`.

---

## Output format per step

Each step prints to the user in this shape:

```
Step <N>/13 — <step title>
[<progress-bar>] <pct>% — ~<N> min left

WIFM: <one-line value statement>
HOW:  <one-line mechanism>

Q: <the question> <(default if any)>
> _
```

The user's response is captured. Validate where the spec says to (e.g., Step 2 should look like an email; Step 3 should be a path). On invalid input, ask once more with a tighter phrasing; if still invalid, accept it and flag in `wizard-state.json` for later cleanup.

---

## Guardrails

- **Never call home.** The wizard never makes a network call except for Step 12/13 OAuth flows, which are user-initiated.
- **Never auto-decide.** Every step's value gets confirmed before the wizard moves on.
- **Always reach the end.** No step blocks. `skip` works on every step.
- **State is always recoverable.** `wizard-state.json` is written after every step. An interrupted wizard can resume.
- **Defaults are sensible.** A user who hits "ok" through every prompt should end up with a working install.
- **Tone: warm but not chatty.** This is setup, not a sales pitch. The WIFM/HOW lines do the explaining; the questions stay short.

---

## Integration

- **`exo` meta-skill** routes here when `~/Exo/.exo/setup-complete` is absent.
- **`pulse new <name>`** uses the same project-scaffolding logic as Step 8.
- **`/exo settings`** is the lightweight alternative for changing one or two values post-setup.
- **`docs/wizard.md`** is the user-facing reference (the rendered WIFM/HOW + closing screen). Keep it in sync with this skill file's question text.
