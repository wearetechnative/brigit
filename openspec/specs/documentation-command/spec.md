# documentation-command Specification

## Purpose
Provide a `docs` subcommand that displays brigit's bundled README documentation
from the terminal, so users can read the full docs regardless of how brigit was
installed, without leaving the shell.
## Requirements
### Requirement: docs command displays the README
The `docs` subcommand SHALL display the contents of the bundled `README.md`
documentation file to the user.

#### Scenario: docs command is registered
- **WHEN** the user runs `brigit` with no arguments (or `brigit usage`)
- **THEN** the command list includes `docs` with a short description

#### Scenario: README contents are shown
- **WHEN** the user runs `brigit docs` and `README.md` is present
- **THEN** the full documentation text from `README.md` is displayed
- **THEN** the command exits with status `0`

### Requirement: Rendering adapts to the output context
The `docs` subcommand SHALL render the documentation for readability when
attached to an interactive terminal, and SHALL emit plain, unmodified text when
its output is not a terminal, so the command remains usable in pipelines.

#### Scenario: Interactive terminal
- **WHEN** the user runs `brigit docs` from an interactive terminal
- **THEN** the markdown is rendered for readability and presented in a scrollable pager

#### Scenario: Output is piped
- **WHEN** the user runs `brigit docs | cat` (output is not a terminal)
- **THEN** the raw `README.md` text is emitted verbatim
- **THEN** no interactive pager or terminal-only formatting is invoked

### Requirement: Missing documentation is handled gracefully
When the bundled `README.md` cannot be found, the `docs` subcommand SHALL report
an error to standard error and exit with a non-zero status, rather than printing
empty or misleading output.

#### Scenario: README file is absent
- **WHEN** the user runs `brigit docs` and `README.md` does not exist at the resolved location
- **THEN** an error message is written to standard error
- **THEN** the command exits with a non-zero status

### Requirement: Documentation is available from every install method
The `README.md` file SHALL be packaged alongside the installed binary so that
`brigit docs` works identically for a local git checkout and for a Nix
installation.

#### Scenario: Nix installation includes the README
- **WHEN** brigit is built and installed via the Nix package
- **THEN** `README.md` is present in the installed share directory
- **THEN** running `brigit docs` displays the documentation

