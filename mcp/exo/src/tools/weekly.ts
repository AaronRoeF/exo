import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { existsSync, readdirSync, readFileSync, statSync } from 'fs';
import { join } from 'path';
import { exoSubdir, exoRootExists, notReadyMessage } from '../exo-dir.js';
import { ToolResponse } from '../types.js';

export const weeklyTool: Tool = {
  name: 'weekly',
  description:
    'Weekly status summary across ~/Exo/projects/*/pulse.md — counts by status, stale projects, recently touched. NOTE: full /weekly with calendar review is Code-only.',
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

export async function handleWeekly(_args: unknown): Promise<ToolResponse> {
  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }

  const projDir = exoSubdir('projects');
  if (!existsSync(projDir)) {
    return { content: [{ type: 'text', text: 'No ~/Exo/projects/ directory found.' }] };
  }

  const now = Date.now();
  const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
  const fourteenDaysMs = 14 * 24 * 60 * 60 * 1000;

  const statusCounts: Record<string, number> = {};
  const recent: Array<{ slug: string; touched: string }> = [];
  const stale: Array<{ slug: string; touched: string }> = [];

  for (const entry of readdirSync(projDir)) {
    const pulsePath = join(projDir, entry, 'pulse.md');
    if (!existsSync(pulsePath)) continue;
    try {
      const content = readFileSync(pulsePath, 'utf8');
      const fm = parseFrontmatter(content);
      const status = (fm.status as string | undefined) ?? 'active';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      const mtime = statSync(pulsePath).mtimeMs;
      const touched = new Date(mtime).toISOString().slice(0, 10);
      if (now - mtime <= sevenDaysMs) {
        recent.push({ slug: entry, touched });
      } else if (status === 'active' && now - mtime >= fourteenDaysMs) {
        stale.push({ slug: entry, touched });
      }
    } catch {
      // skip
    }
  }

  const today = new Date().toISOString().slice(0, 10);
  const sections: string[] = [`# Weekly Review — ${today}\n`];

  sections.push(
    `## Status Counts\n\n` +
      (Object.keys(statusCounts).length
        ? Object.entries(statusCounts)
            .map(([k, v]) => `- ${k}: ${v}`)
            .join('\n')
        : '(no projects found)'),
  );

  sections.push(
    `\n## Touched in Last 7 Days\n\n` +
      (recent.length
        ? recent
            .sort((a, b) => (a.touched < b.touched ? 1 : -1))
            .map((p) => `- ${p.slug} (${p.touched})`)
            .join('\n')
        : '(none)'),
  );

  sections.push(
    `\n## Stale (active, untouched 14d+)\n\n` +
      (stale.length
        ? stale
            .sort((a, b) => (a.touched < b.touched ? -1 : 1))
            .map((p) => `- ${p.slug} (last touched ${p.touched})`)
            .join('\n')
        : '(none)'),
  );

  sections.push(
    `\n---\n` +
      `Note: full /weekly — calendar review for what happened, what's coming, blockers and surprises — ` +
      `requires the Claude Code skill with calendar MCP connected.`,
  );

  return { content: [{ type: 'text', text: sections.join('\n') }] };
}
