#!/bin/bash

export XBPS_ALLOW_CHROOT_BREAKOUT=1

set -e

# Configuration
VOID_PACKAGES_DIR="$HOME/void-packages"  # Path to void-packages
REPO_DIR="$PWD/binpkgs"               # Output repository directory
HOSTDIR="$VOID_PACKAGES_DIR/hostdir"
PACKAGES=("t2linux6.13" "t2linux")       # All packages to build

# Make sure void-packages exists
if [ ! -d "$VOID_PACKAGES_DIR" ]; then
    echo "Error: void-packages directory not found at $VOID_PACKAGES_DIR"
    echo "Please clone it with: git clone https://github.com/void-linux/void-packages.git"
    exit 1
fi

echo "Creating symlinks for subpackages..."
cd "$VOID_PACKAGES_DIR/srcpkgs"
ln -sf t2linux6.13 t2linux6.13-headers
cd - > /dev/null

# Make sure the bootstrap has been run
if [ ! -d "$HOSTDIR/binpkgs" ]; then
    echo "Running bootstrap in void-packages..."
    (cd "$VOID_PACKAGES_DIR" && ./xbps-src binary-bootstrap)
fi

# Copy our package templates to void-packages
echo "Copying package templates to void-packages..."
for pkg in "${PACKAGES[@]}"; do
    echo "- Copying $pkg"
    mkdir -p "$VOID_PACKAGES_DIR/srcpkgs/$pkg"
    cp -r "srcpkgs/$pkg"/* "$VOID_PACKAGES_DIR/srcpkgs/$pkg/"
done

# Build each package
for pkg in "${PACKAGES[@]}"; do
    echo "Building package: $pkg"
    (cd "$VOID_PACKAGES_DIR" && ./xbps-src pkg "$pkg")
done

# Create repository directory
mkdir -p "$REPO_DIR"

# Copy all built packages to our repository
echo "Copying built packages to repository..."
for pkg in "${PACKAGES[@]}"; do
    cp -f "$HOSTDIR"/binpkgs/"$pkg"*.xbps "$REPO_DIR"/ 2>/dev/null || true
    cp -f "$HOSTDIR"/binpkgs/nonfree/"$pkg"*.xbps "$REPO_DIR"/ 2>/dev/null || true
done

# Generate repository data (without signatures)
echo "Generating repository index..."
xbps-rindex -a "$REPO_DIR"/*.xbps

echo "Repository created at $REPO_DIR"
