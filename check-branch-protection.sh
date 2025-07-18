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

# Function for spinning cursor animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to check if branch protection matches expected configuration
check_branch_protection() {
    local org=$1
    local repo=$2
    local error_msg=""
    
    printf "%-40s" "$repo"
    
    # Get current branch protection settings in background and capture PID
    current_protection=$(gh api "/repos/$org/$repo/branches/main/protection" 2>/dev/null) &
    local pid=$!
    spinner $pid
    wait $pid
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo "❌"
        error_msg="No protection enabled, insufficient permissions, or repository doesn't exist"
        error_repos+=("$repo: $error_msg")
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
        echo "✅"
        return 0
    else
        echo "❌"
        error_msg="Configuration mismatch - Expected: $expected_simplified, Current: $current_simplified"
        error_repos+=("$repo: $error_msg")
        return 2
    fi
}

# Get list of repositories in the organization
echo "Fetching repositories for organization: $ORGANIZATION..."
repos=$(gh repo list "$ORGANIZATION" --json name --limit 100 | jq -r '.[].name')

if [ -z "$repos" ]; then
    echo "No repositories found for organization $ORGANIZATION or you don't have access."
    exit 1
fi

# Initialize array to store repositories with errors
declare -a error_repos

# Check branch protection for each repository
repo_count=$(echo "$repos" | wc -l | tr -d ' ')
echo "Found $repo_count repositories. Checking branch protection..."
echo
printf "%-40s %s\n" "REPOSITORY" "STATUS"
printf "%-40s %s\n" "----------" "------"

matching_count=0
non_matching_count=0
error_count=0

for repo in $repos; do
    if check_branch_protection "$ORGANIZATION" "$repo"; then
        matching_count=$((matching_count + 1))
    else
        result=$?
        if [ $result -eq 1 ]; then
            error_count=$((error_count + 1))
        else
            non_matching_count=$((non_matching_count + 1))
        fi
    fi
done

# Print summary
echo
echo "Summary:"
echo "- Repositories with matching branch protection: $matching_count"
echo "- Repositories with non-matching branch protection: $non_matching_count"
echo "- Repositories with errors (no protection or access issues): $error_count"
echo "- Total repositories checked: $((matching_count + non_matching_count + error_count))"

# Print repositories with errors
if [ ${#error_repos[@]} -gt 0 ]; then
    echo
    echo "Repositories with issues:"
    for error_repo in "${error_repos[@]}"; do
        echo "- $error_repo"
    done
fi

# Exit with non-zero status if any repositories don't match
if [ $non_matching_count -gt 0 ]; then
    exit 1
fi

exit 0
