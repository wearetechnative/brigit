# Brigit Project Context

## Overview

**Brigit** (Branch Integrity Guard for Git) is a command-line tool for managing GitHub branch protection rules at scale. It helps organizations maintain consistent security and quality standards across multiple repositories.

## Purpose

Organizations with many repositories need a way to:
- Audit branch protection compliance across all repos
- Enforce standardized protection rules consistently
- Identify repositories with inadequate protection
- Skip archived or special-case repositories
- Generate actionable reports for remediation

Brigit provides this capability through a simple CLI interface that wraps the GitHub API.

## Tech Stack

- **Language**: Bash (shell scripts)
- **Package Manager**: Nix Flakes
- **Dependencies**:
  - `gh` - GitHub CLI (API access and authentication)
  - `jq` - JSON processing
  - `gum` - Terminal UI for interactive features
  - `bash` - Shell interpreter

## Architecture

```
┌─────────────┐
│   brigit    │  Main entry point & command router
└──────┬──────┘
       │
       ├─► _lib.sh         Shared utilities
       ├─► ghbranchprotection.json   Protection rules config
       ├─► repos-ignore.txt          User exclusion list
       └─► Commands:
           ├─ scan         Check compliance
           ├─ enforce      Apply rules
           ├─ clean        Cleanup logs
           └─ version      Version info
```

## Domain Model

### Core Concepts

- **Repository**: GitHub repo identified as `org:repo`
- **Branch Protection**: GitHub rules that restrict how code can be merged
- **Protection Rules**: JSON configuration defining desired protection settings
- **Scan**: Read-only check of current protection state
- **Enforce**: Write operation to apply protection rules
- **Status**: Classification of repo protection state (OK, NOK, ARCHIVED, IGNORED, SKIPPED)

### Key Workflows

1. **Audit Workflow**: Scan → Review logs → Identify issues
2. **Remediation Workflow**: Scan → Generate issue list → Enforce → Verify
3. **Maintenance Workflow**: Update config → Enforce → Scan to verify

## Conventions

### Code Style
- Bash functions use snake_case
- Commands use kebab-case
- Global variables use UPPER_CASE
- Local variables use lowercase

### File Naming
- Generated logs: `brigit-{command}-{timestamp}.log`
- Issue lists: `repos-{timestamp}.txt`
- User config: `repos-ignore.txt`, `ghbranchprotection.json`

### Output Format
- Interactive mode: Uses `gum` for styled tables, spinners, progress
- Non-interactive mode: Plain text for CI/CD pipelines
- Logs: Timestamped files with summary statistics

## Project Structure

```
brigit/
├── brigit                          # Main executable
├── _lib.sh                         # Shared functions
├── ghbranchprotection.json         # Protection rules template
├── repos-ignore.txt.example        # Example ignore list
├── repos.txt.example               # Example target list
├── package.nix                     # Nix package definition
├── flake.nix                       # Nix flake
├── README.md                       # User documentation
├── INSTALL.md                      # Installation guide
├── CHANGELOG.md                    # Version history
└── openspec/                       # OpenSpec artifacts
    ├── config.yaml                 # OpenSpec config
    ├── PROJECT.md                  # This file
    └── specs/                      # Capability specs
```

## Current State

- **Version**: 0.0.1 (initial release)
- **Status**: Production-ready
- **Distribution**: Published via GitHub (wearetechnative/brigit)
- **Installation**: Nix Flakes, manual installation

## Future Considerations

Potential areas for evolution (not committed):
- Support for multiple branches beyond `main`
- Custom protection profiles per repository
- Integration with other VCS platforms (GitLab, Bitbucket)
- CI/CD integration examples
- Dry-run mode for enforce command
- Webhooks for continuous compliance monitoring
