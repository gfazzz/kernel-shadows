#!/bin/bash

# ═══════════════════════════════════════════════════════════
# KERNEL SHADOWS - Season 8, Episode 30
# Solution Script: Security Audit Day 58
# ═══════════════════════════════════════════════════════════
#
# Description: Comprehensive security audit after Day 57 attack
# Features:
#   - Docker image integrity verification
#   - AIDE full system scan
#   - SELinux violations analysis
#   - Fail2ban statistics aggregation
#   - Threat intelligence correlation
#   - Final comprehensive report
#
# ═══════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
LOG_FILE="/var/log/security_audit_day58.log"
REPORT_FILE="reports/day58_security_audit.md"
ARTIFACTS_DIR="artifacts"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# ═══════════════════════════════════════════════════════════
# 1. Docker Image Integrity Check
# ═══════════════════════════════════════════════════════════

check_docker_integrity() {
    log "=== Docker Image Integrity Check ==="

    local suspicious_count=0
    local clean_count=0

    # Симуляция: Проверка контрольных сумм образов
    if [[ -f "$ARTIFACTS_DIR/docker/compromised_images.txt" ]]; then
        suspicious_count=$(wc -l < "$ARTIFACTS_DIR/docker/compromised_images.txt")
        log_warning "Found $suspicious_count suspicious Docker images"

        while IFS= read -r image; do
            log_error "  - Compromised: $image"
        done < "$ARTIFACTS_DIR/docker/compromised_images.txt"
    else
        log_warning "Compromised images file not found, using mock data"
        suspicious_count=1
        log_error "  - Compromised: viktor/crypto-toolkit:latest (digest mismatch)"
    fi

    # Чистые образы
    clean_count=$(($(docker images 2>/dev/null | wc -l) - suspicious_count - 1)) || clean_count=49
    log_success "Verified $clean_count clean Docker images"

    echo "$suspicious_count" > /tmp/audit_docker_suspicious_count.txt
    echo "$clean_count" > /tmp/audit_docker_clean_count.txt
}

# ═══════════════════════════════════════════════════════════
# 2. AIDE Full Scan
# ═══════════════════════════════════════════════════════════

check_aide() {
    log "=== AIDE Full System Scan ==="

    local servers_with_anomalies=0
    local total_servers=50

    # Симуляция: Запуск AIDE на всех серверах через Ansible
    log "Running AIDE scans on $total_servers servers (this may take time)..."

    # Используем mock данные из артефактов
    if [[ -f "$ARTIFACTS_DIR/forensics/aide_anomalies.txt" ]]; then
        servers_with_anomalies=$(grep -c "server-" "$ARTIFACTS_DIR/forensics/aide_anomalies.txt" || echo 0)

        log_warning "Servers with anomalies detected: $servers_with_anomalies"

        while IFS= read -r line; do
            if [[ $line == server-* ]]; then
                log_error "  - $line"
            fi
        done < "$ARTIFACTS_DIR/forensics/aide_anomalies.txt"
    else
        log_warning "AIDE anomalies file not found, using mock data"
        servers_with_anomalies=0
    fi

    local clean_servers=$((total_servers - servers_with_anomalies))
    log_success "Clean servers: $clean_servers/$total_servers"

    echo "$servers_with_anomalies" > /tmp/audit_aide_anomalies.txt
    echo "$clean_servers" > /tmp/audit_aide_clean.txt
}

# ═══════════════════════════════════════════════════════════
# 3. SELinux Violations Check
# ═══════════════════════════════════════════════════════════

check_selinux_violations() {
    log "=== SELinux Violations Analysis ==="

    local total_violations=0
    local suspicious_violations=0
    local legitimate_violations=0

    # Симуляция: Проверка SELinux violations
    if [[ -f "$ARTIFACTS_DIR/logs/selinux_violations.log" ]]; then
        total_violations=$(wc -l < "$ARTIFACTS_DIR/logs/selinux_violations.log")

        # Классификация (mock logic)
        suspicious_violations=$(grep -c "sshd_backup\|suspicious\|backdoor" "$ARTIFACTS_DIR/logs/selinux_violations.log" || echo 0)
        legitimate_violations=$((total_violations - suspicious_violations))

        log "Total violations: $total_violations"
        log_success "Legitimate: $legitimate_violations (normal application behavior)"
        log_warning "Suspicious: $suspicious_violations (potential threats)"

        if [[ $suspicious_violations -gt 0 ]]; then
            log_error "Suspicious violations detected:"
            grep "sshd_backup\|suspicious\|backdoor" "$ARTIFACTS_DIR/logs/selinux_violations.log" | head -5 | while read -r line; do
                log_error "  - $line"
            done
        fi
    else
        log "No SELinux violations logged"
        total_violations=0
    fi

    echo "$total_violations" > /tmp/audit_selinux_total.txt
    echo "$suspicious_violations" > /tmp/audit_selinux_suspicious.txt
}

# ═══════════════════════════════════════════════════════════
# 4. Fail2ban Statistics
# ═══════════════════════════════════════════════════════════

check_fail2ban_stats() {
    log "=== Fail2ban Statistics Collection ==="

    local total_banned=0
    local top_attackers=""

    # Симуляция: Сбор статистики Fail2ban
    if [[ -f "$ARTIFACTS_DIR/logs/fail2ban_banned_ips.txt" ]]; then
        total_banned=$(wc -l < "$ARTIFACTS_DIR/logs/fail2ban_banned_ips.txt")

        log "Total banned IPs: $total_banned"

        # Топ-10 атакующих
        log "Top 10 attacking IPs:"
        head -10 "$ARTIFACTS_DIR/logs/fail2ban_banned_ips.txt" | while read -r ip; do
            log "  - $ip"
        done

        # География атак (mock данные)
        log "Attack geography:"
        log "  - Russia: 45%"
        log "  - China: 23%"
        log "  - USA (VPN): 15%"
        log "  - Netherlands (TOR): 10%"
        log "  - Other: 7%"
    else
        log_warning "Fail2ban statistics not found, using mock data"
        total_banned=847
        log "Total banned IPs: $total_banned (from Day 57 attack)"
    fi

    echo "$total_banned" > /tmp/audit_fail2ban_banned.txt
}

# ═══════════════════════════════════════════════════════════
# 5. Threat Intelligence Aggregation
# ═══════════════════════════════════════════════════════════

aggregate_threat_intel() {
    log "=== Threat Intelligence Aggregation ==="

    local total_ips=0
    local tor_nodes=0
    local vpn_ips=0
    local botnet_ips=0
    local known_malicious=0

    # Симуляция: OSINT анализ
    if [[ -f "$ARTIFACTS_DIR/threat_intel/suspicious_ips.txt" ]]; then
        total_ips=$(wc -l < "$ARTIFACTS_DIR/threat_intel/suspicious_ips.txt")

        # Классификация (mock logic)
        tor_nodes=$(grep -c "TOR" "$ARTIFACTS_DIR/threat_intel/ip_classification.txt" 2>/dev/null || echo 85)
        vpn_ips=$(grep -c "VPN" "$ARTIFACTS_DIR/threat_intel/ip_classification.txt" 2>/dev/null || echo 127)
        botnet_ips=$(grep -c "Botnet" "$ARTIFACTS_DIR/threat_intel/ip_classification.txt" 2>/dev/null || echo 435)
        known_malicious=$(grep -c "Malicious" "$ARTIFACTS_DIR/threat_intel/ip_classification.txt" 2>/dev/null || echo 200)

        log "Total suspicious IPs analyzed: $total_ips"
        log "Classification:"
        log "  - TOR exit nodes: $tor_nodes (10%)"
        log "  - VPN exit points: $vpn_ips (15%)"
        log "  - Botnet members: $botnet_ips (51%)"
        log "  - Known malicious: $known_malicious (24%)"

        # C2 server
        if [[ -f "$ARTIFACTS_DIR/threat_intel/c2_server.txt" ]]; then
            local c2_ip=$(cat "$ARTIFACTS_DIR/threat_intel/c2_server.txt")
            log_error "C2 Server identified: $c2_ip"
            log "  Location: St. Petersburg, Russia"
            log "  Organization: Nova Era Operations"
        fi
    else
        log_warning "Threat intel data not found, using mock data"
        total_ips=847
        tor_nodes=85
        vpn_ips=127
        botnet_ips=435
        known_malicious=200
    fi

    echo "$total_ips" > /tmp/audit_threat_total_ips.txt
    echo "$tor_nodes" > /tmp/audit_threat_tor.txt
    echo "$botnet_ips" > /tmp/audit_threat_botnet.txt
}

# ═══════════════════════════════════════════════════════════
# 6. Generate Final Report
# ═══════════════════════════════════════════════════════════

generate_final_report() {
    log "=== Generating Final Comprehensive Report ==="

    # Читаем собранные данные
    local docker_suspicious=$(cat /tmp/audit_docker_suspicious_count.txt 2>/dev/null || echo 1)
    local docker_clean=$(cat /tmp/audit_docker_clean_count.txt 2>/dev/null || echo 49)
    local aide_anomalies=$(cat /tmp/audit_aide_anomalies.txt 2>/dev/null || echo 0)
    local aide_clean=$(cat /tmp/audit_aide_clean.txt 2>/dev/null || echo 50)
    local selinux_total=$(cat /tmp/audit_selinux_total.txt 2>/dev/null || echo 0)
    local selinux_suspicious=$(cat /tmp/audit_selinux_suspicious.txt 2>/dev/null || echo 0)
    local fail2ban_banned=$(cat /tmp/audit_fail2ban_banned.txt 2>/dev/null || echo 847)
    local threat_total=$(cat /tmp/audit_threat_total_ips.txt 2>/dev/null || echo 847)
    local threat_tor=$(cat /tmp/audit_threat_tor.txt 2>/dev/null || echo 85)
    local threat_botnet=$(cat /tmp/audit_threat_botnet.txt 2>/dev/null || echo 435)

    # Создать Markdown отчёт
    cat > "$REPORT_FILE" << EOF
# Security Audit Report — Day 58

**Generated:** $(date '+%Y-%m-%d %H:%M:%S UTC')
**Auditor:** LILITH v8.0 + Max Sokolov
**Infrastructure:** 50 servers, global distributed operation
**Status:** Post-incident analysis after Day 57 attack

---

## Executive Summary

After the intensive Day 57 attack (DDoS 100+ Gbps, zero-day exploit, APT backdoors), a comprehensive security audit was conducted during the brief calm period (Day 58, 06:00-20:00 UTC).

**Key Findings:**
- ✅ All compromised Docker images rebuilt and verified
- ✅ Infrastructure hardened (SELinux enforcing, auditd, fail2ban)
- ✅ 47/50 servers cleaned and verified
- ⚠️  The Architect identity still unknown
- ⚠️  Next attack expected Day 59-60

---

## 1. Docker Image Integrity Check

**Status:** ⚠️ **CRITICAL FINDINGS**

| Metric | Count |
|--------|-------|
| Total Images Checked | $((docker_suspicious + docker_clean)) |
| Clean Images | $docker_clean |
| Compromised Images | $docker_suspicious |

**Compromised Image Details:**
- **Image:** \`viktor/crypto-toolkit:latest\`
- **Issue:** Supply chain attack (Docker Hub account phishing)
- **Infection Date:** Day 43 (October 10, 2025, 14:23 UTC)
- **Scope:** 47/50 servers affected
- **Remediation:** Full rebuild from verified Ubuntu 22.04 base image

**Attack Vector:**
1. Marcus Weber credentials stolen via phishing (Day 42)
2. Attacker pushed modified image with backdoor (Day 43)
3. Backdoors dormant for 14 days before activation (Day 57)

**Verification:**
\`\`\`bash
# Official digest (Docker Hub): sha256:a2b3c4d5e6f7...
# Compromised digest:           sha256:7f8a3d9e2c1b...
# Status after rebuild:         sha256:a2b3c4d5e6f7... ✅ CLEAN
\`\`\`

---

## 2. AIDE System Integrity Scan

**Status:** ✅ **CLEAN (after remediation)**

| Metric | Count |
|--------|-------|
| Servers Scanned | 50 |
| Clean Servers | $aide_clean |
| Servers with Anomalies | $aide_anomalies |

**Before Rebuild (Day 57):**
- 47 servers with backdoor files detected
- Files: \`/usr/lib/systemd/sshd_backup\`, \`/usr/bin/curl\` (modified)

**After Rebuild (Day 58):**
- All anomalies removed
- AIDE baseline updated
- Daily scans scheduled (cron: 02:00 UTC)

**AIDE Configuration:**
\`\`\`bash
# Monitored paths:
- /usr/bin (critical binaries)
- /usr/lib (system libraries)
- /etc (configuration files)
- /root/.ssh (SSH keys)
\`\`\`

---

## 3. SELinux Violations Analysis

**Status:** ✅ **OPERATIONAL**

| Metric | Count |
|--------|-------|
| Total Violations Logged | $selinux_total |
| Legitimate Violations | $((selinux_total - selinux_suspicious)) |
| Suspicious Violations | $selinux_suspicious |

**SELinux Mode:** Enforcing (on all 50 servers)

**Violation Breakdown:**
- **Legitimate:** Normal application behavior (nginx, docker containers)
- **Suspicious:** $selinux_suspicious violations related to backdoor attempts (blocked successfully)

**Key Protection:**
- Even with root access, backdoors are constrained by SELinux policies
- Example: \`sshd_backup\` process blocked from accessing \`/home/\` directory

---

## 4. Fail2ban Statistics

**Status:** ✅ **ACTIVE**

| Metric | Count |
|--------|-------|
| Total IPs Banned | $fail2ban_banned |
| Ban Time | 24 hours (aggressive mode) |
| Max Retry | 3 attempts |

**Attack Geography:**
- 🇷🇺 Russia: 45% (382 IPs)
- 🇨🇳 China: 23% (195 IPs)
- 🇺🇸 USA (VPN): 15% (127 IPs)
- 🇳🇱 Netherlands (TOR): 10% (85 IPs)
- 🌐 Other: 7% (58 IPs)

**Top 10 Attacking IPs:**
1. 195.123.221.47 (St. Petersburg, Russia) — **C2 Server**
2. 185.220.101.52 (TOR exit node, Amsterdam)
3. 203.0.113.47 (Botnet member, China)
4. 198.51.100.23 (VPN exit point, USA)
5. 192.0.2.89 (Botnet member, Russia)
6-10. [Additional IPs logged in \`artifacts/logs/fail2ban_banned_ips.txt\`]

---

## 5. Threat Intelligence

**Status:** ⚠️ **CRITICAL ATTRIBUTION**

| Metric | Count | Percentage |
|--------|-------|------------|
| Total Suspicious IPs | $threat_total | 100% |
| TOR Exit Nodes | $threat_tor | 10% |
| VPN Exit Points | 127 | 15% |
| Botnet Members | $threat_botnet | 51% |
| Known Malicious | 200 | 24% |

**Command & Control Server:**
- **IP:** 195.123.221.47
- **Location:** St. Petersburg, Russia
- **Organization:** "Nova Era" operations center
- **Attribution:** Linked to "The Architect" (identity unknown)

**Attack Pattern:**
1. **Day 43:** Initial compromise (Docker supply chain)
2. **Day 57:** Coordinated multi-vector attack
   - DDoS: 100+ Gbps (botnet)
   - Zero-day: Nginx RCE (custom exploit)
   - APT: 5 backdoors activated simultaneously
3. **Day 58:** Tactical pause (regrouping)
4. **Day 59-60:** Expected escalation

**The Architect Clue:**
- Encrypted message found in backdoor source code
- References Day 2 (Episode 01, Novosibirsk)
- IP 10.0.1.47 (viktor-workstation) — spoofed
- Investigation ongoing (Episode 31)

---

## 6. Remediation Actions Completed

✅ **Day 58, 06:00-20:00 UTC (14 hours)**

### Infrastructure Cleanup:
1. **Docker Images:** All 47 compromised servers rebuilt from clean source
2. **AIDE:** Baseline updated, anomalies cleared
3. **Backdoors:** All 5 APT backdoors removed and verified

### Hardening Measures:
1. **SELinux:** Enforcing mode on all 50 servers
2. **Auditd:** Maximum logging enabled (all syscalls monitored)
3. **Fail2ban:** Aggressive mode (3 attempts = 24h ban)
4. **Network Segmentation:** Compromised segments isolated

### Personnel:
1. **Marcus Weber:** Cleared (victim of phishing, not insider threat)
2. **Credentials:** All Docker Hub, VPN, SSH keys rotated
3. **2FA:** Enforced for all critical accounts

---

## 7. Recommendations for Day 59

### Immediate Actions (Next 12 hours):

🔴 **Critical:**
1. **Counteroffensive Preparation:**
   - Alex Sokolov to lead offensive operations
   - Target: "Nova Era" C2 server (195.123.221.47)
   - Objective: Neutralize infrastructure, identify The Architect

2. **The Architect Investigation:**
   - Deep dive into Day 2 logs (viktor-workstation)
   - MAC address spoofing analysis
   - Timeline correlation: Day 2 → Day 43 → Day 57

3. **Defense Readiness:**
   - Kubernetes HPA: Ready for instant scale to 500 pods
   - Monitoring: LILITH real-time alerts (< 1 second response)
   - Incident response: All team members on standby

🟡 **High Priority:**
1. **Supply Chain Security:**
   - Implement Docker Content Trust (image signing)
   - Verify all base images with cryptographic signatures
   - Block unsigned images from deployment

2. **Phishing Defense:**
   - Team-wide security training (recognize phishing)
   - Password managers mandatory (prevent credential reuse)
   - 2FA enforcement completed

3. **Forensics Continuation:**
   - Anna Kovaleva: Full forensics analysis of backdoor source code
   - Metadata analysis: Compile timestamps, developer artifacts
   - Attribution: Link to specific threat actor groups

🟢 **Medium Priority:**
1. **Documentation:**
   - Incident response playbook updates (lessons learned)
   - Timeline documentation (Day 2 → Day 58)
   - Team coordination protocols (sleep rotation, decision fatigue management)

2. **Backup Verification:**
   - Test restore procedures (disaster recovery)
   - Offsite backup integrity check
   - Immutable backups (protection against ransomware)

---

## 8. Security Posture Assessment

**Overall Status:** 🟡 **GUARDED**

| Component | Status | Notes |
|-----------|--------|-------|
| Infrastructure | ✅ CLEAN | All 47 servers rebuilt and verified |
| Monitoring | ✅ ACTIVE | LILITH v8.0 real-time detection |
| Hardening | ✅ ENFORCED | SELinux + auditd + fail2ban |
| Team | 🟡 EXHAUSTED | 14 hours continuous work, 4h rest |
| Threat | 🔴 ACTIVE | Next attack expected Day 59-60 |
| The Architect | 🔴 UNKNOWN | Identity and capabilities unknown |

**Risk Level:** 🔴 **HIGH**

**Justification:**
- "Nova Era" has demonstrated advanced capabilities (supply chain, zero-day, APT)
- The Architect remains unidentified (high intelligence, patient, methodical)
- Day 57 was reconnaissance, not full assault
- Day 59-60 expected to be decisive battle

---

## 9. Conclusion

Day 58 was successfully utilized for comprehensive forensics, cleanup, and hardening. Infrastructure is now significantly more resilient than Day 56 pre-attack baseline.

**Key Achievements:**
- Supply chain attack fully remediated
- Marcus Weber cleared (team integrity maintained)
- Defense posture upgraded from "adequate" to "hardened"

**Open Questions:**
- Who is The Architect?
- Why reference Day 2 (Novosibirsk)?
- What is "Nova Era" ultimate objective?

**Next 24 Hours:**
- Counteroffensive against "Nova Era" (Episode 31)
- The Architect identity revelation expected
- Final confrontation approaching (Day 60)

---

**Report compiled by:** LILITH v8.0 + Max Sokolov
**Reviewed by:** Anna Kovaleva (Forensics Lead), Viktor Petrov (Operations Commander)
**Distribution:** Core Team Only (CONFIDENTIAL)

---

*"You weathered the eye of the storm. But the storm is not over."* — LILITH v8.0
EOF

    log_success "Comprehensive report generated: $REPORT_FILE"

    # Cleanup temporary files
    rm -f /tmp/audit_*.txt
}

# ═══════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════

main() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN} Episode 30: Eye of the Storm — Security Audit Day 58${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    log "=== Security Audit Day 58 Started ==="
    log "Timestamp: $(date '+%Y-%m-%d %H:%M:%S UTC')"
    log "Auditor: LILITH v8.0 + Max Sokolov"
    log ""

    # Create reports directory
    mkdir -p reports/ 2>/dev/null || true

    # Execute all audit checks
    check_docker_integrity
    echo ""

    check_aide
    echo ""

    check_selinux_violations
    echo ""

    check_fail2ban_stats
    echo ""

    aggregate_threat_intel
    echo ""

    generate_final_report
    echo ""

    log ""
    log "=== Security Audit Complete ==="
    log "Report available at: $REPORT_FILE"
    log "Log file: $LOG_FILE"

    echo ""
    echo -e "${GREEN}✅ Security audit completed successfully${NC}"
    echo -e "📊 Full report: ${BLUE}$REPORT_FILE${NC}"
    echo -e "📝 Audit log: ${BLUE}$LOG_FILE${NC}"
    echo ""
    echo -e "${YELLOW}Next: Day 59 counteroffensive (Episode 31)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

# Run main
main "$@"

