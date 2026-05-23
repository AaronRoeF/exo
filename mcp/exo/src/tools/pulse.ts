import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { readdirSync, readFileSync, existsSync, statSync } from 'fs';
import { join } from 'path';
import { exoSubdir, exoRootExists, notReadyMessage } from '../exo-dir.js';
import { ToolResponse, PulseAction } from '../types.js';

export const pulseTool: Tool = {
  name: 'pulse',
  description:
    'Project tracker. Actions: "status" (list active projects), "focus" (which project is the current focus), "new" (scaffold a new project — Code-side recommended), "list" (list all projects).',
  inputSchema: {
    type: 'object',
    properties: {
      action: {
        type: 'string',
        enum: ['status', 'focus', 'new', 'list'],
        description: 'Which pulse subcommand to run.',
      },
      args: {
        type: 'object',
        description: 'Optional extra arguments (e.g. {"slug": "my-project"} for "new").',
        additionalProperties: true,
      },
    },
    required: ['action'],
  },
};

interface PulseArgs {
  action: PulseAction;
  args?: Record<string, unknown>;
}

function isPulseArgs(x: unknown): x is PulseArgs {
  if (typeof x !== 'object' || x === null) return false;
  const o = x as Record<string, unknown>;
  return (
    typeof o.action === 'string' &&
    ['status', 'focus', 'new', 'list'].includes(o.action)
  );
}

interface PulseSummary {
  slug: string;
  title?: string;
  status?: string;
  focus?: boolean;
  mtime: number;
}

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

function listProjects(): PulseSummary[] {
  const projDir = exoSubdir('projects');
  if (!existsSync(projDir)) return [];

  const out: PulseSummary[] = [];
  for (const entry of readdirSync(projDir)) {
    const pulsePath = join(projDir, entry, 'pulse.md');
    if (!existsSync(pulsePath)) continue;
    try {
      const content = readFileSync(pulsePath, 'utf8');
      const fm = parseFrontmatter(content);
      out.push({
        slug: entry,
        title: typeof fm.title === 'string' ? fm.title : undefined,
        status: typeof fm.status === 'string' ? fm.status : undefined,
        focus: fm.focus === true,
        mtime: statSync(pulsePath).mtimeMs,
      });
    } catch {
      // skip unreadable
    }
  }
  return out;
}

export async function handlePulse(args: unknown): Promise<ToolResponse> {
  if (!exoRootExists()) {
    return { content: [{ type: 'text', text: notReadyMessage() }], isError: true };
  }
  if (!isPulseArgs(args)) {
    return {
      content: [{ type: 'text', text: 'pulse: invalid arguments. Required: action ("status" | "focus" | "new" | "list").' }],
      isError: true,
    };
  }

  switch (args.action) {
    case 'status': {
      const all = listProjects();
      const active = all.filter((p) => (p.status ?? 'active') === 'active');
      if (active.length === 0) {
        return { content: [{ type: 'text', text: 'No active projects found in ~/Exo/projects/.' }] };
      }
      const lines = active
        .sort((a, b) => b.mtime - a.mtime)
        .map((p) => `- ${p.slug}${p.title ? ` — ${p.title}` : ''}${p.focus ? ' [FOCUS]' : ''}`);
      return { content: [{ type: 'text', text: `Active projects:\n${lines.join('\n')}` }] };
    }

    case 'focus': {
      const all = listProjects();
      const focused = all.find((p) => p.focus);
      if (focused) {
        return { content: [{ type: 'text', text: `Current focus: ${focused.slug}${focused.title ? ` — ${focused.title}` : ''}` }] };
      }
      return {
        content: [{ type: 'text', text: 'No focus lock set. Use the Claude Code /pulse focus <slug> command to set one.' }],
      };
    }

    case 'list': {
      const all = listProjects();
      if (all.length === 0) {
        return { content: [{ type: 'text', text: 'No projects found in ~/Exo/projects/.' }] };
      }
      const lines = all
        .sort((a, b) => a.slug.localeCompare(b.slug))
        .map((p) => `- ${p.slug} [${p.status ?? 'active'}]${p.title ? ` — ${p.title}` : ''}`);
      return { content: [{ type: 'text', text: `All projects:\n${lines.join('\n')}` }] };
    }

    case 'new': {
      const slug =
        args.args && typeof args.args.slug === 'string' ? args.args.slug : '<slug>';
      return {
        content: [
          {
            type: 'text',
            text:
              `Project scaffolding (new "${slug}") is best run from the Claude Code /pulse skill — ` +
              `it creates ~/Exo/projects/<slug>/pulse.md with the right template and frontmatter. ` +
              `Run /pulse new ${slug} in Claude Code.`,
          },
        ],
      };
    }
  }
}
