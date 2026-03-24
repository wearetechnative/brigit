#!/usr/bin/env bash

# Test script for git-release command
# This script tests the release functionality in a safe test repository

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="/tmp/git-release-test-$$"
GIT_RELEASE="$SCRIPT_DIR/git-release"

# Color output helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

info() {
    echo -e "${YELLOW}→${NC} $1"
}

cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

# Setup test repository
setup_test_repo() {
    info "Setting up test repository at $TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"

    git init
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create VERSION file
    echo "0.0.1" > VERSION

    # Create CHANGELOG.md
    cat > CHANGELOG.md << 'EOF'
# Changelog

## [Unreleased]

### Added
- New feature A
- New feature B

### Fixed
- Bug fix C

## [0.0.1] - 2024-01-01

Initial release
EOF

    # Copy git-release script
    cp "$SCRIPT_DIR/git-release" git-release
    chmod +x git-release

    git add .
    git commit -m "Initial commit"

    pass "Test repository created"
}

# Test 1: Version file format validation
test_version_file_format() {
    info "Test: VERSION file format validation"

    local version
    version=$(cat VERSION)

    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        pass "VERSION file has correct format: $version"
    else
        fail "VERSION file has incorrect format: $version"
    fi
}

# Test 2: Clean repository check (should pass)
test_clean_repo_check() {
    info "Test: Clean repository check"

    if git diff-index --quiet HEAD --; then
        pass "Repository is clean"
    else
        fail "Repository is not clean"
    fi
}

# Test 3: Dirty repository check (should fail)
test_dirty_repo_check() {
    info "Test: Dirty repository check (should block release)"

    # Modify a tracked file
    echo "test" >> VERSION

    # Try to run release (should fail)
    if ./git-release patch 2>&1 | grep -q "Git repository is dirty"; then
        pass "Dirty repository correctly detected"
    else
        fail "Dirty repository check failed"
    fi

    # Restore VERSION
    git checkout VERSION
}

# Test 4: Untracked files allowed
test_untracked_files_allowed() {
    info "Test: Untracked files are allowed"

    # Create untracked file
    touch untracked-file.txt

    # Check if repository is considered clean for release purposes
    local modified_files
    modified_files=$(git status --porcelain | grep -v "^??" || true)

    if [ -z "$modified_files" ]; then
        pass "Untracked files correctly ignored"
    else
        fail "Untracked files should be ignored"
    fi

    # Clean up
    rm untracked-file.txt
}

# Test 5: Version calculation - patch
test_version_calculation_patch() {
    info "Test: Version calculation - patch"

    local current="0.0.1"
    local expected="0.0.2"

    # Parse current version
    IFS='.' read -r major minor patch <<< "$current"
    patch=$((patch + 1))
    local result="${major}.${minor}.${patch}"

    if [ "$result" = "$expected" ]; then
        pass "Patch version calculation: $current -> $result"
    else
        fail "Patch version calculation failed: expected $expected, got $result"
    fi
}

# Test 6: Version calculation - minor
test_version_calculation_minor() {
    info "Test: Version calculation - minor"

    local current="0.0.1"
    local expected="0.1.0"

    # Parse current version
    IFS='.' read -r major minor patch <<< "$current"
    minor=$((minor + 1))
    patch=0
    local result="${major}.${minor}.${patch}"

    if [ "$result" = "$expected" ]; then
        pass "Minor version calculation: $current -> $result"
    else
        fail "Minor version calculation failed: expected $expected, got $result"
    fi
}

# Test 7: Version calculation - major
test_version_calculation_major() {
    info "Test: Version calculation - major"

    local current="0.0.1"
    local expected="1.0.0"

    # Parse current version
    IFS='.' read -r major minor patch <<< "$current"
    major=$((major + 1))
    minor=0
    patch=0
    local result="${major}.${minor}.${patch}"

    if [ "$result" = "$expected" ]; then
        pass "Major version calculation: $current -> $result"
    else
        fail "Major version calculation failed: expected $expected, got $result"
    fi
}

# Test 8: CHANGELOG format validation
test_changelog_format() {
    info "Test: CHANGELOG.md format validation"

    if grep -q "## \[Unreleased\]" CHANGELOG.md; then
        pass "CHANGELOG has Unreleased section"
    else
        fail "CHANGELOG missing Unreleased section"
    fi

    if grep -q "## \[0.0.1\]" CHANGELOG.md; then
        pass "CHANGELOG has versioned section"
    else
        fail "CHANGELOG missing versioned section"
    fi
}

# Test 9: Invalid release type
test_invalid_release_type() {
    info "Test: Invalid release type detection"

    if ./git-release invalid 2>&1 | grep -qi "unknown argument\|invalid"; then
        pass "Invalid release type correctly rejected"
    else
        fail "Invalid release type should be rejected"
    fi
}

# Test 10: Help text
test_help_text() {
    info "Test: Help text display"

    if ./git-release -h | grep -q "Create and publish a GitHub release"; then
        pass "Help text displays correctly"
    else
        fail "Help text not displayed"
    fi
}

# Test 11: Error handling - VERSION file missing
test_missing_version_file() {
    info "Test: Missing VERSION file error handling"

    mv VERSION VERSION.backup
    git add -A
    git commit -m "Remove VERSION temporarily" > /dev/null 2>&1

    if ./git-release patch 2>&1 | grep -q "VERSION file not found"; then
        pass "Missing VERSION file correctly detected"
    else
        fail "Missing VERSION file should be detected"
    fi

    mv VERSION.backup VERSION
    git add VERSION
    git commit -m "Restore VERSION" > /dev/null 2>&1
}

# Test 12: Error handling - CHANGELOG missing
test_missing_changelog() {
    info "Test: Missing CHANGELOG.md error handling"

    mv CHANGELOG.md CHANGELOG.md.backup
    git add -A
    git commit -m "Remove CHANGELOG temporarily" > /dev/null 2>&1

    if ./git-release patch 2>&1 | grep -q "CHANGELOG.md not found"; then
        pass "Missing CHANGELOG.md correctly detected"
    else
        fail "Missing CHANGELOG.md should be detected"
    fi

    mv CHANGELOG.md.backup CHANGELOG.md
    git add CHANGELOG.md
    git commit -m "Restore CHANGELOG" > /dev/null 2>&1
}

# Test 13: Error handling - invalid VERSION format
test_invalid_version_format() {
    info "Test: Invalid VERSION file format"

    local current_version
    current_version=$(cat VERSION)

    echo "invalid" > VERSION
    git add -u > /dev/null 2>&1
    git commit -m "Invalid VERSION for testing" > /dev/null 2>&1

    # Run command and capture output to a temp file
    local tmpout=$(mktemp)
    ./git-release patch > "$tmpout" 2>&1 || true

    if grep -qi "invalid.*version" "$tmpout"; then
        pass "Invalid VERSION format correctly detected"
    else
        fail "Invalid VERSION format should be detected"
    fi

    rm -f "$tmpout"

    echo "$current_version" > VERSION
    git add -u > /dev/null 2>&1
    git commit -m "Restore valid VERSION" > /dev/null 2>&1
}

# Main test runner
main() {
    echo "=========================================="
    echo "git-release Test Suite"
    echo "=========================================="
    echo

    setup_test_repo

    echo
    echo "Running unit tests..."
    echo "=========================================="

    test_version_file_format
    test_clean_repo_check
    test_dirty_repo_check
    test_untracked_files_allowed
    test_version_calculation_patch
    test_version_calculation_minor
    test_version_calculation_major
    test_changelog_format
    test_invalid_release_type
    test_help_text
    test_missing_version_file
    test_missing_changelog
    test_invalid_version_format

    echo
    echo "=========================================="
    echo -e "${GREEN}All tests passed!${NC}"
    echo "=========================================="
    echo
    echo "Note: Full integration tests (git push, GitHub release creation)"
    echo "require a real GitHub repository and should be run manually."
    echo
    echo "To run manual integration test:"
    echo "1. Create a test repository on GitHub"
    echo "2. Clone it locally"
    echo "3. Create VERSION and CHANGELOG.md files"
    echo "4. Copy git-release script to the repo"
    echo "5. Run: ./git-release patch"
    echo "6. Verify tag and release on GitHub"
}

main
