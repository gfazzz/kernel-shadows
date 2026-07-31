#!/bin/bash
# performance_audit.sh - Automated Performance Audit Script (REFERENCE SOLUTION)
# Episode 27: Performance Tuning
# KERNEL SHADOWS - Season 7

set -euo pipefail

# ============================================================================
# VARIABLES
# ============================================================================

REPORT_FILE="performance_audit_$(date +%Y%m%d_%H%M%S).txt"
LOG_FILE="/var/log/performance_audit.log"

# Thresholds
CPU_THRESHOLD=80          # %
MEMORY_THRESHOLD=80       # %
DISK_UTIL_THRESHOLD=80    # %
CACHE_HIT_RATE_MIN=70     # %
IOWAIT_THRESHOLD=10       # %

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_status() {
    local status=$1
    local message=$2

    case $status in
        "OK")
            echo -e "${GREEN}🟢 $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}🟡 $message${NC}"
            ;;
        "CRITICAL")
            echo -e "${RED}🔴 $message${NC}"
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

check_cpu() {
    echo ""
    echo "=== CPU PERFORMANCE ==="

    # Get load average (1 min)
    load_avg=$(cat /proc/loadavg | awk '{print $1}')
    cores=$(nproc)

    # Calculate load per core
    load_per_core=$(echo "scale=2; $load_avg / $cores" | bc)

    # Check iowait
    if command_exists iostat; then
        iowait=$(iostat -c 1 2 | tail -1 | awk '{print $4}' | cut -d. -f1)
    else
        iowait=0
    fi

    echo "  Load average: $load_avg (cores: $cores, per core: $load_per_core)"
    echo "  I/O wait: ${iowait}%"

    # Status check
    if (( $(echo "$load_avg < $cores" | bc -l) )); then
        print_status "OK" "CPU load normal (${load_avg}/${cores} cores)"
    elif (( $(echo "$load_avg < $cores * 1.5" | bc -l) )); then
        print_status "WARNING" "CPU load elevated (${load_avg}/${cores} cores)"
    else
        print_status "CRITICAL" "CPU overloaded! (${load_avg}/${cores} cores)"
    fi

    if [ "$iowait" -gt "$IOWAIT_THRESHOLD" ]; then
        print_status "CRITICAL" "High I/O wait (${iowait}%) - disk bottleneck!"
    else
        print_status "OK" "I/O wait normal (${iowait}%)"
    fi
}

check_memory() {
    echo ""
    echo "=== MEMORY PERFORMANCE ==="

    # Get memory stats (in MB)
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    mem_used=$(free -m | awk '/^Mem:/ {print $3}')
    mem_free=$(free -m | awk '/^Mem:/ {print $4}')
    mem_available=$(free -m | awk '/^Mem:/ {print $7}')
    swap_used=$(free -m | awk '/^Swap:/ {print $3}')

    # Calculate percentage
    mem_usage_pct=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc)

    echo "  Total: ${mem_total} MB"
    echo "  Used: ${mem_used} MB (${mem_usage_pct}%)"
    echo "  Available: ${mem_available} MB"
    echo "  Swap used: ${swap_used} MB"

    # Status check
    if (( $(echo "$mem_usage_pct < $MEMORY_THRESHOLD" | bc -l) )); then
        print_status "OK" "Memory usage normal (${mem_usage_pct}%)"
    elif (( $(echo "$mem_usage_pct < $MEMORY_THRESHOLD + 10" | bc -l) )); then
        print_status "WARNING" "Memory usage high (${mem_usage_pct}%)"
    else
        print_status "CRITICAL" "Memory critically high (${mem_usage_pct}%)!"
    fi

    if [ "$swap_used" -gt 100 ]; then
        print_status "CRITICAL" "Swap is being used (${swap_used} MB) - performance degradation!"
    else
        print_status "OK" "Swap usage minimal"
    fi
}

check_disk_io() {
    echo ""
    echo "=== DISK I/O PERFORMANCE ==="

    if ! command_exists iostat; then
        print_status "WARNING" "iostat not installed (install sysstat package)"
        return
    fi

    # Get disk stats (skip header, average over 3 seconds)
    iostat -x 1 3 | grep -E '^(sd|nvme|vd|hd)' | tail -n +2 | while read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        util=$(echo "$line" | awk '{print $NF}' | cut -d. -f1)
        await=$(echo "$line" | awk '{print $(NF-4)}' | cut -d. -f1)

        echo "  Device: $device - Utilization: ${util}%, Avg wait: ${await}ms"

        if [ "$util" -lt "$DISK_UTIL_THRESHOLD" ]; then
            print_status "OK" "$device utilization normal (${util}%)"
        elif [ "$util" -lt $((DISK_UTIL_THRESHOLD + 10)) ]; then
            print_status "WARNING" "$device utilization high (${util}%)"
        else
            print_status "CRITICAL" "$device overloaded (${util}%)!"
        fi

        if [ "$await" -gt 20 ]; then
            print_status "WARNING" "$device high latency (${await}ms)"
        fi
    done
}

check_database() {
    echo ""
    echo "=== DATABASE PERFORMANCE ==="

    # Check MySQL
    if systemctl is-active --quiet mysql 2>/dev/null || systemctl is-active --quiet mysqld 2>/dev/null; then
        echo "  MySQL detected"

        if command_exists mysql; then
            # Get slow queries count
            slow_queries=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null | awk '{print $2}' || echo "0")
            echo "  Slow queries: $slow_queries"

            if [ "$slow_queries" -eq 0 ]; then
                print_status "OK" "No slow queries"
            elif [ "$slow_queries" -lt 10 ]; then
                print_status "WARNING" "Some slow queries detected ($slow_queries)"
            else
                print_status "CRITICAL" "Many slow queries ($slow_queries) - optimize!"
            fi
        else
            print_status "WARNING" "mysql client not available"
        fi

    # Check PostgreSQL
    elif systemctl is-active --quiet postgresql 2>/dev/null; then
        echo "  PostgreSQL detected"
        print_status "OK" "PostgreSQL running"

    else
        print_status "OK" "No database service detected (skipping)"
    fi
}

check_cache() {
    echo ""
    echo "=== CACHE PERFORMANCE ==="

    if ! command_exists redis-cli; then
        print_status "OK" "Redis not installed (skipping)"
        return
    fi

    if ! redis-cli PING >/dev/null 2>&1; then
        print_status "WARNING" "Redis not running (skipping)"
        return
    fi

    # Get cache stats
    hits=$(redis-cli INFO stats 2>/dev/null | grep keyspace_hits | cut -d: -f2 | tr -d '\r' || echo "0")
    misses=$(redis-cli INFO stats 2>/dev/null | grep keyspace_misses | cut -d: -f2 | tr -d '\r' || echo "0")

    total=$((hits + misses))

    if [ "$total" -gt 0 ]; then
        hit_rate=$(echo "scale=1; $hits * 100 / $total" | bc)
        echo "  Cache hits: $hits"
        echo "  Cache misses: $misses"
        echo "  Hit rate: ${hit_rate}%"

        if (( $(echo "$hit_rate > 90" | bc -l) )); then
            print_status "OK" "Excellent cache hit rate (${hit_rate}%)"
        elif (( $(echo "$hit_rate > $CACHE_HIT_RATE_MIN" | bc -l) )); then
            print_status "WARNING" "Cache hit rate acceptable (${hit_rate}%) - can improve"
        else
            print_status "CRITICAL" "Low cache hit rate (${hit_rate}%) - check TTL!"
        fi
    else
        print_status "OK" "Redis running, no traffic yet"
    fi
}

check_sysctl() {
    echo ""
    echo "=== SYSCTL SETTINGS ==="

    # TCP settings
    tcp_fin=$(sysctl -n net.ipv4.tcp_fin_timeout 2>/dev/null || echo "N/A")
    somaxconn=$(sysctl -n net.core.somaxconn 2>/dev/null || echo "N/A")
    swappiness=$(sysctl -n vm.swappiness 2>/dev/null || echo "N/A")
    file_max=$(sysctl -n fs.file-max 2>/dev/null || echo "N/A")

    echo "  tcp_fin_timeout: $tcp_fin (recommended: 30)"
    echo "  somaxconn: $somaxconn (recommended: 4096+)"
    echo "  swappiness: $swappiness (recommended: 1-10 for DB)"
    echo "  file-max: $file_max (recommended: 100000+)"

    # Check tcp_fin_timeout
    if [ "$tcp_fin" != "N/A" ] && [ "$tcp_fin" -le 30 ]; then
        print_status "OK" "tcp_fin_timeout optimized ($tcp_fin)"
    elif [ "$tcp_fin" != "N/A" ]; then
        print_status "WARNING" "tcp_fin_timeout could be lower (current: $tcp_fin, recommend: 30)"
    fi

    # Check somaxconn
    if [ "$somaxconn" != "N/A" ] && [ "$somaxconn" -ge 4096 ]; then
        print_status "OK" "somaxconn well configured ($somaxconn)"
    elif [ "$somaxconn" != "N/A" ]; then
        print_status "WARNING" "somaxconn too low (current: $somaxconn, recommend: 4096+)"
    fi

    # Check swappiness
    if [ "$swappiness" != "N/A" ] && [ "$swappiness" -le 10 ]; then
        print_status "OK" "swappiness optimized for performance ($swappiness)"
    elif [ "$swappiness" != "N/A" ]; then
        print_status "WARNING" "swappiness high (current: $swappiness, recommend: 1-10 for databases)"
    fi
}

check_network() {
    echo ""
    echo "=== NETWORK PERFORMANCE ==="

    if command_exists ss; then
        # Count connections
        tcp_established=$(ss -tan | grep ESTAB | wc -l)
        tcp_timewait=$(ss -tan | grep TIME-WAIT | wc -l)

        echo "  Established connections: $tcp_established"
        echo "  TIME-WAIT connections: $tcp_timewait"

        if [ "$tcp_established" -gt 10000 ]; then
            print_status "WARNING" "High number of connections ($tcp_established)"
        else
            print_status "OK" "Connection count normal"
        fi

        if [ "$tcp_timewait" -gt 5000 ]; then
            print_status "WARNING" "Many TIME-WAIT sockets ($tcp_timewait) - consider tcp_tw_reuse"
        fi
    else
        print_status "WARNING" "ss command not available"
    fi
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_summary() {
    echo ""
    echo "========================================"
    echo " PERFORMANCE AUDIT SUMMARY"
    echo "========================================"
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Kernel: $(uname -r)"
    echo ""
    echo "Report saved to: $REPORT_FILE"
    echo "Log file: $LOG_FILE"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo "========================================"
    echo " PERFORMANCE AUDIT"
    echo " KERNEL SHADOWS - Episode 27"
    echo "========================================"
    echo "Starting audit at $(date)"

    # Run all checks
    check_cpu
    check_memory
    check_disk_io
    check_database
    check_cache
    check_sysctl
    check_network

    # Generate summary
    generate_summary

    echo ""
    echo "✅ Audit complete!"
}

# Run main function and save output to file
main "$@" | tee "$REPORT_FILE"

# Also append to log file
cat "$REPORT_FILE" >> "$LOG_FILE" 2>/dev/null || true

exit 0

