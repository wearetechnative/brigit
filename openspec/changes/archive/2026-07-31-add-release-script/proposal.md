## Why

Brigit currently lacks an automated release workflow. Creating releases manually is error-prone and requires remembering multiple steps: version bumping, changelog updates, git tagging, and GitHub release creation. Automating this ensures consistency, reduces errors, and makes releases faster.

## What Changes

- Create standalone `git-release` script that automates the entire release workflow
- Interactive version selection (patch/minor/major) using gum dropdown
- Automatic version bumping in VERSION file
- Automatic CHANGELOG.md updates with version and date
- Git safety checks (fail on dirty working tree)
- Git tag creation and push to GitHub
- GitHub release creation via `gh` CLI

## Capabilities

### New Capabilities
- `release-automation`: Automated release workflow including version management, changelog updates, and GitHub release publishing

### Modified Capabilities
<!-- No existing capabilities are being modified -->

## Impact

**New Files**:
- `git-release`: Standalone bash script for release automation
- Can be used in any git repository with VERSION and CHANGELOG.md files

**Modified Files**:
- `VERSION`: Will be automatically updated by release script
- `CHANGELOG.md`: Will be automatically updated with version headers

**Dependencies**:
- `gh` (GitHub CLI)
- `gum` (for interactive prompts)
- `bash`
- Git repository must be clean before release

**User Workflow**:
- Developers run `./git-release` or `git-release` instead of manual steps
- Interactive prompt guides version selection
- Script handles all git operations and GitHub integration
- Script is generic and can be used in any project
