#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 13 — Git & Version Control
# Test Suite
#
# Tests Git repository setup, branching strategy, secrets management
################################################################################

# Strict mode
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_NAME="operation-shadow-infrastructure"
REPO_PATH="$HOME/$REPO_NAME"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

################################################################################
# Test utilities
################################################################################

test_start() {
    ((TESTS_RUN++))
    echo -e "${BLUE}[Test $TESTS_RUN]${NC} $1..."
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $1"
}

test_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

################################################################################
# Test Category 1: Repository Initialization
################################################################################

test_git_repository() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 1: Git Repository Initialization"
    echo "═══════════════════════════════════════════════════════════════"

    # Test 1.1: Repository exists
    test_start "Repository directory exists"
    if [ -d "$REPO_PATH" ]; then
        test_pass "Repository directory found at $REPO_PATH"
    else
        test_fail "Repository directory NOT found at $REPO_PATH"
        echo "  Run: mkdir -p $REPO_PATH && cd $REPO_PATH && git init"
        return 1
    fi

    # Test 1.2: Git initialized
    test_start "Git repository initialized"
    if [ -d "$REPO_PATH/.git" ]; then
        test_pass "Git repository initialized (.git directory exists)"
    else
        test_fail "Git NOT initialized (no .git directory)"
        echo "  Run: cd $REPO_PATH && git init"
        return 1
    fi

    # Test 1.3: Git config
    test_start "Git user configured"
    cd "$REPO_PATH" || return 1
    USER_NAME=$(git config user.name 2>/dev/null || echo "")
    USER_EMAIL=$(git config user.email 2>/dev/null || echo "")
    if [ -n "$USER_NAME" ] && [ -n "$USER_EMAIL" ]; then
        test_pass "Git user configured: $USER_NAME <$USER_EMAIL>"
    else
        test_fail "Git user NOT configured"
        echo "  Run: git config user.name 'Your Name'"
        echo "       git config user.email 'your@email.com'"
    fi

    # Test 1.4: At least one commit
    test_start "Repository has commits"
    if git rev-parse HEAD &>/dev/null; then
        COMMIT_COUNT=$(git rev-list --count HEAD)
        if [ "$COMMIT_COUNT" -ge 1 ]; then
            test_pass "Repository has $COMMIT_COUNT commits"
        else
            test_fail "No commits found"
            echo "  Make at least one commit"
        fi
    else
        test_fail "No commits found"
        echo "  Run: git add . && git commit -m 'Initial commit'"
    fi
}

################################################################################
# Test Category 2: Directory Structure
################################################################################

test_directory_structure() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 2: Directory Structure"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Required directories
    REQUIRED_DIRS=(
        "ansible"
        "ansible/playbooks"
        "ansible/roles"
        "ansible/inventory"
        "docker"
        "docker/web"
        "terraform"
        "scripts"
        "docs"
    )

    for dir in "${REQUIRED_DIRS[@]}"; do
        test_start "Directory exists: $dir"
        if [ -d "$dir" ]; then
            test_pass "Directory exists: $dir"
        else
            test_fail "Directory NOT found: $dir"
            echo "  Run: mkdir -p $dir"
        fi
    done

    # Required files
    test_start "README.md exists"
    if [ -f "README.md" ]; then
        test_pass "README.md exists"
    else
        test_fail "README.md NOT found"
    fi
}

################################################################################
# Test Category 3: .gitignore
################################################################################

test_gitignore() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 3: .gitignore Configuration"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 3.1: .gitignore exists
    test_start ".gitignore exists"
    if [ -f ".gitignore" ]; then
        test_pass ".gitignore exists"
    else
        test_fail ".gitignore NOT found"
        return 1
    fi

    # Test 3.2: .gitignore patterns
    REQUIRED_PATTERNS=(
        ".env"
        "*.pem"
        "*.key"
        "*.log"
        ".DS_Store"
        "*.retry"
        "*.tfstate"
    )

    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        test_start ".gitignore contains: $pattern"
        if grep -qF "$pattern" .gitignore; then
            test_pass ".gitignore contains: $pattern"
        else
            test_warning ".gitignore missing: $pattern (optional but recommended)"
        fi
    done

    # Test 3.3: .gitignore is committed
    test_start ".gitignore is committed to Git"
    if git ls-files | grep -q "^\.gitignore$"; then
        test_pass ".gitignore is committed"
    else
        test_fail ".gitignore NOT committed"
        echo "  Run: git add .gitignore && git commit -m 'chore: add .gitignore'"
    fi
}

################################################################################
# Test Category 4: Branching Strategy
################################################################################

test_branching() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 4: Branching Strategy"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 4.1: Main branch exists
    test_start "Main branch exists"
    if git rev-parse --verify main &>/dev/null || git rev-parse --verify master &>/dev/null; then
        test_pass "Main branch exists"
    else
        test_fail "Main branch NOT found"
    fi

    # Test 4.2: Development branch exists
    test_start "Development branch exists"
    if git rev-parse --verify development &>/dev/null; then
        test_pass "Development branch exists"
    else
        test_warning "Development branch NOT found (optional)"
    fi

    # Test 4.3: Multiple branches
    test_start "Multiple branches exist"
    BRANCH_COUNT=$(git branch -a | wc -l)
    if [ "$BRANCH_COUNT" -ge 3 ]; then
        test_pass "Multiple branches exist ($BRANCH_COUNT branches)"
    else
        test_warning "Only $BRANCH_COUNT branch(es) found. Expected 3+ (main, development, feature/*)"
    fi

    # Test 4.4: Branching documentation
    test_start "Branching strategy documented"
    if [ -f "docs/BRANCHING_STRATEGY.md" ]; then
        test_pass "BRANCHING_STRATEGY.md exists"
    else
        test_fail "docs/BRANCHING_STRATEGY.md NOT found"
    fi
}

################################################################################
# Test Category 5: Commit Quality
################################################################################

test_commits() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 5: Commit Quality"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 5.1: Minimum commit count
    test_start "Sufficient commits (minimum 5)"
    COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    if [ "$COMMIT_COUNT" -ge 5 ]; then
        test_pass "$COMMIT_COUNT commits found (excellent!)"
    elif [ "$COMMIT_COUNT" -ge 3 ]; then
        test_warning "$COMMIT_COUNT commits found (minimum is 5)"
    else
        test_fail "Only $COMMIT_COUNT commits (need at least 5)"
    fi

    # Test 5.2: Conventional Commits format (sample check)
    test_start "Conventional Commits format used"
    CONVENTIONAL_COUNT=$(git log --oneline | grep -cE "^[a-f0-9]+ (feat|fix|docs|chore|style|refactor|test|perf|ci|build|revert):" || echo "0")
    if [ "$CONVENTIONAL_COUNT" -ge 3 ]; then
        test_pass "Conventional Commits format detected ($CONVENTIONAL_COUNT commits)"
    else
        test_warning "Few Conventional Commits found. Use: feat:, fix:, docs:, chore:, etc."
    fi

    # Test 5.3: Commit messages not too short
    test_start "Commit messages are descriptive"
    SHORT_MESSAGES=$(git log --oneline | awk '{print $2}' | awk 'length($0) < 10' | wc -l)
    TOTAL_COMMITS=$(git log --oneline | wc -l)
    if [ "$SHORT_MESSAGES" -eq 0 ]; then
        test_pass "All commit messages are descriptive"
    elif [ "$SHORT_MESSAGES" -lt $(( TOTAL_COMMITS / 2 )) ]; then
        test_warning "$SHORT_MESSAGES commits have short messages (< 10 chars)"
    else
        test_fail "Too many short commit messages ($SHORT_MESSAGES/$TOTAL_COMMITS)"
        echo "  Use descriptive messages: 'feat: add nginx playbook for webservers'"
    fi
}

################################################################################
# Test Category 6: Infrastructure Files
################################################################################

test_infrastructure_files() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 6: Infrastructure Files"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 6.1: Ansible playbook
    test_start "Ansible playbook exists"
    if find ansible/playbooks -name "*.yml" -o -name "*.yaml" | grep -q .; then
        test_pass "Ansible playbook(s) found"
    else
        test_warning "No Ansible playbooks found in ansible/playbooks/"
    fi

    # Test 6.2: Dockerfile
    test_start "Dockerfile exists"
    if find docker -name "Dockerfile" | grep -q .; then
        test_pass "Dockerfile(s) found"
    else
        test_warning "No Dockerfiles found in docker/"
    fi

    # Test 6.3: Scripts
    test_start "Scripts exist"
    if [ -d "scripts" ] && [ "$(ls -A scripts 2>/dev/null | wc -l)" -gt 0 ]; then
        test_pass "Scripts found in scripts/"
    else
        test_warning "No scripts found in scripts/"
    fi
}

################################################################################
# Test Category 7: Secrets Management
################################################################################

test_secrets_management() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 7: Secrets Management"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 7.1: .env.example exists
    test_start ".env.example template exists"
    if [ -f ".env.example" ]; then
        test_pass ".env.example exists"
    else
        test_fail ".env.example NOT found"
    fi

    # Test 7.2: .env.example is committed
    test_start ".env.example is committed"
    if git ls-files | grep -q "^\.env\.example$"; then
        test_pass ".env.example is committed to Git"
    else
        test_fail ".env.example NOT committed"
    fi

    # Test 7.3: .env is NOT committed (if exists)
    test_start ".env is NOT committed to Git"
    if [ -f ".env" ]; then
        if git ls-files | grep -q "^\.env$"; then
            test_fail "❌ CRITICAL: .env is committed to Git! This is a security risk!"
            echo "  ACTION REQUIRED: Remove from Git history immediately!"
        else
            test_pass ".env exists but is NOT committed (correct)"
        fi
    else
        test_warning ".env file not found (will be created by user from .env.example)"
    fi

    # Test 7.4: Secrets documentation
    test_start "Secrets management documented"
    if [ -f "docs/SECRETS_MANAGEMENT.md" ]; then
        test_pass "SECRETS_MANAGEMENT.md exists"
    else
        test_fail "docs/SECRETS_MANAGEMENT.md NOT found"
    fi

    # Test 7.5: No secrets in commit history (sample check)
    test_start "No obvious secrets in commit messages"
    if git log --all --oneline | grep -iE "(password|secret.*=|key.*=)" | head -1 | grep -q .; then
        test_warning "Potential secret references found in commit messages"
        echo "  Review: git log --all | grep -i password"
    else
        test_pass "No obvious secrets in commit messages"
    fi
}

################################################################################
# Test Category 8: Git Audit
################################################################################

test_git_audit() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 8: Git Audit Report"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 8.1: Audit script exists
    test_start "Git audit script exists"
    if [ -f "scripts/git_audit.sh" ]; then
        test_pass "scripts/git_audit.sh exists"
    else
        test_fail "scripts/git_audit.sh NOT found"
        return 1
    fi

    # Test 8.2: Audit script is executable
    test_start "Audit script is executable"
    if [ -x "scripts/git_audit.sh" ]; then
        test_pass "scripts/git_audit.sh is executable"
    else
        test_fail "scripts/git_audit.sh is NOT executable"
        echo "  Run: chmod +x scripts/git_audit.sh"
    fi

    # Test 8.3: Audit report exists
    test_start "Git audit report exists"
    if [ -f "git_audit_report.txt" ]; then
        test_pass "git_audit_report.txt exists"
    else
        test_warning "git_audit_report.txt NOT found (run ./scripts/git_audit.sh)"
    fi
}

################################################################################
# Test Category 9: Documentation
################################################################################

test_documentation() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 9: Documentation Quality"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 9.1: Main README
    test_start "Main README.md is comprehensive"
    if [ -f "README.md" ]; then
        README_LINES=$(wc -l < README.md)
        if [ "$README_LINES" -ge 20 ]; then
            test_pass "README.md is comprehensive ($README_LINES lines)"
        else
            test_warning "README.md is short ($README_LINES lines)"
        fi
    fi

    # Test 9.2: Required docs exist
    REQUIRED_DOCS=(
        "docs/BRANCHING_STRATEGY.md"
        "docs/SECRETS_MANAGEMENT.md"
    )

    for doc in "${REQUIRED_DOCS[@]}"; do
        test_start "Documentation exists: $doc"
        if [ -f "$doc" ]; then
            test_pass "$doc exists"
        else
            test_fail "$doc NOT found"
        fi
    done
}

################################################################################
# Test Category 10: Best Practices
################################################################################

test_best_practices() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Category 10: Git Best Practices"
    echo "═══════════════════════════════════════════════════════════════"

    cd "$REPO_PATH" || return 1

    # Test 10.1: No large files (>10MB)
    test_start "No large files in repository"
    LARGE_FILES=$(find . -type f ! -path './.git/*' -size +10M 2>/dev/null | wc -l)
    if [ "$LARGE_FILES" -eq 0 ]; then
        test_pass "No large files (>10MB) found"
    else
        test_warning "$LARGE_FILES large files found. Consider Git LFS."
    fi

    # Test 10.2: Git repository size reasonable
    test_start "Git repository size is reasonable"
    if [ -d ".git" ]; then
        GIT_SIZE=$(du -sm .git | cut -f1)
        if [ "$GIT_SIZE" -lt 100 ]; then
            test_pass "Git repository size: ${GIT_SIZE}MB (good)"
        elif [ "$GIT_SIZE" -lt 500 ]; then
            test_warning "Git repository size: ${GIT_SIZE}MB (consider cleanup)"
        else
            test_fail "Git repository size: ${GIT_SIZE}MB (too large!)"
        fi
    fi

    # Test 10.3: README mentions project
    test_start "README mentions 'Operation Shadow'"
    if [ -f "README.md" ] && grep -qi "operation shadow" README.md; then
        test_pass "README mentions Operation Shadow"
    else
        test_warning "README does not mention 'Operation Shadow'"
    fi
}

################################################################################
# Final Summary
################################################################################

print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Total tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Tests failed:${NC} $TESTS_FAILED"
    echo ""

    PASS_RATE=$(( TESTS_PASSED * 100 / TESTS_RUN ))

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✓ ALL TESTS PASSED! ($PASS_RATE%)${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Excellent work! Your Git repository is properly configured."
        echo ""
        echo "Next steps:"
        echo "  1. Review: cd $REPO_PATH && git log --oneline --graph --all"
        echo "  2. Read audit: cat $REPO_PATH/git_audit_report.txt"
        echo "  3. Continue to Episode 14: Docker Basics (Amsterdam)"
        echo ""
        return 0
    elif [ "$PASS_RATE" -ge 80 ]; then
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  ⚠ TESTS MOSTLY PASSED ($PASS_RATE%)${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Good progress! Fix remaining issues above."
        return 1
    else
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  ✗ TESTS FAILED ($PASS_RATE%)${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Review failed tests above and fix issues."
        echo "See Episode 13 README.md for detailed instructions."
        return 1
    fi
}

################################################################################
# Main execution
################################################################################

main() {
    echo ""
    echo "################################################################"
    echo "  KERNEL SHADOWS: Episode 13 — Git & Version Control"
    echo "  Test Suite"
    echo "################################################################"
    echo ""

    # Check if repository exists
    if [ ! -d "$REPO_PATH" ]; then
        echo -e "${RED}ERROR:${NC} Repository not found at $REPO_PATH"
        echo ""
        echo "Expected location: $REPO_PATH"
        echo ""
        echo "To create repository, run:"
        echo "  cd ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control"
        echo "  ./starter.sh"
        echo ""
        exit 1
    fi

    # Run all test categories
    test_git_repository || true
    test_directory_structure || true
    test_gitignore || true
    test_branching || true
    test_commits || true
    test_infrastructure_files || true
    test_secrets_management || true
    test_git_audit || true
    test_documentation || true
    test_best_practices || true

    # Print summary
    print_summary
}

# Run main
main "$@"


