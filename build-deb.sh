#!/bin/bash
#
# Script to build the IMX585 DKMS Debian package
#

set -e

echo "IMX585 DKMS Debian Package Builder"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -f "imx585.c" ] || [ ! -d "debian" ]; then
    echo "Error: This script must be run from the root of the imx585-v4l2-driver repository"
    exit 1
fi

# Check for required build dependencies
echo "Checking build dependencies..."
MISSING_DEPS=()

for pkg in debhelper dkms device-tree-compiler build-essential; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        MISSING_DEPS+=($pkg)
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    echo "Missing build dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install them with:"
    echo "  sudo apt install ${MISSING_DEPS[*]}"
    echo ""
    read -p "Do you want to install them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt install -y ${MISSING_DEPS[*]}
    else
        echo "Cannot build without required dependencies. Exiting."
        exit 1
    fi
fi

echo ""
echo "Building Debian package..."
echo ""

# Build the package
dpkg-buildpackage -us -uc -b

echo ""
echo "Build completed successfully!"
echo ""
echo "The package file is located at: ../imx585-dkms_0.0.1-1_all.deb"
echo ""
echo "To install it, run:"
echo "  sudo dpkg -i ../imx585-dkms_0.0.1-1_all.deb"
echo "  sudo apt-get install -f"
echo ""
