## Context

Nix's `wrapProgram` utility is used to inject environment variables and PATH modifications into executables. It works by:
1. Renaming the original binary to `.<name>-wrapped`
2. Creating a wrapper shell script at the original name
3. The wrapper sets environment, then executes the wrapped binary

However, when scripts use `$0` or `basename $0` to determine their name (for log files, process names, etc.), they see `.brigit-wrapped` instead of `brigit`.

Current brigit implementation:
- Uses `wrapProgram` in package.nix installPhase
- Sets PATH and BRIGIT_LIB_DIR via wrapper
- Scripts reference `$0` for naming log files

Alternative approach used by many Nix packages:
- Use `symlinkJoin` to combine the unwrapped binary with a wrapper
- Use `makeWrapper` to create a wrapper that preserves the binary name
- Set `pname` in the wrapper metadata

## Goals / Non-Goals

**Goals:**
- Binary shows as `brigit` (not `.brigit-wrapped`) in ps/top
- Log files use `brigit-scan-*.log` naming pattern
- Examples and documentation show correct binary name
- Preserve all current functionality (PATH, environment variables)
- No changes to user invocation (`brigit` command still works)

**Non-Goals:**
- Changing the actual script logic or functionality
- Modifying how log files are generated (keep current pattern)
- Supporting non-Nix installations differently (only fix Nix)

## Decisions

### Decision 1: Use makeWrapper with --argv0 flag

**Options:**
- **Option A**: Use `symlinkJoin` + `makeWrapper` with `--argv0`
- **Option B**: Modify brigit script to detect wrapped name and normalize it
- **Option C**: Use `substituteInPlace` to hardcode the binary name in the script

**Choice**: Option A (makeWrapper with --argv0)

**Rationale**:
- `--argv0` flag explicitly sets what appears in `$0`
- Clean separation: Nix handles naming, script remains unchanged
- Standard Nix pattern used by other packages
- No runtime detection overhead
- Script works identically in dev and Nix environments

**Implementation**:
```nix
makeWrapper $out/share/brigit/brigit $out/bin/brigit \
  --argv0 brigit \
  --prefix PATH : ${...} \
  --set BRIGIT_LIB_DIR $out/share/brigit
```

**Trade-offs**:
- Requires moving original binary to share/ directory
- Wrapper becomes the main executable
- Slightly more complex package.nix structure

### Decision 2: Move unwrapped binary to share directory

**Options:**
- **Option A**: Install to share/brigit/, create wrapper in bin/
- **Option B**: Keep both in bin/, use different name for wrapped version
- **Option C**: Use symlinkJoin to merge directories

**Choice**: Option A (share directory for unwrapped)

**Rationale**:
- Follows Nix conventions (executables in bin/, libraries/support in share/)
- Clear separation between wrapper (bin/) and actual script (share/)
- Prevents accidental direct execution of unwrapped binary
- Consistent with how _lib.sh is already installed

**Structure**:
```
$out/
├── bin/
│   └── brigit (wrapper created by makeWrapper)
└── share/brigit/
    ├── brigit (actual script)
    ├── _lib.sh
    ├── VERSION
    └── ...
```

### Decision 3: No changes to brigit script itself

**Options:**
- **Option A**: Keep script unchanged, fix in package.nix only
- **Option B**: Add runtime detection and normalization in script

**Choice**: Option A (no script changes)

**Rationale**:
- Problem is Nix packaging specific, not script logic issue
- Script already works correctly in dev environment
- Simpler: single fix point in package.nix
- Easier to test: just rebuild Nix package
- Future-proof: if Nix changes, only package.nix needs update

## Risks / Trade-offs

**Risk**: makeWrapper might not set $0 correctly in all contexts
- **Mitigation**: --argv0 is a documented feature, widely used in nixpkgs
- **Validation**: Test actual binary name in logs after installation

**Risk**: Moving binary to share/ might break SCRIPT_DIR detection
- **Mitigation**: brigit already uses BRIGIT_LIB_DIR env var set by wrapper
- **Validation**: Test that _lib.sh and VERSION are still found

**Risk**: Wrapper adds minimal startup overhead
- **Trade-off**: Accepted - negligible performance impact (~1ms)
- **Benefit**: Proper binary naming worth the overhead

**Trade-off**: Package.nix becomes slightly more complex
- **Benefit**: Script remains simple and testable outside Nix
- **Benefit**: Clear separation of concerns

**Trade-off**: Two copies of brigit binary (share/ + wrapper in bin/)
- **Impact**: Minimal disk space (~50KB extra)
- **Benefit**: Clean installation structure following Nix conventions

## Migration Plan

### Implementation Steps
1. Modify package.nix installPhase:
   - Install brigit to `$out/share/brigit/brigit` (not bin/)
   - Use makeWrapper to create `$out/bin/brigit` wrapper
   - Add `--argv0 brigit` to makeWrapper call
   - Keep existing PATH and BRIGIT_LIB_DIR settings

2. Test in Nix environment:
   - Build package: `nix build .#brigit`
   - Verify binary name: `ps aux | grep brigit` (should show `brigit`)
   - Run scan: `brigit scan ...`
   - Check log file naming: `ls brigit-scan-*.log`
   - Verify version works: `brigit version`

3. No migration needed for users:
   - Installation method unchanged
   - Command invocation unchanged (`brigit` still works)
   - Existing configs still valid

### Rollback Strategy
If issues occur:
- Revert package.nix changes
- Rebuild and reinstall
- Previous functionality fully preserved

### Validation
- ✓ Binary name appears as `brigit` in process list
- ✓ Log files named `brigit-scan-*.log` (not `.brigit-wrapped-scan-*.log`)
- ✓ All commands work identically
- ✓ Examples in documentation are accurate
- ✓ VERSION file still accessible
- ✓ _lib.sh still loads correctly

## Open Questions

1. Should we also update INSTALL.md to clarify the Nix package naming behavior?
   - **Decision**: Only if examples were incorrect; otherwise documentation already accurate

2. Do we need to update any tests?
   - **Decision**: No, tests run against unwrapped script in dev environment
