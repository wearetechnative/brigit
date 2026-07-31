## ADDED Requirements

### Requirement: Scan issue list naming

The scan issue list SHALL be named `brigit-scan-<timestamp>.repos`, sharing the scan report's prefix and using the `.repos` extension for the machine-readable `org:repo` list.

#### Scenario: Scan produces a .repos issue list
- **WHEN** `brigit scan` finds repositories with issues
- **THEN** the issue list SHALL be written as `brigit-scan-<timestamp>.repos` in the resolved output directory
- **AND** it SHALL share the `brigit-scan-<timestamp>` prefix with the scan report `brigit-scan-<timestamp>.log`

#### Scenario: Issue list remains valid enforce input
- **WHEN** brigit reports the path of the `brigit-scan-<timestamp>.repos` file
- **THEN** that path SHALL be directly usable as the argument to `brigit enforce -f`

#### Scenario: Cleanup recognizes the .repos issue list
- **WHEN** `brigit clean` runs
- **THEN** it SHALL include `brigit-scan-*.repos` files as candidates for deletion
