# EPISODE 25: KUBERNETES BASICS
**Season 7: Production & Advanced Topics** | Рейкьявик, Исландия 🇮🇸

> *"Kubernetes is not tool. It's operating system for distributed applications."* — Björn Sigurdsson

---

## 📋 ИНФОРМАЦИЯ ОБ ЭПИЗОДЕ

- **Локация:** Рейкьявик, Verne Global Datacenter (бывшая военная база НАТО)
- **Дни операции:** 49-50 из 60
- **Время прохождения:** 5-6 часов
- **Сложность:** ⭐⭐⭐⭐⭐
- **Тип:** Type B (Configuration — kubectl + YAML, minimal bash)

**Персонажи:**
- **Макс Соколов** — главный герой (вы), 47 дней операции позади
- **Виктор Петров** — координатор операции
- **Björn Sigurdsson** — Kubernetes SRE, ex-CCP Games (EVE Online infrastructure)
- **LILITH** — AI-помощник (v7.0 — Production Mode)

**Цель эпизода:** Развернуть production Kubernetes кластер для 50+ серверов операции

---

## 🎬 PROLOGUE: ПРИБЫТИЕ В ИСЛАНДИЮ

### День 49, 08:00 — Keflavík Airport, Рейкьявик

Макс выходит из самолёта. Холодный ветер с Атлантики, чёрные лавовые поля до горизонта, низкие серые облака. Исландия. Край света.

Телефон вибрирует — видеозвонок от Виктора.

**Виктор:** "Добро пожаловать в Исландию, Макс. Это наш последний рубеж перед финалом. Verne Global Datacenter — бывшая военная база НАТО, теперь один из самых защищённых ЦОДов мира. Geothermal энергия, free cooling, полная изоляция. Идеально для критической инфраструктуры."

**Макс:** "Что здесь нужно сделать?"

**Виктор:** "Kubernetes. Production кластер для всех 50 серверов. High availability, zero downtime, auto-scaling. Björn Sigurdsson встретит тебя. Он настраивал инфраструктуру EVE Online — 500,000 игроков онлайн одновременно. Если кто знает production под нагрузкой — это он."

**Макс** (про себя): *"47 дней операции. Новосибирск, Москва, Стокгольм, Санкт-Петербург, Таллин, Амстердам, Берлин, Цюрих, Женева, Шэньчжэнь... и теперь Исландия. Как я здесь оказался?"*

---

### День 49, 10:30 — Verne Global Datacenter

Массивные стальные двери, бетонные стены метровой толщины, камеры безопасности каждые 10 метров. Бывшая база НАТО выглядит неприступной.

У входа стоит высокий мужчина с седыми волосами и спокойным взглядом. Viking.

**Björn:** "Welcome to the edge of the world. I'm Björn. Viktor told me about you. 7 countries, 47 days, from junior sysadmin to... DevSecOps? Impressive. But Kubernetes is different universe. Come. I show you."

Они спускаются в серверную. Гудение кондиционеров, ряды стоек с серверами, холод как в морозильнике.

**Björn:** "This datacenter — NATO Cold War base. Built to survive nuclear war. Now we host servers. Free cooling — Arctic air through lava tunnels. Geothermal power — volcanoes give us electricity. 100% renewable. Zero carbon. Iceland is perfect for datacenters."

**Макс:** "Впечатляюще. Виктор сказал, ты работал на EVE Online?"

**Björn:** "15 years CCP Games. EVE Online — half million players online. Massive space battles. Thousands of ships, real-time combat, millisecond latency critical. If servers lag — players rage. If servers crash — company loses millions. So I learned: everything must work. Always. Under attack. Under load. Under pressure."

**Björn:** "Kubernetes saved us. Before — manual server management. Nightmare. With Kubernetes — orchestration. Automation. Self-healing. If pod crashes — Kubernetes restarts automatically. If node fails — pods migrate to healthy nodes. If load increases — auto-scaling creates more pods. This is why we use Kubernetes."

**Макс:** "Я работал с Docker, CI/CD, Ansible. Kubernetes — следующий шаг?"

**Björn** (качает головой): "Not next step. Different dimension. Docker = одна коробка. Kubernetes = оркестр из тысячи коробок. You must learn orchestration. I teach you. But warning: Kubernetes is not forgiving. One mistake in YAML — whole cluster fails. But if you configure correctly — it runs forever."

**LILITH** (v7.0 — Production Mode): "Макс. Ты в Исландии. Последний рубеж перед финалом Season 8. Kubernetes — это не просто инструмент. Это операционная система для распределённых приложений. Björn прав: configure once, run forever. Или configure wrong, crash immediately. Учись. У тебя 2 дня."

---

## 📚 ТЕОРИЯ: KUBERNETES MICRO-CYCLES

> **Структура:** 8 micro-cycles × 10-15 минут
> **Pattern:** 🎬 Сюжет → 📚 Теория → 💻 Практика → 🤔 Вопрос

---

## 🔄 ЦИКЛ 1: ЧТО ТАКОЕ KUBERNETES? (10 минут)

### 🎬 Сюжет (2 мин)

**Björn:** "First question. You know Docker. You can run one container. But you have 50 servers. 200 containers. How to manage?"

**Макс:** "Ansible? Docker Compose?"

**Björn:** "Good for 5 servers. Not good for 50. Not good for 500. Ansible runs commands. Docker Compose runs containers on one host. Kubernetes — orchestration for many hosts. Come. I show you diagram."

*[Björn рисует на доске]*

### 📚 Теория: Kubernetes Architecture (5-7 мин)

**Метафора:** Kubernetes = Оркестр

Представь оркестр:
- **Музыканты** = Containers (каждый играет свою партию)
- **Дирижёр** = Control Plane (координирует всех)
- **Ноты** = YAML манифесты (инструкции что делать)
- **Сцена** = Worker Nodes (где музыканты играют)
- **Группы инструментов** = Pods (контейнеры вместе)

**Kubernetes — это:**
- **Оркестратор контейнеров** (автоматическое управление сотнями/тысячами контейнеров)
- **Распределённая система** (работает на multiple servers одновременно)
- **Self-healing** (если контейнер упал — автоматический restart)
- **Auto-scaling** (нагрузка растёт → автоматически создаются новые pods)
- **Declarative configuration** (вы описываете ЖЕЛАЕМОЕ состояние, Kubernetes достигает его)

**Архитектура:**

```
┌─────────────────────────────────────────────────┐
│             KUBERNETES CLUSTER                   │
├─────────────────────────────────────────────────┤
│                                                  │
│  CONTROL PLANE (мозг кластера)                  │
│  ├─ API Server      (центральный интерфейс)     │
│  ├─ Scheduler       (распределяет pods)         │
│  ├─ Controller Mgr  (поддерживает состояние)    │
│  └─ etcd            (database состояния)        │
│                                                  │
│  WORKER NODES (рабочие машины)                  │
│  ├─ Node 1                                      │
│  │  ├─ kubelet      (агент на node)            │
│  │  ├─ kube-proxy   (сетевые правила)          │
│  │  └─ Pods → Containers (приложения)          │
│  ├─ Node 2                                      │
│  │  └─ [то же самое]                           │
│  └─ Node N...                                   │
│                                                  │
└─────────────────────────────────────────────────┘
```

**Основные концепты:**

1. **Pod** — минимальная единица (1+ контейнеров вместе)
2. **Deployment** — управляет pods (сколько реплик, какая версия)
3. **Service** — единая точка входа (балансировка между pods)
4. **ConfigMap** — конфигурация (без перестройки образов)
5. **Secret** — секреты (пароли, ключи, зашифрованы)
6. **Namespace** — изоляция (разные проекты/окружения)

**Почему Kubernetes?**

❌ **Без Kubernetes:**
- Ansible run на 50 серверах → 10 минут
- Контейнер упал? Вручную перезапуск
- Нагрузка выросла? Вручную добавить серверы
- Update? Downtime 10-30 минут

✅ **С Kubernetes:**
- Deploy за секунды (kubectl apply)
- Контейнер упал? Авто-restart за 5 секунд
- Нагрузка? Auto-scaling автоматически
- Rolling update → ZERO downtime

**Björn's wisdom:**
> "Kubernetes is not tool. It's operating system for cloud. Like Linux manages processes — Kubernetes manages containers."

**LILITH:**
> "Kubernetes как дирижёр. Ты даёшь ноты (YAML), он управляет оркестром (pods). Если музыкант фальшивит (pod crash) — заменяет его. Если публика шумная (high load) — добавляет музыкантов (scaling). Ты только говоришь ЧЕГО хочешь. Kubernetes делает КАК."

### 💻 Практика (3-5 мин)

**Задание:** Проверь свою систему для Kubernetes

```bash
# 1. Проверь CPU (минимум 2 cores для k3s)
nproc

# 2. Проверь память (минимум 2GB для k3s)
free -h

# 3. Проверь disk space (минимум 10GB)
df -h

# 4. Проверь Docker installed (опционально, но рекомендуется)
docker --version
```

**Ожидаемый результат:**
- CPU: 2+ cores
- RAM: 2GB+ free
- Disk: 10GB+ free
- Docker: version 20+

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Вопрос. Ты запустил 50 Docker контейнеров на 10 серверах вручную. Один сервер упал. Что происходит с контейнерами на нём?"

<details>
<summary>💡 Думай 30 секунд перед проверкой</summary>

**Ответ:** Контейнеры **пропали**. Docker не перемещает контейнеры между хостами автоматически.

**Kubernetes решение:** Если Node падает → Kubernetes автоматически создаёт pods на здоровых nodes. Self-healing.

**Вывод:** Kubernetes = автоматическая миграция при failures. Docker standalone = manual recovery.

</details>

---

## 🔄 ЦИКЛ 2: УСТАНОВКА KUBERNETES (12 минут)

### 🎬 Сюжет (2 мин)

**Björn:** "Choose your weapon. Production Kubernetes — many options. EKS, GKE, AKS — cloud managed. Good, but expensive. Self-hosted — kubeadm, k3s, minikube."

**Björn:** "For learning and small clusters — k3s perfect. Lightweight. 40MB binary. Uses half memory of full Kubernetes. But 100% compatible. CNCF certified. I use k3s for edge deployments."

**Макс:** "k3s подходит для production?"

**Björn:** "Yes. Rancher uses k3s for IoT, edge computing, ARM devices. We use k3s for testing. For your 50 servers — k3s or full Kubernetes both work. Start with k3s. Easier. Faster."

### 📚 Теория: k3s vs Kubernetes (5-7 мин)

**Kubernetes distributions сравнение:**

| Distribution | Size | RAM | Use Case | Complexity |
|--------------|------|-----|----------|------------|
| **k3s** | 40MB | 512MB | IoT, Edge, Learning | ⭐☆☆☆☆ |
| **minikube** | 200MB | 2GB | Local development | ⭐⭐☆☆☆ |
| **kubeadm** | Full | 4GB+ | Production self-hosted | ⭐⭐⭐⭐☆ |
| **EKS/GKE/AKS** | Cloud | Managed | Production cloud | ⭐⭐⭐☆☆ |

**k3s особенности:**
- ✅ Lightweight (удалены cloud provider integrations)
- ✅ Single binary (easy install)
- ✅ Автоматически встроенные: containerd, CoreDNS, Traefik, ServiceLB
- ✅ CNCF certified (100% Kubernetes API compatible)
- ✅ Production-ready (используется Rancher, SUSE)

**Installation methods:**

1. **Automatic script** (рекомендуется):
```bash
curl -sfL https://get.k3s.io | sh -
```

2. **Manual binary** (для понимания):
```bash
wget https://github.com/k3s-io/k3s/releases/download/v1.28.3+k3s1/k3s
chmod +x k3s
sudo mv k3s /usr/local/bin/
```

**После установки:**
```bash
# Проверка статуса
sudo systemctl status k3s

# kubectl доступ (k3s включает kubectl)
sudo k3s kubectl get nodes

# Или создать symlink
sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl
```

**kubeconfig location:**
```bash
# k3s kubeconfig (нужен sudo)
/etc/rancher/k3s/k3s.yaml

# Для доступа без sudo (опционально):
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config
```

**kubectl basics:**
```bash
kubectl version              # Kubernetes версия
kubectl cluster-info         # Cluster endpoints
kubectl get nodes            # Список nodes
kubectl get pods --all-namespaces  # Все pods
```

**Björn's wisdom:**
> "k3s is Kubernetes without bloat. Like Linux Alpine. Small, fast, powerful. Perfect for edge. Perfect for learning. Perfect for Verne Global."

**LILITH:**
> "k3s = Kubernetes минус cloud bloat. 40MB binary vs 2GB full install. Но API identical. Ты учишь k3s — ты знаешь Kubernetes. Разница только в размере, не в functionality."

### 💻 Практика (3-5 мин)

**Задание 1: Install k3s**

```bash
# 1. Install k3s (automatic script)
curl -sfL https://get.k3s.io | sh -

# 2. Проверка installation
sudo systemctl status k3s

# 3. Setup kubectl access (без sudo)
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# 4. Test kubectl
kubectl version
kubectl get nodes
```

**Ожидаемый результат:**
```
NAME       STATUS   ROLES                  AGE   VERSION
your-host  Ready    control-plane,master   1m    v1.28.3+k3s1
```

**Troubleshooting:**
- Если `k3s` не найден → проверь PATH: `export PATH=$PATH:/usr/local/bin`
- Если "permission denied" → используй `sudo kubectl` или fix kubeconfig ownership
- Если node "NotReady" → подожди 30-60 секунд (k3s инициализируется)

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "k3s установлен. Сколько containers уже работает в кластере? (Hint: `kubectl get pods --all-namespaces`)"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** ~10-15 system pods уже running!

k3s автоматически создаёт:
- `kube-system` namespace: CoreDNS, metrics-server, traefik
- `coredns` — DNS для кластера
- `traefik` — Ingress controller
- `local-path-provisioner` — storage
- `metrics-server` — ресурсы monitoring

**Вывод:** Kubernetes не пустой после install. System pods работают в background, обеспечивая core functionality.

</details>

---

## 🔄 ЦИКЛ 3: PODS & DEPLOYMENTS (15 минут)

### 🎬 Сюжет (2 мин)

**Björn:** "Kubernetes cluster running. Now we deploy application. In Docker — you run container. In Kubernetes — you don't run containers directly. You create Deployment. Deployment creates Pods. Pods contain containers."

**Макс:** "Зачем такая сложность? Почему не запустить контейнер напрямую?"

**Björn:** "Control. Deployment — это спецификация. 'Я хочу 3 копии nginx'. Kubernetes читает спецификацию и создаёт 3 pods. Если pod умирает — Deployment создаёт новый. If you kill pod manually — Deployment resurrects it. Это self-healing."

*[Björn открывает IDE, показывает YAML file]*

### 📚 Теория: Pods & Deployments (5-7 мин)

**Метафора: Pod = Квартира**

Представь многоквартирный дом:
- **Здание** = Node (физический сервер)
- **Квартира** = Pod (группа контейнеров)
- **Жильцы** = Containers (приложения)
- **Соседи по квартире** = Containers в одном Pod (share resources)

В квартире может быть 1-2 жильца (обычно 1 container per pod, редко 2-3 для sidecar pattern).

**Pod — минимальная единица:**
- Содержит 1+ контейнеров (обычно 1)
- Share network namespace (один IP для всех контейнеров в pod)
- Share storage volumes
- Atomic unit (либо весь pod работает, либо нет)
- Ephemeral (pods умирают и создаются снова)

**Deployment — менеджер pods:**
- Создаёт и управляет ReplicaSet
- ReplicaSet создаёт pods (нужное количество реплик)
- Обеспечивает declarative updates
- Rolling updates (обновление без downtime)
- Rollback (возврат к предыдущей версии)
- Scaling (increase/decrease replicas)

**Hierarchy:**
```
Deployment
 └─ ReplicaSet
     ├─ Pod 1 → Container(s)
     ├─ Pod 2 → Container(s)
     └─ Pod 3 → Container(s)
```

**YAML структура Deployment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shadow-web              # Название deployment
  namespace: shadow-ops          # Namespace (изоляция)
spec:
  replicas: 3                    # Сколько pods создать
  selector:
    matchLabels:
      app: shadow-web            # Какие pods управлять
  template:                      # Шаблон для pods
    metadata:
      labels:
        app: shadow-web          # Label для pod
    spec:
      containers:
      - name: nginx              # Имя контейнера
        image: nginx:1.25        # Docker image
        ports:
        - containerPort: 80      # Port expose
        resources:
          limits:
            cpu: "500m"          # Max CPU (0.5 core)
            memory: "256Mi"      # Max Memory
          requests:
            cpu: "250m"          # Min CPU
            memory: "128Mi"      # Min Memory
```

**Resource units:**
- CPU: `1000m` = 1 core, `500m` = 0.5 core, `100m` = 0.1 core
- Memory: `256Mi` = 256 MiB, `1Gi` = 1 GiB

**kubectl commands:**

```bash
# Create deployment
kubectl apply -f deployment.yaml

# Get deployments
kubectl get deployments
kubectl get deploy            # Короткая форма

# Get pods
kubectl get pods
kubectl get po                # Короткая форма

# Describe (детальная информация)
kubectl describe deployment shadow-web
kubectl describe pod <pod-name>

# Logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f    # Follow (real-time)

# Delete
kubectl delete deployment shadow-web
kubectl delete -f deployment.yaml
```

**Pod lifecycle:**

```
Pending → ContainerCreating → Running → Succeeded/Failed
```

**Pod statuses:**
- `Pending` — ждёт scheduling (node не выбран yet)
- `ContainerCreating` — pulling image
- `Running` — всё работает
- `CrashLoopBackOff` — контейнер падает повторно
- `Error` / `Failed` — ошибка
- `Completed` — job finished successfully

**Björn's wisdom:**
> "Pod is mortal. Deployment is immortal. Pod dies — Deployment creates new pod. This is Kubernetes way. Accept impermanence."

**LILITH:**
> "Pods умирают. Это нормально. Как клетки в теле — постоянно отмирают и возрождаются. Deployment следит чтобы ВСЕГДА было 3 живых pods. Один умер? Создаёт нового. Это self-healing. Твоя задача — описать ЖЕЛАЕМОЕ состояние (3 replicas). Kubernetes достигает его."

### 💻 Практика (3-5 мин)

**Задание 2: Create Namespace**

```bash
# Create namespace для isolation
kubectl create namespace shadow-ops

# Verify
kubectl get namespaces
kubectl get ns              # Короткая форма

# Set default namespace (optional)
kubectl config set-context --current --namespace=shadow-ops
```

**Задание 3: Create Deployment**

Создай файл `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shadow-web
  namespace: shadow-ops
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shadow-web
  template:
    metadata:
      labels:
        app: shadow-web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "500m"
            memory: "256Mi"
          requests:
            cpu: "250m"
            memory: "128Mi"
```

Apply:
```bash
kubectl apply -f deployment.yaml
```

Verify:
```bash
# Watch pods появляться
kubectl get pods -n shadow-ops -w

# Когда все Running:
kubectl get deployment -n shadow-ops
kubectl get pods -n shadow-ops
```

**Ожидаемый результат:**
```
NAME                          READY   STATUS    RESTARTS   AGE
shadow-web-xxxx-yyyyy         1/1     Running   0          30s
shadow-web-xxxx-zzzzz         1/1     Running   0          30s
shadow-web-xxxx-aaaaa         1/1     Running   0          30s
```

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Ты удалил один pod: `kubectl delete pod shadow-web-xxxx-yyyyy`. Сколько pods будет через 10 секунд? 2 или 3?"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **3 pods**. Deployment immediately создаст новый pod.

**Почему:** Deployment spec говорит `replicas: 3`. Kubernetes видит только 2 pods → создаёт третий.

**Попробуй:**
```bash
kubectl delete pod <pod-name> -n shadow-ops
kubectl get pods -n shadow-ops -w
# Увидишь: новый pod появляется почти мгновенно
```

**Вывод:** Нельзя "убить" pods managed by Deployment. Они воскресают как феникс.

</details>

---

## 🔄 ЦИКЛ 4: SERVICES & NETWORKING (15 минут)

### 🎬 Сюжет (2 мин)

**Björn:** "Deployment running. 3 pods. Good. But problem. How to access them? Each pod has IP. But pods ephemeral — они умирают и создаются с новыми IPs. You can't hardcode pod IP in application. Solution: Service. Service — stable endpoint. Load balancer. Pods change — Service stays same."

**Макс:** "Service = LoadBalancer?"

**Björn:** "Service = abstraction. Can be ClusterIP (internal), NodePort (external на node IP), or LoadBalancer (cloud только). For k3s internal cluster — ClusterIP sufficient."

### 📚 Теория: Services (5-7 мин)

**Метафора: Service = Ресепшн отеля**

Представь отель:
- **Комнаты** = Pods (гости заселяются, выселяются, номера меняются)
- **Ресепшн** = Service (единая точка входа, **адрес стабильный**)
- **Сотрудник ресепшена** = kube-proxy (направляет к нужной комнате)

Ты звонишь в отель → ресепшн → они соединяют с комнатой. Неважно какой номер комнаты — ресепшн знает.

**Service — stable network endpoint:**
- **Единый IP** (не меняется)
- **Единый DNS имя** (например `shadow-web.shadow-ops.svc.cluster.local`)
- **Load balancing** между pods (round-robin)
- **Service discovery** (другие pods находят сервис по имени)

**Service types:**

| Type | Access | Use Case |
|------|--------|----------|
| **ClusterIP** | Internal только | Внутренняя коммуникация (default) |
| **NodePort** | External на Node IP:Port | Development, testing |
| **LoadBalancer** | External через Cloud LB | Production (AWS, GCP, Azure) |
| **ExternalName** | CNAME к внешнему сервису | Legacy integration |

**k3s ServiceLB:**
k3s включает встроенный ServiceLB (замена MetalLB). LoadBalancer type работает даже без cloud provider.

**YAML структура Service:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shadow-web-service
  namespace: shadow-ops
spec:
  type: ClusterIP          # Или NodePort, LoadBalancer
  selector:
    app: shadow-web        # Какие pods target (по label)
  ports:
  - protocol: TCP
    port: 80               # Service port (внешний)
    targetPort: 80         # Container port (внутренний)
```

**Service selector:**
Service находит pods по **labels**. В Deployment мы указали `app: shadow-web` → Service ищет pods с этим label.

**DNS в Kubernetes:**
Каждый Service автоматически получает DNS имя:
```
<service-name>.<namespace>.svc.cluster.local

Пример:
shadow-web-service.shadow-ops.svc.cluster.local
```

Внутри кластера можно использовать короткое имя: `shadow-web-service` (если в том же namespace).

**Testing connectivity:**

```bash
# Test from another pod
kubectl run test-pod --image=curlimages/curl -it --rm -- sh
# Inside pod:
curl http://shadow-web-service

# Test from outside (if NodePort/LoadBalancer)
curl http://<node-ip>:<node-port>
```

**Port forwarding (для тестирования):**
```bash
# Forward Service port to localhost
kubectl port-forward service/shadow-web-service 8080:80 -n shadow-ops

# В другом терминале:
curl http://localhost:8080
```

**Björn's wisdom:**
> "Service is contract. 'I promise this endpoint will work'. Pods behind Service can change, restart, move. Service never changes. This is stability."

**LILITH:**
> "Service = единая точка входа. Pods за ним — армия клонов. Один умер? Неважно, Service перенаправляет к живым. Load balancing automatic. DNS automatic. Ты просто говоришь: хочу Service для app=shadow-web. Kubernetes делает остальное."

### 💻 Практика (3-5 мин)

**Задание 4: Create Service**

Создай файл `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shadow-web-service
  namespace: shadow-ops
spec:
  type: ClusterIP
  selector:
    app: shadow-web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

Apply:
```bash
kubectl apply -f service.yaml
```

Verify:
```bash
# Get service
kubectl get service -n shadow-ops
kubectl get svc -n shadow-ops        # Short form

# Describe (shows endpoints)
kubectl describe svc shadow-web-service -n shadow-ops
```

**Ожидаемый результат:**
```
NAME                  TYPE        CLUSTER-IP      PORT(S)   AGE
shadow-web-service    ClusterIP   10.43.123.45    80/TCP    10s

Endpoints: 10.42.0.5:80,10.42.0.6:80,10.42.0.7:80
```

**Test connectivity:**
```bash
# Port-forward to localhost
kubectl port-forward svc/shadow-web-service 8080:80 -n shadow-ops

# В браузере или curl:
curl http://localhost:8080
# Должен вернуть nginx default page
```

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Service имеет 3 endpoints (3 pods). Ты делаешь `curl http://shadow-web-service` 10 раз. На какой pod попадёт запрос?"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **Разные pods, round-robin**.

Service балансирует трафик между всеми endpoints. Примерно:
- Request 1 → Pod A
- Request 2 → Pod B
- Request 3 → Pod C
- Request 4 → Pod A (снова)
- ...

**Попробуй проверить:**
```bash
# Добавь в nginx разные имена pods
kubectl exec -it <pod-name> -n shadow-ops -- sh
echo "Pod: <pod-name>" > /usr/share/nginx/html/index.html

# Повтори для всех 3 pods
# Затем curl несколько раз:
for i in {1..10}; do
  kubectl run test --image=curlimages/curl --rm -it --restart=Never \
    -- curl -s http://shadow-web-service | grep Pod
done
```

**Вывод:** Service = built-in load balancer. Automatic. Free.

</details>

---

## 🔄 ЦИКЛ 5: CONFIGMAPS & SECRETS (12 минут)

### 🎬 Сюжет (2 мин)

**Björn:** "Application running. But hard-coded configuration. Not good. What if you need different config for staging and production? Rebuild image? No. Use ConfigMap. ConfigMap — configuration external to container."

**Макс:** "А для паролей?"

**Björn:** "Secrets. Same as ConfigMap but base64 encoded. Not encrypted by default (warning!), but separated from code. In production — use external secrets manager like Vault. But for learning — Kubernetes Secrets sufficient."

### 📚 Теория: ConfigMaps & Secrets (5-7 мин)

**Метафора: ConfigMap = Книга рецептов**

Представь ресторан:
- **Повар** = Container
- **Блюда** = Application code (в Docker image)
- **Рецепты** = ConfigMap (конфигурация, можно менять)
- **Сейф с секретными ингредиентами** = Secrets (пароли, ключи)

Повар не запоминает рецепты — он читает книгу. Книгу можно обновить без смены повара.

**ConfigMap:**
- Key-value pairs для конфигурации
- Можно mount как файл в container
- Можно использовать как environment variables
- Изменение ConfigMap → нужен pod restart (не automatic)

**ConfigMap YAML:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: shadow-config
  namespace: shadow-ops
data:
  # Key-value format
  api_url: "https://api.shadow-ops.internal"
  log_level: "debug"
  max_connections: "100"

  # File format (multiline)
  app.conf: |
    server {
      listen 80;
      server_name shadow.local;
      root /var/www/html;
    }
```

**Usage в Pod:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    envFrom:
    - configMapRef:
        name: shadow-config    # Все keys как env vars

    # ИЛИ mount как volume:
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: shadow-config
```

**Secret:**
- Аналогично ConfigMap, но для sensitive data
- Base64 encoded (НЕ encrypted! Можно декодировать)
- Best practice: external secrets manager (Vault, AWS Secrets Manager)

**Secret YAML:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: shadow-secrets
  namespace: shadow-ops
type: Opaque
data:
  # Base64 encoded values
  db_password: cGFzc3dvcmQxMjM=    # "password123" в base64
  api_key: c2VjcmV0a2V5          # "secretkey" в base64
```

**Create Secret from command line:**
```bash
kubectl create secret generic shadow-secrets \
  --from-literal=db_password=password123 \
  --from-literal=api_key=secretkey \
  -n shadow-ops
```

**Usage в Pod:**
```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: shadow-secrets
          key: db_password
```

**Важно про Secrets:**

⚠️ **Kubernetes Secrets НЕ encrypted at rest by default!**

В production используй:
- Encryption at rest (Kubernetes feature, нужна настройка)
- External secrets manager (HashiCorp Vault, AWS Secrets Manager)
- Sealed Secrets (Bitnami)

**Björn's wisdom:**
> "ConfigMap for 'I don't care if anyone sees'. Secrets for 'please don't steal my passwords'. But Secrets not encrypted — так что 'please' = polite request, not security guarantee."

**LILITH:**
> "ConfigMap = настройки которые можно показать боссу. Secrets = пароли которые нельзя показать никому. Но Kubernetes Secrets = base64, НЕ encryption. Base64 = encoding, не security. Любой с доступом к etcd видит secrets. Production? Vault. Learning? Kubernetes Secrets достаточно."

### 💻 Практика (3-5 мин)

**Задание 5: Create ConfigMap**

```bash
# Create ConfigMap from literal
kubectl create configmap shadow-config \
  --from-literal=api_url=https://api.shadow-ops.internal \
  --from-literal=log_level=debug \
  -n shadow-ops

# Verify
kubectl get configmap -n shadow-ops
kubectl describe configmap shadow-config -n shadow-ops
```

**ИЛИ через YAML:**

Создай `configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: shadow-config
  namespace: shadow-ops
data:
  api_url: "https://api.shadow-ops.internal"
  log_level: "debug"
```

```bash
kubectl apply -f configmap.yaml
```

**Задание 6: Create Secret**

```bash
# Create Secret
kubectl create secret generic shadow-secrets \
  --from-literal=db_password=supersecret123 \
  -n shadow-ops

# Verify
kubectl get secrets -n shadow-ops
kubectl describe secret shadow-secrets -n shadow-ops

# View decoded secret (for verification only!)
kubectl get secret shadow-secrets -n shadow-ops -o jsonpath='{.data.db_password}' | base64 -d
```

**Update Deployment для использования ConfigMap и Secret:**

Добавь в `deployment.yaml`:
```yaml
spec:
  containers:
  - name: nginx
    # ... existing config ...
    envFrom:
    - configMapRef:
        name: shadow-config
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: shadow-secrets
          key: db_password
```

```bash
kubectl apply -f deployment.yaml
```

Проверка:
```bash
kubectl exec -it <pod-name> -n shadow-ops -- env | grep -E 'api_url|DB_PASSWORD'
```

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Ты изменил ConfigMap. Pods автоматически получат новую конфигурацию?"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **НЕТ**. Pods нужно перезапустить.

**Почему:** ConfigMap читается при старте pod. Изменение ConfigMap → нужен restart.

**Решение:**
```bash
kubectl rollout restart deployment shadow-web -n shadow-ops
```

**Альтернатива:** Mount ConfigMap как volume + application supports hot-reload (автоматическое чтение измененного файла).

**Вывод:** ConfigMap != dynamic configuration по умолчанию. Для true hot-reload нужна application support или external config server.

</details>

---

---

## 🔄 ЦИКЛ 6: SCALING (12 минут)

### 🎬 Сюжет (2 мин)

**День 50, 11:00 — Серверная Verne Global**

**Dmitry** (видеозвонок): "Макс, хорошие новости и плохие. Хорошие — production работает. Плохие — нагрузка растёт. 3 pods не справляются. Нужно 5. Можешь добавить?"

**Björn:** "This is why we use Kubernetes. Scaling is one command. Watch."

*[Björn вводит команду]*

```bash
kubectl scale deployment shadow-web --replicas=5 -n shadow-ops
```

*[Через 10 секунд появляются 2 новых pods]*

**Björn:** "Done. 3 pods → 5 pods. 10 seconds. No downtime. Try this with manual server management."

**Макс:** "Впечатляюще. А можно автоматически? Если нагрузка растёт — автоматически добавлять pods?"

**Björn:** "Yes. HorizontalPodAutoscaler. Based on CPU or memory. Load increases — HPA creates more pods. Load decreases — HPA removes pods. Automatic elasticity."

### 📚 Теория: Scaling в Kubernetes (5-7 мин)

**Метафора: Scaling = Добавление официантов в ресторан**

Представь ресторан:
- **Официанты** = Pods (обслуживают клиентов)
- **Посетители** = Requests (нагрузка)
- **Менеджер** = HPA (следит за нагрузкой, нанимает/увольняет)

Мало посетителей → 2 официанта достаточно.
Много посетителей → нужно 10 официантов.
Ночь, ресторан пуст → обратно 2 официанта.

**Два типа scaling:**

1. **Manual Scaling** (ручное)
2. **Horizontal Pod Autoscaler (HPA)** (автоматическое)

**Manual Scaling:**

```bash
# Scale up (увеличить)
kubectl scale deployment shadow-web --replicas=10 -n shadow-ops

# Scale down (уменьшить)
kubectl scale deployment shadow-web --replicas=2 -n shadow-ops

# Проверка
kubectl get deployment shadow-web -n shadow-ops
```

**HorizontalPodAutoscaler (HPA):**

HPA автоматически изменяет replicas на основе метрик:
- **CPU utilization** (самый частый)
- **Memory utilization**
- **Custom metrics** (запросы/сек, queue length, etc.)

**Требования для HPA:**
- Metrics Server должен быть установлен (в k3s — уже встроен)
- Resource requests должны быть указаны в Deployment

**HPA YAML:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: shadow-web-hpa
  namespace: shadow-ops
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shadow-web
  minReplicas: 2              # Минимум pods (даже если нагрузки нет)
  maxReplicas: 10             # Максимум pods (защита от runaway)
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70   # Target: держать CPU ~70%
```

**Как работает HPA:**

```
1. Metrics Server собирает CPU/Memory каждые 15 секунд
2. HPA проверяет metrics каждые 30 секунд
3. Если CPU > 70% → увеличивает replicas
4. Если CPU < 70% → уменьшает replicas (но не меньше minReplicas)
5. Scale up быстрее чем scale down (защита от flapping)
```

**Formula:**
```
desiredReplicas = ceil[currentReplicas × (currentMetric / targetMetric)]

Пример:
currentReplicas = 3
currentCPU = 90%
targetCPU = 70%

desiredReplicas = ceil[3 × (90 / 70)] = ceil[3.857] = 4 pods
```

**kubectl commands для HPA:**

```bash
# Create HPA (imperative)
kubectl autoscale deployment shadow-web \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n shadow-ops

# Get HPA status
kubectl get hpa -n shadow-ops

# Describe HPA (events, current metrics)
kubectl describe hpa shadow-web-hpa -n shadow-ops

# Delete HPA
kubectl delete hpa shadow-web-hpa -n shadow-ops
```

**Мониторинг scaling:**

```bash
# Watch pods появляться/исчезать
kubectl get pods -n shadow-ops -w

# Watch HPA в real-time
watch kubectl get hpa -n shadow-ops
```

**Best practices:**

✅ **DO:**
- Устанавливай resource requests (иначе HPA не работает)
- Используй `minReplicas: 2+` (для high availability)
- Устанавливай разумный `maxReplicas` (защита от costs)
- Мониторь HPA events (`kubectl describe hpa`)

❌ **DON'T:**
- Не используй HPA + manual scaling одновременно (конфликт)
- Не ставь слишком низкий target (будет constant scaling)
- Не ставь minReplicas=1 в production (single point of failure)

**Björn's wisdom:**
> "Scaling is not about more resources. It's about right amount of resources. Too few — users wait. Too many — money waste. HPA finds balance automatically."

**LILITH:**
> "HPA как термостат. Ты ставишь target temperature (70% CPU). Термостат автоматически включает/выключает обогрев чтобы поддерживать. Kubernetes делает то же с pods. Умный, автоматический, эффективный."

### 💻 Практика (3-5 мин)

**Задание 7: Manual Scaling**

```bash
# Current state
kubectl get deployment shadow-web -n shadow-ops
# Должно быть: 3/3 replicas

# Scale up to 5
kubectl scale deployment shadow-web --replicas=5 -n shadow-ops

# Watch pods появляться
kubectl get pods -n shadow-ops -w
# Ctrl+C чтобы остановить watch

# Verify
kubectl get deployment shadow-web -n shadow-ops
# Должно быть: 5/5 replicas
```

**Задание 8: Horizontal Pod Autoscaler (optional)**

Создай файл `hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: shadow-web-hpa
  namespace: shadow-ops
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shadow-web
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

```bash
# Apply HPA
kubectl apply -f hpa.yaml

# Verify
kubectl get hpa -n shadow-ops

# Generate load (optional, advanced)
# kubectl run load-generator --image=busybox --restart=Never \
#   -- /bin/sh -c "while true; do wget -q -O- http://shadow-web-service; done"

# Watch HPA adjust replicas
watch kubectl get hpa -n shadow-ops
```

**Примечание:** HPA может показывать `<unknown>` для metrics если нет нагрузки или metrics server ещё собирает данные. Подожди 1-2 минуты.

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "HPA установлен с `minReplicas: 2`, `maxReplicas: 10`. CPU usage = 30% (target 70%). Сколько pods будет?"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **2 pods** (minReplicas).

**Почему:**
- CPU = 30%, target = 70% → нагрузка низкая
- HPA хочет scale down: 2 × (30/70) = 0.86 → 1 pod
- Но minReplicas = 2 → HPA не может уменьшить меньше 2

**Вывод:** minReplicas = safety net. Даже при нулевой нагрузке — минимум 2 pods работают (high availability).

</details>

---

## 🔄 ЦИКЛ 7: ROLLING UPDATES & ROLLBACK (12 минут)

### 🎬 Сюжет (2 мин)

**День 50, 14:20 — Production deployment**

**Dmitry** (видеозвонок, паника): "Макс! Я обновил nginx image до новой версии. Deployment failed! Pods в CrashLoopBackOff! Production не работает!"

*[На мониторе: статусы pods показывают Error]*

**Björn** (спокойно): "This is why we test. Show me `kubectl describe pod`."

*[Debugging: новый nginx image имеет wrong config, контейнер падает при старте]*

**Björn:** "Rollback. Kubernetes saves previous version. One command — back to working state."

```bash
kubectl rollout undo deployment shadow-web -n shadow-ops
```

*[10 секунд — pods возвращаются к рабочей версии]*

**Björn:** "Production restored. Zero downtime for users — old pods работали пока новые падали. This is Kubernetes rolling update. If new version crashes — old version still running. Rollback instant."

**Макс:** "Значит можно обновлять production без риска?"

**Björn:** "Without risk? No. Lower risk? Yes. Rolling update = gradual replacement. If new pods fail — deployment stops, old pods remain. Then rollback. But still test staging first. Always."

### 📚 Теория: Updates & Rollback (5-7 мин)

**Метафора: Rolling Update = Смена караула**

Представь охрану здания:
- **Старая смена** = Old pods (версия 1.0)
- **Новая смена** = New pods (версия 2.0)
- **Процесс:** Новая смена приходит, старая уходит — постепенно, не все сразу
- **Если новая смена не готова** → старая остаётся (rollback)

Никогда нет момента когда здание без охраны = zero downtime.

**Rolling Update strategy:**

Kubernetes использует **RollingUpdate** по умолчанию:
- Создаёт новые pods с новой версией (постепенно)
- Удаляет старые pods (когда новые Ready)
- Если новые pods падают → deployment останавливается, старые остаются
- Zero downtime (traffic всегда обслуживается)

**Deployment strategy в YAML:**

```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate       # Или Recreate (все pods сразу)
    rollingUpdate:
      maxUnavailable: 1       # Максимум 1 pod может быть down
      maxSurge: 1             # Максимум 1 extra pod во время update
```

**maxUnavailable и maxSurge:**

Пример: 3 replicas, maxUnavailable=1, maxSurge=1

```
Initial state:     Pod1  Pod2  Pod3          (v1.0)
Step 1: Create new Pod4                       (v1.0 + v2.0)
Step 2: Delete old Pod1  Pod2  Pod3  Pod4    (v1.0 + v2.0)
Step 3: Create new       Pod2  Pod3  Pod4  Pod5  (v1.0 + v2.0)
Step 4: Delete old             Pod3  Pod4  Pod5  (v1.0 + v2.0)
...
Final state:                   Pod4  Pod5  Pod6  (v2.0)
```

В любой момент минимум 2 pods работают (3 - maxUnavailable=1).

**kubectl commands для updates:**

```bash
# Update image (declarative)
kubectl set image deployment/shadow-web nginx=nginx:1.26 -n shadow-ops

# Или edit deployment YAML и apply
kubectl apply -f deployment.yaml

# Watch rollout status
kubectl rollout status deployment shadow-web -n shadow-ops

# Pause rollout (если проблемы)
kubectl rollout pause deployment shadow-web -n shadow-ops

# Resume rollout
kubectl rollout resume deployment shadow-web -n shadow-ops

# Rollback to previous version
kubectl rollout undo deployment shadow-web -n shadow-ops

# Rollback to specific revision
kubectl rollout undo deployment shadow-web --to-revision=2 -n shadow-ops
```

**Rollout history:**

Kubernetes хранит историю deployments (по умолчанию 10 revisions):

```bash
# View history
kubectl rollout history deployment shadow-web -n shadow-ops

# Output:
# REVISION  CHANGE-CAUSE
# 1         kubectl apply ... (initial)
# 2         kubectl set image ... (nginx:1.25 -> 1.26)
# 3         kubectl set image ... (nginx:1.26 -> 1.27)

# View specific revision details
kubectl rollout history deployment shadow-web --revision=2 -n shadow-ops
```

**Чтобы сохранить CHANGE-CAUSE:**
```bash
kubectl apply -f deployment.yaml --record
# Или добавь annotation в YAML:
# metadata:
#   annotations:
#     kubernetes.io/change-cause: "Updated nginx to 1.26"
```

**Health checks для safe deployments:**

```yaml
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    livenessProbe:          # Проверка "жив ли контейнер?"
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
    readinessProbe:         # Проверка "готов ли к трафику?"
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 3
```

- **livenessProbe:** Если fails → Kubernetes restarts container
- **readinessProbe:** Если fails → Kubernetes не отправляет трафик (pod из Service endpoints)

**Deployment failure detection:**

Kubernetes автоматически определяет failed deployment:
- Если новые pods не становятся Ready за `progressDeadlineSeconds` (default 600s)
- Если readinessProbe fails
- Deployment status становится "Progressing: False"

**Best practices:**

✅ **DO:**
- Всегда используй health checks (liveness + readiness)
- Тестируй на staging перед production
- Мониторь rollout: `kubectl rollout status`
- Держи rollout history (для rollback)
- Используй CI/CD с автоматическими тестами

❌ **DON'T:**
- Не используй `strategy: Recreate` в production (downtime!)
- Не пропускай readinessProbe (broken pods получат трафик)
- Не удаляй rollout history (`revisionHistoryLimit: 0`)

**Björn's wisdom:**
> "Deployment is not 'push and pray'. It's 'push and validate'. Rolling update gives you safety net. But still test first. Kubernetes is smart, not magic."

**LILITH:**
> "Rolling update = страховка, не гарантия. Kubernetes постепенно заменяет pods. Если новые падают — старые остаются, rollback мгновенный. Но лучше не доводить до rollback. Тестируй staging. Всегда."

### 💻 Практика (3-5 мин)

**Задание 9: Rolling Update**

```bash
# Current image version
kubectl get deployment shadow-web -n shadow-ops -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: nginx:1.25-alpine

# Update to newer version
kubectl set image deployment/shadow-web nginx=nginx:1.26-alpine -n shadow-ops

# Watch rollout progress
kubectl rollout status deployment shadow-web -n shadow-ops
# Output: "deployment "shadow-web" successfully rolled out"

# Verify pods updated
kubectl get pods -n shadow-ops
# Должны быть новые pods (другие имена)

# Check image version
kubectl get deployment shadow-web -n shadow-ops -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: nginx:1.26-alpine
```

**Задание 10: Rollback**

Представим новая версия broken (симуляция):

```bash
# Update to non-existent image (will fail)
kubectl set image deployment/shadow-web nginx=nginx:999-broken -n shadow-ops

# Watch — новые pods будут в ImagePullBackOff или CrashLoopBackOff
kubectl get pods -n shadow-ops -w

# Rollback to previous working version
kubectl rollout undo deployment shadow-web -n shadow-ops

# Verify rollback successful
kubectl rollout status deployment shadow-web -n shadow-ops
kubectl get pods -n shadow-ops
# Pods вернулись к nginx:1.26-alpine
```

**View rollout history:**
```bash
kubectl rollout history deployment shadow-web -n shadow-ops
```

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Rolling update started. 3 old pods (v1.0), создаются 3 new pods (v2.0). New pods в CrashLoopBackOff. Что случится с production?"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **Production продолжает работать** (old pods v1.0).

**Почему:**
- Rolling update создаёт новые pods постепенно
- Старые pods НЕ удаляются пока новые не Ready
- Если новые pods падают → deployment останавливается
- Old pods continue serving traffic
- Service endpoints содержат только healthy pods (old v1.0)

**Вывод:** Zero downtime даже при failed deployment. Старая версия защищает production пока новая не proven работающей.

**Действие:** `kubectl rollout undo` для возврата.

</details>

---

## 🔄 ЦИКЛ 8: TROUBLESHOOTING & BEST PRACTICES (15 минут)

### 🎬 Сюжет (2 мин)

**День 50, 16:00 — Debugging session**

**Макс:** "Björn, у меня pod в CrashLoopBackOff. Как debug?"

**Björn:** "Show me. `kubectl describe pod <name>`. This is first command always. Kubernetes events tell you what happened. Describe = X-ray vision into pod."

*[kubectl describe показывает: Back-off restarting failed container]*

**Björn:** "Container crashes. Why? Check logs. `kubectl logs <pod-name>`. Logs = application говорит что случилось."

*[Logs показывают: configuration file missing]*

**Björn:** "ConfigMap not mounted. Check deployment YAML. volumeMounts section. This is typical mistake — forgot to mount ConfigMap. Fix YAML, reapply, pod restarts, problem solved."

**Макс:** "Это всегда такой процесс? Describe → Logs → Fix YAML?"

**Björn:** "90% of problems — yes. Other 10% — network issues, resource limits, image pull errors. I teach you common problems and how to fix. This is Kubernetes troubleshooting."

### 📚 Теория: Troubleshooting (7-10 мин)

**Common Kubernetes issues:**

### 1️⃣ **CrashLoopBackOff**

**Симптомы:** Pod постоянно перезапускается

**Причины:**
- Application crashes при старте
- Missing configuration
- Wrong command/args
- Port already in use

**Debugging:**
```bash
# 1. Describe pod (events)
kubectl describe pod <pod-name> -n shadow-ops

# 2. Check logs
kubectl logs <pod-name> -n shadow-ops

# 3. Check previous container logs (если crashed)
kubectl logs <pod-name> -n shadow-ops --previous

# 4. Check resource limits (OOMKilled?)
kubectl describe pod <pod-name> -n shadow-ops | grep -A 5 "Last State"
```

**Решения:**
- Fix application code
- Add missing ConfigMap/Secret
- Increase resource limits
- Fix command/args в Deployment

---

### 2️⃣ **ImagePullBackOff**

**Симптомы:** Не может скачать Docker image

**Причины:**
- Image не существует (typo в имени)
- Private registry без credentials
- Network issues

**Debugging:**
```bash
kubectl describe pod <pod-name> -n shadow-ops
# Look for: "Failed to pull image", "unauthorized"

# Check image name
kubectl get pod <pod-name> -n shadow-ops -o jsonpath='{.spec.containers[0].image}'
```

**Решения:**
- Исправь image name (проверь typo)
- Добавь imagePullSecrets для private registry:
```yaml
spec:
  imagePullSecrets:
  - name: registry-credentials
```
- Проверь network connectivity: `kubectl run test --image=busybox --rm -it -- nslookup docker.io`

---

### 3️⃣ **Pending (не может scheduling)**

**Симптомы:** Pod остаётся в Pending, не переходит в Running

**Причины:**
- Недостаточно resources (CPU/Memory на nodes)
- Node selector/affinity не match
- PersistentVolume не available

**Debugging:**
```bash
kubectl describe pod <pod-name> -n shadow-ops
# Look for: "Insufficient cpu", "Insufficient memory", "no nodes available"

# Check node resources
kubectl top nodes
kubectl describe nodes
```

**Решения:**
- Увеличь cluster capacity (добавь nodes)
- Уменьши resource requests в Deployment
- Исправь node selector/affinity rules

---

### 4️⃣ **Service не доступен**

**Симптомы:** `curl http://service-name` не работает

**Причины:**
- Service selector не match pod labels
- Service targetPort != container port
- Network policy блокирует трафик

**Debugging:**
```bash
# 1. Check Service endpoints
kubectl get endpoints -n shadow-ops
# Должны быть IP адреса pods

# 2. If endpoints empty — selector mismatch
kubectl get service shadow-web-service -n shadow-ops -o yaml | grep selector
kubectl get pods -n shadow-ops --show-labels

# 3. Check port mapping
kubectl describe service shadow-web-service -n shadow-ops

# 4. Test connectivity from another pod
kubectl run test --image=curlimages/curl --rm -it -- sh
curl http://shadow-web-service
```

**Решения:**
- Исправь selector чтобы match pod labels
- Проверь targetPort = containerPort
- Check NetworkPolicy rules

---

### 5️⃣ **High Memory/CPU (OOMKilled)**

**Симптомы:** Pod killed с OOMKilled status

**Причины:**
- Memory leak в приложении
- Resource limits слишком низкие
- Unexpected load spike

**Debugging:**
```bash
# Check resource usage
kubectl top pods -n shadow-ops

# Check limits
kubectl describe pod <pod-name> -n shadow-ops | grep -A 5 Limits

# Check events for OOMKilled
kubectl describe pod <pod-name> -n shadow-ops | grep OOMKilled
```

**Решения:**
- Увеличь memory limits:
```yaml
resources:
  limits:
    memory: "512Mi"   # Was 256Mi
```
- Fix memory leak в application
- Add HPA для scaling при high load

---

### **Kubernetes Best Practices Summary:**

✅ **Configuration:**
- Всегда указывай resource requests & limits
- Используй health checks (liveness + readiness)
- Не используй `latest` tag (specify version)
- Используй namespaces для isolation
- ConfigMaps для config, Secrets для passwords

✅ **Deployment:**
- Тестируй на staging first
- Используй rolling updates (не Recreate)
- Мониторь rollout: `kubectl rollout status`
- Держи rollout history для rollback
- Добавляй change-cause annotations

✅ **Monitoring:**
- Включай metrics-server (для HPA и `kubectl top`)
- Check pod logs регулярно: `kubectl logs`
- Мониторь events: `kubectl get events`
- Используй Prometheus/Grafana (Episode 26!)

✅ **Security:**
- Не запускай containers as root
- Используй RBAC (Role-Based Access Control)
- Secrets encryption at rest (production)
- Network Policies для firewall between pods
- Regular security audits: `kubectl auth can-i`

❌ **Avoid:**
- `latest` image tag (non-deterministic)
- Running as root user
- No resource limits (risk of resource exhaustion)
- Single replica в production (no HA)
- Manual kubectl commands в production (use CI/CD + GitOps)

**Björn's wisdom:**
> "Kubernetes gives you power. With power comes responsibility. Configure correctly — everything works. Configure wrong — everything fails spectacularly. This is why we test, monitor, and have rollback plan. Always."

**LILITH:**
> "Troubleshooting Kubernetes = детектив работа. Events + Logs + Describe = 90% ответов. Остальное — experience. Каждая ошибка учит. CrashLoopBackOff кажется страшным первый раз. 20-й раз — знаешь где смотреть. Practice."

### 💻 Практика (3-5 мин)

**Troubleshooting drill:**

```bash
# 1. Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# 2. Check specific namespace
kubectl get all -n shadow-ops

# 3. Describe problematic pod
kubectl describe pod <pod-name> -n shadow-ops

# 4. Check logs
kubectl logs <pod-name> -n shadow-ops
kubectl logs <pod-name> -n shadow-ops --previous  # If crashed

# 5. Check resource usage
kubectl top pods -n shadow-ops
kubectl top nodes

# 6. Check events (cluster-wide)
kubectl get events --sort-by='.lastTimestamp' -n shadow-ops

# 7. Interactive debug
kubectl exec -it <pod-name> -n shadow-ops -- sh
# Inside container: check files, test network, etc.
```

**Common kubectl shortcuts:**
```bash
alias k=kubectl
alias kgp='kubectl get pods'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kaf='kubectl apply -f'
```

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Pod status: CrashLoopBackOff, Restarts: 5. Какая первая команда для debugging?"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** `kubectl logs <pod-name> --previous`

**Почему:**
- Pod крашится → нужны logs
- `--previous` flag показывает logs crashed container (до restart)
- Текущий container может быть ещё не started или снова crashed

**Альтернативно:** `kubectl describe pod` покажет events (почему crashed), но logs покажут application errors (what happened).

**Best practice:** Смотри оба:
1. `kubectl describe pod` → Events (Kubernetes perspective)
2. `kubectl logs --previous` → Application logs (app perspective)

</details>

---

## 📋 ПРАКТИЧЕСКИЕ ЗАДАНИЯ

### Структура заданий

Каждое задание имеет **progressive hints** (3-уровневая система):
1. **Задание** — что нужно сделать
2. 💡 **Подсказка 1** (если застрял > 5 мин) — направление
3. 💡 **Подсказка 2** (если застрял > 10 мин) — конкретные команды
4. ✅ **Решение** (если совсем застрял) — полный код с объяснением

---

### 📝 ЗАДАНИЕ 1: Install Kubernetes (k3s)

**Цель:** Установить k3s и настроить kubectl доступ

**Что нужно сделать:**
1. Установить k3s используя официальный скрипт
2. Проверить статус k3s service
3. Настроить kubectl access (без sudo)
4. Проверить что cluster работает

<details>
<summary>💡 Подсказка 1 (направление)</summary>

- k3s официальный installation script: `curl -sfL https://get.k3s.io | sh -`
- После установки k3s работает как systemd service
- kubeconfig файл находится в `/etc/rancher/k3s/k3s.yaml`
- Нужно скопировать его в `~/.kube/config` для доступа без sudo

</details>

<details>
<summary>💡 Подсказка 2 (команды)</summary>

```bash
# 1. Install k3s
curl -sfL https://get.k3s.io | sh -

# 2. Check service
sudo systemctl status k3s

# 3. Setup kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# 4. Test
kubectl get nodes
```

</details>

<details>
<summary>✅ Решение (полный код)</summary>

```bash
#!/bin/bash
# Episode 25: Kubernetes Installation

# 1. Install k3s (automatic script)
echo "Installing k3s..."
curl -sfL https://get.k3s.io | sh -

# Wait for k3s to start
sleep 10

# 2. Check service status
echo "Checking k3s service..."
sudo systemctl status k3s --no-pager

# 3. Setup kubectl access
echo "Setting up kubectl..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# 4. Verify installation
echo "Verifying installation..."
kubectl version --short
kubectl cluster-info
kubectl get nodes

echo "✅ k3s installed successfully!"
```

**Ожидаемый результат:**
```
NAME       STATUS   ROLES                  AGE   VERSION
your-host  Ready    control-plane,master   1m    v1.28.3+k3s1
```

</details>

---

### 📝 ЗАДАНИЕ 2: Create Namespace

**Цель:** Создать namespace `shadow-ops` для изоляции ресурсов

**Что нужно сделать:**
1. Создать namespace `shadow-ops`
2. Проверить что namespace создан
3. (Optional) Установить namespace как default

<details>
<summary>💡 Подсказка 1</summary>

Команда: `kubectl create namespace <name>`

</details>

<details>
<summary>✅ Решение</summary>

```bash
# Create namespace
kubectl create namespace shadow-ops

# Verify
kubectl get namespaces
kubectl get ns  # Short form

# (Optional) Set as default
kubectl config set-context --current --namespace=shadow-ops

# Verify default namespace
kubectl config view --minify | grep namespace
```

</details>

---

### 📝 ЗАДАНИЕ 3: Deploy Application (Deployment)

**Цель:** Создать Deployment с 3 replicas nginx

**Что нужно сделать:**
1. Создать файл `deployment.yaml`
2. Specify: nginx:1.25-alpine image, 3 replicas, resource limits
3. Apply Deployment
4. Verify pods running

<details>
<summary>💡 Подсказка 1</summary>

YAML структура:
- `apiVersion: apps/v1`
- `kind: Deployment`
- `spec.replicas: 3`
- `spec.template.spec.containers` — nginx container

</details>

<details>
<summary>✅ Решение</summary>

Создай `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shadow-web
  namespace: shadow-ops
  labels:
    app: shadow-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shadow-web
  template:
    metadata:
      labels:
        app: shadow-web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "250m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
```

Apply:
```bash
kubectl apply -f deployment.yaml

# Verify
kubectl get deployments -n shadow-ops
kubectl get pods -n shadow-ops

# Watch pods starting
kubectl get pods -n shadow-ops -w
```

</details>

---

*(Аналогично создать задания 4-8: Service, ConfigMap, Secret, Scaling, Rolling Update)*

---

## 🎬 EPILOGUE: PRODUCTION READY

### День 50, 18:00 — Final check

**Björn:** "Deployment complete. Pods running. Service exposed. ConfigMap configured. Secrets secure. Scaling works. Rolling updates tested. Good. You understand Kubernetes basics."

**Björn:** "But this is not end. This is beginning. Kubernetes is deep ocean. We touched surface. Episode 26 — Monitoring. Without monitoring — you are blind. Episode 27 — Performance. Episode 28 — Security hardening. Production requires all."

**Макс:** "От Docker контейнеров до Kubernetes кластера за 2 дня. Голова кругом."

**Björn:** "Normal. EVE Online — 15 years experience, still learn new things. Kubernetes evolves fast. But foundation you learned today — stays same. Pods, Deployments, Services, ConfigMaps. Master basics — advanced topics become easier."

**LILITH:** "Макс, ты прошёл Kubernetes basics. From zero to deployment в 2 дня. Björn прав — это foundation. Season 7 continues: мониторинг, performance, hardening. Каждый episode builds on previous. Ты готов?"

**Макс:** "Готов. 3 дня до Season 8 finale. Нужно успеть всё."

**Viktor** (видеозвонок): "Хорошая работа, Макс. Kubernetes running. Завтра — Guðrún Ásta. Monitoring и alerting. Real-time visibility в production. Отдохни. Tomorrow is day 51."

*[Макс выходит из datacenter. Северное сияние освещает небо. Verne Global — бывшая военная база, теперь fortress для данных. Исландия. Последний рубеж перед финалом.]*

**Макс** (смотрит на северное сияние): *"Kubernetes — это не инструмент. Это экосистема. Pods умирают и воскресают. Services балансируют трафик. Deployments следят за состоянием. Self-healing, auto-scaling, rolling updates. Будто живой организм."*

**Макс:** *"48 дней назад я запускал `ls -la` в терминале. Сегодня я управляю distributed системами. Где я окажусь через 12 дней? Season 8... финальная битва. Используй всё что выучил."*

---

## 📊 СТАТИСТИКА ЭПИЗОДА

**Что вы изучили:**
- ✅ Kubernetes architecture (Control Plane, Worker Nodes)
- ✅ k3s installation и setup
- ✅ Pods & Deployments (replicas, self-healing)
- ✅ Services & Networking (ClusterIP, load balancing, DNS)
- ✅ ConfigMaps & Secrets (configuration management)
- ✅ Scaling (manual & HPA)
- ✅ Rolling Updates & Rollback (zero-downtime deployments)
- ✅ Troubleshooting (logs, describe, debugging)

**Kubernetes resources created:**
- 1 Namespace (`shadow-ops`)
- 1 Deployment (`shadow-web`, 3 replicas)
- 3 Pods (nginx containers)
- 1 Service (`shadow-web-service`)
- 1 ConfigMap (`shadow-config`)
- 1 Secret (`shadow-secrets`)
- 1 HPA (optional, autoscaling)

**kubectl commands mastered:**
- `kubectl get` / `describe` / `logs` / `exec`
- `kubectl apply` / `delete`
- `kubectl scale` / `autoscale`
- `kubectl rollout` (status, undo, history)
- `kubectl top` (resource usage)

**Time spent:** 5-6 hours
**Complexity:** ⭐⭐⭐⭐⭐
**Production readiness:** 60% (basics done, monitoring next)

---

## 🔗 СЛЕДУЮЩИЙ ЭПИЗОД

**Episode 26: Monitoring & Observability**
- Prometheus (metrics collection)
- Grafana (visualization)
- Alertmanager (alerting)
- Real-time visibility в production
- **Персонаж:** Guðrún Ásta (monitoring engineer)

**День 51 операции** — 9 дней до финала

---

## 📚 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ

**Official Documentation:**
- Kubernetes docs: https://kubernetes.io/docs/
- k3s docs: https://docs.k3s.io/
- kubectl cheat sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

**Learning:**
- Kubernetes By Example: https://kubernetesbyexample.com/
- Play with Kubernetes: https://labs.play-with-k8s.com/
- Killer.sh (CKA prep): https://killer.sh/

**Community:**
- CNCF Slack: https://slack.cncf.io/
- Kubernetes subreddit: r/kubernetes
- Stack Overflow: [kubernetes] tag

---

<div align="center">

**"Kubernetes is operating system for cloud."** — Björn Sigurdsson

**EPISODE 25 COMPLETE** ✅

*День 50 из 60 | Рейкьявик, Исландия 🇮🇸 | Production infrastructure готова*

**Next:** Episode 26 — Monitoring (Prometheus/Grafana) 📊

</div>

