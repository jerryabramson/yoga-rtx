#!/bin/sh
# Yoga 9N internal keyboard:
#  - hwdb remap: F1-F6 -> media keys, Caps Lock -> Left Ctrl, Right Alt -> Caps Lock
#  - libinput quirk marking the keyboard internal (tablet mode suspends it,
#    disable-while-typing pairs it with the touchpad)
#  - panel-only brightness keys (with key repeat) for KDE Plasma
# Run as: sudo ./install.sh        Uninstall: sudo ./install.sh --uninstall
# The brightness service acts for the user who ran sudo (override: DESKTOP_USER=name).
set -e
cd "$(dirname "$0")"

if [ "$1" = "--uninstall" ]; then
    systemctl disable --now panel-brightness-keys.service 2>/dev/null || true
    rm -f /etc/udev/hwdb.d/61-yoga9n-keyboard.hwdb \
          /usr/local/sbin/panel-brightness-keys \
          /usr/local/bin/panel-brightness \
          /etc/systemd/system/panel-brightness-keys.service
    if grep -qs "Lenovo Yoga 9 2-in-1 16N1X11" /etc/libinput/local-overrides.quirks; then
        rm -f /etc/libinput/local-overrides.quirks
    fi
    systemctl daemon-reload
else
    USER_NAME="${DESKTOP_USER:-$SUDO_USER}"
    if [ -z "$USER_NAME" ] || [ "$USER_NAME" = root ]; then
        echo "run via sudo from your desktop account, or set DESKTOP_USER=name" >&2
        exit 1
    fi
    install -m 0644 61-yoga9n-keyboard.hwdb /etc/udev/hwdb.d/61-yoga9n-keyboard.hwdb
    if [ -e /etc/libinput/local-overrides.quirks ] && \
       ! grep -q "Lenovo Yoga 9 2-in-1 16N1X11" /etc/libinput/local-overrides.quirks; then
        echo "note: /etc/libinput/local-overrides.quirks exists and isn't ours;" \
             "merge keyboard/local-overrides.quirks into it by hand" >&2
    else
        install -D -m 0644 local-overrides.quirks /etc/libinput/local-overrides.quirks
    fi
    install -m 0755 panel-brightness /usr/local/bin/panel-brightness
    install -m 0755 panel-brightness-keys /usr/local/sbin/panel-brightness-keys
    sed "s/@USER@/$USER_NAME/" panel-brightness-keys.service \
        > /etc/systemd/system/panel-brightness-keys.service
    chmod 0644 /etc/systemd/system/panel-brightness-keys.service
    systemctl daemon-reload
    systemctl enable panel-brightness-keys.service
fi
systemd-hwdb update
# Re-apply keymaps to the internal keyboard's input devices now.
for ev in /sys/class/input/event*; do
    case "$(cat "$ev/device/id/vendor"):$(cat "$ev/device/id/product")" in
        048d:83db) udevadm trigger --action=change "$ev" ;;
    esac
done
udevadm settle
if [ "$1" != "--uninstall" ]; then
    systemctl restart panel-brightness-keys.service
    systemctl --no-pager status panel-brightness-keys.service | head -6
    echo "log out and back in for the libinput quirk to reach KWin"
fi
echo "done"
