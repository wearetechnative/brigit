## Context

See proposal.md — Why. The two target specs currently use `## Requirements` → `### Functional Requirements` → `**FR1: ...**` bullet lists, plus free-form Data Model / API / Edge Case sections, and no `#### Scenario:` blocks. OpenSpec's strict validator (used when rebuilding a spec during archive) requires: every requirement as `### Requirement: <name>` and at least one `#### Scenario:` per requirement using WHEN/THEN. After PR #4 merges, each file also contains one appended strict-format requirement (from the archived output-location / output-file-naming changes) that already conforms.

## Goals / Non-Goals

**Goals:**
- Both specs pass `openspec validate --strict` and rebuild cleanly during future archives (no `--no-validate`).
- Behavior is preserved one-to-one: every existing FR/NFR maps to a strict requirement.

**Non-Goals:**
- No behavior change, no new/removed requirements.
- No reformatting of other specs (`filtering`, `configuration`, `reporting`, `nix-binary-naming`, etc.) — only the two that block archiving.
- Not deleting the auxiliary prose (Data Model, API Interactions, Edge Cases, Examples) if it stays valid — it can remain as supporting sections as long as it doesn't break validation.

## Decisions

**D1: Map each `**FRn:**` to one `### Requirement:` with scenarios.**
Group the FR's bullet points into WHEN/THEN scenarios. NFRs become requirements too (e.g. "Read-only operation", "CI/CD non-interactive support"). This keeps the requirement set traceable to the original.

**D2: `skip_specs: true`; edit the baseline specs directly.**
There is no spec-level *behavior* change, so no delta spec is written. The reformat edits `openspec/specs/*/spec.md` in place. This avoids the impossible MODIFIED-delta match (the legacy file has no `### Requirement:` headers to match against) and correctly models the change as a format/tooling refactor.

**D3: Preserve supporting prose as non-requirement sections.**
Keep Data Model / API Interactions / Edge Cases / Examples as descriptive sections after the requirements, provided the validator tolerates them. If any section trips validation, fold its content into requirement/scenario text or drop it.

**D4: Validate against the post-PR-#4 file.**
Rebase this branch on `main` after PR #4 merges so the appended output-location/naming requirement is present, then reformat the complete file.

## Risks / Trade-offs

- **Dropping a requirement in translation** → Mitigation: build an explicit FR/NFR → new-requirement checklist in tasks and diff the requirement count before/after.
- **Validator rejects auxiliary prose sections** → Mitigation: if `--strict` complains, move the prose into scenario text or remove it; requirements + scenarios are the must-pass core.
- **Merge conflict with PR #4** → Mitigation: sequencing gate (implement only after PR #4 merges; rebase first).

## Migration Plan

1. Wait for PR #4 to merge; rebase this branch on updated `main`.
2. Reformat `scanning`, then `enforcement`.
3. Gate on `openspec validate --strict` for both specs (and a dry-run archive that no longer needs `--no-validate`).
4. Rollback: revert the two file edits; specs return to the legacy format. No code or behavior affected.
