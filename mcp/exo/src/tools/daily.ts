import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { existsSync, readFileSync, readdirSync, statSync } from 'fs';
import { join } from 'path';
import { exoSubdir, exoRootExists, notReadyMessage } from '../exo-dir.js';
import { ToolResponse } from '../types.js';

export const dailyTool: Tool = {
  name: 'daily',
  description:
    'Morning briefing stitched from ~/Exo/priorities/this-week.md plus active project pulses. NOTE: the full /daily command (calendar + email pulls) requires Claude Code with calendar/Gmail MCPs.',
  inputSchema: {
    type: 'object',
    properties: {},
    required: [],
  },
};

function parseFrontmatter(content: string): Record<string, string | boolean> {
  const out: Record<string, string | boolean> = {};
  const m = content.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return out;
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-zA-Z_][a-zA-Z0-9_-]*):\s*(.+)$/);
    if (!kv) continue;
    const key = kv[1].trim();
    const raw = kv[2].trim().replace(/^["']|["']$/g, '');
    if (raw === 'true') out[key] = true;
    else if (raw === 'false') out[key] = false;
    else out[key] = raw;
  }
  return out;
}

export async function handleDaily(_args: unknown): Promise<ToolResponse> {
  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }

  const sections: string[] = [];
  const today = new Date().toISOString().slice(0, 10);
  sections.push(`# Daily Briefing — ${today}\n`);

  // Priorities
  const prioritiesPath = join(exoSubdir('priorities'), 'this-week.md');
  if (existsSync(prioritiesPath)) {
    const content = readFileSync(prioritiesPath, 'utf8').trim();
    sections.push(`## This Week's Priorities\n\n${content}\n`);
  } else {
    sections.push(`## This Week's Priorities\n\n(none — create ~/Exo/priorities/this-week.md)\n`);
  }

  // Active projects
  const projDir = exoSubdir('projects');
  const projectLines: string[] = [];
  if (existsSync(projDir)) {
    for (const entry of readdirSync(projDir)) {
      const pulsePath = join(projDir, entry, 'pulse.md');
      if (!existsSync(pulsePath)) continue;
      try {
        const content = readFileSync(pulsePath, 'utf8');
        const fm = parseFrontmatter(content);
        const status = (fm.status as string | undefined) ?? 'active';
        if (status !== 'active') continue;
        const title = (fm.title as string | undefined) ?? entry;
        const focus = fm.focus === true ? ' [FOCUS]' : '';
        const touched = new Date(statSync(pulsePath).mtimeMs).toISOString().slice(0, 10);
        projectLines.push(`- **${entry}**${focus} — ${title} (last touched ${touched})`);
      } catch {
        // skip
      }
    }
  }
  if (projectLines.length) {
    sections.push(`## Active Projects\n\n${projectLines.join('\n')}\n`);
  } else {
    sections.push(`## Active Projects\n\n(none found in ~/Exo/projects/)\n`);
  }

  sections.push(
    `---\n` +
      `Note: full /daily — calendar events, email triage, meeting prep — requires the Claude Code skill ` +
      `with calendar and Gmail MCPs connected. Desktop MCP does not have native access to those sources.`,
  );

  return { content: [{ type: 'text', text: sections.join('\n') }] };
}
