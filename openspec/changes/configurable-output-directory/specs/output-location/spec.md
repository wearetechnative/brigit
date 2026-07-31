## Purpose

Defines where brigit writes its output, log, and artifact files, how that location can be overridden, and how created files are reported back to the user so they remain discoverable outside the current working directory.

## ADDED Requirements

### Requirement: XDG-compliant default output directory

Brigit SHALL write all generated output files to a dedicated output directory that defaults to an XDG Base Directory `state` location, NOT the current working directory.

#### Scenario: Default location when no override is set
- **WHEN** brigit runs a command that produces output and no override is configured
- **THEN** output files SHALL be written to `${XDG_STATE_HOME}/brigit/` when `XDG_STATE_HOME` is set
- **AND** output files SHALL be written to `$HOME/.local/state/brigit/` when `XDG_STATE_HOME` is unset

#### Scenario: Output directory is created if missing
- **WHEN** the resolved output directory does not exist
- **THEN** brigit SHALL create it (including parent directories) before writing
- **AND** brigit SHALL abort with a clear error naming the directory if it cannot be created

#### Scenario: Output no longer written to the working directory
- **WHEN** brigit is run from an arbitrary working directory with default settings
- **THEN** no output files SHALL be created in that working directory

### Requirement: Configurable output directory with defined precedence

Brigit SHALL allow the output directory to be overridden, resolving the location using a fixed precedence: command-line flag, then environment variable, then config file, then the XDG default.

#### Scenario: Command-line flag has highest precedence
- **WHEN** a command is run with `-O <dir>`
- **THEN** brigit SHALL write output to `<dir>` regardless of environment variable or config file settings

#### Scenario: Environment variable overrides config and default
- **WHEN** `BRIGIT_OUTPUT_DIR` is set and no `-O` flag is given
- **THEN** brigit SHALL write output to the directory named by `BRIGIT_OUTPUT_DIR`

#### Scenario: Config file overrides the default
- **WHEN** no flag and no environment variable are set
- **AND** `~/.config/brigit/config` contains an `output_dir` setting
- **THEN** brigit SHALL write output to the directory named by that setting
- **AND** a leading `~/` or `$HOME` in the value SHALL be expanded to the user's home directory

#### Scenario: Override to an ephemeral location
- **WHEN** the user sets the output directory to `/tmp` via any override mechanism
- **THEN** brigit SHALL write output there

### Requirement: Created files are reported with absolute paths

At the end of a command that produces output, brigit SHALL report the absolute path of every file it created so the user can locate output that no longer resides in the working directory.

#### Scenario: Scan reports created files
- **WHEN** `brigit scan` completes and writes a log file
- **THEN** brigit SHALL print the absolute path of the log file
- **AND** SHALL print the absolute path of the `brigit-repos-*.txt` file when one was created

#### Scenario: Enforce reports created file
- **WHEN** `brigit enforce` completes and writes a log file
- **THEN** brigit SHALL print the absolute path of the log file

### Requirement: Cleanup targets the resolved output directory

The `clean` command SHALL remove brigit-generated files from the same resolved output directory that `scan` and `enforce` write to, not from the script installation directory.

#### Scenario: Clean finds files in the resolved output directory
- **WHEN** output files exist in the resolved output directory
- **AND** the user runs `brigit clean`
- **THEN** brigit SHALL list those log and `brigit-repos-*.txt` files as candidates for deletion
- **AND** SHALL delete them after confirmation

#### Scenario: Clean works for Nix installations
- **WHEN** brigit is installed via Nix (read-only script directory)
- **AND** output files exist in the resolved output directory
- **THEN** `brigit clean` SHALL find and delete those files
