#!/usr/bin/env bash

# Script to check branch protection for GitHub repositories against ghbranchprotection.json configuration
# Usage: ./check-branch-protection.sh [-o organization]

# Default values
CONFIG_FILE="ghbranchprotection.json"
ORGANIZATION=""

# Function to display usage information
usage() {
    echo "Usage: $0 [-o organization]"
    echo "  -o organization  GitHub organization to check repositories for"
    echo "  -h               Display this help message"
    exit 1
}

# Parse command line arguments
while getopts "o:h" opt; do
    case ${opt} in
        o)
            ORGANIZATION=$OPTARG
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

# If no organization provided, prompt for it
if [ -z "$ORGANIZATION" ]; then
    read -p "Enter GitHub organization name: " ORGANIZATION
    
    # Validate input
    if [ -z "$ORGANIZATION" ]; then
        echo "Error: Organization name cannot be empty."
        exit 1
    fi
fi

# Get expected branch protection configuration
expected_config=$(jq -c '.default' "$CONFIG_FILE")

# Function to check if branch protection matches expected configuration
check_branch_protection() {
    local org=$1
    local repo=$2
    
    echo "Checking branch protection for $org/$repo..."
    
    # Get current branch protection settings
    current_protection=$(gh api "/repos/$org/$repo/branches/main/protection" 2>/dev/null)
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo "❌ Failed to get branch protection for $org/$repo"
        echo "   This could be due to: no protection enabled, insufficient permissions, or repository doesn't exist"
        return 1
    fi
    
    # Extract the fields we care about from the current protection
    current_simplified=$(echo "$current_protection" | jq -c '{
        required_status_checks: .required_status_checks,
        enforce_admins: .enforce_admins.enabled,
        required_pull_request_reviews: {
            required_approving_review_count: .required_pull_request_reviews.required_approving_review_count
        },
        restrictions: .restrictions
    }')
    
    # Extract the same fields from expected config for comparison
    expected_simplified=$(echo "$expected_config" | jq -c '{
        required_status_checks: .required_status_checks,
        enforce_admins: .enforce_admins,
        required_pull_request_reviews: {
            required_approving_review_count: .required_pull_request_reviews.required_approving_review_count
        },
        restrictions: .restrictions
    }')
    
    # Compare configurations
    if [ "$current_simplified" = "$expected_simplified" ]; then
        echo "✅ Branch protection for $org/$repo matches expected configuration"
        return 0
    else
        echo "❌ Branch protection for $org/$repo does NOT match expected configuration"
        echo "   Expected: $expected_simplified"
        echo "   Current:  $current_simplified"
        return 1
    fi
}

# Get list of repositories in the organization
echo "Fetching repositories for organization: $ORGANIZATION..."
repos=$(gh repo list "$ORGANIZATION" --json name --limit 100 | jq -r '.[].name')

if [ -z "$repos" ]; then
    echo "No repositories found for organization $ORGANIZATION or you don't have access."
    exit 1
fi

# Check branch protection for each repository
echo "Found $(echo "$repos" | wc -l | tr -d ' ') repositories. Checking branch protection..."
echo

matching_count=0
non_matching_count=0
error_count=0

for repo in $repos; do
    if check_branch_protection "$ORGANIZATION" "$repo"; then
        matching_count=$((matching_count + 1))
    else
        if [ $? -eq 1 ]; then
            error_count=$((error_count + 1))
        else
            non_matching_count=$((non_matching_count + 1))
        fi
    fi
    echo
done

# Print summary
echo "Summary:"
echo "- Repositories with matching branch protection: $matching_count"
echo "- Repositories with non-matching branch protection: $non_matching_count"
echo "- Repositories with errors (no protection or access issues): $error_count"
echo "- Total repositories checked: $((matching_count + non_matching_count + error_count))"

# Exit with non-zero status if any repositories don't match
if [ $non_matching_count -gt 0 ]; then
    exit 1
fi

exit 0
