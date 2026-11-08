# Keyboard, hotkeys and brightness (KDE Plasma)

## Hotkeys

The internal keyboard (`LENC0001`, ITE `048D:83DB`) always sends plain F1–F6
for the top row. The real hotkey path (EC → `Notify(WMIU, 0xD0)` → Lenovo WMI
driver) is dead on Linux; see [acpi-findings.md](acpi-findings.md#hotkeys-go-through-the-ec-and-wmi-not-the-keyboard).
So `keyboard/61-yoga9n-keyboard.hwdb` remaps the scancodes, for the internal
keyboard only (match `evdev:input:b0018v048Dp83DB*`):

| Key | Becomes | Scancode |
|---|---|---|
| F1 | Mute | 0x7003a |
| F2 | Volume down | 0x7003b |
| F3 | Volume up | 0x7003c |
| F4 | Mic mute | 0x7003d |
| F5 | Brightness down | 0x7003e |
| F6 | Brightness up | 0x7003f |
| Caps Lock | Left Ctrl | 0x70039 |
| Right Alt | Caps Lock | 0x700e6 |

The cost: plain F1–F6 and Right Alt (AltGr) are gone on the internal keyboard.
External keyboards are untouched. The Copilot key sends no event at all, so it
can't be remapped.

`tools/keywatch` (root) prints key events with names and scancodes from every
input device, which is handy for checking any of this.

## Brightness keys: laptop panel only, with key repeat

Plasma's brightness keys (PowerDevil) adjust every display with a brightness
control, external monitors included (software dimming when KWin doesn't use
DDC/CI). There's no option to limit them to one screen, and Plasma ignores
key repeat for custom command shortcuts. So:

- `panel-brightness up|down [step]` changes only `eDP-1` via
  `kscreen-doctor` (KWin stays in sync) and shows the normal Plasma OSD via
  `qdbus6 … osdService.brightnessChanged`.
- `panel-brightness-keys` is a root service that reads the internal
  keyboard's evdev node, reacts only to `KEY_BRIGHTNESSUP/DOWN` (press and
  repeat; repeats queued during a step are merged), and runs
  `panel-brightness` as the desktop user inside their session. It grabs
  nothing and gives the user session no keyboard access.

**After installing**, in System Settings → Keyboard → Shortcuts → Power
Management, **unbind** *Increase Screen Brightness* and *Decrease Screen
Brightness*, or each press steps twice. The step size is the `5` in the
service's `ExecStart`.

## Tablet mode

libinput suspends only *internal* keyboards when `SW_TABLET_MODE` is on, and
its generic rules count only PS/2 keyboards as internal. So this I2C keyboard
stayed live in tablet mode. `keyboard/local-overrides.quirks` (installed as
`/etc/libinput/local-overrides.quirks`) sets `AttrKeyboardIntegration=internal`.
That also enables disable-while-typing for the touchpad. KWin reads quirks
only at login.

## Installing

`sudo keyboard/install.sh` installs all of the above. Run it via `sudo` from
your desktop account (the brightness service acts for `$SUDO_USER`), then log
out and back in.
