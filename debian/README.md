# Releasing imx585-dkms

Set each release version in the newest entry in `debian/changelog`. The Debian
package uses the full version. DKMS and its `/usr/src/imx585-<upstream>/`
directory use the upstream part, excluding the epoch and Debian revision.
The standalone installer reads the same changelog.

From the repository root, use `dch` (provided by `devscripts`) or edit the
changelog directly. For example, to start a new driver release:

```sh
dch --newversion 1.1.0-1 "Describe the driver changes."
```

For a packaging-only change, use `dch --increment` and describe the change.
When the entry is ready, use `dch --release` to finalize it.

## Build and install

Install the build tools and build the architecture-independent binary package:

```sh
sudo apt install build-essential debhelper dh-dkms device-tree-compiler
./build-deb.sh
```

The script runs `dpkg-buildpackage -us -uc -b`, checks the archive against the
changelog and prints the exact install command. The build machine can package
the driver without Raspberry Pi hardware or kernel headers. Install matching
kernel headers on the target Pi so DKMS can build the module.

To repeat the checks for an existing archive from the same checkout:

```sh
version=$(dpkg-parsechangelog -S Version)
deb="../imx585-dkms_${version#*:}_all.deb"
./validate-package.sh "$deb"
sudo apt install "$deb"
dkms status -m imx585
```

Binary builds work directly from the checkout. A full `3.0 (quilt)` source
build also needs the matching `imx585-dkms_<upstream>.orig.tar.*` in the
parent directory. Create that archive from the upstream release sources and
reuse it across Debian revisions of that release.

## Installed files

DKMS registers the source under `/usr/src/imx585-<upstream>/`, builds the
module for eligible kernels with headers, and rebuilds it on kernel upgrades.
The package installs the modules-load configuration under
`/etc/modules-load.d/` and copies the compiled overlay to
`/boot/firmware/overlays/imx585.dtbo` on current Raspberry Pi OS or
`/boot/overlays/imx585.dtbo` on older systems. Enable it in the Pi's boot
configuration as described in the [driver README](../README.md).

Use `sudo apt remove imx585-dkms` to unregister the module and remove the
overlay. Use `sudo apt purge imx585-dkms` to also remove the configuration.
