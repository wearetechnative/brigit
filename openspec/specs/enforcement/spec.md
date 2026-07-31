# Protection Enforcement Capability

## Purpose

Apply branch protection rules to GitHub repositories. Modifies repository settings to enforce standardized protection configuration.

## Requirements

### Functional Requirements

**FR1: Target Selection**
- MUST support enforcing on single repository with `-o` and `-r` flags
- MUST support enforcing on multiple repositories from file with `-f` flag
- MUST validate that organization and repository are provided
- MUST NOT support organization-wide enforcement (too risky without explicit list)

**FR2: Configuration Loading**
- MUST load protection rules from `ghbranchprotection.json`
- MUST use `default` profile from configuration
- MUST validate that configuration file exists
- MUST fail gracefully if configuration is invalid

**FR3: Protection Application**
- MUST apply protection to `main` branch only
- MUST set required pull request reviews
- MUST set required approving review count (default: 1)
- MUST set dismiss stale reviews flag
- MUST set require code owner reviews flag
- MUST apply all rules from configuration atomically

**FR4: Pre-Flight Checks**
- MUST check if repository is archived (skip if true)
- MUST check if repository is in ignore list (skip if true)
- MUST verify `main` branch exists before applying
- MUST handle missing branch as error

**FR5: Permission Handling**
- MUST detect "requires GitHub Pro" errors
- MUST detect "no permission" errors
- MUST report specific error messages
- MUST continue processing other repos after errors

**FR6: Output Generation**
- MUST generate timestamped log file `brigit-enforce-{timestamp}.log`
- MUST display summary statistics:
  - Successfully applied: N
  - Failed: N
  - Skipped (archived): N
  - Ignored: N
  - Total processed: N
- MUST list each failed repository with specific error message

### Non-Functional Requirements

**NFR1: Safety**
- MUST require explicit repository list (no wildcards)
- MUST respect ignore list unconditionally
- MUST skip archived repositories automatically
- SHOULD allow dry-run mode (future enhancement)

**NFR2: Performance**
- MUST show progress indicator during enforcement (when interactive)
- MUST process repositories sequentially
- SHOULD complete enforcement of 50 repositories within 10 minutes

**NFR3: Idempotency**
- MUST be safe to run multiple times on same repository
- MUST overwrite existing protection with new configuration
- MUST handle "already protected" scenarios gracefully

**NFR4: Auditability**
- MUST log every enforcement attempt
- MUST record success/failure for each repository
- MUST include timestamps in all log files

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
2. Review `repos-{timestamp}.txt` output
3. Edit file to remove any repos that shouldn't be modified
4. Run `brigit enforce -f repos-{timestamp}.txt`
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
# Output: repos-20260226_184729.txt

# Review and edit the file if needed
# Then enforce
brigit enforce -f repos-20260226_184729.txt
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
