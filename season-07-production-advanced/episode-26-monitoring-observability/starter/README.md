# Episode 26: Starter Files
**Monitoring & Observability** | Season 7

## 📁 Files

This episode uses Helm chart для installation, поэтому starter files минимальны.

## 🎯 Your Task

Follow README.md instructions:

1. Install Prometheus stack (Helm)
2. Access Prometheus UI (port-forward)
3. Create custom Grafana dashboard
4. Configure custom alert rule
5. Test alert firing

## 📝 Custom Configuration Examples

### Custom Alert Rule Template

Create `custom-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-alerts
  namespace: monitoring
spec:
  groups:
  - name: custom
    rules:
    # TODO: Add your alert rules here
    - alert: HighMemory
      expr: container_memory_usage_bytes{namespace="shadow-ops"} / container_spec_memory_limit_bytes > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ $labels.pod }}"
        description: "Memory usage > 90% for 5 minutes"
```

Apply: `kubectl apply -f custom-alerts.yaml`

### Grafana Dashboard JSON Template

Dashboards создаются через GUI (см. README Цикл 5).

Export: Dashboards → Settings → JSON Model → Copy

## ✅ Verification

После завершения проверь:

```bash
# 1. All monitoring pods running
kubectl get pods -n monitoring

# 2. Prometheus accessible
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
curl http://localhost:9090/metrics

# 3. Grafana accessible
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
# Open http://localhost:3000 (admin/admin123)

# 4. Alerts configured
kubectl get prometheusrules -n monitoring
```

---

**Good luck!** 📊 Monitoring — глаза production infrastructure.

