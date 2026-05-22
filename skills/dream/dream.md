---
name: dream
description: >
  Consolidation pass — reads accumulated captures (observations) from
  ~/Exo/observations/, groups by theme across days, identifies patterns,
  and proposes graduations into CLAUDE.md / skill files / MEMORY.md.
  Trigger on "dream", "/dream", "consolidate", "dream review", "graduate
  learnings", "what patterns are emerging", or any request to review
  observations and surface repeating signals.
  For raw single-observation capture, use `capture`. For project state, use `pulse`.
---

<!--
SKILL SUMMARY: dream
==========================
The consolidation half of the Exo learning loop.

WHAT IT DOES:
  Reads observations written by `capture`, clusters them by theme, identifies
  patterns that repeat across multiple days (not just within a single day),
  and proposes graduating those patterns into permanent rules — pasted into
  CLAUDE.md, individual skill files, or MEMORY.md. Output is copy-paste-ready
  with checkboxes; the user picks what to apply.

WHEN TO USE:
  - "dream" / "/dream" — full consolidation review of the last 14 days
  - "dream <N>d" — consolidate the last N days (e.g., dream 30d)
  - "dream since <date>" — consolidate observations since a given date
  - "dream --focus '<topic>'" — steer the review toward a specific theme
  - "dream apply <path>" — apply approved graduations from a prior dream
    output file
  - Automatic trigger when capture status flags it (30+ unreviewed obs or 7+
    days since last dream)

WHEN NOT TO USE:
  - Capturing single observations (use `capture`)
  - Editing a specific pulse.md (use `pulse update`)
  - Pure vault health-check (use `lint`)

DATA SOURCES:
  - ~/Exo/observations/*.md (captures to consolidate)
  - ~/Exo/observations/REVIEW-LOG.md (prior dream cycles)
  - CLAUDE.md, ~/.claude/skills/exo/*.md, MEMORY.md (graduation targets)

KEY RULES:
  - Cross-day repetition is the signal (3+ separate days = graduation candidate).
  - Single-day repetition is anecdote, not pattern. Don't graduate from one day.
  - Every proposed graduation cites source files (provenance trail) so the
    user can audit before approving.
  - Graduations are always human-approved. Never auto-merge.
  - Output is copy-paste-ready (Modifications / New Skills / New Patterns / Horizon).
-->

# dream — Consolidation Pass

**WHY:** Raw captures pile up. Without consolidation, patterns hide in the noise. This skill finds the patterns that repeat across days and proposes them as graduations — durable rules that update the user's setup without manual reading of every observation file.

---

## Argument Parsing

| Form | Mode | Window | Focus |
|---|---|---|---|
| `dream` (empty) | full | last 14 days | none |
| `dream <N>d` (e.g., `dream 30d`, `dream 7d`) | full | last N days | none |
| `dream since <date>` | full | since that date | none |
| `dream memory` | memory-only | last 90 days | none |
| `dream observations` | observations-only | last 14 days | none |
| `dream --focus "<text>"` | full | last 14 days | scoped (see below) |
| `dream <N>d --focus "<text>"` | full | last N days | scoped |
| `dream apply <path>` | apply mode | reads the dream output file | n/a |

---

## The `--focus` Parameter (Steering Knob)

Pass `--focus "<text>"` to steer the consolidation toward a specific area. The focus text becomes a soft filter that:

1. **Prioritizes** clusters that match the focus theme.
2. **De-prioritizes** clusters outside the theme (still listed, but lower in the output).
3. **Does NOT exclude** other clusters entirely — Aaron's "focus on coding-style preferences; ignore one-off debugging notes" example is a soft hint, not a hard filter.

Max focus text length: 4,096 characters (enough for a paragraph of nuance, not a full essay).

Examples:
```
dream --focus "MCP server reliability — when tools fail, when they hang"
dream 30d --focus "coding style preferences; ignore one-off debugging notes"
dream --focus "anything related to the wizard's onboarding flow"
```

---

## Threshold-Gated Auto-Trigger

The dream skill can be triggered automatically when:
- **30+ unreviewed observations** have accumulated in `~/Exo/observations/`, OR
- **7+ days** have passed since the last dream (per REVIEW-LOG.md)

The `capture status` command surfaces when these thresholds are met. The `exo-stop-dream.sh` hook (PreStop on session end) can also propose a dream if the thresholds are met and the session is wrapping up.

Auto-trigger is a SUGGESTION, never an automatic execution. The user always approves before dream runs.

---

## Mode: Full Consolidation

The standard dream cycle. Three phases:

### Phase 1 — Inventory

1. **Read observations** in the window. Parse the dated entries from each daily file.
2. **Mark stale observations.** Any observation older than 30 days that hasn't clustered with anything across reviews gets tagged `[STALE]` in place. Stale entries are excluded from grouping. Don't delete — they remain as audit trail.
3. **Group by theme.** Cluster non-stale observations that describe the same underlying pattern, even if they use different words. Track which *days* each theme appears on (cross-day repetition is the signal, not within-day count).
4. **Score each cluster:**
   - 1 day = anecdote (skip)
   - 2 days = pattern (watch list, don't graduate)
   - 3+ days = graduation candidate
   - 5+ days = strong candidate (flag as priority)

### Phase 2 — Propose Graduations (copy-paste-ready format)

For each candidate, propose in one of these four sections:

**Modifications — copy-paste blocks for existing files**

```
[x] ## <Section Name>  →  <target file>
<the literal text to paste, ready to apply>

WHY: <one line — observation count, cross-day evidence, source files>
```

**New Skills / Hooks — scaffold blocks**

```bash
# [x] <hook or skill name>  →  <one-line purpose>
mkdir -p <target dir>
cat > <target path> <<'EOF'
<scaffold content>
EOF
chmod +x <if executable>
```

**New Patterns — for `~/Exo/patterns/` (if the user uses one)**

```yaml
# [x] <pattern-name>.md
---
name: <pattern-name>
phase: <design | implementation | debugging | review | ops>
source: dream graduation
confidence: <pattern | rule>
last_validated: <date>
---
## <Pattern Name>

**When:** <triggering condition>
**Do:** <what to do>
**Why:** <rationale>
**Anti-pattern:** <what NOT to do>

## Provenance
Graduated from observations on: <date1>, <date2>, <date3>
Source files: <obs-file-1>, <obs-file-2>, <obs-file-3>
```

**HORIZON — ambitious workflows (not graduating; flagging as build candidates)**

```
[ ] <skill or workflow name>
    <one-paragraph description of what it would do>
    Estimated session count: <N>
    Why now: <observation count + signal strength>
```

**Hygiene — batch the small stuff in one commit**

```
[x] <small action — file move, registry update, link fix, TODO append>
```

**Skipped clusters:** Brief list at the end. One line per skipped cluster with reason (anecdote, single-day, context-specific, already-graduated, etc.).

### Rules for the output format

- Default-checked `[x]` = the recommended set. Unchecked `[ ]` = optional / ambitious.
- Every item has a `WHY` line citing observation count + cross-day evidence + source files.
- Every code/scaffold block must be paste-ready (no `<placeholder>` left in critical spots).
- User approves with "approve all checked" / "do 1,3,4; skip 2" / "do all" / "skip all".
- The dream cycle generates good analysis AND copy-paste-ready application material in the same pass — never analysis alone.

### Phase 3 — Graduate (with approval)

1. **Present the full proposal** to the user. Wait for approval.
2. **Apply approved graduations** to target files.
3. **Mark graduated observations.** Add a `[GRADUATED → <target-file>]` tag to the original observation entries so they aren't re-proposed.
4. **Add changelog entry.** When graduating a rule, add a `## Changelog` section to the target (if it doesn't exist) and append:
   ```
   - <date>: Original graduation from <N> observations across <M> days
   ```
   When a graduated rule is later corrected or updated, append a new changelog line with what changed and why. This creates a lightweight audit trail.
5. **Mark stale observations.** Tag any observation >30 days old that didn't cluster: `[STALE — <date> review]`.
6. **Log the dream** by appending to `~/Exo/observations/REVIEW-LOG.md`:

```markdown
## <date> Dream
- Observations reviewed: <total>
- Date range: <first> to <last>
- Focus: <focus text or "none">
- Stale marked: <count>
- Clusters found: <count>
- Graduated: <count> (<list themes>)
- Skipped: <count> (<list themes with reasons>)
- Graduation-to-observation ratio: <X>% (<graduated> / <total reviewed across all dreams>)
```

---

## Mode: Apply (`dream apply <path>`)

If the user wants to apply graduations from a prior dream output that was saved to a file:

1. Read the dream output file.
2. Identify items marked `[x]` (approved by default).
3. Apply each item as if it had just been freshly approved.
4. Append the dream-log entry.

This is useful when the dream output was reviewed asynchronously (saved to a file, edited, then applied later).

---

## Provenance Trail

Every graduation must cite its sources. When the user reads CLAUDE.md (or any graduated target) and asks "why is this rule here," they should be able to trace it back to specific observations.

In each Modification block:

```
[x] ## <Section Name>  →  <target file>
<the literal text to paste>

WHY: 4 observations across 4 days
SOURCES:
  - observations/<date-1>.md  (line N: "...")
  - observations/<date-2>.md  (line N: "...")
  - observations/<date-3>.md  (line N: "...")
  - observations/<date-4>.md  (line N: "...")
```

The user can spot-check by reading any source.

---

## Graduation Targets

Where rules go depends on what they're about:

| Pattern Type | Target File | Section |
|---|---|---|
| Claude Code behavior, context management | `CLAUDE.md` | Context Management Rules |
| MCP server gotchas | `CLAUDE.md` | MCP Infrastructure (or relevant skill file) |
| Skill-specific failure modes | `~/.claude/skills/exo/<skill>.md` | Add Gotchas section if none exists |
| Repeated Claude errors | `~/Exo/learnings.md` (if maintained) | Relevant category |
| Cross-session guardrails | `MEMORY.md` | Guardrails section |
| Workflow patterns | `CLAUDE.md` | Workflow Patterns |
| Reusable craft/development patterns | `~/Exo/patterns/` (if maintained) | One .md per pattern |

---

## Gates

### GATE: Graduation Confidence

Before proposing any graduation:

1. Verify the pattern appeared on **3+ separate days** (not 3 times in one day).
2. Assign confidence: 1 day = anecdote (don't propose), 2 days = pattern (mention, don't push), 3+ days = rule (propose), 5+ days = strong rule (flag as priority).
3. Check that the proposed rule describes **failure mode**, not just correct behavior.
4. Verify the graduation target file doesn't already contain a similar rule (avoid duplicate or contradictory rules).

Do NOT propose graduations based on single-day clustering. Cross-day repetition is the signal.

### GATE: Don't Over-Prescribe

Compliance decreases as instruction count increases — adding more rules makes ALL rules suffer, including ones that worked before. Before adding to a target file:

- CLAUDE.md soft ceiling: ~200 lines
- Skill file Gotchas: ~10 entries
- MEMORY.md guardrails: ~15 entries

If a graduation would push a target file past these soft ceilings, propose pruning something first or moving the new rule to a hook.

---

## Guardrails

- **Never auto-graduate.** Always propose and wait for approval.
- **Cross-day repetition is the signal.** Three variations on one insight in a single session is not the same as three separate incidents on three separate days.
- **Quality over quantity.** Better to propose 3 strong graduations than 12 weak ones. The user trusts the graduation process when the recommendations are reliably high-signal.
- **Lead with positive rules, anchor with failure modes.** Graduated rules should primarily describe what TO do. Add failure-mode descriptions for observed recurring issues. "Only use real-world data" is stronger than "Don't use mock data" — negative framing makes the undesired behavior more salient (Pink Elephant effect).
- **Don't graduate context-specific observations.** If a learning only applies to one specific debugging session or one specific project, leave it as a note.
- **Stale observation cutoff: 30 days.** Observations older than 30 days that haven't clustered get marked `[STALE]` and excluded from future dreams. Old unclustered notes are noise, not signal.
- **Track graduation-to-observation ratio.** Healthy range: 15-25% of observations eventually contribute to a graduated rule. Below 10% = too much noise (capture more selectively). Above 40% = under-capturing (write down more).
- **Keep observation files.** Don't delete daily files after graduation — they're the audit trail.

---

## Integration

- **`capture`** writes the observations dream consumes.
- **`pulse update <project>`** can be triggered when a graduation is project-specific (the dream proposes updating that project's pulse.md).
- **`exo-stop-dream.sh` hook** checks dream thresholds at session end; if hit, asks if the user wants to dream now or later.
- **`echo "<focus>" | dream`** — pipe a focus string in for shell-pipeline use cases.
