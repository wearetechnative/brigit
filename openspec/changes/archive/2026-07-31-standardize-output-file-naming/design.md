## Context

See proposal.md — Why. Current generation points in `brigit`:
- `scan()`: `${OUTPUT_DIR}/${SCRIPT_NAME}-scan-${TIMESTAMP}.log` and `${OUTPUT_DIR}/${SCRIPT_NAME}-repos-${TIMESTAMP}.txt`
- `enforce()`: `${OUTPUT_DIR}/${SCRIPT_NAME}-enforce-${TIMESTAMP}.log`
- `clean()`: globs `${script_name}-*.log` and `${script_name}-repos-*.txt`

`SCRIPT_NAME`/`script_name` is `basename "$0"` (normally `brigit`, follows a renamed binary). `TIMESTAMP` comes from `generate_timestamp()` = `date +"%Y%m%d_%H%M%S"`. The naming exploration settled on Option A (name by command, extension carries meaning) with a local timestamp.

## Goals / Non-Goals

**Goals:**
- One closed grammar: `<tool>-<command>-<timestamp>.<ext>`, where `<tool>` = `SCRIPT_NAME`.
- Both scan artifacts share the `brigit-scan-<timestamp>` prefix.
- Extension is the sole differentiator between report and data.

**Non-Goals:**
- No change to the timestamp format, timezone, or position (stays a local `%Y%m%d_%H%M%S` suffix).
- No change to file *contents* or the `enforce -f` input contract.
- No per-run subdirectory scheme.
- No renaming of input/config files (`repos.txt`, `repos-ignore.txt`, `ghbranchprotection.json`).

## Decisions

**D1: Middle segment is always the command.**
The scan issue list becomes `brigit-scan-<ts>.repos` (was `brigit-repos-<ts>.txt`). Both scan outputs now share `brigit-scan-<ts>` and sort adjacently; `ls brigit-scan-*` shows a full run. Chosen over content-based names (`brigit-report`/`brigit-issues`) because it yields the shortest, fully uniform grammar and leans on the extension for the report-vs-data distinction.

**D2: `.repos` extension for the repo list.**
Self-documenting ("a list of repos"), collision-free, and greppable. Rejected alternatives:
- `.txt` — generic, collides with everything, says nothing about content.
- `.repo` — collides with YUM/DNF repository config (INI); editors/tooling mis-associate it.
- `.lst` — generic "list", weaker grep uniqueness, relies on the `scan` segment for meaning.
`.log` is retained for both reports (conventional for run output).

**D3: Keep the local timestamp unchanged.**
`%Y%m%d_%H%M%S` still sorts lexicographically = chronologically. UTC/ISO-8601 was considered and explicitly declined for readability of local audit runs.

**D4: Simplify the `clean` globs.**
With the closed grammar, `clean` can match `${script_name}-scan-*.repos` for the issue list (and the existing `${script_name}-*.log` for reports). The `${script_name}-*.log` glob already covers both scan and enforce logs. No file outside the grammar remains, so the globs fully describe brigit's output.

## Risks / Trade-offs

- **Third rename of the issue list** (`repos-*` → `brigit-repos-*` → `brigit-scan-*.repos`) → mitigated by making this the *final* form (grammar is now closed) and by superseding PR #2 rather than stacking on it.
- **`.repos` has no default OS handler** → it opens as plain text everywhere, same as the old `.txt`; no practical downside, and better than `.repo` which would open as INI.
- **Breaking for consumers of the old name** → documented BREAKING in proposal, README, and CHANGELOG; the file format is unchanged so only the path/name needs updating.
- **`clean` won't remove pre-existing old-named files** (`*-repos-*.txt`, `repos-*.txt`) → note in CHANGELOG that legacy files must be removed manually; going forward all output matches the new grammar.

## Migration Plan

1. Land this as a single change; close/supersede PR #2 (`feat/prefix-repos-file`) so only one rename reaches `main`.
2. No automated migration of previously generated files — they simply stop being produced under the old name.
3. Rollback: revert the change; the previous naming returns. No persisted state blocks rollback.
