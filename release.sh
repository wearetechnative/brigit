#!/usr/bin/env bash
#
# Release Preparation Script for brigit
#
# This script prepares a new release by:
#   0. Requiring that it is run on the 'main' branch with a clean tree
#   1. Checking for uncommitted changes and remote connectivity
#   2. Prompting for the release type (patch / minor / major)
#   3. Optionally archiving completed OpenSpec changes
#   4. Updating CHANGELOG.md ([Unreleased] -> versioned section + fresh [Unreleased])
#   5. Updating the VERSION file
#   6. Optionally refreshing flake.lock and verifying the Nix flake builds
#   7. Verifying `brigit version` reports the new version
#   8. Creating a git commit and an annotated tag
#   9. Optionally pushing the commit and tag to the remote
#
# Distribution model
# ------------------
# brigit is a Bash tool distributed as a Nix flake — there is no compiled
# binary and no CI build pipeline. Once the tag is pushed, Nix consumers can
# use the new version directly:
#
#     nix run github:wearetechnative/brigit
#     nix profile install github:wearetechnative/brigit
#
# The version is the single source of truth in the VERSION file. `brigit
# version` and package.nix both read it, so flake.nix carries NO version
# literal to bump — this script only refreshes flake.lock (inputs) and
# verifies the flake still builds.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info()    { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }

# Always operate from the repository root (directory of this script)
cd "$(dirname "$0")"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    print_error "You have uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi

# Detect the remote to push to (prefer the current branch's upstream, then
# origin, then the only configured remote). brigit repos commonly use
# 'upstream' rather than 'origin'.
REMOTE=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null | cut -d/ -f1 || true)
if [[ -z "$REMOTE" ]]; then
    if git remote | grep -qx origin; then
        REMOTE="origin"
    else
        REMOTE=$(git remote | head -n 1)
    fi
fi
if [[ -z "$REMOTE" ]]; then
    print_error "No git remote configured"
    exit 1
fi
BRANCH=$(git rev-parse --abbrev-ref HEAD)
print_info "Remote: ${GREEN}${REMOTE}${NC}   Branch: ${GREEN}${BRANCH}${NC}"

# Releases may only be cut from the main branch
if [[ "$BRANCH" != "main" ]]; then
    print_error "Releases must be run on the 'main' branch (current: '${BRANCH}')."
    print_info "Switch first: git checkout main && git pull ${REMOTE} main"
    exit 1
fi
print_success "On the main branch"

# Check remote connectivity
print_info "Checking remote connectivity..."
if ! git ls-remote --exit-code "$REMOTE" &>/dev/null; then
    print_error "Cannot reach remote '${REMOTE}'. Check your network connection."
    exit 1
fi
print_success "Remote is reachable"

# Read current version from VERSION
if [[ ! -f VERSION ]]; then
    print_error "VERSION file not found"
    exit 1
fi

CURRENT_VERSION=$(tr -d '[:space:]' < VERSION)
print_info "Current version: ${GREEN}${CURRENT_VERSION}${NC}"

# Parse version components
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

if [[ -z "$MAJOR" || -z "$MINOR" || -z "$PATCH" ]]; then
    print_error "VERSION '${CURRENT_VERSION}' is not in X.Y.Z format"
    exit 1
fi

echo ""
echo "Select release type:"
echo "  1) Patch   (${MAJOR}.${MINOR}.$((PATCH + 1))) - Bug fixes, no new features"
echo "  2) Minor   (${MAJOR}.$((MINOR + 1)).0) - New features, backwards compatible"
echo "  3) Major   ($((MAJOR + 1)).0.0) - Breaking changes"
echo ""
read -p "Enter choice (1-3): " RELEASE_TYPE

case $RELEASE_TYPE in
    1) RELEASE_NAME="patch"; NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
    2) RELEASE_NAME="minor"; NEW_VERSION="${MAJOR}.$((MINOR + 1)).0" ;;
    3) RELEASE_NAME="major"; NEW_VERSION="$((MAJOR + 1)).0.0" ;;
    *) print_error "Invalid choice"; exit 1 ;;
esac

print_info "New version will be: ${GREEN}${NEW_VERSION}${NC} (${RELEASE_NAME} release)"

# Check if tag already exists
if git rev-parse "v${NEW_VERSION}" >/dev/null 2>&1; then
    print_error "Tag v${NEW_VERSION} already exists!"
    exit 1
fi
print_success "Version tag v${NEW_VERSION} is available"

# Check for OpenSpec completed changes that need archiving
echo ""
if command -v openspec &> /dev/null; then
    print_info "Checking OpenSpec changes..."
    # Use --json (jq is a hard brigit dependency) to find complete, un-archived changes
    COMPLETED_CHANGES=$(openspec list --json 2>/dev/null \
        | jq -r '.changes[]? | select(.status == "complete") | .name' 2>/dev/null || true)

    if [[ -n "$COMPLETED_CHANGES" ]]; then
        print_warning "Found completed OpenSpec changes that may need archiving:"
        echo "$COMPLETED_CHANGES" | sed 's/^/    - /'
        echo ""
        read -p "Archive these changes before release? (y/n): " ARCHIVE_CHANGES

        if [[ $ARCHIVE_CHANGES == "y" || $ARCHIVE_CHANGES == "Y" ]]; then
            for change in $COMPLETED_CHANGES; do
                print_info "Archiving ${change}..."
                if openspec archive "$change" --yes &>/dev/null; then
                    print_success "Archived ${change}"
                else
                    print_warning "Could not archive ${change} (may need manual attention)"
                fi
            done

            if [[ -n $(git status --porcelain openspec/) ]]; then
                git add openspec/
                git commit -m "chore: archive completed openspec changes before release"
                print_success "Archived changes committed"
            fi
        else
            print_warning "Skipping OpenSpec archiving"
        fi
    else
        print_success "No completed OpenSpec changes to archive"
    fi
else
    print_warning "OpenSpec CLI not found, skipping OpenSpec checks"
fi

# CHANGELOG.md update
echo ""
print_info "CHANGELOG.md update"
echo ""
echo "Choose changelog option:"
echo "  1) Entries are already under '## [Unreleased]' in CHANGELOG.md"
echo "  2) Enter changelog entries now (interactive)"
echo ""
read -p "Enter choice (1-2): " CHANGELOG_CHOICE

# Detect the current unreleased marker: prefer Keep-a-Changelog '## [Unreleased]',
# fall back to the '## NEXT VERSION' convention.
if grep -q "^## \[Unreleased\]" CHANGELOG.md; then
    UNRELEASED_MARKER="## [Unreleased]"
elif grep -q "^## NEXT VERSION" CHANGELOG.md; then
    UNRELEASED_MARKER="## NEXT VERSION"
else
    print_error "No '## [Unreleased]' or '## NEXT VERSION' section found in CHANGELOG.md"
    print_info "Add one (with your entries) before releasing."
    exit 1
fi

ENTRIES_FILE=""
if [[ $CHANGELOG_CHOICE == "2" ]]; then
    echo ""
    print_info "Enter changelog entries (Keep a Changelog format), then press Ctrl+D:"
    print_info "e.g.  ### Added"
    print_info "      - **Feature**: description"
    echo ""
    ENTRIES_FILE=$(mktemp)
    cat > "$ENTRIES_FILE"
    if [[ ! -s "$ENTRIES_FILE" ]]; then
        print_error "No changelog entries provided"
        rm -f "$ENTRIES_FILE"
        exit 1
    fi
fi

# Release date in ISO format, matching existing CHANGELOG entries
RELEASE_DATE=$(date +"%Y-%m-%d")

# Rewrite CHANGELOG.md: turn the unreleased marker into a versioned heading,
# insert a fresh empty '## [Unreleased]' above it, and (option 2) splice in the
# typed entries under the new version heading.
print_info "Updating CHANGELOG.md..."
TMP_CHANGELOG=$(mktemp)
awk -v ver="$NEW_VERSION" -v date="$RELEASE_DATE" -v marker="$UNRELEASED_MARKER" \
    -v entriesfile="$ENTRIES_FILE" '
    BEGIN { done = 0 }
    !done && index($0, marker) == 1 {
        print "## [Unreleased]"
        print ""
        print "## [" ver "] - " date
        if (entriesfile != "") {
            print ""
            while ((getline line < entriesfile) > 0) print line
        }
        done = 1
        next
    }
    { print }
' CHANGELOG.md > "$TMP_CHANGELOG"

if ! grep -q "^## \[${NEW_VERSION}\] - ${RELEASE_DATE}" "$TMP_CHANGELOG"; then
    print_error "Failed to update CHANGELOG.md"
    rm -f "$TMP_CHANGELOG" "$ENTRIES_FILE"
    exit 1
fi
mv "$TMP_CHANGELOG" CHANGELOG.md
[[ -n "$ENTRIES_FILE" ]] && rm -f "$ENTRIES_FILE"

# Append a release-tag link reference (Keep a Changelog convention) if absent
if ! grep -q "^\[${NEW_VERSION}\]:" CHANGELOG.md; then
    echo "[${NEW_VERSION}]: https://github.com/wearetechnative/brigit/releases/tag/v${NEW_VERSION}" >> CHANGELOG.md
fi
print_success "Updated CHANGELOG.md"

# Update VERSION
print_info "Updating VERSION..."
echo "$NEW_VERSION" > VERSION
print_success "Updated VERSION to ${NEW_VERSION}"

# Verify `brigit version` reports the new version (no build needed — it reads VERSION)
print_info "Verifying 'brigit version'..."
VERSION_OUTPUT=$(./brigit version 2>&1 || true)
if echo "$VERSION_OUTPUT" | grep -q "${NEW_VERSION}"; then
    print_success "brigit reports v${NEW_VERSION}"
else
    print_warning "brigit version output did not contain ${NEW_VERSION}:"
    echo "$VERSION_OUTPUT"
fi

# Nix flake: flake.nix has no version literal (version is derived from VERSION),
# so there is nothing to bump there. Optionally refresh flake.lock inputs and
# verify the flake still builds with the new version.
echo ""
if [[ -f flake.nix ]] && command -v nix &> /dev/null; then
    read -p "Update flake.lock (nix flake update)? (y/n): " UPDATE_FLAKE
    if [[ $UPDATE_FLAKE == "y" || $UPDATE_FLAKE == "Y" ]]; then
        print_info "Updating flake.lock..."
        if nix flake update 2>&1 | tail -3; then
            [[ -n $(git status --porcelain flake.lock) ]] && print_info "flake.lock will be included in the release commit"
        fi
    fi

    print_info "Verifying the Nix flake builds (this may take a moment)..."
    if nix build .#brigit 2>&1 | tail -5; then
        if [[ -x result/bin/brigit ]]; then
            BUILT_VERSION=$(result/bin/brigit version 2>&1 || true)
            if echo "$BUILT_VERSION" | grep -q "${NEW_VERSION}"; then
                print_success "Nix build reports v${NEW_VERSION}"
            else
                print_warning "Nix build version check inconclusive"
            fi
        fi
        rm -f result
    else
        print_warning "Nix build did not succeed — verify manually before pushing"
    fi
else
    if [[ ! -f flake.nix ]]; then
        print_warning "flake.nix not found, skipping Nix checks"
    else
        print_warning "Nix not installed, skipping flake.lock update and build verification"
    fi
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════"
print_info "Release Summary"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Release type:  ${RELEASE_NAME}"
echo "  Old version:   ${CURRENT_VERSION}"
echo -e "  New version:   ${GREEN}${NEW_VERSION}${NC}"
echo "  Release date:  ${RELEASE_DATE}"
echo ""
echo "  Files changed:"
echo "    - CHANGELOG.md"
echo "    - VERSION"
[[ -n $(git status --porcelain flake.lock 2>/dev/null) ]] && echo "    - flake.lock"
[[ -n $(git status --porcelain openspec/ 2>/dev/null) ]] && echo "    - openspec/ (archived changes)"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Show the diff to be committed
print_info "Changes to be committed:"
echo ""
git --no-pager diff -- CHANGELOG.md VERSION flake.lock 2>/dev/null || true
echo ""

# Confirm before committing
read -p "Commit these changes? (y/n): " CONFIRM_COMMIT
if [[ $CONFIRM_COMMIT != "y" && $CONFIRM_COMMIT != "Y" ]]; then
    print_warning "Aborting release. Rolling back file changes..."
    git checkout -- CHANGELOG.md VERSION 2>/dev/null || true
    git checkout -- flake.lock 2>/dev/null || true
    print_info "Changes rolled back (any archived OpenSpec commit was kept)"
    exit 0
fi

# Create git commit
print_info "Creating git commit..."
git add CHANGELOG.md VERSION
[[ -n $(git status --porcelain flake.lock 2>/dev/null) ]] && git add flake.lock

git commit -m "Release v${NEW_VERSION}

Update VERSION and CHANGELOG.md for ${RELEASE_NAME} release."
print_success "Commit created"

# Create annotated git tag, embedding this version's changelog section
print_info "Creating git tag v${NEW_VERSION}..."
TAG_BODY=$(awk -v ver="$NEW_VERSION" '
    $0 ~ "^## \\[" ver "\\]" { grab = 1; next }
    grab && /^## / { exit }
    grab { print }
' CHANGELOG.md)

git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}
${TAG_BODY}"
print_success "Tag v${NEW_VERSION} created"

# Confirm before pushing
echo ""
echo "════════════════════════════════════════════════════════════"
print_success "Release v${NEW_VERSION} prepared!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Commit: $(git log -1 --pretty=format:'%h - %s')"
echo "  Tag:    v${NEW_VERSION}"
echo ""
read -p "Push to ${REMOTE} (${BRANCH} + tag)? (y/n): " CONFIRM_PUSH

if [[ $CONFIRM_PUSH != "y" && $CONFIRM_PUSH != "Y" ]]; then
    print_warning "Skipping push. You can push later with:"
    echo ""
    echo "  git push ${REMOTE} ${BRANCH}"
    echo "  git push ${REMOTE} v${NEW_VERSION}"
    echo ""
    exit 0
fi

# Push to remote
print_info "Pushing to ${REMOTE}..."
git push "$REMOTE" "$BRANCH"
git push "$REMOTE" "v${NEW_VERSION}"

echo ""
print_success "Release v${NEW_VERSION} pushed to ${REMOTE}!"
echo ""
print_info "Nix consumers can now use the new version:"
echo "    nix run github:wearetechnative/brigit"
echo "    nix profile install github:wearetechnative/brigit"
echo ""
print_info "Release page:"
echo "    https://github.com/wearetechnative/brigit/releases/tag/v${NEW_VERSION}"
echo ""
print_success "Done! 🚀"
echo ""
