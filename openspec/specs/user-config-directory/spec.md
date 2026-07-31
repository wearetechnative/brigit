# user-config-directory Specification

## Purpose
TBD - created by archiving change user-config-directory-support. Update Purpose after archive.
## Requirements
### Requirement: Support user-specific config directory
The system SHALL check for a user-specific configuration file in the XDG-compliant location before using the system default configuration.

#### Scenario: User config exists and is used
- **WHEN** file exists at `~/.config/brigit/ghbranchprotection.json`
- **THEN** brigit SHALL use this file for configuration
- **THEN** brigit SHALL NOT use the system default config

#### Scenario: User config does not exist, use system default
- **WHEN** file does NOT exist at `~/.config/brigit/ghbranchprotection.json`
- **THEN** brigit SHALL use `$SCRIPT_DIR/ghbranchprotection.json`
- **THEN** brigit SHALL function normally with system defaults

#### Scenario: Config search order is documented
- **WHEN** user reads documentation
- **THEN** documentation SHALL clearly state config search order
- **THEN** documentation SHALL show both config file locations

### Requirement: Config file location follows XDG specification
The user configuration directory SHALL follow the XDG Base Directory specification for configuration files.

#### Scenario: Config in standard XDG location
- **WHEN** user wants to customize config
- **THEN** config file SHALL be placed in `~/.config/brigit/`
- **THEN** this location SHALL be consistent with other XDG-compliant tools

### Requirement: System default config is accessible
Users SHALL be able to locate and copy the system default configuration file.

#### Scenario: Nix installation shows system config location
- **WHEN** brigit is installed via Nix flake
- **THEN** system config SHALL be at `/nix/store/<hash>-brigit-<version>/share/brigit/ghbranchprotection.json`
- **THEN** this location SHALL be documented

#### Scenario: User can copy system config
- **WHEN** user wants to customize config
- **THEN** user SHALL be able to copy system default to user location
- **THEN** documentation SHALL provide copy command example

### Requirement: Default configuration settings are documented
The default branch protection settings SHALL be documented so users understand what they are customizing.

#### Scenario: Documentation shows default settings
- **WHEN** user reads configuration documentation
- **THEN** documentation SHALL list all default JSON settings
- **THEN** documentation SHALL explain what each setting does

#### Scenario: Default config enforces protection
- **WHEN** using system default config without customization
- **THEN** branch protection rules SHALL be enforced as specified in default JSON
- **THEN** behavior SHALL match documented defaults

### Requirement: No breaking changes to existing installations
Existing brigit installations SHALL continue to work without modification.

#### Scenario: Existing installation without user config
- **WHEN** brigit is already installed and no user config exists
- **THEN** brigit SHALL continue using system default
- **THEN** behavior SHALL be unchanged from previous version

#### Scenario: Backward compatibility maintained
- **WHEN** brigit is updated to support user config
- **THEN** users SHALL NOT need to make any changes
- **THEN** system default config SHALL work as before

### Requirement: Configuration documentation is complete
Documentation SHALL provide clear instructions for config customization and explain config file locations.

#### Scenario: README has configuration section
- **WHEN** user reads README.md
- **THEN** there SHALL be a "Configuration" section
- **THEN** section SHALL explain user vs system config
- **THEN** section SHALL show copy command and location paths

#### Scenario: Nix-specific instructions provided
- **WHEN** user installs brigit via Nix
- **THEN** documentation SHALL explain read-only Nix store limitation
- **THEN** documentation SHALL show exact Nix store path pattern
- **THEN** documentation SHALL explain how to customize config for Nix

