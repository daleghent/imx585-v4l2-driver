# Building the Debian Package

This directory contains the Debian packaging files for the IMX585 DKMS driver.

## Prerequisites

Install the required build tools:

```bash
sudo apt install debhelper dkms device-tree-compiler build-essential
```

## Building the Package

From the root of the repository, run:

```bash
dpkg-buildpackage -us -uc -b
```

This will create a `.deb` file in the parent directory.

## Installing the Package

Install the generated package:

```bash
sudo dpkg -i ../imx585-dkms_0.0.1-1_all.deb
```

If there are dependency issues, run:

```bash
sudo apt-get install -f
```

## What the Package Does

When installed, the package will:

1. Copy the driver source files to `/usr/src/imx585-0.0.1/`
2. Register the module with DKMS
3. Build the kernel module for all installed kernels
4. Install the compiled module
5. Compile and install the device tree overlay to `/boot/overlays/imx585.dtbo`

When the kernel is upgraded, DKMS will automatically rebuild and reinstall the module for the new kernel.

## Uninstalling

To remove the package:

```bash
sudo apt remove imx585-dkms
```

To completely purge the package including configuration:

```bash
sudo apt purge imx585-dkms
```

## Configuration

After installing the package, you still need to configure `/boot/config.txt` as described in the main README:

```
camera_auto_detect=0
dtoverlay=imx585
```

Then reboot for the changes to take effect.
