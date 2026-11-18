# Linux Hardware & Display Manager Quirks

## 1. Media Keys Blocking `Ctrl+Alt+F1`–`F6` VT Switching

### The Issue
* **Hardware media key reservation:** `F1` through `F6` send media keycodes by default rather than standard function keycodes (`F1`–`F6`).
* **Blocked VT shortcuts:** Pressing `Ctrl+Alt+F1` through `F6` does not switch Virtual Terminals, and the `Fn` key is intercepted in hardware so it cannot be bound directly in Linux.

### The Workaround
* **Text Consoles (TTYs 1–6):** Created `/usr/local/share/kbd/keymaps/custom-vt.map` (loaded via `loadkeys` / `/etc/vconsole.conf`) mapping `Ctrl+Alt+1` through `Ctrl+Alt+=` (`keycodes 2–13`) to `Console_1` through `Console_12`.
* **KDE Plasma (Wayland/X11):** Granted passwordless `sudo` for `/usr/bin/chvt` in `/etc/sudoers.d/chvt` and reassigned `Ctrl+Alt+1` through `Ctrl+Alt+=` in KDE Shortcuts to execute `sudo chvt <N>` (clearing orphaned KWin shortcut entries via KDE's reassign prompt).

**/usr/local/share/kbd/keymaps/custom-vt.map**
```
control alt keycode 2 = Console_1
control alt keycode 3 = Console_2
control alt keycode 4 = Console_3
control alt keycode 5 = Console_4
control alt keycode 6 = Console_5
control alt keycode 7 = Console_6
control alt keycode 8 = Console_7
control alt keycode 9 = Console_8
control alt keycode 10 = Console_9
control alt keycode 11 = Console_10
```
---

## 2. SDDM Hanging on Logout vs. GDM Working Reliably

### The Issue
* **SDDM post-logout hang:** SDDM fails to respawn properly after logging out of a KDE Plasma Wayland session, leaving a black screen.
* **Root cause on RTX Spark (N1X):** The system runs without `nvidia_drm.modeset=1` on the kernel command line. When a Wayland session exits, SDDM's X11 greeter (`/usr/bin/X`) cannot cleanly reclaim the framebuffer/DRM master (compounded by leftover Budgie X11 display scripts and missing Qt5 greeter themes).

### The Workaround
* **Use GDM as the primary display manager:** GDM manages Wayland/DRM handoffs through `systemd-logind` cleanly even without `nvidia_drm.modeset=1`, allowing reliable logouts and re-logins into **Plasma (Wayland)**.
* **Keep `Ctrl+Alt+1`–`=` VT switching active:** Provides reliable two-way access between text TTYs (1–6) and graphical sessions (7–12) as a fallback without needing `Fn` keys.

```
systemctl disable --now sddm && systemctl enable --now gdm
```
