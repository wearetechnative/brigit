## Why

Several baseline specs were hand-written in a free-form style (`**FR1:**` bullet requirements, no scenario headers) that predates OpenSpec's strict schema. When a change's delta is applied during `openspec archive`, the tool rebuilds and re-validates the whole spec — and this legacy content fails strict validation ("Requirement must have at least one scenario", "Scenarios must use level-4 headers"). As a result, recent archives had to use `--no-validate`. Reformatting the affected specs to the strict format restores clean, validated archiving so the whole project passes `openspec validate --all --strict`.

## What Changes

- Rewrite the four non-conforming baseline specs into the strict OpenSpec format (`### Requirement:` blocks with SHALL/MUST wording, each followed by one or more `#### Scenario:` blocks in WHEN/THEN form):
  - `openspec/specs/scanning/spec.md` — flatten `**FRn:**`/NFR bullets into requirements.
  - `openspec/specs/enforcement/spec.md` — flatten `**FRn:**`/NFR bullets into requirements.
  - `openspec/specs/filtering/spec.md` — flatten `**FRn:**`/NFR bullets into requirements.
  - `openspec/specs/nix-binary-naming/spec.md` — add the missing title / `## Purpose` and convert the leftover `## ADDED Requirements` delta header to `## Requirements` (its requirements were already strict-format).
- Preserve **all existing requirement behavior** — this is a pure format/documentation refactor, not a behavior change. Every current FR/NFR (and the requirements appended by the archived output-location/naming changes) must be represented, none added or removed.
- No changes to the `brigit` script or to any already-conforming spec.

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
- `openspec/specs/filtering/spec.md` — reformatted to strict schema.
- `openspec/specs/nix-binary-naming/spec.md` — added Purpose/title, delta header converted.

**Sequencing (BLOCKING)**:
- Implementation happens **after PR #4 (the archiving PR) is merged**. PR #4 appends `output-location` / output-file-naming requirements to `scanning` and `enforcement`. The reformat must cover the complete post-merge specs (legacy FR1–FR6 **plus** those appended requirements). Doing this before/parallel to PR #4 would conflict on the same files and reformat incomplete specs. (`filtering` and `nix-binary-naming` are unaffected by PR #4 but carry the same legacy-format bug, so they are folded in here.)

**Risk**: Low — no runtime code touched. The only risk is dropping or altering a requirement during the rewrite; mitigated by a one-to-one mapping check (see tasks) and a strict-validation gate.
