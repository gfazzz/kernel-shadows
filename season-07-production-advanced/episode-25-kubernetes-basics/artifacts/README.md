# Episode 25: Artifacts & Resources
**Kubernetes Basics** | Season 7: Production & Advanced Topics

Этот файл содержит полезные reference materials для работы с Kubernetes.

---

## 📚 KUBECTL CHEAT SHEET

### Cluster Info
```bash
# Cluster information
kubectl cluster-info
kubectl version --short

# Nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top nodes  # Resource usage
```

### Namespaces
```bash
# List namespaces
kubectl get namespaces
kubectl get ns  # Short form

# Create namespace
kubectl create namespace <name>

# Set default namespace
kubectl config set-context --current --namespace=<name>

# Delete namespace (WARNING: deletes all resources inside!)
kubectl delete namespace <name>
```

### Pods
```bash
# List pods
kubectl get pods -n <namespace>
kubectl get pods --all-namespaces
kubectl get pods -o wide  # More details

# Describe pod (events, status)
kubectl describe pod <pod-name> -n <namespace>

# Logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous container (if crashed)
kubectl logs <pod-name> -n <namespace> -f  # Follow logs (tail -f style)
kubectl logs -l app=<label> -n <namespace>  # All pods with label

# Execute command in pod
kubectl exec <pod-name> -n <namespace> -- <command>
kubectl exec -it <pod-name> -n <namespace> -- sh  # Interactive shell

# Port forward (access pod from localhost)
kubectl port-forward <pod-name> 8080:80 -n <namespace>
```

### Deployments
```bash
# List deployments
kubectl get deployments -n <namespace>
kubectl get deploy -n <namespace>  # Short form

# Describe deployment
kubectl describe deployment <name> -n <namespace>

# Create deployment (imperative, for quick tests only)
kubectl create deployment <name> --image=<image> -n <namespace>

# Scale deployment
kubectl scale deployment <name> --replicas=<number> -n <namespace>

# Update image (rolling update)
kubectl set image deployment/<name> <container>=<new-image> -n <namespace>

# Rollout status
kubectl rollout status deployment <name> -n <namespace>

# Rollout history
kubectl rollout history deployment <name> -n <namespace>

# Rollback
kubectl rollout undo deployment <name> -n <namespace>
kubectl rollout undo deployment <name> --to-revision=<number> -n <namespace>

# Pause/Resume rollout
kubectl rollout pause deployment <name> -n <namespace>
kubectl rollout resume deployment <name> -n <namespace>

# Delete deployment
kubectl delete deployment <name> -n <namespace>
```

### Services
```bash
# List services
kubectl get services -n <namespace>
kubectl get svc -n <namespace>  # Short form

# Describe service
kubectl describe service <name> -n <namespace>

# Check endpoints (which pods service targets)
kubectl get endpoints <service-name> -n <namespace>

# Port forward to service
kubectl port-forward service/<name> 8080:80 -n <namespace>

# Delete service
kubectl delete service <name> -n <namespace>
```

### ConfigMaps & Secrets
```bash
# ConfigMaps
kubectl get configmaps -n <namespace>
kubectl get cm -n <namespace>  # Short form
kubectl describe configmap <name> -n <namespace>
kubectl get configmap <name> -n <namespace> -o yaml  # View data

# Create ConfigMap from literal
kubectl create configmap <name> --from-literal=key=value -n <namespace>

# Create ConfigMap from file
kubectl create configmap <name> --from-file=<path> -n <namespace>

# Secrets
kubectl get secrets -n <namespace>
kubectl describe secret <name> -n <namespace>

# Create Secret from literal
kubectl create secret generic <name> --from-literal=key=value -n <namespace>

# Decode secret (base64)
kubectl get secret <name> -n <namespace> -o jsonpath='{.data.<key>}' | base64 -d
```

### Apply/Delete Resources (Declarative)
```bash
# Apply YAML file
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/  # All YAML files in directory

# Delete from YAML
kubectl delete -f <file.yaml>

# Dry-run (validate without applying)
kubectl apply -f <file.yaml> --dry-run=client
kubectl apply -f <file.yaml> --dry-run=server  # Server-side validation

# Get resource as YAML (for export)
kubectl get <resource> <name> -n <namespace> -o yaml
kubectl get <resource> <name> -n <namespace> -o yaml > export.yaml
```

### Events & Troubleshooting
```bash
# Get events (cluster-wide)
kubectl get events
kubectl get events -n <namespace>
kubectl get events --sort-by='.lastTimestamp'

# Watch resources (auto-refresh)
kubectl get pods -n <namespace> -w
kubectl get all -n <namespace> -w

# Resource usage
kubectl top nodes
kubectl top pods -n <namespace>

# Debug: Run temporary pod
kubectl run debug --image=busybox --rm -it -- sh
kubectl run debug --image=curlimages/curl --rm -it -- sh
```

### HorizontalPodAutoscaler
```bash
# List HPA
kubectl get hpa -n <namespace>

# Describe HPA
kubectl describe hpa <name> -n <namespace>

# Create HPA (imperative)
kubectl autoscale deployment <name> --cpu-percent=70 --min=2 --max=10 -n <namespace>

# Delete HPA
kubectl delete hpa <name> -n <namespace>
```

### All Resources in Namespace
```bash
# Get all resources
kubectl get all -n <namespace>

# Delete all resources in namespace
kubectl delete all --all -n <namespace>
```

---

## 🔧 TROUBLESHOOTING GUIDE

### 1. Pod в CrashLoopBackOff

**Причина:** Container crashes при старте и перезапускается.

**Debugging:**
```bash
# 1. Check logs (current container)
kubectl logs <pod-name> -n <namespace>

# 2. Check logs (previous crashed container)
kubectl logs <pod-name> -n <namespace> --previous

# 3. Describe pod (events)
kubectl describe pod <pod-name> -n <namespace>

# 4. Check resource limits (OOMKilled?)
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "Last State"
```

**Решения:**
- Fix application code (если ошибка в logs)
- Add missing ConfigMap/Secret
- Increase resource limits (если OOMKilled)
- Fix command/args в Deployment

---

### 2. ImagePullBackOff

**Причина:** Не может скачать Docker image.

**Debugging:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>
# Look for: "Failed to pull image", "unauthorized", "not found"

# Check image name
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[0].image}'
```

**Решения:**
- Проверь typo в image name
- Для private registry: добавь imagePullSecrets
- Проверь network connectivity

---

### 3. Pod в Pending

**Причина:** Не может scheduling (нет доступных resources на nodes).

**Debugging:**
```bash
# Describe pod
kubectl describe pod <pod-name> -n <namespace>
# Look for: "Insufficient cpu", "Insufficient memory"

# Check node resources
kubectl top nodes
kubectl describe nodes
```

**Решения:**
- Добавь nodes в cluster
- Уменьши resource requests
- Check node selector/affinity rules

---

### 4. Service не работает

**Причина:** Service не может найти pods (selector mismatch).

**Debugging:**
```bash
# 1. Check endpoints (should have pod IPs)
kubectl get endpoints <service-name> -n <namespace>

# 2. If empty — check selectors
kubectl get service <service-name> -n <namespace> -o yaml | grep selector
kubectl get pods -n <namespace> --show-labels

# 3. Test from inside cluster
kubectl run test --image=curlimages/curl --rm -it -n <namespace> -- sh
curl http://<service-name>
```

**Решения:**
- Fix selector чтобы match pod labels
- Check targetPort = containerPort
- Check NetworkPolicy rules

---

### 5. Health Check Fails

**Причина:** livenessProbe или readinessProbe fails.

**Debugging:**
```bash
# Check probe configuration
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 Probe

# Check logs for application errors
kubectl logs <pod-name> -n <namespace>

# Test probe manually
kubectl exec <pod-name> -n <namespace> -- wget -q -O- http://localhost:80/
```

**Решения:**
- Увеличь `initialDelaySeconds` (app медленно стартует)
- Fix probe path (неправильный endpoint)
- Fix application (если действительно не работает)

---

## 🎯 COMMON PATTERNS

### Pattern 1: Create deployment + service + configmap

```bash
# 1. ConfigMap
kubectl create configmap app-config \
  --from-literal=env=production \
  --from-literal=log_level=info \
  -n shadow-ops

# 2. Deployment
kubectl create deployment app \
  --image=nginx:1.25-alpine \
  --replicas=3 \
  -n shadow-ops

# 3. Expose as service
kubectl expose deployment app \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP \
  -n shadow-ops

# 4. Verify
kubectl get all -n shadow-ops
```

### Pattern 2: Update and rollback

```bash
# Rolling update
kubectl set image deployment/app nginx=nginx:1.26 -n shadow-ops

# Watch progress
kubectl rollout status deployment app -n shadow-ops

# If fails — rollback
kubectl rollout undo deployment app -n shadow-ops
```

### Pattern 3: Debug pod issues

```bash
# 1. Get pod status
kubectl get pods -n shadow-ops

# 2. Describe problematic pod
kubectl describe pod <pod-name> -n shadow-ops

# 3. Check logs
kubectl logs <pod-name> -n shadow-ops
kubectl logs <pod-name> -n shadow-ops --previous

# 4. Interactive debugging
kubectl exec -it <pod-name> -n shadow-ops -- sh
```

### Pattern 4: Scale based on load

```bash
# Manual scaling
kubectl scale deployment app --replicas=5 -n shadow-ops

# Auto-scaling
kubectl autoscale deployment app \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n shadow-ops

# Monitor HPA
kubectl get hpa -n shadow-ops -w
```

---

## 💡 BEST PRACTICES

### Configuration:
- ✅ Всегда указывай resource requests & limits
- ✅ Используй health checks (liveness + readiness)
- ✅ Не используй `latest` tag (specify version)
- ✅ Используй namespaces для isolation
- ✅ ConfigMaps для config, Secrets для passwords

### Deployment:
- ✅ Тестируй на staging first
- ✅ Используй rolling updates (не Recreate)
- ✅ Мониторь rollout: `kubectl rollout status`
- ✅ Держи rollout history для rollback
- ✅ Добавляй change-cause annotations

### Security:
- ✅ Не запускай containers as root
- ✅ Используй RBAC (Role-Based Access Control)
- ✅ Secrets encryption at rest
- ✅ Network Policies для firewall between pods

### High Availability:
- ✅ Минимум 2 replicas в production
- ✅ Pod disruption budgets
- ✅ Anti-affinity rules (distribute pods across nodes)

---

## 🔗 RESOURCES

### Official Docs:
- Kubernetes: https://kubernetes.io/docs/
- k3s: https://docs.k3s.io/
- kubectl reference: https://kubernetes.io/docs/reference/kubectl/

### Interactive Learning:
- Kubernetes By Example: https://kubernetesbyexample.com/
- Play with Kubernetes: https://labs.play-with-k8s.com/
- Katacoda scenarios: https://www.katacoda.com/courses/kubernetes

### Certification:
- CKA (Certified Kubernetes Administrator): https://www.cncf.io/certification/cka/
- Killer.sh practice: https://killer.sh/

### Community:
- CNCF Slack: https://slack.cncf.io/
- r/kubernetes: https://reddit.com/r/kubernetes
- Stack Overflow: [kubernetes] tag

---

**Björn's reminder:**
> "This cheat sheet — your survival guide. Kubernetes has 100+ commands. You need 20 for daily work. Master these 20 first. Rest — when needed. Don't memorize everything. Understand concepts. Commands follow naturally."

**LILITH v7.0:**
> "Сохрани этот cheat sheet. Kubectl — твой main tool теперь. Docker был starter. Kubernetes — production level. Команды кажутся много, но patterns повторяются. Get, describe, logs, apply — 90% работы. Остальное —ググレカス (google it)."

---

<div align="center">

**Episode 25 Artifacts Complete** ✅

Next: Use these references during Episode 26-28 practice.

</div>

