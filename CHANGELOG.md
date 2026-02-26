# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-02-26

### Added
- Initial release of brigit - Branch Integrity Guard for Git
- `scan` command to check branch protection compliance
  - Scan all repositories in an organization (`-o` flag)
  - Scan specific repository (`-o` and `-r` flags)
  - Scan repositories from file (`-f` flag)
- `enforce` command to apply branch protection rules
  - Enforce on specific repository (`-o` and `-r` flags)
  - Enforce on multiple repositories from file (`-f` flag)
- `clean` command to remove log files and output files
- `version` command to display version information
- Support for `repos-ignore.txt` to skip specific repositories
- Automatic detection and skipping of archived repositories
- Interactive terminal support with `gum` for better UX
- Non-interactive mode for CI/CD pipelines
- Colored output and progress indicators
- JSON configuration file for branch protection settings
- Output files with timestamps:
  - `brigit-scan-*.log` - Scan results
  - `brigit-enforce-*.log` - Enforce results
  - `repos-*.txt` - Repositories with issues
- Repository status indicators:
  - `OK` - Proper branch protection configured
  - `NOK` - Improper or missing branch protection
  - `ARCHIVED` - Repository is archived
  - `IGNORED` - Repository is in ignore list
  - `SKIPPED` - Repository skipped during enforcement
- Debug mode for scan command (`-d` flag)
- Nix Flake support for easy installation and development
- Comprehensive documentation in README.md

### Requirements
- GitHub CLI (`gh`) - authenticated
- `jq` - JSON processor
- `gum` - Terminal UI toolkit
- Bash shell

### Configuration
- `ghbranchprotection.json` - Branch protection rules configuration
- `repos-ignore.txt` - Optional ignore list for repositories

[0.0.1]: https://github.com/wearetechnative/brigit/releases/tag/v0.0.1
