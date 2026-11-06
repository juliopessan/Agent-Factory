import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { createTool } from '@mastra/core/tools';
import { z } from 'zod';
import { STUDIO_DIR } from '../factory/loader';

// super-board lanes. Cards only move forward one lane at a time, or back to Build when QA/Review fails.
export const LANES = ['Backlog', 'Ready', 'Build', 'QA', 'Review', 'Done'] as const;
export const laneSchema = z.enum(LANES);
export type Lane = z.infer<typeof laneSchema>;

export const cardSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  labels: z.array(z.enum(['feature', 'bug', 'qa', 'security', 'docs'])),
  lane: laneSchema,
  owner: z.string().optional(),
  evidence: z.array(z.object({ at: z.string(), by: z.string(), note: z.string() })),
  updatedAt: z.string(),
});
export type Card = z.infer<typeof cardSchema>;

const BOARD_FILE = process.env.FACTORY_BOARD_FILE ?? join(STUDIO_DIR, 'factory-board.json');

function load(): Card[] {
  if (!existsSync(BOARD_FILE)) return [];
  return JSON.parse(readFileSync(BOARD_FILE, 'utf8')) as Card[];
}
function save(cards: Card[]) {
  writeFileSync(BOARD_FILE, JSON.stringify(cards, null, 2));
}

export function createCard(input: Pick<Card, 'title' | 'description' | 'labels'>): Card {
  const cards = load();
  const card: Card = {
    ...input,
    id: `SB-${String(cards.length + 1).padStart(3, '0')}`,
    lane: 'Backlog',
    evidence: [],
    updatedAt: new Date().toISOString(),
  };
  save([...cards, card]);
  return card;
}

export function getCard(id: string): Card {
  const card = load().find(c => c.id === id);
  if (!card) throw new Error(`Card ${id} not found`);
  return card;
}

export function moveCard(id: string, to: Lane, by: string, note: string): Card {
  const cards = load();
  const card = cards.find(c => c.id === id);
  if (!card) throw new Error(`Card ${id} not found`);
  const from = LANES.indexOf(card.lane);
  const target = LANES.indexOf(to);
  const sendBack = to === 'Build' && (card.lane === 'QA' || card.lane === 'Review');
  if (target !== from + 1 && !sendBack && target !== from) {
    throw new Error(`Illegal move ${card.lane} -> ${to}. Cards advance one lane at a time; QA/Review can only send back to Build.`);
  }
  card.lane = to;
  card.owner = by;
  card.evidence.push({ at: new Date().toISOString(), by, note });
  card.updatedAt = new Date().toISOString();
  save(cards);
  return card;
}

export const listBoardTool = createTool({
  id: 'list-board',
  description: 'List cards on the super-board Kanban, optionally filtered by lane.',
  inputSchema: z.object({ lane: laneSchema.optional() }),
  outputSchema: z.object({ cards: z.array(cardSchema) }),
  execute: async ({ lane }) => ({ cards: load().filter(c => !lane || c.lane === lane) }),
});

export const createCardTool = createTool({
  id: 'create-card',
  description: 'Add a new card to the Backlog lane.',
  inputSchema: z.object({
    title: z.string().min(3),
    description: z.string(),
    labels: z.array(z.enum(['feature', 'bug', 'qa', 'security', 'docs'])).default(['feature']),
  }),
  outputSchema: cardSchema,
  execute: async input => createCard(input),
});

export const moveCardTool = createTool({
  id: 'move-card',
  description:
    'Move a card to the next lane with a note of evidence. QA and Review may send a card back to Build. Moving to Done is a merge and needs human approval.',
  inputSchema: z.object({ id: z.string(), to: laneSchema, by: z.string(), note: z.string().min(1) }),
  outputSchema: cardSchema,
  // Human oversight: every move asks for approval in Studio (Agent-Factory `beforeMerge` gate).
  requireApproval: true,
  execute: async ({ id, to, by, note }) => moveCard(id, to, by, note),
});

export const boardTools = { listBoardTool, createCardTool, moveCardTool };
