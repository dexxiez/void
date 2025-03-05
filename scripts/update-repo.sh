#!/bin/bash
# Script to update repository metadata for the custom repo

set -e

CUSTOM_PKG_DIR="/custom-repo"
ARCH="${1:-x86_64}"

echo "==> Updating repository metadata for architecture: ${ARCH}"

# Create architecture-specific directory if needed
mkdir -p "${CUSTOM_PKG_DIR}/binpkgs/${ARCH}-repodata"

# Find all .xbps packages for this architecture
PACKAGES=$(find "${CUSTOM_PKG_DIR}/binpkgs" -name "*${ARCH}.xbps" | sort)

if [ -z "${PACKAGES}" ]; then
    echo "Warning: No packages found for architecture ${ARCH}"
    exit 0
fi

echo "Found packages:"
echo "${PACKAGES}" | xargs -n1 basename

# Move architecture-specific packages to their directory
for pkg in ${PACKAGES}; do
    pkg_name=$(basename "$pkg")
    cp -vf "$pkg" "${CUSTOM_PKG_DIR}/binpkgs/${ARCH}-repodata/"
done

# Update repository index
cd "${CUSTOM_PKG_DIR}/binpkgs/${ARCH}-repodata"
xbps-rindex -a *.xbps

echo "==> Repository metadata updated!"
echo "You can now use this repository by adding it to your XBPS configuration:"
echo "    echo 'repository=/path/to/${CUSTOM_PKG_DIR}/binpkgs/${ARCH}-repodata' > /etc/xbps.d/10-custom-repo.conf"

# Sign packages if a key is available
if [ -f "${CUSTOM_PKG_DIR}/private.pem" ]; then
    echo "==> Signing packages with available private key"
    xbps-rindex --sign --signedby "Custom Repository" --privkey "${CUSTOM_PKG_DIR}/private.pem" .
    xbps-rindex --sign-pkg --privkey "${CUSTOM_PKG_DIR}/private.pem" *.xbps
fi
