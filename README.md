# Secure Ubuntu Autoinstallation

## Purpose
This project aims to provide a secure and automated installation of Ubuntu on a specified disk (typically a USB drive) using a cloud-config YAML file. The configuration includes disk partitioning, package installations, network settings, and other security enhancements to create a secure Ubuntu environment.

## Instructions

### Prerequisites
- An Ubuntu installation ISO.
- A USB drive with at least 64GB of space for the installation target.
- Ensure the USB drive is prepared with the necessary `user-data.yaml` and `meta-data.yaml` files.

### Using a GitHub Repository for Autoinstall Configuration

#### Using a Personal Access Token (PAT)

1. **Create a Personal Access Token:**
   - Generate a token from your GitHub account settings with the `repo` scope.

2. **Set Up the Boot Parameters:**
   - Boot from the Ubuntu installation USB drive.
   - When the GRUB menu appears, press `e` to edit the boot parameters.
   - Find the line that starts with `linux`.
   - Append the following parameter:

     ```bash
     autoinstall ds=nocloud-net;s=https://DF-dev-rep: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@raw.githubusercontent.com/DF-dev-rep/Autoinstall-Secure-Ubuntu/main/autoinstall/
     ```

   - Press `Ctrl+X` to boot with the modified parameters and start the installation.

### Using Local Files on the Installation USB

1. **Prepare the USB Drive:**
   - Copy the `user-data.yaml` and `meta-data.yaml` files to an `autoinstall` directory in the root of the Ubuntu installation USB drive.

2. **Set Up the Boot Parameters:**
   - Boot from the Ubuntu installation USB drive.
   - When the GRUB menu appears, press `e` to edit the boot parameters.
   - Find the line that starts with `linux`.
   - Append the following parameter to use the local `autoinstall` directory:

     ```bash
     autoinstall ds=nocloud-net;s=file:///cdrom/autoinstall/
     ```

   - Press `Ctrl+X` to boot with the modified parameters and start the installation.

### Verifying Disk Selection
Before proceeding with the installation, ensure you have identified the correct target disk to avoid data loss. Use the `lsblk` command to list the available disks and partitions. Update the `user-data.yaml` file to reflect the correct disk path (e.g., `/dev/sda`).

### Notes
- This configuration will format the specified disk and create partitions as defined in the `user-data.yaml` file. Ensure that the target disk is correct to prevent accidental data loss.
- The installation includes several security and privacy tools. Review the package list in the `user-data.yaml` file and modify it according to your needs.
- If you encounter any issues, refer to the Ubuntu autoinstall documentation and the cloud-init documentation for further details and troubleshooting tips.
