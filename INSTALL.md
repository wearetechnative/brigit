# Installation Guide

This guide covers different installation methods for brigit.

## Prerequisites

brigit requires the following tools to be installed and available in your PATH:

### Required Tools

1. **GitHub CLI (`gh`)**
   - Used for GitHub API interactions
   - Must be authenticated (`gh auth login`)
   - Installation: https://cli.github.com/

2. **jq**
   - JSON processor for parsing API responses
   - Installation:
     - Debian/Ubuntu: `apt install jq`
     - macOS: `brew install jq`
     - Other: https://stedolan.github.io/jq/download/

3. **gum**
   - Terminal UI toolkit for interactive features
   - Installation:
     - Nix: `nix-env -iA nixpkgs.gum`
     - Homebrew: `brew install gum`
     - Other: https://github.com/charmbracelet/gum

4. **Bash**
   - Shell interpreter (usually pre-installed)
   - Version 4.0 or higher recommended

### Authentication

Before using brigit, authenticate with GitHub CLI:

```bash
gh auth login
```

## Installation Methods

### Option 1: Nix Flakes (Recommended)

Nix Flakes provides the easiest installation method as it automatically handles all dependencies.

#### Prerequisites for Nix

- Nix package manager installed (https://nixos.org/download.html)
- Flakes enabled in your Nix configuration

Enable Flakes (if not already enabled):

```bash
# Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
experimental-features = nix-command flakes
```

#### Run Directly (No Installation)

Run brigit without installing:

```bash
nix run github:wearetechnative/brigit -- version
nix run github:wearetechnative/brigit -- scan -o my-org
```

#### Install to User Profile

Install brigit permanently:

```bash
nix profile install github:wearetechnative/brigit
```

After installation, brigit is available globally:

```bash
brigit version
```

#### Use in Development Shell

Create a temporary environment with brigit:

```bash
nix shell github:wearetechnative/brigit
brigit version
```

#### Local Development

Clone the repository and use locally:

```bash
git clone https://github.com/wearetechnative/brigit
cd brigit

# Run directly
nix run .#brigit -- version

# Enter development shell
nix develop

# Build the package
nix build .#brigit
./result/bin/brigit version
```

### Option 2: NixOS System Configuration

Add brigit to your NixOS system configuration:

```nix
# In your configuration.nix or flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    brigit.url = "github:wearetechnative/brigit";
  };

  outputs = { self, nixpkgs, brigit }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [
            brigit.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch
```

### Option 3: Home Manager

Add brigit to your Home Manager configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    brigit.url = "github:wearetechnative/brigit";
  };

  outputs = { self, nixpkgs, home-manager, brigit }: {
    homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        {
          home.packages = [
            brigit.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

Then apply the configuration:

```bash
home-manager switch
```

### Option 4: Manual Installation

If you prefer not to use Nix, install manually:

#### 1. Install Prerequisites

Ensure all required tools are installed (see Prerequisites section above).

#### 2. Clone Repository

```bash
git clone https://github.com/wearetechnative/brigit
cd brigit
```

#### 3. Make Executable

```bash
chmod +x brigit
```

#### 4. Create Symbolic Link (Optional)

Create a symbolic link in your PATH:

```bash
sudo ln -s "$(pwd)/brigit" /usr/local/bin/brigit
```

Or add the brigit directory to your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/brigit"
```

#### 5. Verify Installation

```bash
brigit version
```

## Configuration

### Branch Protection Rules

After installation, create or modify `ghbranchprotection.json` in the brigit directory:

```json
{
  "default": {
    "required_pull_request_reviews": {
      "required_approving_review_count": 1,
      "dismiss_stale_reviews": false,
      "require_code_owner_reviews": false
    },
    "required_status_checks": null,
    "enforce_admins": false,
    "restrictions": null
  }
}
```

**Note:** When using Nix installation, the default configuration is automatically included.

### Repository Ignore List (Optional)

Create a `repos-ignore.txt` file to skip specific repositories:

```bash
# Format: org:repo (one per line)
technative-mcs:deprecated-repo
technative-mcs:test-repository
```

For Nix installations, create this file in your working directory.

## Verification

After installation, verify brigit is working:

```bash
# Check version
brigit version

# View help
brigit

# Test with a scan (requires GitHub authentication)
brigit scan -o your-organization
```

## Updating

### Nix Installation

Update to the latest version:

```bash
nix profile upgrade brigit
```

Or for direct runs:

```bash
nix run github:wearetechnative/brigit -- version
```

Nix will automatically fetch the latest version.

### Manual Installation

Update by pulling the latest changes:

```bash
cd /path/to/brigit
git pull origin main
```

## Troubleshooting

### GitHub CLI Not Authenticated

```
Error: GitHub CLI is not authenticated
```

**Solution:** Run `gh auth login` and follow the prompts.

### Missing Dependencies

```
Error: jq is required but not installed
Error: gum is required but not installed
```

**Solution:** Install missing dependencies (see Prerequisites section).

### Permission Denied

```
Error: Repository not found or you don't have access
```

**Solution:** Ensure your GitHub account has the necessary permissions for the organization/repositories.

### Nix Flakes Not Enabled

```
error: experimental Nix feature 'flakes' is disabled
```

**Solution:** Enable Flakes in your Nix configuration (see Nix Prerequisites section).

## Uninstallation

### Nix Installation

```bash
nix profile remove brigit
```

### Manual Installation

```bash
# Remove symbolic link
sudo rm /usr/local/bin/brigit

# Remove repository
rm -rf /path/to/brigit
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/wearetechnative/brigit/issues
- Documentation: https://github.com/wearetechnative/brigit

## Next Steps

After installation, see the main [README.md](README.md) for usage examples and workflows.
