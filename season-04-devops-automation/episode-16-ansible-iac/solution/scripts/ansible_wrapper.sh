#!/bin/bash

################################################################################
# KERNEL SHADOWS: Episode 16 — Ansible Helper
# MINIMAL wrapper for Ansible commands (Type B Approach!)
#
# Philosophy: "Ansible exists → use it, don't wrap it"
# This script is ONLY for convenience. Learn ansible-playbook!
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")/ansible"

cd "$ANSIBLE_DIR" || exit 1

################################################################################
# Usage
################################################################################

usage() {
    cat << EOF
Usage: $0 {check|apply|limit|tags}

Commands:
  check         - Dry-run (check mode, no changes)
  apply         - Apply playbook to all 50 servers
  limit GROUP   - Apply only to specific group (web, database, etc.)
  tags TAG      - Apply only specific tags (common, monitoring, etc.)

This is a MINIMAL wrapper. For advanced usage, use ansible-playbook directly:
  ansible-playbook -i inventory.ini playbook.yml --check
  ansible-playbook -i inventory.ini playbook.yml --limit web
  ansible-playbook -i inventory.ini playbook.yml --tags monitoring

EOF
    exit 1
}

################################################################################
# Main Commands
################################################################################

case "${1:-}" in
    check)
        echo -e "${BLUE}Running playbook in CHECK mode (dry-run)...${NC}"
        ansible-playbook -i inventory.ini playbook.yml --check
        ;;

    apply)
        echo -e "${YELLOW}Applying playbook to ALL production servers...${NC}"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ansible-playbook -i inventory.ini playbook.yml
            echo -e "${GREEN}✓ Configuration applied${NC}"
        fi
        ;;

    limit)
        if [[ -z "${2:-}" ]]; then
            echo "Error: Specify group (web, database, cache, monitoring, app)"
            exit 1
        fi
        echo -e "${BLUE}Applying playbook to group: ${2}${NC}"
        ansible-playbook -i inventory.ini playbook.yml --limit "$2"
        ;;

    tags)
        if [[ -z "${2:-}" ]]; then
            echo "Error: Specify tag (common, web, database, monitoring, etc.)"
            exit 1
        fi
        echo -e "${BLUE}Applying playbook with tags: ${2}${NC}"
        ansible-playbook -i inventory.ini playbook.yml --tags "$2"
        ;;

    *)
        usage
        ;;
esac

################################################################################
# Type B Philosophy:
#
# This wrapper is ~70 lines (vs 910 lines in old ansible_setup.sh!)
#
# Real work is done by:
#   - inventory.ini (servers)
#   - playbook.yml (tasks)
#   - roles/ (reusable components)
#   - group_vars/ (configuration)
#
# Learn Ansible, don't hide it behind bash!
#
# "50 servers, one command, 3 minutes. That's Ansible." — Klaus Schmidt
################################################################################


