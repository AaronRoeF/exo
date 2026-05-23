import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { existsSync, readFileSync, readdirSync } from 'fs';
import { join } from 'path';
import { exoSubdir, exoRootExists, notReadyMessage } from '../exo-dir.js';
import { ToolResponse } from '../types.js';

export const enrichTool: Tool = {
  name: 'enrich',
  description:
    'Return the existing person or account file for a target. NOTE: full enrichment (LinkedIn, Gmail search, web search) requires the Claude Code skill with those MCPs connected.',
  inputSchema: {
    type: 'object',
    properties: {
      target: {
        type: 'string',
        description: 'Name of a person or account to look up.',
      },
    },
    required: ['target'],
  },
};

interface EnrichArgs {
  target: string;
}

function isEnrichArgs(x: unknown): x is EnrichArgs {
  if (typeof x !== 'object' || x === null) return false;
  const o = x as Record<string, unknown>;
  return typeof o.target === 'string';
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
  const exact = files.find((f) => slugify(f.replace(/\.md$/, '')) === want);
  if (exact) return join(dir, exact);
  const partial = files.find((f) => slugify(f.replace(/\.md$/, '')).includes(want));
  if (partial) return join(dir, partial);
  return null;
}

export async function handleEnrich(args: unknown): Promise<ToolResponse> {
  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }
  if (!isEnrichArgs(args)) {
    return {
      content: [{ type: 'text', text: 'enrich: invalid arguments. Required: target (string).' }],
      isError: true,
    };
  }

  const sections: string[] = [`# Enrich — ${args.target}\n`];
  let found = false;

  const personPath = findFileByLooseMatch(exoSubdir('people'), args.target);
  if (personPath) {
    found = true;
    sections.push(`## Person File: ${personPath.split('/').pop()}\n\n${readFileSync(personPath, 'utf8').trim()}\n`);
  }

  const accountPath = findFileByLooseMatch(exoSubdir('accounts'), args.target);
  if (accountPath) {
    found = true;
    sections.push(`## Account File: ${accountPath.split('/').pop()}\n\n${readFileSync(accountPath, 'utf8').trim()}\n`);
  }

  if (!found) {
    sections.push(`No existing file found in ~/Exo/people/ or ~/Exo/accounts/ for "${args.target}".\n`);
  }

  sections.push(
    `---\n` +
      `Note: full /enrich (LinkedIn lookups, Gmail/HubSpot history scans, web research, ` +
      `automatic file creation and merging) requires the Claude Code skill with those MCPs connected.`,
  );

  return { content: [{ type: 'text', text: sections.join('\n') }] };
}
