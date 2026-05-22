# Security

> **WIFM:** Everything Exo knows about you stays on your machine.

Exo is local-first by design. There is no Exo server, no Exo account, no Exo telemetry. The integrations are yours, the data layer is yours, and the disconnect is one command.

---

## What's local

- The entire `~/Exo/` data layer — people, accounts, decisions, intel, observations, projects, personality, skills, hooks.
- All capture output. Hooks write to local files only.
- All consolidation output. The dream pass reads and writes local files.
- OAuth tokens for the integrations you connect. They live in the standard OS keychain (macOS Keychain, Linux Secret Service, Windows Credential Manager) or in `~/.config/exo/tokens/` (file-mode 0600) depending on the integration.

---

## What Anthropic processes

When you use Claude Code or Claude Desktop, the model still runs at Anthropic. Exo doesn't change that. Anything in a session prompt — including context Exo pulls in from your data layer — is sent to Anthropic the same way any other prompt is.

Exo's local-first guarantee is about persistence: nothing about you is stored anywhere other than your machine. The model still sees what you ask it to see in any given session.

If you have data that should never be sent to Anthropic at all, mark it in the file (a `private:` frontmatter flag) and Exo's pull rules will skip it. See `docs/customization.md` for examples.

---

## What's not local

The third-party services you connect to (Google Calendar, Gmail, Notion, HubSpot, etc.) store data on their own infrastructure under their own terms. When Exo pulls a calendar event or an email thread, it's reading from those services and bringing the data onto your machine for that session. Exo does not store a permanent copy unless you explicitly graduate something into a typed file (people, account, decision).

---

## OAuth tokens on disk

Where they live:

| Integration | Storage |
|---|---|
| Google (Calendar, Gmail, Drive) | OS keychain or `~/.config/exo/tokens/google.json` |
| Notion | OS keychain or `~/.config/exo/tokens/notion.json` |
| HubSpot | Private App token in `~/.config/exo/tokens/hubspot.json` |
| Slack | Bot token in `~/.config/exo/tokens/slack.json` |
| Jira | API token in `~/.config/exo/tokens/jira.json` |

All token files are `0600` (owner read/write only). Inspect with `ls -la ~/.config/exo/tokens/`.

To inspect what scope a token grants:

```bash
exo auth status [integration]
```

---

## Disconnect procedure

To revoke and remove a single integration:

```bash
exo disconnect [integration]
```

This:

1. Revokes the token at the provider (where supported).
2. Deletes the local token file.
3. Removes the MCP entry from `~/.claude.json`.
4. Leaves your `~/Exo/` data layer intact (you may have past captures from that integration; nothing is deleted by accident).

To disconnect everything:

```bash
exo disconnect --all
```

To nuke the entire install (data layer included):

```bash
exo disconnect --all
rm -rf ~/.claude/skills/exo ~/Exo ~/.config/exo
```

---

## What Exo will not do

- Send telemetry or analytics. There is no instrumentation in this codebase. Open the source if you want to verify.
- Phone home for updates. You pull updates yourself with `git pull` or via the Marketplace.
- Read files outside your declared data layer or working project directories without an explicit user action.
- Bypass an integration's scope. If you grant Exo read-only Gmail scope, the write-mode email skills will refuse to run.

---

## Reporting a security issue

For anything that looks like a vulnerability — token leak, file-permission bug, scope-bypass, anything that could expose user data — report privately at the contact listed in `CODE_OF_CONDUCT.md`. Don't open a public GitHub issue for security reports.
