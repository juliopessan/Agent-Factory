import { Agent } from '@mastra/core/agent';
import { Memory } from '@mastra/memory';
import { loadAgentProfiles, loadSkillSummary } from '../factory/loader';
import { boardTools, listBoardTool } from '../tools/board';

const model = process.env.FACTORY_MODEL ?? 'anthropic/claude-sonnet-5-5';

// Which super-board lane each Agent-Factory role works in.
const laneSkills: Record<string, string[]> = {
  'chief-of-staff': ['super-board', 'super-collect'],
  backend: ['super-build'],
  frontend: ['super-build'],
  integrations: ['super-build'],
  qa: ['super-qa'],
  security: ['pr-security-review'],
  architect: ['super-review'],
  docs: [],
};

const studioRules = `
## Running inside Mastra Studio
You operate through Mastra Studio, not GitHub Copilot. You cannot edit files or run commands here.
Work is tracked on the super-board Kanban (Backlog -> Ready -> Build -> QA -> Review -> Done).
Use the board tools to read cards and to record evidence. Never claim a check ran unless it did.
Answer in the user's language.`;

const profiles = loadAgentProfiles();

const built: Record<string, Agent> = {};
for (const p of profiles.filter(p => p.id !== 'chief-of-staff')) {
  const lanes = (laneSkills[p.id] ?? []).map(loadSkillSummary).filter(Boolean);
  built[p.id] = new Agent({
    id: p.id,
    name: p.name,
    description: p.description,
    instructions: [p.body, lanes.length ? `## super-board lane rules\n${lanes.join('\n\n')}` : '', studioRules].join('\n\n'),
    model,
    tools: { listBoardTool },
    memory: new Memory(),
  });
}

const chief = profiles.find(p => p.id === 'chief-of-staff')!;
built['chief-of-staff'] = new Agent({
  id: 'chief-of-staff',
  name: chief.name,
  description: chief.description,
  instructions: [
    chief.body,
    `## super-board lane rules\n${['super-board', 'super-collect'].map(loadSkillSummary).join('\n\n')}`,
    studioRules,
    'You own the board: create cards, move them between lanes, and delegate to specialists.',
  ].join('\n\n'),
  model,
  tools: boardTools,
  agents: Object.fromEntries(Object.entries(built)),
  memory: new Memory(),
});

export const factoryAgents = built;
