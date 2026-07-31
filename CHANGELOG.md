# Changelog

## [Unreleased]

### Added
- **Configurable output directory**: Output/log files now go to a dedicated directory instead of the current working directory
  - New default location: `${XDG_STATE_HOME:-~/.local/state}/brigit/` (XDG-compliant)
  - Override precedence: `-O <dir>` flag > `BRIGIT_OUTPUT_DIR` env var > `output_dir` in `~/.config/brigit/config` > XDG default
  - `scan` and `enforce` now print the absolute path of every file they create

### Changed
- **BREAKING**: `scan` and `enforce` no longer write `brigit-scan-*.log`, `brigit-enforce-*.log`, or `brigit-repos-*.txt` to the current working directory. Automation reading these from the CWD must be updated (or set `BRIGIT_OUTPUT_DIR=$PWD` to restore the old behavior).
- **BREAKING**: the scan issue file is now named `brigit-repos-<timestamp>.txt` (was `repos-<timestamp>.txt`), matching the log-file naming convention.

### Fixed
- **`clean` command**: Now searches the resolved output directory instead of the script installation directory, so it works for Nix installations (previously it looked in the read-only Nix store and never found any files)

## [0.0.4] - 2026-03-24

## [0.0.3] - 2026-03-24

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
