# Repository Filtering Capability

## Purpose

Exclude repositories from scanning and enforcement operations based on user-defined ignore lists and automatic detection of special cases (e.g., archived repos).

## Requirements

### Functional Requirements

**FR1: Ignore List Loading**
- MUST load ignore list from `repos-ignore.txt` file
- MUST support format `org:repo` (one per line)
- MUST skip empty lines
- MUST skip lines starting with `#` (comments)
- MUST trim whitespace from organization and repository names
- MUST handle missing ignore file gracefully (treat as empty)

**FR2: Repository Matching**
- MUST match repositories exactly by `org:repo` key
- MUST be case-sensitive (GitHub repos are case-sensitive)
- MUST support multiple organizations in same ignore list
- MUST allow duplicate entries (no error, just redundant)

**FR3: Archived Repository Detection**
- MUST query GitHub API to check `isArchived` flag
- MUST automatically skip archived repositories
- MUST mark archived repos with ARCHIVED status
- MUST count archived repos separately in summary

**FR4: Status Reporting**
- MUST mark ignored repos with IGNORED status
- MUST mark archived repos with ARCHIVED status
- MUST report counts separately:
  - Ignored (user-defined)
  - Archived (system-detected)
- MUST include both in summary statistics

**FR5: Early Exit**
- MUST check ignore list before making any GitHub API calls
- MUST check archived status before attempting protection operations
- MUST skip all processing for filtered repositories

### Non-Functional Requirements

**NFR1: Performance**
- SHOULD load ignore list once at startup
- SHOULD cache loaded ignore list in memory
- MUST NOT reload ignore list for each repository

**NFR2: Transparency**
- MUST report count of ignored repos at start
- MUST show which repos are filtered in output
- MUST differentiate between user-ignored and system-archived

**NFR3: Maintainability**
- MUST provide example ignore file (`repos-ignore.txt.example`)
- MUST document ignore file format
- SHOULD validate ignore file format (warn on malformed lines)

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
