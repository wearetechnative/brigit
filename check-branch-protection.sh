#!/usr/bin/env bash

# Script to check branch protection for GitHub repositories
# Usage: ./check-branch-protection.sh [-o organization]

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

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

# Initialize shared functionality
check_prerequisites
detect_interactive
generate_timestamp

# Generate output file names
OUTPUT_FILE="output-${TIMESTAMP}.txt"
REPOS_OUTPUT_FILE="repos-${TIMESTAMP}.txt"

# Validate that organization is provided
if [ -z "$ORGANIZATION" ]; then
    echo "Error: Organization (-o) is required."
    usage
fi

# Validate repository if provided with organization
if [ -n "$REPOSITORY" ] && [ -z "$ORGANIZATION" ]; then
    echo "Error: Organization (-o) must be specified when checking a specific repository."
    exit 1
fi

# Function to check if branch protection is properly configured
# Sets global variables: last_status, last_error_msg
check_branch_protection() {
    local org=$1
    local repo=$2
    last_error_msg=""
    last_status="NOK"

    # Get current branch protection settings
    current_protection=$(gh api "/repos/$org/$repo/branches/main/protection" 2>&1)
    exit_code=$?

    # Show raw API response in debug mode
    if $DEBUG; then
        echo "DEBUG: Raw API response for $org/$repo:"
        if [ $exit_code -eq 0 ]; then
            echo "$current_protection" | jq '.' 2>/dev/null || echo "$current_protection"
        else
            echo "Error: $current_protection"
        fi
    fi

    # Check if the response contains an error message or is empty
    if [ $exit_code -ne 0 ] || [ -z "$current_protection" ] || [ "$current_protection" = "null" ] || echo "$current_protection" | grep -q "Branch not protected" || echo "$current_protection" | grep -q "Not Found"; then
        # Try to get branch information to see if the branch exists
        branch_info=$(gh api "/repos/$org/$repo/branches/main" 2>/dev/null)
        branch_exists=$?

        if [ $branch_exists -ne 0 ]; then
            last_error_msg="Branch 'main' does not exist"
        else
            last_error_msg="No branch protection enabled"
        fi

        error_repos+=("$repo: $last_error_msg")
        return 1
    fi

    # Check if the response is valid JSON
    if ! echo "$current_protection" | jq '.' &>/dev/null; then
        last_error_msg="Invalid response format or no branch protection"
        error_repos+=("$repo: $last_error_msg")
        return 1
    fi

    # Check if branch protection is enabled by looking for required_pull_request_reviews
    has_protection=$(echo "$current_protection" | jq 'has("required_pull_request_reviews")' 2>/dev/null || echo "false")

    if [ "$has_protection" != "true" ]; then
        last_error_msg="Branch protection is not properly configured (missing required pull request reviews)"
        error_repos+=("$repo: $last_error_msg")
        return 1
    fi

    # Check if required_approving_review_count is at least 1
    current_review_count=$(echo "$current_protection" | jq -r '.required_pull_request_reviews.required_approving_review_count // "0"')

    # For debug purposes, show the extracted values
    if $DEBUG; then
        echo "DEBUG: Required approving review count: $current_review_count"
    fi

    # Check if review count is at least 1
    if [ "$current_review_count" -ge 1 ]; then
        last_status="OK"
        return 0
    else
        last_error_msg="Branch protection requires at least 1 approval (current: $current_review_count)"
        error_repos+=("$repo: $last_error_msg")
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
    fetch_repos_with_spinner "$ORGANIZATION"
    repos=$(echo "$repos_json" | jq -r '.[].name')

    if [ -z "$repos" ]; then
        echo "No repositories found for organization $ORGANIZATION or you don't have access."
        exit 1
    fi

    # Count repositories
    repo_count=$(echo "$repos" | wc -l | tr -d ' ')
    echo "Found $repo_count repositories. Checking branch protection..."
fi
echo

matching_count=0
non_matching_count=0
error_count=0

# Collect results for table
table_data="REPOSITORY,STATUS"

current_repo_num=0
for repo in $repos; do
    current_repo_num=$((current_repo_num + 1))

    # Show progress on a single line (overwrite previous)
    show_progress "$current_repo_num" "$repo_count" "Checking $repo"

    if check_branch_protection "$ORGANIZATION" "$repo"; then
        matching_count=$((matching_count + 1))
        table_data+="\n$repo,OK"
    else
        result=$?
        if [ $result -eq 1 ]; then
            error_count=$((error_count + 1))
        else
            non_matching_count=$((non_matching_count + 1))
        fi
        table_data+="\n$repo,NOK"
    fi
done

# Clear the progress line
clear_progress

# Display results table
print_table "$table_data"

# Write table to output file
echo -e "$table_data" | column -t -s "," > "$OUTPUT_FILE"

# Print summary
echo
print_header "Summary:"
echo "- Repositories with proper branch protection: $matching_count"
echo "- Repositories with improper branch protection: $non_matching_count"
echo "- Repositories with errors (no protection or access issues): $error_count"
echo "- Total repositories checked: $((matching_count + non_matching_count + error_count))"

# Write summary to output file
{
    echo ""
    echo "Summary:"
    echo "- Repositories with proper branch protection: $matching_count"
    echo "- Repositories with improper branch protection: $non_matching_count"
    echo "- Repositories with errors (no protection or access issues): $error_count"
    echo "- Total repositories checked: $((matching_count + non_matching_count + error_count))"
} >> "$OUTPUT_FILE"

# Print repositories with errors
if [ ${#error_repos[@]} -gt 0 ]; then
    echo
    print_warning_header "Repositories with issues:"
    for error_repo in "${error_repos[@]}"; do
        echo "- $error_repo"
    done

    # Write to output file
    {
        echo ""
        echo "Repositories with issues:"
        for error_repo in "${error_repos[@]}"; do
            echo "- $error_repo"
        done
    } >> "$OUTPUT_FILE"

    # Write repos with errors to separate file (format: org:repo for set-branch-protection.sh)
    for error_repo in "${error_repos[@]}"; do
        echo "${ORGANIZATION}:${error_repo%%:*}" >> "$REPOS_OUTPUT_FILE"
    done
fi

# Print output file locations
echo
echo "Output written to: $OUTPUT_FILE"
if [ ${#error_repos[@]} -gt 0 ]; then
    echo "Repos with issues written to: $REPOS_OUTPUT_FILE"
fi

# Exit with non-zero status if any repositories don't match
if [ $non_matching_count -gt 0 ]; then
    exit 1
fi

exit 0
