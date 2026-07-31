# Protection Enforcement Capability

## Purpose

Apply branch protection rules to GitHub repositories. Modifies repository settings to enforce standardized protection configuration.

## Requirements

### Requirement: Target selection

The tool SHALL support enforcing on a single repository (`-o` and `-r`) or on multiple repositories from a file (`-f`), SHALL validate that the required targets are provided, and SHALL NOT support organization-wide enforcement without an explicit list.

#### Scenario: Enforce on a single repository
- **WHEN** the user runs `brigit enforce -o <org> -r <repo>`
- **THEN** brigit SHALL enforce protection on that repository

#### Scenario: Enforce from a file
- **WHEN** the user runs `brigit enforce -f <file>` with `org:repo` lines
- **THEN** brigit SHALL enforce protection on each listed repository

#### Scenario: Organization-wide enforcement is refused
- **WHEN** the user attempts enforcement with only `-o <org>` and no repository or file
- **THEN** brigit SHALL refuse to run (no wildcard org-wide enforcement)

### Requirement: Configuration loading

The tool SHALL load protection rules from `ghbranchprotection.json`, using the `default` profile, and SHALL fail gracefully when the configuration is missing or invalid.

#### Scenario: Valid configuration is loaded
- **WHEN** `ghbranchprotection.json` exists with a `default` profile
- **THEN** brigit SHALL load the `default` profile as the protection rules

#### Scenario: Missing or invalid configuration
- **WHEN** the configuration file is missing or invalid
- **THEN** brigit SHALL fail gracefully with a clear message

### Requirement: Protection application

The tool SHALL apply the configured protection to the `main` branch only, setting required pull request reviews, approving review count (default 1), dismiss-stale-reviews, and require-code-owner-reviews, applying all rules from the configuration.

#### Scenario: Protection applied to main
- **WHEN** brigit enforces on a repository
- **THEN** it SHALL apply the configured protection rules to the `main` branch
- **AND** it SHALL set the required approving review count (defaulting to 1)

### Requirement: Pre-flight checks

The tool SHALL skip archived repositories and repositories in the ignore list, and SHALL verify the `main` branch exists before applying, treating a missing branch as an error.

#### Scenario: Archived or ignored repository is skipped
- **WHEN** a target repository is archived or appears in the ignore list
- **THEN** brigit SHALL skip it without modifying it

#### Scenario: Missing main branch
- **WHEN** a target repository has no `main` branch
- **THEN** brigit SHALL report it as an error and not apply protection

### Requirement: Permission handling

The tool SHALL detect "requires GitHub Pro" and "no permission" errors, report specific error messages, and continue processing the remaining repositories after an error.

#### Scenario: Continue after a permission error
- **WHEN** enforcement on a repository fails with a GitHub Pro or permission error
- **THEN** brigit SHALL report a specific error message
- **AND** it SHALL continue processing the other repositories

### Requirement: Enforce report generation

`brigit enforce` SHALL generate a timestamped log file with summary statistics and the list of failed repositories.

#### Scenario: Report includes summary statistics
- **WHEN** an enforcement run completes
- **THEN** the log SHALL include counts of successfully applied, failed, skipped (archived), ignored, and total processed

#### Scenario: Report lists failed repositories
- **WHEN** repositories fail enforcement
- **THEN** the log SHALL list each failed repository with its specific error message

### Requirement: Enforcement safety

The tool SHALL require an explicit repository list (no wildcards), SHALL respect the ignore list unconditionally, and SHALL skip archived repositories automatically.

#### Scenario: No wildcard enforcement
- **WHEN** enforcement is requested without an explicit repository or file
- **THEN** brigit SHALL NOT perform any enforcement

### Requirement: Enforcement performance

The tool SHALL show a progress indicator during interactive enforcement and process repositories sequentially.

#### Scenario: Progress shown during interactive enforcement
- **WHEN** enforcement runs in an interactive terminal
- **THEN** brigit SHALL show a progress indicator
- **AND** it SHALL process repositories sequentially

### Requirement: Idempotency

The tool SHALL be safe to run multiple times on the same repository, overwriting existing protection with the configured rules.

#### Scenario: Re-running enforcement
- **WHEN** enforcement is run again on an already-protected repository
- **THEN** brigit SHALL overwrite the existing protection with the configured rules without error

### Requirement: Auditability

The tool SHALL log every enforcement attempt, recording success or failure per repository with a timestamp.

#### Scenario: Every attempt is logged
- **WHEN** an enforcement run processes repositories
- **THEN** the timestamped log SHALL record the success or failure of each repository

### Requirement: Enforce output location and reporting

`brigit enforce` SHALL write its generated log file to the resolved output directory (see the `output-location` capability) rather than the current working directory, and SHALL report the absolute path of the created file.

#### Scenario: Enforce writes log to resolved output directory
- **WHEN** `brigit enforce` produces a `brigit-enforce-{timestamp}.log` file
- **THEN** the file SHALL be created in the resolved output directory
- **AND** brigit SHALL print its absolute path when the run completes

## Data Model

### Input

```yaml
Command: brigit enforce
Flags:
  -o: organization name (string, required without -f)
  -r: repository name (string, required with -o)
  -f: file path (string, required without -o/-r)
  -h: help (boolean, optional)

File format (repos.txt):
  org:repo
  org:repo
  ...

Configuration (ghbranchprotection.json):
  {
    "default": {
      "required_status_checks": null | object,
      "enforce_admins": boolean,
      "required_pull_request_reviews": {
        "required_approving_review_count": number,
        "dismiss_stale_reviews": boolean,
        "require_code_owner_reviews": boolean
      },
      "restrictions": null | object,
      "allow_force_pushes": boolean,
      "allow_deletions": boolean
    }
  }
```

### Output

```yaml
Log file: brigit-enforce-{YYYYMMDD_HHMMSS}.log
  Format: table
    Columns: REPOSITORY, STATUS
    Values: org/repo, OK|NOK|SKIPPED|IGN
  Summary:
    - Successfully applied: N
    - Failed: N
    - Skipped (archived): N
    - Ignored: N
    - Total processed: N
  Failed repos:
    - org/repo: error message
```

### Status Codes

- **OK**: Protection successfully applied
- **NOK**: Failed to apply protection
- **SKIPPED**: Repository archived, not modified
- **IGN**: Repository in ignore list, intentionally skipped

## API Interactions

### GitHub API Calls

1. **Check if repo is archived**
   - Command: `gh repo view {org}/{repo} --json isArchived --jq '.isArchived'`
   - Returns: `true` or `false`

2. **Check if main branch exists**
   - Endpoint: `gh api /repos/{org}/{repo}/branches/main`
   - Returns: Branch object or 404 error

3. **Apply branch protection**
   - Method: PUT
   - Endpoint: `gh api --method PUT /repos/{org}/{repo}/branches/main/protection --input -`
   - Body: JSON protection configuration
   - Returns: Updated protection object or error

## Protection Configuration

The enforcement builds a complete protection configuration by:

1. Loading `ghbranchprotection.json`
2. Extracting `.default` profile
3. Constructing full API payload:
   ```json
   {
     "required_status_checks": <from config>,
     "enforce_admins": <from config>,
     "required_pull_request_reviews": {
       "required_approving_review_count": <from config | default: 1>,
       "dismiss_stale_reviews": <from config | default: false>,
       "require_code_owner_reviews": <from config | default: false>
     },
     "restrictions": <from config>
   }
   ```

## Error Scenarios

### Common Errors

1. **"Upgrade to GitHub Pro"**
   - Cause: Private repo requires Pro plan for branch protection
   - Action: Report error, continue with other repos
   - User action: Upgrade plan or make repo public

2. **"Not Found"**
   - Cause: Repository doesn't exist or no access permissions
   - Action: Report error, continue with other repos
   - User action: Check permissions, verify repo exists

3. **"Branch 'main' does not exist"**
   - Cause: Repository uses different default branch
   - Action: Report error, skip repository
   - User action: Rename default branch or update brigit to support other branches

4. **"No default config found"**
   - Cause: `ghbranchprotection.json` missing `default` key
   - Action: Fail immediately (affects all repos)
   - User action: Fix configuration file

## Safety Guardrails

### What Enforcement Does NOT Do

- Does NOT support wildcards (`brigit enforce -o myorg` is invalid)
- Does NOT allow bulk org-wide enforcement without explicit list
- Does NOT skip confirmation in interactive mode (future enhancement)
- Does NOT preserve existing protection settings (overwrites completely)

### Recommended Workflow

1. Run `brigit scan -o myorg` first
2. Review `brigit-scan-{timestamp}.repos` output
3. Edit file to remove any repos that shouldn't be modified
4. Run `brigit enforce -f brigit-scan-{timestamp}.repos`
5. Run `brigit scan -o myorg` again to verify

## Examples

### Enforce on specific repository
```bash
brigit enforce -o technative-mcs -r brigit
```

### Enforce on multiple repositories from scan output
```bash
# First scan to find issues
brigit scan -o technative-mcs
# Output: brigit-scan-20260226_184729.repos

# Review and edit the file if needed
# Then enforce
brigit enforce -f brigit-scan-20260226_184729.repos
```

### Enforce on custom list
```bash
# Create custom list
cat > my-repos.txt << EOF
myorg:important-repo
myorg:critical-service
EOF

# Enforce
brigit enforce -f my-repos.txt
```

## Related Capabilities

- **Scanning**: Provides input files for enforcement
- **Filtering**: Honors ignore list during enforcement
- **Reporting**: Generates logs for audit trail
- **Configuration**: Reads protection rules from JSON
