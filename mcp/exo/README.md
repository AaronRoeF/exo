# exo-mcp

MCP server exposing [Exo](https://github.com/aaronroe/exo-public) (a cognitive stack for Claude) to Claude Desktop.

Exo's primary surface is **Claude Code** (slash commands, skills, hooks). This MCP server is the **Claude Desktop lite mode** — it wraps your `~/Exo/` data directory and surfaces the same KB operations as MCP tools so you can use Exo from Desktop.

## Install

```bash
npm install -g @aaronroef/exo-mcp
```

Or use `npx` directly in your Desktop config (no install needed).

## Configure Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or the equivalent on your platform and add:

```json
{
  "mcpServers": {
    "exo": {
      "command": "npx",
      "args": ["-y", "@aaronroef/exo-mcp"],
      "env": {
        "EXO_DIR": "/Users/you/Exo"
      }
    }
  }
}
```

`EXO_DIR` is optional — defaults to `~/Exo`. Restart Claude Desktop. You should see the `exo` tools available.

## Tools

| Tool | What it does |
| --- | --- |
| `capture` | Append a TIL observation to today's observations file. |
| `dream` | Pointer to the full consolidation flow (Claude Code skill). |
| `pulse` | Project tracker queries: status, focus, new, list. |
| `daily` | Morning briefing stitched from priorities + project pulses. |
| `prep` | Meeting pre-brief from people/account files. |
| `wrap` | Meeting debrief — accepts inline transcript, updates people files. |
| `weekly` | Weekly status across all project pulses. |
| `enrich` | Read existing person/account file (full enrichment is Code-only). |

## Limitations

Desktop MCP doesn't have native access to your calendar, Gmail, Granola, LinkedIn, or web search. Tools that depend on those (`daily`, `prep`, `wrap`, `enrich`) work in a degraded mode here. For the full experience — including calendar pulls, email scans, web enrichment, and the full `dream` consolidation — use the Claude Code side of Exo.

## Repo

Full source and documentation: https://github.com/aaronroe/exo-public
