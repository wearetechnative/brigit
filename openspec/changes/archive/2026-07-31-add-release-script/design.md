## Context

Brigit is a bash-based CLI tool for managing GitHub branch protection. It currently uses:
- Manual version management in a VERSION file
- Manual CHANGELOG.md updates following Keep a Changelog format
- Nix flakes for packaging (package.nix reads VERSION file)
- `gh` CLI for GitHub API operations
- `gum` for interactive terminal UI
- Existing command structure in main `brigit` script with command registration pattern

The project needs an automated release workflow to reduce human error and ensure consistent releases. The release script must integrate with the existing toolchain and follow established patterns in the codebase.

## Goals / Non-Goals

**Goals:**
- Automated version bumping following semantic versioning (patch/minor/major)
- Automated changelog updates maintaining Keep a Changelog format
- Git safety checks preventing releases from dirty repositories
- Atomic git operations (commit → tag → push → GitHub release)
- Interactive mode using gum for developer-friendly experience
- Non-interactive mode for CI/CD integration
- Integration with existing brigit command structure
- Clear error messages and progress feedback

**Non-Goals:**
- Automated determination of version bump type (requires human judgment)
- Changelog entry content generation (user manages this manually before release)
- Multi-branch release support (only supports releases from main/current branch)
- Release rollback automation (manual git operations if needed)
- Pre-release or beta version support (X.Y.Z only)
- Integration with other package managers beyond Nix

## Decisions

### Decision 1: Command structure - New command vs. separate script

**Options:**
- **Option A**: Add `release` as a new command in main `brigit` script
- **Option B**: Create separate standalone `git-release` script

**Choice**: Option B (standalone script)

**Rationale**:
- Generic script can be used in any git repository, not just brigit
- Keeps brigit focused on its core purpose (branch protection)
- Release automation is a separate concern from branch protection
- Script can be distributed and used independently
- Simpler to test and maintain as standalone tool
- No coupling to brigit's command structure

**Trade-offs**: Requires separate installation/distribution, but provides more flexibility and reusability.

### Decision 2: Version file format and location

**Options:**
- **Option A**: Keep VERSION file with simple `X.Y.Z\n` format
- **Option B**: Use JSON/YAML for version metadata
- **Option C**: Embed version in multiple files (brigit script, package.nix, etc.)

**Choice**: Option A (simple VERSION file)

**Rationale**:
- Already established in project
- Simple to parse with bash (read single line)
- Simple to write (echo to file)
- package.nix already reads this file
- Follows Unix philosophy: one file, one purpose

**Trade-offs**: No metadata storage (release date, notes), but CHANGELOG.md serves that purpose.

### Decision 3: Changelog update strategy

**Options:**
- **Option A**: Replace `## [Unreleased]` header with version and date, add new Unreleased
- **Option B**: Append new version section, leave Unreleased
- **Option C**: Use changelog generation tool (changelog-cli, etc.)

**Choice**: Option A (header replacement)

**Rationale**:
- Matches Keep a Changelog conventions
- Simple sed/awk operation
- Users maintain Unreleased section as they work
- Release script just finalizes the version
- No external dependencies

**Implementation approach**:
```bash
# Find and replace first occurrence of [Unreleased]
sed -i "0,/## \[Unreleased\]/s//## [${VERSION}] - ${DATE}\n\n## [Unreleased]/" CHANGELOG.md
```

### Decision 4: Git workflow - Commit, tag, push order

**Options:**
- **Option A**: Commit → Push → Tag → Push tag → GitHub release
- **Option B**: Commit → Tag locally → Push commit and tag together → GitHub release
- **Option C**: Tag → Commit → Push

**Choice**: Option B (commit, tag locally, push together)

**Rationale**:
- Tag should point to commit containing version changes
- Single push operation is more atomic (both commit and tag or neither)
- Reduces window where remote state is inconsistent
- Matches git best practices

**Sequence**:
1. Modify VERSION and CHANGELOG.md files
2. `git add VERSION CHANGELOG.md`
3. `git commit -m "Release v${VERSION}"`
4. `git tag -a "v${VERSION}" -m "Release v${VERSION}"`
5. `git push && git push --tags`
6. `gh release create v${VERSION} --notes-file <extracted notes>`

### Decision 5: Interactive vs. non-interactive mode detection

**Options:**
- **Option A**: Use existing `detect_interactive` function from `_lib.sh`
- **Option B**: Check for command argument (brigit release patch)
- **Option C**: Use flag (brigit release --type patch)

**Choice**: Hybrid approach - Option B (argument) with Option A (detection)

**Rationale**:
- If argument provided: use it (supports CI/CD: `brigit release patch`)
- If no argument and interactive: use gum dropdown
- If no argument and non-interactive: error (explicit intent required)

**Implementation**:
```bash
if [ -n "$1" ]; then
  RELEASE_TYPE=$1
elif $INTERACTIVE; then
  RELEASE_TYPE=$(gum choose "patch" "minor" "major")
else
  echo "Error: Release type required in non-interactive mode"
  exit 1
fi
```

### Decision 6: Error handling and rollback strategy

**Options:**
- **Option A**: Explicit rollback on any failure
- **Option B**: Fail-fast with clear state description
- **Option C**: Transactional with full rollback

**Choice**: Option B (fail-fast with clear state)

**Rationale**:
- Git operations are easy to inspect and manually rollback if needed
- Automatic rollback is complex and risky (could make things worse)
- Clear error messages guide users on recovery
- Early exit prevents partial state

**Failure points and recovery**:
| Failure Point | State | Recovery |
|---------------|-------|----------|
| Dirty repo check | No changes | Fix working tree, retry |
| Version parsing | No changes | Fix VERSION file format |
| Changelog update | VERSION modified | Restore VERSION, fix CHANGELOG |
| Git commit | Files staged | `git reset HEAD`, restore files |
| Git tag | Commit on local | Delete tag, reset commit |
| Git push | Commit and tag local | Delete tag, reset commit, retry |
| GitHub release | Tag on remote | Manually create release or delete tag |

### Decision 7: Release notes extraction from CHANGELOG.md

**Options:**
- **Option A**: Extract section between version headers using sed/awk
- **Option B**: User provides release notes manually
- **Option C**: Generate notes from commit messages

**Choice**: Option A (extract from CHANGELOG.md)

**Rationale**:
- CHANGELOG.md is already maintained with release info
- Users write release notes as they work (in Unreleased section)
- Extraction ensures GitHub release matches CHANGELOG
- Simple text processing with standard tools

**Implementation**:
```bash
# Extract content between [VERSION] and next [VERSION] or end of file
awk "/## \[${VERSION}\]/,/## \[/" CHANGELOG.md | sed '1d;$d' > release-notes.tmp
gh release create "v${VERSION}" --notes-file release-notes.tmp
rm release-notes.tmp
```

### Decision 8: Semantic version calculation

**Options:**
- **Option A**: Use external tool (semver-tool, npm semver)
- **Option B**: Implement in bash with IFS parsing
- **Option C**: Use Python/Ruby one-liner

**Choice**: Option B (bash implementation)

**Rationale**:
- No additional dependencies
- Simple logic: split on `.`, increment appropriate field, reset others
- Bash string manipulation is sufficient
- Keeps everything in bash ecosystem

**Implementation**:
```bash
IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
case $RELEASE_TYPE in
  patch) patch=$((patch + 1)) ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  major) major=$((major + 1)); minor=0; patch=0 ;;
esac
NEW_VERSION="${major}.${minor}.${patch}"
```

## Risks / Trade-offs

**Risk**: User forgets to update CHANGELOG.md Unreleased section before release
- **Mitigation**: Add check that verifies Unreleased section is not empty
- **Alternative**: Warn user to review CHANGELOG before proceeding

**Risk**: Network failure during push leaves local and remote out of sync
- **Mitigation**: Clear error message guides manual recovery
- **Trade-off**: Automatic retry could help but adds complexity

**Risk**: VERSION file becomes out of sync with git tags
- **Mitigation**: Script is the only way to create releases (documented)
- **Trade-off**: No technical prevention, relies on convention

**Risk**: Flake.nix may need version sync if it hardcodes version
- **Mitigation**: Verify flake.nix reads from package.nix which reads VERSION
- **Verification needed**: Check if flake.nix has any hardcoded version references

**Risk**: Release notes extraction fails if CHANGELOG.md format is non-standard
- **Mitigation**: Document CHANGELOG.md format requirements
- **Alternative**: Fallback to empty notes if extraction fails

**Risk**: Interactive gum dropdown doesn't work in all terminals
- **Mitigation**: Always support command argument as fallback
- **Already handled**: Existing code uses detect_interactive pattern

**Trade-off**: No automated CHANGELOG content generation
- **Benefit**: Humans write better release notes than commit message aggregation
- **Cost**: Users must manually maintain Unreleased section

**Trade-off**: No rollback automation for failed releases
- **Benefit**: Simpler code, less risky (rollback could fail too)
- **Cost**: Manual recovery required, but git makes this straightforward

**Trade-off**: No support for pre-release versions (alpha, beta, rc)
- **Benefit**: Simpler version scheme, clearer release process
- **Cost**: Pre-releases must use different mechanism if needed

## Migration Plan

**Phase 1: Implementation**
1. Add `release` command to brigit script
2. Add version calculation logic
3. Add CHANGELOG.md update logic
4. Add git operations (commit, tag, push)
5. Add GitHub release creation
6. Add tests/dry-run validation

**Phase 2: Documentation**
1. Update README.md with release workflow
2. Add release command to help text
3. Document CHANGELOG.md format requirements
4. Add examples for both interactive and non-interactive usage

**Phase 3: Validation**
1. Test release script on a test repository
2. Verify VERSION file updates correctly
3. Verify CHANGELOG.md updates preserve format
4. Verify git operations work as expected
5. Verify GitHub release is created correctly

**Phase 4: Adoption**
1. Use release script for next brigit release
2. Document as preferred release method
3. Archive manual release instructions

**Rollback Strategy:**
If release script has critical issues:
1. Document manual release process as fallback
2. Fix release script issues
3. Test fixes in test repository
4. Re-enable automated releases

## Open Questions

1. **flake.nix version handling**: Does flake.nix have any hardcoded version references that need updating? Need to verify it properly inherits from package.nix.

2. **CHANGELOG validation**: Should we validate that Unreleased section has content before release? Or just trust the user?

3. **Nix flake lock updates**: Should release script also update flake.lock, or is that a separate concern?

4. **Release branch naming**: Current design assumes release from current branch. Should we enforce release from main branch only?

5. **Co-Authored-By for automated commits**: Should release commits include co-authorship trailers?
