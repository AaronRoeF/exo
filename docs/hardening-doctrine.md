# Hardening doctrine — four rules that keep a learning loop alive

Every personal-AI setup decays the same way: context evaporates between sessions, the same corrections get re-stated forever, and the system never actually gets smarter. A learning loop fixes that — *if the loop itself stays alive*. This doctrine exists because ours didn't: our capture pipeline died silently for 31 days, and nothing noticed. What follows is what we changed, written as four portable rules plus the incident that taught them.

The test for the whole system: **time-to-first-graduation.** If a week of normal use hasn't turned one of your repeated corrections into a permanent rule, the loop isn't working — no matter how good it looks.

---

## Rule 1 — The escalation ladder: one is an anecdote, two is a pattern, three is a rule

Capture cheaply and constantly (a dated file per observation: a correction, a surprise, a gotcha, a thing that worked). But *graduate* conservatively:

- **1 occurrence** — anecdote. Capture it, move on.
- **2 occurrences on different days** — pattern. Put it on a watch list.
- **3 occurrences** — rule. Promote it into permanent context.

The counting only works across days — five repeats inside one session is one data point. And the review pass that does the counting must actually run (see Rule 3: a review queue nobody drains is where warnings go to die).

**One exception to the ladder: incidents escalate immediately.** If a capture describes a *broken mechanism* — a dead path, a silent failure, a wrong counter — don't let it wait for pattern-counting. It's already actionable; route it to your TODO the same session. Our 31-day outage was self-reported in a capture on day 5... which then sat unread in the review queue for 36 days.

## Rule 2 — Memory tiers: if losing the file would matter, it's in the wrong store

Three tiers, strictly separated:

1. **Chat context** — evaporates by design. Anything worth keeping must leave it before the session ends.
2. **Observations** — the capture inbox. Durable but unrefined; feeds the ladder.
3. **The rules substrate** — one directory of small rule files, loaded into *every* session by a startup hook, each with a trigger ("when does this fire?") and a one-liner. This is where graduated learnings live.

The trap is the in-between store: assistant "auto-memory" directories that are keyed to your working directory's path. Move or rename the workspace and the store is silently orphaned — the assistant boots with none of your accumulated preferences and doesn't know it. It happened to us three separate times.

Two fixes, one structural, one doctrinal:

- **Structural:** point every path-keyed memory directory at ONE fixed location via symlinks, refreshed by a startup hook. New workspace paths self-heal at the next boot; stranding becomes impossible.
- **Doctrinal:** durable guardrails go in the rules substrate, never in auto-memory. Auto-memory holds only machine-local, disposable state. The test that makes this usable in the moment: *if losing this file would matter, it's in the wrong store.*

## Rule 3 — Dead-man switches: ask "what fires when the input goes quiet?"

Most monitoring measures *accumulation*: too many unreviewed items, too many stale projects, queue too deep. Almost nothing measures **silence** — and zero new captures for two weeks looks exactly like a healthy quiet fortnight unless something counts the days.

For every pipeline whose health means "new files keep appearing," add a boot-time tripwire:

```bash
# SessionStart hook: warn when capture has been silent too long
LATEST=$(ls "$KB/observations" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)
DAYS=$(( ( $(date +%s) - $(date -j -f '%Y-%m-%d' "$LATEST" +%s) ) / 86400 ))
[ "$DAYS" -ge 3 ] && echo "CAPTURE STALLED — last observation $LATEST (${DAYS}d ago)."
```

Corollary: **"no signal" and "broken sensor" are indistinguishable without one.** When a consolidation pass comes back empty, treat the emptiness itself as the finding.

## Rule 4 — Hooks beat prose (and drift-checks need drift-checks)

Instructions written in your context file are aspirational: they degrade as conversations compact, and they depend on the model remembering to comply. Mechanical enforcement doesn't:

- A rule the model keeps forgetting → a **startup hook** that injects it, or a **pre-action hook** that warns at the moment of the mistake.
- Configuration that keeps un-wiring itself → a boot hook that *diffs against a canonical spec and self-repairs*, not a checklist.
- Anything installed by hand → a versioned source in your repo plus an idempotent install script. **Machine-local config is a deploy target, never a source of truth** — unversioned files the assistant reads WILL drift, because nothing can diff them against intent.

And apply the skepticism recursively: our review-debt counter was confidently wrong for weeks (wrong path, wrong sort order, wrong file pattern — three separate bugs). A counter that feeds a threshold alarm needs its own inputs verified. A drift-check that cries wolf gets skimmed past, which is how real warnings die — false positives in boot output are P1 bugs, not cosmetics.

**Bonus pattern — fail-loud API wrappers.** One of our tool servers was dead for four weeks because the vendor reports auth failures as HTTP 200 with a `{"message": "..."}` body; the wrapper trusted the status code and crashed three layers downstream with a misleading type error. After the `!res.ok` check, also reject a "success" body that is a lone message envelope:

```js
if (payload && typeof payload === "object" && !Array.isArray(payload)
    && Object.keys(payload).length === 1 && typeof payload.message === "string") {
  throw new Error(`API returned 200-with-message envelope: ${payload.message}`);
}
```

An error that is *confusing* buys an outage weeks of silence; an error that is *loud and located* buys it a same-day fix.

---

## The incident that taught all four

**Day 0:** a repo relocation changed a canonical path. The context file routing the learning-loop skill still pointed at the old location — the skill file was intact, but nothing could reach it. Capture died.

**Day 5:** a capture was written (by hand, routing around the break) *describing the exact failure*. It entered the review queue. Nothing escalated it (no Rule 1 incident path yet).

**Days 5–31:** silence. The capture nudge only fired on a rare event, not at every boot (Rule 4 gap). The review-debt counter read its log from a wrong path and reported a plausible-but-wrong number nobody questioned (Rule 4, recursive clause). No staleness tripwire existed (Rule 3 gap). Meanwhile auto-memory stores had quietly stranded at old workspace paths (Rule 2 gap).

**Day 31:** a scheduled consolidation pass found a completely empty window — and the emptiness was the alarm. Root-cause to fixed took one day: path corrected and consumer-swept, staleness tripwire added, counters repaired, memory stores unified behind symlinks, incident-escalation added to capture, and the consolidation pass put on a weekly schedule so the next silence gets caught in days, not weeks.

The uncomfortable summary: **the learning loop is your system's immune system, and immune systems need their own monitoring.** Every rule above is cheap — a few small hooks and one discipline about where things live. What's expensive is a month of your best corrections evaporating while everything looks fine.
