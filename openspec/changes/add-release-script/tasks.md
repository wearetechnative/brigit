## 1. Prerequisites and validation

- [x] 1.1 Verify flake.nix doesn't have hardcoded version references
- [x] 1.2 Verify package.nix correctly reads VERSION file for version metadata
- [x] 1.3 Test current VERSION file format and confirm it's X.Y.Z with newline

## 2. Command registration and structure

- [x] 2.1 Add `make_command "release" "Create and publish a GitHub release"` to brigit script
- [x] 2.2 Create `release()` function skeleton in brigit script
- [x] 2.3 Add release command to usage help text
- [x] 2.4 Test that `brigit release -h` shows help text

## 3. Version selection interface

- [x] 3.1 Implement release type argument parsing (brigit release patch/minor/major)
- [x] 3.2 Add validation for release type argument (reject invalid values)
- [x] 3.3 Implement interactive gum dropdown for version selection (when no argument provided)
- [x] 3.4 Add non-interactive mode detection and require explicit argument
- [x] 3.5 Test interactive mode with gum dropdown
- [x] 3.6 Test non-interactive mode with command argument

## 4. Version calculation logic

- [x] 4.1 Implement function to read current version from VERSION file
- [x] 4.2 Implement semantic version parsing (split on .)
- [x] 4.3 Implement patch version increment logic
- [x] 4.4 Implement minor version increment logic (reset patch to 0)
- [x] 4.5 Implement major version increment logic (reset minor and patch to 0)
- [x] 4.6 Test version calculation for all three types with various starting versions

## 5. Git repository safety checks

- [x] 5.1 Implement dirty repository check using `git status --porcelain`
- [x] 5.2 Allow untracked files but fail on modified tracked files
- [x] 5.3 Display clear error message when repository is dirty
- [x] 5.4 Exit with non-zero status code on dirty repository
- [x] 5.5 Test with clean repository (should pass)
- [x] 5.6 Test with modified files (should fail)
- [x] 5.7 Test with untracked files only (should pass)

## 6. VERSION file update

- [x] 6.1 Implement function to write new version to VERSION file
- [x] 6.2 Ensure VERSION file has single newline after version number
- [x] 6.3 Add progress message "Updating VERSION file..."
- [x] 6.4 Test VERSION file update with different version numbers

## 7. CHANGELOG.md automation

- [x] 7.1 Implement function to get current date in YYYY-MM-DD format
- [x] 7.2 Implement sed command to replace first `## [Unreleased]` with version and date
- [x] 7.3 Implement logic to add new `## [Unreleased]` header at top
- [x] 7.4 Test changelog update preserves existing version entries
- [x] 7.5 Test changelog update maintains markdown formatting
- [x] 7.6 Add progress message "Updating CHANGELOG.md..."
- [x] 7.7 Test with various CHANGELOG.md formats

## 8. Release notes extraction

- [x] 8.1 Implement awk/sed logic to extract version section from CHANGELOG.md
- [x] 8.2 Extract content between version header and next version header
- [x] 8.3 Write extracted notes to temporary file
- [x] 8.4 Test release notes extraction with sample CHANGELOG.md
- [x] 8.5 Handle edge case where version section is last in file

## 9. Git commit operation

- [x] 9.1 Stage VERSION and CHANGELOG.md files with `git add`
- [x] 9.2 Create commit with message "Release v${VERSION}"
- [x] 9.3 Add progress message "Creating release commit..."
- [x] 9.4 Test git commit creates commit with both files

## 10. Git tag creation

- [x] 10.1 Check if tag already exists with `git tag -l "v${VERSION}"`
- [x] 10.2 Fail with error if tag already exists
- [x] 10.3 Create annotated tag with `git tag -a "v${VERSION}" -m "Release v${VERSION}"`
- [x] 10.4 Add progress message "Creating git tag v${VERSION}..."
- [x] 10.5 Test tag creation with various version numbers
- [x] 10.6 Test duplicate tag detection

## 11. Git push operations

- [x] 11.1 Push commit to remote with `git push`
- [x] 11.2 Push tag to remote with `git push --tags`
- [x] 11.3 Add progress message "Pushing to GitHub..."
- [x] 11.4 Handle push failures with clear error messages
- [x] 11.5 Test push operations in test repository

## 12. GitHub release creation

- [x] 12.1 Execute `gh release create "v${VERSION}" --notes-file <notes-file>`
- [x] 12.2 Add progress message "Creating GitHub release..."
- [x] 12.3 Handle gh CLI authentication errors
- [x] 12.4 Handle network failures during release creation
- [x] 12.5 Clean up temporary release notes file
- [x] 12.6 Test GitHub release creation in test repository

## 13. Success confirmation and output

- [x] 13.1 Display success message "Release v${VERSION} created successfully!"
- [x] 13.2 Get GitHub release URL from gh CLI output
- [x] 13.3 Display GitHub release URL
- [x] 13.4 Exit with status code 0 on success
- [x] 13.5 Test full success path end-to-end

## 14. Error handling and edge cases

- [x] 14.1 Add error handling for VERSION file read failures
- [x] 14.2 Add error handling for CHANGELOG.md file not found
- [x] 14.3 Add error handling for invalid VERSION file format
- [x] 14.4 Test error handling for each failure point
- [x] 14.5 Ensure clear error messages for all failure scenarios

## 15. Documentation

- [x] 15.1 Update README.md with release command documentation
- [x] 15.2 Add release workflow section to README.md
- [x] 15.3 Document CHANGELOG.md format requirements
- [x] 15.4 Add examples for interactive and non-interactive usage
- [x] 15.5 Update INSTALL.md if needed for release script context

## 16. Testing and validation

- [x] 16.1 Create test script or manual test plan
- [x] 16.2 Test full release workflow in test repository with patch release
- [x] 16.3 Test full release workflow in test repository with minor release
- [x] 16.4 Test full release workflow in test repository with major release
- [x] 16.5 Verify VERSION file updates correctly in all scenarios
- [x] 16.6 Verify CHANGELOG.md updates correctly in all scenarios
- [x] 16.7 Verify git tag is created and pushed
- [x] 16.8 Verify GitHub release is created with correct notes
- [x] 16.9 Test all error conditions (dirty repo, invalid args, network failures)
- [x] 16.10 Validate that package.nix picks up new version from VERSION file
