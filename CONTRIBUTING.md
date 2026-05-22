# Contributing to Exo

Thanks for your interest. Exo is opinionated software — there's a specific design philosophy (capture → consolidate → promote; WIFM-first; warm machine character) and contributions are evaluated against it.

## Quick links

- **Bug?** Open an issue with the `bug` template.
- **Feature idea?** Open a discussion first (issue with the `feature` template). Not every feature lands — Exo deliberately stays small.
- **Want to add a skill / persona / hook?** Read `docs/customization.md` first.

## PR flow

1. Fork the repo
2. Create a topic branch (`feat/short-name` or `fix/short-name`)
3. Make changes
4. Run the test harness: `bash tests/run-all.sh` (must pass)
5. Open a PR with a description that includes:
   - What problem this solves
   - What changes (file-by-file)
   - Why this fits Exo's design philosophy
6. Wait for review

## Design philosophy

Read these before contributing anything substantive:

- `docs/architecture.md` — capture / consolidate / promote loop
- `docs/customization.md` — extension points + opt-in power surfaces
- The shipped personality at `personality/exo-personality.md` (don't change without RFC)

## What we won't merge

- Sycophancy (UI nudges, gamification, "you did great!")
- Telemetry of any kind
- Cloud dependencies (Exo is local-first)
- Features that break the Aaron-archetype use case (non-coder white-collar professional)

## Code of conduct

See `CODE_OF_CONDUCT.md`. Be direct, be kind, prefer evidence over rhetoric.
