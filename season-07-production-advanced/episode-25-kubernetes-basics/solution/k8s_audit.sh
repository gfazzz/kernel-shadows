#!/bin/bash
# EPISODE 25: Kubernetes Audit Script - SOLUTION
# Season 7: Production & Advanced Topics
# Type B: Uses kubectl commands, minimal bash (collection only, NOT wrapper)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="shadow-ops"
REPORT_FILE="k8s_audit_report.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Banner
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   KUBERNETES AUDIT SCRIPT - Episode 25 Solution${NC}"
echo -e "${BLUE}   Season 7: Production & Advanced Topics${NC}"
echo -e "${BLUE}   Type B: kubectl collection, minimal bash${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Initialize report
{
    echo "═══════════════════════════════════════════════════════════"
    echo "  KUBERNETES CLUSTER AUDIT REPORT"
    echo "  Episode 25: Kubernetes Basics"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Generated: $TIMESTAMP"
    echo "Namespace: $NAMESPACE"
    echo ""
} > "$REPORT_FILE"

# Function: Check if kubectl is available
check_kubectl() {
    echo -e "${YELLOW}[1/10]${NC} Checking kubectl availability..."
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}✗ kubectl not found${NC}"
        echo "ERROR: kubectl not installed" >> "$REPORT_FILE"
        exit 1
    fi
    echo -e "${GREEN}✓ kubectl found${NC}"
    echo "" >> "$REPORT_FILE"
}

# Function: Check cluster info
check_cluster() {
    echo -e "${YELLOW}[2/10]${NC} Checking cluster info..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "1. CLUSTER INFORMATION"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl cluster-info 2>&1 || echo "ERROR: Cannot connect to cluster"
        echo ""
        kubectl version --short 2>&1 || echo "ERROR: Cannot get version"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Cluster info collected${NC}"
}

# Function: Check nodes
check_nodes() {
    echo -e "${YELLOW}[3/10]${NC} Checking nodes..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "2. NODES STATUS"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get nodes -o wide 2>&1 || echo "ERROR: Cannot get nodes"
        echo ""
        echo "Node details:"
        kubectl describe nodes 2>&1 | grep -E "(Name:|Status:|Roles:|Capacity:|Allocatable:|Allocated resources:)" || true
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Nodes checked${NC}"
}

# Function: Check namespace
check_namespace() {
    echo -e "${YELLOW}[4/10]${NC} Checking namespace..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "3. NAMESPACE: $NAMESPACE"
        echo "───────────────────────────────────────────────────────────"
        echo ""

        if kubectl get namespace "$NAMESPACE" &> /dev/null; then
            echo "✓ Namespace exists"
            kubectl get namespace "$NAMESPACE" -o yaml | grep -E "(name:|status:)" || true
        else
            echo "✗ Namespace NOT found"
        fi
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Namespace checked${NC}"
}

# Function: Check deployments
check_deployments() {
    echo -e "${YELLOW}[5/10]${NC} Checking deployments..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "4. DEPLOYMENTS"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get deployments -n "$NAMESPACE" -o wide 2>&1 || echo "No deployments found"
        echo ""
        echo "Deployment details:"
        kubectl describe deployments -n "$NAMESPACE" 2>&1 | grep -E "(Name:|Namespace:|Replicas:|StrategyType:|Pod Template:|Image:)" || echo "No deployments"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Deployments checked${NC}"
}

# Function: Check pods
check_pods() {
    echo -e "${YELLOW}[6/10]${NC} Checking pods..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "5. PODS STATUS"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get pods -n "$NAMESPACE" -o wide 2>&1 || echo "No pods found"
        echo ""

        # Pod resource usage (if metrics-server available)
        echo "Pod resource usage:"
        kubectl top pods -n "$NAMESPACE" 2>&1 || echo "Metrics not available (metrics-server required)"
        echo ""

        # Recent events related to pods
        echo "Recent pod events:"
        kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' 2>&1 | tail -20 || echo "No events"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Pods checked${NC}"
}

# Function: Check services
check_services() {
    echo -e "${YELLOW}[7/10]${NC} Checking services..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "6. SERVICES & ENDPOINTS"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        kubectl get services -n "$NAMESPACE" -o wide 2>&1 || echo "No services found"
        echo ""
        echo "Endpoints:"
        kubectl get endpoints -n "$NAMESPACE" 2>&1 || echo "No endpoints found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Services checked${NC}"
}

# Function: Check configmaps and secrets
check_config() {
    echo -e "${YELLOW}[8/10]${NC} Checking ConfigMaps and Secrets..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "7. CONFIGURATION"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "ConfigMaps:"
        kubectl get configmaps -n "$NAMESPACE" 2>&1 || echo "No configmaps found"
        echo ""
        echo "Secrets:"
        kubectl get secrets -n "$NAMESPACE" 2>&1 || echo "No secrets found"
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ Configuration checked${NC}"
}

# Function: Check HPA
check_hpa() {
    echo -e "${YELLOW}[9/10]${NC} Checking Horizontal Pod Autoscaler..."
    {
        echo "───────────────────────────────────────────────────────────"
        echo "8. HORIZONTAL POD AUTOSCALER"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        if kubectl get hpa -n "$NAMESPACE" &> /dev/null; then
            kubectl get hpa -n "$NAMESPACE" -o wide 2>&1
            echo ""
            echo "HPA details:"
            kubectl describe hpa -n "$NAMESPACE" 2>&1 || true
        else
            echo "No HPA configured (optional)"
        fi
        echo ""
    } >> "$REPORT_FILE"
    echo -e "${GREEN}✓ HPA checked${NC}"
}

# Function: Generate summary and Björn's assessment
generate_summary() {
    echo -e "${YELLOW}[10/10]${NC} Generating summary..."

    # Count resources
    DEPLOYMENT_COUNT=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    POD_COUNT=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    SERVICE_COUNT=$(kubectl get services -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    CONFIGMAP_COUNT=$(kubectl get configmaps -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    SECRET_COUNT=$(kubectl get secrets -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)

    # Count running pods
    RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "Running" || echo "0")

    {
        echo "───────────────────────────────────────────────────────────"
        echo "9. SUMMARY"
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "Resources in namespace '$NAMESPACE':"
        echo "  - Deployments: $DEPLOYMENT_COUNT"
        echo "  - Pods: $POD_COUNT (Running: $RUNNING_PODS)"
        echo "  - Services: $SERVICE_COUNT"
        echo "  - ConfigMaps: $CONFIGMAP_COUNT"
        echo "  - Secrets: $SECRET_COUNT"
        echo ""

        echo "Health Status:"
        if [[ $RUNNING_PODS -gt 0 && $DEPLOYMENT_COUNT -gt 0 && $SERVICE_COUNT -gt 0 ]]; then
            echo "  ✓ Cluster is healthy"
            echo "  ✓ Pods are running"
            echo "  ✓ Services are exposed"
        else
            echo "  ⚠ Some resources missing or not running"
        fi
        echo ""

        echo "───────────────────────────────────────────────────────────"
        echo "10. BJÖRN'S ASSESSMENT"
        echo "───────────────────────────────────────────────────────────"
        echo ""

        if [[ $DEPLOYMENT_COUNT -gt 0 && $RUNNING_PODS -ge 3 && $SERVICE_COUNT -gt 0 ]]; then
            echo "Björn Sigurdsson:"
            echo "\"Good work. Deployment running. Pods healthy. Service exposed."
            echo " You understand Kubernetes basics. From Docker containers to"
            echo " orchestrated pods. This is foundation. Production requires more:"
            echo " monitoring, performance tuning, security hardening. But you"
            echo " started correctly. 3 replicas = high availability. Health checks"
            echo " = self-healing. Rolling updates = zero downtime. This is"
            echo " Kubernetes way. Continue to Episode 26.\""
            echo ""
            echo "Status: ✓ EPISODE 25 COMPLETE"
        else
            echo "Björn Sigurdsson:"
            echo "\"Configuration incomplete. Check logs. Debug pods. Fix YAML."
            echo " Kubernetes is not forgiving — one mistake, everything fails."
            echo " But also not mysterious — describe pod, check logs, understand"
            echo " error. Try again.\""
            echo ""
            echo "Status: ⚠ NEEDS FIXES"
        fi
        echo ""

        echo "───────────────────────────────────────────────────────────"
        echo "LILITH v7.0 (Production Mode):"
        echo "\"От ls -la до kubectl get pods. 48 дней. 7 сезонов. Ты управляешь"
        echo " distributed systems теперь. Kubernetes — это не магия. Это"
        echo " automation + declarative configuration + self-healing. Pods умирают"
        echo " и воскресают. Services балансируют. Deployments следят. Живой"
        echo " организм. Episode 26 — мониторинг. Without eyes — you are blind.\""
        echo "───────────────────────────────────────────────────────────"
        echo ""
        echo "Report generated: $TIMESTAMP"
        echo "Audit complete."
        echo ""
    } >> "$REPORT_FILE"

    echo -e "${GREEN}✓ Summary generated${NC}"
}

# Main execution
main() {
    check_kubectl
    check_cluster
    check_nodes
    check_namespace
    check_deployments
    check_pods
    check_services
    check_config
    check_hpa
    generate_summary

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Audit complete!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Report saved to: ${GREEN}$REPORT_FILE${NC}"
    echo ""
    echo "View report:"
    echo "  cat $REPORT_FILE"
    echo "  less $REPORT_FILE"
    echo ""
}

main "$@"

