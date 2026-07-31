## Why

When brigit is installed via Nix, the wrapProgram mechanism creates a `.brigit-wrapped` binary. This causes issues in examples and documentation where the binary name appears as `.brigit-wrapped` instead of `brigit`, and log files are generated with names like `.brigit-wrapped-scan-*.log` instead of `brigit-scan-*.log`. This breaks user expectations and makes the tool harder to use.

## What Changes

- Modify package.nix to use symlinkJoin instead of wrapProgram to preserve the binary name
- Ensure wrapped binary appears as `brigit` in ps/top output
- Ensure log files are created with `brigit-scan-*.log` naming pattern
- Verify examples show correct binary name
- Update documentation if needed

## Capabilities

### New Capabilities
- `nix-binary-naming`: Proper binary naming when installed via Nix package manager

### Modified Capabilities
<!-- No existing capabilities are being modified -->

## Impact

**Modified Files**:
- `package.nix`: Change from wrapProgram to symlinkJoin approach

**User Impact**:
- Positive: Binary name shows as `brigit` in all contexts
- Positive: Log files use expected naming pattern
- Positive: Examples work as documented
- No breaking changes: Command invocation remains the same

**Dependencies**:
- No new dependencies
- Same runtime dependencies (gh, jq, gum, bash)
