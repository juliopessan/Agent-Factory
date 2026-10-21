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
console.log(`PASS: YAML/frontmatter syntax, pinned actions, promotion dependencies, deployment protection contracts, Markdown tables/fences, and ${localLinks} local links.`);