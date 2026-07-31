#!/bin/bash
# EPISODE 26: Monitoring Stack - TEST SUITE
# Season 7: Production & Advanced Topics
# Validates monitoring stack deployment

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NAMESPACE="monitoring"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Banner
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   MONITORING STACK - TEST SUITE${NC}"
echo -e "${BLUE}   Episode 26 | Season 7${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}[TEST $TESTS_RUN]${NC} $test_name..."

    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: kubectl available
run_test "kubectl is available" \
    "command -v kubectl"

# Test 2: helm available
run_test "helm is available" \
    "command -v helm"

# Test 3: Monitoring namespace exists
run_test "Namespace '$NAMESPACE' exists" \
    "kubectl get namespace $NAMESPACE"

# Test 4: Prometheus pods running
PROM_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=prometheus --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
run_test "Prometheus pods running (found: $PROM_PODS)" \
    "[ '$PROM_PODS' -ge '1' ]"

# Test 5: Grafana pods running
GRAFANA_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
run_test "Grafana pods running (found: $GRAFANA_PODS)" \
    "[ '$GRAFANA_PODS' -ge '1' ]"

# Test 6: Alertmanager pods running
ALERT_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=alertmanager --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
run_test "Alertmanager pods running (found: $ALERT_PODS)" \
    "[ '$ALERT_PODS' -ge '1' ]"

# Test 7: Prometheus Service exists
run_test "Prometheus Service exists" \
    "kubectl get service -n $NAMESPACE -l app.kubernetes.io/name=prometheus"

# Test 8: Grafana Service exists
run_test "Grafana Service exists" \
    "kubectl get service -n $NAMESPACE -l app.kubernetes.io/name=grafana"

# Test 9: PrometheusRules configured
RULES_COUNT=$(kubectl get prometheusrules -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
run_test "PrometheusRules configured (found: $RULES_COUNT)" \
    "[ '$RULES_COUNT' -ge '1' ]"

# Test 10: node-exporter DaemonSet
run_test "node-exporter DaemonSet exists" \
    "kubectl get daemonset -n $NAMESPACE -l app.kubernetes.io/name=prometheus-node-exporter"

# Test 11: kube-state-metrics Deployment
run_test "kube-state-metrics Deployment exists" \
    "kubectl get deployment -n $NAMESPACE -l app.kubernetes.io/name=kube-state-metrics"

# Test 12: Prometheus StatefulSet (persistent storage)
run_test "Prometheus StatefulSet exists" \
    "kubectl get statefulset -n $NAMESPACE -l app.kubernetes.io/name=prometheus"

# Test 13: PersistentVolumeClaims (для TSDB)
PVC_COUNT=$(kubectl get pvc -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
run_test "PersistentVolumeClaims exist (found: $PVC_COUNT)" \
    "[ '$PVC_COUNT' -ge '1' ]"

# Test 14: Prometheus targets (можно проверить через API)
echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Prometheus targets accessible (API check)..."
if kubectl port-forward -n $NAMESPACE svc/prometheus-kube-prometheus-prometheus 9091:9090 &>/dev/null &
then
    PF_PID=$!
    sleep 3
    if curl -s http://localhost:9091/api/v1/targets 2>/dev/null | grep -q "activeTargets"; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠ SKIP${NC} (API not responding)"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    kill $PF_PID 2>/dev/null || true
else
    echo -e "${RED}✗ SKIP${NC} (port-forward failed)"
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 15: No pods in error state
ERROR_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
run_test "No pods in error state (found: $ERROR_PODS)" \
    "[ '$ERROR_PODS' -eq '0' ]"

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

# Pass percentage
PASS_PERCENT=$((TESTS_PASSED * 100 / TESTS_RUN))
echo -e "Pass rate: ${PASS_PERCENT}%"
echo ""

# Assessment
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Guðrún Ásta:"
    echo "\"Perfect. Monitoring stack complete. Prometheus scrapes metrics."
    echo " Grafana visualizes dashboards. Alertmanager handles alerts."
    echo " You have eyes now. Real-time visibility. Continue to Episode 27.\""
    echo ""
    echo "LILITH v7.0:"
    echo "\"От kubectl к полному observability. Prometheus collects, Grafana"
    echo " shows, Alertmanager warns. Production ready. Episode 27 — performance"
    echo " tuning. Monitoring показывает проблемы, performance их фиксит.\""
    echo ""
    exit 0
elif [ $PASS_PERCENT -ge 80 ]; then
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠ MOST TESTS PASSED (${PASS_PERCENT}%)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Guðrún Ásta:"
    echo "\"Good progress but $TESTS_FAILED tests failed. Check errors above."
    echo " Fix configuration. Monitoring critical для production. Complete"
    echo " setup before continuing.\""
    echo ""
    exit 1
else
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}✗ TESTS FAILED (${PASS_PERCENT}%)${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Guðrún Ásta:"
    echo "\"Too many failures. $TESTS_FAILED tests failed. Go back to README."
    echo " Follow installation steps. Helm chart должен установить всё."
    echo " Without monitoring — you are blind. Fix setup.\""
    echo ""
    exit 1
fi

