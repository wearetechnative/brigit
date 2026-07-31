# Repository Scanning Capability

## Purpose

Scan GitHub repositories to check compliance with branch protection rules. Provides read-only auditing of current protection state without making any changes.

## Requirements

### Functional Requirements

**FR1: Organization-Wide Scanning**
- MUST support scanning all repositories in a GitHub organization
- MUST use GitHub API to list repositories (via `gh repo list`)
- MUST handle pagination for organizations with 100+ repositories
- MUST respect GitHub API rate limits

**FR2: Selective Scanning**
- MUST support scanning a single repository with `-o` and `-r` flags
- MUST support scanning multiple repositories from a file with `-f` flag
- MUST support format `org:repo` in input files (one per line)
- MUST validate that repositories exist before scanning

**FR3: Protection Rule Checking**
- MUST check if branch `main` exists
- MUST check if branch protection is enabled
- MUST verify `required_pull_request_reviews` is configured
- MUST verify `required_approving_review_count >= 1`
- MUST return status: OK, NOK, ARCHIVED, IGNORED, or SKIPPED

**FR4: Repository Filtering**
- MUST automatically skip archived repositories
- MUST respect repositories in `repos-ignore.txt`
- MUST report count of filtered repositories separately

**FR5: Error Handling**
- MUST gracefully handle repositories without a `main` branch
- MUST handle permission errors (no access to repository)
- MUST handle API errors (rate limiting, timeouts)
- MUST log errors but continue scanning other repositories

**FR6: Output Generation**
- MUST generate timestamped log file `brigit-scan-{timestamp}.log`
- MUST generate `repos-{timestamp}.txt` if issues found
- MUST display summary statistics:
  - Repositories with proper protection (OK)
  - Repositories with improper protection (NOK)
  - Repositories with errors (missing branch, access issues)
  - Archived repositories (ARCHIVED)
  - Ignored repositories (IGNORED)
- MUST list each repository with issues and specific error message

### Non-Functional Requirements

**NFR1: Performance**
- MUST show progress indicator during scan (when interactive)
- MUST process repositories sequentially to avoid API rate limits
- SHOULD complete scan of 100 repositories within 5 minutes

**NFR2: Usability**
- MUST use `gum` for interactive display (tables, spinners)
- MUST support non-interactive mode for CI/CD
- MUST provide clear error messages

**NFR3: Reliability**
- MUST NOT modify any GitHub settings (read-only operation)
- MUST validate all inputs before making API calls
- MUST handle network failures gracefully

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

Issue file: repos-{YYYYMMDD_HHMMSS}.txt
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

- **Enforcement**: Uses scan output (`repos-*.txt`) as input
- **Filtering**: Relies on ignore list loading
- **Reporting**: Generates logs consumed by users
- **Configuration**: Checks against rules in `ghbranchprotection.json`
