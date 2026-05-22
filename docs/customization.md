# Customization

> **WIFM:** Make Exo yours without forking.

Exo ships with opinionated defaults — anti-sycophancy personality, three-loop architecture, a specific set of hooks. You can customize most of it by editing a file. You only need to fork for changes that touch the core consolidation logic.

---

## Swap the personality

Exo's character lives in a single file: `~/Exo/personality/exo-personality.md`. The shipped default is the "warm machine" — rigorous, anti-sycophantic, with the seven traits documented in that file.

To customize: edit `exo-personality.md` directly. Exo reads it at session start; changes take effect next session.

To fork: copy `exo-personality.md` to `my-personality.md` in the same directory, edit, and update `~/.claude/CLAUDE.md` to point at your file:

```markdown
## Personality
Active personality: ~/Exo/personality/my-personality.md
```

Common edits:

- **Tone shift.** The default leans dry. You can soften or sharpen it by editing the "How Exo Speaks" section.
- **Different traits.** The seven traits are a starting set, not a contract. Remove or add as you want.
- **Different name and pronouns.** Exo's name and pronouns are conventions, not constants. If you want your assistant called something else, search/replace and update pronoun rules.

Don't change what the consolidation loop reads (the trait names are referenced in some skill files). If you remove "Completion engine" entirely, the completion-related capture rules stop firing.

---

## Add MCP servers

Exo treats MCP servers as the integration surface for the outside world. Adding one:

1. Install the server (npm, pip, or binary). Example:
   ```bash
   npx -y @some-vendor/mcp-server --install
   ```
2. Add to `~/.claude.json`:
   ```json
   {
     "mcpServers": {
       "some-vendor": {
         "command": "npx",
         "args": ["-y", "@some-vendor/mcp-server"],
         "env": { "API_KEY": "..." }
       }
     }
   }
   ```
3. Restart Claude Code.
4. (Optional) Add a capture rule. Open or create `~/Exo/skills/some-vendor.md`:
   ```markdown
   ---
   name: some-vendor
   description: Use when the user asks about some-vendor data
   ---
   When the user asks about [topic], call mcp__some-vendor__[tool] and surface results inline.
   ```

That's it. Exo will discover the skill on next session start.

---

## Opt-in power surfaces

Some Exo features are off by default because they're invasive for new users. Turn them on after you've used Exo for a couple of weeks and want more.

| Feature | What it does | Enable by |
|---|---|---|
| Auto-dream | Nightly background consolidation pass via launchd | Run `exo enable auto-dream` |
| Focus gate | Inject a context-switch warning when you edit outside your declared focus project | Run `exo enable focus-gate` |
| TIL flow auto-prompt | Prompt you for TIL candidates at end of every session, not just on EOD | Edit `~/.claude/settings.json` hook config |
| Watch-list aging surfacing | Show aged watch-list items at session start | Add `--show-watchlist` to the SessionStart hook |
| Telemetry | (Permanently off. Not configurable.) | n/a |

---

## Custom slash commands

Exo's slash commands live in `~/.claude/commands/`. The shipped set:

- `/exo` — setup wizard.
- `/daily` — morning briefing.
- `/wrap [meeting]` — meeting debrief.
- `/prep [person|meeting]` — meeting pre-brief.
- `/dream` — manual consolidation pass.
- `/review` — pipeline review.
- `/weekly` — weekly review.

Add your own by dropping a new markdown file in `~/.claude/commands/<name>.md`. The file is the prompt that gets injected when you run `/<name>`.

Example — a custom `/standup` command:

```markdown
# /standup

Pull the last 24h of activity from my active PULSEs, format as a three-bullet standup:
- What I did yesterday
- What I'm doing today
- What's blocked

Read from ~/Exo/projects/*/PULSE.md and summarize.
```

Save as `~/.claude/commands/standup.md`. Available immediately as `/standup`.

---

## Naming conventions

Exo enforces a four-prefix lifecycle for working files. Override or extend in your shell config:

| Prefix | Means | Test |
|---|---|---|
| `wip-` | Work in progress | "Still cooking." |
| `ref-` | Reference material | "I look at this, I don't send it." |
| `out-` | Output / deliverable | "This goes to someone or somewhere." |
| `old-` | Archived | "Kept for history, no longer active." |

The naming is enforced by skill rules, not by hooks (so you can break it without breaking the system). To customize: edit `~/Exo/skills/naming.md`.

---

## Disabling features

To disable a hook entirely, comment it out in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      // { "command": "~/.claude/hooks/exo-pulse-session-start.sh" }
    ]
  }
}
```

To disable a skill, rename its file to `_disabled-<name>.md` — Exo's skill loader ignores files starting with underscore.

---

## When to fork

Edit a file when:
- You want a different personality.
- You want to add or remove an integration.
- You want to disable or enable a feature.
- You want a new slash command or skill.

Fork the repo when:
- You want to change the consolidation algorithm itself.
- You want to redesign the data layer schema.
- You're building a derivative tool with significantly different goals.

For everything in between, opening an issue or PR upstream is faster than maintaining a fork.
