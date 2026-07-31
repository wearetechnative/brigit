# Nix Binary Naming Capability

## Purpose

Ensure that when brigit is installed via the Nix package manager, the binary presents itself as `brigit` (not `.brigit-wrapped`) in process listings, generated file names, and command invocation, while preserving all script functionality.

## Requirements

### Requirement: Binary name appears correctly in process list
When brigit is installed via Nix package manager, the binary name SHALL appear as "brigit" (not ".brigit-wrapped") in process listings such as ps, top, and htop.

#### Scenario: Check process name with ps
- **WHEN** brigit is running and user executes `ps aux | grep brigit`
- **THEN** the process name column shows "brigit"
- **THEN** the process name does NOT show ".brigit-wrapped"

#### Scenario: Check process name with top
- **WHEN** brigit is running and user views running processes in top
- **THEN** the command column shows "brigit"
- **THEN** the command does NOT show ".brigit-wrapped"

### Requirement: Log files use correct naming pattern
When brigit creates log files, they SHALL use the pattern "brigit-<command>-<timestamp>.log" regardless of how the binary is wrapped.

#### Scenario: Scan command creates log file
- **WHEN** user runs `brigit scan` after Nix installation
- **THEN** a log file is created matching pattern "brigit-scan-YYYYMMDD_HHMMSS.log"
- **THEN** the log file name does NOT contain ".brigit-wrapped"

#### Scenario: Enforce command creates log file
- **WHEN** user runs `brigit enforce` after Nix installation
- **THEN** a log file is created matching pattern "brigit-enforce-YYYYMMDD_HHMMSS.log"
- **THEN** the log file name does NOT contain ".brigit-wrapped"

### Requirement: Binary invocation remains unchanged
The command-line invocation of brigit SHALL remain "brigit" for all users, regardless of installation method.

#### Scenario: Command works as brigit
- **WHEN** user types `brigit --help` in terminal
- **THEN** the help output is displayed
- **THEN** no ".brigit-wrapped" is mentioned in the output

#### Scenario: Binary location in PATH
- **WHEN** user runs `which brigit` after Nix installation
- **THEN** the output shows a path ending in "/bin/brigit"
- **THEN** the output does NOT show ".brigit-wrapped"

### Requirement: Script functionality preserved
All existing brigit functionality SHALL work identically before and after the naming fix.

#### Scenario: Version command works
- **WHEN** user runs `brigit version` after Nix installation
- **THEN** the version number is displayed correctly
- **THEN** the VERSION file is still accessible

#### Scenario: Library loading works
- **WHEN** brigit script executes
- **THEN** _lib.sh is loaded successfully from BRIGIT_LIB_DIR
- **THEN** all library functions are available

#### Scenario: Environment variables preserved
- **WHEN** brigit wrapper executes
- **THEN** PATH includes gh, jq, gum, and bash
- **THEN** BRIGIT_LIB_DIR points to correct share directory
- **THEN** all dependencies are accessible

### Requirement: Documentation accuracy
Examples in documentation SHALL show "brigit" as the binary name, matching actual behavior.

#### Scenario: README examples match reality
- **WHEN** user follows examples in README.md
- **THEN** the command `brigit scan` works as documented
- **THEN** log files match documented naming pattern

#### Scenario: Help text matches invocation
- **WHEN** user runs `brigit --help`
- **THEN** usage examples show "brigit <command>"
- **THEN** no wrapped binary name appears in help text
