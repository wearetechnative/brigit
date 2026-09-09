## Why

Users who install brigit via Nix (`nix run` / `nix profile install`) have no
convenient way to read the project documentation from the terminal — the README
lives in the git repository, not alongside the installed binary. A built-in
`brigit docs` command lets any user, regardless of install method, view the full
documentation without leaving the shell or hunting through the Nix store.

## What Changes

- Add a new `docs` subcommand that prints the contents of `README.md`.
- Render the markdown with `gum format` and page it through `gum pager` when
  running interactively (TTY); fall back to plain `cat` when output is piped so
  the command stays composable and dependency-free in pipelines.
- Guard against a missing `README.md`: print an error to stderr and exit `1`.
- Ship `README.md` inside the Nix package so the installed binary can find it
  (it is currently not copied into `$out/share/brigit/`).
- Document the new command in the README `## Usage` section.

## Capabilities

### New Capabilities
- `documentation-command`: A `docs` subcommand that displays the bundled README
  documentation, rendered for interactive terminals and plain for pipes, and
  packaged so it is available from every install method.

### Modified Capabilities
<!-- None. No existing spec-level behavior changes. -->

## Impact

- `brigit` — new `make_command "docs"` registration and `docs()` function.
- `package.nix` — `installPhase` copies `README.md` into `$out/share/brigit/`.
- `README.md` — new `brigit docs` entry under `## Usage`.
- `CHANGELOG.md` — new `### Added` entry.
- Dependencies — none added; `gum` is already a required dependency.
