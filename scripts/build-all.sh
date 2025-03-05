#!/bin/bash
# Script to build all packages in the custom repository

set -e

CUSTOM_PKG_DIR="/custom-repo"
ARCH="${1:-x86_64}"

echo "==> Building all packages for architecture: ${ARCH}"

# Find all packages in the custom repository
PACKAGES=$(find "${CUSTOM_PKG_DIR}/srcpkgs" -maxdepth 1 -type d | grep -v "^${CUSTOM_PKG_DIR}/srcpkgs$" | sort)

if [ -z "${PACKAGES}" ]; then
    echo "Error: No packages found in ${CUSTOM_PKG_DIR}/srcpkgs/"
    exit 1
fi

echo "Packages to build:"
echo "${PACKAGES}" | xargs -n1 basename

# Build each package
for pkg_dir in ${PACKAGES}; do
    pkg_name=$(basename "$pkg_dir")
    echo "======================================================"
    echo "Building package: ${pkg_name}"
    echo "======================================================"
    build-package "${pkg_name}" "${ARCH}" || {
        echo "Error building ${pkg_name}. Continuing with next package..."
    }
done

# Update repository metadata
update-repo "${ARCH}"

echo "==> All packages built and repository updated!"
