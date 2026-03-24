# git-release - Automated Release Script

A standalone bash script for automating GitHub releases with semantic versioning.

## Overview

`git-release` is a generic script that can be used in any git repository to automate the release process. It handles version bumping, changelog updates, git tagging, and GitHub release creation.

## Features

- ✓ Semantic versioning (patch/minor/major)
- ✓ Interactive mode with `gum` dropdown
- ✓ Non-interactive mode for CI/CD
- ✓ Automatic VERSION file updates
- ✓ Automatic CHANGELOG.md updates with dates
- ✓ Git safety checks (dirty repository detection)
- ✓ Atomic git operations (commit → tag → push)
- ✓ GitHub release creation with extracted release notes
- ✓ Comprehensive error handling

## Requirements

- **bash** - Shell interpreter
- **git** - Version control
- **gh** (GitHub CLI) - For creating GitHub releases (must be authenticated)
- **gum** (optional) - For interactive prompts (recommended)

Install requirements:
```bash
# GitHub CLI
brew install gh      # macOS
apt install gh       # Debian/Ubuntu
# Or see: https://github.com/cli/cli#installation

# Authenticate
gh auth login

# gum (optional, for interactive mode)
brew install gum     # macOS
# Or see: https://github.com/charmbracelet/gum#installation
```

## Installation

### Option 1: Copy to Your Repository

```bash
# Copy script to your repository
curl -o git-release https://raw.githubusercontent.com/wearetechnative/brigit/main/git-release
chmod +x git-release

# Or use wget
wget https://raw.githubusercontent.com/wearetechnative/brigit/main/git-release
chmod +x git-release
```

### Option 2: Install Globally

```bash
# Download script
curl -o /usr/local/bin/git-release https://raw.githubusercontent.com/wearetechnative/brigit/main/git-release
chmod +x /usr/local/bin/git-release

# Now you can run from any repository
cd /path/to/your/repo
git-release patch
```

## Setup

Your repository needs two files:

### 1. VERSION File

Create a `VERSION` file in your repository root:
```
0.0.1
```

Format: `X.Y.Z` (semantic versioning)

### 2. CHANGELOG.md File

Create a `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

## [Unreleased]

### Added
- New feature X
- New feature Y

### Changed
- Updated behavior Z

### Fixed
- Bug fix A

## [0.0.1] - 2024-01-01

### Added
- Initial release
```

The `[Unreleased]` section is **required**. This section will be converted to the release version automatically.

## Usage

### Interactive Mode

Run without arguments to get an interactive prompt (requires `gum`):

```bash
./git-release
```

You'll see a dropdown to select:
- patch (0.0.1 → 0.0.2)
- minor (0.0.1 → 0.1.0)
- major (0.0.1 → 1.0.0)

### Non-Interactive Mode

Specify the version type as an argument:

```bash
./git-release patch    # Patch release
./git-release minor    # Minor release
./git-release major    # Major release
```

Perfect for CI/CD pipelines!

### Help

```bash
./git-release -h
./git-release --help
```

## Release Process

When you run `git-release`, it performs these steps:

1. **Safety Checks**
   - Verifies you're in a git repository
   - Checks that working directory is clean (no uncommitted changes)
   - Untracked files are allowed

2. **Version Calculation**
   - Reads current version from `VERSION` file
   - Validates format (X.Y.Z)
   - Calculates new version based on type:
     - **patch**: Increments patch (0.0.1 → 0.0.2)
     - **minor**: Increments minor, resets patch (0.0.1 → 0.1.0)
     - **major**: Increments major, resets minor and patch (0.0.1 → 1.0.0)

3. **File Updates**
   - Updates `VERSION` file with new version
   - Updates `CHANGELOG.md`:
     - Replaces `## [Unreleased]` with `## [X.Y.Z] - YYYY-MM-DD`
     - Adds new `## [Unreleased]` section at top

4. **Release Notes Extraction**
   - Extracts content from CHANGELOG.md for the new version
   - Uses this as release notes for GitHub release

5. **Git Operations**
   - Creates commit: `Release vX.Y.Z`
   - Creates annotated tag: `vX.Y.Z`
   - Pushes commit and tag to remote

6. **GitHub Release**
   - Creates GitHub release using `gh` CLI
   - Attaches extracted release notes
   - Provides URL to view the release

## Release Types

Choose the appropriate release type based on semantic versioning:

| Type | When to Use | Example |
|------|-------------|---------|
| **patch** | Bug fixes, minor changes, no API changes | 0.0.1 → 0.0.2 |
| **minor** | New features, backwards compatible | 0.0.1 → 0.1.0 |
| **major** | Breaking changes, incompatible API changes | 0.0.1 → 1.0.0 |

## Workflow Example

### Making a Release

```bash
# 1. Make your changes and commit them
git add .
git commit -m "Add new feature"

# 2. Update CHANGELOG.md
# Add your changes under the [Unreleased] section
vim CHANGELOG.md

# Commit the changelog
git add CHANGELOG.md
git commit -m "Update changelog"

# 3. Ensure working directory is clean
git status

# 4. Run release script
./git-release          # Interactive
# OR
./git-release patch    # Non-interactive

# Done! The script handles everything:
# ✓ VERSION file updated
# ✓ CHANGELOG.md updated with date
# ✓ Git commit created
# ✓ Git tag created
# ✓ Pushed to GitHub
# ✓ GitHub release created
```

### CHANGELOG.md Maintenance

Before each release:
1. Add all changes under `## [Unreleased]`
2. Use standard categories: `Added`, `Changed`, `Fixed`, `Removed`, `Deprecated`, `Security`
3. Write clear, user-focused descriptions

Example:
```markdown
## [Unreleased]

### Added
- Support for custom templates via `--template` flag
- New `validate` command for checking configuration

### Fixed
- Fixed crash when processing empty files
- Improved error messages for invalid input
```

The script will automatically:
- Convert `[Unreleased]` to `[X.Y.Z] - 2024-03-24`
- Add a new `[Unreleased]` section for next release

## Error Handling

### Common Errors

**"Git repository is dirty"**
```bash
# You have uncommitted changes
git status
git commit -am "Commit message"
# Or
git stash
```

**"VERSION file not found"**
```bash
# Create VERSION file
echo "0.0.1" > VERSION
git add VERSION
git commit -m "Add VERSION file"
```

**"CHANGELOG.md not found"**
```bash
# Create CHANGELOG.md
cat > CHANGELOG.md << 'EOF'
# Changelog

## [Unreleased]

### Added
- Initial release
EOF
git add CHANGELOG.md
git commit -m "Add CHANGELOG.md"
```

**"Tag vX.Y.Z already exists"**
```bash
# This version was already released
# Either:
# 1. Use a different version type, or
# 2. Delete the tag if it was a mistake:
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z
```

**"Failed to create GitHub release"**
```bash
# Check gh authentication
gh auth status
gh auth login

# Check you have push permissions
gh repo view
```

### Recovery from Failed Release

If the release fails partway through:

| Stage Failed | What Happened | Recovery |
|--------------|---------------|----------|
| Before commit | No changes made | Safe to retry |
| After commit, before tag | Commit exists locally | `git reset HEAD~1` then retry |
| After tag, before push | Tag exists locally | `git tag -d vX.Y.Z` then retry |
| After push, before GitHub release | Tag on remote | Manually create release or delete tag |

To manually create a GitHub release:
```bash
gh release create vX.Y.Z --notes "Release notes here"
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      version_type:
        description: 'Version type (patch, minor, major)'
        required: true
        default: 'patch'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Setup GitHub CLI
        run: |
          gh auth login --with-token <<< "${{ secrets.GITHUB_TOKEN }}"

      - name: Download git-release
        run: |
          curl -o git-release https://raw.githubusercontent.com/wearetechnative/brigit/main/git-release
          chmod +x git-release

      - name: Create Release
        run: ./git-release ${{ github.event.inputs.version_type }}
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Testing

A test suite is included to verify the script:

```bash
# Run tests
./test-release.sh

# Tests verify:
# - Version calculation logic
# - VERSION file handling
# - CHANGELOG.md updates
# - Error handling
# - Git safety checks
```

## Limitations

- Only supports semantic versioning (X.Y.Z format)
- No pre-release versions (alpha, beta, rc)
- Requires GitHub (uses gh CLI)
- No automatic rollback on failure (manual recovery needed)
- CHANGELOG.md must follow Keep a Changelog format

## Contributing

The `git-release` script is part of the [brigit](https://github.com/wearetechnative/brigit) repository but designed to be standalone.

To contribute:
1. Fork the repository
2. Make your changes to `git-release`
3. Test with `./test-release.sh`
4. Submit a pull request

## License

Apache License 2.0 - See LICENSE file in the brigit repository.

## Support

- **Issues**: https://github.com/wearetechnative/brigit/issues
- **Discussions**: https://github.com/wearetechnative/brigit/discussions

---

Made with ❤️ by [TechNative](https://technative.eu)
