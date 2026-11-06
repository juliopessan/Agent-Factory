import { createStep, createWorkflow } from '@mastra/core/workflows';
import { z } from 'zod';
import { createCard, getCard, moveCard, cardSchema } from '../tools/board';

const ask = async (mastra: any, agentId: string, prompt: string) => {
  const res = await mastra.getAgentById(agentId).generate(prompt);
  return res.text as string;
};

const state = z.object({ card: cardSchema, spec: z.string().optional(), build: z.string().optional() });

const triage = createStep({
  id: 'triage',
  description: 'Chief of Staff turns the request into a Backlog card and moves it to Ready.',
  inputSchema: z.object({
    title: z.string().min(3),
    request: z.string().min(10),
    type: z.enum(['feature', 'bug']).default('feature'),
    implementer: z.enum(['backend', 'frontend', 'integrations']).default('backend'),
  }),
  outputSchema: state.extend({ implementer: z.string() }),
  execute: async ({ inputData, mastra }) => {
    const brief = await ask(
      mastra,
      'chief-of-staff',
      `Triage this request into a short task contract (goal, scope, out of scope, acceptance criteria). Do not call tools.\n\n${inputData.request}`,
    );
    const card = createCard({ title: inputData.title, description: brief, labels: [inputData.type] });
    return { card: moveCard(card.id, 'Ready', 'Chief of Staff', 'Triaged into a task contract.'), implementer: inputData.implementer };
  },
});

const specify = createStep({
  id: 'specification',
  description: 'Architect writes the architecture and contracts. Pauses for human approval (beforeImplementation).',
  inputSchema: state.extend({ implementer: z.string() }),
  outputSchema: state.extend({ implementer: z.string() }),
  suspendSchema: z.object({ gate: z.literal('beforeImplementation'), cardId: z.string(), spec: z.string() }),
  resumeSchema: z.object({ approved: z.boolean(), comment: z.string().optional() }),
  execute: async ({ inputData, mastra, resumeData, suspend, suspendData, bail }) => {
    const spec =
      (suspendData as { spec?: string } | undefined)?.spec ??
      (await ask(mastra, 'architect', `Write the architecture, contracts and implementation plan for card ${inputData.card.id}:\n\n${inputData.card.description}`));
    if (!resumeData) return suspend({ gate: 'beforeImplementation', cardId: inputData.card.id, spec });
    if (!resumeData.approved) return bail({ ...inputData, spec: `Rejected: ${resumeData.comment ?? ''}` });
    return { ...inputData, spec, card: moveCard(inputData.card.id, 'Build', 'Human', `Spec approved. ${resumeData.comment ?? ''}`) };
  },
});

const build = createStep({
  id: 'build',
  description: 'The implementation agent produces the change plan and code for the card.',
  inputSchema: state.extend({ implementer: z.string() }),
  outputSchema: state,
  execute: async ({ inputData, mastra }) => {
    const out = await ask(
      mastra,
      inputData.implementer,
      `Implement card ${inputData.card.id} following the approved spec. Give the smallest safe change, tests first.\n\nSpec:\n${inputData.spec}`,
    );
    return { card: moveCard(inputData.card.id, 'QA', inputData.implementer, 'Build delivered.'), spec: inputData.spec, build: out };
  },
});

const review = (id: 'qa' | 'security' | 'docs', prompt: string) =>
  createStep({
    id: `${id}-review`,
    inputSchema: state,
    outputSchema: z.object({ verdict: z.enum(['PASS', 'FAIL']), report: z.string() }),
    execute: async ({ inputData, mastra }) => {
      const report = await ask(mastra, id, `${prompt}\nStart your answer with PASS or FAIL.\n\nSpec:\n${inputData.spec}\n\nBuild:\n${inputData.build}`);
      return { verdict: (/^\W*FAIL/i.test(report) ? 'FAIL' : 'PASS') as 'PASS' | 'FAIL', report };
    },
  });

const mergeGate = createStep({
  id: 'merge-gate',
  description: 'Human decides whether to merge (beforeMerge). Any FAIL sends the card back to Build.',
  inputSchema: z.object({
    'qa-review': z.object({ verdict: z.string(), report: z.string() }),
    'security-review': z.object({ verdict: z.string(), report: z.string() }),
    'docs-review': z.object({ verdict: z.string(), report: z.string() }),
  }),
  outputSchema: z.object({ card: cardSchema, outcome: z.string() }),
  suspendSchema: z.object({ gate: z.literal('beforeMerge'), cardId: z.string(), verdicts: z.record(z.string(), z.string()) }),
  resumeSchema: z.object({ merge: z.boolean(), comment: z.string().optional() }),
  execute: async ({ inputData, resumeData, suspend, getStepResult }) => {
    const cardId = (getStepResult(build) as any).card.id as string;
    const verdicts = Object.fromEntries(Object.entries(inputData).map(([k, v]) => [k, v.verdict]));
    const failed = Object.values(verdicts).includes('FAIL');
    if (failed) {
      return { card: moveCard(cardId, 'Build', 'QA', `Checks failed: ${JSON.stringify(verdicts)}`), outcome: 'Sent back to Build' };
    }
    if (getCard(cardId).lane === 'QA') moveCard(cardId, 'Review', 'QA', 'QA, security and docs passed.');
    if (!resumeData) return suspend({ gate: 'beforeMerge', cardId, verdicts });
    if (!resumeData.merge) return { card: moveCard(cardId, 'Build', 'Human', `Merge declined. ${resumeData.comment ?? ''}`), outcome: 'Merge declined' };
    return { card: moveCard(cardId, 'Done', 'Human', `Merged. ${resumeData.comment ?? ''}`), outcome: 'Done' };
  },
});

export const deliveryWorkflow = createWorkflow({
  id: 'factory-delivery',
  description: 'Agent-Factory stages on the super-board Kanban: triage -> spec (approval) -> build -> QA/security/docs -> merge (approval).',
  inputSchema: triage.inputSchema,
  outputSchema: mergeGate.outputSchema,
})
  .then(triage)
  .then(specify)
  .then(build)
  .parallel([
    review('qa', 'Verify the build against the acceptance criteria and test strategy.'),
    review('security', 'Security-review the build: high-confidence, exploitable issues only.'),
    review('docs', 'Check the docs and user-facing notes the build needs.'),
  ])
  .then(mergeGate)
  .commit();
