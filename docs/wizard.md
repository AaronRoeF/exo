# Wizard

> **WIFM:** *Know what's coming before you start. Five minutes from `paste-one-thing` to a working assistant. Each step shows you what it unlocks AND how it works before you answer.*

The setup wizard runs once after install. 13 steps. Every step is skippable; defaults are sensible. Re-run anytime with `/exo wizard`.

---

## Run it

```
/exo
```

The wizard takes about 5 minutes. Optimistic estimate — your first walkthrough may run 7-8 if you pause to think on the role and priorities steps. That's fine.

---

## The opening WIFM (what Exo shows you before Step 1)

```
Welcome to Exo

Most AI assistants feel amazing in week 1 and disappointing in week 3.
The reason isn't the model — it's that nothing on your side accumulates
between conversations. You re-explain who's on which deal, retrace what
you decided last week, rebuild project state every time you open a chat.
Hours per week burned re-establishing context your AI had and forgot.

Exo fixes that two ways:

  1. State that persists. Exo boots into work already knowing what's in
     flight, who's involved, what's blocked, what you decided last time —
     because it reads your files at session start.

  2. Learning that compounds. Exo learns from every conversation. Some
     explicitly (you tell it "remember this"); most implicitly (it watches
     how you correct it, what you ask for, who you talk about). Week 3
     is better than week 1.

Setup is ~5 minutes. 13 steps. Each shows you what it unlocks AND how
it works.

[░░░░░░░░░░░░░░░░░░░░░] 0% — Ready? (yes / no)
```

---

## The 13 steps

Each step shows: progress bar tick → WIFM line → HOW-it-works tease → question. Every step is skippable.

### Step 1 — Your name

> **WIFM:** I'll use this to address you in summaries and prep notes. Nothing here gets shared.
>
> **HOW:** Your name shows up in greetings and gets used as `[USER]` placeholder when I draft anything that mentions you. First name is enough.

**Q:** What should I call you? *(First name is fine.)*

`[█░░░░░░░░░░░░░░░░░░░░] 8% — ~5 min left`

### Step 2 — Work email

> **WIFM:** I'll use this as the default From: line on any drafts I help you write.
>
> **HOW:** Stored in your local config. Nothing sent anywhere. If you connect Gmail later (Step 13), this becomes the authenticated account.

**Q:** What's your work email?

`[██░░░░░░░░░░░░░░░░░░░] 15% — ~4.5 min left`

### Step 3 — Data directory

> **WIFM:** This is where YOUR Exo lives. A folder you can browse, edit, back up — like any other.
>
> **HOW:** I create the directory and seed it with people/accounts/decisions/observations/projects subdirs. Default is `~/Exo`. Pick anything you like.

**Q:** Where should I store your data? *(Type `ok` for default `~/Exo`, or a different path.)*

`[███░░░░░░░░░░░░░░░░░░] 23% — ~4 min left`

### Step 4 — Your role

> **WIFM:** Knowing your role lets me shape outputs for your audience. A CEO needs different briefs than an analyst.
>
> **HOW:** Every draft I produce gets calibrated to the seniority and domain you operate in. Same engine, different voice.

**Q:** What's your role? *One line — e.g., "CEO of a 50-person AI startup" or "Head of Sales at a fintech."*

`[████░░░░░░░░░░░░░░░░░] 31% — ~3.5 min left`

### Step 5 — Company context

> **WIFM:** Lets me ground references in your actual company instead of making things up.
>
> **HOW:** One line. Industry, stage, what you sell. Optional — type `skip` if you'd rather not.

**Q:** Anything specific about your company I should know?

`[█████░░░░░░░░░░░░░░░░] 38% — ~3 min left`

### Step 6 — Top people

> **WIFM:** I'll create people files for everyone you mention from here on. Next time you say "prep Sarah," I'll know who she is, what she cares about, what you promised her.
>
> **HOW:** One markdown file per person. Every meeting, email, signal appends. When you say "prep [name]," I read their file in one second and brief you on context I never forget.

**Q:** Who are the 2-3 people you talk to most often at work? *(Names + their roles. Comma-separated.)*

`[██████░░░░░░░░░░░░░░░] 46% — ~2.5 min left`

### Step 7 — Top accounts

> **WIFM:** Same as people, but at the account/company level. Sets up your starting CRM.
>
> **HOW:** One file per account, growing as you work it. The `/wrap` command auto-enriches account files from every meeting.

**Q:** Top 2-3 companies or accounts you're working with right now? *(Comma-separated. Names only.)*

`[███████░░░░░░░░░░░░░░] 54% — ~2 min left`

### Step 8 — Your priorities

> **WIFM:** These seed your initial PULSE files. Session-start dashboard shows where each priority is, what's next, and what's stale — so you finish what you start.
>
> **HOW:** Each priority becomes a state machine I track. Health, completion %, last-touched. If you try to silently switch projects mid-session without updating state, I warn you.

**Q:** What are your top 1-3 priorities this quarter? *(One per line.)*

`[████████░░░░░░░░░░░░░] 62% — ~90 sec left`

### Step 9 — Auto-capture

> **WIFM:** I'll watch our conversations for corrections and preferences, and save them. Stop correcting me on the same thing twice.
>
> **HOW:** Daily raw signals captured to `~/Exo/observations/`. Weekly consolidation pass proposes new permanent rules. You approve before anything graduates.

**Q:** Auto-capture corrections + preferences? *(Default: yes — review weekly. Type `no` to opt out.)*

`[█████████░░░░░░░░░░░░] 69% — ~70 sec left`

### Step 10 — Consolidation cadence

> **WIFM:** When the weekly memory consolidation runs. The "what your assistant learned about you this week" one-pager you'll get.
>
> **HOW:** A scheduled pass that reads observations + memory + project trackers as a corpus and surfaces patterns. Default: Monday 6am. Pick any time.

**Q:** Weekly consolidation day/time? *(Default: Monday 6am. Type `ok` or a different time.)*

`[██████████░░░░░░░░░░░] 77% — ~50 sec left`

### Step 11 — Session-start briefing

> **WIFM:** Whether Exo opens every new session with a portfolio dashboard — what's in flight, what's stale, what's due, calendar for today.
>
> **HOW:** A SessionStart hook reads your PULSE files + calendar + email and renders a one-screen briefing as the first thing you see.

**Q:** Show a daily briefing every time we start a new session? *(Default: yes.)*

`[███████████░░░░░░░░░░] 85% — ~30 sec left`

### Step 12 — Connect calendar

> **WIFM:** I can prep you for meetings without being asked, and warn when something just got rescheduled.
>
> **HOW:** OAuth into your provider. Token stored locally in your Claude config — never leaves your disk. Read scope by default. *Anthropic processes your conversations to generate Claude's responses (same as a normal Claude chat), but your persistent state — files, learned patterns, OAuth tokens, connections — never leaves your machine.*

**Q:** Connect your calendar? *(yes / skip — opens a browser OAuth flow.)*

`[████████████░░░░░░░░░] 92% — ~15 sec left`

### Step 13 — Connect email

> **WIFM:** I can surface threads worth answering and avoid drafting outreach to someone you already replied to yesterday.
>
> **HOW:** OAuth into Gmail (or your provider). Read scope by default; sending drafts is a separate opt-in later. Same local-only token storage.

**Q:** Connect your email? *(yes / skip.)*

`[█████████████████████] 100% ✓ Done.`

---

## Closing screen

```
You're set up. Your Exo lives at ~/Exo (or wherever you put it). Try:

  /daily — your morning briefing
  /prep [name] — pre-meeting prep on a specific person
  /wrap [name] — post-meeting debrief
  /dream — manual memory consolidation pass

I'll get smarter every conversation. See you tomorrow morning.
```

---

## Want more connections later?

After setup, add more integrations through Claude Code's MCP system. Common examples:

- Slack (channels + messages)
- Notion (pages + databases)
- Google Drive (Docs + Sheets + Slides)
- HubSpot (deals + contacts)
- Granola (meeting transcripts)
- And ~10 more

Each becomes a tool Exo can use on your behalf. Type `/exo connect` anytime to manage them.

---

## Skip behavior

Skipping a step does two things:

1. Records the skip in `~/Exo/.wizard-state` so the wizard doesn't re-prompt next time.
2. Disables any capture rules that depend on that step.

Nothing breaks if you skip. Features just stay inert until you come back and connect.

---

## Re-running the wizard

```
/exo wizard
```

You can also re-run individual steps by number:

```
/exo wizard 6      # re-prompt for top people
/exo wizard 12     # reconnect calendar
```

Re-running a step rewrites only that step's config. Other steps are left untouched.

---

## What the wizard does NOT do

- Send anything to Anthropic beyond what Claude normally needs to respond
- Connect to an Exo cloud — there isn't one
- Lock you into the defaults — every step's output is a file you can edit
- Block on any step — every step is skippable; the wizard always reaches the end
