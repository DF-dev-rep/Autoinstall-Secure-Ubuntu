#!/bin/bash

# Ensure the script runs with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo." | tee -a /root/setup.log >&2
  exit 1
fi

# Determine the non-root user
USER_HOME=$(eval echo ~${SUDO_USER})
DESKTOP_DIR="$USER_HOME/Desktop"

# Create Desktop directory if it doesn't exist
mkdir -p "$DESKTOP_DIR"

echo "Starting VPN configuration..." | tee -a /root/setup.log

# Install ProtonVPN
echo "Installing ProtonVPN..." | tee -a /root/setup.log
wget -q https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb -O /tmp/protonvpn-stable-release_1.0.3-3_all.deb
dpkg -i /tmp/protonvpn-stable-release_1.0.3-3_all.deb && apt update
apt install -y proton-vpn-gnome-desktop | tee -a /root/setup.log

# Install Mullvad VPN
echo "Installing Mullvad VPN..." | tee -a /root/setup.log
curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/mullvad.list
apt update
apt install -y mullvad-vpn | tee -a /root/setup.log

# Install NordVPN
echo "Installing NordVPN..." | tee -a /root/setup.log
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh) | tee -a /root/setup.log

# Cleanup downloaded files
rm -f /tmp/protonvpn-stable-release_1.0.3-3_all.deb

# Create desktop shortcuts
echo "Creating desktop shortcuts..." | tee -a /root/setup.log

# ProtonVPN Desktop Shortcut
cat <<EOF > "$DESKTOP_DIR/protonvpn.desktop"
[Desktop Entry]
Name=ProtonVPN
Comment=Secure Internet Connection
Exec=protonvpn
Icon=protonvpn
Terminal=false
Type=Application
EOF

# Mullvad VPN Desktop Shortcut
cat <<EOF > "$DESKTOP_DIR/mullvad-vpn.desktop"
[Desktop Entry]
Name=Mullvad VPN
Comment=Secure Internet Connection
Exec=mullvad-vpn
Icon=mullvad
Terminal=false
Type=Application
EOF

# NordVPN Desktop Shortcut
cat <<EOF > "$DESKTOP_DIR/nordvpn.desktop"
[Desktop Entry]
Name=NordVPN
Comment=Secure Internet Connection
Exec=nordvpn
Icon=nordvpn
Terminal=false
Type=Application
EOF

# Set permissions for desktop shortcuts
chmod +x "$DESKTOP_DIR/protonvpn.desktop"
chmod +x "$DESKTOP_DIR/mullvad-vpn.desktop"
chmod +x "$DESKTOP_DIR/nordvpn.desktop"
chown $SUDO_USER:$SUDO_USER "$DESKTOP_DIR"/*.desktop

echo "VPN configuration complete." | tee -a /root/setup.log

