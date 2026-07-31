#!/bin/bash
# security_audit.sh - Automated Security Audit Script
# Episode 28: Security Hardening
# KERNEL SHADOWS - Season 7

# TODO: Complete this script to audit system security
# Requirements:
# 1. Check SELinux status
# 2. Check auditd running
# 3. Check fail2ban active
# 4. Check SSH config (password auth disabled, root login disabled)
# 5. Check sysctl security parameters
# 6. Check firewall active
# 7. Check automatic updates
# 8. Check file permissions (/etc/shadow, /etc/sudoers)
# 9. Check open ports
# 10. Generate colored security report (🟢/🟡/🔴)

set -euo pipefail

# ============================================================================
# VARIABLES
# ============================================================================

REPORT_FILE="security_audit_$(date +%Y%m%d_%H%M%S).txt"
LOG_FILE="/var/log/security_audit.log"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_status() {
    local status=$1
    local message=$2

    case $status in
        "OK")
            echo "🟢 $message"
            ;;
        "WARNING")
            echo "🟡 $message"
            ;;
        "CRITICAL")
            echo "🔴 $message"
            ;;
        *)
            echo "  $message"
            ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# AUDIT FUNCTIONS
# ============================================================================

check_selinux() {
    echo ""
    echo "=== SELINUX STATUS ==="

    # TODO: Implement SELinux check
    # - Check if SELinux installed (command 'getenforce' exists)
    # - Check mode (Enforcing/Permissive/Disabled)
    # - OK if Enforcing
    # - WARNING if Permissive
    # - CRITICAL if Disabled or not installed

    print_status "WARNING" "SELinux check not implemented yet!"
}

check_auditd() {
    echo ""
    echo "=== AUDITD STATUS ==="

    # TODO: Implement auditd check
    # - Check if auditd installed
    # - Check if auditd running (systemctl is-active auditd)
    # - Check if audit rules loaded (auditctl -l)
    # - OK if running with rules
    # - WARNING if running without rules
    # - CRITICAL if not running

    print_status "WARNING" "auditd check not implemented yet!"
}

check_fail2ban() {
    echo ""
    echo "=== FAIL2BAN STATUS ==="

    # TODO: Implement fail2ban check
    # - Check if fail2ban installed
    # - Check if running
    # - Check active jails (fail2ban-client status)
    # - OK if running with jails
    # - WARNING if running without jails
    # - CRITICAL if not running

    print_status "WARNING" "fail2ban check not implemented yet!"
}

check_ssh_config() {
    echo ""
    echo "=== SSH CONFIGURATION ==="

    # TODO: Implement SSH config check
    # Check in /etc/ssh/sshd_config:
    # - PermitRootLogin (should be 'no')
    # - PasswordAuthentication (should be 'no' for max security)
    # - Port (recommend != 22 for obscurity)
    # - Protocol (should be 2)
    #
    # Use: grep "^PermitRootLogin" /etc/ssh/sshd_config
    # (^ means start of line, ignores comments)

    print_status "WARNING" "SSH config check not implemented yet!"
}

check_sysctl_security() {
    echo ""
    echo "=== SYSCTL SECURITY PARAMETERS ==="

    # TODO: Implement sysctl security check
    # Check critical security parameters:
    # - net.ipv4.ip_forward (should be 0 if not router)
    # - net.ipv4.conf.all.accept_source_route (should be 0)
    # - net.ipv4.tcp_syncookies (should be 1)
    # - kernel.randomize_va_space (should be 2)
    # - kernel.dmesg_restrict (should be 1)
    #
    # Use: sysctl -n net.ipv4.ip_forward

    print_status "WARNING" "sysctl security check not implemented yet!"
}

check_firewall() {
    echo ""
    echo "=== FIREWALL STATUS ==="

    # TODO: Implement firewall check
    # Check if firewall active:
    # - ufw status (Ubuntu)
    # - iptables -L (generic)
    # - firewalld status (RHEL/CentOS)
    #
    # OK if active
    # CRITICAL if inactive

    print_status "WARNING" "Firewall check not implemented yet!"
}

check_updates() {
    echo ""
    echo "=== AUTOMATIC UPDATES ==="

    # TODO: Implement automatic updates check
    # Ubuntu: check if unattended-upgrades installed and configured
    # - dpkg -l | grep unattended-upgrades
    # - /etc/apt/apt.conf.d/50unattended-upgrades exists
    #
    # OK if configured
    # WARNING if not configured

    print_status "WARNING" "Automatic updates check not implemented yet!"
}

check_file_permissions() {
    echo ""
    echo "=== FILE PERMISSIONS ==="

    # TODO: Implement file permissions check
    # Critical files should have restricted permissions:
    # - /etc/shadow: 640 or 000 (root:shadow or root:root)
    # - /etc/sudoers: 440 (root:root)
    # - /etc/ssh/sshd_config: 644 or 600
    # - ~/.ssh/authorized_keys: 600
    #
    # Use: stat -c '%a' /etc/shadow  # Get octal permissions

    print_status "WARNING" "File permissions check not implemented yet!"
}

check_open_ports() {
    echo ""
    echo "=== OPEN PORTS AUDIT ==="

    # TODO: Implement open ports check
    # List listening ports:
    # - ss -tuln (preferred)
    # - netstat -tuln (legacy)
    #
    # WARNING if unexpected ports open
    # Show which services listening

    print_status "WARNING" "Open ports check not implemented yet!"
}

check_rootkit() {
    echo ""
    echo "=== ROOTKIT SCAN ==="

    # TODO: Implement rootkit check (optional)
    # Tools: rkhunter, chkrootkit
    # If installed, run basic check
    # If not installed, skip with note

    print_status "WARNING" "Rootkit scan not implemented yet!"
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_summary() {
    echo ""
    echo "========================================"
    echo " SECURITY AUDIT SUMMARY"
    echo "========================================"
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
    echo "Report saved to: $REPORT_FILE"
    echo ""
    echo "⚠️  Review all CRITICAL and WARNING items!"
    echo "🔒 Security is a process, not a product."
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo "========================================"
    echo " SECURITY AUDIT"
    echo " KERNEL SHADOWS - Episode 28"
    echo "========================================"
    echo "Starting audit at $(date)"

    # Run all checks
    check_selinux
    check_auditd
    check_fail2ban
    check_ssh_config
    check_sysctl_security
    check_firewall
    check_updates
    check_file_permissions
    check_open_ports
    check_rootkit

    # Generate summary
    generate_summary

    echo ""
    echo "✅ Security audit complete!"
}

# Run main function and save output to file
main "$@" | tee "$REPORT_FILE"

# Also append to log file
cat "$REPORT_FILE" >> "$LOG_FILE" 2>/dev/null || true

exit 0

