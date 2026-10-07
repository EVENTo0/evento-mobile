#!/usr/bin/env node
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { ROOT, ALLOWED_PATHS, validateRoot, validateChangedPaths } from './validate-evento-control-plane-pilot.mjs';

function fixture(run) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'evento-mobile-pilot-'));
  try {
    for (const name of ['.evento', 'AGENTS.md', 'docs/authority', 'scripts', '.github/workflows/evento-control-plane-pilot.yml']) {
      fs.mkdirSync(path.dirname(path.join(root, name)), { recursive: true });
      fs.cpSync(path.join(ROOT, name), path.join(root, name), { recursive: true });
    }
    run(root);
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
}
const edit = (root, name, mutate) => {
  const file = path.join(root, '.evento', name);
  const value = JSON.parse(fs.readFileSync(file, 'utf8'));
  mutate(value); fs.writeFileSync(file, JSON.stringify(value));
};

test('valid source-linked packs pass all pinned schemas and bridge checks', () => {
  assert.deepEqual(validateRoot(), []);
});

const negative = [
  ['unknown task property', 'task-contract.json', x => { x.approved_scope_version = 1; }, /unknown approved_scope_version/],
  ['upstream local evidence status is rejected', 'evidence-pack.json', x => { x.status = 'verified'; }, /invalid enum/],
  ['upstream local evidence fields are rejected', 'evidence-pack.json', x => { x.evidence[0].kind = 'commit'; }, /unknown kind/],
  ['release authority cannot enter transport', 'evidence-pack.json', x => { x.release_authority = true; }, /unknown release_authority/],
  ['Mobile cannot become customer authority', 'control-plane-pilot.json', x => { x.authority_role = 'customer-saas-truth'; }, /Mobile authority drift/],
  ['payment authority fails closed', 'control-plane-pilot.json', x => { x.policy.payment_truth = true; }, /policy drift/],
  ['self merge fails closed', 'control-plane-pilot.json', x => { x.policy.self_merge = true; }, /policy drift/],
  ['chain cannot reorder repositories', 'control-plane-pilot.json', x => { x.authority_chain.reverse(); }, /authority chain/],
  ['pilot cannot expand allowlist', 'control-plane-pilot.json', x => { x.allowed_paths.push('lib/**'); }, /scope drift/],
  ['proposed memory cannot become authoritative', 'context-pack.json', x => { x.facts[0].validation_state = 'proposed'; }, /non-authoritative/],
  ['fact requires provenance', 'context-pack.json', x => { x.facts[0].evidence = []; }, /provenance missing/],
  ['fact cannot invent provenance', 'context-pack.json', x => { x.facts[0].evidence[0].ref = 'unverified'; }, /source not in evidence/],
  ['duplicate context identity fails', 'context-pack.json', x => { x.facts.push(x.facts[0]); }, /duplicate context/],
  ['missing context bucket fails', 'context-pack.json', x => { delete x.lessons; }, /missing lessons/],
  ['missing required authority rule fails', 'context-pack.json', x => { x.rules = []; }, /required context missing/],
  ['task and evidence identity must match', 'evidence-pack.json', x => { x.task_id = 'another-task'; }, /evidence task drift/],
  ['no release mode', 'task-contract.json', x => { x.mode = 'release'; }, /execution mode drift/],
  ['no deployment trigger', 'task-contract.json', x => { x.deployment_trigger = 'push'; }, /deployment trigger/],
  ['forbidden actions retained', 'task-contract.json', x => { x.forbidden_actions = []; }, /forbidden actions/],
  ['unknown agent fails closed', 'task-contract.json', x => { x.preferred_agents = ['unknown']; }, /unknown agent route/],
  ['product CI cannot become hosted E2E', 'evidence-pack.json', x => { x.evidence[1].type = 'e2e'; }, /type\/source refs drift/],
  ['unproven pilot pass rejected', 'evidence-pack.json', x => { x.status = 'pass'; }, /cannot self-certify/],
  ['missing activation gates rejected', 'evidence-pack.json', x => { x.remaining_gates = []; }, /activation gates drift/],
];
for (const [name, file, mutate, pattern] of negative) test(name, () => fixture(root => {
  edit(root, file, mutate);
  assert.match(validateRoot(root).join('\n'), pattern);
}));

test('missing and malformed JSON fail closed', () => fixture(root => {
  fs.writeFileSync(path.join(root, '.evento/task-contract.json'), '{');
  assert.match(validateRoot(root).join('\n'), /invalid or missing/);
  fs.unlinkSync(path.join(root, '.evento/task-contract.json'));
  assert.match(validateRoot(root).join('\n'), /invalid or missing/);
}));
test('vendored schema mutation is rejected', () => fixture(root => {
  fs.appendFileSync(path.join(root, '.evento/schemas/evento-task.schema.json'), '\n');
  assert.match(validateRoot(root).join('\n'), /schema drift/);
}));
test('missing local source and weakened agent boundaries fail', () => fixture(root => {
  fs.writeFileSync(path.join(root, 'AGENTS.md'), 'No boundaries');
  assert.match(validateRoot(root).join('\n'), /agent boundary missing/);
  fs.unlinkSync(path.join(root, 'docs/authority/ONE_MEMBER_UI_V1.md'));
  assert.match(validateRoot(root).join('\n'), /invalid or missing/);
}));
test('scope matcher rejects runtime, dependencies and existing workflow changes', () => {
  assert.deepEqual(validateChangedPaths(ALLOWED_PATHS.filter(x => !x.includes('*')).concat('.evento/context-pack.json')), []);
  assert.equal(validateChangedPaths(['lib/main_one.dart', 'test/one_member_app_test.dart',
    'pubspec.lock', 'tool/configure_android_api36.py', '.github/workflows/pr-verify.yml']).length, 5);
});
test('git diff guard catches both tracked runtime edits and untracked additions', () => fixture(root => {
  const git = args => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trim();
  git(['init', '-q']);
  git(['add', '.']);
  git(['-c', 'user.name=Pilot Test', '-c', 'user.email=pilot@example.invalid', 'commit', '-qm', 'fixture']);
  const base = git(['rev-parse', 'HEAD']);
  assert.deepEqual(validateRoot(root, { base }), []);
  fs.mkdirSync(path.join(root, 'lib'));
  fs.writeFileSync(path.join(root, 'lib/main_one.dart'), 'synthetic fixture');
  assert.match(validateRoot(root, { base }).join('\n'), /out-of-scope changed path: lib\/main_one.dart/);
  git(['add', 'lib']);
  git(['-c', 'user.name=Pilot Test', '-c', 'user.email=pilot@example.invalid', 'commit', '-qm', 'runtime fixture']);
  fs.appendFileSync(path.join(root, 'lib/main_one.dart'), '\nmodified');
  assert.match(validateRoot(root, { base }).join('\n'), /out-of-scope changed path: lib\/main_one.dart/);
}));
test('scope guard rejects non-SHA input', () => {
  assert.match(validateRoot(ROOT, { base: 'main' }).join('\n'), /exact commit SHA/);
});
