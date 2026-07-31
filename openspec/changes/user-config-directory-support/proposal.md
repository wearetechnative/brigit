## Why

When brigit is installed via Nix, the config file `ghbranchprotection.json` is placed in the read-only Nix store (`/nix/store/<hash>-brigit-<version>/share/brigit/`). Users cannot modify this file to customize their branch protection rules, making the tool inflexible for different organizational needs.

## What Changes

- Add support for user-specific config file in `~/.config/brigit/ghbranchprotection.json`
- Search user config location first, fall back to system default
- Allow users to customize branch protection rules without modifying system files
- Maintain backward compatibility with existing installations

## Capabilities

### New Capabilities
- `user-config-directory`: Support for user-specific configuration files in XDG-compliant location

### Modified Capabilities
<!-- No existing capabilities are being modified -->

## Impact

**Modified Files**:
- `brigit`: Add config file location logic to check user directory first

**User Workflow Changes**:
- Users can now copy and customize config: `cp /nix/store/*-brigit-*/share/brigit/ghbranchprotection.json ~/.config/brigit/`
- No changes required for users who want to use default config

**Benefits**:
- Solves read-only Nix store limitation
- Follows XDG Base Directory specification
- No breaking changes to existing workflows
