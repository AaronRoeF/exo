# Anthropic Plugin Marketplace Listing — Submission Prep

Reference material for submitting Exo to the Anthropic Plugin Marketplace. This file is internal/repo-side; it's NOT what users read. It's what the maintainer (or whoever runs the submission) pastes into the marketplace web form when listing.

---

## Listing fields

### Name
`Exo`

### Tagline (under 80 chars)
`A cognitive layer for Claude that remembers, learns, and gets smarter every week.`

### Category
- Primary: `Productivity`
- Secondary: `Knowledge Management`

### Description (1500 chars max)

Most AI assistants feel amazing in week 1 and disappointing in week 3. The reason isn't the model — it's that nothing on the user side accumulates between conversations.

Exo fixes that two ways:

**1. State that persists.** Files on your machine accumulate as a side effect of normal work. Every meeting updates people files. Every decision logs to decision files. Every priority gets a tracker. Exo boots into work already knowing what's in flight.

**2. Learning that compounds.** Daily captures + weekly consolidation graduate validated patterns into permanent rules. Week 3 is better than week 1.

What's in v1:
- 13 skills (capture, dream, pulse, exo meta + 9 domain skills)
- 5 daily-driver slash commands (/daily, /prep, /wrap, /weekly, /enrich)
- 4 hooks (session-start dashboard, focus-gate context-switch warning, dream threshold prompts, TIL flow nudges)
- Project tracker (pulse.md) per active project with portfolio dashboard
- 13-step conversational setup wizard
- Claude Desktop lite mode via exo-mcp (optional)

**Local-first.** No Exo server. No telemetry. No account required. Your data lives at `~/Exo/` and never leaves your machine.

MIT licensed. Built on lessons from MindTouch (acquired by NICE; still powers LibreTexts and thousands of customer support KBs).

### Tags
`memory`, `knowledge-management`, `productivity`, `daily-briefing`, `meeting-prep`, `learning-loop`, `local-first`, `MIT`, `cli`, `assistant`

### Repository URL
`https://github.com/AaronRoeF/exo`

### Author
- Name: Aaron Fulkerson
- URL: `https://aaronfulkerson.com`
- Email (support): `aaron@opaque.co`

### License
`MIT`

### Pricing
`Free / Open Source`

### Compatibility
- Claude Code: full experience (skills + hooks + slash commands)
- Claude Desktop: lite mode via the `exo-mcp` MCP server

### Install commands (for the listing's quickstart section)

**One-liner (Claude Code, recommended):**
```bash
git clone https://github.com/AaronRoeF/exo ~/.exo-install && bash ~/.exo-install/install.sh
```

**Marketplace install (when Anthropic ships marketplace install flow):**
Click `Install` in the marketplace listing. Then in Claude Code, type `/exo` to run the setup wizard.

**Claude Desktop lite mode:**
```bash
npm install -g exo-mcp
```
Then add to `claude_desktop_config.json` — see [`mcp/exo/README.md`](../mcp/exo/README.md).

### Screenshot / preview assets

TODO before submission:
- [ ] Session-start dashboard screenshot (PULSE Portfolio rendering)
- [ ] `/daily` output screenshot (with real-looking but synthetic data)
- [ ] Wizard step 1 screenshot (the welcome WIFM)
- [ ] Wizard step 6 screenshot (top people)
- [ ] Architecture diagram (from docs/architecture.md — render as PNG)
- [ ] Hero image (the Exo logo + tagline) — optional, design-dependent

Capture against a synthetic sandbox (use `tests/exo/fixtures/seed-exo-dir.sh` to seed; clean up after).

---

## Pre-submission checklist

### Repo hygiene
- [x] README.md complete with foreword, install, what's in v1, honest novelty
- [x] LICENSE present (MIT)
- [x] CODE_OF_CONDUCT.md (Contributor Covenant v2.1)
- [x] CONTRIBUTING.md (PR flow + skill/hook guide)
- [x] .github/ISSUE_TEMPLATE/ (bug, feature)
- [x] Docs complete (architecture, customization, install, security, wizard, marketplace)
- [x] Tests pass: `bash tests/exo/run-all.sh` exits 0
- [x] install.sh works in --dry-run

### Functional
- [x] 13 skills shipped (all bodies filled, no stubs)
- [x] 5 slash commands shipped
- [x] 4 hooks shipped
- [x] 4 KB templates shipped
- [x] Setup wizard executable (skills/exo/wizard.md)
- [x] Test harness ports cleanly (9/9 files pass)
- [ ] exo-mcp MCP server (Sub-plan 5 — in flight)
- [x] install.sh covers all install paths

### Polish (pre-submission)
- [ ] All screenshots captured (see above)
- [ ] One short Loom (3 min) showing install + first `/daily` (for the listing's media section)
- [ ] Verify the repo's "About" field on github.com matches the tagline above
- [ ] Verify the repo's website field links to a landing page if one exists
- [ ] Set up GitHub Discussions or pin an issue for early users
- [ ] One round of friend-installs (3-5 people) to catch install.sh bugs before public launch
- [ ] Anthropic marketplace submission form filled per the fields above

---

## Post-launch first-week plan

- [ ] Monitor `gh repo view --comments` for issues
- [ ] Tag `v0.1.0` after first round of friend-installs settles
- [ ] Write a launch announcement blog post (Aaron Column lane at aaronfulkerson.com)
- [ ] Post in relevant communities (Claude Code Discord, MCP discussions, LessWrong, HN if there's a real angle)
- [ ] Daily quick-glance at the issue queue for the first week; respond to anything non-trivial

---

## Notes

- The marketplace listing should sell on **craft + composition + honesty**, not on novelty. Per the project's novelty-audit guidance: do NOT claim "first of its kind." Honest framing: "A capture-consolidate cognitive stack for Claude Code with echo-chamber and focus-gate guards."
- Aaron's MindTouch lineage is the credibility anchor. Mention it in the foreword (already done in README.md) but don't lead with it in the tagline.
- Local-first is the differentiator vs. SaaS knowledge assistants. Lean on it.
