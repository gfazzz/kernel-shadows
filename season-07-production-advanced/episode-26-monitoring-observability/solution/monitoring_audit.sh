#!/bin/bash
# EPISODE 26: Monitoring Stack Audit - SOLUTION
# Season 7: Production & Advanced Topics
# Type B: Uses kubectl/helm commands, minimal bash (collection only)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NAMESPACE="monitoring"
REPORT_FILE="monitoring_audit_report.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Banner
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   MONITORING STACK AUDIT - Episode 26${NC}"
echo -e "${BLUE}   Season 7: Production & Advanced Topics${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Initialize report
{
    echo "═══════════════════════════════════════════════════════════"
    echo "  MONITORING STACK AUDIT REPORT"
    echo "  Episode 26: Monitoring & Observability"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Generated: $TIMESTAMP"
    echo "Namespace: $NAMESPACE"
    echo ""
} > "$REPORT_FILE"

# Function: Check monitoring namespace
check_namespace() {
    echo -e "${YELLOW}[1/8]${NC} Checking monitoring namespace..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "1. MONITORING NAMESPACE"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        if kubectl get namespace "$NAMESPACE" &>/dev/null; then
            echo "✓ Namespace exists: $NAMESPACE"
        else
            echo "✗ Namespace NOT found: $NAMESPACE"
        fi
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Namespace checked${NC}"
}

# Function: Check Prometheus
check_prometheus() {
    echo -e "${YELLOW}[2/8]${NC} Checking Prometheus..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "2. PROMETHEUS SERVER"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=prometheus 2>&1 || echo "No Prometheus pods found"
        echo ""
        echo "Prometheus StatefulSet:"
        kubectl get statefulset -n "$NAMESPACE" -l app.kubernetes.io/name=prometheus 2>&1 || echo "No StatefulSet found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Prometheus checked${NC}"
}

# Function: Check Grafana
check_grafana() {
    echo -e "${YELLOW}[3/8]${NC} Checking Grafana..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "3. GRAFANA"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=grafana 2>&1 || echo "No Grafana pods found"
        echo ""
        echo "Grafana Service:"
        kubectl get service -n "$NAMESPACE" -l app.kubernetes.io/name=grafana 2>&1 || echo "No Service found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Grafana checked${NC}"
}

# Function: Check Alertmanager
check_alertmanager() {
    echo -e "${YELLOW}[4/8]${NC} Checking Alertmanager..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "4. ALERTMANAGER"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=alertmanager 2>&1 || echo "No Alertmanager pods found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Alertmanager checked${NC}"
}

# Function: Check Exporters
check_exporters() {
    echo -e "${YELLOW}[5/8]${NC} Checking Exporters..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "5. EXPORTERS"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "node-exporter:"
        kubectl get daemonset -n "$NAMESPACE" -l app.kubernetes.io/name=prometheus-node-exporter 2>&1 || echo "Not found"
        echo ""
        echo "kube-state-metrics:"
        kubectl get deployment -n "$NAMESPACE" -l app.kubernetes.io/name=kube-state-metrics 2>&1 || echo "Not found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Exporters checked${NC}"
}

# Function: Check Alerting Rules
check_rules() {
    echo -e "${YELLOW}[6/8]${NC} Checking Alerting Rules..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "6. PROMETHEUS RULES"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get prometheusrules -n "$NAMESPACE" 2>&1 || echo "No PrometheusRules found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Rules checked${NC}"
}

# Function: Check Services
check_services() {
    echo -e "${YELLOW}[7/8]${NC} Checking Services..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "7. SERVICES"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get services -n "$NAMESPACE" 2>&1 || echo "No services found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Services checked${NC}"
}

# Function: Generate Summary
generate_summary() {
    echo -e "${YELLOW}[8/8]${NC} Generating summary..."

    # Count resources
    PROMETHEUS_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | wc -l)
    GRAFANA_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | wc -l)
    ALERTMANAGER_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=alertmanager --no-headers 2>/dev/null | wc -l)
    RULES_COUNT=$(kubectl get prometheusrules -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)

    {
        echo "───────────────────────────────────────────────────────────"
        echo "8. SUMMARY"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "Monitoring Stack Components:"
        echo "  - Prometheus: $PROMETHEUS_COUNT pods"
        echo "  - Grafana: $GRAFANA_COUNT pods"
        echo "  - Alertmanager: $ALERTMANAGER_COUNT pods"
        echo "  - PrometheusRules: $RULES_COUNT"
        echo ""

        if [[ $PROMETHEUS_COUNT -gt 0 && $GRAFANA_COUNT -gt 0 ]]; then
            echo "✓ Monitoring stack is deployed"
        else
            echo "✗ Monitoring stack incomplete"
        fi
        echo ""

        echo "───────────────────────────────────────────────────────────"
        echo "GUÐRÚN'S ASSESSMENT"
        echo "───────────────────────────────────────────────────────────"
        echo ""

        if [[ $PROMETHEUS_COUNT -gt 0 && $GRAFANA_COUNT -gt 0 && $ALERTMANAGER_COUNT -gt 0 ]]; then
            echo "Guðrún Ásta:"
            echo "\"Good work. Prometheus collects metrics. Grafana visualizes."
            echo " Alertmanager handles alerts. You have eyes now. Production"
            echo " infrastructure visible. Before — kubectl get pods manually."
            echo " Now — real-time dashboards, automatic alerts. This is"
            echo " observability. Episode 27 — performance tuning. Monitoring"
            echo " shows problems. Performance fixes them.\""
            echo ""
            echo "Status: ✓ EPISODE 26 COMPLETE"
        else
            echo "Guðrún Ásta:"
            echo "\"Monitoring stack incomplete. Check installation. Helm chart"
            echo " should install all components. If missing — reinstall. Without"
            echo " monitoring — you are blind. Complete setup first.\""
            echo ""
            echo "Status: ⚠ NEEDS FIXES"
        fi
        echo ""

        echo "───────────────────────────────────────────────────────────"
        echo "LILITH v7.0 (Production Mode):"
        echo "\"От слепого kubectl к полной observability. Prometheus scrapes"
        echo " каждые 15 секунд. Grafana показывает trends. Alertmanager"
        echo " предупреждает до того как users заметят. Production требует"
        echo " visibility. Ты её получил. Episode 27 — оптимизация.\""
        echo "───────────────────────────────────────────────────────────"
        echo ""
    } >> "$REPORT_FILE"

    echo -e "${GREEN}✓ Summary generated${NC}"
}

# Main execution
main() {
    check_namespace
    check_prometheus
    check_grafana
    check_alertmanager
    check_exporters
    check_rules
    check_services
    generate_summary

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Audit complete!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Report saved to: ${GREEN}$REPORT_FILE${NC}"
    echo ""
}

main "$@"

