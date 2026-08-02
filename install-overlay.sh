#!/bin/sh
set -eu

overlays=/boot/overlays
if [ -d /boot/firmware/overlays ]; then
    overlays=/boot/firmware/overlays
fi
install -D -m 0644 "$1" "$overlays/imx585.dtbo"
