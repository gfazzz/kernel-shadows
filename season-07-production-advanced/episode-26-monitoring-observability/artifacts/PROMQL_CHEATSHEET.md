# PromQL Cheat Sheet
**Episode 26: Monitoring & Observability**

## 📊 BASIC QUERIES

### Instant Vector (current value)
```promql
metric_name                           # All time-series
metric_name{label="value"}           # Filtered by label
metric_name{label=~"regex"}          # Regex match
metric_name{label!="value"}          # Not equal
```

### Range Vector (time window)
```promql
metric_name[5m]                      # Last 5 minutes
metric_name{label="value"}[1h]       # Last 1 hour, filtered
```

## 🔢 AGGREGATION FUNCTIONS

### Sum / Avg / Min / Max
```promql
sum(metric)                           # Total
avg(metric)                           # Average
min(metric)                           # Minimum
max(metric)                           # Maximum
count(metric)                         # Count time-series
```

### Group By
```promql
sum by (label) (metric)               # Sum grouped by label
avg by (pod, namespace) (metric)      # Multi-label grouping
```

## 📈 RATE FUNCTIONS

### Rate (per-second rate)
```promql
rate(counter_metric[5m])              # Req/sec over 5min window
irate(counter_metric[5m])             # Instant rate (more responsive)
increase(counter_metric[1h])          # Total increase in 1 hour
```

**Use cases:**
- `rate()` — smooth, для alerting
- `irate()` — responsive, для graphing
- `increase()` — total count

## 🎯 KUBERNETES QUERIES

### CPU Usage
```promql
# CPU usage by pod
sum by (pod) (rate(container_cpu_usage_seconds_total[5m]))

# CPU usage by namespace
sum by (namespace) (rate(container_cpu_usage_seconds_total[5m]))

# Total cluster CPU
sum(rate(container_cpu_usage_seconds_total[5m]))
```

### Memory Usage
```promql
# Memory by pod
container_memory_usage_bytes{pod="app-pod"}

# Memory by namespace
sum by (namespace) (container_memory_usage_bytes)

# Memory usage percentage
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100
```

### Pod Status
```promql
# Running pods
kube_pod_status_phase{phase="Running"}

# Pod restarts
kube_pod_container_status_restarts_total

# Pods not ready
kube_pod_status_ready{condition="false"}
```

### Network
```promql
# Network bytes received
rate(container_network_receive_bytes_total[5m])

# Network bytes sent
rate(container_network_transmit_bytes_total[5m])
```

## 📊 HTTP METRICS

### Request Rate
```promql
# Requests per second
rate(http_requests_total[5m])

# By status code
rate(http_requests_total{status="200"}[5m])

# By method
sum by (method) (rate(http_requests_total[5m]))
```

### Error Rate
```promql
# Error rate (%)
sum(rate(http_requests_total{status=~"5.."}[5m])) /
sum(rate(http_requests_total[5m])) * 100

# 4xx rate
sum(rate(http_requests_total{status=~"4.."}[5m])) /
sum(rate(http_requests_total[5m])) * 100
```

### Latency
```promql
# p95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# p99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Average latency
rate(http_request_duration_seconds_sum[5m]) /
rate(http_request_duration_seconds_count[5m])
```

## 🔍 ADVANCED QUERIES

### Top K / Bottom K
```promql
# Top 5 CPU-consuming pods
topk(5, sum by (pod) (rate(container_cpu_usage_seconds_total[5m])))

# Bottom 3 by requests
bottomk(3, sum by (service) (rate(http_requests_total[5m])))
```

### Arithmetic
```promql
metric1 + metric2                     # Addition
metric1 - metric2                     # Subtraction
metric1 * 100                         # Multiplication
metric1 / metric2                     # Division
```

### Comparison
```promql
metric > 0.9                          # Greater than
metric < 100                          # Less than
metric == 1                           # Equal
metric != 0                           # Not equal
```

### Boolean
```promql
metric1 and metric2                   # Logical AND
metric1 or metric2                    # Logical OR
metric1 unless metric2                # UNLESS
```

## ⏰ TIME FUNCTIONS

### Offset
```promql
metric offset 5m                      # Value 5 minutes ago
metric[1h] offset 1d                  # Range 1 day ago
```

### Time
```promql
time()                                # Current Unix timestamp
hour()                                # Current hour (0-23)
day_of_week()                         # Day of week (0-6)
```

## 🎨 USEFUL PATTERNS

### Availability (%)
```promql
# Uptime percentage
avg(up{job="kubernetes-nodes"}) * 100
```

### Resource Saturation
```promql
# CPU saturation
sum(rate(container_cpu_usage_seconds_total[5m])) /
sum(machine_cpu_cores) * 100

# Memory saturation
sum(container_memory_usage_bytes) /
sum(machine_memory_bytes) * 100
```

### Growth Rate
```promql
# Growth over 1 hour
(metric - metric offset 1h) / metric offset 1h * 100
```

### Prediction (Linear Regression)
```promql
# Predict disk full in X hours
predict_linear(node_filesystem_free_bytes[1h], 3600*24) < 0
```

## 🚨 ALERTING QUERIES

### High CPU
```promql
sum by (pod) (rate(container_cpu_usage_seconds_total[5m])) > 0.9
```

### Memory Pressure
```promql
container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
```

### High Error Rate
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) /
sum(rate(http_requests_total[5m])) > 0.01
```

### Disk Full Soon
```promql
predict_linear(node_filesystem_free_bytes[1h], 3600*4) < 0
```

## 📝 BEST PRACTICES

✅ **DO:**
- Use `rate()` для counters (not raw values)
- Group by relevant labels (`by (pod)`)
- Use time windows (5m typical для rate)
- Keep queries simple (easier to debug)

❌ **DON'T:**
- Use instant vectors для alerting (use range vectors + rate)
- Use high cardinality labels (user_id, request_id)
- Over-aggregate (lose важные детали)
- Forget units (bytes vs MB, seconds vs ms)

---

**Guðrún's tip:** "Start simple. `up` shows targets. `rate(metric[5m])` shows trends. `sum by (label)` groups. Master these — 90% queries использует эти patterns."

**LILITH:** "PromQL странный сначала. Но логика простая: metric{filter}[window] | function. Запомни patterns. Copy-paste + modify. Prometheus docs — твой друг."

