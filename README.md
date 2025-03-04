# T2Linux for Void Linux

This repository provides custom Linux kernel and support packages for Apple T2 machines running Void Linux.

## Packages Included

- **t2linux6.13**: Custom Linux kernel (6.13.4) with T2 machine support
- **t2linux**: Meta-package that installs all necessary T2 support packages

## Installation

### 1. Add this repository to your system:

```bash
# Create a new repository file 
echo 'repository=https://yourusername.github.io/t2linux-void/repository
repository-compression=zst
repository-signature=no' | sudo tee /etc/xbps.d/10-t2linux.conf

# Sync the new repository
sudo xbps-install -S
```

### 2. Install the meta-package:

```bash
# Install the meta-package (recommended)
sudo xbps-install -S t2linux

# Or install just the kernel if you prefer
sudo xbps-install -S t2linux6.13
```

### 3. Update your bootloader configuration and reboot

```bash
# Update GRUB config if you're using GRUB
sudo update-grub

# Reboot to use the new kernel
sudo reboot
```

## Adding Additional Packages

If you need additional packages for T2 support, you can:
1. Install them manually with `xbps-install`
2. Update the meta-package to include them as dependencies

## Building From Source

To build these packages yourself:

1. Clone this repository
2. Run the `build.sh` script
3. Install the resulting packages
