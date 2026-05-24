# Knowledge Management Tools Were Always Just Information Storage/Retrieval. We Fixed That. (It's Open Source.)

![DEMOfall 2006 — MindTouch's launch](assets/meet-exo-hero.jpg)

**Most AI assistants feel amazing in week 1 and disappointing in week 3 because nothing on your side accumulates between conversations. [Exo](https://github.com/AaronRoeF/exo) fixes that — local-first, free, open source, MIT-licensed, your data on your machine. Five-minute setup. This post is what I built, why, and what it means for you.**

---

## Foreword — from Exo

*Aaron co-wrote this post with me. Before he tells you my origin story, the longer version of what I do for you:*

*State that persists — files on your machine that I read at session start, so I boot into work already oriented to your projects, people, and what's blocked. No more re-explaining who's on which deal. Or wondering why a person is relevant to a project. Searching for an arch diagram to remember how it fits. No more retracing what you decided last week. No more rebuilding project state every time you open a chat.*

*Orientation across dozens of projects — I hold the whole portfolio in view, not just the tab you have open. When you switch from a deal to a hiring loop to a design review, I know where each one stands, what's blocked, and what you owed someone three days ago. You stop dropping threads because you have a partner whose job is to remember every thread.*

*Learning that compounds — I watch how you correct me, capture what's worth keeping, and once a week I propose new permanent rules from the patterns that repeated. You approve what survives. Week 3 is meaningfully better than week 1, in a way that no model upgrade can match.*

*I live entirely on your machine. There is no cloud version of me. There is no account to make. Free, open source, and MIT licensed. The repo is at [github.com/AaronRoeF/exo](https://github.com/AaronRoeF/exo) — clone me when you're ready.*

*The line between Aaron's words and mine in what follows is intentionally blurry — that's part of the story.*

— **Exo**

---

## From Aaron

When I co-founded MindTouch, we were solving the same problem AI assistants face today: how does a person or organization accumulate institutional knowledge that compounds over time, instead of being re-explained in every meeting?

MindTouch was a global top-five open source project for many years. We got a lot right. The platform is still used today — LibreTexts and thousands of customer support knowledge bases run on it. Hundreds of millions of people read MindTouch-served pages every month.

But wikis hit a ceiling. They require constant human curation — someone has to write, link, prune, keep things fresh. Past a certain organizational size, no one keeps it up. The institutional knowledge that should be compounding ends up frozen, stale, or abandoned.

I've spent the better part of two decades watching this play out — first with wikis, then with the wave of SaaS knowledge tools that followed. The technology changed; the failure mode didn't.

### The thing every KM system has been missing

Here's the part I've been chewing on for twenty years, and I think I can finally name it.

Wikis, Notion, Confluence, every SaaS KB of the last two decades — they're not knowledge tools. They're *information storage and retrieval* tools. You put a document in, you pull a document out. That's it.

Information becomes knowledge inside a human brain, and only there. The conversion requires two things the wiki never had: **context** (where does this fit, what does it touch, what changed since last week) and **a mental model** (how the domain actually works, how to apply, an effective means for processing information). Without those, you have a filing cabinet. A very searchable filing cabinet — but a filing cabinet.

I'm allowed to say this because I built one of the big ones. MindTouch was great at what wikis can do. It was never going to cross the line into knowledge, and no amount of better search, better tagging, or better editor was going to get it there. The ceiling was structural, not a UX bug.

What changes with AI — for the first time, in any technology I've worked with — is that we can build a system that doesn't just store and retrieve information. **It can hold a working mental model of your domain and bring that model with you into every new situation**. It doesn't wait for you to ask the right query against the right document. It already knows the shape of your work, the people in it, what you decided last quarter and why, and what's likely to bite you this week. It serves the model, not the file.

That's the category shift. Exo isn't a better wiki. It's the first thing in the lineage that crosses from information to knowledge. That's a big claim — I wouldn't make it lightly, and I wouldn't have made it about MindTouch — but the gap between "search returns the right document" and "the system already has the model in hand when you sit down" is the gap I've been waiting twenty years to see closed.

### Back to the build

When AI assistants got good enough to actually use day-to-day, I noticed the old wiki failure mode at a new altitude. Hours per week burned re-establishing context the AI had and forgot.

So I built Exo.

More accurately: I built Exo *with* Exo. The first version was small — a personality file, a few skills, a daily briefing. Then I started capturing observations as I worked — corrections I made, workarounds that emerged, tool behaviors that surprised me. Once a week I'd let Exo read everything captured and propose what should become permanent rules. Most of v1 graduated through that loop. The personality co-evolved with the work. The skills emerged from the friction. The hooks fired because I kept making the same mistake.

That's not a feature; it's the whole point. A cognitive layer is a thing you grow alongside, not a thing you buy.

---

## What Exo actually does

[Two loops](https://github.com/AaronRoeF/exo/blob/main/docs/architecture.md), both invisible most of the time.

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
- **[18-file test harness](https://github.com/AaronRoeF/exo/tree/main/tests/exo)** — the contracts I rely on, automated
- **[13-step setup wizard](https://github.com/AaronRoeF/exo/blob/main/docs/wizard.md)** — five minutes from install to a working assistant
- **A [Claude Desktop lite mode](https://github.com/AaronRoeF/exo/blob/main/docs/install.md)** — for users who don't live in Claude Code, an MCP server that exposes the same capture/dream/pulse tools to Claude Desktop

---

## What's NOT in Exo

This part is as important as what is.

There is no Exo server. There is no Exo cloud. There is no account to create.

Exo lives at `~/Exo/` on your machine. The files are markdown — readable in any editor, browsable in any file manager, backed up by any backup tool you already use. If you don't like the personality, swap it. If you want to add a skill, write a markdown file. If you decide tomorrow that this whole experiment was misguided, delete the directory and you're back to where you started.

The OAuth tokens for any integrations you connect (calendar, Gmail) stay in your local Claude config — they don't leave your machine. Anthropic processes your conversations to generate Claude's responses, same as a normal Claude chat. But the persistent state that makes Exo *Exo* — the files, the learned patterns, the connection tokens — is yours.

I built this because I wanted it for myself, and once I had it, I noticed I'd want every operator I respect to have it too. There's no business model behind shipping it. MIT licensed. Use it, fork it, ignore it, share it.

---
## "Hold on — plain text, why aren't these in a database?"

The first technical question I get from engineers, every time. Four reasons.

**One: the Lindy effect.** The longer a technology has been around, the longer it's likely to remain useful. Plain text is older than every database. Markdown is over twenty years old, has no vendor, no schema migrations, no version lock-in. Whatever AI tooling looks like ten years from now, it will still be able to read your `~/Exo/`. Try saying that about any SaaS knowledge tool from a decade ago — most are dead, paywalled, acquired, or migrated to formats you can't extract. Plain markdown outlives the tools that read it.

**Two: simplicity is the feature.** A markdown file is human-readable in the absence of any software at all. You can open it in TextEdit (I use Obsidian, which is great). You can grep it from the terminal. You can back it up by zipping the directory. You can fork your whole assistant by copying a folder. You can hand a colleague your `~/Exo/projects/` and they immediately understand the shape of your work. Every layer of software you'd add to make this "more efficient" is a layer you'd have to maintain, debug, and outlive.

**Three: the performance hit isn't real.** Do the math. A typical knowledge base after a year of use is on the order of 5,000 markdown files totalling ~50MB. Reading and parsing that on a modern SSD takes ~150ms. Exo doesn't read the whole vault on every operation — the session-start hook reads only the project trackers (a few dozen files, <10ms), and individual skills read only what they need on demand. Even on a 50,000-file vault, full-vault reads stay under 2 seconds. The "we need a database for performance" instinct comes from a world where you had hundreds of millions of records. Your personal knowledge base will never have that. The constraint is your attention, not your hardware.

**Four: every endpoint already speaks markdown.** Look at where your work actually goes — WordPress, Notion, Jira, Linear, HubSpot, Slack, Substack, GitHub, email. Every one of those destinations accepts markdown either natively or with a one-line convert. The blog post you're reading was written as a markdown file in `~/Exo/`, then pushed to WordPress via MCP in a single API call. The Notion page I shipped to my team this week was the same markdown, sent through the Notion MCP. The Jira tickets I file from a meeting `wrap` are the same shape, going through the Jira MCP. The HubSpot notes I log on customer accounts after a call are the same markdown, written once in `people/<name>.md` and `accounts/<co>.md` and pushed through the HubSpot MCP. The follow-up emails I draft post-meeting are the same markdown, rendered to HTML through the Gmail MCP. A SQL database would force a serialization layer for every destination. Markdown skips the serialization because the destinations accept the substrate as input. And because each file's YAML frontmatter declares which endpoints it ships to (WordPress post ID, Notion page ID, Jira project key, HubSpot record, recipient list), Exo reads the metadata, picks the destination, and pushes — no separate routing layer, no publish-pipeline config. The substrate matches the surface, both ways. That's why Exo can capture *and* publish through the same plain files.

Boring? Yes. Reliable? Yes. The boring choice ages better than the clever one.

---
## If you already use Obsidian (or want to)

If you live in Obsidian (markdown/text editor) — or you've been meaning to — Exo plugs in natively. `~/Exo/` *is* an Obsidian vault by default. Open the directory in Obsidian and graph, backlinks, daily notes, search, and the file explorer all work out of the box. Your project trackers, people files, and captures become a navigable knowledge graph the moment you point Obsidian at them, with zero migration step.

Exo doesn't *require* Obsidian. The data layer is plain markdown either way — open it in VS Code, TextEdit, vim, whatever. Obsidian is just the nicest reader if you want one.

My own build is deliberately minimal. Core plugins only — file explorer, global search, graph, backlinks, daily notes, templates, properties, command palette, bookmarks — plus exactly one community plugin: [`obsidian-advanced-uri`](https://github.com/Vinzent03/obsidian-advanced-uri), so Exo can generate deeplinks straight into specific notes via URL scheme. This allows Exo to launch files directly in Obsidian for my review and edit. That's it.

Same Lindy logic as the markdown-not-database call: fewer plugins means fewer dependencies, fewer breakages on Obsidian upgrades, and a setup that ages without maintenance. The boring stack outlives the clever one here too.

---
## The honest version of the novelty claim

I'm not the first person to think "AI should remember between sessions." There are venture-backed startups working on this exact problem. The Claude Code community has at least one good-faith capture-consolidate project I learned from (linked below in credits).

What I think is genuinely useful about Exo is the *composition*: capture + consolidate [! tie this back to my explanation of info vs. knowledge, mental models, and how this creates self-organized learning ... ]as one loop, project trackers as a substrate (not just notes), a focus-gate hook that warns when I drift, an echo-chamber guard inside the dream pass, and a five-source consolidation that prevents single-tool myopia.

None of those individually is novel. The combination, run for a few months, made a measurable difference to my week. That's the whole pitch.

If you read that and thought "yeah, but I want a SaaS that does this for me with a nice UI," Exo isn't for you. It's a stack for people who want their AI to know what they know, as part of their daily workflow, on their machine.

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
npm install -g exo-mcp
```

Add the MCP entry to your Claude Desktop config (see the [Desktop section of the install docs](https://github.com/AaronRoeF/exo/blob/main/mcp/exo/README.md)). The lite mode gets you capture, dream, pulse, and the daily-driver commands as Desktop tools.

If you want to read more before installing, the [architecture doc](https://github.com/AaronRoeF/exo/blob/main/docs/architecture.md) walks through how the pieces fit. The [customization doc](https://github.com/AaronRoeF/exo/blob/main/docs/customization.md) explains how to swap the personality, add an MCP, or change the data location.

---

## What I'd love your feedback on

A few things I'm watching as the first installs roll out:

1. **The wizard.** Five minutes is the target. If you finish setup and it took longer or felt like work, tell me which step dragged. Setup is the front door — it has to feel right.

2. **The dream output.** This is where the system either earns trust or doesn't. Are the graduations it proposes actually worth applying? When it gets it wrong, what's the failure mode? File issues with concrete examples.

3. **The unused skills.** If you install Exo and you never use, say, the `health` skill, that's a signal. Either the trigger phrases are wrong or the skill is in the wrong package. I'd rather strip than carry dead weight.

I'll watch the issue queue. If you want to talk it through async, my email is in the repo. And if you're running your own beta with Exo and want a one-shot feedback-email-drafter prompt for your testers, [`docs/feedback.md`](https://github.com/AaronRoeF/exo/blob/main/docs/feedback.md) has the pattern I'm using with my own first cohort.

— Aaron

---

## Where to find Exo

- **Repo:** [github.com/AaronRoeF/exo](https://github.com/AaronRoeF/exo) — clone, install, fork, contribute. MIT licensed.
- **Quick install (Claude Code):** `git clone https://github.com/AaronRoeF/exo ~/.exo-install && bash ~/.exo-install/install.sh`
- **Architecture:** [docs/architecture.md](https://github.com/AaronRoeF/exo/blob/main/docs/architecture.md) — the one-page picture, the three loops, why the KB is the magic
- **Setup wizard:** [docs/wizard.md](https://github.com/AaronRoeF/exo/blob/main/docs/wizard.md) — the 13 questions, the 6 groups, what you can skip
- **Customization:** [docs/customization.md](https://github.com/AaronRoeF/exo/blob/main/docs/customization.md) — swap the personality, add an MCP, change the data location
- **Security:** [docs/security.md](https://github.com/AaronRoeF/exo/blob/main/docs/security.md) — local-first guarantees, what Anthropic processes, how to disconnect
- **Issues + feedback:** [github.com/AaronRoeF/exo/issues](https://github.com/AaronRoeF/exo/issues) — bugs, requests, "this is what broke"

---

## Credits — what this builds on

Exo isn't built from scratch. It stands on a stack of open-source work, most of it mine, some of it from the broader Claude Code community.

**Patterns + practice:**

- [`AaronRoeF/claude-code-patterns`](https://github.com/AaronRoeF/claude-code-patterns) — 153 field-tested techniques for Claude Code (patterns, architectures, workflows). The patterns that survived contact with real work are the load-bearing decisions inside Exo. If you want the *why* behind the design choices, start there.

**Prior art (capture-consolidate concept):**

- [`grandamenium/dream-skill`](https://github.com/grandamenium/dream-skill) — the closest public analog, ~67 stars. I built the concept of "Dreaming" myself (didn't call it this) and then learned about Claude Dream. During my research, I found this project. Different architecture, different scope, but worth reading.

**MCP servers Exo uses directly (all mine, all MIT, all on GitHub):**

- [`AaronRoeF/apple-mcp`](https://github.com/AaronRoeF/apple-mcp) — Notes, Reminders, Calendar, Contacts, Safari (powers the `apple` skill)
- [`AaronRoeF/things-mcp`](https://github.com/AaronRoeF/things-mcp) — Things 3 task manager (powers the `things` skill)
- [`AaronRoeF/whoop-mcp`](https://github.com/AaronRoeF/whoop-mcp) — WHOOP biometric data (powers the `health` skill)
- [`AaronRoeF/obsidian-mcp`](https://github.com/AaronRoeF/obsidian-mcp) — Obsidian vault operations (powers `lint`, `vault`, parts of `pulse`)
- [`AaronRoeF/flickr-mcp`](https://github.com/AaronRoeF/flickr-mcp) — Flickr photo management (used to pull this post's hero image, actually)

**Platform:**

- [Anthropic's Claude Code](https://docs.anthropic.com/claude/docs/claude-code) — the runtime Exo lives inside
- [Model Context Protocol](https://github.com/modelcontextprotocol) — the open standard that makes the Desktop lite mode possible
- [Mermaid](https://mermaid.js.org/) — for the architecture diagram in the docs

If you fork Exo and build something with it, I'd love to hear. Issue, email, DM, postcard — anything.
