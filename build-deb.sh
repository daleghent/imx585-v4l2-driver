#!/bin/sh
set -eu
cd "$(dirname "$0")"

if ! dpkg-checkbuilddeps; then
    echo "Install the declared build dependencies with: sudo apt-get build-dep ." >&2
    [ -t 0 ] || exit 1
    printf 'Install them now? [y/N] ' >&2
    read -r answer
    case "$answer" in
        y|Y|yes|YES) sudo apt-get build-dep . ;;
        *) exit 1 ;;
    esac
fi

dpkg-buildpackage -us -uc -b
version=$(dpkg-parsechangelog -S Version)
deb="../imx585-dkms_${version#*:}_all.deb"
./validate-package.sh "$deb"
printf '\nInstall with: sudo apt install %s\n' "$deb"
