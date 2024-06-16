#!/bin/bash

# Ensure the script runs with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo." | tee -a /root/setup.log >&2
  exit 1
fi

echo "Starting security setup..." | tee -a /root/setup.log

# Enable and configure fail2ban
echo "Configuring fail2ban..." | tee -a /root/setup.log
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Create a basic jail.local configuration for fail2ban
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600  # Ban hosts for one hour
maxretry = 3    # After three attempts

[sshd]
enabled = true
EOF

systemctl restart fail2ban

# Enforce AppArmor profiles
echo "Enforcing AppArmor profiles..." | tee -a /root/setup.log
apt-get install -y apparmor apparmor-utils
aa-enforce /etc/apparmor.d/* || true

# Configure UFW (Uncomplicated Firewall)
echo "Configuring UFW..." | tee -a /root/setup.log
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 443/tcp  # Allow HTTPS
ufw allow 80/tcp   # Allow HTTP
ufw enable

# Set up sysctl configurations for additional security
echo "Configuring sysctl for security..." | tee -a /root/setup.log
cat <<EOF > /etc/sysctl.d/99-sysctl.conf
# IPv6 disable
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Enable ExecShield (if supported)
kernel.exec-shield = 1
kernel.randomize_va_space = 2

# Enable ptrace protections
kernel.yama.ptrace_scope = 1

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Disable core dumps
fs.suid_dumpable = 0

# Restrict access to kernel pointers in /proc
kernel.kptr_restrict = 2

# Disable unprivileged access to BPF
kernel.unprivileged_bpf_disabled = 1

# Harden sysctl settings for IPv4
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.secure_redirects = 1
net.ipv4.conf.default.send_redirects = 0

# Harden sysctl settings for IPv6
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Enable TCP SYN Cookie Protection
net.ipv4.tcp_syncookies = 1

# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF

# Apply sysctl settings
sysctl --system

# Install and configure ClamAV for antivirus protection
echo "Installing and configuring ClamAV..." | tee -a /root/setup.log
apt-get install -y clamav clamav-daemon
systemctl stop clamav-freshclam
freshclam
systemctl start clamav-freshclam
systemctl enable clamav-daemon
systemctl start clamav-daemon

# Initial ClamAV scan
echo "Running initial ClamAV scan..." | tee -a /root/setup.log
clamscan -r / --exclude-dir="^/sys" --exclude-dir="^/proc" --exclude-dir="^/dev"

# Schedule daily ClamAV scans
cat <<EOF > /etc/cron.daily/clamav_scan
#!/bin/bash
clamscan -r / --exclude-dir="^/sys" --exclude-dir="^/proc" --exclude-dir="^/dev" | mail -s "ClamAV Daily Scan Report" root
EOF
chmod +x /etc/cron.daily/clamav_scan

# Install and configure rkhunter
echo "Installing and configuring rkhunter..." | tee -a /root/setup.log
apt-get install -y rkhunter
rkhunter --update
rkhunter --propupd

# Initial rkhunter check
echo "Running initial rkhunter check..." | tee -a /root/setup.log
rkhunter --check --sk

# Schedule daily rkhunter scans
cat <<EOF > /etc/cron.daily/rkhunter_scan
#!/bin/bash
rkhunter --update
rkhunter --check --sk | mail -s "rkhunter Daily Scan Report" root
EOF
chmod +x /etc/cron.daily/rkhunter_scan

# Configure automatic updates
echo "Configuring automatic updates..." | tee -a /root/setup.log
apt-get install -y unattended-upgrades apt-listchanges
dpkg-reconfigure -plow unattended-upgrades

# Set up auditing with auditd
echo "Setting up auditd..." | tee -a /root/setup.log
apt-get install -y auditd audispd-plugins
systemctl enable auditd
systemctl start auditd

# Basic audit rules (can be expanded based on requirements)
cat <<EOF > /etc/audit/rules.d/audit.rules
# Monitor for unauthorized access to /etc/passwd and /etc/shadow
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes

# Monitor for changes to the audit configuration
-w /etc/audit/ -p wa -k audit_changes

# Monitor for modifications to /bin/su
-w /bin/su -p x -k su_changes

# Monitor login/logout events
-w /var/log/wtmp -p wa -k logins
EOF

# Apply audit rules
service auditd restart

# Disable root SSH login and password authentication
echo "Disabling root SSH login and password authentication..." | tee -a /root/setup.log
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Change SSH port (optional, change the port number as needed)
# echo "Changing SSH port..." | tee -a /root/setup.log
# sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
# systemctl restart sshd

# Configure logrotate for system logs
echo "Configuring logrotate..." | tee -a /root/setup.log
cat <<EOF > /etc/logrotate.d/syslog
/var/log/syslog
{
    rotate 7
    daily
    missingok
    notifempty
    delaycompress
    compress
    postrotate
        reload rsyslog >/dev/null 2>&1 || true
    endscript
}
EOF

# Install and configure Postfix for local email
echo "Installing and configuring Postfix..." | tee -a /root/setup.log
debconf-set-selections <<< "postfix postfix/mailname string $(hostname)"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
apt-get install -y postfix mailutils

# Test Postfix setup by sending a test email to root
echo "Postfix setup complete" | mail -s "Postfix Test Email" root

echo "Security setup complete." | tee -a /root/setup.log

