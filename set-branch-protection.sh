#!/usr/bin/env bash

# Script to set branch protection for GitHub repositories based on ghbranchprotection.json configuration
# Usage: ./set-branch-protection.sh [-o organization] [-r repository] [-f repos_file]

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# Default values
CONFIG_FILE="$SCRIPT_DIR/ghbranchprotection.json"
REPOS_FILE=""
ORGANIZATION=""
REPOSITORY=""

# Function to display usage information
usage() {
    echo "Usage: $0 [-o organization] [-r repository] [-f repos_file]"
    echo "  -o organization  GitHub organization name"
    echo "  -r repository    Repository name (requires -o)"
    echo "  -f repos_file    Path to a text file containing repositories in format <org>:<repo> (one per line)"
    echo "  -h               Display this help message"
    exit 1
}

# Parse command line arguments
while getopts "o:r:f:h" opt; do
    case ${opt} in
        o)
            ORGANIZATION=$OPTARG
            ;;
        r)
            REPOSITORY=$OPTARG
            ;;
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

# Initialize shared functionality
check_prerequisites
detect_interactive
generate_timestamp

# Generate output file names
OUTPUT_FILE="set-output-${TIMESTAMP}.txt"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
fi

# Function to apply branch protection to a repository
# Returns: 0 on success, 1 on failure
apply_branch_protection() {
    local org=$1
    local repo=$2
    local status="NOK"
    local message=""

    # Get protection settings from config file - use default configuration
    local protection_config=$(jq -c '.default' "$CONFIG_FILE")

    # If no default config, exit with error
    if [ "$protection_config" == "null" ]; then
        message="No default protection configuration found"
        failed_repos+=("$org:$repo: $message")
        return 1
    fi

    # First check if the branch exists
    if ! gh api "/repos/$org/$repo/branches/main" &>/dev/null; then
        message="Branch 'main' does not exist"
        failed_repos+=("$org:$repo: $message")
        return 1
    fi

    # Apply branch protection using GitHub API via gh CLI
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

    response=$(echo "$complete_config" | gh api --method PUT "/repos/$org/$repo/branches/main/protection" --input - 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        status="OK"
        return 0
    else
        # Check for specific error messages
        if echo "$response" | grep -q "Upgrade to GitHub Pro"; then
            message="Requires GitHub Pro for private repos"
        elif echo "$response" | grep -q "Not Found"; then
            message="Repository not found or no permissions"
        else
            message="Failed to apply protection"
        fi
        failed_repos+=("$org:$repo: $message")
        return 1
    fi
}

# Initialize arrays
declare -a failed_repos
declare -a repos_to_process

# Validate that -r requires -o
if [ -n "$REPOSITORY" ] && [ -z "$ORGANIZATION" ]; then
    echo "Error: Organization (-o) must be specified when specifying a repository (-r)."
    exit 1
fi

# Build list of repositories to process
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

        repos_to_process+=("$org:$repo")
    done < "$REPOS_FILE"
elif [ -n "$ORGANIZATION" ] && [ -n "$REPOSITORY" ]; then
    repos_to_process+=("$ORGANIZATION:$REPOSITORY")
else
    echo "Error: Please provide either -f <repos_file> or both -o <organization> and -r <repository>."
    usage
fi

# Count repositories
repo_count=${#repos_to_process[@]}
echo "Setting branch protection for $repo_count repository/repositories..."
echo

# Collect results for table
table_data="REPOSITORY,STATUS"
success_count=0
fail_count=0

current_repo_num=0
for repo_entry in "${repos_to_process[@]}"; do
    current_repo_num=$((current_repo_num + 1))

    # Parse org:repo format
    org="${repo_entry%%:*}"
    repo="${repo_entry#*:}"

    # Show progress on a single line (overwrite previous)
    show_progress "$current_repo_num" "$repo_count" "Setting protection for $org/$repo"

    if apply_branch_protection "$org" "$repo"; then
        success_count=$((success_count + 1))
        table_data+="\n$org/$repo,OK"
    else
        fail_count=$((fail_count + 1))
        table_data+="\n$org/$repo,NOK"
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
echo "- Successfully applied: $success_count"
echo "- Failed: $fail_count"
echo "- Total processed: $repo_count"

# Write summary to output file
{
    echo ""
    echo "Summary:"
    echo "- Successfully applied: $success_count"
    echo "- Failed: $fail_count"
    echo "- Total processed: $repo_count"
} >> "$OUTPUT_FILE"

# Print repositories with errors
if [ ${#failed_repos[@]} -gt 0 ]; then
    echo
    print_warning_header "Failed repositories:"
    for failed_repo in "${failed_repos[@]}"; do
        echo "- $failed_repo"
    done

    # Write to output file
    {
        echo ""
        echo "Failed repositories:"
        for failed_repo in "${failed_repos[@]}"; do
            echo "- $failed_repo"
        done
    } >> "$OUTPUT_FILE"
fi

# Print output file location
echo
echo "Output written to: $OUTPUT_FILE"

# Exit with non-zero status if any failures
if [ $fail_count -gt 0 ]; then
    exit 1
fi

exit 0
