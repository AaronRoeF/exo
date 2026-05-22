---
name: capture
description: >
  In-session TIL (Today I Learned) capture — writes observations from the
  current conversation to dated daily files in ~/Exo/observations/. Trigger on
  "TIL", "TIL:", "capture this", "save this insight", "learn", "add an
  observation", or any request to record something noticed during work.
  For consolidation across observations (finding patterns, proposing rules),
  use `dream` instead.
---

<!--
SKILL SUMMARY: capture
==========================
In-session TIL capture for the Exo learning loop.

WHAT IT DOES:
  Writes observations from the active conversation to dated daily files
  (~/Exo/observations/YYYY-MM-DD.md). Supports single-observation capture,
  session-scan (find uncaptured TILs from the conversation), and lightweight
  status (count, recent themes, days since last consolidation).

WHEN TO USE:
  - User types "TIL: <observation>" — quick single capture
  - User types "capture" — scan conversation, propose batch, write approved
  - User types "capture status" — show counts, themes, days since last dream
  - End-of-session signals ("EOD", "good night", "wrap it up") — propose 2-3
    candidate captures before session ends

WHEN NOT TO USE:
  - Consolidating observations into patterns or rules (use `dream`)
  - General questions about learning or education (not relevant)
  - One-off debugging notes that won't recur (skip — only capture if signal)

DATA SOURCES:
  - ~/Exo/observations/*.md (daily observation files)
  - Current conversation context (for session-scan mode)

KEY RULES:
  - Observations go in ~/Exo/observations/YYYY-MM-DD.md
  - 2-3 captures per session is the target (not 5+) — selectivity is itself a
    learning mechanism
  - Lead with the failure mode, not just the correct answer
  - Direct, concise tone — 1-3 sentences per observation max
-->

# capture — In-Session TIL Capture

**WHY:** Insights from daily sessions evaporate between conversations. Captures preserve them as raw signal. The `dream` skill consolidates captures into patterns and rules — but only if captures exist to consolidate.

---

## Commands

| Command | Mode | What It Does |
|---|---|---|
| `TIL: <observation>` | **Quick Capture** | Write a single observation to today's file |
| `capture` | **Session Scan** | Scan conversation, propose 2-3 candidates, write approved |
| `capture status` | **Status** | Count observations, show themes, days since last dream |

---

## Mode 1 — Quick Capture (`TIL: ...`)

1. **Extract the observation** from the user's message. Everything after `TIL:` is the observation.

2. **Categorize** into one of:
   - `mcp` — MCP server gotcha, auth issue, tool behavior
   - `skill` — skill routing misfire, prompt pattern, skill gap
   - `claude` — Claude Code behavior, context management, model quirk
   - `code` — language/framework/library gotcha
   - `workflow` — process insight, productivity pattern
   - `product` — product insight, customer pattern (relevant to user's work)
   - `meta` — observation about the learning system itself

3. **Write to today's daily file** at `~/Exo/observations/<today>.md`. Create the file if it doesn't exist, using this format:

```markdown
# Observations — <date>

## [HH:MM] category: Title
Description of what happened and why it matters. Include the failure mode
or surprise, not just the correct answer.
```

Append new entries to the end. Use 24-hour time.

4. **Acknowledge** with a single line: `Captured: [category] — [title]`

---

## Mode 2 — Session Scan (`capture`)

1. **Scan the current conversation** for uncaptured learnings. Look for:
   - Corrections the user made ("no", "don't do that", "wrong approach")
   - Surprises ("huh", "interesting", "I didn't know that")
   - Workarounds ("had to do X because Y didn't work")
   - MCP tool failures or unexpected behavior
   - Skill routing issues
   - Approaches that worked well (confirmed by user accepting without pushback)
   - Repeated patterns within the session

2. **Propose 2-3 candidates** (not 5+) to the user before writing:

```
Found N potential observations:

1. [strong] [category] — [title]: [one-line why this matters]
2. [weak]   [category] — [title]: [one-line why this matters]
...

Write all to today's daily file? (all / numbers / none / edit)
```

Signal strength guide:
- **strong** — clear failure mode, likely to recur, would save real time if graduated
- **weak** — interesting but possibly one-off, context-specific, or low-impact

3. **Write approved entries** to today's daily file using the Quick Capture format.

4. **Acknowledge** with count: `Captured N observations to observations/<today>.md`

---

## Mode 3 — Status (`capture status`)

1. Count total observation files and entries
2. Show date range of observations
3. Show days since last dream (consolidation review)
4. List top 3 most frequent categories
5. Flag if a dream is recommended (30+ unreviewed observations or 7+ days since last)

Format:

```
Capture Status
  Observations: <N> entries across <M> days
  Date range: <first> — <last>
  Last dream: <date> (<N> days ago)
  Top categories: <cat1> (<N>), <cat2> (<N>), <cat3> (<N>)
  [Dream recommended / Up to date]
```

---

## End-of-Session Capture

When the user signals end-of-session ("EOD", "goodnight", "wrap it up", "done for today", "signing off"), proactively propose captures before the session closes:

1. **You propose; the user edits or approves.** Do NOT ask the user to come up with TILs. YOU identify the candidates from the session.

2. **Scan for 2-3 high-quality candidates** (not 5+). Fewer, better captures beat volume.

3. **Tag signal strength** (strong / weak) so the user can quickly approve the right subset.

4. If 30+ unreviewed observations have accumulated, suggest running `dream` after capture.

---

## Flow-aware Capture

If a session crosses ~2 hours on a single project without any observations captured, propose a session-scan at the next natural break (a Bash output, a file save, a user prompt). Heavy work is when the loop should be richest, not quietest — without this nudge, capture only fires on user frustration, which catches only one polarity of learning.

---

## Guardrails

- **Quality over quantity.** Target 2-3 captures per session, not 5+. The act of deciding "is this worth writing down" is itself the learning mechanism.
- **Lead with the failure mode.** "MCP X returns Y when Z" beats "MCP X works." Observations describing what went wrong are more useful than observations describing what went right.
- **Don't capture context-specific one-offs.** If a learning only applies to one debugging session, leave it as a session note. Capture is for things that might repeat.
- **Don't delete observation files.** They're the audit trail. The `dream` skill marks stale entries in place.
- **Direct, concise tone.** 1-3 sentences per observation. No filler.

---

## Rationalization Table — capture

If you catch yourself thinking any of these, you are about to skip a useful capture:

| Excuse | Reality |
|--------|---------|
| "I'll capture it later" | You won't. Sessions end, context dies, and the insight evaporates. Capture now — it takes 30 seconds. |
| "This is too small to note" | Small observations are the ones that repeat. Three small notes about the same MCP quirk = a graduation candidate. |
| "I already know this" | If you knew it, you wouldn't have made the same mistake. The observation exists because the knowledge isn't actionable yet. |
| "This session wasn't interesting enough" | Boring sessions have the most process learnings. The interesting sessions teach you about the domain; the boring ones teach you about yourself. |
| "We're almost done, skip the capture" | End-of-session is when the best observations are freshest. This is the worst time to skip. |
| "The threshold isn't met yet" | Capture quality matters more than triggering review. Write it down. Threshold is for `dream`, not `capture`. |

---

## Integration with `dream`

The `dream` skill picks up where `capture` leaves off. Captures pile up; dream reads accumulated captures, groups by theme, identifies patterns across days, and proposes graduations (rules, skill updates, KB entries).

`capture status` shows when a dream is recommended. The user (or an automated weekly schedule) runs `dream` to do the consolidation.

This skill stays focused: write the raw signal. Let `dream` do the synthesis.
