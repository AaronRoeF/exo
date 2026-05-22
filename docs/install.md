# Install

> **WIFM:** Five minutes from clone to a working assistant.

Three install paths. Pick the one that matches your setup. All three end with the same `~/Exo` data layer and the same `/exo` slash command in Claude Code.

---

## Path 1 — Anthropic Plugin Marketplace

> Status: pending Marketplace launch. This will be the recommended path once Anthropic ships the plugin marketplace inside Claude Code.

When live:

1. Open Claude Code.
2. Run `/plugin install exo`.
3. Follow the wizard prompts.

That's it. The plugin handles directory creation, hooks, and MCP registration.

---

## Path 2 — One-line bootstrap

The fastest install today.

```bash
curl -sSL https://exo.tools/install | bash
```

> **Status:** the `exo.tools` domain is pending. Until it's live, use Path 3 (git clone).

The bootstrap script:

1. Clones this repo into `~/.claude/skills/exo`.
2. Creates the `~/Exo/` data directory with the standard subdirectories (`people/`, `accounts/`, `decisions/`, `intel/`, `observations/`, `projects/`).
3. Registers the Exo hooks in `~/.claude/settings.json`.
4. Adds the `/exo` slash command.
5. Runs the setup wizard.

Idempotent — safe to re-run.

---

## Path 3 — Git clone

For users who want to see exactly what's being installed before it runs.

```bash
git clone https://github.com/AaronRoeF/exo ~/.claude/skills/exo
bash ~/.claude/skills/exo/install.sh
```

The install script does the same five steps as the bootstrap, but locally. Read `install.sh` first if you want to audit it.

To update later:

```bash
cd ~/.claude/skills/exo && git pull && bash install.sh
```

---

## Claude Desktop lite mode

If you don't use Claude Code, Exo can run in a reduced form against Claude Desktop using Project Instructions plus an MCP server for state access.

You give up: hooks (no automatic capture or focus-gate), slash commands (no `/exo` or `/daily`), and shell access. You keep: the personality, the `~/Exo` data layer, the people/accounts/decisions structure, the dream loop (run manually), and cross-session memory through the MCP.

Setup:

1. Install the `exo-mcp` MCP server. Add to your Claude Desktop MCP config:

   ```json
   {
     "mcpServers": {
       "exo": {
         "command": "npx",
         "args": ["-y", "@exo/mcp-server"]
       }
     }
   }
   ```

2. Create a Claude Desktop Project named "Exo".

3. Paste the contents of `personality/exo-personality.md` and `personality/desktop-instructions.md` into the Project Instructions.

4. Restart Claude Desktop.

5. Open a chat in the Exo project. Confirm with: *"Are you running Exo?"* Exo should respond by reading `~/Exo/` and listing your active projects.

---

## Verifying install

In Claude Code:

```
/exo
```

Expected: the setup wizard starts. If it doesn't, check `~/.claude/skills/exo/install.log`.

In Claude Desktop:

Ask the chat *"What's in my Exo today?"* Expected: a portfolio summary of your active projects from `~/Exo/projects/`.

If either surface returns a generic answer instead of reading your local state, the MCP or hooks aren't wired correctly. See `docs/architecture.md` for the wiring diagram, then re-run install.

---

## Uninstall

```bash
rm -rf ~/.claude/skills/exo
# Optional: also remove your data layer
rm -rf ~/Exo
```

Then remove the Exo entries from `~/.claude/settings.json` (hooks, slash command).

Your data lives in `~/Exo/`. Nothing leaves your machine. Uninstalling doesn't trigger any network call.
