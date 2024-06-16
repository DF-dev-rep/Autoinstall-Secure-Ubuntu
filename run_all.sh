#!/bin/bash

# Source utility scripts using relative paths
source "$(dirname "$0")/utils/logging.sh"
source "$(dirname "$0")/utils/download.sh"
source "$(dirname "$0")/utils/validate.sh"

# Validate that the script is running with root privileges
validate_root

# Ensure Zenity and wget are installed
apt-get update && apt-get install -y zenity wget

# Log file
LOGFILE="/root/setup.log"
exec > >(tee -a ${LOGFILE}) 2>&1

# GitHub repository URL where the scripts are stored
REPO_URL="https://DF-dev-rep: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@raw.githubusercontent.com/DF-dev-rep/Autoinstall-Secure-Ubuntu/main/scripts"

# Display Zenity checklist for user to select scripts to run
SELECTION=$(zenity --list --checklist \
  --title="Select Installation Packages" \
  --text="Choose the packages you want to install:" \
  --column="Select" --column="Script" --column="Description" \
  FALSE "setup_security.sh" "Setup security configurations" \
  FALSE "configure_network.sh" "Configure network settings" \
  FALSE "install_applications.sh" "Install applications" \
  FALSE "setup_display.sh" "Setup display settings" \
  FALSE "install_drivers_updates.sh" "Install drivers and updates" \
  FALSE "vpn_credentials.sh" "Configure VPN credentials" \
  --separator=":")

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
    rm "/root/$script_name"
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

# Final cleanup
log_info "Cleaning up..."
rm /etc/systemd/system/first-boot-delayed.service || true
rm /root/run_all.sh || true

log_info "Setup complete."

