#!/bin/sh
set -eu

# With no argument, validate the source packaging before a build.
if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [package.deb]" >&2
    exit 2
fi
for file in imx585.c Makefile dkms.conf imx585-overlay.dts imx585.conf install-overlay.sh \
            debian/control debian/rules debian/imx585-dkms.install; do
    [ -s "$file" ] || { echo "Missing source file: $file" >&2; exit 1; }
done

version=$(dpkg-parsechangelog -S Version)
dpkg --validate-version "$version"
dpkg-source --before-build .
if [ "$#" -eq 0 ]; then
    echo "Source package imx585-dkms $version is ready to build."
    exit 0
fi

deb=$1
fail() { echo "$deb: $*" >&2; exit 1; }
[ "$(dpkg-deb -f "$deb" Package)" = imx585-dkms ] || fail "unexpected package name"
[ "$(dpkg-deb -f "$deb" Version)" = "$version" ] || fail "version differs from debian/changelog"
[ "$(dpkg-deb -f "$deb" Architecture)" = all ] || fail "expected Architecture: all"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dpkg-deb -x "$deb" "$work"
upstream=${version#*:}
upstream=${upstream%-*}
src="$work/usr/src/imx585-$upstream"
for file in imx585.c Makefile dkms.conf; do
    [ -f "$src/$file" ] || fail "missing $file from the DKMS source directory"
    [ ! -e "$work/$file" ] || fail "$file installed at filesystem root"
done
grep -Fxq 'PACKAGE_NAME="imx585"' "$src/dkms.conf" || fail "incorrect DKMS module name"
grep -Fxq "PACKAGE_VERSION=\"$upstream\"" "$src/dkms.conf" || fail "incorrect DKMS module version"
for file in etc/modules-load.d/imx585.conf usr/share/imx585-dkms/imx585.dtbo; do
    [ -s "$work/$file" ] || fail "missing $file"
done
echo "Validated $deb"
