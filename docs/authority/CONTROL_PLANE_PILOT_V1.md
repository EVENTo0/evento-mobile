# Mobile control-plane pilot v1

Metadata/verification bridge for the third Phase B repository. This PR changes
no runtime, provider, database, dependency, signing or release configuration.

## Source comparison

| Source | Inspected revision | Reused contract | Local difference |
| --- | --- | --- | --- |
| Website | `e66a0513926c0bec00f79081f08ffea9ff9dc31d` | AGENTS + pilot manifest + Context/Task/Evidence packs + default-deny CI | Its packs use local extensions, including `kind/claim` and `baseline-verified` |
| ONE | `e6d2e6a91ced6eb06ae0c5a276652496c4778954` | Project authority + task/evidence + memory promotion policy | Its local evidence uses `verified`, `merge` and release booleans |
| Empire | `32437dec9ff2cf47a33b9ca1073415026110d116` | Context, memory, task and evidence JSON schemas | Transport packs reject additional properties; Evidence status is pass/fail/blocked/partial |

Mobile preserves the source-linked bridge but places local policy/extensions in
the pilot manifest rather than incompatible transport fields. Central schemas
are copied under `.evento/schemas` with only final-newline normalization, pinned
by SHA-256 in the validator;
their original repository paths and revision are in the manifest. The offline
checker covers every assertion keyword used by these four schemas and rejects
unknown keywords. It is a bounded checker for these pinned schemas, not a general
JSON Schema implementation. No package installation or network is required.

## Authority and evidence

Website → ONE → Mobile is an ownership chain, not copied application code.
Website owns acquisition/lead truth; ONE owns customer/SaaS/billing truth; Mobile
consumes versioned ONE APIs. No Mobile customer ledger or payment truth is added.

Current inspected main is `8c378d29b15bc25465a9b993879e00f997d8ce55`:
PR #11 merged at `9f4bb3255f5fae754efb5d72f0f9622515bcd92c`, followed only by
the RC6 build-status bot update. Successful run `37298902955` belongs to PR #11
head `b9b12d6d69c3235471c83cfbd87155dc7f4ec006`, not this pilot. The new
`ONE_MEMBER_UI_V1.md` describes the merged member entry and takes precedence over
older pending-adoption statements. Legacy entries remain separate.

Upstream pilot success references supplied for comparison are Website push
`37270189977` and ONE `37294262026` / `37294262157`; the copied packs are pinned to
the merged source revisions, not their historical pre-merge objective summaries.

The checked-in Evidence Pack is **partial**: it records inspected baseline source
and existing product CI, never self-certifies this new PR. Final pilot run/head
and independent review belong in the PR handoff. Keep hosted Mobile→ONE Auth and
tenant testing, physical-device AR/EN/lifecycle/logout, signing and release
approval open. Stripe remains deferred. No end-to-end product completion claim.

## Verification and rollback

```sh
node scripts/validate-evento-control-plane-pilot.mjs
node scripts/test-evento-control-plane-pilot.mjs
node scripts/validate-evento-control-plane-pilot.mjs --base 8c378d29b15bc25465a9b993879e00f997d8ce55
```

The PR gate checks the exact PR head with read-only permissions and no secrets,
uses SHA-pinned actions from the merged Website pilot, and verifies the diff
against the PR base. Positive validation checks schema/identity/provenance,
memory state, authority chain, default-deny policy and retained activation gates.
Negative regressions mutate isolated temporary fixtures, including schema drift,
unproven facts, authority escalation and runtime path violations.

Scope is the manifest allowlist only; existing Flutter/API36 verification remains
unchanged. This gate does not build, sign, configure or publish an APK. Its CI log
prints the tested source SHA. Rollback: revert the pilot commit only. No database
or runtime rollback is required. Phase B adoption remains pending review/merge;
the wider rollout registry is intentionally not changed in another repository.
