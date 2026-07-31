# Starter Files — Episode 16: Ansible & IaC

> **"Конфигурируй инфраструктуру через Ansible напрямую, не через bash wrapper."**

---

## 📁 Структура

```
starter/ansible/
├── ansible.cfg         # Ansible config с TODO
├── inventory.ini       # Серверы и группы с TODO
├── playbook.yml        # Main playbook с TODO
├── roles/
│   └── common/
│       └── tasks/
│           └── main.yml  # Роль с TODO
└── README.md
```

---

## 🔄 Workflow

### 1. Заполни TODO в файлах

```bash
cd starter/ansible
nano ansible.cfg      # TODO 1-4
nano inventory.ini    # TODO 1-5
nano playbook.yml     # TODO 1-2
nano roles/common/tasks/main.yml  # TODO 1-3
```

### 2. Тест connection

```bash
ansible -i inventory.ini local -m ping
```

### 3. Check mode (dry-run)

```bash
ansible-playbook -i inventory.ini playbook.yml --check
```

### 4. Run playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

---

## ✅ Чеклист

- [ ] Заполнил TODO в ansible.cfg
- [ ] Заполнил TODO в inventory.ini
- [ ] Заполнил TODO в playbook.yml
- [ ] Заполнил TODO в roles/common/tasks/main.yml
- [ ] Протестировал ping
- [ ] Запустил --check mode
- [ ] Запустил playbook

---

## 💡 Key Commands

```bash
# Ping all hosts
ansible -i inventory.ini all -m ping

# Check syntax
ansible-playbook playbook.yml --syntax-check

# Dry run
ansible-playbook playbook.yml --check

# Run
ansible-playbook playbook.yml

# Run only specific tag
ansible-playbook playbook.yml --tags common

# Limit to specific hosts
ansible-playbook playbook.yml --limit web
```

---

**"50 servers, one command, 3 minutes. That's Infrastructure as Code."** — Klaus Schmidt

