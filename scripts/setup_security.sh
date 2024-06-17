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
bantime = 3600
maxretry = 3

[sshd]
enabled = true

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
action = iptables[name=HTTP-auth, port=http, protocol=tcp]
logpath = /var/log/nginx/error.log
maxretry = 3

[postfix]
enabled = true
port = smtp,ssmtp
filter = postfix
logpath = /var/log/mail.log
maxretry = 3

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,submissions
filter = dovecot
logpath = /var/log/mail.log
maxretry = 5
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
ufw limit ssh      # Rate limit SSH
ufw allow 123/udp  # Allow NTP
ufw allow 53/udp   # Allow DNS
ufw logging on
ufw enable

echo "Enhanced UFW rules applied." | tee -a /root/setup.log

# Set up sysctl configurations for additional security
echo "Configuring sysctl for security..." | tee -a /root/setup.log
cat <<EOF > /etc/sysctl.d/99-sysctl.conf
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Ignore ICMP redirect messages
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Don't send ICMP redirect messages
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Enable exec-shield
kernel.exec-shield = 1
kernel.randomize_va_space = 2

# Disable IP source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Protect against SYN flood attacks
net.ipv4.tcp_syncookies = 1

# Enable packet forwarding
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Ignore directed pings
net.ipv4.icmp_echo_ignore_all = 1
EOF

# Apply sysctl settings
sysctl --system

echo "Sysctl network parameters hardened." | tee -a /root/setup.log

# Disable unused network services
echo "Disabling unused network services..." | tee -a /root/setup.log

# Disable avahi-daemon (Zeroconf service discovery)
systemctl disable avahi-daemon
systemctl stop avahi-daemon

# Disable CUPS (printing service) if not needed
systemctl disable cups
systemctl stop cups

# Disable NFS server if not needed
systemctl disable nfs-server
systemctl stop nfs-server

# Disable Samba (SMB file sharing) if not needed
systemctl disable smbd
systemctl stop smbd

echo "Unused network services disabled." | tee -a /root/setup.log

# Install and configure ClamAV for antivirus protection
echo "Installing and configuring ClamAV..." | tee -a /root/setup.log
apt-get install -y clamav clamav-daemon
systemctl stop clamav-freshclam
freshclam
systemctl start clamav-freshclam
systemctl enable clamav-daemon
systemctl start clamav-daemon

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

# Restart rsyslog to apply logrotate configuration
systemctl restart rsyslog

echo "Security setup complete." | tee -a /root/setup.log

