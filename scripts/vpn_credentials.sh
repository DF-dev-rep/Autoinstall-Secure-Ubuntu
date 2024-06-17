#!/bin/bash

# Ensure the script runs with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo." | tee -a /root/setup.log >&2
  exit 1
fi

echo "Starting VPN installation and desktop icon setup..." | tee -a /root/setup.log

# Install ProtonVPN
echo "Installing ProtonVPN..." | tee -a /root/setup.log
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb
sudo dpkg -i ./protonvpn-stable-release_1.0.3-3_all.deb && sudo apt update
sudo apt install -y protonvpn-gnome-desktop

# Install Mullvad VPN
echo "Installing Mullvad VPN..." | tee -a /root/setup.log
sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mullvad.list
sudo apt update
sudo apt install -y mullvad-vpn

# Install NordVPN
echo "Installing NordVPN..." | tee -a /root/setup.log
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)

# Create desktop shortcuts
echo "Creating desktop shortcuts..." | tee -a /root/setup.log

# ProtonVPN desktop icon
cat <<EOF > /home/$USER/Desktop/protonvpn.desktop
[Desktop Entry]
Name=ProtonVPN
Comment=Launch ProtonVPN
Exec=protonvpn
Icon=protonvpn
Terminal=false
Type=Application
EOF

# Mullvad VPN desktop icon
cat <<EOF > /home/$USER/Desktop/mullvad-vpn.desktop
[Desktop Entry]
Name=Mullvad VPN
Comment=Launch Mullvad VPN
Exec=mullvad-vpn
Icon=mullvad
Terminal=false
Type=Application
EOF

# NordVPN desktop icon
cat <<EOF > /home/$USER/Desktop/nordvpn.desktop
[Desktop Entry]
Name=NordVPN
Comment=Launch NordVPN
Exec=nordvpn
Icon=nordvpn
Terminal=false
Type=Application
EOF

# Set permissions for the desktop icons
echo "Setting permissions for desktop icons..." | tee -a /root/setup.log
chmod +x /home/$USER/Desktop/protonvpn.desktop
chmod +x /home/$USER/Desktop/mullvad-vpn.desktop
chmod +x /home/$USER/Desktop/nordvpn.desktop

# Allow launching of desktop shortcuts
gio set /home/$USER/Desktop/protonvpn.desktop metadata::trusted true
gio set /home/$USER/Desktop/mullvad-vpn.desktop metadata::trusted true
gio set /home/$USER/Desktop/nordvpn.desktop metadata::trusted true

# Refresh the desktop to show the new icons
xdg-desktop-menu forceupdate

echo "[INFO] VPN installation and desktop icon setup complete."

