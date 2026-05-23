# Drafting feedback with Exo — for beta testers and maintainers

**What this is for you:** If you're running a private beta of Exo (or a fork of it) with a handful of testers, here's a one-shot prompt your testers can paste into Claude Code that uses Exo itself to draft their feedback email for you. Saves them an hour of writing; gives you better signal than self-reports.

The idea: after a week of normal use, Exo has captured enough state (observations, skill usage logs, vault shape) to write the feedback for the tester. They just review and send.

---

## The prompt

Paste this into a Claude Code session that has Exo installed and a week of real use behind it:

```
Draft a feedback email to <maintainer-email> summarizing my week running Exo.
Pull from ~/Exo/observations/ (what I captured), the skill-usage-logger hook
output (which skills actually fired), and `ls -R ~/Exo/` (what shape my vault
took). Three sections:

1) What broke — install issues, hooks that errored, skills that routed wrong
2) What I stopped using — skills I never triggered (candidates to strip)
3) Vault shape after a week — which dirs ended up populated, which stayed empty

Be specific. If something worked surprisingly well, say so. If I bounced
in the first hour, lead with why. Don't pad — short and honest beats long
and polite. Output: a draft email I can read, edit, and send.
```

Replace `<maintainer-email>` with your address. Claude reads from `~/Exo/` directly (no fancy tooling needed — the data is just markdown files), drafts the three sections, hands you a copy-paste-ready email.

## Why this works

Exo's whole premise is that your work leaves a useful trail in `~/Exo/`. A week of use generates:

- **observations/** — dated TIL captures, including any failures or surprises
- **skill-usage-logger output** — which skill triggers fired, how often (if the logger hook is installed)
- **~/Exo/ directory shape** — which dirs ended up populated tells you which subsystems the tester actually engaged with

That's exactly the data a feedback report needs. The tester doesn't have to re-discover it manually; Exo can read it and stitch the report in seconds.

## What you (the maintainer) get back

Three concrete things per tester:
- **Bug list with reproduction context** — Exo cites the observation file + date for each issue
- **Skill-pruning signal** — which skills the tester never triggered (your dead-weight candidates)
- **Vault-shape data** — which defaults to change (if everyone leaves `decisions/` empty, maybe drop it from the wizard default)

Beats "looks great!" by a mile.

## Customizing the prompt

If you've forked Exo and added skills or removed some, tweak the prompt to ask about them specifically. If your beta is focused on one particular flow (e.g., the daily briefing), narrow the feedback ask to that flow.

For longer betas (a month+), have testers re-run the prompt monthly. Watching what changes between week 1 and week 4 is where the durable signal lives.
