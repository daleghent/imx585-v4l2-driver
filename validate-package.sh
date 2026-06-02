#!/bin/bash
#
# Validation script for the IMX585 DKMS Debian package
#

set -e

echo "IMX585 DKMS Package Validation"
echo "==============================="
echo ""

# Check if we're in the right directory
if [ ! -d "debian" ]; then
    echo "Error: debian/ directory not found"
    exit 1
fi

echo "✓ debian/ directory exists"

# Check for required files
REQUIRED_FILES=(
    "debian/control"
    "debian/rules"
    "debian/changelog"
    "debian/copyright"
    "debian/postinst"
    "debian/prerm"
    "debian/postrm"
    "debian/source/format"
    "debian/imx585-dkms.install"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file is missing"
        exit 1
    fi
done

# Check executable permissions
EXECUTABLE_FILES=(
    "debian/rules"
    "debian/postinst"
    "debian/prerm"
    "debian/postrm"
)

for file in "${EXECUTABLE_FILES[@]}"; do
    if [ -x "$file" ]; then
        echo "✓ $file is executable"
    else
        echo "✗ $file is not executable"
        exit 1
    fi
done

# Check source files exist
SOURCE_FILES=(
    "imx585.c"
    "Makefile"
    "dkms.conf"
    "dkms.postinst"
    "imx585-overlay.dts"
)

for file in "${SOURCE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ Source file $file exists"
    else
        echo "✗ Source file $file is missing"
        exit 1
    fi
done

# Validate debian/control format
if grep -q "^Source: imx585-dkms" debian/control && \
   grep -q "^Package: imx585-dkms" debian/control && \
   grep -q "^Depends:.*dkms" debian/control; then
    echo "✓ debian/control format is valid"
else
    echo "✗ debian/control format is invalid"
    exit 1
fi

# Ensure debian/compat doesn't exist (deprecated, use debhelper-compat in control)
if [ -f "debian/compat" ]; then
    echo "✗ debian/compat exists (deprecated - remove it, use debhelper-compat in debian/control)"
    exit 1
else
    echo "✓ debian/compat does not exist (correct - using debhelper-compat in control)"
fi

# Validate debian/changelog format
if head -n 1 debian/changelog | grep -q "^imx585-dkms"; then
    echo "✓ debian/changelog format is valid"
else
    echo "✗ debian/changelog format is invalid"
    exit 1
fi

# Check dkms.conf
if grep -q "^PACKAGE_NAME=imx585-dkms" dkms.conf && \
   grep -q "^BUILT_MODULE_NAME=imx585" dkms.conf; then
    echo "✓ dkms.conf is properly configured"
else
    echo "✗ dkms.conf format is invalid"
    exit 1
fi

# Validate debian/source/format has no trailing newline
if [ "$(tail -c 1 debian/source/format | wc -l)" -eq 0 ]; then
    echo "✓ debian/source/format has no trailing newline"
else
    echo "✗ debian/source/format has trailing newline (will cause build errors)"
    exit 1
fi

# Test dpkg-source format validation
if dpkg-source --before-build . >/dev/null 2>&1; then
    echo "✓ dpkg-source format validation passed"
else
    echo "✗ dpkg-source format validation failed"
    exit 1
fi

echo ""
echo "All validation checks passed!"
echo ""
echo "You can now build the package with:"
echo "  ./build-deb.sh"
echo "or:"
echo "  dpkg-buildpackage -us -uc -b"
