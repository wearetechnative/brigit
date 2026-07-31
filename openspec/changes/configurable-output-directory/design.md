## Context

See proposal.md — Why. Today `scan()` and `enforce()` build output paths as bare filenames (`brigit-scan-${TIMESTAMP}.log`, `repos-${TIMESTAMP}.txt`, `brigit-enforce-${TIMESTAMP}.log`), so they land in the CWD. `clean()` searches `$SCRIPT_DIR` with `find -maxdepth 1`, which only coincides with the CWD in dev mode (`./brigit`); for Nix installs `$SCRIPT_DIR` is the read-only store path.

A config-directory convention already exists from `user-config-directory-support`: `enforce()` checks `$HOME/.config/brigit/ghbranchprotection.json` before falling back to `$SCRIPT_DIR`. There is currently no general key/value config *file* — only that single JSON template.

## Goals / Non-Goals

**Goals:**
- One resolved output directory shared by `scan`, `enforce`, and `clean`.
- XDG-compliant default; overridable without editing the script.
- Report the absolute path of every file created, so output remains discoverable once it leaves the CWD.

**Non-Goals:**
- No per-run subdirectory scheme (`<dir>/<timestamp>/`) — keep flat, timestamped filenames as today.
- No change to file *formats* or *names*, only their location.
- No migration of pre-existing output files already sitting in users' CWDs.
- No rich config format (TOML/YAML). A minimal `key=value` file is sufficient.

## Decisions

**D1: Default to `${XDG_STATE_HOME:-$HOME/.local/state}/brigit/`.**
XDG designates `XDG_STATE_HOME` for "state data that should persist between application restarts but is not important enough for `$XDG_DATA_HOME`" — logs and run history are the canonical example. Chosen over:
- CWD (status quo) → the problem being fixed.
- `/tmp` → ephemeral; a branch-protection audit trail should survive a reboot. Still reachable via override for users who want it.
- `~/.config/brigit/` → XDG reserves config dirs for configuration, not output.
- `~/.cache/brigit/` → cache is explicitly discardable; these are audit artifacts.

**D2: Override precedence — flag > env > config > default.**
```
   1. -O <dir>              per-invocation, highest
   2. $BRIGIT_OUTPUT_DIR    CI / scripting
   3. output_dir=<dir>      ~/.config/brigit/config (key=value)
   4. ${XDG_STATE_HOME:-$HOME/.local/state}/brigit
```
Standard CLI layering: the most specific, most transient signal wins. The `-O` flag is only added to `scan` and `enforce` (the commands that produce output); `clean` resolves the same directory but takes no `-O` (it cleans wherever output is configured to go).

**D3: A single resolver in `_lib.sh`.**
Add `resolve_output_dir()` that applies D2 and `mkdir -p`s the result, setting a shared variable (e.g. `OUTPUT_DIR`). Both commands call it after arg parsing so `-O` is known. Centralizing keeps `scan`/`enforce`/`clean` consistent and gives `clean` the exact same target.

**D4: Config parsing stays minimal.**
Read `output_dir` from `~/.config/brigit/config` with a simple, comment-tolerant `key=value` grep/parse — no new dependency, consistent with the shell-script nature of the tool. `~` / `$HOME` in the value is expanded. Absent file or absent key → fall through to default.

**D5: Report absolute paths at end of run.**
Existing "Output written to: …" lines switch to absolute paths (the resolved dir is absolute). `scan` lists both the `.log` and, when created, the `repos-*.txt`; `enforce` lists its `.log`. A run that creates nothing beyond the log still reports the log.

## Risks / Trade-offs

- **Breaking change for existing automation** reading output from the CWD → documented as BREAKING in proposal, README, INSTALL, and CHANGELOG; the override lets anyone restore CWD-like behavior with `BRIGIT_OUTPUT_DIR=$PWD`.
- **`mkdir -p` could fail** (permissions, read-only override target) → resolver must fail with a clear error message naming the directory, rather than silently writing elsewhere.
- **Home-relative path expansion in the config value** is easy to get subtly wrong (e.g. quoted `~`) → only expand a leading `~/` and `$HOME`; document that absolute paths are safest.
- **`clean` now deletes from a user-state directory** rather than the (often empty) script dir → confirmation prompt already exists and lists files before deleting; behavior preserved.

## Migration Plan

1. Ship the resolver + rewired paths + docs together (single change).
2. No automated migration of old CWD files — they simply stop being produced there. `clean` will not touch them (it only cleans the resolved dir); users remove stragglers manually. Call this out in the CHANGELOG.
3. Rollback: revert the change; output returns to the CWD. No persistent state format is introduced that would block rollback.
