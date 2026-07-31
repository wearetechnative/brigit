## Why

Brigit writes its output files (`brigit-scan-*.log`, `brigit-enforce-*.log`, `repos-*.txt`) into the current working directory, cluttering whatever directory the user happens to run it from. This also creates a latent bug: the `clean` command looks for these files in `$SCRIPT_DIR`, which for Nix installations is the read-only Nix store — so `clean` never finds files written to the CWD. A single, well-defined output location fixes both the clutter and the broken cleanup.

## What Changes

- **BREAKING**: Output files are no longer written to the current working directory. The new default location is `${XDG_STATE_HOME:-$HOME/.local/state}/brigit/`, following the XDG Base Directory specification (`XDG_STATE_HOME` is the spec-designated home for logs and state that persist between runs).
- Add an override chain so the location is configurable: CLI flag (`-O <dir>`) > environment variable (`BRIGIT_OUTPUT_DIR`) > config file (`output_dir` in `~/.config/brigit/config`) > XDG default.
- Create the output directory automatically if it does not exist.
- `scan` and `enforce` MUST print the **absolute** path of every file they created at the end of a run (currently paths are relative and, once moved out of the CWD, would be hard to find).
- Update the `clean` command to operate on the resolved output directory instead of `$SCRIPT_DIR`, fixing the latent bug.
- Update `README.md` and `INSTALL.md` documentation to describe the new location, the override mechanism, and the config setting.

## Capabilities

### New Capabilities
- `output-location`: Resolution of where brigit writes output/log/artifact files, the override precedence (flag > env > config > XDG default), directory creation, end-of-run reporting of created file paths, and `clean` targeting the resolved directory.

### Modified Capabilities
- `scanning`: FR6 (Output Generation) — scan output files are written to the resolved output directory instead of the current working directory, and their absolute paths are reported at the end of the run.
- `enforcement`: FR6 (Output Generation) — enforce output file is written to the resolved output directory instead of the current working directory, and its absolute path is reported at the end of the run.

## Impact

**Modified Files**:
- `brigit`: output path construction in `scan()` and `enforce()`; `clean()` directory target; new `-O` flag parsing; end-of-run path reporting.
- `_lib.sh`: new helper to resolve the output directory (flag/env/config/XDG default) and ensure it exists.
- `README.md`, `INSTALL.md`: document the new default location, override chain, and config setting.

**User Workflow Changes**:
- Output no longer appears in the CWD; users find reports under `~/.local/state/brigit/` by default.
- Users can point output elsewhere (e.g. `/tmp`) via `BRIGIT_OUTPUT_DIR`, `-O`, or the config file.
- Any automation that reads `brigit-scan-*.log` / `repos-*.txt` from the CWD must be updated (breaking change).

**Dependencies**: None new. Relies on existing `~/.config/brigit/` convention introduced by `user-config-directory-support`.
