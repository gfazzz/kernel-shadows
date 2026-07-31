# Episode 09: Artifacts
## Users & Permissions Testing Data

This directory contains supporting files for Episode 09.

---

## Files

### team_list.txt
List of KERNEL SHADOWS operation team members with their roles.

**Format:**
```
username:role:department:sudo_level
```

**Usage:**
```bash
# Parse team list
while IFS=: read -r username role dept sudo_level; do
    echo "Creating $username ($role)"
done < artifacts/team_list.txt
```

---

### requirements.txt
Security requirements and permissions policy for the operation.

Contains:
- Principle of Least Privilege guidelines
- Sudo policy
- ACL requirements
- Password policy
- Audit requirements

---

## Testing

### Test User Creation
```bash
# Check if users exist
for user in viktor alex anna dmitry; do
    id "$user" && echo "✓ $user exists" || echo "❌ $user missing"
done
```

### Test Group Membership
```bash
# Verify group memberships
groups viktor  # Should include: operations
groups alex    # Should include: security, netadmin
groups anna    # Should include: security, forensics
groups dmitry  # Should include: operations, devops
```

### Test Sudo Configuration
```bash
# Test Alex's sudo access
sudo -u alex sudo -l  # Should show NETCMDS
sudo -u alex sudo ip addr show  # Should work
sudo -u alex sudo useradd test  # Should FAIL
```

### Test ACL for Anna
```bash
# Anna should read logs but not modify
sudo -u anna cat /var/log/auth.log          # Should work
sudo -u anna echo "test" >> /var/log/auth.log  # Should FAIL
```

### Test Shared Directory
```bash
# Test shared directory permissions
ls -ld /var/operations/shared
# Expected: drwxrws--T ... viktor operations

# Test sticky bit
sudo -u viktor touch /var/operations/shared/viktor_file.txt
sudo -u dmitry touch /var/operations/shared/dmitry_file.txt
sudo -u dmitry rm /var/operations/shared/viktor_file.txt  # Should FAIL (sticky bit)
```

---

## Notes from Андрея Волкова

> *"Testing - это не просто проверка, что код работает. Это проверка, что security работает правильно. Тестируй не только позитивные сценарии (что должно работать), но и негативные (что НЕ должно работать)."*

**Security Testing Checklist:**

1. ✓ Can Alex run network commands? (positive test)
2. ✓ Can Alex NOT run user management? (negative test)
3. ✓ Can Anna read logs? (positive test)
4. ✓ Can Anna NOT modify logs? (negative test)
5. ✓ Can team delete their own files in shared? (positive test)
6. ✓ Can team NOT delete others' files? (negative test - sticky bit)

---

## LILITH Security Tips

```bash
# Monitor sudo usage
sudo journalctl _COMM=sudo --since "1 hour ago"

# Check for failed sudo attempts
sudo grep "sudo.*COMMAND" /var/log/auth.log | grep "NOT"

# Monitor ACL changes
sudo auditctl -w /etc/passwd -p wa -k user_changes
sudo auditctl -w /etc/sudoers -p wa -k sudo_changes

# Alert on new SUID files
find / -perm -4000 -type f -mtime -1 2>/dev/null
```

---

## Troubleshooting

### User creation fails
```bash
# Check if username conflicts with system users
grep "^username:" /etc/passwd

# Check if home directory exists
ls -ld /home/username

# Check for locked accounts
sudo passwd -S username
```

### sudo not working
```bash
# Validate sudoers syntax
sudo visudo -c

# Check sudoers.d file
sudo visudo -c -f /etc/sudoers.d/alex

# Debug sudo
sudo -u alex sudo -l -v
```

### ACL not working
```bash
# Check if filesystem supports ACL
tune2fs -l /dev/sda1 | grep "Default mount options"
# Should include: acl

# If not, remount with ACL
sudo mount -o remount,acl /

# Add to /etc/fstab for persistence
# UUID=...  /  ext4  defaults,acl  0  1
```

### SGID not working on directory
```bash
# Verify SGID bit is set
ls -ld /var/operations/shared
# Should show: drwxrws--T (note the 's' in group permissions)

# Set SGID if missing
sudo chmod g+s /var/operations/shared

# Test: create file and check group
sudo -u viktor touch /var/operations/shared/test.txt
ls -l /var/operations/shared/test.txt
# Group should be 'operations', not 'viktor'
```

---

## Integration with Previous Episodes

### Episode 02 (Shell Scripting)
Use Bash skills to automate user creation:
```bash
#!/bin/bash
users=("viktor" "alex" "anna" "dmitry")
for user in "${users[@]}"; do
    sudo useradd -m -s /bin/bash "$user"
done
```

### Episode 03 (Text Processing)
Parse /etc/passwd for analysis:
```bash
# Extract all users with UID >= 1000 (human users)
awk -F: '$3 >= 1000 {print $1}' /etc/passwd

# Find users without passwords
sudo awk -F: '$2 == "" {print $1}' /etc/shadow
```

### Episode 07 (Firewalls)
Combine with firewall rules for Alex:
```bash
# Alex can configure firewall via sudo
sudo -u alex sudo ufw status
sudo -u alex sudo iptables -L
```

---

## Real-World Scenarios

### Scenario 1: New Team Member
```bash
# Create user
sudo useradd -m -s /bin/bash newuser
echo "newuser:TempPass!" | sudo chpasswd
sudo chage -d 0 newuser

# Add to appropriate groups
sudo usermod -aG operations newuser

# If they need sudo (carefully!)
# sudo visudo -f /etc/sudoers.d/newuser
```

### Scenario 2: Departing Team Member
```bash
# Lock account immediately
sudo passwd -l departed_user

# Move their files to backup
sudo tar czf /backup/departed_user_$(date +%Y%m%d).tar.gz /home/departed_user

# After verification, delete
# sudo userdel -r departed_user
```

### Scenario 3: Compromised Account
```bash
# Immediately lock
sudo passwd -l compromised_user

# Check recent activity
sudo last compromised_user
sudo lastlog -u compromised_user

# Review sudo usage
sudo grep "compromised_user.*sudo" /var/log/auth.log

# Check for backdoors
sudo find /home/compromised_user -name "*.sh" -o -name "cron*"
```

---

## Additional Resources

**Man Pages:**
```bash
man useradd
man chmod
man sudo
man sudoers
man setfacl
```

**Online:**
- [Red Hat: Managing Users](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/managing-users-and-groups_configuring-basic-system-settings)
- [Ubuntu Server Guide: User Management](https://ubuntu.com/server/docs/security-users)
- [sudo Manual](https://www.sudo.ws/docs/man/sudoers.man/)

---

<div align="center">

**"Root — это не привилегия. Это ответственность."**

— Андрей Волков, LETI

</div>

