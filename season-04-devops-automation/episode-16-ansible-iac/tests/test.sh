#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 16 Tests
# Ansible & Infrastructure as Code Validation
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
PROJECT_DIR="$HOME/operation-shadow-ansible"

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
# Test 1: Ansible Installation
################################################################################
test_ansible_installation() {
    print_test "Ansible installation"

    if command -v ansible > /dev/null 2>&1; then
        pass "Ansible installed"

        VERSION=$(ansible --version | head -1)
        echo "     Version: $VERSION"

        if command -v ansible-playbook > /dev/null 2>&1; then
            pass "ansible-playbook available"
        else
            fail "ansible-playbook not found"
        fi

        if command -v ansible-vault > /dev/null 2>&1; then
            pass "ansible-vault available"
        else
            fail "ansible-vault not found"
        fi

    else
        fail "Ansible not installed"
        warn "Install: sudo apt install -y ansible"
    fi
}

################################################################################
# Test 2: Project Structure
################################################################################
test_project_structure() {
    print_test "Project structure"

    if [ -d "$PROJECT_DIR" ]; then
        pass "Project directory exists"
    else
        fail "Project directory not found: $PROJECT_DIR"
        return
    fi

    # Check required files
    local required_files=(
        "inventory.ini"
        "playbook.yml"
        "ansible.cfg"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$PROJECT_DIR/$file" ]; then
            pass "$file exists"
        else
            fail "$file not found"
        fi
    done

    # Check directories
    if [ -d "$PROJECT_DIR/roles" ]; then
        pass "roles/ directory exists"
    else
        fail "roles/ directory not found"
    fi

    if [ -d "$PROJECT_DIR/group_vars" ]; then
        pass "group_vars/ directory exists"
    else
        warn "group_vars/ directory not found (recommended)"
    fi
}

################################################################################
# Test 3: Inventory File
################################################################################
test_inventory() {
    print_test "Inventory file"

    if [ ! -f "$PROJECT_DIR/inventory.ini" ]; then
        fail "inventory.ini not found"
        return
    fi

    pass "inventory.ini exists"

    # Check for required groups
    local required_groups=("[web]" "[database]" "[cache]" "[production:children]" "[production:vars]")

    for group in "${required_groups[@]}"; do
        if grep -q "$group" "$PROJECT_DIR/inventory.ini"; then
            pass "Group $group defined"
        else
            fail "Group $group not found"
        fi
    done

    # Check for server definitions
    if grep -qE "(web-|db-|cache-|app-)" "$PROJECT_DIR/inventory.ini"; then
        pass "Server definitions found"
    else
        fail "No server definitions found"
    fi

    # Test inventory syntax (if servers accessible)
    if command -v ansible-inventory > /dev/null 2>&1; then
        cd "$PROJECT_DIR"
        if ansible-inventory -i inventory.ini --list > /dev/null 2>&1; then
            pass "Inventory syntax valid"
        else
            fail "Inventory syntax error"
        fi
    fi
}

################################################################################
# Test 4: Playbook Syntax
################################################################################
test_playbook_syntax() {
    print_test "Playbook syntax"

    if [ ! -f "$PROJECT_DIR/playbook.yml" ]; then
        fail "playbook.yml not found"
        return
    fi

    cd "$PROJECT_DIR"

    # Check YAML syntax
    if ansible-playbook playbook.yml --syntax-check > /dev/null 2>&1; then
        pass "playbook.yml syntax valid"
    else
        fail "playbook.yml syntax error"
    fi

    # Check for required sections
    if grep -q "^- name:" "$PROJECT_DIR/playbook.yml"; then
        pass "Playbook has name"
    else
        fail "Playbook missing name"
    fi

    if grep -q "hosts:" "$PROJECT_DIR/playbook.yml"; then
        pass "Playbook has hosts"
    else
        fail "Playbook missing hosts"
    fi

    if grep -q "tasks:" "$PROJECT_DIR/playbook.yml"; then
        pass "Playbook has tasks"
    else
        fail "Playbook missing tasks"
    fi

    # Check for become
    if grep -q "become:" "$PROJECT_DIR/playbook.yml"; then
        pass "Playbook uses become (sudo)"
    else
        warn "Playbook should use 'become: yes' for admin tasks"
    fi
}

################################################################################
# Test 5: Roles
################################################################################
test_roles() {
    print_test "Roles structure"

    if [ ! -d "$PROJECT_DIR/roles" ]; then
        fail "roles/ directory not found"
        return
    fi

    # Check for roles
    local roles=("common" "webserver" "database")

    for role in "${roles[@]}"; do
        if [ -d "$PROJECT_DIR/roles/$role" ]; then
            pass "Role '$role' exists"

            # Check role structure
            if [ -d "$PROJECT_DIR/roles/$role/tasks" ]; then
                pass "  $role/tasks/ exists"

                if [ -f "$PROJECT_DIR/roles/$role/tasks/main.yml" ]; then
                    pass "  $role/tasks/main.yml exists"
                else
                    fail "  $role/tasks/main.yml not found"
                fi
            else
                fail "  $role/tasks/ not found"
            fi

            # Check handlers (for webserver)
            if [ "$role" = "webserver" ]; then
                if [ -d "$PROJECT_DIR/roles/$role/handlers" ] && [ -f "$PROJECT_DIR/roles/$role/handlers/main.yml" ]; then
                    pass "  $role/handlers/main.yml exists"
                else
                    warn "  $role/handlers/ recommended for service restarts"
                fi

                # Check templates
                if [ -d "$PROJECT_DIR/roles/$role/templates" ]; then
                    pass "  $role/templates/ exists"

                    if ls "$PROJECT_DIR/roles/$role/templates"/*.j2 > /dev/null 2>&1; then
                        pass "  Jinja2 templates found"
                    else
                        warn "  No .j2 templates found"
                    fi
                else
                    warn "  $role/templates/ recommended for configs"
                fi
            fi

        else
            fail "Role '$role' not found"
        fi
    done
}

################################################################################
# Test 6: Variables
################################################################################
test_variables() {
    print_test "Variables configuration"

    if [ -d "$PROJECT_DIR/group_vars" ]; then
        pass "group_vars/ exists"

        # Check for common vars
        if [ -f "$PROJECT_DIR/group_vars/all.yml" ]; then
            pass "group_vars/all.yml exists"
        else
            warn "group_vars/all.yml recommended for common variables"
        fi

        # Check for group-specific vars
        if [ -f "$PROJECT_DIR/group_vars/web.yml" ]; then
            pass "group_vars/web.yml exists"
        else
            warn "group_vars/web.yml recommended for web servers"
        fi

    else
        warn "group_vars/ directory not found (recommended)"
    fi

    if [ -d "$PROJECT_DIR/host_vars" ]; then
        pass "host_vars/ exists"
    else
        warn "host_vars/ not found (optional, for host-specific vars)"
    fi
}

################################################################################
# Test 7: Templates
################################################################################
test_templates() {
    print_test "Jinja2 templates"

    # Check for .j2 files in roles
    if find "$PROJECT_DIR/roles" -name "*.j2" 2>/dev/null | grep -q .; then
        pass "Jinja2 templates found"

        # Check for variable usage in templates
        local templates=$(find "$PROJECT_DIR/roles" -name "*.j2")
        for template in $templates; do
            if grep -q "{{" "$template"; then
                pass "Template uses variables: $(basename $template)"
            else
                warn "Template has no variables: $(basename $template)"
            fi
        done

    else
        warn "No Jinja2 templates found (recommended for dynamic configs)"
    fi
}

################################################################################
# Test 8: Handlers
################################################################################
test_handlers() {
    print_test "Handlers configuration"

    # Check for handlers in roles
    if find "$PROJECT_DIR/roles" -path "*/handlers/main.yml" 2>/dev/null | grep -q .; then
        pass "Handlers found"

        # Check handler content
        local handler_files=$(find "$PROJECT_DIR/roles" -path "*/handlers/main.yml")
        for handler_file in $handler_files; do
            if grep -q "^- name:" "$handler_file"; then
                pass "Handler defined in $(basename $(dirname $(dirname $handler_file)))/handlers/main.yml"
            fi
        done

    else
        warn "No handlers found (recommended for service restarts)"
    fi
}

################################################################################
# Test 9: Security Audit Playbook
################################################################################
test_audit_playbook() {
    print_test "Security audit playbook"

    if [ -f "$PROJECT_DIR/audit.yml" ]; then
        pass "audit.yml exists"

        # Check syntax
        cd "$PROJECT_DIR"
        if ansible-playbook audit.yml --syntax-check > /dev/null 2>&1; then
            pass "audit.yml syntax valid"
        else
            fail "audit.yml syntax error"
        fi

        # Check for security checks
        local security_checks=(
            "UID 0"
            "empty password"
            "SSH"
            "suspicious process"
            "open ports"
            "firewall"
        )

        for check in "${security_checks[@]}"; do
            if grep -iq "$check" "$PROJECT_DIR/audit.yml"; then
                pass "Audit checks for: $check"
            else
                warn "Audit missing check for: $check"
            fi
        done

    else
        fail "audit.yml not found"
    fi
}

################################################################################
# Test 10: Ansible Configuration
################################################################################
test_ansible_cfg() {
    print_test "Ansible configuration"

    if [ -f "$PROJECT_DIR/ansible.cfg" ]; then
        pass "ansible.cfg exists"

        # Check for recommended settings
        if grep -q "^inventory" "$PROJECT_DIR/ansible.cfg"; then
            pass "Inventory path configured"
        else
            warn "Inventory path not configured in ansible.cfg"
        fi

        if grep -q "host_key_checking" "$PROJECT_DIR/ansible.cfg"; then
            pass "Host key checking configured"
        else
            warn "host_key_checking recommended (False for testing)"
        fi

        if grep -q "roles_path" "$PROJECT_DIR/ansible.cfg"; then
            pass "Roles path configured"
        else
            warn "roles_path recommended in ansible.cfg"
        fi

    else
        warn "ansible.cfg not found (recommended for project settings)"
    fi
}

################################################################################
# Test 11: Best Practices
################################################################################
test_best_practices() {
    print_test "Best practices"

    # Check for idempotent modules
    if [ -f "$PROJECT_DIR/playbook.yml" ]; then
        # Check if using proper modules (not shell for package management)
        if grep -q "apt:" "$PROJECT_DIR/playbook.yml" || grep -q "package:" "$PROJECT_DIR/playbook.yml"; then
            pass "Uses apt/package modules (idempotent)"
        else
            warn "Consider using apt module instead of shell for packages"
        fi

        # Check for service module
        if grep -q "service:" "$PROJECT_DIR/playbook.yml" || grep -q "systemd:" "$PROJECT_DIR/playbook.yml"; then
            pass "Uses service/systemd module (idempotent)"
        else
            warn "Consider using service module for service management"
        fi
    fi

    # Check for README
    if [ -f "$PROJECT_DIR/README.md" ]; then
        pass "README.md exists (documentation)"
    else
        warn "README.md recommended for documentation"
    fi

    # Check for .gitignore
    if [ -f "$PROJECT_DIR/.gitignore" ]; then
        pass ".gitignore exists"
    else
        warn ".gitignore recommended (ignore *.retry, vault passwords)"
    fi
}

################################################################################
# Test 12: Integration Test (if possible)
################################################################################
test_integration() {
    print_test "Integration test"

    cd "$PROJECT_DIR"

    # Test local ping
    if ansible localhost -m ping --connection=local > /dev/null 2>&1; then
        pass "Local ping successful"
    else
        warn "Local ping failed (not critical)"
    fi

    # Test playbook check mode (dry run)
    if ansible-playbook playbook.yml -i "localhost," --connection=local --check > /dev/null 2>&1; then
        pass "Playbook dry run successful"
    else
        warn "Playbook dry run failed (may need sudo or real servers)"
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
        echo "Klaus Schmidt: 'Good. Ansible infrastructure solid.'"
        echo "               '50 servers, 3 minutes, one command. Ready.'"
        echo ""
        echo "SEASON 4: DEVOPS & AUTOMATION — COMPLETE! 🎉"
        echo ""
        echo "Next: Season 5: Security & Pentesting (Zürich 🇨🇭)"
        echo "      Eva Zimmerman awaits."
        echo ""
        return 0
    else
        echo -e "${RED}✗ Some tests failed.${NC}"
        echo ""
        echo "LILITH: 'Fix the failures. Infrastructure as Code must be solid.'"
        echo "        'Automation at scale requires correctness.'"
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
    echo "  KERNEL SHADOWS: Episode 16 Tests"
    echo "  Ansible & Infrastructure as Code Validation"
    echo "  SEASON 4 FINALE!"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    test_ansible_installation
    echo ""
    test_project_structure
    echo ""
    test_inventory
    echo ""
    test_playbook_syntax
    echo ""
    test_roles
    echo ""
    test_variables
    echo ""
    test_templates
    echo ""
    test_handlers
    echo ""
    test_audit_playbook
    echo ""
    test_ansible_cfg
    echo ""
    test_best_practices
    echo ""
    test_integration

    print_summary
}

main "$@"


