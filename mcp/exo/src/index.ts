#!/usr/bin/env node
/**
 * exo-mcp — MCP server exposing Exo (cognitive stack for Claude) tools to Claude Desktop.
 *
 * Wraps ~/Exo (or $EXO_DIR) and surfaces the same KB operations as MCP tools.
 * The full Exo experience lives in Claude Code; this server is the Desktop lite mode.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  CallToolResult,
} from '@modelcontextprotocol/sdk/types.js';

import { captureTool, handleCapture } from './tools/capture.js';
import { dreamTool, handleDream } from './tools/dream.js';
import { pulseTool, handlePulse } from './tools/pulse.js';
import { dailyTool, handleDaily } from './tools/daily.js';
import { prepTool, handlePrep } from './tools/prep.js';
import { wrapTool, handleWrap } from './tools/wrap.js';
import { weeklyTool, handleWeekly } from './tools/weekly.js';
import { enrichTool, handleEnrich } from './tools/enrich.js';

const server = new Server(
  { name: 'exo', version: '0.1.0' },
  { capabilities: { tools: {} } },
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    captureTool,
    dreamTool,
    pulseTool,
    dailyTool,
    prepTool,
    wrapTool,
    weeklyTool,
    enrichTool,
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (req): Promise<CallToolResult> => {
  const { name, arguments: args } = req.params;
  switch (name) {
    case 'capture':
      return (await handleCapture(args)) as CallToolResult;
    case 'dream':
      return (await handleDream(args)) as CallToolResult;
    case 'pulse':
      return (await handlePulse(args)) as CallToolResult;
    case 'daily':
      return (await handleDaily(args)) as CallToolResult;
    case 'prep':
      return (await handlePrep(args)) as CallToolResult;
    case 'wrap':
      return (await handleWrap(args)) as CallToolResult;
    case 'weekly':
      return (await handleWeekly(args)) as CallToolResult;
    case 'enrich':
      return (await handleEnrich(args)) as CallToolResult;
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
