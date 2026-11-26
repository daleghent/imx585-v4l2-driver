# Kernel Driver for IMX585

This guide provides detailed instructions on how to install the IMX585 kernel driver on a Linux system, specifically Raspbian.

## Special Thanks

Special thanks to Soho-enterprise for the additional register info.  
Special thanks to Sasha Shturma's Raspberry Pi CM4 Сarrier with Hi-Res MIPI Display project, the DKMS install script is adapted from the github project page: https://github.com/renetec-io/cm4-panel-jdi-lt070me05000

## Prerequisites

Before you begin the installation process, please ensure the following prerequisites are met:

- **Kernel version**: You should be running on a Linux kernel version 6.12 or newer. You can verify your kernel version by executing `uname -r` in your terminal.

- Install the kernel headers matching the Raspberry Pi kernel you will run. DKMS needs them to compile the module.

## Installation Steps

You can install the IMX585 driver either via a Debian package (recommended) or manually using the setup script.

### Option 1: Install via Debian Package (Recommended)

The Debian package provides automated DKMS integration, making it easier to manage the driver across kernel upgrades.

#### Building the Debian Package

First, install the build dependencies:

```bash
sudo apt install build-essential debhelper dh-dkms device-tree-compiler
```

Clone the repository and build the package:

```bash
git clone --branch eos/aither https://github.com/daleghent/imx585-v4l2-driver.git
cd imx585-v4l2-driver/
./build-deb.sh
```

#### Installing the Package

Install the generated `.deb` file:

```bash
version=$(dpkg-parsechangelog -S Version)
sudo apt install "../imx585-dkms_${version#*:}_all.deb"
```

The package will automatically:
- Register the module with DKMS
- Build and install the kernel module for kernels selected by DKMS with matching headers
- Install the precompiled device tree overlay
- Rebuild the module automatically when the kernel is upgraded

See [debian/README.md](debian/README.md) for more details.

### Option 2: Manual Installation with setup.sh

#### Setting Up the Tools

Install the tools for a standalone DKMS installation:

```bash
sudo apt install dkms dpkg-dev device-tree-compiler git
```

#### Fetching the Source Code

Clone the repository to your local machine and navigate to the cloned directory:

```bash
git clone --branch eos/aither https://github.com/daleghent/imx585-v4l2-driver.git
cd imx585-v4l2-driver/
```

#### Compiling and Installing the Kernel Driver

To compile and install the kernel driver, execute the provided installation script:

```bash
./setup.sh
```

The script installs the new driver for the running kernel. If you previously
installed a different version manually, check `dkms status -m imx585`. Once
all kernels you use have the new driver, you can retire the old registration
with `sudo dkms remove imx585/<old-version> --all`.

### Updating the Boot Configuration

On current Raspberry Pi OS, edit the boot configuration file with:

```bash
sudo nano /boot/firmware/config.txt
```

On older installations the file is `/boot/config.txt`.

In the opened editor, locate the line containing `camera_auto_detect` and change its value to `0`. Then, add the line `dtoverlay=imx585`. So, it will look like this:

```
camera_auto_detect=0
dtoverlay=imx585
```

After making these changes, save the file and exit the editor.

Remember to reboot your system for the changes to take effect.

## Register settings outside the Sony worksheet

The IMX585 Standard Register Setting Ver. 1.0 worksheet omits the addresses below. The driver uses them for existing module and Raspberry Pi behavior. The commit IDs identify where each setting entered this driver.

| Address | Driver use | Source in driver history |
| --- | --- | --- |
| `0x3019` | Select monochrome or color binning | `f3a37a0`, monochrome binning correction |
| `0x303A` | Disable embedded-data output | `3a31573`, Raspberry Pi RAW16 capture |
| `0x30CE` | Select external XVS synchronization | `fe777d7`, external sync support |
| `0x30E0`, `0x30E2`, `0x5300` | Enable the test-pattern output and clock, and select a pattern | `2553a87`, test-pattern support adapted from the IMX283 driver |
| `0x3458` | Disable digital clamp at stream start | `8245dd1`, imported sensor setup |

These settings have no per-address IMX585 vendor reference in the repository. For black-level calibration, record that the driver disables digital clamp independently of the programmable `BLKLEVEL` offset.

## dtoverlay options

### cam0

If the camera is attached to cam0 port, append the dtoverlay with `,cam0` like this:  
```
camera_auto_detect=0
dtoverlay=imx585,cam0
```

### always-on

If you want to keep the camera power always on (Useful for debugging HW issues, specifically this will set CAM_GPIO to high constantly), append the dtoverlay with `,always-on` like this:  
```
camera_auto_detect=0
dtoverlay=imx585,always-on
```

### mono

If you are using a monochrome varient, append the dtoverlay with `,mono` like this:  
```
camera_auto_detect=0
dtoverlay=imx585,mono
```

### Lane Count

If you want to use 2-lane for IMX585, append the dtoverlay with `,2lane` like this:  
```
camera_auto_detect=0
dtoverlay=imx585,2lane
```

### link-frequency

If you want to change the default link frequency of 1440Mbps/lane (720Mhz), you can chage it like the following:
```
camera_auto_detect=0
dtoverlay=imx585,link-frequency=297000000
```
Here is a list of available frequencies:
| Valid Frequency Value | Mbps/Lane | Max Framerate with 4K 12bit + 4 lane | Max Framerate with 4K 12bit + 2 lane |
| -------- | -------- | -------- | -------- |
| 297000000|594 Mbps/Lane| 20.8 fps | 10.4 fps|
| 360000000|720 Mbps/Lane| 25.0 fps | 12.5 fps|
| 445500000|891 Mbps/Lane| 30.0 fps | 15.0 fps|
| 594000000|1188 Mbps/Lane| 41.7 fps| 20.8 fps|
| 720000000|1440 Mbps/Lane| 50.0 fps | 25.0 fps|
| 891000000|1782 Mbps/Lane| 60.0 fps | 30.0 fps|
| 1039500000|2079 Mbps/Lane| 75.0 fps | 37.5 fps|

Notes that by default RPI5/RP1 has a limit of 400Mpix/s processing speed, without overclocking RP1 (hence the Camera Frontend) you will be limited to ~43.8 FPS @ 4K.  
For ClearHDR mode the framerate will be half, for 1080P 2x2 binned the framerate will be double.  
1188 Mhz (2376 Mbps/lane) is also in the driver but RPI4 doesn't supports it from testing and RPI5 experience framedrop.  

### Sync-Mode

The driver exposes three sync modes, selectable via dtoverlay parameters:
| Mode                  | Description |
|-----------------------|-------------|
| **internal-leader** (default) | Sensor runs from its own internal clock and outputs both `XVS` (vertical sync) and `XHS` (horizontal sync). Other cameras can lock onto these signals. |
| **internal-follower** | Sensor still uses its own clock, but takes in an external `XVS` signal. It aligns vertical sync to this input by adding or subtracting a horizontal sync pulse. |
| **external**          | Sensor clock and timing are fully driven by external `XVS` and `XHS` signals. Both syncs are inputs, no outputs are generated. |

See [here](https://github.com/will127534/StarlightEye/wiki/IMX585-Camera-Clock-Synchronization-Guide) for the full guide.


### mix usage

Last note is that all the options can be used at the same time, the dtoverlay will looks like this:
```
camera_auto_detect=0
dtoverlay=imx585,mono,always-on,cam0,link-frequency=297000000
```
Imaging how many config I need to test.

