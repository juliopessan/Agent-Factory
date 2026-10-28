import assert from 'node:assert/strict';
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseDocument } from 'yaml';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
function filesAt(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    if (['node_modules', '.git', '.factory', 'artifact'].includes(entry.name)) return [];
    const path = join(directory, entry.name);
    return entry.isDirectory() ? filesAt(path) : [path];
  });
}
const files = filesAt(root);
for (const path of files.filter(path => ['.yml', '.yaml'].includes(extname(path)))) {
  const document = parseDocument(readFileSync(path, 'utf8'), { uniqueKeys: true });
  assert.equal(document.errors.length, 0, `${path}: ${document.errors}`);
  const workflow = document.toJS();
  assert(workflow.on && workflow.jobs && workflow.permissions?.contents === 'read', `${path}: missing workflow contract`);
  assert(!workflow.on.pull_request_target, `${path}: privileged pull_request_target is prohibited`);
  for (const job of Object.values(workflow.jobs)) {
    for (const step of job.steps ?? []) {
      if (step.uses?.startsWith('actions/')) assert.match(step.uses, /@[a-f0-9]{40}$/, `${path}: unpinned action`);
      assert(!step['continue-on-error'], `${path}: checks cannot ignore failures`);
    }
  }
}
const product = parseDocument(readFileSync(join(root, '.github/workflow-templates/product-cicd.yml'), 'utf8')).toJS();
assert.equal(product.jobs.build.needs, 'quality');
assert.deepEqual(product.jobs.uat.needs, ['build', 'dev']);
assert.deepEqual(product.jobs.prod.needs, ['build', 'uat']);
assert.match(product.jobs.dev.if, /workflow_dispatch/);
for (const stage of ['dev', 'uat', 'prod']) {
  assert.equal(product.jobs[stage].with.environment, stage.toUpperCase());
  assert.equal(product.jobs[stage].uses, './.github/workflows/deploy-product.yml');
  assert.equal(product.jobs[stage].with.manifest_hash, '${{ needs.build.outputs.manifest_hash }}');
}
const deploymentText = readFileSync(join(root, '.github/workflows/deploy-product.yml'), 'utf8');
const deployment = parseDocument(deploymentText).toJS();
assert.equal(deployment.jobs.deploy.environment, '${{ inputs.environment }}');
assert.equal(deployment.concurrency['cancel-in-progress'], false);
assert(deploymentText.includes('prevent_self_review') && deploymentText.includes('protected_branches'));
let localLinks = 0;
for (const path of files.filter(path => extname(path) === '.md')) {
  const content = readFileSync(path, 'utf8');
  let fenced = false;
  let tableColumns = 0;
  for (const line of content.split(/\r?\n/)) {
    if (line.startsWith('```')) { fenced = !fenced; tableColumns = 0; continue; }
    if (fenced) continue;
    if (/^\|.*\|$/.test(line)) {
      const columns = (line.match(/(?<!\\)\|/g) ?? []).length;
      if (tableColumns) assert.equal(columns, tableColumns, `${path}: inconsistent table`);
      tableColumns = columns;
    } else tableColumns = 0;
    for (const match of line.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
      const target = match[1];
      if (/^(https?:|#)/.test(target)) continue;
      assert(existsSync(resolve(dirname(path), decodeURIComponent(target.split('#')[0]))), `${path}: broken link ${target}`);
      localLinks++;
    }
  }
  assert(!fenced, `${path}: unclosed code fence`);
}
for (const path of files.filter(path => path.endsWith('.agent.md') || path.endsWith('.prompt.md'))) {
  const content = readFileSync(path, 'utf8');
  const header = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  assert(header, `${path}: missing frontmatter`);
  const document = parseDocument(header[1]);
  assert.equal(document.errors.length, 0, `${path}: invalid frontmatter`);
  assert(document.toJS().description, `${path}: missing description`);
}
const bootstrap = readFileSync(join(root, 'prompts/BOOTSTRAP.md'), 'utf8');
const onboardingStart = bootstrap.indexOf('## Guided Onboarding');
const planningStart = bootstrap.indexOf('## Planning Workflow');
assert(onboardingStart >= 0 && planningStart > onboardingStart, 'Onboarding must precede planning');
const onboarding = bootstrap.slice(onboardingStart, planningStart);
for (const requirement of [
  'one or two questions per turn', 'just explore is read-only', 'What would you like to create or improve',
  'File > Open Folder', 'temporary ZIP extraction', 'VERIFIED', 'MISSING', 'NOT CHECKED',
  'VS Code chat for beginners', 'Copilot CLI as an advanced alternative',
  'Never request passwords, tokens, private keys, or production secrets',
  'Wait for explicit confirmation of those writes', 'PROJECT_BRIEF and TASK_BOARD',
  'progress was not saved to disk', 'EXPLORE ONLY', 'BLOCKED', 'READY FOR PLANNING',
  'fast path', 'not that architecture, implementation, or release is approved',
]) assert(onboarding.includes(requirement), `Missing onboarding contract: ${requirement}`);
for (const entry of ['.github/agents/chief-of-staff.agent.md', '.github/prompts/BOOTSTRAP.prompt.md']) {
  const content = readFileSync(join(root, entry), 'utf8');
  assert(content.includes('../../prompts/BOOTSTRAP.md#guided-onboarding'), `${entry}: missing shared onboarding`);
  assert(content.includes('one or two questions per turn'), `${entry}: missing progressive conversation`);
}
assert(bootstrap.includes('For EXPLORE ONLY or BLOCKED, do not execute the steps below.'), 'Planning must remain gated');
const reviewPolicy = readFileSync(join(root, 'REVIEW.md'), 'utf8');
const claudeEntry = readFileSync(join(root, 'CLAUDE.md'), 'utf8');
const factoryInstructions = readFileSync(join(root, '.github/copilot-instructions.md'), 'utf8');
assert(claudeEntry.includes('(.github/copilot-instructions.md)') && claudeEntry.includes('(REVIEW.md)'), 'Claude entry must reuse Factory rules and review policy');
assert(factoryInstructions.includes('[REVIEW.md](../REVIEW.md)'), 'Copilot instructions must explicitly route reviews to the shared policy');
for (const requirement of [
  'REV-1', '## Risk And Depth', '## Findings Contract', '## Review And Convergence',
  'INTRODUCED', 'PRE_EXISTING', 'UNKNOWN', 'REJECTED_WITH_EVIDENCE', 'RISK_ACCEPTED_BY_HUMAN',
  'After three review rounds', 'stop automatic fix/review iteration', 'New changes invalidate affected review evidence',
  'Model agreement alone is not evidence', 'NOT OBSERVED', 'does not configure branch protections',
]) assert(reviewPolicy.includes(requirement), `Missing review policy contract: ${requirement}`);
const reviewReport = readFileSync(join(root, 'templates/AGENT_REPORT.md'), 'utf8');
const commander = readFileSync(join(root, '.github/agents/chief-of-staff.agent.md'), 'utf8');
assert(reviewReport.includes('[REVIEW.md](../REVIEW.md)') && reviewReport.includes('## Review Evidence'), 'Agent reports must retain shared review evidence');
assert(commander.includes('[REVIEW.md](../../REVIEW.md)') && commander.includes('separate-context review'), 'Commander must coordinate shared review without a new role');
for (const requirement of ['Risk tier and rationale', 'Reviewer and independence', 'Round and prior review reference', 'NOT OBSERVED', 'human reference for risk acceptance']) {
  assert(reviewReport.includes(requirement), `Missing review report field: ${requirement}`);
}
const projectReview = readFileSync(join(root, 'templates/REVIEW.md'), 'utf8');
assert(projectReview.includes('(../REVIEW.md)') && projectReview.includes('never overrides it'), 'Project review guide must defer to the shared policy');
for (const requirement of [
  'What Failure Looks Like Here', 'Do Not Flag', 'Repeated Findings Become Rules', 'Reviewer Regression Cases',
  'An agent review is evidence, never approval', 'NOT OBSERVED',
]) assert(projectReview.includes(requirement), `Missing project review guide contract: ${requirement}`);
for (const entry of ['.github/copilot-instructions.md', '.github/agents/chief-of-staff.agent.md']) {
  assert(readFileSync(join(root, entry), 'utf8').includes('templates/REVIEW.md'), `${entry}: missing project review guide`);
}
const sdlcReview = readFileSync(join(root, 'docs/SDLC_REVIEW.md'), 'utf8');
for (const requirement of [
  '## Software Factory Reference', 'Factory as code', 'Measure before routing', 'Improvement stays reviewed',
  'never self-modifies its governance', 'within approved Microsoft services', 'Two human roles',
]) assert(sdlcReview.includes(requirement), `Missing software factory reference contract: ${requirement}`);
const phase2 = readFileSync(join(root, 'docs/factory-extensions/PHASE2_SPEC.md'), 'utf8');
for (const requirement of [
  'PROPOSED, NOT APPROVED', 'FAC-ARCH-1', 'FAC-CON-1', 'FAC-CON-2', 'FAC-PLAN-1', 'FAC-OWN-1',
  'Agents cannot approve', 'Gates are invariants', 'No new package', 'No `run` command in Phase 2',
]) assert(phase2.includes(requirement), `Missing Phase 2 proposal contract: ${requirement}`);
assert(!existsSync(join(root, 'factory.json')) && !existsSync(join(root, 'scripts/Invoke-FactoryManifest.ps1')), 'Phase 2 implementation files require recorded FAC approval');
assert(readFileSync(join(root, 'docs/factory/TASK_BOARD.md'), 'utf8').includes('| Phase 2 Factory as Code and Run Ledger |'), 'Task board must register the Phase 2 proposal');
const azureGuide = readFileSync(join(root, 'docs/AZURE_INTEGRATION.md'), 'utf8');
const azureChecker = readFileSync(join(root, 'scripts/Test-FactoryAzurePrerequisites.ps1'), 'utf8');
for (const requirement of ['AZ-ARCH-1', 'AZ-CON-1', 'AZ-PLAN-1', 'AZ-OWN-1', 'NOT CHECKED', '--read-only', '--tool', 'hooks', 'Copilot CLI does not read', 'separate', 'NOT RUN']) {
  assert(azureGuide.includes(requirement), `Missing optional Azure guide contract: ${requirement}`);
}
for (const entry of ['prompts/BOOTSTRAP.md', '.github/agents/chief-of-staff.agent.md', '.github/agents/integrations.agent.md']) {
  const content = readFileSync(join(root, entry), 'utf8');
  assert(content.includes('AZURE_INTEGRATION.md') && content.includes('NOT CHECKED'), `${entry}: missing optional Azure routing or honest capability status`);
  assert(content.includes('azure-prepare') && content.includes('azure.yaml'), `${entry}: missing conditional azd routing`);
}
assert(azureChecker.includes('-CommandType Application') && azureChecker.includes('LOCAL_CHECKS_COMPLETE'), 'Azure checker must expose offline discovery semantics');
const factoryCi = parseDocument(readFileSync(join(root, '.github/workflows/ci.yml'), 'utf8')).toJS();
assert(factoryCi.jobs.validate.steps.some(step => step.run === './tests/azure-integration.tests.ps1'), 'Factory CI must execute the offline Azure suite');
console.log(`PASS: YAML/frontmatter syntax, pinned actions, promotion dependencies, deployment protection contracts, guided onboarding, review policy and optional Azure wiring, Markdown tables/fences, and ${localLinks} local links. Conversational behavior, live review enforcement and Azure activation were not evaluated.`);
