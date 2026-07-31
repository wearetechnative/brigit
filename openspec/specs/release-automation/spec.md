# release-automation Specification

## Purpose
TBD - created by archiving change add-release-script. Update Purpose after archive.
## Requirements
### Requirement: Version selection interface
The release command SHALL prompt the user to select a release type (patch, minor, or major) using an interactive dropdown interface.

#### Scenario: User selects patch release
- **WHEN** user runs `brigit release` and selects "patch" from the dropdown
- **THEN** system increments the patch version number (e.g., 0.0.1 → 0.0.2)

#### Scenario: User selects minor release
- **WHEN** user runs `brigit release` and selects "minor" from the dropdown
- **THEN** system increments the minor version and resets patch to 0 (e.g., 0.0.1 → 0.1.0)

#### Scenario: User selects major release
- **WHEN** user runs `brigit release` and selects "major" from the dropdown
- **THEN** system increments the major version and resets minor and patch to 0 (e.g., 0.0.1 → 1.0.0)

### Requirement: Version file management
The system SHALL read the current version from the VERSION file, calculate the new version based on user selection, and write the updated version back to the VERSION file.

#### Scenario: Read current version
- **WHEN** release process starts
- **THEN** system reads the version from VERSION file (format: X.Y.Z)

#### Scenario: Update version file
- **WHEN** new version is calculated
- **THEN** system writes the new version to VERSION file with single newline

#### Scenario: Version file is consumed by other components
- **WHEN** package.nix reads VERSION file
- **THEN** version information is available for Nix package metadata
- **WHEN** brigit application displays version
- **THEN** version matches content of VERSION file

### Requirement: Changelog automation
The system SHALL update CHANGELOG.md by replacing the placeholder heading with the new version and date, and SHALL create a new placeholder heading for the next release.

#### Scenario: Replace placeholder with version
- **WHEN** release is executed with version 0.0.2
- **THEN** system replaces `## [Unreleased]` or placeholder heading with `## [0.0.2] - YYYY-MM-DD` using current date

#### Scenario: Create new placeholder
- **WHEN** version heading is replaced
- **THEN** system creates new `## [Unreleased]` heading at the top of the changelog

#### Scenario: Preserve changelog format
- **WHEN** changelog is updated
- **THEN** existing version entries remain unchanged
- **THEN** markdown formatting is preserved
- **THEN** changelog follows Keep a Changelog format

### Requirement: Git repository safety checks
The release command SHALL verify the git repository is in a clean state before proceeding with any operations and SHALL fail with a clear error message if the working tree is dirty.

#### Scenario: Clean repository check passes
- **WHEN** user runs `brigit release` and repository has no uncommitted changes
- **THEN** system proceeds with release workflow

#### Scenario: Dirty repository check fails
- **WHEN** user runs `brigit release` and repository has uncommitted changes
- **THEN** system displays error message "Error: Git repository is dirty. Commit or stash changes before creating a release."
- **THEN** system exits with non-zero status code
- **THEN** no version changes or git operations are performed

#### Scenario: Untracked files are allowed
- **WHEN** repository has untracked files but no modified tracked files
- **THEN** system considers repository clean and proceeds

### Requirement: Git tag creation and push
The system SHALL create an annotated git tag with the new version number and SHALL push the tag to the remote GitHub repository.

#### Scenario: Create version tag
- **WHEN** release version is 0.0.2
- **THEN** system creates git tag `v0.0.2` with annotation "Release v0.0.2"

#### Scenario: Push tag to remote
- **WHEN** git tag is created
- **THEN** system pushes tag to remote origin
- **THEN** system pushes any committed changes (VERSION, CHANGELOG.md) to remote

#### Scenario: Tag already exists
- **WHEN** a tag with the same version already exists
- **THEN** system fails with error message "Error: Tag v0.0.2 already exists"
- **THEN** no changes are pushed to remote

### Requirement: GitHub release creation
The system SHALL create a GitHub release using the `gh` CLI with the release notes extracted from the CHANGELOG.md for the current version.

#### Scenario: Create GitHub release
- **WHEN** git tag v0.0.2 is pushed
- **THEN** system executes `gh release create v0.0.2` command
- **THEN** release notes are extracted from CHANGELOG.md section for version 0.0.2
- **THEN** GitHub release is created with title "v0.0.2"

#### Scenario: Release notes extraction
- **WHEN** extracting release notes for version 0.0.2
- **THEN** system reads content between `## [0.0.2]` and next version heading in CHANGELOG.md
- **THEN** system passes this content to `gh release create --notes` parameter

#### Scenario: GitHub release failure
- **WHEN** `gh release create` fails (authentication, network, permissions)
- **THEN** system displays error message with details from gh CLI
- **THEN** git tag remains on remote (manual cleanup required)

### Requirement: Atomic commit for version and changelog
The system SHALL commit the VERSION and CHANGELOG.md changes together with a standardized commit message before creating the git tag.

#### Scenario: Commit release changes
- **WHEN** VERSION file is updated to 0.0.2 and CHANGELOG.md is updated
- **THEN** system stages both files
- **THEN** system creates commit with message "Release v0.0.2"
- **THEN** commit is pushed to remote before tag is pushed

#### Scenario: Commit before tag
- **WHEN** release workflow executes
- **THEN** version/changelog commit is created before tag
- **THEN** tag points to the commit containing version changes

### Requirement: Non-interactive mode support
The system SHALL support non-interactive execution where version type is provided as a command argument, bypassing the interactive dropdown.

#### Scenario: Command-line version argument
- **WHEN** user runs `brigit release patch`
- **THEN** system uses "patch" as version type without prompting
- **THEN** release workflow proceeds automatically

#### Scenario: Invalid version argument
- **WHEN** user runs `brigit release invalid`
- **THEN** system displays error "Error: Invalid release type. Use patch, minor, or major."
- **THEN** system exits with non-zero status code

#### Scenario: CI/CD usage
- **WHEN** brigit release is executed in non-interactive environment with version argument
- **THEN** system detects non-interactive mode
- **THEN** no interactive prompts are shown
- **THEN** release completes automatically

### Requirement: Rollback on failure
The system SHALL maintain transactional behavior where failures during the release process do not leave the repository in a partially released state.

#### Scenario: Failure before git commit
- **WHEN** release fails during version calculation or changelog update
- **THEN** VERSION and CHANGELOG.md are not modified
- **THEN** no git operations are performed

#### Scenario: Failure after commit but before tag
- **WHEN** release fails after committing but before creating tag
- **THEN** commit exists on remote
- **THEN** no git tag is created
- **THEN** user can manually revert commit or retry with `git reset`

#### Scenario: Failure after tag but before GitHub release
- **WHEN** git tag is pushed but GitHub release creation fails
- **THEN** git tag exists on remote
- **THEN** user can manually create GitHub release or delete tag and retry

### Requirement: Output and confirmation
The system SHALL display progress information during the release process and SHALL show a success message with the release URL upon completion.

#### Scenario: Progress indicators
- **WHEN** release is in progress
- **THEN** system displays current step (e.g., "Updating VERSION file...", "Creating git tag...", "Pushing to GitHub...")

#### Scenario: Success confirmation
- **WHEN** release completes successfully
- **THEN** system displays "Release v0.0.2 created successfully!"
- **THEN** system displays GitHub release URL
- **THEN** system exits with status code 0

#### Scenario: Error messages
- **WHEN** any step fails
- **THEN** system displays clear error message indicating which step failed and why
- **THEN** system exits with non-zero status code

