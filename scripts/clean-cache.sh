#!/bin/bash
# Script to clean build cache when needed

set -e

show_usage() {
    echo "Usage: clean-cache [OPTIONS]"
    echo "Clean build cache for void-packages builds"
    echo ""
    echo "Options:"
    echo "  all           Clean entire build cache (warning: will remove all cached builds)"
    echo "  ccache        Clean only the compiler cache"
    echo "  PACKAGE_NAME  Clean cache for a specific package"
}

if [ -z "$1" ]; then
    show_usage
    exit 1
fi

CACHE_TYPE="$1"
VOID_PKG_DIR="/void-packages"

case ${CACHE_TYPE} in
    "all")
        echo "==> Cleaning entire build cache"
        # Keep basic bootstrap files, but remove all builds
        rm -rf ${VOID_PKG_DIR}/hostdir/binpkgs/*
        rm -rf ${VOID_PKG_DIR}/hostdir/destdir/*
        rm -rf ${VOID_PKG_DIR}/hostdir/sources/*
        rm -rf ${VOID_PKG_DIR}/hostdir/ccache/*
        echo "==> Build cache cleaned"
        ;;
        
    "ccache")
        echo "==> Cleaning compiler cache"
        rm -rf ${VOID_PKG_DIR}/hostdir/ccache/*
        echo "==> Compiler cache cleaned"
        ;;
        
    *)
        # Assume it's a package name
        echo "==> Cleaning cache for package: ${CACHE_TYPE}"
        rm -rf ${VOID_PKG_DIR}/hostdir/binpkgs/*${CACHE_TYPE}*
        rm -rf ${VOID_PKG_DIR}/hostdir/destdir/${CACHE_TYPE}-*
        rm -rf ${VOID_PKG_DIR}/hostdir/sources/${CACHE_TYPE}-*
        echo "==> Package cache cleaned"
        ;;
esac

# Make sure permissions are correct
sudo chown -R builder:builder ${VOID_PKG_DIR}/hostdir

echo "==> Cache cleaning complete"
