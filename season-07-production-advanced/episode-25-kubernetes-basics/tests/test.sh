#!/bin/bash
# EPISODE 25: Kubernetes Basics - TEST SUITE
# Season 7: Production & Advanced Topics
# Validates Kubernetes deployment correctness

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NAMESPACE="shadow-ops"
DEPLOYMENT_NAME="shadow-web"
SERVICE_NAME="shadow-web-service"
CONFIGMAP_NAME="shadow-config"
SECRET_NAME="shadow-secrets"
EXPECTED_REPLICAS=3
EXPECTED_IMAGE="nginx:1.25-alpine"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Banner
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   KUBERNETES BASICS - TEST SUITE${NC}"
echo -e "${BLUE}   Episode 25 | Season 7${NC}"
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

# Test 2: Cluster accessible
run_test "Kubernetes cluster accessible" \
    "kubectl cluster-info"

# Test 3: Namespace exists
run_test "Namespace '$NAMESPACE' exists" \
    "kubectl get namespace $NAMESPACE"

# Test 4: Deployment exists
run_test "Deployment '$DEPLOYMENT_NAME' exists" \
    "kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE"

# Test 5: Correct number of replicas
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    REPLICAS=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}')
    run_test "Deployment has $EXPECTED_REPLICAS replicas (found: $REPLICAS)" \
        "[ '$REPLICAS' -eq '$EXPECTED_REPLICAS' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Deployment replicas check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: Correct image
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    IMAGE=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
    run_test "Deployment uses image '$EXPECTED_IMAGE' (found: $IMAGE)" \
        "[ '$IMAGE' = '$EXPECTED_IMAGE' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Image check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 7: Pods are running
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    RUNNING_PODS=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    run_test "At least 1 pod Running (found: $RUNNING_PODS)" \
        "[ '$RUNNING_PODS' -ge '1' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Pods running check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 8: All pods ready
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    READY_REPLICAS=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
    READY_REPLICAS=${READY_REPLICAS:-0}
    run_test "All replicas ready (found: $READY_REPLICAS/$EXPECTED_REPLICAS)" \
        "[ '$READY_REPLICAS' -eq '$EXPECTED_REPLICAS' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Ready replicas check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 9: Resource limits configured
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    CPU_LIMIT=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
    run_test "CPU limits configured (found: ${CPU_LIMIT:-none})" \
        "[ ! -z '$CPU_LIMIT' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} CPU limits check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 10: Liveness probe configured
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    LIVENESS=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}')
    run_test "Liveness probe configured" \
        "[ ! -z '$LIVENESS' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Liveness probe check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 11: Readiness probe configured
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    READINESS=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}')
    run_test "Readiness probe configured" \
        "[ ! -z '$READINESS' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Readiness probe check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 12: Service exists
run_test "Service '$SERVICE_NAME' exists" \
    "kubectl get service $SERVICE_NAME -n $NAMESPACE"

# Test 13: Service type is ClusterIP
if kubectl get service $SERVICE_NAME -n $NAMESPACE &>/dev/null; then
    SERVICE_TYPE=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.type}')
    run_test "Service type is ClusterIP (found: $SERVICE_TYPE)" \
        "[ '$SERVICE_TYPE' = 'ClusterIP' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Service type check... ${RED}✗ SKIP${NC} (service not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 14: Service has endpoints
if kubectl get service $SERVICE_NAME -n $NAMESPACE &>/dev/null; then
    ENDPOINTS=$(kubectl get endpoints $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
    run_test "Service has endpoints (pods targeted)" \
        "[ ! -z '$ENDPOINTS' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Service endpoints check... ${RED}✗ SKIP${NC} (service not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 15: ConfigMap exists
run_test "ConfigMap '$CONFIGMAP_NAME' exists" \
    "kubectl get configmap $CONFIGMAP_NAME -n $NAMESPACE"

# Test 16: ConfigMap has required keys
if kubectl get configmap $CONFIGMAP_NAME -n $NAMESPACE &>/dev/null; then
    API_URL=$(kubectl get configmap $CONFIGMAP_NAME -n $NAMESPACE -o jsonpath='{.data.api_url}' 2>/dev/null)
    run_test "ConfigMap has 'api_url' key" \
        "[ ! -z '$API_URL' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} ConfigMap keys check... ${RED}✗ SKIP${NC} (configmap not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 17: Secret exists
run_test "Secret '$SECRET_NAME' exists" \
    "kubectl get secret $SECRET_NAME -n $NAMESPACE"

# Test 18: Rolling update strategy configured
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &>/dev/null; then
    STRATEGY=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.strategy.type}')
    run_test "Deployment strategy is RollingUpdate (found: ${STRATEGY:-Recreate})" \
        "[ '$STRATEGY' = 'RollingUpdate' ]"
else
    echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Strategy check... ${RED}✗ SKIP${NC} (deployment not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 19: No pods in error state
ERROR_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
run_test "No pods in error state (found: $ERROR_PODS)" \
    "[ '$ERROR_PODS' -eq '0' ]"

# Test 20: Service connectivity (optional, requires port-forward)
echo -e "${YELLOW}[TEST $((TESTS_RUN+1))]${NC} Service connectivity test (port-forward)..."
if kubectl get service $SERVICE_NAME -n $NAMESPACE &>/dev/null; then
    # Start port-forward in background
    kubectl port-forward service/$SERVICE_NAME 18080:80 -n $NAMESPACE &>/dev/null &
    PF_PID=$!
    sleep 3

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:18080 | grep -q "200\|301\|302\|404"; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠ SKIP${NC} (service not responding or port-forward failed)"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))

    # Kill port-forward
    kill $PF_PID 2>/dev/null || true
else
    echo -e "${RED}✗ SKIP${NC} (service not found)"
    TESTS_RUN=$((TESTS_RUN + 1))
fi

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

# Björn's assessment
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Björn Sigurdsson:"
    echo "\"Good work. All tests pass. Deployment correct. Pods healthy."
    echo " Service exposed. Configuration complete. You understand"
    echo " Kubernetes basics. From zero to production deployment."
    echo " Continue to Episode 26 — Monitoring.\""
    echo ""
    echo "LILITH v7.0:"
    echo "\"Тесты прошли. Kubernetes работает. Self-healing проверен."
    echo " Rolling updates готовы. Ты управляешь production infrastructure."
    echo " 48 дней назад ты не знал что такое ls. Сегодня — kubectl master."
    echo " Episode 26 — мониторинг. Let's watch this beauty work.\""
    echo ""
    exit 0
elif [ $PASS_PERCENT -ge 75 ]; then
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠ MOST TESTS PASSED (${PASS_PERCENT}%)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Björn Sigurdsson:"
    echo "\"Decent. Most components working. But $TESTS_FAILED tests failed."
    echo " Check errors above. Fix configuration. Kubernetes is strict —"
    echo " one wrong YAML line, everything fails. Debug: kubectl describe,"
    echo " kubectl logs. Try again.\""
    echo ""
    exit 1
else
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}✗ TESTS FAILED (${PASS_PERCENT}%)${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Björn Sigurdsson:"
    echo "\"Too many failures. $TESTS_FAILED tests failed. Go back."
    echo " Check main README.md theory. Review YAML examples. Try starter"
    echo " templates. Kubernetes is not forgiving. But also not mysterious."
    echo " Every error has reason. Find it. Fix it. Test again.\""
    echo ""
    echo "LILITH:"
    echo "\"Kubernetes broke. Чини. kubectl describe pod, kubectl logs."
    echo " Errors are teachers. Read them. Understand them. Kubernetes"
    echo " tells you exactly what wrong. Listen.\""
    echo ""
    exit 1
fi

