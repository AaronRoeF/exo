# Changelog

Notable public releases of **exo**. Date-stamped; curated (this is the forker-facing subset of a private working log).

---

## [2026-09-24] — v0.1.2 — The governed-agents guide qualifies its enforcement and evidence claims after Imran Siddique's review (PR #3): three enforcers named separately, the canary tests rather than proves, reads are default-allow outside the denylist, and Appendix B is pinned to current spec revisions
- Source commit: a987470


## [2026-09-24] — v0.1.1 — The governed-agents guide says the scripts keep their direct grant and the sandbox stands between an agent and those files (ADR-0071); its diagrams use the standard palette
- Source commit: 0c3c300


## [2026-09-24] — Diagrams in the OPAQUE palette; the governance guide linked from the README
- The systems, subsystems and capability-graph diagrams use the OPAQUE diagram profile's node types; the capability graph's generator changed with them.
- The README links [Building verifiable security and governance into AI agents](docs/study-guide-governed-agents.md) under the governance note, from the audit-trail section, and in the docs list.

## [2026-09-23] — v0.1.0 — Building verifiable security and governance into AI agents ([docs/study-guide-governed-agents.md](docs/study-guide-governed-agents.md))
- Source commit: b1fd03a


## [2026-08-01] — LANTERN skill

- **New: [`skills/lantern/lantern.md`](skills/lantern/lantern.md)** — LANTERN, a teaching framework for the concepts ADEPT can't carry: spiritual, psychological, and ethical wisdom the reader's own ego resists. Seven moves in fixed order (Line → Anchor → Narrative → Turn → Enact → Ripples → Nemesis), extracted from the documented methods of Nathan, Hillel, Socrates, Aristotle, the Buddha, Jesus, Epictetus, Rumi & Shams of Tabriz, the Zen koan tradition, the Hasidim, Ignatius, Kierkegaard, Jung, Bonhoeffer, Trungpa, and Tolle. ADEPT fights complexity; LANTERN fights resistance. Introduction essay forthcoming at aaronfulkerson.com.

## [2026-07-12] — Hardening doctrine + contact-email hygiene

- **New: [`docs/hardening-doctrine.md`](docs/hardening-doctrine.md)** — four portable rules that keep a learning loop alive (the escalation ladder; memory tiers and the disposability test; dead-man switches; hooks-beat-prose), plus a fail-loud API-wrapper pattern and the real 31-day silent-outage incident that taught all of it. If you only read one doc in this repo, read this one.
- **Fixed:** contact email corrected to the work address across `CODE_OF_CONDUCT.md`, `mcp/exo/package.json`, and `docs/marketplace.md`.
- **Coming:** the hardened loop *mechanics* behind the doctrine (capture-staleness tripwire, memory-store unification, counter integrity, incident escalation) land after a release-engine redesign currently in progress — doctrine first, so the ideas are usable today with any implementation.
