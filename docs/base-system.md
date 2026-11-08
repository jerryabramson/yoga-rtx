# Base system: Ubuntu, kernel, NVIDIA driver, CUDA

This is the system everything else in this repo was built and tested on. It's
reconstructed from the reference machine's installed packages and config
(November 2026), not from a script, so treat it as a checklist, not a recipe.

| Component | Version on the reference machine |
|---|---|
| Distribution | Ubuntu 26.04.1 LTS (`resolute`), arm64 |
| Desktop | KDE Plasma 6.6.6 on Wayland (KWin 6.6.6), PipeWire 1.6.2 |
| Kernel | `linux-image-nvidia` 7.0.0-1025.26 (`7.0.0-1025-nvidia`) |
| NVIDIA driver | 615.71.10, open kernel modules (`nvidia-open`, `nvidia-dkms-open`) via DKMS |
| CUDA | 13.4 (`cuda-toolkit-13-4` 13.4.3), plus `cuda-toolkit-13-0` |
| Firmware (BIOS) | Lenovo `SDCN77WW`, 2026-09-24 |

## 1. Kernel: use the `-nvidia` flavour, not `-generic`

Most N1X SoC blocks are MediaTek IP behind NVIDIA ACPI IDs. Stock
`-generic` kernels have no drivers for them, so on `-generic` there's no I2C
(hence no internal keyboard, touchpad or touchscreen), no GPIO/pinctrl, and no
audio. Ubuntu's `linux-nvidia` flavour, built from NVIDIA's NV-Kernels, has
them:

| ACPI HID | Block | Driver in `-nvidia` |
|---|---|---|
| `NVDA0200` | I2C0–6 | `i2c-mt65xx` |
| `NVDA9221` | GPIO/pinctrl (`GIO0`) | `pinctrl_mt8901` (built-in) |
| `NVDA0240` | UARTs | `8250_mtk` |
| `NVDA9022` / `NVDA9100` | audio AFE / SoundWire | `mt8901-audio`, `mtk-soundwire` |

```sh
sudo apt install linux-image-nvidia linux-headers-nvidia
```

The headers package matters: DKMS rebuilds the NVIDIA driver for the new
kernel. Check `dkms status` shows `nvidia/615.71.10, 7.0.0-1025-nvidia,
aarch64: installed` **before** rebooting. Keep the `-generic` kernel
installed as a fallback (GRUB → *Advanced options*).

## 2. Kernel parameter: `acpi_osi="!Windows 2022"` (required)

Even on `-nvidia`, every I2C controller and the audio DSPs fail with
`pwrap probe failed`. The MediaTek drivers need the SSPM power manager
(`\_SB.SSPM`, `NVDA8400`), and its `_STA` returns 0 whenever
`_OSI("Windows 2022")` is true, which Linux answers yes to by default. All
five `_OSI("Windows 2022")` checks in the firmware (`SVP0`, `SSPM`, `HFRP` in
the DSDT; `NH1X`, `NMAP` in SSDT2) hide Linux-only devices from Windows 11,
so turning that one string off is the intended fix; no DSDT override is
needed. See [acpi-findings.md](acpi-findings.md).

In `/etc/default/grub`:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_osi=\"!Windows 2022\" console=tty0"
```

then `sudo update-grub`. The running kernel should show
`"acpi_osi=!Windows 2022"` in `/proc/cmdline`, and
`cat /sys/bus/acpi/devices/NVDA8400:00/status` should print `15`.

Showing the GRUB menu is worth it while experimenting with kernels:
`GRUB_TIMEOUT_STYLE=menu`, `GRUB_TIMEOUT=5`.

## 3. NVIDIA driver 615.71.10 (open modules)

Installed from NVIDIA's **local repository package** for Ubuntu 26.04,
`nvidia-driver-local-repo-ubuntu2604-615.71.10` (apt source
`file:///var/nvidia-driver-local-repo-ubuntu2604-615.71.10`), which also
installs `nvidia-driver-pinning-615.71.10`. That pins every driver package
to `615.71.10-*` at priority 1000 (`/etc/apt/preferences.d/nvidia-driver-pin`)
so Ubuntu's own driver packages don't replace it.

Packages: `nvidia-open` (pulls `nvidia-driver-open`, `nvidia-dkms-open`,
`nvidia-kernel-source-open`, `nvidia-kernel-common`, `nvidia-utils`,
`nvidia-settings`, `nvidia-persistenced`, `nvidia-modprobe`,
`xserver-xorg-video-nvidia`).

Module options in `/etc/modprobe.d/nvidia-graphics-drivers-kms.conf`:

```
options nvidia_drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var
```

`nvidia-smi` reports `NVIDIA RTX Spark N1X (6144-core Blackwell RTX GPU)`,
driver 615.71.10. The internal panel and HDMI both work, and the panel
backlight is `/sys/class/backlight/nvidia_0`.

## 4. CUDA 13.4

Two NVIDIA apt sources are configured:

| Source | Purpose |
|---|---|
| `file:///var/cuda-repo-ubuntu2604-13-4-local` (from `cuda-repo-ubuntu2604-13-4-local` 13.4.3) | CUDA 13.4 local repo for Ubuntu 26.04 |
| `https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/sbsa/` (with `cuda-keyring`, keyring `/usr/share/keyrings/cuda-archive-keyring.gpg`) | NVIDIA's network repo for arm64 servers (SBSA), Ubuntu 24.04 track |

`/etc/apt/preferences.d/cuda-repository-pin-600` gives `l=NVIDIA CUDA` a
priority of 600 and blocks Ubuntu's own `nsight-compute`/`nsight-systems`.

Installed: `cuda-toolkit-13-4` (and `cuda-toolkit-13-0`), under
`/usr/local/cuda-13.4`, with `/usr/local/cuda` → the current one.

## 5. Other repos on the reference machine

- `ppa:graphics-drivers/ppa` is configured; the NVIDIA pin above keeps it from
  changing the driver.
- Leftovers that aren't needed: mainline `linux-headers-7.2.0-070200`, and
  `nvidia-utils-580`.
