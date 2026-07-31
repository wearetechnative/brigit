# Repository Scanning Capability

## Purpose

Scan GitHub repositories to check compliance with branch protection rules. Provides read-only auditing of current protection state without making any changes.

## Requirements

### Requirement: Organization-wide scanning

The tool SHALL support scanning all repositories in a GitHub organization, using the GitHub API to list them, handling pagination for large organizations, and respecting API rate limits.

#### Scenario: Scan every repository in an organization
- **WHEN** the user runs `brigit scan -o <org>`
- **THEN** brigit SHALL list the organization's repositories via `gh repo list`
- **AND** it SHALL handle pagination for organizations with 100 or more repositories
- **AND** it SHALL respect GitHub API rate limits

### Requirement: Selective scanning

The tool SHALL support scanning a single repository or a set of repositories supplied from a file in `org:repo` format, validating that repositories exist before scanning.

#### Scenario: Scan a single repository
- **WHEN** the user runs `brigit scan -o <org> -r <repo>`
- **THEN** brigit SHALL validate the repository exists
- **AND** it SHALL scan only that repository

#### Scenario: Scan repositories from a file
- **WHEN** the user runs `brigit scan -f <file>` with `org:repo` lines (one per line)
- **THEN** brigit SHALL scan each listed repository

### Requirement: Protection rule checking

The tool SHALL evaluate the `main` branch's protection and return a status of OK, NOK, ARCHIVED, IGNORED, or SKIPPED.

#### Scenario: Compliant repository
- **WHEN** `main` exists, branch protection is enabled, `required_pull_request_reviews` is configured, and `required_approving_review_count` is at least 1
- **THEN** brigit SHALL return status OK

#### Scenario: Non-compliant repository
- **WHEN** branch protection is missing or `required_approving_review_count` is below 1
- **THEN** brigit SHALL return status NOK

### Requirement: Repository filtering

The tool SHALL skip archived repositories and repositories listed in `repos-ignore.txt`, and SHALL report the counts of filtered repositories separately.

#### Scenario: Archived repository is skipped
- **WHEN** a repository is archived
- **THEN** brigit SHALL skip it and count it as ARCHIVED

#### Scenario: Ignored repository is skipped
- **WHEN** a repository appears in `repos-ignore.txt`
- **THEN** brigit SHALL skip it and count it as IGNORED

### Requirement: Error handling

The tool SHALL handle per-repository errors gracefully and continue scanning the remaining repositories.

#### Scenario: Repository without a main branch
- **WHEN** a repository has no `main` branch
- **THEN** brigit SHALL report it as an error
- **AND** it SHALL continue scanning the other repositories

#### Scenario: Access or API error
- **WHEN** a permission error or an API error (rate limiting, timeout) occurs for a repository
- **THEN** brigit SHALL log the error
- **AND** it SHALL continue scanning the other repositories

### Requirement: Scan report generation

`brigit scan` SHALL generate a timestamped log file containing the results table, summary statistics, and the list of repositories with issues.

#### Scenario: Report includes summary statistics
- **WHEN** a scan completes
- **THEN** the log SHALL include counts of repositories with proper protection (OK), improper protection (NOK), errors, archived, and ignored

#### Scenario: Report lists repositories with issues
- **WHEN** repositories are found with improper protection or errors
- **THEN** the log SHALL list each such repository with its specific error message

### Requirement: Scan performance

The tool SHALL show a progress indicator during interactive scans and process repositories sequentially to avoid hitting API rate limits.

#### Scenario: Progress shown during interactive scan
- **WHEN** a scan runs in an interactive terminal
- **THEN** brigit SHALL show a progress indicator
- **AND** it SHALL process repositories sequentially

### Requirement: Interactive and non-interactive usability

The tool SHALL use `gum` for interactive display, SHALL support a non-interactive mode for CI/CD, and SHALL provide clear error messages.

#### Scenario: Interactive display
- **WHEN** a scan runs in an interactive terminal
- **THEN** brigit SHALL render tables and spinners using `gum`

#### Scenario: Non-interactive mode for CI/CD
- **WHEN** a scan runs without an interactive terminal
- **THEN** brigit SHALL produce plain output suitable for CI/CD

### Requirement: Read-only reliability

The tool SHALL NOT modify any GitHub settings during a scan, SHALL validate all inputs before making API calls, and SHALL handle network failures gracefully.

#### Scenario: Scan makes no modifications
- **WHEN** any scan runs
- **THEN** brigit SHALL NOT modify any GitHub branch protection or repository settings

### Requirement: Scan output location and reporting

`brigit scan` SHALL write its generated files to the resolved output directory (see the `output-location` capability) rather than the current working directory, and SHALL report the absolute path of each created file.

#### Scenario: Scan writes log to resolved output directory
- **WHEN** `brigit scan` produces a `brigit-scan-{timestamp}.log` file
- **THEN** the file SHALL be created in the resolved output directory
- **AND** brigit SHALL print its absolute path when the run completes

#### Scenario: Scan writes issue file to resolved output directory
- **WHEN** scanning finds repositories with issues and produces `brigit-scan-{timestamp}.repos`
- **THEN** the file SHALL be created in the resolved output directory
- **AND** brigit SHALL print its absolute path when the run completes

#### Scenario: Issue file path is usable as enforce input
- **WHEN** brigit reports the absolute path of the `brigit-scan-{timestamp}.repos` file
- **THEN** that path SHALL be directly usable as the argument to `brigit enforce -f`

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

## Data Model

### Input

```yaml
Command: brigit scan
Flags:
  -o: organization name (string, optional with -f)
  -r: repository name (string, optional, requires -o)
  -f: file path (string, optional with -o)
  -d: debug mode (boolean, optional)
  -h: help (boolean, optional)

File format (repos.txt):
  org:repo
  org:repo
  ...
```

### Output

```yaml
Log file: brigit-scan-{YYYYMMDD_HHMMSS}.log
  Format: table
    Columns: REPOSITORY, STATUS
    Values: org/repo, OK|NOK|ARCHIVED|IGNORED
  Summary:
    - Repositories with proper protection: N
    - Repositories with improper protection: N
    - Repositories with errors: N
    - Archived repositories: N
    - Ignored repositories: N
  Issues list:
    - org/repo: error message

Issue file: brigit-scan-{YYYYMMDD_HHMMSS}.repos
  Format: org:repo (one per line)
  Contains: Only repos with NOK or error status
```

### Status Codes

- **OK**: Branch protection properly configured
- **NOK**: Branch protection missing or inadequate
- **ARCHIVED**: Repository is archived (automatically skipped)
- **IGNORED**: Repository in ignore list (user-defined skip)
- **SKIPPED**: Repository skipped for other reasons

## API Interactions

### GitHub API Calls

1. **List repositories** (if scanning org)
   - Endpoint: `gh repo list {org} --json name --limit 100`
   - Returns: JSON array of repository objects

2. **Check if repo exists** (if scanning specific repo)
   - Command: `gh repo view {org}/{repo}`
   - Returns: Success/error

3. **Check if repo is archived**
   - Command: `gh repo view {org}/{repo} --json isArchived --jq '.isArchived'`
   - Returns: `true` or `false`

4. **Get branch info** (check if main exists)
   - Endpoint: `gh api /repos/{org}/{repo}/branches/main`
   - Returns: Branch object or 404

5. **Get branch protection**
   - Endpoint: `gh api /repos/{org}/{repo}/branches/main/protection`
   - Returns: Protection object or error

## Edge Cases

1. **No main branch**: Report as error, don't fail entire scan
2. **Private repo requires GitHub Pro**: Can't check protection without Pro
3. **No access to repository**: Report as error, continue scanning
4. **Empty organization**: Report "No repositories found"
5. **All repos ignored/archived**: Success with 0 scanned
6. **API rate limit hit**: Pause and retry, or fail gracefully with message

## Debug Mode

When `-d` flag is provided:
- Display raw API response JSON for each repository
- Show protection configuration in detail
- Useful for troubleshooting why a repo is marked NOK

## Examples

### Scan entire organization
```bash
brigit scan -o technative-mcs
```

### Scan specific repository
```bash
brigit scan -o technative-mcs -r brigit
```

### Scan from file
```bash
brigit scan -f repos.txt
```

### Debug mode
```bash
brigit scan -o technative-mcs -d
```

## Related Capabilities

- **Enforcement**: Uses scan output (`brigit-scan-*.repos`) as input
- **Filtering**: Relies on ignore list loading
- **Reporting**: Generates logs consumed by users
- **Configuration**: Checks against rules in `ghbranchprotection.json`
