import { homedir } from 'os';
import { join } from 'path';
import { existsSync, mkdirSync } from 'fs';

/**
 * Resolve the root of the user's ~/Exo data directory.
 * Honors the EXO_DIR environment variable; defaults to ~/Exo.
 */
export function exoRoot(): string {
  return process.env.EXO_DIR || join(homedir(), 'Exo');
}

/**
 * Get an absolute path to a named subdirectory of ~/Exo.
 */
export function exoSubdir(name: string): string {
  return join(exoRoot(), name);
}

/**
 * True if the Exo setup sentinel exists (~/Exo/.exo/setup-complete).
 * Tools should warn (not crash) when this is false.
 */
export function isSetupComplete(): boolean {
  return existsSync(join(exoRoot(), '.exo', 'setup-complete'));
}

/**
 * True if the Exo root directory itself exists.
 */
export function exoRootExists(): boolean {
  return existsSync(exoRoot());
}

/**
 * Path to today's observations file (~/Exo/observations/YYYY-MM-DD.md).
 */
export function todayObsFile(): string {
  const d = new Date().toISOString().slice(0, 10);
  return join(exoSubdir('observations'), `${d}.md`);
}

/**
 * Ensure a directory exists; creates it (and parents) if not.
 */
export function ensureDir(path: string): void {
  if (!existsSync(path)) {
    mkdirSync(path, { recursive: true });
  }
}

/**
 * Standard not-ready warning text for tools to surface when ~/Exo is missing.
 */
export function notReadyMessage(): string {
  return (
    `Exo data directory not found at ${exoRoot()}.\n\n` +
    `Run the Exo installer (install.sh) from the main repo, ` +
    `or set the EXO_DIR environment variable in your Claude Desktop MCP config.`
  );
}
