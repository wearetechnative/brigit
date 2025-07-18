#!/bin/bash

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
    
    # Get protection settings from config file
    local protection_config=$(jq -c --arg org "$org" --arg repo "$repo" '.[$org][$repo] // .default' "$CONFIG_FILE")
    
    # If no specific config and no default, use empty config
    if [ "$protection_config" == "null" ]; then
        echo "No protection configuration found for $org/$repo and no default configuration."
        return 1
    fi
    
    # Apply branch protection using GitHub API via gh CLI
    echo "$protection_config" | gh api --method PUT "/repos/$org/$repo/branches/main/protection" --input - \
        && echo "✅ Branch protection applied successfully for $org/$repo" \
        || echo "❌ Failed to apply branch protection for $org/$repo"
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
    # No file provided, process all repositories from config file
    jq -r 'keys[]' "$CONFIG_FILE" | while read -r org; do
        # Skip default key if it exists
        if [ "$org" == "default" ]; then
            continue
        fi
        
        jq -r --arg org "$org" '.[$org] | keys[]' "$CONFIG_FILE" | while read -r repo; do
            apply_branch_protection "$org" "$repo"
        done
    done
fi

echo "Branch protection setup completed."
