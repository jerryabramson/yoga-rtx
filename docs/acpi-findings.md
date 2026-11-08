# ACPI findings

Notes from reading this laptop's own ACPI tables (DSDT `LENOVO CB-01` OEM rev
4, BIOS `SDCN77WW`). The tables themselves aren't in this repo: they're
Lenovo/NVIDIA firmware with no redistribution license. Dump your own:

```sh
mkdir acpi && cd acpi
sudo cp /sys/firmware/acpi/tables/{DSDT,SSDT*} . && sudo chown "$USER" *
iasl -e SSDT1 SSDT2 SSDT3 SSDT4 SSDT5 -d DSDT    # ACPICA iasl (20260408 used here)
```

Line numbers below refer to that `DSDT.dsl` and are approximate.

## Platform

ARM64 (`IORT`, `GTDT`, `PPTT`, `SPCR`, `DBG2`, `CSRT`), 20 cores as
`SYSM → PKG0 → CLU0/CLU1` with 10 `ACPI0007` CPUs each. The large `PEPD`
device (~5425–9130) is the Windows-on-ARM power engine plugin.

SoC blocks are MediaTek IP behind NVIDIA IDs. The I2C controllers have a main
register window plus a 0x80-byte AP-DMA window (MediaTek style), and `GIO0`
spans ~14 separate 4 KB windows (MediaTek pinctrl). The driver mapping is in
[base-system.md](base-system.md#1-kernel-use-the--nvidia-flavour-not--generic).

SSDT sources: `SSDT1` NVIDIA `RotSsdt`, `SSDT2` Lenovo `CB-01` platform,
`SSDT3` TPM, `SSDT4` `ELN-WACF` (touch/pen), `SSDT5` `LfcECCom` (EC comms).

## The `_OSI("Windows 2022")` gate

| Device | HID | Table |
|---|---|---|
| `SVP0` | `NVDA3000` | DSDT (~15898) |
| `SSPM` | `NVDA8400` | DSDT (~16083) |
| `HFRP` | `MTK00055` | DSDT (~16115) |
| `NH1X` | `NVDA300A` | SSDT2 |
| `NMAP` | `NVDA300B` | SSDT2 |

Each `_STA` is `If (_OSI ("Windows 2022")) { Return (Zero) } Else { Return (0x0F) }`.
Linux claims every Windows `_OSI` string, so all five vanish. SSPM is the one
that matters: `mtk_pwrap`, the I2C controllers and the audio DSPs depend on it
(`pwrap probe failed for \_SB_.I2Cn`, `SSPM probe failed: -19`). The fix is
the boot parameter `acpi_osi="!Windows 2022"`. The ASUS ProArt P16 project
byte-patches its DSDT for the same predicate instead.

## Input devices (all HID over I2C, `PNP0C50`)

| Device | ACPI | Bus | VID:PID | Linux driver |
|---|---|---|---|---|
| Keyboard | `ECKB` / `LENC0001` (DSDT ~14228) | I2C2 @0x3A, GPIO 0x21 | `048D:83DB` (ITE) | hid-generic |
| Touchpad | `TCPD` / `WACF2205` (SSDT4) | I2C3 | `04F3:3355` (ELAN haptic) | hid-multitouch |
| Touchscreen + pen | `TCPL` / `WACF2200` | I2C1 @0x0A, GPIO 0x1F | `056A:5424` (Wacom) | wacom |
| Sensor hub | `AI5K` / `IDEA5003` | I2C1 or I2C3 (per `BRDP`) @0x5C, GPIO 0x29 | `048D:5003` (ITE) | hid-sensor-hub |
| Hinge / tablet mode | `CONV` / `ID9001` (`PNP0C60`) | GPIO | n/a | soc_button_array → gpio-keys `SW_TABLET_MODE` |

Each I2C device's `_DEP` lists `GIO0` plus its I2C controller, so nothing
enumerates until both drivers bind, which on `-generic` they never do.

## Hotkeys go through the EC and WMI, not the keyboard

The keyboard always sends plain F1–F6. Fn, Fn-Lock (Fn+Esc) and the BIOS
hotkey-mode setting don't change its HID output. The hotkey *functions* are
routed through the embedded controller: a large `Switch` (~19230–19510)
stores an EC code in `EC0.LSK2` and raises `Notify (WMIU, 0xD0)`, where
`WMIU` is `PNP0C14` UID `LSK20`, Lenovo's WMI hotkey device. On Windows the
Lenovo WMI driver handles that. On this Linux setup the path is dead twice
over:

- `nvidia-ffa-ec` (the EC transport over Arm FF-A) fails to probe:
  `Failed to request notification cookie=237 notif_id=36 error=-22`;
- the `-nvidia` kernel is built without `CONFIG_ACPI_WMI`.

The Copilot key sends nothing at all, presumably through the same path. See
[keyboard.md](keyboard.md) for the remap used instead.

## Audio identity

The `_SUB` of the audio devices is `380217AA`: Lenovo subsystem
`17aa:3802`. linux-firmware has no CS35L56 tuning for `17aa3802`, and the
MT8901 machine driver doesn't pass a subsystem ID to the amps anyway (the P16
project patches `mt8901-acp-sdw-legacy-mach.c` with `snd_soc_card_set_pci_ssid`
for ASUS). See [audio.md](audio.md).
