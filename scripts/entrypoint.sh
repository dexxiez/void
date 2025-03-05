#!/bin/bash
# Entrypoint script to handle initialization with cache

set -e

echo "==> Initializing Void Linux build environment"

# Check if we need to initialize the build environment
if [ ! -f "/void-packages/hostdir/.cache_initialized" ]; then
    echo "==> First run: Initializing void-packages bootstrap"
    cd /void-packages
    ./xbps-src binary-bootstrap
    
    # Mark cache as initialized
    touch /void-packages/hostdir/.cache_initialized
    echo "==> Initialization complete"
else
    echo "==> Using cached build environment"
    
    # Make sure masterdir links to hostdir correctly
    cd /void-packages
    if [ ! -d "/void-packages/masterdir" ]; then
        # Recreate basic structure if needed
        ./xbps-src binary-bootstrap
    fi
fi

# Ensure permissions are correct on the cache directory
sudo chown -R builder:builder /void-packages/hostdir

echo "==> Environment ready!"
exec "$@"
