# Episode 25: Starter Templates
**Kubernetes Basics** | Season 7

## 📁 Files

### Templates (complete these):
- `deployment.yaml.template` — Deployment для nginx application
- `service.yaml.template` — Service для expose deployment
- `configmap.yaml.template` — ConfigMap для configuration

## 🎯 Your Task

Complete the YAML templates by filling in all `# TODO` sections.

### Step-by-step:

#### 1. Create Namespace (command only, no YAML needed)
```bash
kubectl create namespace shadow-ops
```

#### 2. Complete `deployment.yaml.template`
Fill in:
- `metadata.name`: shadow-web
- `metadata.namespace`: shadow-ops
- `spec.replicas`: 3
- `spec.selector.matchLabels.app`: shadow-web
- `spec.template.metadata.labels.app`: shadow-web
- `spec.template.spec.containers[0].image`: nginx:1.25-alpine
- `spec.template.spec.containers[0].ports[0].containerPort`: 80
- Resource `requests`: cpu="250m", memory="128Mi"
- Resource `limits`: cpu="500m", memory="256Mi"
- `livenessProbe`: path="/", port=80
- `readinessProbe`: path="/", port=80

Save as `deployment.yaml` (remove `.template` suffix) and apply:
```bash
kubectl apply -f deployment.yaml
kubectl get pods -n shadow-ops -w
```

#### 3. Complete `service.yaml.template`
Fill in:
- `metadata.name`: shadow-web-service
- `metadata.namespace`: shadow-ops
- `spec.type`: ClusterIP
- `spec.selector.app`: shadow-web
- `spec.ports[0].port`: 80
- `spec.ports[0].targetPort`: 80

Save as `service.yaml` and apply:
```bash
kubectl apply -f service.yaml
kubectl get service -n shadow-ops
```

Test connectivity:
```bash
kubectl port-forward service/shadow-web-service 8080:80 -n shadow-ops
# In another terminal:
curl http://localhost:8080
```

#### 4. Complete `configmap.yaml.template`
Fill in:
- `metadata.name`: shadow-config
- `metadata.namespace`: shadow-ops
- `data.api_url`: "https://api.shadow-ops.internal"
- `data.log_level`: "debug"
- `data.max_connections`: "100"

Save as `configmap.yaml` and apply:
```bash
kubectl apply -f configmap.yaml
kubectl get configmap -n shadow-ops
```

#### 5. Create Secret (command only)
```bash
kubectl create secret generic shadow-secrets \
  --from-literal=db_password=supersecret123 \
  -n shadow-ops

kubectl get secrets -n shadow-ops
```

#### 6. Manual Scaling
```bash
kubectl scale deployment shadow-web --replicas=5 -n shadow-ops
kubectl get pods -n shadow-ops
```

#### 7. Rolling Update
```bash
kubectl set image deployment/shadow-web nginx=nginx:1.26-alpine -n shadow-ops
kubectl rollout status deployment shadow-web -n shadow-ops
```

#### 8. Rollback (if needed)
```bash
kubectl rollout undo deployment shadow-web -n shadow-ops
kubectl rollout history deployment shadow-web -n shadow-ops
```

## ✅ Verification

После завершения всех заданий проверь:

```bash
# All resources should exist:
kubectl get all -n shadow-ops

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# pod/shadow-web-xxx-yyy            1/1     Running   0          5m
# pod/shadow-web-xxx-zzz            1/1     Running   0          5m
# pod/shadow-web-xxx-aaa            1/1     Running   0          5m

# NAME                         TYPE        CLUSTER-IP      PORT(S)
# service/shadow-web-service   ClusterIP   10.43.xxx.xxx   80/TCP

# NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/shadow-web   3/3     3            3           5m
```

## 🆘 Need Help?

### Progressive Hints available in main README.md:
1. **Stuck > 5 min?** → Read Hint 1 (direction)
2. **Stuck > 10 min?** → Read Hint 2 (commands)
3. **Stuck > 15 min?** → Check Solution (full code)

### Common Issues:

**Pods не запускаются (ImagePullBackOff)?**
```bash
kubectl describe pod <pod-name> -n shadow-ops
# Check image name typo
```

**Service не работает?**
```bash
kubectl get endpoints shadow-web-service -n shadow-ops
# If empty → selector mismatch
# Check: kubectl get pods -n shadow-ops --show-labels
```

**CrashLoopBackOff?**
```bash
kubectl logs <pod-name> -n shadow-ops --previous
kubectl describe pod <pod-name> -n shadow-ops
```

## 📚 Resources

- **kubectl cheat sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **YAML validator**: https://www.yamllint.com/
- **Main README.md**: Full theory + practice with micro-cycles

---

**Good luck!** 🚀 Remember: Björn says *"Configure correctly — everything works. Configure wrong — everything fails spectacularly."*

