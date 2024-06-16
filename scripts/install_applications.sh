#!/bin/bash

# Ensure the script runs with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo." | tee -a /root/setup.log >&2
  exit 1
fi

echo "Starting manual application installation..." | tee -a /root/setup.log

# Install dependencies
echo "Installing dependencies..." | tee -a /root/setup.log
apt-get update | tee -a /root/setup.log
apt-get install -y wget gpg | tee -a /root/setup.log

# Install Signal Desktop
echo "Installing Signal Desktop..." | tee -a /root/setup.log
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | tee /etc/apt/sources.list.d/signal-xenial.list
apt-get update | tee -a /root/setup.log
apt-get install -y signal-desktop | tee -a /root/setup.log

# Install Obsidian
echo "Installing Obsidian..." | tee -a /root/setup.log
wget -O /tmp/obsidian.deb https://github.com/obsidianmd/obsidian-releases/releases/download/v1.6.3/obsidian_1.6.3_amd64.deb
dpkg -i /tmp/obsidian.deb | tee -a /root/setup.log
apt-get -f install -y | tee -a /root/setup.log

# Install ProtonVPN
echo "Installing ProtonVPN..." | tee -a /root/setup.log
wget -q -O /tmp/protonvpn.deb https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-1_all.deb
dpkg -i /tmp/protonvpn.deb | tee -a /root/setup.log
apt-get update | tee -a /root/setup.log
apt-get install -y protonvpn | tee -a /root/setup.log

# Install Firefox
echo "Installing Firefox..." | tee -a /root/setup.log
add-apt-repository -y ppa:mozillateam/ppa | tee -a /root/setup.log
apt-get update | tee -a /root/setup.log
apt-get install -y firefox | tee -a /root/setup.log

# Install NVIDIA driver 570
echo "Installing NVIDIA driver 570..." | tee -a /root/setup.log
apt-get install -y nvidia-driver-570 | tee -a /root/setup.log

# Install GitHub Desktop
echo "Installing GitHub Desktop..." | tee -a /root/setup.log
wget -O /tmp/github-desktop.deb https://github.com/shiftkey/desktop/releases/download/release-2.9.9-linux1/GitHubDesktop-linux-2.9.9-linux1.deb
dpkg -i /tmp/github-desktop.deb | tee -a /root/setup.log
apt-get -f install -y | tee -a /root/setup.log

echo "Manual application installation complete." | tee -a /root/setup.log

# Cleanup downloaded .deb files
rm -f /tmp/obsidian.deb /tmp/protonvpn.deb /tmp/github-desktop.deb

echo "Cleanup complete." | tee -a /root/setup.log

# Pin applications to the dash
echo "Pinning applications to the dash..." | tee -a /root/setup.log
dconf write /org/gnome/shell/favorite-apps "['firefox_firefox.desktop', 'signal-desktop.desktop', 'obsidian.desktop', 'protonvpn.desktop', 'github-desktop.desktop']"

# Switch to dark mode
echo "Switching system to dark mode..." | tee -a /root/setup.log
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "Applications pinned and dark mode enabled." | tee -a /root/setup.log

