# Repository Filtering Capability

## Purpose

Exclude repositories from scanning and enforcement operations based on user-defined ignore lists and automatic detection of special cases (e.g., archived repos).

## Requirements

### Requirement: Ignore list loading

The tool SHALL load the ignore list from `repos-ignore.txt` in `org:repo` format, skipping empty lines and `#` comments, trimming whitespace, and treating a missing file as an empty list.

#### Scenario: Load a valid ignore file
- **WHEN** `repos-ignore.txt` exists with `org:repo` lines, comments, and blank lines
- **THEN** brigit SHALL load the `org:repo` entries
- **AND** it SHALL skip empty lines and lines starting with `#`
- **AND** it SHALL trim surrounding whitespace from each name

#### Scenario: Missing ignore file
- **WHEN** `repos-ignore.txt` does not exist
- **THEN** brigit SHALL treat the ignore list as empty and proceed

### Requirement: Repository matching

The tool SHALL match ignore entries exactly by `org:repo` key, case-sensitively, supporting multiple organizations and tolerating duplicate entries.

#### Scenario: Exact case-sensitive match
- **WHEN** a repository's `org:repo` key exactly matches an ignore entry
- **THEN** brigit SHALL treat the repository as ignored

#### Scenario: Duplicate entries are harmless
- **WHEN** the ignore list contains duplicate entries
- **THEN** brigit SHALL not error and SHALL treat the repository as ignored

### Requirement: Archived repository detection

The tool SHALL query the GitHub API for the `isArchived` flag, automatically skip archived repositories, mark them ARCHIVED, and count them separately.

#### Scenario: Archived repository detected
- **WHEN** the GitHub API reports a repository as archived
- **THEN** brigit SHALL skip it, mark it ARCHIVED, and count it separately

### Requirement: Status reporting

The tool SHALL mark ignored repositories IGNORED and archived repositories ARCHIVED, reporting the two counts separately in the summary statistics.

#### Scenario: Separate counts in summary
- **WHEN** a run filters both user-ignored and system-archived repositories
- **THEN** the summary SHALL report the IGNORED and ARCHIVED counts separately

### Requirement: Early exit for filtered repositories

The tool SHALL check the ignore list before making any GitHub API calls and check archived status before attempting protection operations, skipping all further processing for filtered repositories.

#### Scenario: Ignored repository is not queried
- **WHEN** a repository is in the ignore list
- **THEN** brigit SHALL skip it without making protection-related API calls

### Requirement: Ignore list caching

The tool SHALL load the ignore list once and reuse it, and SHALL NOT reload it for each repository.

#### Scenario: Loaded once per run
- **WHEN** a run processes many repositories
- **THEN** brigit SHALL load the ignore list once and reuse it in memory

### Requirement: Filtering transparency

The tool SHALL report the count of ignored repositories at the start, show which repositories are filtered in the output, and differentiate user-ignored from system-archived.

#### Scenario: Filtered repositories are visible
- **WHEN** a run filters repositories
- **THEN** the output SHALL show the ignored count and distinguish ignored from archived

### Requirement: Ignore file documentation

The project SHALL provide an example ignore file (`repos-ignore.txt.example`) and document the ignore file format.

#### Scenario: Example file is available
- **WHEN** a user looks for how to configure ignores
- **THEN** an example `repos-ignore.txt.example` SHALL be available with the documented format

## Data Model

### Ignore File Format

```
# Repository Ignore List
# Format: org:repo (one per line)
# Lines starting with # are comments

# Deprecated repositories
acme-corp:legacy-v1-api
acme-corp:old-website-2020

# Test repositories
acme-corp:test-sandbox
acme-corp:demo-project

# Special cases
acme-corp:vendor-library-fork
```

### Internal Representation

```bash
# Array of ignore patterns
ignore_list=(
  "org1:repo1"
  "org2:repo2"
  "org3:repo3"
)

# Function to check if repo is ignored
is_repo_ignored() {
  local org="$1"
  local repo="$2"
  local repo_key="$org:$repo"

  for ignored in "${ignore_list[@]}"; do
    if [ "$ignored" = "$repo_key" ]; then
      return 0  # Ignored
    fi
  done
  return 1  # Not ignored
}
```

### API Response (Archived Check)

```json
{
  "isArchived": true
}
```

## Processing Flow

```
┌─────────────────┐
│ Start Operation │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Load repos-ignore.txt   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ For each repository:    │
└────────┬────────────────┘
         │
         ▼
    ┌────────────────┐      YES   ┌────────────────┐
    │ In ignore list?├────────────►│ Status: IGNORED│
    └────────┬───────┘             └────────────────┘
             │ NO
             ▼
    ┌────────────────┐      YES   ┌────────────────┐
    │ Is archived?   ├────────────►│Status: ARCHIVED│
    └────────┬───────┘             └────────────────┘
             │ NO
             ▼
    ┌────────────────┐
    │ Process repo   │
    │ (scan/enforce) │
    └────────────────┘
```

## Edge Cases

### Ignore File Edge Cases

1. **File doesn't exist**: Treat as empty, no repos ignored
2. **File is empty**: No repos ignored
3. **Only comments**: No repos ignored
4. **Malformed lines**: Skip silently (could add warning)
5. **Trailing/leading whitespace**: Trimmed automatically
6. **Duplicate entries**: No error, just ignored twice (harmless)

### Archived Repository Edge Cases

1. **API error checking archive status**: Treat as not archived, proceed
2. **Repository unarchived between scan and enforce**: Will process normally
3. **All repositories are archived**: Valid scenario, report 0 processed

### Combined Filtering

- If repo is both ignored AND archived: Shows as IGNORED (checked first)
- If repo is in ignore list but doesn't exist: No error (never queried)
- If repo is archived but not in ignore list: Shows as ARCHIVED

## Configuration

### Default Ignore File Location

- Development: `./repos-ignore.txt` (same directory as brigit)
- Nix installation: User's working directory `./repos-ignore.txt`

### Environment Variables

Currently none. Future enhancement:
- `BRIGIT_IGNORE_FILE` - Override ignore file location

## Examples

### Basic Ignore List

```
# repos-ignore.txt
myorg:deprecated-repo
myorg:test-sandbox
```

### Complex Ignore List

```
# repos-ignore.txt
# Organized by category

# === Deprecated Projects ===
acme-corp:legacy-v1-api
acme-corp:old-website-2020
acme-corp:deprecated-mobile-app

# === Test/Sandbox ===
acme-corp:test-sandbox
acme-corp:demo-project
acme-corp:playground-experiments

# === Third-party Forks ===
acme-corp:vendor-library-fork
acme-corp:external-integration-mirror

# === Documentation Only ===
# These don't need branch protection
myorg:company-handbook
myorg:onboarding-docs
```

### Usage Workflow

```bash
# Create ignore list
cat > repos-ignore.txt << EOF
myorg:legacy-repo
myorg:archived-project
EOF

# Scan will automatically skip these
brigit scan -o myorg
# Output shows: "Ignored: 2"

# Enforce will also skip
brigit enforce -f repos.txt
# Ignored repos won't be modified even if in file
```

## API Interactions

### Check Archive Status

```bash
# Command
gh repo view ${org}/${repo} --json isArchived --jq '.isArchived'

# Response (archived)
true

# Response (not archived)
false

# Error (repo not found)
# Falls through, treats as not archived
```

## Validation

### Ignore File Validation (Future Enhancement)

```bash
# Validate format
while IFS=: read -r org repo; do
  if [ -z "$org" ] || [ -z "$repo" ]; then
    echo "Warning: Invalid line in repos-ignore.txt: '$org:$repo'"
  fi
done < repos-ignore.txt
```

Currently validation is implicit - malformed lines are silently skipped.

## Related Capabilities

- **Scanning**: Uses filtering to skip repos during scan
- **Enforcement**: Uses filtering to skip repos during enforcement
- **Reporting**: Includes filtered repo counts in summaries
- **Configuration**: Ignore file is part of configuration system
