# Audio: MT8901 SoundWire, CS42L43 + 4× CS35L56

With the `-nvidia` kernel and `acpi_osi="!Windows 2022"`, the hardware comes
up on its own: card `mt8901-soundwir` (`mt8901-soundwire`, long name
`LENOVO-83N7-Yoga92_in_116N1X11-LNVNB161216`), with SoundWire link 1 carrying
the CS42L43 (`sdw:0:1:01fa:4243:01`, headphones) and four CS35L56 amps
(`sdw:0:1:01fa:3556:01:{0,1,4,5}`). What's missing is a UCM profile, without
which PipeWire shows only *Dummy Output*.

## The profile

`audio/ucm2/` is NVIDIA's `HiFi-cs42l43-cs35l56x4.conf` from
[alsa-ucm-conf PR 862](https://github.com/alsa-project/alsa-ucm-conf/pull/862)
(head `7d3555a7`). PR 862 covers exactly this topology: everything on link 1,
amps numbered 0, 1, 4, 5. It's cut down to playback and has all four amps at
0 dB. Verified: speakers (left/right), headphones (jack switching, hardware
volume via `cs42l43 Headphone Digital`).

| Output | PCM | Path |
|---|---|---|
| Speakers | `hw:N,0` (DL0) | O152/O153 → PDI3 → DP3 → 4× CS35L56 |
| Headphones | `hw:N,1` (DL1) | O156/O157 → PDI5 → DP5 → CS42L43 |

**Microphones are left out on purpose** (the reference setup records from a
USB mic, and internal sources could take over as PipeWire's default). The
internal mic array does work: UL1 = `hw:N,8`, via PDI13 ← DP7, O020/O021, from
cs42l43 decimators 3+4. It measured about −42 dBFS room noise after a
~200 ms startup transient. To add it, copy the `Mic`/`Headset` devices and
the three capture `cset`s from PR 862's file.

When alsa-ucm-conf ships PR 862, prefer the upstream files. `install.sh`
refuses to overwrite files that aren't its own.

## Speaker tuning (not done)

The CS35L56s run untuned ROM firmware (`FIRMWARE_MISSING`, `Can't read tuning
IDs`). linux-firmware has no tuning for Lenovo `17aa:3802`, and the machine
driver doesn't pass the SSID that the firmware lookup needs. Volume and
quality are fine as is. Tuning would mean a one-line patch to
`mt8901-acp-sdw-legacy-mach.c` (as the ASUS P16 project did) plus the
`cs35l56-b0-dsp1-misc-17aa3802*` files from Lenovo's Windows audio driver.
Until then, there's no speaker protection matched to these drivers, so don't
push the speakers into audible distortion.
