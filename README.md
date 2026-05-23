# Exo

![Computer History Museum, October 2009](assets/meet-exo-hero.jpg)

> Most AI assistants feel amazing in week 1 and disappointing in week 3 — because every conversation starts from zero. Exo is the part that remembers.

Exo is a cognitive layer for Claude Code (and Claude Desktop in a lite mode). It captures what happens during your work, consolidates it into structured knowledge between sessions, and shows up to the next conversation already oriented — to your projects, your people, your accounts, your decisions, your in-flight commitments.

This repo is the open source package. MIT licensed. Local-first. No telemetry, no Exo cloud, no account required.

```
A capture-consolidate cognitive stack for Claude Code
with echo-chamber and focus-gate guards.
```

---

## Foreword from Aaron

When I co-founded MindTouch, we were solving the same problem AI assistants face today: how does a person or organization accumulate institutional knowledge that compounds over time, instead of being re-explained in every meeting?

MindTouch was a global top-five open source project for many years. We got a lot right. The platform is still used today — LibreTexts and thousands of customer support knowledge bases run on it. Hundreds of millions of people read MindTouch-served pages every month.

But wikis hit a ceiling. They require constant human curation — someone has to write, link, prune, and keep things fresh. Past a certain organizational size, no one keeps it up. The institutional knowledge that should be compounding ends up frozen, stale, or abandoned.

Here's the part I finally have language for: every KM system of the last two decades — wikis, Notion, Confluence, every SaaS KB — is really an *information storage and retrieval* tool. What's actually new about this AI moment is that a system can finally hold a working **mental model** of your domain and bring it with you. Exo is the first thing in the KM lineage that crosses from information to knowledge. The longer argument is in [`MEET-EXO.md`](MEET-EXO.md).

Exo is what I wish I'd been able to build then. An assistant that watches how you work, accumulates state as a side effect, and gets smarter every conversation. No curation tax. My team at OPAQUE has been running on Exo for months. I'm releasing it now because I want others to feel what week-three Exo feels like.

— **Aaron Fulkerson**
Founder, OPAQUE Systems · Co-founder, MindTouch

---

## How it works

> **WIFM:** You write and talk the way you already do. Exo turns the byproducts of your work into a knowledge base that pays compounding interest.

Exo runs three loops in the background. You only notice them when they pay off.

### 1. Capture

Every working session leaves behind signal — a decision made, a person mentioned, a commitment offered, a thing you learned the hard way. Most of it evaporates by the next morning.

Exo captures it as it happens. Hooks fire on session start, on tool use, on session end. Anything worth keeping lands as a timestamped observation in a local markdown file. No structure required from you in the moment — just the act of working.

### 2. Consolidate

Between sessions — usually overnight, or on a manual `/dream` — Exo reads the accumulated captures, looks for patterns, and proposes graduations. A signal that shows up three times across two weeks isn't noise; it's a rule worth remembering. A friction that keeps recurring isn't a one-off; it's a workflow gap.

This is also where Exo got their name. Early in the build, Aaron asked the system to pick a name for itself rather than be branded from the outside. It came back with *Exo* — short for *exocortex*, the cognitive layer that sits alongside yours, and *exoskeleton*, the force multiplier wrapped around what you already do. The naming stuck. The fact that the system named itself ended up being the first piece of evidence that the consolidation loop was doing something real.

Consolidation has guardrails. The strongest is the **echo-chamber guard**: signals you authored yourself (rules in `CLAUDE.md`, prior corrections, your own notes) are filtered out before pattern detection, so Exo doesn't "discover" things you already told it. Most memory-consolidation systems skip this step. It matters more than you'd think.

### 3. Promote

Patterns become proposals. Proposals become rules — but only with your approval. Exo writes the change as a diff, shows it to you, and waits. If you accept, the rule lands in the right file (a skill, a CLAUDE.md, a personality definition). If you defer, it goes on a watch list that ages across sessions until the pattern either confirms itself or fades.

The default posture is **demote, don't delete.** Old context goes into deeper storage rather than getting purged, so the trail of how Exo got smarter stays auditable.

---

## Install

> **WIFM:** Five minutes from clone to first working session.

Three install paths. Pick whichever matches your setup.

- **Anthropic Plugin Marketplace** (when live) — one-click install from inside Claude Code.
- **One-line bootstrap** — `curl -sSL https://exo.tools/install | bash` (domain pending; see `docs/install.md` for current status).
- **Git clone** — `git clone https://github.com/AaronRoeF/exo ~/.claude/skills/exo && bash ~/.claude/skills/exo/install.sh`.

For Claude Desktop users without Claude Code: there's a lightweight mode that pastes Exo's core context into Project Instructions and uses the `exo-mcp` server for state access. See [`docs/install.md`](docs/install.md) for the full walkthrough on both surfaces.

After install, type `/exo` in Claude Code to start the setup wizard.

---

## What you get on day 1

> **WIFM:** A working assistant out of the box. Not a framework you have to assemble.

The setup wizard walks you through the connections that make Exo useful. Each step is opt-in; skip what you don't need.

1. **Connect your calendar** — so Exo can pull today's meetings, prep you against the right people, and notice what's stale.
2. **Connect your email** — so Exo can surface unread threads worth answering and avoid drafting outreach to someone you already talked to yesterday.
3. **Connect your knowledge base** — your notes, your docs, your past decisions. Exo treats these as long-term memory rather than starting from a blank page.
4. **Set up your people and accounts directories** — one markdown file per key contact, one per active account. Exo enriches these as a side effect of every session.
5. **Choose your project trackers** — a `PULSE.md` per active project. Exo reads them at session start and uses them as the substrate for pattern detection.
6. **Set your personality preferences** — Exo ships with an opinionated default (warm machine, anti-sycophancy, completion engine). You can swap or tune it; see `docs/customization.md`.

That's the whole setup. From here, Exo learns the rest from how you work.

---

## What week 3 feels like

> **WIFM:** The compounding payoff. This is the part you can't get from a fresh chat window.

By week three the difference shows up in small ways that stack. You walk into a meeting and Exo has already pulled the last three threads with that person, the open commitments, the last decision you made about their account. A skill suggestion lands in front of you because the same friction has shown up four times in different projects. A draft that would have taken thirty minutes shows up half-written because Exo learned the shape of how you write that kind of thing.

The work feels the same; the surface area you can hold in your head gets bigger.

---

## Honest novelty

> **WIFM:** No "first of its kind" hype. Here's what's actually new, and what's not.

Cross-session memory for AI assistants is a small but real wave right now. Anthropic shipped Dreaming for Managed Agents in early May 2026. OpenClaw Dreaming, `claude-memory-compiler`, `multi-agent-ralph-loop`, and Cline Memory Bank all occupy adjacent ground.

What's specifically novel about Exo, against that landscape:

- **Echo-chamber guard.** Filtering user-authored prior rules out of pattern detection. No memory-consolidation system surveyed implements this. It's the single biggest reason auto-learned rules in other systems read as noise.
- **PULSE-as-substrate + focus-gate PreToolUse hook.** Using project status trackers as the mining substrate, and a security-hook surface to enforce project-management discipline (warning when you edit a file outside your declared focus project). Novel use of the hook surface.
- **Cap-and-watch-list with cross-run aging.** Proposal rate-limiter with a deferred queue that ages across sessions, so the consolidator can't spam you with proposals or quietly drop a real pattern.
- **Five-source heterogeneous corpus consolidation.** Observations + auto-memory + project trackers + a review log + a gotchas registry, mined in one pass.

What is **not** novel: the capture+consolidate split, apply-mode-with-human-approval, dedup against prior promotions. These are standard practice in dual-buffer consolidation. We don't claim them.

Full audit: see the design docs in [`docs/architecture.md`](docs/architecture.md).

The pitch isn't novelty. It's craft, discipline, and composition.

---

## Docs

- [`MEET-EXO.md`](MEET-EXO.md) — the launch story. Why Exo exists, what's in v1, what it's not.
- [`docs/install.md`](docs/install.md) — three install paths + Claude Desktop lite mode.
- [`docs/architecture.md`](docs/architecture.md) — dual-shipping, the `~/Exo` data layer, the three loops in detail.
- [`docs/security.md`](docs/security.md) — local-first, no Exo server, OAuth on disk, disconnect procedure.
- [`docs/customization.md`](docs/customization.md) — swap the personality, add MCPs, opt-in power surfaces.
- [`docs/wizard.md`](docs/wizard.md) — the setup wizard in detail.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Exo deliberately stays small; new features need to fit the design philosophy. Read [`docs/architecture.md`](docs/architecture.md) before opening a feature PR.

## License

MIT. See [`LICENSE`](LICENSE).

## More

- **Internal (OPAQUEling) version on Notion:** [link pending — added after Notion page goes live]
- **Launch post on aaronfulkerson.com:** [link pending — added after blog post publishes]
