# Changelog

Notable public releases of **exo**. Date-stamped; curated (this is the forker-facing subset of a private working log).

---

## [2026-07-12] — Hardening doctrine + contact-email hygiene

- **New: [`docs/hardening-doctrine.md`](docs/hardening-doctrine.md)** — four portable rules that keep a learning loop alive (the escalation ladder; memory tiers and the disposability test; dead-man switches; hooks-beat-prose), plus a fail-loud API-wrapper pattern and the real 31-day silent-outage incident that taught all of it. If you only read one doc in this repo, read this one.
- **Fixed:** contact email corrected to the work address across `CODE_OF_CONDUCT.md`, `mcp/exo/package.json`, and `docs/marketplace.md`.
- **Coming:** the hardened loop *mechanics* behind the doctrine (capture-staleness tripwire, memory-store unification, counter integrity, incident escalation) land after a release-engine redesign currently in progress — doctrine first, so the ideas are usable today with any implementation.
