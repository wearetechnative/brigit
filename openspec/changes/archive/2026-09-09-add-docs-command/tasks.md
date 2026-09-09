## 1. Implement the docs command

- [x] 1.1 Register the command with `make_command "docs" "Show the README documentation"` in `brigit`, placed alongside the other command registrations (e.g. next to `version`)
- [x] 1.2 Implement `docs()` reading `$SCRIPT_DIR/README.md`: when `$INTERACTIVE`, render with `gum format` piped through `gum pager`; otherwise `cat` the file verbatim
- [x] 1.3 Add the missing-file guard: if `$SCRIPT_DIR/README.md` does not exist, write an error to stderr and `return 1`

## 2. Package the README

- [x] 2.1 In `package.nix` `installPhase`, add `cp README.md $out/share/brigit/README.md` so Nix installs ship the documentation

## 3. Documentation

- [x] 3.1 Add a `brigit docs` line under the `## Usage` section of `README.md`
- [x] 3.2 Add a `### Added` entry for the `docs` command under the Unreleased/NEXT VERSION section of `CHANGELOG.md`

## 4. Verify

- [x] 4.1 Dev mode: `./brigit docs` renders the README in a pager; `./brigit docs | cat` emits raw README text with no escape codes; `brigit` (no args) lists `docs`
- [x] 4.2 Missing-file: temporarily rename README, confirm `docs` errors to stderr and exits non-zero
- [x] 4.3 Nix build: `nix build` succeeds and `README.md` is present in the built `share/brigit/` output; the installed `brigit docs` displays the docs
