# output-file-naming Specification

## Purpose
Defines the uniform naming grammar and extension semantics for all files brigit generates, so that output is consistent, self-grouping per run, and predictable to discover.
## Requirements
### Requirement: Uniform output file naming grammar

Every file brigit generates SHALL be named `<tool>-<command>-<timestamp>.<ext>`, where `<tool>` is the invoked binary name, `<command>` is the command that produced it, and `<timestamp>` uses the local `%Y%m%d_%H%M%S` format.

#### Scenario: Scan report follows the grammar
- **WHEN** `brigit scan` produces its report
- **THEN** the file SHALL be named `brigit-scan-<timestamp>.log`

#### Scenario: Enforce report follows the grammar
- **WHEN** `brigit enforce` produces its report
- **THEN** the file SHALL be named `brigit-enforce-<timestamp>.log`

#### Scenario: Command segment reflects the producing command
- **WHEN** any brigit command generates a file
- **THEN** the segment after the tool name SHALL be that command's name, not the file's content type

#### Scenario: Timestamp format is local and unchanged
- **WHEN** brigit generates a file
- **THEN** the timestamp SHALL be formatted as `%Y%m%d_%H%M%S` in local time with no timezone suffix

### Requirement: Extension carries the artifact type

The file extension SHALL indicate the artifact type: `.log` for a human-readable report and `.repos` for a machine-readable `org:repo` list.

#### Scenario: Reports use .log
- **WHEN** a command produces a human-readable report (table and summary)
- **THEN** the file extension SHALL be `.log`

#### Scenario: Repo lists use .repos
- **WHEN** a command produces a machine-readable `org:repo` list
- **THEN** the file extension SHALL be `.repos`
- **AND** the file SHALL be directly usable as input to `brigit enforce -f`

### Requirement: Artifacts of one run share a prefix

All files produced by a single command invocation SHALL share the `<tool>-<command>-<timestamp>` prefix, differing only by extension, so they group together when listed.

#### Scenario: A scan run's files sort adjacently
- **WHEN** a single `brigit scan` run produces both a report and a repo list
- **THEN** both files SHALL share the prefix `brigit-scan-<timestamp>`
- **AND** they SHALL differ only in their extension (`.log` vs `.repos`)

