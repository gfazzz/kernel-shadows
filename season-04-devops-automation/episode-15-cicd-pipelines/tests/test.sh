#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 15 Tests
# CI/CD Pipelines Validation
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
PROJECT_DIR="$HOME/operation-shadow-cicd"

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

pass() {
    echo -e "${GREEN}  ✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}  ✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}  ⚠${NC} $1"
}

################################################################################
# Test 1: Project Structure
################################################################################
test_project_structure() {
    print_test "Project structure"

    if [ -d "$PROJECT_DIR" ]; then
        pass "Project directory exists"
    else
        fail "Project directory not found: $PROJECT_DIR"
        return
    fi

    if [ -d "$PROJECT_DIR/.github/workflows" ]; then
        pass "Workflows directory exists"
    else
        fail "Workflows directory not found"
    fi

    if [ -d "$PROJECT_DIR/tests" ]; then
        pass "Tests directory exists"
    else
        fail "Tests directory not found"
    fi

    if [ -d "$PROJECT_DIR/docs" ]; then
        pass "Documentation directory exists"
    else
        warn "Documentation directory not found (optional)"
    fi
}

################################################################################
# Test 2: GitHub Actions Workflows
################################################################################
test_workflows() {
    print_test "GitHub Actions workflows"

    # CI/CD workflow
    if [ -f "$PROJECT_DIR/.github/workflows/ci-cd.yml" ] ||
       [ -f "$PROJECT_DIR/.github/workflows/ci.yml" ]; then
        pass "CI/CD workflow exists"

        WORKFLOW_FILE=$(find "$PROJECT_DIR/.github/workflows" -name "ci*.yml" | head -1)

        # Check for required jobs
        if grep -q "jobs:" "$WORKFLOW_FILE"; then
            pass "Workflow has jobs defined"
        else
            fail "No jobs found in workflow"
        fi

        if grep -q "test:" "$WORKFLOW_FILE" || grep -q "test" "$WORKFLOW_FILE"; then
            pass "Test job exists"
        else
            fail "Test job not found"
        fi

        if grep -q "build" "$WORKFLOW_FILE"; then
            pass "Build job exists"
        else
            fail "Build job not found"
        fi

        if grep -q "deploy" "$WORKFLOW_FILE"; then
            pass "Deploy job exists"
        else
            warn "Deploy job not found (may be in separate workflow)"
        fi

    else
        fail "CI/CD workflow not found"
    fi

    # Rollback workflow
    if [ -f "$PROJECT_DIR/.github/workflows/rollback.yml" ]; then
        pass "Rollback workflow exists"

        if grep -q "workflow_dispatch" "$PROJECT_DIR/.github/workflows/rollback.yml"; then
            pass "Rollback has manual trigger"
        else
            fail "Rollback workflow must use workflow_dispatch"
        fi
    else
        warn "Rollback workflow not found (recommended)"
    fi
}

################################################################################
# Test 3: Automated Tests
################################################################################
test_automated_tests() {
    print_test "Automated tests"

    if [ -f "$PROJECT_DIR/tests/test.sh" ]; then
        pass "Test script exists"

        if [ -x "$PROJECT_DIR/tests/test.sh" ]; then
            pass "Test script is executable"
        else
            fail "Test script is not executable (chmod +x)"
        fi

        # Check test content
        if grep -q "Dockerfile" "$PROJECT_DIR/tests/test.sh"; then
            pass "Tests check Dockerfile"
        else
            warn "Tests should validate Dockerfile"
        fi

        if grep -q "docker build" "$PROJECT_DIR/tests/test.sh"; then
            pass "Tests include Docker build"
        else
            warn "Tests should build Docker image"
        fi

    else
        fail "Test script not found: tests/test.sh"
    fi
}

################################################################################
# Test 4: Docker Configuration
################################################################################
test_docker_config() {
    print_test "Docker configuration"

    if [ -f "$PROJECT_DIR/Dockerfile" ]; then
        pass "Dockerfile exists"

        # Check Dockerfile content
        if grep -q "FROM" "$PROJECT_DIR/Dockerfile"; then
            pass "Dockerfile has FROM instruction"
        else
            fail "Dockerfile missing FROM instruction"
        fi

        if grep -q "HEALTHCHECK" "$PROJECT_DIR/Dockerfile"; then
            pass "Dockerfile has health check"
        else
            warn "Dockerfile should include HEALTHCHECK"
        fi

        if grep -q "EXPOSE" "$PROJECT_DIR/Dockerfile"; then
            pass "Dockerfile exposes port"
        else
            warn "Dockerfile should EXPOSE port"
        fi

    else
        fail "Dockerfile not found"
    fi

    # Docker Compose
    if [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
        pass "docker-compose.yml exists"

        if grep -q "version:" "$PROJECT_DIR/docker-compose.yml"; then
            pass "docker-compose has version"
        else
            fail "docker-compose.yml missing version"
        fi

        if grep -q "services:" "$PROJECT_DIR/docker-compose.yml"; then
            pass "docker-compose has services"
        else
            fail "docker-compose.yml missing services"
        fi

    else
        warn "docker-compose.yml not found (recommended)"
    fi
}

################################################################################
# Test 5: Workflow Syntax (YAML validation)
################################################################################
test_workflow_syntax() {
    print_test "Workflow syntax validation"

    if command -v yamllint > /dev/null 2>&1; then
        WORKFLOW_FILES=$(find "$PROJECT_DIR/.github/workflows" -name "*.yml" 2>/dev/null)

        if [ -n "$WORKFLOW_FILES" ]; then
            SYNTAX_OK=true
            for file in $WORKFLOW_FILES; do
                if yamllint -d relaxed "$file" > /dev/null 2>&1; then
                    pass "$(basename "$file") — valid YAML"
                else
                    fail "$(basename "$file") — invalid YAML"
                    SYNTAX_OK=false
                fi
            done

            if [ "$SYNTAX_OK" = true ]; then
                pass "All workflows have valid YAML syntax"
            fi
        fi
    else
        warn "yamllint not installed, skipping syntax validation"
        warn "Install: pip install yamllint"
    fi
}

################################################################################
# Test 6: Deployment Configuration
################################################################################
test_deployment_config() {
    print_test "Deployment configuration"

    WORKFLOW_FILE=$(find "$PROJECT_DIR/.github/workflows" -name "*.yml" | head -1)

    if [ -f "$WORKFLOW_FILE" ]; then
        # Check for staging deployment
        if grep -q "staging" "$WORKFLOW_FILE"; then
            pass "Staging deployment configured"
        else
            warn "No staging deployment found"
        fi

        # Check for production deployment
        if grep -q "production" "$WORKFLOW_FILE"; then
            pass "Production deployment configured"
        else
            warn "No production deployment found"
        fi

        # Check for environment protection
        if grep -q "environment:" "$WORKFLOW_FILE"; then
            pass "Environment protection configured"
        else
            warn "No environment protection (manual approval recommended)"
        fi

        # Check for secrets usage
        if grep -q "secrets\." "$WORKFLOW_FILE"; then
            pass "Secrets configured in workflow"
        else
            warn "No secrets found (may need Docker/SSH credentials)"
        fi
    fi
}

################################################################################
# Test 7: Rollback Strategy
################################################################################
test_rollback_strategy() {
    print_test "Rollback strategy"

    if [ -f "$PROJECT_DIR/.github/workflows/rollback.yml" ]; then
        pass "Rollback workflow exists"

        ROLLBACK_FILE="$PROJECT_DIR/.github/workflows/rollback.yml"

        # Check for version input
        if grep -q "version:" "$ROLLBACK_FILE"; then
            pass "Rollback accepts version parameter"
        else
            fail "Rollback workflow should accept version input"
        fi

        # Check for health check
        if grep -q "health" "$ROLLBACK_FILE"; then
            pass "Rollback includes health verification"
        else
            warn "Rollback should verify health after restore"
        fi

    else
        fail "Rollback workflow not found"
    fi
}

################################################################################
# Test 8: Documentation
################################################################################
test_documentation() {
    print_test "Documentation"

    if [ -f "$PROJECT_DIR/docs/CICD.md" ] ||
       [ -f "$PROJECT_DIR/README.md" ]; then
        pass "Documentation exists"
    else
        warn "No documentation found (recommended)"
    fi

    if [ -f "$PROJECT_DIR/CICD_REPORT.txt" ]; then
        pass "Setup report generated"
    else
        warn "Setup report not found (may be generated by solution)"
    fi
}

################################################################################
# Test 9: Git Configuration
################################################################################
test_git_config() {
    print_test "Git repository"

    if [ -d "$PROJECT_DIR/.git" ]; then
        pass "Git repository initialized"

        cd "$PROJECT_DIR"

        # Check for commits
        if git log > /dev/null 2>&1; then
            pass "Repository has commits"
        else
            warn "No commits yet"
        fi

        # Check for .gitignore
        if [ -f ".gitignore" ]; then
            pass ".gitignore exists"

            if grep -q "\.key" .gitignore || grep -q "\.env" .gitignore; then
                pass ".gitignore protects secrets"
            else
                warn ".gitignore should protect secrets (*.key, .env)"
            fi
        else
            fail ".gitignore not found"
        fi

    else
        fail "Git repository not initialized"
    fi
}

################################################################################
# Test 10: Best Practices
################################################################################
test_best_practices() {
    print_test "CI/CD best practices"

    WORKFLOW_FILES=$(find "$PROJECT_DIR/.github/workflows" -name "*.yml" 2>/dev/null)

    if [ -n "$WORKFLOW_FILES" ]; then
        # Check for needs (job dependencies)
        if grep -q "needs:" $WORKFLOW_FILES; then
            pass "Job dependencies configured (needs:)"
        else
            warn "Consider adding job dependencies for sequential execution"
        fi

        # Check for conditionals
        if grep -q "if:" $WORKFLOW_FILES; then
            pass "Conditional execution configured"
        else
            warn "Consider adding conditionals (if:) for branch-specific jobs"
        fi

        # Check for caching
        if grep -q "cache" $WORKFLOW_FILES; then
            pass "Build caching configured"
        else
            warn "Consider adding caching to speed up builds"
        fi

        # Check for on: pull_request
        if grep -q "pull_request" $WORKFLOW_FILES; then
            pass "PR validation configured"
        else
            warn "Consider running tests on PRs (on: pull_request)"
        fi
    fi

    # Check for health checks
    if [ -f "$PROJECT_DIR/Dockerfile" ]; then
        if grep -q "/health" "$PROJECT_DIR/Dockerfile" ||
           [ -f "$PROJECT_DIR/nginx.conf" ] && grep -q "/health" "$PROJECT_DIR/nginx.conf"; then
            pass "Health check endpoint configured"
        else
            warn "Consider adding /health endpoint for monitoring"
        fi
    fi
}

################################################################################
# Summary
################################################################################
print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${GREEN}Passed:${NC} $PASSED"
    echo -e "${RED}Failed:${NC} $FAILED"
    TOTAL=$((PASSED + FAILED))
    if [ $TOTAL -gt 0 ]; then
        PERCENTAGE=$((PASSED * 100 / TOTAL))
        echo "Score: $PERCENTAGE%"
    fi
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        echo "Hans Müller: 'Good. CI/CD infrastructure solid.'"
        echo "             'Now push to GitHub and watch it work.'"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Some tests failed.${NC}"
        echo ""
        echo "LILITH: 'Fix the failures. CI/CD must be reliable.'"
        echo "        'One broken workflow = 50 servers at risk.'"
        echo ""
        return 1
    fi
}

################################################################################
# Main execution
################################################################################
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  KERNEL SHADOWS: Episode 15 Tests"
    echo "  CI/CD Pipelines Validation"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    test_project_structure
    echo ""
    test_workflows
    echo ""
    test_automated_tests
    echo ""
    test_docker_config
    echo ""
    test_workflow_syntax
    echo ""
    test_deployment_config
    echo ""
    test_rollback_strategy
    echo ""
    test_documentation
    echo ""
    test_git_config
    echo ""
    test_best_practices

    print_summary
}

main "$@"


