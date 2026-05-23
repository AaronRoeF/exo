/**
 * Shared TypeScript types for the exo-mcp server.
 * Kept intentionally minimal — these mirror the file shapes that the
 * Claude Code Exo skills read and write under ~/Exo/.
 */

/**
 * Standard MCP tool response envelope.
 */
export interface ToolResponse {
  content: Array<{ type: 'text'; text: string }>;
  isError?: boolean;
}

/**
 * A single TIL capture line appended to ~/Exo/observations/<date>.md.
 */
export interface Observation {
  timestamp: string; // ISO timestamp
  category: string;
  text: string;
}

/**
 * Frontmatter shape for ~/Exo/projects/<slug>/pulse.md.
 */
export interface ProjectPulse {
  slug: string;
  title?: string;
  status?: 'active' | 'paused' | 'done' | 'idea' | string;
  focus?: boolean;
  lastTouched?: string;
  owner?: string;
  tags?: string[];
}

/**
 * Frontmatter / structured fields for a person file (~/Exo/people/<name>.md).
 */
export interface PersonFile {
  name: string;
  company?: string;
  role?: string;
  email?: string;
  linkedin?: string;
  lastInteraction?: string;
  notes?: string;
  rawMarkdown: string;
}

/**
 * Frontmatter / structured fields for an account file (~/Exo/accounts/<slug>.md).
 */
export interface AccountFile {
  slug: string;
  name: string;
  domain?: string;
  industry?: string;
  stage?: string;
  notes?: string;
  rawMarkdown: string;
}

/**
 * Valid pulse subcommands.
 */
export type PulseAction = 'status' | 'focus' | 'new' | 'list';

/**
 * Pulse tool input.
 */
export interface PulseArgs {
  action: PulseAction;
  args?: Record<string, unknown>;
}
