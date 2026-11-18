# yoga-rtx

Linux enablement for the **Lenovo Yoga 9 2-in-1 16N1X11** (machine type
**83N7**, "Yoga 9N RTX Spark"): an ARM64 laptop on the **NVIDIA RTX Spark N1X**
SoC. Lenovo and NVIDIA ship no Linux support for it, and this repo collects
what it took to make the hardware work on Ubuntu with KDE Plasma.

Tested on Ubuntu 26.04.1 LTS, kernel `7.0.0-1025-nvidia`, NVIDIA driver
615.71.10 (open), CUDA 13.4, KDE Plasma 6.6.6 (Wayland), BIOS `SDCN77WW`.

## Status

| Hardware | Status | How |
|---|---|---|
| Internal panel, HDMI, GPU/CUDA | ✅ | NVIDIA 615.71.10 open driver (DKMS) |
| Wi-Fi | ✅ | stock (~1.35 Gbit/s measured) |
| 10 GbE USB adapter (Realtek RTL8159) | ✅ | `network/`: Realtek's r8152 via DKMS; 6.33 Gbit/s down, 6.9 up (was 2.15 down) |
| Internal keyboard, touchpad, touchscreen, pen | ✅ | `-nvidia` kernel + `acpi_osi="!Windows 2022"` |
| Touchpad click force | ✅ | `touchpad/`: set to light (1 of 3) |
| Hotkeys (mute, volume, mic mute, brightness) | ✅ | `keyboard/`: F1–F6 remapped (plain F1–F6 lost) |
| Brightness keys: panel only, with key repeat | ✅ | `keyboard/`: Plasma-specific service |
| Speakers, headphones (jack switching) | ✅ | `audio/`: UCM from NVIDIA's alsa-ucm-conf PR 862 |
| Auto-rotation, tablet mode | ✅ | stock, plus `keyboard/` libinput quirk so tablet mode suspends the keyboard |
| Internal microphones | ⚠️ | hardware path verified; not enabled in the profile (see [docs/audio.md](docs/audio.md)) |
| Stronger touchpad haptics | ❌ | firmware limit (see [docs/touchpad.md](docs/touchpad.md)) |
| Copilot key, other EC/WMI hotkeys | ❌ | `nvidia-ffa-ec` fails; kernel lacks `CONFIG_ACPI_WMI` |
| Pen on the touchpad surface | ❌ | the pad's pen collection is ignored by `hid-multitouch` |
| Speaker tuning (CS35L56) | ❌ | no Lenovo `17aa:3802` tuning; untuned ROM firmware |
| External monitor DDC/CI in KWin | ❌ | KWin reports `detectedDdcCi=false` |
| Thunderbolt/USB4 dock: DisplayPort, Ethernet | ❌ | no Linux driver for the platform USB4 host routers (`NVDA8100`/`ACPI0015`); dock USB works (see [docs/acpi-findings.md](docs/acpi-findings.md#usb4--thunderbolt)) |

## Setup, in order

1. **Base system**: Ubuntu 26.04, the `linux-image-nvidia` kernel, the
   `acpi_osi="!Windows 2022"` boot parameter, and the NVIDIA driver + CUDA.
   See **[docs/base-system.md](docs/base-system.md)**. Nothing internal
   (keyboard, touchpad, audio) works without the kernel and the boot
   parameter.
2. **Touchpad click force**: `sudo touchpad/install.sh`
3. **Audio**: `sudo audio/install.sh`, then
   `systemctl --user restart wireplumber pipewire pipewire-pulse`
4. **Wired network** (only for an RTL8159 adapter):
   `sudo network/install.sh /path/to/r8152-vX.Y.Z.tar.gz`, then replug it.
5. **Keyboard**: `sudo keyboard/install.sh` (via `sudo` from your desktop
   account), then in System Settings → Keyboard → Shortcuts → Power
   Management unbind *Increase/Decrease Screen Brightness*, and log out and
   back in.

Every `install.sh` takes `--uninstall`.

## Layout

| Path | Contents |
|---|---|
| `docs/base-system.md` | Ubuntu, kernel, boot parameter, NVIDIA driver, CUDA |
| `docs/acpi-findings.md` | What the firmware tables revealed (MediaTek IP, the `_OSI` gate, input devices, the EC/WMI hotkey path) |
| `docs/touchpad.md`, `docs/keyboard.md`, `docs/audio.md`, `docs/network.md` `docs/HARDWARE_QUIRKS.md` | Per-component details and findings |
| `touchpad/` | `elan-touchpad` tool, udev rule, resume hook |
| `audio/` | ALSA UCM profile |
| `network/` | DKMS packaging for Realtek's r8152 driver (RTL8159) |
| `keyboard/` | hwdb remap, libinput quirk, `panel-brightness` + key service |
| `tools/` | `keywatch` (evdev key events), `hid-descriptor` (HID report descriptor decoder) |


## 3. System Specifications (Sanitized)

```text
  $ neofetch && mysystem && showDisks.sh
           `.:/ossyyyysso/:.               user@hostname
        .:oyyyyyyyyyyyyyyyyyyo:`           -------------
      -oyyyyyyyodMMyyyyyyyysyyyyo-         OS: Kubuntu 26.04.1 LTS aarch64
    -syyyyyyyyyydMMyoyyyydmMMyyyyys-       Host: LENOVO [REDACTED]
   oyyysdMysyyyydMMMMMMMMMMMMMyyyyyyyo     Kernel: 7.0.0-1025-nvidia
 `oyyyydMMMMysyysoooooodMMMMyyyyyyyyyo`    Uptime: 1 hour, 23 mins
 oyyyyyydMMMMyyyyyyyyyyyysdMMysssssyyyo    Packages: 2877 (dpkg), 13 (snap)
-yyyyyyyydMysyyyyyyyyyyyyyysdMMMMMysyyy-   Shell: bash 5.3.9
oyyyysoodMyyyyyyyyyyyyyyyyyyydMMMMysyyyo   Resolution: 2880x1800
yyysdMMMMMyyyyyyyyyyyyyyyyyyysosyyyyyyyy   DE: Plasma 6.6.6 (Wayland)
yyysdMMMMMyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy   WM: kwin_wayland_wr
oyyyyysosdyyyyyyyyyyyyyyyyyyydMMMMysyyyo   Theme: Mojave-Dark-solid [GTK2/3]
-yyyyyyyydMysyyyyyyyyyyyyyysdMMMMMysyyy-   Icons: WhiteSur-dark [GTK2/3]
 oyyyyyydMMMysyyyyyyyyyyysdMMyoyyyoyyyo    Terminal: kitty
 `oyyyydMMMysyyyoooooodMMMMyoyyyyyyyyo     Terminal Font: Meslo [REDACTED]
   oyyysyyoyyyysdMMMMMMMMMMMyyyyyyyyo      CPU: (20) @ 2.808GHz
    -syyyyyyyyydMMMysyyydMMMysyyyys-       GPU: NVIDIA RTX Spark N1X
      -oyyyyyyydMMyyyyyyysosyyyyo-         Memory: 3344MiB / 29073MiB
        ./oyyyyyyyyyyyyyyyyyyo/.
           `.:/oosyyyysso/:.`


                  Hostname: [REDACTED]
          Operating System: Linux   (Ubuntu 26.04.1 LTS) 7.0.0-1025-nvidia aarch64
                  Platform: Linux 7.0.0-1025-nvidia
                 CPU Model: Cortex-X925 Cortex-A725
             Serial Number: [REDACTED]
                 CPU Cores: 20
        System Memory (GB): 28.39
 VGA compatible controller: NVIDIA Corporation GB20B [RTX Spark N1X (6144-core Blackwell RTX GPU)] (rev a1)

nvme1n1        1.8T disk                                                                                                                      Sandisk [REDACTED]
├─nvme1n1p1    1.9G part /boot      ext4   345.9M    1.4G    19% [REDACTED]                                                                   Linux filesystem
├─nvme1n1p2      1G part /boot/efi  vfat       8M      1G     1% [REDACTED]                                                                   EFI System
├─nvme1n1p3   65.2G part /          ext4    31.9G   28.5G    50% [REDACTED]                                                                   Linux filesystem
├─nvme1n1p4  186.3G part /home      ext4    26.6G  146.3G    15% [REDACTED]                                                                   Linux filesystem
├─nvme1n1p5   14.9G part [SWAP]     swap                         [REDACTED]                                                                   Linux swap
```


## Credits

- NVIDIA's MT8901 UCM work: [alsa-ucm-conf PR 862](https://github.com/alsa-project/alsa-ucm-conf/pull/862).
- The ASUS ProArt P16 (H7607BA) Arch Linux ARM enablement project, a sibling
  N1X laptop, pointed the way on NV-Kernels, SSPM and audio.
   - https://github.com/johannhartmann/asus-proart-p16-rtx-spark-linux

## License

MIT (see `LICENSE`), except the files under `audio/ucm2/`, which are derived
from NVIDIA's UCM and stay **BSD-3-Clause** (notice in each file).

No ACPI tables or firmware are included: they're Lenovo/NVIDIA material with
no redistribution license. [docs/acpi-findings.md](docs/acpi-findings.md)
shows how to dump your own.
