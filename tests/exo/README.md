# Exo Test Harness

Automated tests for the Exo skill bundle. Verifies skill contracts, hook behavior,
slash-command flows, and end-to-end smoke scenarios against synthetic sandbox data.

## Layout

```
tests/exo/
├── run-all.sh          orchestrator — runs every test in order
├── cleanup.sh          tears down sandbox dirs between runs
├── lib/
│   ├── sandbox.sh      sandbox lifecycle helpers
│   └── assert.sh       shared assertion library
├── fixtures/
│   ├── sample-pulse.md         realistic pulse.md for tests
│   ├── sample-observations.md  realistic observation file
│   └── seed-exo-dir.sh         scaffolds a sandbox ~/Exo equivalent
├── unit/               structural / contract tests (one per skill)
├── integration/        cross-skill tests (slash commands, hooks)
├── smoke/              end-to-end scenarios (wizard, dream cycle)
└── golden/             reference inputs for snapshot testing
```

## Running

```
bash tests/exo/run-all.sh
```

Each test file can also be run individually:

```
bash tests/exo/unit/test-capture.sh
bash tests/exo/integration/test-hooks.sh
```

## Sandbox

Tests do NOT touch the user's real ~/Exo/ directory. They create a sandbox
under /tmp/exo-test-sandbox/ for the duration of the run, seed it with fixtures,
and clean up after.

Environment variables let you point at a different repo root if needed:

```
EXO_CAPTURE_SKILL=/path/to/your/capture.md bash tests/exo/unit/test-capture.sh
EXO_HOOKS_DIR=/path/to/your/hooks         bash tests/exo/integration/test-hooks.sh
```

Defaults compute the repo root relative to each test file's location, so the
harness works from any clone of this repo without configuration.

## Contracts under test

- **Capture**: TIL schema, file write to ~/Exo/observations/<today>.md, batch proposal format
- **Dream**: 4-section output format (Modifications / New Skills / New Patterns / Horizon), 3+ day graduation gate, provenance trail
- **Pulse**: Dashboard rendering, focus lock semantics, pulse.md frontmatter contract
- **Wizard**: 13 questions / 6 steps, file outputs (~/Exo/CLAUDE.md, MEMORY.md, README.md, people/, accounts/, projects/)
- **Hooks**: exo-session-start dashboard, exo-focus-gate context-switch warning, exo-stop-dream threshold check, exo-til-flow capture prompt
- **Slash commands**: /daily, /prep, /wrap, /weekly, /enrich behaviors
- **MCP tools manifest**: Desktop lite mode tool surface
