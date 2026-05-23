import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { existsSync, readFileSync, readdirSync } from 'fs';
import { join } from 'path';
import { exoSubdir, exoRootExists, notReadyMessage } from '../exo-dir.js';
import { ToolResponse } from '../types.js';

export const prepTool: Tool = {
  name: 'prep',
  description:
    'Assemble a meeting pre-brief from ~/Exo/people/<name>.md and ~/Exo/accounts/<company>.md. NOTE: full /prep (calendar + web + email enrichment) requires Claude Code.',
  inputSchema: {
    type: 'object',
    properties: {
      name_or_meeting: {
        type: 'string',
        description: 'Person name or meeting name to prep for (e.g. "Sarah Chen" or "Acme call").',
      },
    },
    required: ['name_or_meeting'],
  },
};

interface PrepArgs {
  name_or_meeting: string;
}

function isPrepArgs(x: unknown): x is PrepArgs {
  if (typeof x !== 'object' || x === null) return false;
  const o = x as Record<string, unknown>;
  return typeof o.name_or_meeting === 'string';
}

function slugify(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function findFileByLooseMatch(dir: string, query: string): string | null {
  if (!existsSync(dir)) return null;
  const want = slugify(query);
  const files = readdirSync(dir).filter((f) => f.endsWith('.md'));

  // exact slug match first
  const exact = files.find((f) => slugify(f.replace(/\.md$/, '')) === want);
  if (exact) return join(dir, exact);

  // substring match
  const partial = files.find((f) => slugify(f.replace(/\.md$/, '')).includes(want));
  if (partial) return join(dir, partial);

  return null;
}

function parseFrontmatter(content: string): Record<string, string> {
  const out: Record<string, string> = {};
  const m = content.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return out;
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-zA-Z_][a-zA-Z0-9_-]*):\s*(.+)$/);
    if (!kv) continue;
    out[kv[1].trim()] = kv[2].trim().replace(/^["']|["']$/g, '');
  }
  return out;
}

export async function handlePrep(args: unknown): Promise<ToolResponse> {
  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }
  if (!isPrepArgs(args)) {
    return {
      content: [{ type: 'text', text: 'prep: invalid arguments. Required: name_or_meeting (string).' }],
      isError: true,
    };
  }

  const sections: string[] = [`# Pre-brief — ${args.name_or_meeting}\n`];

  // Try to find a person file
  const personPath = findFileByLooseMatch(exoSubdir('people'), args.name_or_meeting);
  let companyHint: string | undefined;

  if (personPath) {
    const content = readFileSync(personPath, 'utf8');
    const fm = parseFrontmatter(content);
    companyHint = fm.company;
    sections.push(`## Person: ${personPath.split('/').pop()}\n\n${content.trim()}\n`);
  } else {
    sections.push(
      `## Person\n\nNo person file found for "${args.name_or_meeting}" in ~/Exo/people/. ` +
        `Create one to enable richer pre-briefs.\n`,
    );
  }

  // Try to find an account file (use companyHint from person file, or query itself)
  const accountQuery = companyHint ?? args.name_or_meeting;
  const accountPath = findFileByLooseMatch(exoSubdir('accounts'), accountQuery);
  if (accountPath) {
    const content = readFileSync(accountPath, 'utf8');
    sections.push(`## Account: ${accountPath.split('/').pop()}\n\n${content.trim()}\n`);
  } else {
    sections.push(`## Account\n\nNo account file found for "${accountQuery}" in ~/Exo/accounts/.\n`);
  }

  sections.push(
    `---\n` +
      `Note: full /prep — recent calendar history, email threads, LinkedIn enrichment, web search — ` +
      `requires the Claude Code skill with those MCPs connected.`,
  );

  return { content: [{ type: 'text', text: sections.join('\n') }] };
}
