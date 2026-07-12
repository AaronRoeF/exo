import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { appendFileSync, existsSync, writeFileSync } from 'fs';
import { dirname } from 'path';
import { todayObsFile, ensureDir, exoRootExists, notReadyMessage } from '../exo-dir.js';
import { ToolResponse } from '../types.js';

export const captureTool: Tool = {
  name: 'capture',
  description:
    'Capture a TIL (Today I Learned) observation into Exo. Appends to ~/Exo/observations/<today>.md for later consolidation by the dream skill.',
  inputSchema: {
    type: 'object',
    properties: {
      observation: {
        type: 'string',
        description: 'The observation text — what you noticed, learned, or want to remember.',
      },
      category: {
        type: 'string',
        description:
          'Category tag for this capture (e.g. "work", "health", "personal", "research", "idea").',
      },
    },
    required: ['observation', 'category'],
  },
};

interface CaptureArgs {
  observation: string;
  category: string;
}

function isCaptureArgs(x: unknown): x is CaptureArgs {
  if (typeof x !== 'object' || x === null) return false;
  const o = x as Record<string, unknown>;
  return typeof o.observation === 'string' && typeof o.category === 'string';
}

export async function handleCapture(args: unknown): Promise<ToolResponse> {
  if (!isCaptureArgs(args)) {
    return {
      content: [
        { type: 'text', text: 'capture: invalid arguments. Required: observation (string), category (string).' },
      ],
      isError: true,
    };
  }

  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }

  const file = todayObsFile();
  ensureDir(dirname(file));

  const now = new Date().toISOString();
  const header = `# Observations — ${now.slice(0, 10)}\n\n`;
  const line = `- [${now.slice(11, 16)}] [${args.category}] ${args.observation}\n`;

  if (!existsSync(file)) {
    writeFileSync(file, header + line, 'utf8');
  } else {
    appendFileSync(file, line, 'utf8');
  }

  const preview = args.observation.length > 50 ? args.observation.slice(0, 50) + '…' : args.observation;
  return {
    content: [
      { type: 'text', text: `Captured: [${args.category}] — ${preview}` },
    ],
  };
}
