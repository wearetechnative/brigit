## Context

See proposal.md — Why. `brigit` is a single Bash script that registers each
subcommand via `make_command "<name>" "<desc>"` followed by a same-named
function; dispatch is `eval "$ARG1" "$ARGREST"` (`brigit:102-103`). The nearest
existing pattern is `version()` (`brigit:121-133`), which reads a bundled file
from `$SCRIPT_DIR` with a fallback. `$SCRIPT_DIR` resolves to the repo root in
dev mode (`./brigit`) and to `$out/share/brigit/` on a Nix install (via
`BRIGIT_LIB_DIR`, `brigit:31-33`). Interactive-vs-plain rendering already has a
precedent: `usage()` branches on `$INTERACTIVE` (`brigit:66-70`), and `gum` is
already a required dependency. `package.nix` copies a fixed set of files into
`$out/share/brigit/` — `README.md` is not currently among them.

## Goals / Non-Goals

**Goals:**
- A `docs` subcommand that reads and displays `$SCRIPT_DIR/README.md`.
- Readable rendering in a terminal; verbatim, pipe-safe output otherwise.
- Works identically for a git checkout and a Nix install.

**Non-Goals:**
- Converting the README to any other format or hosting/serving it.
- Rendering docs other than `README.md` (e.g. INSTALL.md) — out of scope here.
- Adding new runtime dependencies.

## Decisions

- **Follow the `version()` pattern.** Register with `make_command "docs" "Show
  the README documentation"` and define `docs()` reading `$SCRIPT_DIR/README.md`.
  This reuses the established path-resolution that already works across dev and
  Nix installs, rather than introducing a new mechanism.

- **Branch on `$INTERACTIVE`, mirroring `usage()`.** When interactive, render
  with `gum format` and page through `gum pager` (README is ~550 lines, so an
  unpaged dump is unwieldy). When non-interactive, `cat` the file verbatim so the
  output composes cleanly in pipes and carries no terminal escape codes.
  Alternative considered: always `gum format` — rejected because it injects ANSI
  formatting into piped output and offers no scrollback. Alternative: add
  `glow`/`mdcat` — rejected as a new dependency when `gum` already suffices.

- **Guard a missing file explicitly.** If `README.md` is absent, write an error
  to stderr and `return 1`. `version()` degrades to `"unknown"`, but an empty or
  silent docs command is misleading, so a hard error is the better contract here.

- **Package the README.** Add `cp README.md $out/share/brigit/README.md` to the
  `installPhase` in `package.nix`. Without this the command works in dev but
  fails for every Nix user — the single highest-risk omission in this change.

## Risks / Trade-offs

- **Forgetting the Nix copy** → command silently unavailable on installed
  builds. Mitigation: spec requirement + task explicitly covering the packaged
  case, and it is called out as the primary risk here.
- **`gum pager` behavior in edge terminals** → detection already flows through
  the existing `$INTERACTIVE` check, so the non-interactive path (plain `cat`)
  is the safe default whenever no TTY is present.
