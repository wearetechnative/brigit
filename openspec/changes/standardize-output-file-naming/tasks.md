## 1. Rename the scan issue list (`brigit`)

- [x] 1.1 In `scan()`, change `REPOS_OUTPUT_FILE` to `${OUTPUT_DIR}/${SCRIPT_NAME}-scan-${TIMESTAMP}.repos`
- [x] 1.2 Confirm the end-of-run reporting prints the new `.repos` path (it references `$REPOS_OUTPUT_FILE`, so no separate change needed — verify)

## 2. Update cleanup (`brigit`)

- [x] 2.1 In `clean()`, change the issue-list `find` glob from `${script_name}-repos-*.txt` to `${script_name}-scan-*.repos`
- [x] 2.2 Verify the `${script_name}-*.log` glob still covers both scan and enforce reports

## 3. Update ignore rules and docs

- [x] 3.1 `.gitignore`: replace `brigit-repos-*.txt` with `brigit-scan-*.repos`
- [x] 3.2 README.md "Output Files" table: rename the issue-list entry to `brigit-scan-yyyymmdd_hhmmss.repos` and note the extension semantics (`.log` report, `.repos` repo list)
- [x] 3.3 README.md examples: update `enforce -f` paths that reference the old issue-list name
- [x] 3.4 CHANGELOG.md: add an entry under `[Unreleased]` documenting the BREAKING rename to `brigit-scan-<timestamp>.repos` and the closed naming grammar

## 4. Align OpenSpec specs

- [x] 4.1 Update filename references in `openspec/specs/scanning/spec.md` (FR6, data model, related capabilities) to `brigit-scan-<timestamp>.repos`
- [x] 4.2 Update filename references in `openspec/specs/enforcement/spec.md` examples/workflow to the new name
- [x] 4.3 Update `openspec/PROJECT.md` issue-list reference

## 5. Verification

- [x] 5.1 `bash -n brigit` passes
- [x] 5.2 Simulate a scan output dir with `brigit-scan-<ts>.log` + `brigit-scan-<ts>.repos`; run `brigit clean` and confirm both are listed and removed
- [x] 5.3 Confirm `ls brigit-scan-*` groups a run's report and repo list adjacently
- [x] 5.4 `openspec validate standardize-output-file-naming --strict` passes
