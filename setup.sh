#!/bin/sh
set -eu
cd "$(dirname "$0")"

deb_version=$(dpkg-parsechangelog -S Version)
version=${deb_version#*:}
version=${version%-*}
src="/usr/src/imx585-$version"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
sed "s/#MODULE_VERSION#/$version/g" dkms.conf > "$work/dkms.conf"
dtc -Wno-interrupts_property -Wno-unit_address_vs_reg -@ -I dts -O dtb \
    -o "$work/imx585.dtbo" imx585-overlay.dts

status=$(sudo dkms status -m imx585 -v "$version")
if [ -n "$status" ]; then
    sudo dkms remove -m imx585 -v "$version" --all
fi
sudo install -d "$src"
sudo install -m 0644 imx585.c Makefile "$work/dkms.conf" "$src/"
sudo dkms install -m imx585 -v "$version"
sudo sh ./install-overlay.sh "$work/imx585.dtbo"
