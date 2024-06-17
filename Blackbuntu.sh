#!/bin/bash

# Source utility scripts using relative paths
source "$(dirname "$0")/utils/logging.sh"
source "$(dirname "$0")/utils/download.sh"
source "$(dirname "$0")/utils/validate.sh"

# Validate that the script is running with root privileges
validate_root

# Ensure necessary tools are installed
apt-get update && apt-get install -y zenity wget x11-utils xdotool

# Log file
LOGFILE="/root/setup.log"
exec > >(tee -a ${LOGFILE}) 2>&1

# GitHub repository URL where the scripts are stored
REPO_URL="https://raw.githubusercontent.com/DF-dev-rep/Autoinstall-Secure-Ubuntu/main/scripts"

# Create desktop shortcut for Blackbuntu.sh at the beginning
cat <<EOF > /home/$USER/Desktop/Blackbuntu.desktop
[Desktop Entry]
Name=Blackbuntu
Comment=Run all setup scripts
Exec=/root/Blackbuntu.sh
Icon=utilities-terminal
Terminal=true
Type=Application
EOF

# Set permissions for the desktop shortcut
chmod +x /home/$USER/Desktop/Blackbuntu.desktop

# Log that the desktop shortcut was created
log_info "Desktop shortcut for Blackbuntu.sh created."

# Function to display Zenity checklist and center it on the screen
display_zenity_checklist() {
  WIDTH=800  # Set the width in pixels
  HEIGHT=600 # Set the height in pixels
  SELECTION=$(zenity --list --checklist \
    --width=$WIDTH \
    --height=$HEIGHT \
    --title="Select Installation Packages" \
    --text="Choose the packages you want to install:" \
    --column="Select" --column="Script" --column="Description" \
    FALSE "setup_security.sh" "Setup security configurations" \
    FALSE "configure_network.sh" "Configure network settings" \
    FALSE "install_applications.sh" "Install applications" \
    FALSE "setup_display.sh" "Setup display settings" \
    FALSE "install_drivers_updates.sh" "Install drivers and updates" \
    FALSE "vpn_setup.sh" "Configure VPNs" \
    --separator=":")

  # Center the Zenity window
  zenity_window_id=$(xdotool search --onlyvisible --class zenity | head -n 1)
  screen_width=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)
  screen_height=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f2)
  window_x=$(( (screen_width - WIDTH) / 2 ))
  window_y=$(( (screen_height - HEIGHT) / 2 ))
  xdotool windowmove $zenity_window_id $window_x $window_y
}

# Display the Zenity checklist
display_zenity_checklist

# Convert selection to an array
IFS=':' read -r -a SCRIPTS <<< "$SELECTION"

# Function to run a script
run_script() {
    local script_name="$1"
    local script_path="/root/$script_name"
    log_info "Running $script_name..."

    bash "$script_path"
    local status=$?

    if [ $status -ne 0 ]; then
        log_error "$script_name exited with an error."
        return 1
    fi

    log_info "$script_name completed successfully."
    return 0
}

# Function to clean up downloaded script
cleanup_script() {
    local script_name="$1"
    if [ -f "/root/$script_name" ]; then
        rm "/root/$script_name"
    else
        log_info "/root/$script_name does not exist. No need to remove."
    fi
}

# Download and run each selected script sequentially
for script in "${SCRIPTS[@]}"; do
    download_script "$script" "$REPO_URL"
    if [ $? -ne 0 ]; then
        log_error "Failed to download $script. Skipping."
        continue
    fi

    run_script "$script"
    if [ $? -ne 0 ]; then
        log_error "Error occurred during execution of $script. Cleaning up and moving to next script."
        cleanup_script "$script"
        continue
    fi

    cleanup_script "$script"
done

# Additional cleanup for specific files like the ProtonVPN .deb file
cleanup_files() {
    local files=(
        "/root/protonvpn-stable-release_1.0.3-3_all.deb"
        "/root/Blackbuntu.sh"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            rm "$file"
        else
            log_info "$file does not exist. No need to remove."
        fi
    done
}

# Final cleanup
log_info "Cleaning up additional files..."
cleanup_files

log_info "Setup complete."

