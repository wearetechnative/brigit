## Why

Brigit's generated files follow two different naming grammars: the log files are named after the **command** (`brigit-scan-*.log`, `brigit-enforce-*.log`), but the scan issue list is named after its **content** (`brigit-repos-*.txt`). As a result, the two artifacts produced by a single `scan` run don't share a prefix, and an `ls` interleaves unrelated runs. Standardizing on one grammar makes the output uniform, self-grouping per run, and predictable to grep — DevOps naming best practice.

## What Changes

- Adopt a single, closed naming grammar for all generated files: `brigit-<command>-<timestamp>.<ext>`.
- **BREAKING**: Rename the scan issue list from `brigit-repos-<timestamp>.txt` to `brigit-scan-<timestamp>.repos`. It now shares the `brigit-scan-<timestamp>` prefix with the scan log, differing only by extension.
- Define extension semantics: `.log` = human-readable report (scan and enforce), `.repos` = machine-readable `org:repo` list (scan only, consumed by `enforce -f`).
- Keep the existing local timestamp format `%Y%m%d_%H%M%S` unchanged (no UTC / timezone suffix).
- Update the `clean` glob, `.gitignore`, `README.md`, `CHANGELOG.md`, and OpenSpec specs to match.

## Capabilities

### New Capabilities
- `output-file-naming`: The uniform naming grammar for generated files (`brigit-<command>-<timestamp>.<ext>`), the extension semantics (`.log` report, `.repos` repo list), and the run-grouping property (one run shares one `brigit-<command>-<timestamp>` prefix).

### Modified Capabilities
- `scanning`: The scan issue list is renamed from `brigit-repos-<timestamp>.txt` to `brigit-scan-<timestamp>.repos`.

## Impact

**Modified Files**:
- `brigit`: `REPOS_OUTPUT_FILE` construction in `scan()`; `clean()` glob for the issue list.
- `.gitignore`: `brigit-repos-*.txt` → `brigit-scan-*.repos`.
- `README.md`, `CHANGELOG.md`: filename references, output table, examples.
- OpenSpec specs: filename references in `scanning`, `enforcement`, `output-location`.

**Relationship to pending work**:
- This **supersedes the still-open PR #2** (`feat/prefix-repos-file`, "Prefix scan issue file with the binary name"), which renamed the issue list to `brigit-repos-<timestamp>.txt`. That intermediate name is subsumed here. Recommended path: close PR #2 and land this as the single, final naming change instead of stacking a second rename on top.

**User Workflow Changes**:
- The scan issue file is now `brigit-scan-<timestamp>.repos`; anything referencing the old `.txt` / `brigit-repos-` name must be updated.
- `brigit enforce -f <file>` still consumes the file; only its name/extension changed.

**Dependencies**: None new. Builds on the output-directory behavior from `configurable-output-directory`.
