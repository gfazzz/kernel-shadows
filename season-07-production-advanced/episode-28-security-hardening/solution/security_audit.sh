#!/bin/bash
# security_audit.sh - Automated Security Audit Script (REFERENCE SOLUTION)
# Episode 28: Security Hardening
# KERNEL SHADOWS - Season 7

set -euo pipefail

# ============================================================================
# VARIABLES
# ============================================================================

REPORT_FILE="security_audit_$(date +%Y%m%d_%H%M%S).txt"
LOG_FILE="/var/log/security_audit.log"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
CRITICAL_COUNT=0
WARNING_COUNT=0
OK_COUNT=0

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_status() {
    local status=$1
    local message=$2

    case $status in
        "OK")
            echo -e "${GREEN}🟢 $message${NC}"
            ((OK_COUNT++))
            ;;
        "WARNING")
            echo -e "${YELLOW}🟡 $message${NC}"
            ((WARNING_COUNT++))
            ;;
        "CRITICAL")
            echo -e "${RED}🔴 $message${NC}"
            ((CRITICAL_COUNT++))
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

    if ! command_exists getenforce; then
        # SELinux not installed (может быть Ubuntu с AppArmor)
        if command_exists aa-status; then
            print_status "WARNING" "SELinux not installed (AppArmor detected)"

            # Check AppArmor instead
            if sudo aa-status --enabled 2>/dev/null; then
                profiles_enforcing=$(sudo aa-status 2>/dev/null | grep "profiles are in enforce mode" | awk '{print $1}')
                print_status "OK" "AppArmor active ($profiles_enforcing profiles enforcing)"
            else
                print_status "CRITICAL" "AppArmor disabled!"
            fi
        else
            print_status "CRITICAL" "Neither SELinux nor AppArmor installed!"
        fi
        return
    fi

    # SELinux installed
    selinux_status=$(getenforce)

    case $selinux_status in
        "Enforcing")
            print_status "OK" "SELinux: Enforcing mode (active protection)"
            ;;
        "Permissive")
            print_status "WARNING" "SELinux: Permissive mode (logging only, not blocking!)"
            ;;
        "Disabled")
            print_status "CRITICAL" "SELinux: Disabled (no MAC protection!)"
            ;;
    esac
}

check_auditd() {
    echo ""
    echo "=== AUDITD STATUS ==="

    if ! command_exists auditctl; then
        print_status "CRITICAL" "auditd not installed!"
        return
    fi

    if ! systemctl is-active --quiet auditd 2>/dev/null; then
        print_status "CRITICAL" "auditd not running!"
        return
    fi

    print_status "OK" "auditd running"

    # Check audit rules
    rules_count=$(sudo auditctl -l 2>/dev/null | grep -v "No rules" | wc -l)

    if [ "$rules_count" -gt 0 ]; then
        print_status "OK" "Audit rules loaded ($rules_count rules)"
    else
        print_status "WARNING" "No audit rules configured!"
    fi

    # Check audit log exists and is being written
    if [ -f "/var/log/audit/audit.log" ]; then
        log_size=$(stat -f%z "/var/log/audit/audit.log" 2>/dev/null || stat -c%s "/var/log/audit/audit.log" 2>/dev/null || echo 0)
        print_status "OK" "Audit log active ($log_size bytes)"
    else
        print_status "WARNING" "Audit log not found"
    fi
}

check_fail2ban() {
    echo ""
    echo "=== FAIL2BAN STATUS ==="

    if ! command_exists fail2ban-client; then
        print_status "WARNING" "fail2ban not installed (no automatic brute-force protection)"
        return
    fi

    if ! systemctl is-active --quiet fail2ban 2>/dev/null; then
        print_status "CRITICAL" "fail2ban installed but not running!"
        return
    fi

    print_status "OK" "fail2ban running"

    # Check active jails
    jails=$(sudo fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | sed 's/,/ /g' | wc -w || echo 0)

    if [ "$jails" -gt 0 ]; then
        print_status "OK" "Active jails: $jails"

        # Show jail details
        for jail in $(sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | sed 's/,//g'); do
            banned=$(sudo fail2ban-client status "$jail" | grep "Currently banned" | awk '{print $NF}')
            echo "  - $jail: $banned banned IPs"
        done
    else
        print_status "WARNING" "No active jails configured!"
    fi
}

check_ssh_config() {
    echo ""
    echo "=== SSH CONFIGURATION ==="

    if [ ! -f "/etc/ssh/sshd_config" ]; then
        print_status "WARNING" "SSH config not found (SSH not installed?)"
        return
    fi

    # Check PermitRootLogin
    root_login=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}' || echo "not_set")
    if [[ "$root_login" == "no" || "$root_login" == "prohibit-password" ]]; then
        print_status "OK" "PermitRootLogin: $root_login (secure)"
    else
        print_status "CRITICAL" "PermitRootLogin: $root_login (should be 'no' or 'prohibit-password')"
    fi

    # Check PasswordAuthentication
    password_auth=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}' || echo "yes")
    if [ "$password_auth" == "no" ]; then
        print_status "OK" "PasswordAuthentication: no (key-based only)"
    else
        print_status "WARNING" "PasswordAuthentication: $password_auth (recommend 'no' for max security)"
    fi

    # Check Port
    port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
    if [ "$port" != "22" ]; then
        print_status "OK" "SSH Port: $port (non-standard, good for obscurity)"
    else
        print_status "WARNING" "SSH Port: 22 (default, consider changing for obscurity)"
    fi

    # Check Protocol
    protocol=$(grep "^Protocol" /etc/ssh/sshd_config | awk '{print $2}' || echo "2")
    if [ "$protocol" == "2" ]; then
        print_status "OK" "Protocol: 2 (secure)"
    else
        print_status "CRITICAL" "Protocol: $protocol (should be 2 only!)"
    fi
}

check_sysctl_security() {
    echo ""
    echo "=== SYSCTL SECURITY PARAMETERS ==="

    # IP forwarding
    ip_forward=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "N/A")
    if [ "$ip_forward" == "0" ]; then
        print_status "OK" "IP forwarding disabled"
    elif [ "$ip_forward" == "1" ]; then
        print_status "WARNING" "IP forwarding enabled (OK if router, risky if server)"
    fi

    # Source routing
    accept_source_route=$(sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null || echo "N/A")
    if [ "$accept_source_route" == "0" ]; then
        print_status "OK" "Source routing disabled (anti-spoofing)"
    else
        print_status "CRITICAL" "Source routing enabled (IP spoofing risk!)"
    fi

    # SYN cookies
    syn_cookies=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null || echo "N/A")
    if [ "$syn_cookies" == "1" ]; then
        print_status "OK" "SYN cookies enabled (DDoS protection)"
    else
        print_status "WARNING" "SYN cookies disabled (vulnerable to SYN flood!)"
    fi

    # ASLR
    aslr=$(sysctl -n kernel.randomize_va_space 2>/dev/null || echo "N/A")
    if [ "$aslr" == "2" ]; then
        print_status "OK" "ASLR: full randomization (exploit mitigation)"
    elif [ "$aslr" == "1" ]; then
        print_status "WARNING" "ASLR: partial randomization (should be 2)"
    else
        print_status "CRITICAL" "ASLR: disabled (exploit risk!)"
    fi

    # dmesg restrict
    dmesg_restrict=$(sysctl -n kernel.dmesg_restrict 2>/dev/null || echo "N/A")
    if [ "$dmesg_restrict" == "1" ]; then
        print_status "OK" "dmesg restricted to root (info leak protection)"
    else
        print_status "WARNING" "dmesg accessible to all users (info leak risk)"
    fi
}

check_firewall() {
    echo ""
    echo "=== FIREWALL STATUS ==="

    # Check ufw (Ubuntu)
    if command_exists ufw; then
        ufw_status=$(sudo ufw status | head -1 | awk '{print $2}')
        if [ "$ufw_status" == "active" ]; then
            print_status "OK" "ufw firewall active"
        else
            print_status "CRITICAL" "ufw firewall inactive!"
        fi
    # Check firewalld (RHEL/CentOS)
    elif command_exists firewall-cmd; then
        if systemctl is-active --quiet firewalld; then
            print_status "OK" "firewalld active"
        else
            print_status "CRITICAL" "firewalld inactive!"
        fi
    # Check iptables
    elif command_exists iptables; then
        rules_count=$(sudo iptables -L | grep -v "^Chain\|^target" | wc -l)
        if [ "$rules_count" -gt 0 ]; then
            print_status "OK" "iptables rules configured ($rules_count rules)"
        else
            print_status "CRITICAL" "No firewall rules configured!"
        fi
    else
        print_status "CRITICAL" "No firewall detected!"
    fi
}

check_updates() {
    echo ""
    echo "=== AUTOMATIC UPDATES ==="

    # Ubuntu/Debian
    if command_exists apt-get; then
        if dpkg -l | grep -q unattended-upgrades; then
            print_status "OK" "unattended-upgrades installed"

            # Check if configured
            if [ -f "/etc/apt/apt.conf.d/50unattended-upgrades" ]; then
                print_status "OK" "Automatic security updates configured"
            else
                print_status "WARNING" "unattended-upgrades installed but not configured"
            fi
        else
            print_status "WARNING" "unattended-upgrades not installed (no automatic updates)"
        fi
    # RHEL/CentOS
    elif command_exists yum; then
        if yum list installed | grep -q yum-cron; then
            print_status "OK" "yum-cron installed (automatic updates)"
        else
            print_status "WARNING" "yum-cron not installed (no automatic updates)"
        fi
    fi
}

check_file_permissions() {
    echo ""
    echo "=== FILE PERMISSIONS ==="

    # /etc/shadow
    if [ -f "/etc/shadow" ]; then
        shadow_perms=$(stat -c '%a' /etc/shadow 2>/dev/null || stat -f '%OLp' /etc/shadow 2>/dev/null || echo "N/A")
        if [[ "$shadow_perms" == "000" || "$shadow_perms" == "640" ]]; then
            print_status "OK" "/etc/shadow: $shadow_perms (secure)"
        else
            print_status "CRITICAL" "/etc/shadow: $shadow_perms (should be 000 or 640!)"
        fi
    fi

    # /etc/sudoers
    if [ -f "/etc/sudoers" ]; then
        sudoers_perms=$(stat -c '%a' /etc/sudoers 2>/dev/null || stat -f '%OLp' /etc/sudoers 2>/dev/null || echo "N/A")
        if [ "$sudoers_perms" == "440" ]; then
            print_status "OK" "/etc/sudoers: $sudoers_perms (secure)"
        else
            print_status "WARNING" "/etc/sudoers: $sudoers_perms (should be 440)"
        fi
    fi

    # SSH config
    if [ -f "/etc/ssh/sshd_config" ]; then
        sshd_perms=$(stat -c '%a' /etc/ssh/sshd_config 2>/dev/null || stat -f '%OLp' /etc/ssh/sshd_config 2>/dev/null || echo "N/A")
        if [[ "$sshd_perms" == "644" || "$sshd_perms" == "600" ]]; then
            print_status "OK" "/etc/ssh/sshd_config: $sshd_perms (secure)"
        else
            print_status "WARNING" "/etc/ssh/sshd_config: $sshd_perms (should be 644 or 600)"
        fi
    fi
}

check_open_ports() {
    echo ""
    echo "=== OPEN PORTS AUDIT ==="

    if command_exists ss; then
        # Count listening ports
        listening_tcp=$(ss -tuln | grep LISTEN | grep -v "127.0.0.1\|::1" | wc -l)

        echo "  Listening TCP ports (external): $listening_tcp"

        # Show ports
        ss -tuln | grep LISTEN | grep -v "127.0.0.1\|::1" | while read -r line; do
            port=$(echo "$line" | awk '{print $5}' | rev | cut -d: -f1 | rev)
            echo "    - Port $port"
        done

        # Common ports check
        if ss -tuln | grep -q ":22 "; then
            print_status "OK" "SSH port open (expected)"
        fi

        if ss -tuln | grep -qE ":(80|443) "; then
            print_status "OK" "Web server ports open (80/443)"
        fi

        # Unexpected ports
        if ss -tuln | grep -qE ":(23|21|3389) "; then
            print_status "CRITICAL" "Insecure ports detected (telnet:23, ftp:21, rdp:3389)!"
        fi

        if [ "$listening_tcp" -gt 10 ]; then
            print_status "WARNING" "Many open ports ($listening_tcp) - review necessity"
        else
            print_status "OK" "Reasonable number of open ports"
        fi
    else
        print_status "WARNING" "ss command not available"
    fi
}

check_rootkit() {
    echo ""
    echo "=== ROOTKIT SCAN ==="

    if command_exists rkhunter; then
        print_status "OK" "rkhunter installed"
        echo "  Run 'sudo rkhunter --check' for full scan"
    elif command_exists chkrootkit; then
        print_status "OK" "chkrootkit installed"
        echo "  Run 'sudo chkrootkit' for full scan"
    else
        print_status "WARNING" "No rootkit scanner installed (install rkhunter or chkrootkit)"
    fi
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
    echo "Kernel: $(uname -r)"
    echo ""
    echo -e "${GREEN}OK:       $OK_COUNT${NC}"
    echo -e "${YELLOW}WARNING:  $WARNING_COUNT${NC}"
    echo -e "${RED}CRITICAL: $CRITICAL_COUNT${NC}"
    echo ""
    echo "Report saved to: $REPORT_FILE"
    echo "Log file: $LOG_FILE"
    echo ""

    if [ $CRITICAL_COUNT -gt 0 ]; then
        echo -e "${RED}⚠️  CRITICAL ISSUES FOUND! Address immediately!${NC}"
    elif [ $WARNING_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Warnings found - review and improve security${NC}"
    else
        echo -e "${GREEN}✅ No critical issues - good security posture!${NC}"
    fi

    echo ""
    echo "🔒 Remember: Security is a process, not a product."
    echo "   Regular audits + continuous improvement = defense in depth."
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

