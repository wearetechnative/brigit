## Why

The baseline specs `openspec/specs/scanning/spec.md` and `openspec/specs/enforcement/spec.md` were hand-written in a free-form style (`**FR1:**` bullet requirements, no scenario headers) that predates OpenSpec's strict schema. When a change's delta is applied during `openspec archive`, the tool rebuilds and re-validates the whole spec — and this legacy content fails strict validation ("Requirement must have at least one scenario", "Scenarios must use level-4 headers"). As a result, the last two archives had to use `--no-validate`. Reformatting these two specs to the strict format restores clean, validated archiving.

## What Changes

- Rewrite `openspec/specs/scanning/spec.md` and `openspec/specs/enforcement/spec.md` into the strict OpenSpec format: `### Requirement:` blocks with SHALL/MUST wording, each followed by one or more `#### Scenario:` blocks in WHEN/THEN form.
- Preserve **all existing requirement behavior** — this is a pure format/documentation refactor, not a behavior change. Every current FR/NFR and the requirements appended by the archived output-location/naming changes must be represented, none added or removed.
- No changes to the `brigit` script or any other capability spec.

## Capabilities

### New Capabilities
<!-- None — no new behavior. -->

### Modified Capabilities
<!-- None — requirement behavior is unchanged; only the spec file format changes.
     This change sets skip_specs: true in .openspec.yaml (pure format refactor,
     no spec-level behavior change). The reformatted baseline specs are edited
     directly, not via delta specs. -->

## Impact

**Modified Files**:
- `openspec/specs/scanning/spec.md` — reformatted to strict schema.
- `openspec/specs/enforcement/spec.md` — reformatted to strict schema.

**Sequencing (BLOCKING)**:
- Implementation MUST happen **after PR #4 (the archiving PR) is merged**. PR #4 appends `output-location` / output-file-naming requirements to both of these files. The reformat must cover the complete post-merge spec (legacy FR1–FR6 **plus** those appended requirements). Doing this before/parallel to PR #4 would conflict on the same files and reformat an incomplete spec.

**Risk**: Low — no runtime code touched. The only risk is dropping or altering a requirement during the rewrite; mitigated by a one-to-one mapping check (see tasks) and a strict-validation gate.
