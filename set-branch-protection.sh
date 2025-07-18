#!/usr/bin/env bash

# Script to set branch protection for GitHub repositories based on ghbranchprotection.json configuration
# Usage: ./set-branch-protection.sh [-f file_path]

# Default values
CONFIG_FILE="ghbranchprotection.json"
REPOS_FILE=""

# Function to display usage information
usage() {
    echo "Usage: $0 [-f repos_file]"
    echo "  -f repos_file    Path to a text file containing repositories in format <org>:<repo> (one per line)"
    echo "  -h               Display this help message"
    exit 1
}

# Parse command line arguments
while getopts "f:h" opt; do
    case ${opt} in
        f)
            REPOS_FILE=$OPTARG
            ;;
        h)
            usage
            ;;
        \?)
            usage
            ;;
    esac
done

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq."
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is required but not installed. Please install gh and authenticate."
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: GitHub CLI is not authenticated. Please run 'gh auth login' first."
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
fi

# Function to apply branch protection to a repository
apply_branch_protection() {
    local org=$1
    local repo=$2
    
    echo "Setting branch protection for $org/$repo..."
    
    # Get protection settings from config file - use default configuration
    local protection_config=$(jq -c '.default' "$CONFIG_FILE")
    
    # If no default config, exit with error
    if [ "$protection_config" == "null" ]; then
        echo "No default protection configuration found in $CONFIG_FILE."
        return 1
    fi
    
    # First check if the branch exists
    if ! gh api "/repos/$org/$repo/branches/main" &>/dev/null; then
        echo "❌ Branch 'main' does not exist in repository $org/$repo"
        return 1
    fi
    
    # Apply branch protection using GitHub API via gh CLI
    # First, ensure the JSON is properly formatted with all required fields
    local complete_config=$(echo "$protection_config" | jq '{
        required_status_checks: .required_status_checks,
        enforce_admins: .enforce_admins,
        required_pull_request_reviews: {
            required_approving_review_count: (.required_pull_request_reviews.required_approving_review_count // 1),
            dismiss_stale_reviews: (.required_pull_request_reviews.dismiss_stale_reviews // false),
            require_code_owner_reviews: (.required_pull_request_reviews.require_code_owner_reviews // false)
        },
        restrictions: .restrictions
    }')
    
    echo "Applying configuration: $(echo "$complete_config" | jq -c '.')"
    response=$(echo "$complete_config" | gh api --method PUT "/repos/$org/$repo/branches/main/protection" --input - 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Branch protection applied successfully for $org/$repo"
        echo "   Configuration applied: $(echo "$protection_config" | jq -c '.')"
        
        # Verify the protection was applied correctly
        verify_response=$(gh api "/repos/$org/$repo/branches/main/protection" 2>/dev/null)
        verify_exit=$?
        if [ $verify_exit -eq 0 ]; then
            echo "   Verification successful: protection is enabled"
            echo "   Protection details: $(echo "$verify_response" | jq -c '.required_pull_request_reviews')"
        else
            echo "   ⚠️ Warning: Could not verify protection status (exit code: $verify_exit)"
        fi
    else
        echo "❌ Failed to apply branch protection for $org/$repo"
        
        # Check for specific error messages
        if echo "$response" | grep -q "Upgrade to GitHub Pro"; then
            echo "   Error: Branch protection requires GitHub Pro for private repositories."
            echo "   Options: 1) Make the repository public, or 2) Upgrade to GitHub Pro"
        elif echo "$response" | grep -q "Not Found"; then
            echo "   Error: Repository not found or you don't have sufficient permissions."
        else
            echo "   Error details: $response"
        fi
    fi
}

# Process repositories
if [ -n "$REPOS_FILE" ]; then
    # Check if repos file exists
    if [ ! -f "$REPOS_FILE" ]; then
        echo "Error: Repositories file $REPOS_FILE not found."
        exit 1
    fi
    
    # Read repositories from file
    while IFS=: read -r org repo; do
        # Skip empty lines or lines with invalid format
        if [ -z "$org" ] || [ -z "$repo" ]; then
            continue
        fi
        
        # Remove any trailing whitespace
        org=$(echo "$org" | tr -d '[:space:]')
        repo=$(echo "$repo" | tr -d '[:space:]')
        
        apply_branch_protection "$org" "$repo"
    done < "$REPOS_FILE"
else
    # No file provided, prompt for organization and repository
    read -p "Enter organization name: " org
    read -p "Enter repository name: " repo
    
    # Validate input
    if [ -z "$org" ] || [ -z "$repo" ]; then
        echo "Error: Organization and repository names cannot be empty."
        exit 1
    fi
    
    apply_branch_protection "$org" "$repo"
fi

echo "Branch protection setup completed."
