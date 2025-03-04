#!/bin/bash
# checksum-kernel.sh - Calculate checksums for a kernel version
# Usage: ./checksum-kernel.sh [kernel_version]
# Example: ./checksum-kernel.sh 6.13.5

set -e

TEMP_DIR="/tmp/kernel-checksums"
KERNEL_SITE="https://cdn.kernel.org/pub/linux/kernel"

# Get kernel version from command line or prompt for it
if [ -z "$1" ]; then
    read -p "Enter kernel version (e.g., 6.13.4): " VERSION
else
    VERSION="$1"
fi

# Extract major, minor, and patch versions
MAJOR_VERSION="${VERSION%%.*}"
MINOR_VERSION="${VERSION#*.}"
MINOR_VERSION="${MINOR_VERSION%%.*}"
PATCH_VERSION="${VERSION##*.}"
BASE_VERSION="$MAJOR_VERSION.$MINOR_VERSION"

echo "Calculating checksums for Linux kernel version $VERSION"

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download the main kernel tarball
KERNEL_URL="$KERNEL_SITE/v$MAJOR_VERSION.x/linux-$BASE_VERSION.tar.xz"
echo "Downloading kernel tarball from $KERNEL_URL"
curl -O "$KERNEL_URL"

# If patch version is not 0, also download the patch
if [ "$PATCH_VERSION" != "0" ]; then
    PATCH_URL="$KERNEL_SITE/v$MAJOR_VERSION.x/patch-$VERSION.xz"
    echo "Downloading kernel patch from $PATCH_URL"
    curl -O "$PATCH_URL"
fi

# Calculate checksums
echo "Calculating checksums..."
KERNEL_CHECKSUM=$(sha256sum "linux-$BASE_VERSION.tar.xz" | awk '{print $1}')

if [ "$PATCH_VERSION" != "0" ]; then
    PATCH_CHECKSUM=$(sha256sum "patch-$VERSION.xz" | awk '{print $1}')
    CHECKSUM_STRING="checksum=\"$KERNEL_CHECKSUM\n $PATCH_CHECKSUM\""
else
    CHECKSUM_STRING="checksum=\"$KERNEL_CHECKSUM\""
fi

# Output results
echo "===== Checksums for Linux Kernel $VERSION ====="
echo -e "$CHECKSUM_STRING"
echo "=============================================="

# Update template suggestion
echo "To update your template:"
echo "1. Change version=$VERSION in template"
echo "2. Replace the checksum line with:"
echo -e "$CHECKSUM_STRING"

# Clean up
echo "Cleaning up temporary files..."
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo "Done!"
