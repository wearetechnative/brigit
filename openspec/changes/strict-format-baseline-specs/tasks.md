## 0. Precondition (BLOCKING)

- [ ] 0.1 Confirm PR #4 (archive-completed-changes) is merged into `main`
- [ ] 0.2 Rebase this branch on updated `main` so the appended output-location / output-file-naming requirements are present in both target specs

## 1. Inventory existing requirements

- [ ] 1.1 List every `**FRn:**` and NFR in `openspec/specs/scanning/spec.md` (plus the appended output-location/naming requirement) into a FR → new-requirement checklist
- [ ] 1.2 List every `**FRn:**` and NFR in `openspec/specs/enforcement/spec.md` (plus the appended requirement) into a checklist

## 2. Reformat scanning spec

- [ ] 2.1 Rewrite each requirement in `openspec/specs/scanning/spec.md` as `### Requirement: <name>` with SHALL/MUST wording
- [ ] 2.2 Add at least one `#### Scenario:` (WHEN/THEN, level-4 headers) per requirement, derived from the original bullet points
- [ ] 2.3 Preserve or fold in the supporting prose (Data Model, API Interactions, Edge Cases, Examples) without breaking validation
- [ ] 2.4 Verify no requirement from the 1.1 checklist was dropped or altered in behavior

## 3. Reformat enforcement spec

- [ ] 3.1 Rewrite each requirement in `openspec/specs/enforcement/spec.md` as `### Requirement: <name>` with SHALL/MUST wording
- [ ] 3.2 Add at least one `#### Scenario:` (WHEN/THEN, level-4 headers) per requirement
- [ ] 3.3 Preserve or fold in the supporting prose without breaking validation
- [ ] 3.4 Verify no requirement from the 1.2 checklist was dropped or altered in behavior

## 4. Verification

- [ ] 4.1 `openspec validate scanning --strict` passes (or the equivalent spec-level validate)
- [ ] 4.2 `openspec validate enforcement --strict` passes
- [ ] 4.3 Dry-run confirm: a future archive touching these specs no longer requires `--no-validate`
- [ ] 4.4 Requirement counts before/after match for both specs (no silent loss)
