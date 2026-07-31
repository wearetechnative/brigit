## 1. Verify current implementation

- [x] 1.1 Confirm config file location logic is implemented in brigit script
- [x] 1.2 Verify user config directory check works
- [x] 1.3 Verify system default fallback works
- [x] 1.4 Test that user config takes precedence when both exist

## 2. Read and document default config

- [x] 2.1 Read ghbranchprotection.json to understand default settings
- [x] 2.2 Document each JSON field and its purpose
- [x] 2.3 Identify which settings users commonly customize

## 3. Add configuration documentation to README

- [x] 3.1 Create "Configuration" section in README.md
- [x] 3.2 Explain config file search order (user first, then system)
- [x] 3.3 Document system default location for Nix: /nix/store/<hash>-brigit-<version>/share/brigit/ghbranchprotection.json
- [x] 3.4 Document user config location: ~/.config/brigit/ghbranchprotection.json
- [x] 3.5 Add example command to copy config: mkdir -p ~/.config/brigit && cp /nix/store/*-brigit-*/share/brigit/ghbranchprotection.json ~/.config/brigit/
- [x] 3.6 Show default JSON settings and explain each field
- [x] 3.7 Add note about read-only Nix store limitation

## 4. Update Development section

- [x] 4.1 Remove "development mode" terminology (confusing for NIX-only)
- [x] 4.2 Clarify that script works from git clone directory
- [x] 4.3 Explain NIX installation vs local clone usage

## 5. Test and validate

- [x] 5.1 Test with user config present - verify it's used
- [x] 5.2 Test without user config - verify system default used
- [x] 5.3 Verify copy command in docs works correctly
- [x] 5.4 Check all documentation is accurate

## 6. Final review

- [x] 6.1 Ensure all requirements from specs are met
- [x] 6.2 Verify documentation is clear and complete
- [x] 6.3 Check for any broken links or examples
