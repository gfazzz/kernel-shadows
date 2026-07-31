# Ansible Starter — Episode 16

## Quick Start

1. Fill TODO in:
   - `ansible.cfg`
   - `inventory.ini` 
   - `playbook.yml`
   - `roles/common/tasks/main.yml`

2. Run playbook:
```bash
ansible-playbook -i inventory.ini playbook.yml --check
ansible-playbook -i inventory.ini playbook.yml
```

3. Test connection:
```bash
ansible -i inventory.ini all -m ping
```

**Full workflow in `starter/README.md` at episode root.**

