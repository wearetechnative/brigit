#!/usr/bin/env bash

# Shared library functions for branch protection scripts

# Detect if running in interactive terminal
detect_interactive() {
    INTERACTIVE=false
    if [ -t 1 ]; then
        INTERACTIVE=true
    fi
}

# Generate timestamp for output files
generate_timestamp() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
}

# Check all prerequisites
check_prerequisites() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Please install jq."
        exit 1
    fi

    # Check if gum is installed
    if ! command -v gum &> /dev/null; then
        echo "Error: gum is required but not installed. Please install gum: https://github.com/charmbracelet/gum"
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
}

check_repo_archive() {
  local ghorg="$1"
  local ghrepo="$2"
  repo_archive_state=$(gh repo view ${ghorg}/${ghrepo} --json isArchived --jq '.isArchived')
  if [ "$repo_archive_state" = "true" ]; then
    return 0   # repo is archived
  else
    return 1   # repo is not archived
  fi
}

# Print a table (uses gum in interactive mode, column otherwise)
# Usage: print_table "COL1,COL2\nval1,val2"
print_table() {
    local data="$1"
    if $INTERACTIVE; then
        echo -e "$data" | gum table --print --separator ","
    else
        echo -e "$data" | column -t -s ","
    fi
}

# Print a styled header
# Usage: print_header "Header text"
print_header() {
    local text="$1"
    if $INTERACTIVE; then
        gum style --bold "$text"
    else
        echo "$text"
    fi
}

# Print a styled warning/error header
# Usage: print_warning_header "Warning text"
print_warning_header() {
    local text="$1"
    if $INTERACTIVE; then
        gum style --bold --foreground 212 "$text"
    else
        echo "$text"
    fi
}

# Show progress on a single line (overwrite previous)
# Usage: show_progress current total message
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    if $INTERACTIVE; then
        printf "\r\033[K[%d/%d] %s..." "$current" "$total" "$message"
    fi
}

# Clear the progress line
clear_progress() {
    if $INTERACTIVE; then
        printf "\r\033[K"
    fi
}

# Fetch repositories with spinner
# Usage: fetch_repos_with_spinner "org" -> sets $repos_json
fetch_repos_with_spinner() {
    local org="$1"
    if $INTERACTIVE; then
        repos_json=$(gum spin --spinner dot --title "Fetching repositories for $org..." -- gh repo list "$org" --json name --limit 100)
    else
        echo "Fetching repositories for organization: $org..."
        repos_json=$(gh repo list "$org" --json name --limit 100)
    fi
}

# Load ignore list from file
# Usage: load_ignore_list "path/to/ignore-file.txt" -> sets $ignore_list array
load_ignore_list() {
    local ignore_file="$1"
    ignore_list=()

    if [ ! -f "$ignore_file" ]; then
        return 0
    fi

    while IFS=: read -r org repo || [ -n "$org" ]; do
        # Skip empty lines and comments
        if [ -z "$org" ] || [[ "$org" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        if [ -z "$repo" ]; then
            continue
        fi

        org=$(echo "$org" | tr -d '[:space:]')
        repo=$(echo "$repo" | tr -d '[:space:]')
        ignore_list+=("$org:$repo")
    done < "$ignore_file"
}

# Check if a repository should be ignored
# Usage: is_repo_ignored "org" "repo" -> returns 0 if ignored, 1 if not
is_repo_ignored() {
    local org="$1"
    local repo="$2"
    local repo_key="$org:$repo"

    for ignored in "${ignore_list[@]}"; do
        if [ "$ignored" = "$repo_key" ]; then
            return 0
        fi
    done
    return 1
}
