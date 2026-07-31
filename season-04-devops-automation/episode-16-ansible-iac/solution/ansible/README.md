# Episode 16: Ansible & Infrastructure as Code — Solution

## 🎯 Type B Philosophy

**"Configuration management is not about managing servers. It's about managing chaos."**
— Klaus Schmidt

### OLD approach (bash wrapper ❌):
```bash
# ansible_setup.sh (910 lines!)
cat > playbook.yml << 'EOF'
...
EOF
# Generated everything through bash heredoc
```

### NEW approach (Type B ✅):
```bash
# Real Ansible structure with actual YAML files
ansible-playbook -i inventory.ini playbook.yml
```

## 📁 Structure

```
ansible/
├── inventory.ini                       # 50 servers inventory
├── ansible.cfg                         # Ansible configuration
├── playbook.yml                        # Main playbook
├── group_vars/
│   ├── all.yml                         # Global variables
│   └── production.yml                  # Production-specific vars
├── roles/
│   └── common/
│       ├── tasks/main.yml              # Common tasks
│       ├── handlers/main.yml           # Service restart handlers
│       └── templates/
│           ├── sshd_config.j2          # SSH config template
│           ├── ntp.conf.j2             # NTP config template
│           └── jail.local.j2           # Fail2ban config
└── README.md                           # This file
```

## 🚀 Quick Start

### Prerequisites

1. Install Ansible:
```bash
sudo apt update
sudo apt install -y ansible
ansible --version
```

2. Setup SSH keys:
```bash
# Generate deploy key (if not exists)
ssh-keygen -t ed25519 -C "deploy@operation-shadow" -f ~/.ssh/deploy_key

# Copy public key to servers
ssh-copy-id -i ~/.ssh/deploy_key.pub deploy@server-01
```

### Run Playbook

**Dry-run (check mode):**
```bash
cd ansible/
ansible-playbook -i inventory.ini playbook.yml --check
```

**Apply to all 50 servers:**
```bash
ansible-playbook -i inventory.ini playbook.yml
```

**Apply to specific group:**
```bash
# Only web servers
ansible-playbook -i inventory.ini playbook.yml --limit web

# Only databases
ansible-playbook -i inventory.ini playbook.yml --limit database
```

**Apply specific tags:**
```bash
# Only common setup
ansible-playbook -i inventory.ini playbook.yml --tags common

# Only monitoring
ansible-playbook -i inventory.ini playbook.yml --tags monitoring
```

## 📊 Klaus's "50 Servers in 3 Minutes" Demo

```bash
# What Klaus showed in Episode 16:
time ansible-playbook -i inventory.ini playbook.yml

# Output:
# PLAY RECAP *****************************************************
# server-01    : ok=15  changed=8   unreachable=0   failed=0
# server-02    : ok=15  changed=8   unreachable=0   failed=0
# ...
# server-50    : ok=15  changed=8   unreachable=0   failed=0
#
# real    2m47s
# ✓ 50 servers configured identically in under 3 minutes!
```

## 🔧 Key Ansible Concepts

### 1. Inventory
Defines **WHAT** servers to manage:
```ini
[web]
web-01.operation-shadow.net
web-02.operation-shadow.net

[database]
db-01.operation-shadow.net
```

### 2. Playbook
Defines **HOW** to configure servers:
```yaml
- name: Configure web servers
  hosts: web
  roles:
    - nginx
```

### 3. Roles
Reusable components (like functions):
```
roles/common/
├── tasks/       # What to do
├── handlers/    # Service restarts
├── templates/   # Jinja2 configs
└── files/       # Static files
```

### 4. Variables
Configuration data:
```yaml
# group_vars/all.yml
timezone: Europe/Amsterdam
ssh_port: 22
```

### 5. Templates (Jinja2)
Dynamic configuration files:
```jinja2
Port {{ ssh_port }}
PermitRootLogin {{ 'no' if ssh_permit_root_login == false else 'yes' }}
```

## 🎓 Idempotency (Key Concept!)

Run the playbook 100 times → same result:

```bash
# First run
ansible-playbook playbook.yml
# changed=50

# Second run
ansible-playbook playbook.yml
# changed=0  ← No changes, already configured!
```

**Why?** Ansible checks current state before changing anything.

## 🔐 Security: Ansible Vault

Encrypt sensitive data:

```bash
# Create encrypted file
ansible-vault create group_vars/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/vault.yml

# Run playbook with vault password
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

Store secrets in `group_vars/vault.yml`:
```yaml
vault_database_password: "SuperSecurePassword123!"
vault_grafana_password: "AnotherSecurePassword456!"
```

Reference in `group_vars/production.yml`:
```yaml
app_database_password: "{{ vault_database_password }}"
```

## 📈 Comparison: Old vs New

| Metric | Old (bash) | New (Ansible) |
|--------|-----------|---------------|
| Lines of bash | 910 | 0 |
| Configuration | Heredoc in bash | Real YAML files |
| Idempotency | ❌ No | ✅ Yes |
| Scalability | 1 server at a time | 50 servers parallel |
| Time for 50 servers | ~25 hours | ~3 minutes |
| Error rate | High (manual) | Low (automated) |
| Type | ❌ A (wrapper) | ✅ B (IaC) |

## 🧪 Testing

```bash
# Test syntax
ansible-playbook playbook.yml --syntax-check

# Test without changes (dry-run)
ansible-playbook -i inventory.ini playbook.yml --check

# Test on one server first
ansible-playbook -i inventory.ini playbook.yml --limit server-01

# Verbose output (debugging)
ansible-playbook -i inventory.ini playbook.yml -vvv
```

## 📝 Common Tasks

### Ad-hoc commands (quick tasks without playbooks):

```bash
# Ping all servers
ansible -i inventory.ini production -m ping

# Check disk space
ansible -i inventory.ini production -m shell -a "df -h"

# Restart nginx on web servers
ansible -i inventory.ini web -m service -a "name=nginx state=restarted" --become

# Update packages
ansible -i inventory.ini production -m apt -a "upgrade=dist" --become
```

### Gather facts (system information):

```bash
# Collect system info
ansible -i inventory.ini server-01 -m setup

# Filter facts
ansible -i inventory.ini server-01 -m setup -a "filter=ansible_distribution*"
```

## 💬 Klaus's Philosophy

> *"50 servers. One command. 3 minutes."*
>
> *"Ansible is declarative. You describe WHAT you want, not HOW to get there."*
>
> *"Idempotency means you can run it 100 times. Same result. Zero fear."*
>
> *"This is Infrastructure as Code. This is how you scale."*

## ✅ Benefits of Type B Approach

1. **Real Ansible** — Students learn Ansible, not bash tricks
2. **Version Control** — YAML files tracked separately
3. **Reusable** — Roles can be used in other projects
4. **Testable** — `--check` mode validates before applying
5. **Scalable** — Works for 5 servers or 500 servers
6. **Standard** — Industry-standard IaC approach

## 🔄 Migration from Old Approach

If you used old `ansible_setup.sh`:

```bash
# Old way (910 lines of bash generating configs)
./ansible_setup.sh

# New way (direct Ansible usage)
ansible-playbook -i inventory.ini playbook.yml
```

## 🎯 Episode 16 Learning Outcomes

After completing Episode 16, you understand:
- ✅ **Ansible architecture** (inventory, playbooks, roles)
- ✅ **Idempotency** (run multiple times safely)
- ✅ **Infrastructure as Code** (configs as YAML)
- ✅ **Templates** (Jinja2 for dynamic configs)
- ✅ **Secrets management** (Ansible Vault)
- ✅ **Scaling** (1 command → 50 servers)
- ✅ **Type B philosophy** (use tools, don't wrap them)

## 🚀 Next Steps

**Season 4 Complete!** 🎉

Next up: **Season 5 — Security & Pentesting** (Zürich → Geneva 🇨🇭)

---

*"Configuration management is not about managing servers. It's about managing chaos."*
— Klaus Schmidt, Ansible Architect

**Tempelhof Datacenter, Amsterdam → Berlin**
**Day 31-32 of 60**


