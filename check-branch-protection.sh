#!/usr/bin/env bash

# Script to check branch protection for GitHub repositories
# Usage: ./check-branch-protection.sh [-o organization]

# Default values
ORGANIZATION=""
DEBUG=false

# Function to display usage information
usage() {
    echo "Usage: $0 [-o organization] [-r repository] [-d]"
    echo "  -o organization  GitHub organization to check repositories for"
    echo "  -r repository    Specific repository to check (requires -o)"
    echo "  -d               Enable debug mode (shows raw API responses)"
    echo "  -h               Display this help message"
    exit 1
}

# Parse command line arguments
REPOSITORY=""
while getopts "o:r:hd" opt; do
    case ${opt} in
        o)
            ORGANIZATION=$OPTARG
            ;;
        r)
            REPOSITORY=$OPTARG
            ;;
        d)
            DEBUG=true
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

# If no organization provided, prompt for it
if [ -z "$ORGANIZATION" ]; then
    read -p "Enter GitHub organization name: " ORGANIZATION
    
    # Validate input
    if [ -z "$ORGANIZATION" ]; then
        echo "Error: Organization name cannot be empty."
        exit 1
    fi
    
    # If no repository specified, ask if user wants to check a specific repo
    if [ -z "$REPOSITORY" ]; then
        read -p "Do you want to check a specific repository? (y/N): " check_specific
        if [[ "$check_specific" =~ ^[Yy] ]]; then
            read -p "Enter repository name: " REPOSITORY
            if [ -z "$REPOSITORY" ]; then
                echo "Error: Repository name cannot be empty."
                exit 1
            fi
        fi
    fi
fi

# Validate repository if provided with organization
if [ -n "$REPOSITORY" ] && [ -z "$ORGANIZATION" ]; then
    echo "Error: Organization (-o) must be specified when checking a specific repository."
    exit 1
fi

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

# Function to check if branch protection is properly configured
check_branch_protection() {
    local org=$1
    local repo=$2
    local error_msg=""
    
    printf "%-40s" "$repo"
    
    # Get current branch protection settings in background and capture PID
    current_protection=$(gh api "/repos/$org/$repo/branches/main/protection" 2>&1 || echo "ERROR: $?") &
    local pid=$!
    spinner $pid
    wait $pid
    
    # Check if the response contains an error
    if [[ "$current_protection" == ERROR* ]]; then
        exit_code=1
    else
        exit_code=0
    fi
    
    # Show raw API response in debug mode
    if $DEBUG; then
        echo
        echo "DEBUG: Raw API response for $org/$repo:"
        if [ $exit_code -eq 0 ]; then
            echo "$current_protection" | jq '.' 2>/dev/null || echo "$current_protection"
        else
            echo "Error: $current_protection"
        fi
        echo
        printf "%-40s" "$repo"
    fi
    
    # Check if the response contains an error message or is empty
    if [ $exit_code -ne 0 ] || [ -z "$current_protection" ] || [ "$current_protection" = "null" ] || echo "$current_protection" | grep -q "Branch not protected" || echo "$current_protection" | grep -q "Not Found"; then
        echo "❌"
        
        # Try to get branch information to see if the branch exists
        branch_info=$(gh api "/repos/$org/$repo/branches/main" 2>/dev/null)
        branch_exists=$?
        
        if [ $branch_exists -ne 0 ]; then
            error_msg="Branch 'main' does not exist"
        else
            error_msg="No branch protection enabled"
            
            # Try to verify with direct curl command if gh CLI is failing
            if $DEBUG; then
                echo
                echo "   Attempting to verify if repository exists and is accessible..."
                repo_info=$(gh repo view "$org/$repo" --json name 2>/dev/null)
                if [ $? -eq 0 ]; then
                    echo "   Repository exists and is accessible"
                    
                    # Try with curl as a fallback
                    echo "   Attempting direct API call with curl..."
                    token=$(gh auth token)
                    if [ -n "$token" ]; then
                        curl_response=$(curl -s -H "Authorization: token $token" \
                            "https://api.github.com/repos/$org/$repo/branches/main/protection")
                        if [ $? -eq 0 ] && [ -n "$curl_response" ] && [ "$curl_response" != "null" ]; then
                            echo "   Curl API call successful:"
                            echo "$curl_response" | jq '.'
                            
                            # Extract review count from curl response
                            curl_review_count=$(echo "$curl_response" | jq -r '.required_pull_request_reviews.required_approving_review_count // "0"')
                            if [ -n "$curl_review_count" ] && [ "$curl_review_count" != "null" ]; then
                                echo "   Found review count via curl: $curl_review_count"
                                current_protection="$curl_response"
                                exit_code=0
                                # Continue with normal processing
                                return 0
                            fi
                        else
                            echo "   Curl API call failed or returned empty response"
                        fi
                    fi
                else
                    echo "   Repository may not exist or you don't have access"
                fi
            fi
        fi
        
        error_repos+=("$repo: $error_msg")
        return 1
    fi
    
    # Check if the response is valid JSON
    if ! echo "$current_protection" | jq '.' &>/dev/null; then
        echo "❌"
        error_msg="Invalid response format or no branch protection"
        error_repos+=("$repo: $error_msg")
        return 1
    fi
    
    # Check if branch protection is enabled by looking for required_pull_request_reviews
    has_protection=$(echo "$current_protection" | jq 'has("required_pull_request_reviews")' 2>/dev/null || echo "false")
    
    if [ "$has_protection" != "true" ] && [ "$has_protection" != "false" ]; then
        has_protection="false"
    fi
    
    if [ "$has_protection" != "true" ]; then
        echo "❌"
        error_msg="Branch protection is not properly configured (missing required pull request reviews)"
        error_repos+=("$repo: $error_msg")
        return 1
    fi
    
    # Check if required_approving_review_count is at least 1
    current_review_count=$(echo "$current_protection" | jq -r '.required_pull_request_reviews.required_approving_review_count // "0"')
    
    # For debug purposes, show the extracted values
    if $DEBUG; then
        echo
        echo "DEBUG: Required approving review count: $current_review_count"
        echo
        printf "%-40s" "$repo"
    fi
    
    # Check if review count is at least 1
    if [ "$current_review_count" -ge 1 ]; then
        echo "✅"
        return 0
    else
        echo "❌"
        error_msg="Branch protection requires at least 1 approval (current: $current_review_count)"
        error_repos+=("$repo: $error_msg")
        return 2
    fi
}

# Initialize array to store repositories with errors
declare -a error_repos

# Check a single repository or get list of repositories in the organization
if [ -n "$REPOSITORY" ]; then
    # Check if repository exists
    if ! gh repo view "$ORGANIZATION/$REPOSITORY" &>/dev/null; then
        echo "Error: Repository $ORGANIZATION/$REPOSITORY not found or you don't have access."
        exit 1
    fi
    
    echo "Checking branch protection for repository: $ORGANIZATION/$REPOSITORY"
    repos="$REPOSITORY"
    repo_count=1
else
    # Get list of repositories in the organization
    echo "Fetching repositories for organization: $ORGANIZATION..."
    repos=$(gh repo list "$ORGANIZATION" --json name --limit 100 | jq -r '.[].name')

    if [ -z "$repos" ]; then
        echo "No repositories found for organization $ORGANIZATION or you don't have access."
        exit 1
    fi

    # Count repositories
    repo_count=$(echo "$repos" | wc -l | tr -d ' ')
    echo "Found $repo_count repositories. Checking branch protection..."
fi
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
echo "- Repositories with proper branch protection: $matching_count"
echo "- Repositories with improper branch protection: $non_matching_count"
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
