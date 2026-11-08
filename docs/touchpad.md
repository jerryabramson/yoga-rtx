# Touchpad: ELAN haptic pressurepad (04F3:3355)

The touchpad (`WACF2205`, I2C3) works out of the box with `hid-multitouch`
once the I2C controllers come up. libinput already knows the part
(`30-vendor-elantech.quirks`: "Elan Haptic Touchpad (04F3:3355)", marked
`INPUT_PROP_PRESSUREPAD`). It's a solid pad: the firmware senses force and
buzzes to fake a click.

## Vendor controls (from its HID report descriptor)

Dump it with `tools/hid-descriptor 04F3:3355`.

| Report | Type | Contents | Behaviour on this firmware |
|---|---|---|---|
| 8 | feature | Digitizer *Button Press Threshold* (0x0D:0xB0), 2 bits, 1–3 | Click force: 1 = light, 2 = medium (default), 3 = firm. Readable and writable. |
| 9 | feature | Haptics *Intensity* (0x0E:0x23), 2 bytes, 0–100 | **Write-only** (GET returns garbage, report ID 0xFF). Must be written `[v, 0]`: a nonzero second byte is silently ignored. Effectively on/off: 3, 30 and 100 feel the same. It's also a master mute: at 0, manual buzzes are silent too. |
| 0x42 | feature | Waveform list for manual-trigger ordinals 3–7 | `0x1008` (Release), `0x1012` (Sparkle, continuous), `0x1013`–`0x1015` |
| 0x43 | output | Manual trigger: ordinal 1–7, intensity 0–4, repeat 0–5, retrigger period, cutoff ≥ 1000 ms | Works; ordinal 2 = Stop. Ordinals 4→6 run high→low pitch (6 is a deep thump). |
| 0x12 | input | A full **pen** collection (tip, barrel, eraser, X/Y, 4096 pressure levels, tilt) | Ignored by Linux today (application usage 0x0D:0x01 Digitizer, not Pen). |

A "stronger click" daemon (play ordinal 6 for 60 ms on each press) was tried
and dropped. With the built-in buzz off it's silent, because intensity 0 is a
master mute. With the built-in buzz on it lands just after it, so the click
feels doubled. The built-in click is the ceiling.

## What's installed (`touchpad/`)

- `elan-touchpad`: read/set click force and haptic intensity, plus `buzz`,
  `waveforms`, `raw` and `reset` debugging commands. Needs root
  (`/dev/hidraw*`).
- `90-elan-touchpad.rules`: applies `force 1` whenever the pad's hidraw node
  appears.
- `elan-touchpad.sleep`: systemd-sleep hook that reapplies it after resume.

Change the level by editing `force 1` in both files before installing.
