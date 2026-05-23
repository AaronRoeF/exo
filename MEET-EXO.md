# Meet Exo — the cognitive layer I wish I'd built earlier

<!-- HERO IMAGE: drop a 1600x900 image at assets/meet-exo-hero.png and uncomment below -->
<!-- ![Exo — a cognitive layer for Claude Code](assets/meet-exo-hero.png) -->

---

When I co-founded MindTouch, we were solving the same problem that AI assistants face today: how does a person or organization accumulate institutional knowledge that compounds over time, instead of being re-explained in every meeting?

We got a lot right. MindTouch is still used by tens of millions of people every month — LibreTexts and thousands of customer support knowledge bases run on it.

But wikis hit a ceiling. They require constant human curation — someone has to write, link, prune, keep things fresh. Past a certain organizational size, no one keeps it up. The institutional knowledge that should be compounding ends up frozen, stale, or abandoned.

I've spent the better part of two decades watching this play out — first with wikis, then with the wave of SaaS knowledge tools that followed. The technology changed; the failure mode didn't. Capture without consolidation rots. Consolidation without curation rots faster.

When AI assistants got good enough to actually use day-to-day, I noticed the same pattern at a new altitude: most AI assistants feel amazing in week 1 and disappointing in week 3. The reason isn't the model — it's that nothing on the user side accumulates between conversations. You re-explain who's on which deal, retrace what you decided last week, rebuild project state every time you open a chat. Hours per week burned re-establishing context your AI had and forgot.

So I built Exo.

---

## What Exo actually does

Two loops, both invisible most of the time.

**Loop one — state that persists.** Files on my machine accumulate as a side effect of normal work. Every meeting I run through `/wrap` updates a people file for everyone present, appends to the relevant account file, extracts action items, and timestamps everything. Every project gets a tracker — `pulse.md` — that says what's done, what's blocked, what's next. When I open a new session in the morning, Exo reads those files and shows me a portfolio dashboard before I type the first word. I boot into work already oriented.

**Loop two — learning that compounds.** I run a thing called `capture` to write down anything noticed during work — a correction I made to Claude, a workaround for a tool that misbehaved, a pattern that worked unexpectedly well. Once a week, `dream` reads everything captured, finds the things that repeated across multiple days, and proposes them as durable rules — updates to my CLAUDE.md, additions to a specific skill, new entries in my MEMORY.md. I approve what's worth keeping. Week 3 is meaningfully better than week 1.

That's the whole thing. The skills, the slash commands, the hooks, the templates — those are all in service of these two loops.

---

## What's in v1

The shipped open-source package has:

- **13 skills** — `capture` (TIL writer), `dream` (consolidation), `pulse` (project tracker), `exo` (meta + setup wizard), and 9 domain skills (Apple ecosystem, Gmail triage, WHOOP, Things 3, vault management, vault health-check, package release pipeline, runbook investigations, pre-publish verification)
- **5 slash commands** — `/daily`, `/prep`, `/wrap`, `/weekly`, `/enrich` for the daily-driver workflows
- **4 hooks** — session-start dashboard, focus-gate context-switch warnings, dream threshold prompts, capture flow nudges
- **4 templates** for the KB substrate — people, accounts, decisions, project pulses
- **18-file test harness** — the contracts I rely on, automated
- **13-step setup wizard** — five minutes from install to a working assistant
- **A Claude Desktop lite mode** — for users who don't live in Claude Code, an MCP server that exposes the same capture/dream/pulse tools to Claude Desktop

---

## What's NOT in Exo

This part is as important as what is.

There is no Exo server. There is no Exo cloud. There is no account to create.

Exo lives at `~/Exo/` on your machine. The files are markdown — readable in any editor, browsable in any file manager, backed up by any backup tool you already use. If you don't like the personality, swap it. If you want to add a skill, write a markdown file. If you decide tomorrow that this whole experiment was misguided, delete the directory and you're back to where you started.

The OAuth tokens for any integrations you connect (calendar, Gmail) stay in your local Claude config — they don't leave your machine. Anthropic processes your conversations to generate Claude's responses, same as a normal Claude chat. But the persistent state that makes Exo *Exo* — the files, the learned patterns, the connection tokens — is yours.

I built this because I wanted it for myself, and once I had it, I noticed I'd want every operator I respect to have it too. There's no business model behind shipping it. MIT licensed. Use it, fork it, ignore it, share it.

---

## The honest version of the novelty claim

I'm not the first person to think "AI should remember between sessions." There are venture-backed startups working on this exact problem. The Claude Code community has at least one good-faith capture-consolidate project I learned from.

What I think is genuinely useful about Exo is the *composition*: capture + consolidate as one loop, project trackers as a substrate (not just notes), a focus-gate hook that warns when I drift, an echo-chamber guard inside the dream pass, and a 5-source consolidation that prevents single-tool myopia.

None of those individually is novel. The combination, run for a few months, made a measurable difference to my week. That's the whole pitch.

If you read that and thought "yeah, but I want a SaaS that does this for me with a nice UI," Exo isn't for you. It's a stack for people who want their AI to know what they know, on their machine, with their files.

---

## Try it

If you're on Claude Code:

```bash
git clone https://github.com/AaronRoeF/exo ~/.exo-install
bash ~/.exo-install/install.sh
```

Then in any Claude Code session, type `/exo`. The wizard takes about five minutes.

If you're on Claude Desktop:

```bash
npm install -g @aaronroef/exo-mcp
```

Add the MCP entry to your Claude Desktop config (see the [Desktop section of the install docs](https://github.com/AaronRoeF/exo/blob/main/mcp/exo/README.md)). The lite mode gets you capture, dream, pulse, and the daily-driver commands as Desktop tools.

If you want to read more before installing, the [architecture doc](https://github.com/AaronRoeF/exo/blob/main/docs/architecture.md) walks through how the pieces fit. The [customization doc](https://github.com/AaronRoeF/exo/blob/main/docs/customization.md) explains how to swap the personality, add an MCP, or change the data location.

---

## What I'd love your feedback on

A few things I'm watching as the first installs roll out:

1. **The wizard.** Five minutes is the target. If you finish setup and it took longer or felt like work, tell me which step dragged. Setup is the front door — it has to feel right.

2. **The dream output.** This is where the system either earns trust or doesn't. Are the graduations it proposes actually worth applying? When it gets it wrong, what's the failure mode? File issues with concrete examples.

3. **The unused skills.** If you install Exo and you never use, say, the `health` skill, that's a signal. Either the trigger phrases are wrong or the skill is in the wrong package. I'd rather strip than carry dead weight.

I'll watch the issue queue. If you want to talk it through async, my email is in the repo.

— Aaron
