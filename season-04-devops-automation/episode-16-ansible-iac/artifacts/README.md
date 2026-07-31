# Episode 16 Artifacts: Ansible Testing Guide

## 📦 Содержание

Этот каталог содержит инструкции для тестирования Ansible configuration management.

## 🧪 Тестирование Ansible Setup

### 1. Verify Ansible Installation

```bash
# Check Ansible version
ansible --version
# Should show: ansible [core 2.x.x]

# Check Python version
python3 --version
# Should be Python 3.8+

# Test local connection
ansible localhost -m ping
# Expected: localhost | SUCCESS => { "ping": "pong" }
```

### 2. Test Inventory

```bash
cd ~/operation-shadow-ansible

# List all hosts
ansible all -i inventory.ini --list-hosts
# Should show 50+ hosts

# List hosts by group
ansible web -i inventory.ini --list-hosts
ansible database -i inventory.ini --list-hosts
ansible cache -i inventory.ini --list-hosts

# Show inventory graph
ansible-inventory -i inventory.ini --graph
```

### 3. Validate Playbook Syntax

```bash
# Check playbook syntax
ansible-playbook playbook.yml --syntax-check
# Should show: playbook: playbook.yml

# Check with dry run
ansible-playbook playbook.yml --check
# Shows what WOULD change without applying

# Check with diff
ansible-playbook playbook.yml --check --diff
# Shows exact file changes
```

### 4. Test Roles

```bash
# List roles
ls -la roles/

# Verify role structure
tree roles/  # If tree installed
# Or:
find roles/ -type f

# Test role independently
ansible localhost -m include_role -a name=common -e "ansible_connection=local"
```

### 5. Test Variables

```bash
# Show variables for host
ansible web-01.operation-shadow.net -i inventory.ini -m debug -a "var=hostvars[inventory_hostname]"

# Show variables for group
ansible web -i inventory.ini -m debug -a "var=nginx_port"

# Show all facts
ansible localhost -m setup
```

### 6. Local Testing (Without Real Servers)

**Option 1: Localhost**

```bash
# Create local inventory
cat > inventory_local.ini << 'EOF'
[local]
localhost ansible_connection=local
EOF

# Run playbook locally
ansible-playbook -i inventory_local.ini playbook.yml -e "ansible_become_pass=YOUR_PASSWORD"
```

**Option 2: Docker Containers**

```bash
# Start test containers
for i in {1..3}; do
  docker run -d --name ansible-test-$i \
    -v ~/.ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro \
    -p 222$i:22 \
    ubuntu:22.04 \
    /bin/bash -c "apt update && apt install -y openssh-server && service ssh start && tail -f /dev/null"
done

# Create inventory
cat > inventory_docker.ini << 'EOF'
[test]
localhost:2221
localhost:2222
localhost:2223

[test:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF

# Run playbook
ansible-playbook -i inventory_docker.ini playbook.yml
```

### 7. Test Templates

```bash
# Render template locally
ansible localhost -m template \
  -a "src=roles/webserver/templates/nginx.conf.j2 dest=/tmp/nginx.conf" \
  -e "nginx_port=8080 nginx_worker_processes=4 ansible_hostname=test-server" \
  --connection=local

# View rendered template
cat /tmp/nginx.conf
```

### 8. Test Security Audit

```bash
# Run audit playbook
ansible-playbook audit.yml

# Check results
ls -lh audit_reports/
cat audit_reports/SUMMARY_*.txt

# Run audit on specific group
ansible-playbook audit.yml --limit web
```

### 9. Ad-hoc Commands Testing

```bash
# Ping all servers
ansible all -i inventory.ini -m ping

# Get uptime
ansible all -i inventory.ini -m shell -a "uptime" -b

# Check disk space
ansible all -i inventory.ini -m shell -a "df -h /" -b

# Check memory
ansible all -i inventory.ini -m shell -a "free -h" -b

# Check installed packages
ansible all -i inventory.ini -m shell -a "dpkg -l | grep docker" -b
```

## 🔐 Testing Ansible Vault

### Create and Test Vault

```bash
# Create vault password file
echo "operation-shadow-vault-2025" > ~/.vault_pass
chmod 600 ~/.vault_pass

# Create encrypted secrets
cat > secrets.yml << 'EOF'
db_password: superSecretPass123
api_key: sk-abc123xyz456
admin_ssh_key: "ssh-ed25519 AAAA..."
EOF

ansible-vault encrypt secrets.yml --vault-password-file ~/.vault_pass

# Verify encryption
cat secrets.yml
# Should show: $ANSIBLE_VAULT;1.1;AES256...

# View decrypted content
ansible-vault view secrets.yml --vault-password-file ~/.vault_pass

# Use in playbook
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

## 📊 Performance Testing

### Measure Execution Time

```bash
# Run with timing
time ansible-playbook playbook.yml

# Enable profile_tasks callback (shows task duration)
# Already enabled in ansible.cfg

# Run and see task timings
ansible-playbook playbook.yml
# Output will show task execution times

# Parallel execution (increase forks)
ansible-playbook playbook.yml --forks 20
```

### Benchmarks

**Expected performance (50 servers):**
- **Basic playbook:** 3-5 minutes
- **Full site.yml:** 5-8 minutes
- **Security audit:** 2-3 minutes

**Manual configuration (comparison):**
- **One server:** 30 minutes
- **50 servers:** 25+ hours
- **Efficiency gain:** 300-500×

## 🚨 Incident Response Testing

### Simulate Server-27 Compromise (from plot)

```bash
# 1. Simulate compromised binary
ansible server-27 -i inventory.ini -m shell -a "touch /usr/bin/openssl.bak && echo 'COMPROMISED' > /usr/bin/openssl" -b

# 2. Run security audit
ansible-playbook audit.yml --limit server-27

# 3. Check audit report
cat audit_reports/server-27_*.txt
# Should detect modified /usr/bin/openssl

# 4. Rebuild server (simulate)
ansible-playbook site.yml --limit server-27

# 5. Verify clean state
ansible-playbook audit.yml --limit server-27
```

## 💡 Best Practices Testing

### 1. Idempotence Test

```bash
# Run playbook twice
ansible-playbook playbook.yml

# Second run should show mostly "ok", no "changed"
ansible-playbook playbook.yml
# Check output: changed=0
```

### 2. Check Mode vs Real Execution

```bash
# Dry run
ansible-playbook playbook.yml --check > /tmp/check_output.txt

# Real run
ansible-playbook playbook.yml > /tmp/real_output.txt

# Compare
diff /tmp/check_output.txt /tmp/real_output.txt
```

### 3. Limit Scope Testing

```bash
# Test on single host first
ansible-playbook playbook.yml --limit web-01

# Then expand to group
ansible-playbook playbook.yml --limit web

# Finally, all servers
ansible-playbook playbook.yml
```

### 4. Tags Testing

```bash
# Run only package installation
ansible-playbook playbook.yml --tags packages

# Run only firewall configuration
ansible-playbook playbook.yml --tags firewall

# Skip Docker installation
ansible-playbook playbook.yml --skip-tags docker
```

## 📚 Learning Objectives

После Episode 16 вы должны уметь:

- ✅ Install and configure Ansible
- ✅ Create inventory files (groups, variables)
- ✅ Write playbooks (tasks, modules, handlers)
- ✅ Organize roles (reusable components)
- ✅ Use variables and templates (Jinja2)
- ✅ Secure secrets with Ansible Vault
- ✅ Automate security audits
- ✅ Scale configuration (1 → 1000 servers)
- ✅ Recover from compromised servers quickly
- ✅ Understand Infrastructure as Code principles

## 🔗 Полезные ссылки

- **Ansible Documentation:** https://docs.ansible.com/
- **Ansible Galaxy (roles):** https://galaxy.ansible.com/
- **Ansible Modules:** https://docs.ansible.com/ansible/latest/modules/modules_by_category.html
- **Jinja2 Templates:** https://jinja.palletsprojects.com/
- **Best Practices:** https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html

## 🎯 Klaus Schmidt's Testing Checklist

```bash
# 1. Inventory correct?
ansible all --list-hosts

# 2. Playbook syntax valid?
ansible-playbook playbook.yml --syntax-check

# 3. What will change? (dry run)
ansible-playbook playbook.yml --check --diff

# 4. Apply configuration
ansible-playbook playbook.yml

# 5. Idempotent? (run again, should be no changes)
ansible-playbook playbook.yml

# 6. Security audit clean?
ansible-playbook audit.yml

# 7. All servers accessible?
ansible all -m ping

# 8. Firewall configured?
ansible all -m shell -a "ufw status" -b

# 9. Services running?
ansible all -m shell -a "systemctl status docker nginx" -b

# 10. Success!
echo "Infrastructure as Code complete!"
```

---

## 💬 LILITH's Notes

> *"Ansible doesn't prevent compromises. But it makes recovery 16× faster. Server-27 rebuilt in 30 minutes vs 8 hours manual. That's the power of Infrastructure as Code."*

> *"Idempotence = run 100 times, same result. Test this: ansible-playbook playbook.yml && ansible-playbook playbook.yml. Second run should be all 'ok', no 'changed'."*

> *"Klaus's wisdom: '50 servers, 3 minutes, one command.' Manual: 25 hours. Ansible: 3 minutes. That's 500× efficiency. Infrastructure as Code isn't optional at scale."*

---

**Klaus Schmidt's Final Wisdom:**

> *"Configuration management is not about managing servers. It's about managing chaos. Today you learned to manage chaos at scale."*

> *"Season 4 complete. Git, Docker, CI/CD, Ansible. Together = Infrastructure as Code. Everything versioned, automated, reproducible. Now Season 5: make it secure."*


