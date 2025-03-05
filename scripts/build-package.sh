#!/bin/bash
# Script to build a package from the custom repo using void-packages

set -e

# Function to show usage
show_usage() {
    echo "Usage: build-package PACKAGE_NAME [ARCH]"
    echo "Build a package from the custom repository"
    echo ""
    echo "Arguments:"
    echo "  PACKAGE_NAME  Name of the package to build (must exist in /custom-repo/srcpkgs)"
    echo "  ARCH          Optional: Architecture to build for (default: x86_64)"
    echo ""
    echo "Available packages:"
    find /custom-repo/srcpkgs -maxdepth 1 -type d | grep -v "^/custom-repo/srcpkgs$" | sort | xargs -n1 basename
}

# Check arguments
if [ -z "$1" ]; then
    show_usage
    exit 1
fi

PKG_NAME="$1"
ARCH="${2:-x86_64}"
VOID_PKG_DIR="/void-packages"
CUSTOM_PKG_DIR="/custom-repo"

# Check if package exists
if [ ! -d "${CUSTOM_PKG_DIR}/srcpkgs/${PKG_NAME}" ]; then
    echo "Error: Package ${PKG_NAME} not found in ${CUSTOM_PKG_DIR}/srcpkgs/"
    exit 1
fi

# Temporarily copy the package to void-packages
echo "==> Setting up build for ${PKG_NAME}"
rm -rf "${VOID_PKG_DIR}/srcpkgs/${PKG_NAME}"
cp -r "${CUSTOM_PKG_DIR}/srcpkgs/${PKG_NAME}" "${VOID_PKG_DIR}/srcpkgs/"

# Go to void-packages and build
cd "${VOID_PKG_DIR}"
echo "==> Building package: ${PKG_NAME} for ${ARCH}"

# Special case for hyprutils or packages with cross-compile issues
if [[ "${PKG_NAME}" == "hyprutils" ]] || grep -q "nocross=yes" "${VOID_PKG_DIR}/srcpkgs/${PKG_NAME}/template"; then
    echo "==> Detected package with cross-compilation issues, using native build"
    # Force native build by using -N flag
    ./xbps-src -N pkg ${PKG_NAME}
else
    # For kernel builds, enable ccache for faster rebuilds
    if [[ "${PKG_NAME}" == *"linux"* ]]; then
        echo "==> Kernel package detected: Enabling ccache"
        
        # Install ccache if not already installed
        if ! command -v ccache &> /dev/null; then
            sudo xbps-install -y ccache
        fi
        
        # Configure ccache
        export XBPS_CCACHEDIR="/void-packages/hostdir/ccache"
        mkdir -p "${XBPS_CCACHEDIR}"
        export CCACHE_DIR="${XBPS_CCACHEDIR}"
        
        # Enable ccache in xbps-src
        mkdir -p /void-packages/etc
        echo "XBPS_USE_CCACHE=yes" > /void-packages/etc/conf
        echo "XBPS_CCACHEDIR=${XBPS_CCACHEDIR}" >> /void-packages/etc/conf
    fi

    # Normal build with architecture specification
    ./xbps-src -a ${ARCH} pkg ${PKG_NAME}
fi

# Copy the built package back to the custom repo
echo "==> Copying built packages to ${CUSTOM_PKG_DIR}/binpkgs"
mkdir -p "${CUSTOM_PKG_DIR}/binpkgs"

# Handle different architectures correctly
if [[ "${ARCH}" == *"-musl"* ]]; then
    SRC_DIR="${VOID_PKG_DIR}/hostdir/binpkgs/${ARCH%-musl}-musl"
else
    SRC_DIR="${VOID_PKG_DIR}/hostdir/binpkgs/${ARCH}"
fi

if [ -d "${SRC_DIR}" ]; then
    cp -rvf ${SRC_DIR}/* "${CUSTOM_PKG_DIR}/binpkgs/"
else
    echo "Warning: No packages found in ${SRC_DIR}"
    # Fallback to non-specific directory
    cp -rvf ${VOID_PKG_DIR}/hostdir/binpkgs/*${PKG_NAME}* "${CUSTOM_PKG_DIR}/binpkgs/" 2>/dev/null || true
fi

echo "==> Build complete!"
echo "Packages available in: ${CUSTOM_PKG_DIR}/binpkgs"

# Clean up
rm -rf "${VOID_PKG_DIR}/srcpkgs/${PKG_NAME}"
