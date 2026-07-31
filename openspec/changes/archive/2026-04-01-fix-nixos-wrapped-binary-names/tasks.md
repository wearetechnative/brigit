## 1. Modify package.nix structure

- [x] 1.1 Change brigit installation target from $out/bin/brigit to $out/share/brigit/brigit
- [x] 1.2 Remove existing wrapProgram call
- [x] 1.3 Add makeWrapper invocation to create $out/bin/brigit wrapper
- [x] 1.4 Add --argv0 brigit flag to makeWrapper
- [x] 1.5 Preserve existing --prefix PATH setting in makeWrapper
- [x] 1.6 Preserve existing --set BRIGIT_LIB_DIR setting in makeWrapper
- [x] 1.7 Verify all files still installed to share/brigit (_lib.sh, VERSION, etc.)

## 2. Build and test Nix package

- [x] 2.1 Build package with nix build .#brigit
- [x] 2.2 Verify build succeeds without errors
- [x] 2.3 Check that $out/bin/brigit exists and is executable
- [x] 2.4 Check that $out/share/brigit/brigit exists
- [x] 2.5 Verify wrapper is a shell script (not the actual brigit script)

## 3. Test binary naming

- [x] 3.1 Install built package to test environment
- [x] 3.2 Run `brigit version` and verify it works
- [x] 3.3 Start brigit in background and check `ps aux | grep brigit`
- [x] 3.4 Verify process name shows "brigit" not ".brigit-wrapped"
- [x] 3.5 Run `which brigit` and verify path ends with /bin/brigit

## 4. Test log file naming

- [x] 4.1 Run `brigit scan` command in test repository
- [x] 4.2 Verify log file created matches pattern brigit-scan-YYYYMMDD_HHMMSS.log
- [x] 4.3 Verify log file does NOT contain ".brigit-wrapped" in name
- [x] 4.4 Run `brigit enforce` command in test repository
- [x] 4.5 Verify log file created matches pattern brigit-enforce-YYYYMMDD_HHMMSS.log

## 5. Test functionality preservation

- [x] 5.1 Verify `brigit version` shows correct version from VERSION file
- [x] 5.2 Verify `brigit --help` displays help text correctly
- [x] 5.3 Test that _lib.sh is loaded (check BRIGIT_LIB_DIR is set)
- [x] 5.4 Test that gh is available in PATH
- [x] 5.5 Test that jq is available in PATH
- [x] 5.6 Test that gum is available in PATH
- [x] 5.7 Run full brigit scan workflow and verify it completes

## 6. Verify documentation accuracy

- [x] 6.1 Check README.md examples reference "brigit" (not wrapped name)
- [x] 6.2 Verify help text shows "brigit <command>" format
- [x] 6.3 Update documentation if any references to wrapped names exist

## 7. Final validation

- [x] 7.1 Compare behavior with pre-fix version (dev environment)
- [x] 7.2 Confirm all test scenarios from specs pass
- [x] 7.3 Test installation on clean system
- [x] 7.4 Verify no breaking changes to user workflow
