import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { parse } from 'yaml';

// mastra dev runs from a temp folder, so walk up from cwd until we find the project root.
function findProjectRoot(): string {
  let dir = process.cwd();
  while (true) {
    if (existsSync(join(dir, 'factory.json')) && existsSync(join(dir, '.github/agents'))) return dir;
    const parent = dirname(dir);
    if (parent === dir) return process.cwd();
    dir = parent;
  }
}
export const PROJECT_ROOT = process.env.FACTORY_ROOT ?? findProjectRoot();
/** Root of the Agent-Factory kit (holds factory.json and .github/agents). */
export const FACTORY_DIR = PROJECT_ROOT;
export const STUDIO_DIR = join(PROJECT_ROOT, 'studio');

export interface AgentProfile {
  file: string;
  id: string;
  name: string;
  description: string;
  delegatesTo: string[];
  body: string;
}

function parseFrontmatter(raw: string) {
  const match = raw.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  if (!match) return { meta: {} as Record<string, unknown>, body: raw };
  return { meta: (parse(match[1]!) ?? {}) as Record<string, unknown>, body: match[2]! };
}

const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

/** Reads Agent-Factory `.agent.md` profiles (GitHub Copilot format). */
export function loadAgentProfiles(): AgentProfile[] {
  const dir = join(FACTORY_DIR, '.github/agents');
  return readdirSync(dir)
    .filter(f => f.endsWith('.agent.md'))
    .map(file => {
      const { meta, body } = parseFrontmatter(readFileSync(join(dir, file), 'utf8'));
      const name = String(meta.name ?? file.replace('.agent.md', ''));
      return {
        file,
        id: slug(file.replace('.agent.md', '')),
        name,
        description: String(meta.description ?? ''),
        delegatesTo: Array.isArray(meta.agents) ? meta.agents.map(String) : [],
        body,
      };
    });
}

/** super-board skill descriptions, used as lane rules for the matching roles. */
const laneRules = JSON.parse(readFileSync(join(STUDIO_DIR, 'src/mastra/factory/lane-rules.json'), 'utf8')) as {
  skills: Record<string, string>;
};
export function loadSkillSummary(skill: string): string {
  return laneRules.skills[skill] ?? '';
}

export const factoryConfig = JSON.parse(readFileSync(join(FACTORY_DIR, 'factory.json'), 'utf8')) as {
  metadata: { name: string; version: string };
  stages: string[];
  approvalGates: string[];
};
