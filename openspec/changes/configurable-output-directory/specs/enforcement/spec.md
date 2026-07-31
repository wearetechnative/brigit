## ADDED Requirements

### Requirement: Enforce output location and reporting

`brigit enforce` SHALL write its generated log file to the resolved output directory (see the `output-location` capability) rather than the current working directory, and SHALL report the absolute path of the created file.

#### Scenario: Enforce writes log to resolved output directory
- **WHEN** `brigit enforce` produces a `brigit-enforce-{timestamp}.log` file
- **THEN** the file SHALL be created in the resolved output directory
- **AND** brigit SHALL print its absolute path when the run completes
