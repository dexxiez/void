#!/bin/bash
# Script to set up and build packages inside the Void Linux container

# Switch to repo-ci mirror for faster downloads
mkdir -p /etc/xbps.d && cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
sed -i 's|repo-default|repo-ci|g' /etc/xbps.d/*-repository-*.conf

# Install dependencies
xbps-install -Syu xbps && xbps-install -yu && xbps-install -y sudo bash curl git xtools 

# Create non-root user for building
if ! id builder &>/dev/null; then
  useradd -G xbuilder -m builder
fi

# Set up build environment
cd /build
chown -R builder:builder .

# Determine which package to build
if [ -z "$1" ]; then
  echo "Usage: $0 <package_name>"
  echo "Available packages:"
  find ./srcpkgs -maxdepth 1 -type d | grep -v "^./srcpkgs$" | sort | xargs -n1 basename
  exit 1
fi

PKG_NAME="$1"
if [ ! -d "./srcpkgs/$PKG_NAME" ]; then
  echo "Error: Package $PKG_NAME not found in srcpkgs directory"
  exit 1
fi

# Build the package
echo "Building package: $PKG_NAME"
cd /build
sudo -Eu builder xbps-src -m masterdir pkg "$PKG_NAME"

# Copy built packages to output directory
mkdir -p /build/binpkgs
cp -rvf /build/masterdir/hostdir/binpkgs/* /build/binpkgs/

# Generate repository data
cd /build/binpkgs
xbps-rindex -a *.xbps

echo "Build complete! Packages are in the binpkgs directory"
