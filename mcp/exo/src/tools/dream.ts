import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { readdirSync, statSync } from 'fs';
import { join } from 'path';
import { exoSubdir, exoRootExists, notReadyMessage } from '../exo-dir.js';
import { ToolResponse } from '../types.js';

export const dreamTool: Tool = {
  name: 'dream',
  description:
    'Consolidate recent observations into learned patterns. NOTE: full consolidation requires Claude reasoning and is best run via the Claude Code /dream skill. This MCP tool returns a count of in-scope observations and a pointer.',
  inputSchema: {
    type: 'object',
    properties: {
      focus: {
        type: 'string',
        description: 'Optional theme to focus consolidation on (e.g. "gtm", "engineering").',
      },
      days: {
        type: 'number',
        description: 'How many days of observations to consider (default: 7).',
      },
    },
    required: [],
  },
};

interface DreamArgs {
  focus?: string;
  days?: number;
}

function asDreamArgs(x: unknown): DreamArgs {
  if (typeof x !== 'object' || x === null) return {};
  const o = x as Record<string, unknown>;
  return {
    focus: typeof o.focus === 'string' ? o.focus : undefined,
    days: typeof o.days === 'number' ? o.days : undefined,
  };
}

export async function handleDream(args: unknown): Promise<ToolResponse> {
  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }

  const parsed = asDreamArgs(args);
  const days = parsed.days ?? 7;
  const obsDir = exoSubdir('observations');

  let count = 0;
  let files: string[] = [];
  try {
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;
    files = readdirSync(obsDir)
      .filter((f) => f.endsWith('.md'))
      .filter((f) => {
        try {
          return statSync(join(obsDir, f)).mtimeMs >= cutoff;
        } catch {
          return false;
        }
      });
    count = files.length;
  } catch {
    // observations dir missing — count stays 0
  }

  const focusNote = parsed.focus ? ` (focus: ${parsed.focus})` : '';
  const text =
    `Dream scaffold response${focusNote}\n\n` +
    `In scope: ${count} observation file(s) over the last ${days} day(s).\n` +
    (files.length ? `Files: ${files.join(', ')}\n\n` : '\n') +
    `Full consolidation logic lives in the Claude Code /dream skill (it needs Claude's reasoning ` +
    `to cluster, name patterns, and graduate insights). Run /dream from Claude Code for the full experience.`;

  return { content: [{ type: 'text', text }] };
}
