## ADDED Requirements

### Requirement: Scan output location and reporting

`brigit scan` SHALL write its generated files to the resolved output directory (see the `output-location` capability) rather than the current working directory, and SHALL report the absolute path of each created file.

#### Scenario: Scan writes log to resolved output directory
- **WHEN** `brigit scan` produces a `brigit-scan-{timestamp}.log` file
- **THEN** the file SHALL be created in the resolved output directory
- **AND** brigit SHALL print its absolute path when the run completes

#### Scenario: Scan writes issue file to resolved output directory
- **WHEN** scanning finds repositories with issues and produces `brigit-repos-{timestamp}.txt`
- **THEN** the file SHALL be created in the resolved output directory
- **AND** brigit SHALL print its absolute path when the run completes

#### Scenario: Issue file path is usable as enforce input
- **WHEN** brigit reports the absolute path of the `brigit-repos-{timestamp}.txt` file
- **THEN** that path SHALL be directly usable as the argument to `brigit enforce -f`
