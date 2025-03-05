#!/bin/bash
# Script to calculate checksums for Void Linux package templates
# Usage: ./update-checksum.sh [template_file] [version] [download_only]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./update-checksum.sh [template_file] [version] [download_only]"
    echo ""
    echo -e "${BLUE}Arguments:${NC}"
    echo "  template_file  - Path to the template file (default: searches current directory)"
    echo "  version        - Version to verify/update (default: extracted from template)"
    echo "  download_only  - Set to 'true' to skip checksum update (default: false)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./update-checksum.sh ./srcpkgs/hyprutils/template"
    echo "  ./update-checksum.sh ./template 0.5.2"
}

# Function to extract value from template
extract_value() {
    local template="$1"
    local variable="$2"
    grep "^${variable}=" "$template" | cut -d= -f2- | tr -d '"' | tr -d "'"
}

# Function to update checksum in template
update_checksum() {
    local template="$1"
    local new_checksum="$2"
    
    # Create a backup
    cp "$template" "${template}.bak"
    
    # Update the checksum
    sed -i "s/^checksum=.*/checksum=$new_checksum/" "$template"
    
    echo -e "${GREEN}Updated checksum in $template${NC}"
    echo -e "${YELLOW}Backup saved as ${template}.bak${NC}"
}

# Find template file if not specified
if [ -z "$1" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_usage
    exit 0
fi

TEMPLATE_FILE="$1"
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Extract package information
PKGNAME=$(extract_value "$TEMPLATE_FILE" "pkgname")
VERSION="${2:-$(extract_value "$TEMPLATE_FILE" "version")}"
HOMEPAGE=$(extract_value "$TEMPLATE_FILE" "homepage")
DISTFILES=$(extract_value "$TEMPLATE_FILE" "distfiles")
CURRENT_CHECKSUM=$(extract_value "$TEMPLATE_FILE" "checksum")
DOWNLOAD_ONLY="${3:-false}"

# Replace placeholders in distfiles
DISTFILES=$(echo "$DISTFILES" | sed "s/\${version}/$VERSION/g")
DISTFILES=$(echo "$DISTFILES" | sed "s|\${homepage}|$HOMEPAGE|g")

echo -e "${BLUE}Package:${NC} $PKGNAME"
echo -e "${BLUE}Version:${NC} $VERSION"
echo -e "${BLUE}Source:${NC} $DISTFILES"
echo -e "${BLUE}Current checksum:${NC} $CURRENT_CHECKSUM"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Download the file
echo -e "${YELLOW}Downloading source...${NC}"
FILENAME=$(basename "$DISTFILES")
curl -L "$DISTFILES" -o "$TEMP_DIR/$FILENAME"

if [ ! -f "$TEMP_DIR/$FILENAME" ]; then
    echo -e "${RED}Failed to download: $DISTFILES${NC}"
    exit 1
fi

# Calculate SHA256 checksum
echo -e "${YELLOW}Calculating checksum...${NC}"
NEW_CHECKSUM=$(sha256sum "$TEMP_DIR/$FILENAME" | awk '{print $1}')

echo -e "${BLUE}New checksum:${NC} $NEW_CHECKSUM"

# Compare checksums
if [ "$CURRENT_CHECKSUM" == "$NEW_CHECKSUM" ]; then
    echo -e "${GREEN}Checksums match! No update needed.${NC}"
else
    echo -e "${YELLOW}Checksums differ!${NC}"
    
    if [ "$DOWNLOAD_ONLY" != "true" ]; then
        # Ask for confirmation before updating
        read -p "Update the checksum in the template? (y/n): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            update_checksum "$TEMPLATE_FILE" "$NEW_CHECKSUM"
        else
            echo -e "${YELLOW}Template not updated. New checksum is: $NEW_CHECKSUM${NC}"
        fi
    else
        echo -e "${YELLOW}Download-only mode. Template not updated. New checksum is: $NEW_CHECKSUM${NC}"
    fi
fi

# Optional: Optionally print the command to manually update
echo -e "${BLUE}To manually update the template:${NC}"
echo "sed -i \"s/^checksum=.*/checksum=$NEW_CHECKSUM/\" \"$TEMPLATE_FILE\""

# Clean up temporary files (handled by trap)
echo -e "${GREEN}Done!${NC}"
