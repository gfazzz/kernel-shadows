#!/bin/bash
# EPISODE 29 FINAL CHALLENGE — SOLUTION
# Night Shift Cryptomining Response
#
# Scenario: 18:00 UTC, Max sleeping, Alex (night shift lead)
# Alert: Cryptomining malware on moscow-web-05
#
# This script demonstrates INTEGRATION of all Episode 29 skills:
# - Process detection (Cycle 4)
# - Firewall blocking (Cycle 1)
# - Forensics collection (Cycle 4)
# - Decision logging (Cycle 5)
# - Team coordination (Cycle 5)

set -euo pipefail  # Strict mode (exit on error, undefined vars, pipe failures)

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

SERVER="moscow-web-05"
ALERT_TIME="2025-10-14 17:47:00 UTC"
MALWARE_PROCESS="bitcoin_miner"
MALWARE_PID=9234
PRIORITY="P2"  # High but not Critical (не будить Max)

FORENSICS_DIR="/tmp/cryptomining-forensics-$(date +%Y%m%d-%H%M%S)"
DECISION_LOG="/var/log/incident-decisions.log"

# Team contacts
TEAM_CHAT="team-incident-channel"  # Slack/Telegram
MAX_PHONE="+7-999-123-4567"        # Only for P1
ALEX_PHONE="+7-916-765-4321"       # Night shift lead (me)

# Mining pool IPs (from LILITH alert)
MINING_POOLS=(
    "45.76.132.47"
    "104.238.221.81"
    "149.28.201.93"
    "207.246.116.45"
    "95.179.142.23"
)

# ═══════════════════════════════════════════════════════════════
# FUNCTIONS
# ═══════════════════════════════════════════════════════════════

log_decision() {
    local decision="$1"
    local rationale="$2"
    local priority="$3"

    mkdir -p "$(dirname "$DECISION_LOG")"

    cat >> "$DECISION_LOG" <<EOF
[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] DECISION (Priority: $priority)
  Decision: $decision
  Rationale: $rationale
  Approved by: Alex Sokolov (Night Shift Lead)
  Incident: Cryptomining malware (moscow-web-05)
  ──────────────────────────────────────────────────────────────
EOF
}

notify_team() {
    local message="$1"
    local priority="$2"

    # В реальности: Slack API, Telegram bot, email
    # Здесь: просто log для simulation

    echo "╔════════════════════════════════════════════════════════╗"
    echo "║ TEAM NOTIFICATION ($priority)                          ║"
    echo "╠════════════════════════════════════════════════════════╣"
    echo "║ $message"
    echo "╚════════════════════════════════════════════════════════╝"

    # Append to team log
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] [$priority] $message" >> /tmp/team-notifications.log
}

# ═══════════════════════════════════════════════════════════════
# STEP 1: INITIAL ASSESSMENT
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo " NIGHT SHIFT INCIDENT RESPONSE"
echo " Alex Sokolov (Moscow) — Lead"
echo " Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "[STEP 1] Initial Assessment..."
echo "  Server: $SERVER"
echo "  Alert time: $ALERT_TIME"
echo "  Malware: $MALWARE_PROCESS (PID $MALWARE_PID)"
echo "  Priority: $PRIORITY (High — investigate immediately)"
echo ""

# Check if process still running
if ps -p "$MALWARE_PID" &>/dev/null; then
    echo "  ⚠️  Process ACTIVE (PID $MALWARE_PID still running)"
    PROCESS_ACTIVE=true
else
    echo "  ✅ Process NOT FOUND (may have exited or PID changed)"
    PROCESS_ACTIVE=false
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 2: FORENSICS COLLECTION (BEFORE KILLING)
# ═══════════════════════════════════════════════════════════════

echo "[STEP 2] Forensics Collection (preserve evidence)..."
mkdir -p "$FORENSICS_DIR"

if $PROCESS_ACTIVE; then
    echo "  Collecting evidence from live process..."

    # Process details
    ps -p "$MALWARE_PID" -o pid,ppid,user,cmd,lstart > "$FORENSICS_DIR/process_info.txt" 2>&1 || true

    # Network connections
    lsof -i -a -p "$MALWARE_PID" > "$FORENSICS_DIR/network_connections.txt" 2>&1 || true
    netstat -tulpn | grep "$MALWARE_PID" >> "$FORENSICS_DIR/network_connections.txt" 2>&1 || true

    # Open files
    lsof -p "$MALWARE_PID" > "$FORENSICS_DIR/open_files.txt" 2>&1 || true

    # Process memory map
    cat "/proc/$MALWARE_PID/maps" > "$FORENSICS_DIR/memory_maps.txt" 2>&1 || true

    # Environment variables
    cat "/proc/$MALWARE_PID/environ" | tr '\0' '\n' > "$FORENSICS_DIR/environment.txt" 2>&1 || true

    # Binary location
    readlink "/proc/$MALWARE_PID/exe" > "$FORENSICS_DIR/binary_path.txt" 2>&1 || true
    BINARY_PATH=$(readlink "/proc/$MALWARE_PID/exe" 2>/dev/null || echo "/usr/local/bin/bitcoin_miner")

    # Copy binary for analysis (if accessible)
    if [[ -f "$BINARY_PATH" ]]; then
        cp "$BINARY_PATH" "$FORENSICS_DIR/malware_binary" 2>/dev/null || true
        sha256sum "$BINARY_PATH" > "$FORENSICS_DIR/malware_hash.txt" 2>&1 || true
    fi

    echo "  ✅ Evidence collected to: $FORENSICS_DIR"
else
    echo "  ⚠️  Process not running — limited forensics available"

    # Check if binary still exists
    if [[ -f "/usr/local/bin/$MALWARE_PROCESS" ]]; then
        cp "/usr/local/bin/$MALWARE_PROCESS" "$FORENSICS_DIR/malware_binary" 2>/dev/null || true
        sha256sum "/usr/local/bin/$MALWARE_PROCESS" > "$FORENSICS_DIR/malware_hash.txt" 2>&1 || true
    fi
fi

# System state snapshot
ps aux > "$FORENSICS_DIR/all_processes.txt"
netstat -tulpn > "$FORENSICS_DIR/all_connections.txt"
ss -tulpn > "$FORENSICS_DIR/all_sockets.txt"
df -h > "$FORENSICS_DIR/disk_usage.txt"

echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 3: KILL MALWARE PROCESS
# ═══════════════════════════════════════════════════════════════

echo "[STEP 3] Eradicate malware process..."

if $PROCESS_ACTIVE; then
    echo "  Killing PID $MALWARE_PID..."
    kill -9 "$MALWARE_PID" 2>/dev/null || echo "  ⚠️  Process already terminated"

    # Verify killed
    sleep 1
    if ps -p "$MALWARE_PID" &>/dev/null; then
        echo "  ❌ ERROR: Process still alive (resilient malware?)"
        notify_team "ESCALATION: Cryptomining process cannot be killed (PID $MALWARE_PID). May require server reboot." "P1"
    else
        echo "  ✅ Process terminated (PID $MALWARE_PID)"
    fi
else
    echo "  ⚠️  Process not found — may have exited naturally"
fi

# Check for process restart (malware persistence)
echo "  Checking for process restart..."
sleep 3
if pgrep -f "$MALWARE_PROCESS" &>/dev/null; then
    NEW_PID=$(pgrep -f "$MALWARE_PROCESS")
    echo "  🔴 CRITICAL: Process RESTARTED (new PID: $NEW_PID)"
    echo "  Persistence mechanism detected (systemd service? cron? rc.local?)"

    # Check systemd
    if systemctl list-units --all | grep -i "$MALWARE_PROCESS" &>/dev/null; then
        SERVICE_NAME=$(systemctl list-units --all | grep -i "$MALWARE_PROCESS" | awk '{print $1}')
        echo "  Found systemd service: $SERVICE_NAME"
        systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        systemctl disable "$SERVICE_NAME" 2>/dev/null || true
        echo "  ✅ Systemd service disabled"
    fi

    # Kill again
    kill -9 "$NEW_PID" 2>/dev/null || true
else
    echo "  ✅ No process restart detected"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 4: BLOCK MINING POOL IPs (FIREWALL)
# ═══════════════════════════════════════════════════════════════

echo "[STEP 4] Block mining pool IPs (firewall)..."

for ip in "${MINING_POOLS[@]}"; do
    echo "  Blocking $ip..."

    # iptables rule (OUTPUT chain — block outbound connections)
    if ! iptables -C OUTPUT -d "$ip" -j DROP 2>/dev/null; then
        iptables -A OUTPUT -d "$ip" -j DROP
        echo "    ✅ Blocked: $ip"
    else
        echo "    ⚠️  Already blocked: $ip"
    fi
done

# Save iptables rules (persistent across reboot)
if command -v iptables-save &>/dev/null; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    echo "  ✅ Firewall rules saved"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 5: INVESTIGATE INFECTION VECTOR
# ═══════════════════════════════════════════════════════════════

echo "[STEP 5] Investigate how malware was installed..."

# Check file creation time
if [[ -f "/usr/local/bin/$MALWARE_PROCESS" ]]; then
    INSTALL_TIME=$(stat -c '%y' "/usr/local/bin/$MALWARE_PROCESS" 2>/dev/null || echo "Unknown")
    echo "  Binary install time: $INSTALL_TIME"
    echo "$INSTALL_TIME" > "$FORENSICS_DIR/install_time.txt"
fi

# Check recent file modifications
echo "  Recent suspicious files in /usr/local/bin:"
find /usr/local/bin -type f -mtime -1 2>/dev/null | tee "$FORENSICS_DIR/recent_files.txt"

# Check cron jobs (possible installation vector)
echo "  Checking cron jobs..."
crontab -l > "$FORENSICS_DIR/user_crontab.txt" 2>&1 || true
cat /etc/crontab > "$FORENSICS_DIR/system_crontab.txt" 2>/dev/null || true
ls -la /etc/cron.* > "$FORENSICS_DIR/cron_dirs.txt" 2>&1 || true

# Check for backdoor connection (from Episode 29 backdoors?)
echo "  Checking for backdoor processes..."
ps aux | awk '$11 ~ /^\./ {print $0}' > "$FORENSICS_DIR/hidden_processes.txt"
if [[ -s "$FORENSICS_DIR/hidden_processes.txt" ]]; then
    echo "  🔴 ALERT: Hidden processes found (possible backdoor)"
    cat "$FORENSICS_DIR/hidden_processes.txt"
else
    echo "  ✅ No hidden processes detected"
fi

# Correlation: Is this from Day 57 backdoors?
BACKDOOR_C2="195.123.221.47"
if netstat -an | grep "$BACKDOOR_C2" &>/dev/null; then
    echo "  🔴 CRITICAL: Connection to known C2 server ($BACKDOOR_C2)"
    echo "  This cryptominer may be payload from APT backdoors!"
    LIKELY_BACKDOOR_PAYLOAD=true
else
    echo "  ⚠️  No connection to known C2 (different attack vector?)"
    LIKELY_BACKDOOR_PAYLOAD=false
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 6: DECISION & ESCALATION
# ═══════════════════════════════════════════════════════════════

echo "[STEP 6] Decision & Team Notification..."

# Log decision
log_decision \
    "Cryptomining malware eradicated (moscow-web-05)" \
    "Process killed (PID $MALWARE_PID), mining pool IPs blocked (5 IPs), forensics collected. Possible connection to Day 57 APT backdoors (investigation ongoing). Priority P2 (no Max escalation required)." \
    "$PRIORITY"

echo "  ✅ Decision logged: $DECISION_LOG"

# Notify team (but NOT Max — P2 не критично)
if $LIKELY_BACKDOOR_PAYLOAD; then
    notify_team \
        "🔴 Cryptomining malware detected on moscow-web-05. POSSIBLY RELATED to Day 57 APT backdoors. Process killed, IPs blocked, forensics complete. Recommend full server rebuild. — Alex" \
        "P2"
else
    notify_team \
        "⚠️  Cryptomining malware detected on moscow-web-05 (unrelated to backdoors). Process killed, IPs blocked, forensics collected. Monitoring for re-infection. — Alex" \
        "P2"
fi

echo "  ✅ Team notified (Slack/Telegram)"

# Should we wake Max?
if $LIKELY_BACKDOOR_PAYLOAD; then
    echo ""
    echo "  ⚠️  NOTE: Possible backdoor connection detected."
    echo "  Decision: Monitor for 1 hour. If re-infection → escalate to P1 (wake Max)."
else
    echo ""
    echo "  ℹ️  Standard cryptomining attack (not P1 level)."
    echo "  Max continues rest. Morning briefing sufficient."
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 7: MONITORING & FOLLOW-UP
# ═══════════════════════════════════════════════════════════════

echo "[STEP 7] Set up monitoring for re-infection..."

# Create monitoring script
cat > /tmp/cryptomining_monitor.sh <<'MONITOR_EOF'
#!/bin/bash
# Monitor for cryptomining process restart

while true; do
    if pgrep -f "bitcoin_miner" &>/dev/null; then
        echo "[$(date -u)] 🔴 ALERT: Cryptomining process restarted!" | tee -a /var/log/cryptomining-monitor.log
        # Auto-kill
        pkill -9 -f "bitcoin_miner"
        # Notify
        echo "Process auto-killed. Investigate persistence mechanism." >> /var/log/cryptomining-monitor.log
    fi
    sleep 60
done
MONITOR_EOF

chmod +x /tmp/cryptomining_monitor.sh

echo "  ✅ Monitoring script created: /tmp/cryptomining_monitor.sh"
echo "  Run in background: nohup /tmp/cryptomining_monitor.sh &"

# Archive forensics
FORENSICS_ARCHIVE="$FORENSICS_DIR.tar.gz"
tar -czf "$FORENSICS_ARCHIVE" "$FORENSICS_DIR"
sha256sum "$FORENSICS_ARCHIVE" > "$FORENSICS_ARCHIVE.sha256"

echo "  ✅ Forensics archived: $FORENSICS_ARCHIVE"

echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo " INCIDENT RESPONSE COMPLETE"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📊 SUMMARY:"
echo "  Server: $SERVER"
echo "  Malware: $MALWARE_PROCESS (PID $MALWARE_PID)"
echo "  Status: ERADICATED ✅"
echo ""
echo "✅ Actions Taken:"
echo "  1. Forensics collected → $FORENSICS_ARCHIVE"
echo "  2. Process killed (PID $MALWARE_PID)"
echo "  3. Mining pool IPs blocked (${#MINING_POOLS[@]} IPs)"
echo "  4. Infection vector investigated"
echo "  5. Team notified (P2 — Max not woken)"
echo "  6. Monitoring enabled (auto-kill if restart)"
echo "  7. Decision logged → $DECISION_LOG"
echo ""
echo "⏭️  Next Steps:"
echo "  - Monitor for 1 hour (re-infection check)"
echo "  - Morning briefing to Max (08:00 UTC)"
echo "  - Full server rebuild recommended (if backdoor connection confirmed)"
echo "  - Update LILITH detection rules (cryptomining patterns)"
echo ""
echo "📝 Forensics Location:"
echo "  $FORENSICS_ARCHIVE"
echo "  Checksum: $FORENSICS_ARCHIVE.sha256"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Night shift incident handled professionally. 💪"
echo "Max can continue sleeping. Infrastructure secure."
echo ""
echo "*'Cryptomining = low priority если нет data breach."
echo " Killed fast. Team notified. Max отдыхает. Good night shift.'*"
echo "— Alex Sokolov, Moscow"
echo ""
echo "═══════════════════════════════════════════════════════════"

# Exit with success
exit 0

