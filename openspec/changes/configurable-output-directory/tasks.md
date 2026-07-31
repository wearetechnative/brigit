## 1. Output directory resolver (`_lib.sh`)

- [x] 1.1 Add `resolve_output_dir()` implementing precedence: `-O` value (passed in) > `$BRIGIT_OUTPUT_DIR` > `output_dir` from `~/.config/brigit/config` > `${XDG_STATE_HOME:-$HOME/.local/state}/brigit`
- [x] 1.2 Parse `output_dir` from `~/.config/brigit/config` as a comment-tolerant `key=value` line; expand a leading `~/` or `$HOME` in the value
- [x] 1.3 `mkdir -p` the resolved directory; abort with a clear error naming the directory if creation fails
- [x] 1.4 Set the resolved path into a shared variable (e.g. `OUTPUT_DIR`) as an absolute path

## 2. Wire `scan` to the resolved directory (`brigit`)

- [x] 2.1 Add `-O <dir>` to `scan` getopts and help text
- [x] 2.2 Call `resolve_output_dir` after arg parsing, passing the `-O` value
- [x] 2.3 Build `OUTPUT_FILE` and `REPOS_OUTPUT_FILE` under `$OUTPUT_DIR` (absolute paths)
- [x] 2.4 Change end-of-run reporting to print absolute paths of the log and (when created) the `brigit-repos-*.txt`

## 3. Wire `enforce` to the resolved directory (`brigit`)

- [x] 3.1 Add `-O <dir>` to `enforce` getopts and help text
- [x] 3.2 Call `resolve_output_dir` after arg parsing, passing the `-O` value
- [x] 3.3 Build `OUTPUT_FILE` under `$OUTPUT_DIR` (absolute path)
- [x] 3.4 Change end-of-run reporting to print the absolute path of the log

## 4. Fix `clean` (`brigit`)

- [x] 4.1 Resolve the output directory in `clean` (same resolver, no `-O`)
- [x] 4.2 Change the `find` calls to search the resolved output directory instead of `$SCRIPT_DIR`
- [x] 4.3 Verify the confirmation prompt still lists files before deletion

## 5. Documentation

- [x] 5.1 Update README.md "Output Files" section: new default location, override precedence (`-O` > `BRIGIT_OUTPUT_DIR` > config > XDG default), and the `output_dir` config setting
- [x] 5.2 Update README examples that reference `brigit-repos-*.txt` / `brigit-scan-*.log` in the CWD to reflect the new location
- [x] 5.3 Update INSTALL.md if it references output/log file locations
- [x] 5.4 Add a CHANGELOG entry under "## NEXT VERSION" noting the BREAKING location change, the override chain, and the `clean` fix

## 6. Verification

- [x] 6.1 Run `brigit scan` with defaults; confirm files land in `~/.local/state/brigit/` and absolute paths are printed
- [x] 6.2 Verify each override level (`-O`, `BRIGIT_OUTPUT_DIR`, config `output_dir`) takes effect in precedence order, including `/tmp`
- [x] 6.3 Run `brigit clean` and confirm it finds and removes files from the resolved output directory
- [x] 6.4 Run `openspec validate configurable-output-directory --strict` and resolve any issues
