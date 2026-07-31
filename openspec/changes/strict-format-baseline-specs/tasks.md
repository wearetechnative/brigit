## 0. Precondition (BLOCKING)

- [x] 0.1 Confirm PR #4 (archive-completed-changes) is merged into `main`
- [x] 0.2 Rebase this branch on updated `main` so the appended output-location / output-file-naming requirements are present in both target specs

## 1. Inventory existing requirements

- [x] 1.1 List every `**FRn:**` and NFR in `openspec/specs/scanning/spec.md` (plus the appended output-location/naming requirement) into a FR → new-requirement checklist
- [x] 1.2 List every `**FRn:**` and NFR in `openspec/specs/enforcement/spec.md` (plus the appended requirement) into a checklist

## 2. Reformat scanning spec

- [x] 2.1 Rewrite each requirement in `openspec/specs/scanning/spec.md` as `### Requirement: <name>` with SHALL/MUST wording
- [x] 2.2 Add at least one `#### Scenario:` (WHEN/THEN, level-4 headers) per requirement, derived from the original bullet points
- [x] 2.3 Preserve or fold in the supporting prose (Data Model, API Interactions, Edge Cases, Examples) without breaking validation
- [x] 2.4 Verify no requirement from the 1.1 checklist was dropped or altered in behavior

## 3. Reformat enforcement spec

- [x] 3.1 Rewrite each requirement in `openspec/specs/enforcement/spec.md` as `### Requirement: <name>` with SHALL/MUST wording
- [x] 3.2 Add at least one `#### Scenario:` (WHEN/THEN, level-4 headers) per requirement
- [x] 3.3 Preserve or fold in the supporting prose without breaking validation
- [x] 3.4 Verify no requirement from the 1.2 checklist was dropped or altered in behavior

## 4. Reformat filtering spec

- [x] 4.1 Rewrite each `**FRn:**`/NFR in `openspec/specs/filtering/spec.md` as `### Requirement: <name>` with SHALL/MUST wording and `#### Scenario:` blocks
- [x] 4.2 Preserve the supporting prose (Data Model, Processing Flow, Edge Cases, Examples) without breaking validation
- [x] 4.3 Verify no requirement was dropped or altered in behavior

## 5. Fix nix-binary-naming spec

- [x] 5.1 Add a title and `## Purpose` section to `openspec/specs/nix-binary-naming/spec.md`
- [x] 5.2 Convert the leftover `## ADDED Requirements` delta header to `## Requirements` (requirements/scenarios already conform)

## 6. Verification

- [x] 6.1 `openspec validate scanning --strict` passes
- [x] 6.2 `openspec validate enforcement --strict` passes
- [x] 6.3 `openspec validate filtering --strict` passes
- [x] 6.4 `openspec validate nix-binary-naming --strict` passes
- [x] 6.5 `openspec validate --all --strict` passes (whole project green; future archives no longer need `--no-validate`)
- [x] 6.6 Requirement behavior preserved for every reformatted spec (no silent loss)
