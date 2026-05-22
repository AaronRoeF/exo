# Wizard

> **WIFM:** Know what's coming before you start.

The setup wizard runs once after install. It walks you through six configuration steps. Every step is opt-in; you can skip any of them. You can also re-run the wizard later if your setup changes.

---

## Run it

```
/exo
```

The wizard takes about 5 minutes if you have OAuth credentials handy for the services you want to connect.

---

## The 6 steps

### Step 1 — Calendar

> **WIFM:** Exo can prep you for meetings, surface what's stale, and warn when something just got rescheduled.

**HOW:** OAuth into Google Calendar (or your provider). Exo stores the token in your OS keychain. After connect, Exo can read events; write access (creating events) is a separate opt-in later.

**Skip if:** you don't use a digital calendar, or you don't want any calendar context in your sessions.

### Step 2 — Email

> **WIFM:** Exo can surface threads worth answering and avoid drafting outreach to someone you already replied to yesterday.

**HOW:** OAuth into Gmail (or your provider). Read scope by default. Write scope (sending drafts) is a separate opt-in.

**Skip if:** you keep email out of your AI workflow on principle.

### Step 3 — Knowledge base

> **WIFM:** Exo treats your existing notes as long-term memory instead of starting from a blank page.

**HOW:** Point Exo at a directory of markdown files (your notes app's export, an Obsidian vault, a Notion export, anything). Exo indexes the structure, not the content — your notes stay where they are.

**Skip if:** you don't have an existing knowledge base. You can come back to this later once your `~/Exo/` directory has grown.

### Step 4 — People and accounts

> **WIFM:** One file per key contact, one per active account. Exo enriches these as a side effect of every session — by week three they're a working CRM you didn't have to maintain.

**HOW:** Exo creates `~/Exo/people/` and `~/Exo/accounts/` if they don't exist, and seeds them with the schema. You don't need to populate them up front; Exo will create files as people and accounts come up in your work.

**Skip if:** you're using Exo for personal-only workflows with no contact management need.

### Step 5 — Project trackers

> **WIFM:** A `PULSE.md` per active project. Exo reads them at session start and uses them as the substrate for pattern detection — so the consolidator knows what you're actually working on.

**HOW:** Exo creates `~/Exo/projects/` and offers to create a starter `PULSE.md` for each project you name. You can add more later; the focus-gate hook (opt-in via `exo enable focus-gate`) uses these to detect context switches.

**Skip if:** you only run single-project sessions and don't need cross-project state.

### Step 6 — Personality

> **WIFM:** Exo ships with a specific character (warm machine, anti-sycophancy, completion engine). You can swap or tune it.

**HOW:** Exo writes the default personality to `~/Exo/personality/exo-personality.md` and points your `CLAUDE.md` at it. You can edit the file directly anytime; changes take effect next session. See [`customization.md`](customization.md) for fork patterns.

**Skip if:** you want to write your own personality from scratch. (You can — drop a different file in `~/Exo/personality/` and point `CLAUDE.md` at it.)

---

## Skip behavior

Skipping a step does two things:

1. Records the skip in `~/Exo/.wizard-state` so the wizard doesn't re-prompt next time.
2. Disables any capture rules that depend on that step.

If you skip calendar, the meeting-prep skills don't fire. If you skip email, the inbox-triage skill doesn't load. Nothing breaks; the feature just stays inert until you connect.

---

## Re-running the wizard

```
/exo wizard
```

You can also re-run individual steps:

```
/exo wizard calendar
/exo wizard email
/exo wizard kb
/exo wizard people
/exo wizard projects
/exo wizard personality
```

Re-running a step rewrites only that step's config. Other steps are left untouched.

---

## What the wizard does NOT do

- Send anything to Anthropic. The wizard is a local-only configuration flow.
- Connect to an Exo cloud. There isn't one.
- Lock you into the defaults. Every step's output is a file you can edit.
- Block on any step. Every step is skippable; the wizard always reaches the end.
