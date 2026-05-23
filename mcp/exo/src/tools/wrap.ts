import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { appendFileSync, existsSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { exoSubdir, exoRootExists, notReadyMessage, ensureDir } from '../exo-dir.js';
import { ToolResponse } from '../types.js';

export const wrapTool: Tool = {
  name: 'wrap',
  description:
    'Meeting debrief — append a meeting note + extract mentioned people. Accepts inline transcript text since Desktop MCP does not have Granola integration by default. Full feature parity is Code-only.',
  inputSchema: {
    type: 'object',
    properties: {
      meeting_name: {
        type: 'string',
        description: 'Name of the meeting (e.g. "Acme intro call").',
      },
      transcript_text: {
        type: 'string',
        description: 'Optional inline transcript or notes to extract from.',
      },
    },
    required: ['meeting_name'],
  },
};

interface WrapArgs {
  meeting_name: string;
  transcript_text?: string;
}

function isWrapArgs(x: unknown): x is WrapArgs {
  if (typeof x !== 'object' || x === null) return false;
  const o = x as Record<string, unknown>;
  return (
    typeof o.meeting_name === 'string' &&
    (o.transcript_text === undefined || typeof o.transcript_text === 'string')
  );
}

function slugify(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Very light heuristic — pulls "First Last" capitalized pairs.
 * The full /wrap skill does much more (role inference, attendee resolution, etc).
 */
function extractPeople(text: string): string[] {
  const matches = text.match(/\b([A-Z][a-z]+)\s+([A-Z][a-z]+)\b/g) ?? [];
  return Array.from(new Set(matches));
}

export async function handleWrap(args: unknown): Promise<ToolResponse> {
  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }
  if (!isWrapArgs(args)) {
    return {
      content: [{ type: 'text', text: 'wrap: invalid arguments. Required: meeting_name (string).' }],
      isError: true,
    };
  }

  const today = new Date().toISOString().slice(0, 10);
  const meetingsDir = exoSubdir('meetings');
  ensureDir(meetingsDir);
  const meetingFile = join(meetingsDir, `${today}-${slugify(args.meeting_name)}.md`);

  const header = `# ${args.meeting_name}\n\n_Date: ${today}_\n\n`;
  const body = args.transcript_text ? `## Notes / Transcript\n\n${args.transcript_text}\n` : '## Notes\n\n(no transcript provided)\n';

  if (!existsSync(meetingFile)) {
    writeFileSync(meetingFile, header + body, 'utf8');
  } else {
    appendFileSync(meetingFile, '\n\n' + body, 'utf8');
  }

  // Best-effort: append a "last seen" line to any matching person file
  let updated: string[] = [];
  if (args.transcript_text) {
    const people = extractPeople(args.transcript_text);
    const peopleDir = exoSubdir('people');
    ensureDir(peopleDir);
    for (const name of people) {
      const path = join(peopleDir, `${slugify(name)}.md`);
      const line = `- ${today}: mentioned in "${args.meeting_name}"\n`;
      if (existsSync(path)) {
        appendFileSync(path, line, 'utf8');
        updated.push(name);
      }
      // Note: we intentionally do NOT auto-create new person files here —
      // the Code-side /wrap skill handles that with richer context.
    }
  }

  const summary =
    `Wrapped meeting: ${args.meeting_name}\n` +
    `- Meeting note: ${meetingFile}\n` +
    (updated.length ? `- Updated person files: ${updated.join(', ')}\n` : `- No existing person files matched.\n`) +
    `\nNote: full /wrap (Granola transcript pull, attendee resolution, auto-creating new person files, ` +
    `co-pe-til / co-gtm-til triggering) requires the Claude Code skill.`;

  return { content: [{ type: 'text', text: summary }] };
}
