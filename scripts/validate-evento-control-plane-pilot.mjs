#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { isDeepStrictEqual } from 'node:util';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const ALLOWED_PATHS = ['AGENTS.md', '.evento/**',
  'scripts/validate-evento-control-plane-pilot.mjs',
  'scripts/test-evento-control-plane-pilot.mjs',
  '.github/workflows/evento-control-plane-pilot.yml',
  'docs/authority/CONTROL_PLANE_PILOT_V1.md'];
const BASELINE = '8c378d29b15bc25465a9b993879e00f997d8ce55';
const TASK = 'evento-mobile-control-plane-pilot-v1';
const SCHEMAS = {
  'context-pack.schema.json': 'a89a0dc5fb60850a58235e225ac0df3c47e779f9d44ca91f8416afabf19b0a30',
  'memory.schema.json': 'e3068438d3ee451811ff8983ea753214ee3b80b70383fc6d902c36815351fcd7',
  'evento-task.schema.json': '7bc1f311442a835731f265dcf47756ebe875fb807dfa7e852f528603a92ba44c',
  'evento-evidence-pack.schema.json': '6c34db1386cad61fe1b5533c1ea1a1b8d2013a1580eda94f81f8c010fb776bc2',
};
const FORBIDDEN = ['push-directly-to-main', 'self-approve', 'self-merge',
  'production-deploy', 'hosted-supabase-mutation', 'dns-change', 'payment-change',
  'store-release', 'runtime-change', 'customer-truth-write', 'payment-truth-write', 'secret-storage'];
const POLICY = { default: 'deny', provider_neutral: true, self_approval: false,
  self_merge: false, direct_main_push: false, production_mutation: false,
  external_release: false, customer_truth: false, payment_truth: false, runtime_changes: false };
const CHAIN = [
  { project_id: 'evento-acquisition', repository: 'EVENTo0/Evento-project-development-v1',
    role: 'acquisition-and-lead-truth', revision: 'e66a0513926c0bec00f79081f08ffea9ff9dc31d' },
  { project_id: 'evento-one', repository: 'EVENTo0/Evento-One',
    role: 'customer-saas-truth', revision: 'e6d2e6a91ced6eb06ae0c5a276652496c4778954' },
  { project_id: 'evento-mobile', repository: 'EVENTo0/evento-mobile',
    role: 'mobile-operator-customer-interface', revision: BASELINE },
];

// Bounded offline checker for the assertion keywords in the pinned schemas.
function schemaCheck(value, schema, location, errors) {
  const known = new Set(['$schema', '$id', 'title', 'type', 'required', 'properties',
    'items', 'additionalProperties', 'enum', 'minLength', 'minItems', 'minimum', 'maximum', 'format']);
  for (const key of Object.keys(schema)) {
    if (!known.has(key)) throw new Error(`unsupported schema keyword: ${key}`);
  }
  const kind = value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value;
  if (schema.type && ![].concat(schema.type).includes(kind)) {
    errors.push(`${location}: type mismatch`); return;
  }
  if (schema.enum && !schema.enum.includes(value)) errors.push(`${location}: invalid enum`);
  if (kind === 'object') {
    for (const key of schema.required || []) {
      if (!Object.hasOwn(value, key)) errors.push(`${location}: missing ${key}`);
    }
    for (const [key, item] of Object.entries(value)) {
      if (schema.properties?.[key]) schemaCheck(item, schema.properties[key], `${location}.${key}`, errors);
      else if (schema.additionalProperties === false) errors.push(`${location}: unknown ${key}`);
    }
  }
  if (kind === 'array') {
    if (schema.minItems !== undefined && value.length < schema.minItems) errors.push(`${location}: too few items`);
    if (schema.items) value.forEach((item, i) => schemaCheck(item, schema.items, `${location}[${i}]`, errors));
  }
  if (kind === 'string') {
    if (schema.minLength !== undefined && [...value].length < schema.minLength) errors.push(`${location}: too short`);
    if (schema.format === 'date-time' && (!/^\d{4}-\d\d-\d\dT.*(?:Z|[+-]\d\d:\d\d)$/.test(value) || !Number.isFinite(Date.parse(value)))) errors.push(`${location}: invalid date-time`);
  }
  if (kind === 'number' && (!Number.isFinite(value) ||
    (schema.minimum !== undefined && value < schema.minimum) ||
    (schema.maximum !== undefined && value > schema.maximum))) errors.push(`${location}: numeric bounds`);
}

export function validateChangedPaths(paths) {
  return paths.filter(name => !ALLOWED_PATHS.some(allowed =>
    allowed === '.evento/**' ? name.startsWith('.evento/') : name === allowed))
    .map(name => `out-of-scope changed path: ${name}`);
}

export function validateRoot(root = ROOT, { base } = {}) {
  const errors = [];
  const requireValue = (condition, message) => { if (!condition) errors.push(message); };
  const equal = (actual, expected, message) => requireValue(isDeepStrictEqual(actual, expected), message);
  const read = name => fs.readFileSync(path.join(root, name), 'utf8');
  const load = name => JSON.parse(read(name));
  try {
    const schemas = {};
    for (const [name, digest] of Object.entries(SCHEMAS)) {
      const raw = read(`.evento/schemas/${name}`);
      requireValue(createHash('sha256').update(raw).digest('hex') === digest, `schema drift: ${name}`);
      schemas[name] = JSON.parse(raw);
    }
    const pilot = load('.evento/control-plane-pilot.json');
    const task = load('.evento/task-contract.json');
    const context = load('.evento/context-pack.json');
    const evidence = load('.evento/evidence-pack.json');
    equal(Object.keys(pilot).sort(), ['version', 'project_id', 'repository', 'authority_role',
      'baseline', 'contracts', 'authority_chain', 'schema_source', 'required_lanes',
      'memory_policy', 'policy', 'allowed_paths'].sort(), 'unknown or missing pilot manifest field');
    schemaCheck(task, schemas['evento-task.schema.json'], 'task', errors);
    schemaCheck(context, schemas['context-pack.schema.json'], 'context', errors);
    schemaCheck(evidence, schemas['evento-evidence-pack.schema.json'], 'evidence', errors);
    for (const [name, pack] of Object.entries({ pilot, task, context, evidence })) {
      requireValue(pack.project_id === 'evento-mobile', `${name}: project identity drift`);
    }
    equal(pilot.version, 1, 'pilot version drift');
    equal(pilot.repository, 'EVENTo0/evento-mobile', 'repository drift');
    equal(pilot.authority_role, 'mobile-operator-customer-interface', 'Mobile authority drift');
    equal(pilot.authority_chain, CHAIN, 'authority chain/order/revision drift');
    equal(pilot.policy, POLICY, 'default-deny authority policy drift');
    equal(pilot.allowed_paths, ALLOWED_PATHS, 'allowed path scope drift');
    equal(pilot.baseline, { branch: 'main', commit: BASELINE,
      runtime_merge: '9f4bb3255f5fae754efb5d72f0f9622515bcd92c',
      verified_head: 'b9b12d6d69c3235471c83cfbd87155dc7f4ec006',
      ci_run_id: '37298902955', ci_conclusion: 'success' }, 'baseline evidence drift');
    equal(pilot.contracts, { agent_contract: 'AGENTS.md', context_pack: '.evento/context-pack.json',
      task_contract: '.evento/task-contract.json', evidence_pack: '.evento/evidence-pack.json' }, 'contract routing drift');
    equal(pilot.required_lanes, ['agent-contract', 'memory', 'evidence'], 'required lanes drift');
    equal(pilot.schema_source, { repository: 'EVENTo0/AAA-prompt-empire',
      revision: '32437dec9ff2cf47a33b9ca1073415026110d116', paths: [
        'memory/context-pack.schema.json', 'memory/memory.schema.json',
        'schemas/evento-task.schema.json', 'schemas/evento-evidence-pack.schema.json'] }, 'schema provenance drift');
    equal(pilot.memory_policy, { namespace: 'projects/evento-mobile',
      authoritative_states: ['verified', 'active'], promotion_requires_independent_evidence: true,
      share_to_evento_requires_review: true, secret_storage: 'forbidden' }, 'memory policy drift');
    equal(task.task_id, TASK, 'task identity drift');
    equal(context.task, TASK, 'context task drift');
    equal(context.domain, 'mobile', 'context domain drift');
    equal(evidence.task_id, TASK, 'evidence task drift');
    equal([task.mode, task.risk, task.status], ['verify', 'low', 'verifying'], 'task execution mode drift');
    equal(task.deployment_trigger, null, 'deployment trigger prohibited');
    equal(task.preferred_agents, ['codex'], 'unknown agent route');
    equal(task.forbidden_actions, FORBIDDEN, 'forbidden actions drift');
    equal(task.allowed_actions, ['read-repository', 'write-pilot-allowlisted-paths',
      'run-offline-validation', 'open-isolated-draft-pr'], 'allowed actions drift');
    equal(task.dependencies, CHAIN.slice(0, 2).map(x => `${x.repository}@${x.revision}`), 'upstream dependencies drift');
    equal(evidence.status, 'partial', 'pilot cannot self-certify completion');
    equal(evidence.head_sha, BASELINE, 'evidence source revision drift');
    equal(evidence.pr, null, 'new PR evidence must be recorded in the PR handoff');
    const expectedRefs = [
      ['source', `https://github.com/EVENTo0/evento-mobile/commit/${BASELINE}`],
      ['ci', 'https://github.com/EVENTo0/evento-mobile/actions/runs/37298902955'],
      ...CHAIN.slice(0, 2).map(x => ['source', `https://github.com/${x.repository}/commit/${x.revision}`]),
      ['manual_review', 'AGENTS.md'], ['source', 'docs/authority/ONE_MEMBER_UI_V1.md'],
    ];
    equal(evidence.evidence.map(x => [x.type, x.ref]), expectedRefs, 'evidence type/source refs drift');
    equal(evidence.remaining_gates, [
      'Exact pilot PR-head CI and independent review before merge',
      'Configured hosted Mobile to ONE Auth/tenant journey',
      'Physical-device AR/EN, lifecycle and logout acceptance',
      'Signing evidence and separate owner approval before any store release'], 'remaining approval/activation gates drift');

    const ids = new Set();
    for (const [bucket, type] of Object.entries({ facts: 'fact', decisions: 'decision',
      rules: 'rule', lessons: 'lesson', patterns: 'pattern', anti_patterns: 'anti_pattern' })) {
      for (const item of context[bucket] || []) {
        schemaCheck(item, schemas['memory.schema.json'], `context.${bucket}`, errors);
        requireValue(!ids.has(item.id), 'duplicate context id'); ids.add(item.id);
        requireValue(item.memory_type === type && item.project_id === 'evento-mobile' &&
          item.scope === 'project' && ['verified', 'active'].includes(item.validation_state), 'non-authoritative context record');
        requireValue(Array.isArray(item.evidence) && item.evidence.length > 0, 'context provenance missing');
        for (const ref of item.evidence || []) {
          requireValue(expectedRefs.some(x => x[1] === ref.ref), 'context source not in evidence pack');
        }
      }
    }
    for (const id of ['mobile-baseline', 'one-member-entry', 'pilot-isolation',
      'authority-chain', 'no-release', 'synthetic-proof-promotion']) requireValue(ids.has(id), `required context missing: ${id}`);
    equal(context.rules.find(x => x.id === 'authority-chain')?.summary,
      'Website owns acquisition/lead truth. ONE owns customer/SaaS/billing truth. Mobile is a consumer of versioned ONE APIs, never customer or payment truth.', 'context authority rule drift');
    for (const file of [...ALLOWED_PATHS.filter(x => !x.includes('*')),
      'docs/authority/ONE_MEMBER_UI_V1.md', 'docs/authority/ONE_READ_CLIENT_V1.md']) read(file);
    const agent = read('AGENTS.md');
    for (const marker of ['Mobile consumes versioned ONE APIs.', 'Mobile is not customer or payment truth.',
      'Never self-approve or self-merge.', 'Secret storage is forbidden.']) requireValue(agent.includes(marker), `agent boundary missing: ${marker}`);
    if (base !== undefined) {
      requireValue(/^[0-9a-f]{40}$/.test(base), 'base must be an exact commit SHA');
      if (/^[0-9a-f]{40}$/.test(base)) {
        const git = args => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).split('\0').filter(Boolean);
        errors.push(...validateChangedPaths([
          ...git(['diff', '--no-renames', '--name-only', '-z', base, '--']),
          ...git(['ls-files', '--others', '--exclude-standard', '-z']),
        ]));
      }
    }
  } catch (error) { errors.push(`invalid or missing pilot input: ${error.message}`); }
  return errors;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const validArgs = args.length === 0 || (args.length === 2 && args[0] === '--base');
  const errors = validArgs ? validateRoot(ROOT, { base: args[1] }) : ['usage: validator [--base <exact-sha>]'];
  if (errors.length) { console.error(errors.join('\n')); process.exitCode = 1; }
  else {
    console.log('EVENTO MOBILE CONTROL-PLANE PILOT: PASSED');
    console.log('Offline contract validation only; no hosted, device or release proof.');
    console.log(`Tested source: ${execFileSync('git', ['rev-parse', 'HEAD'], { cwd: ROOT, encoding: 'utf8' }).trim()}`);
  }
}
