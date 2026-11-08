#!/bin/sh
# Keep the Yoga 9N touchpad's click force at 1 across boot, reset and resume.
# Run as: sudo ./install.sh        Uninstall: sudo ./install.sh --uninstall
set -e
cd "$(dirname "$0")"

if [ "$1" = "--uninstall" ]; then
    rm -f /usr/local/bin/elan-touchpad \
          /etc/udev/rules.d/90-elan-touchpad.rules \
          /usr/lib/systemd/system-sleep/elan-touchpad
    udevadm control --reload
    echo "uninstalled"
    exit 0
fi

install -m 0755 elan-touchpad /usr/local/bin/elan-touchpad
install -m 0644 90-elan-touchpad.rules /etc/udev/rules.d/90-elan-touchpad.rules
install -m 0755 elan-touchpad.sleep /usr/lib/systemd/system-sleep/elan-touchpad
udevadm control --reload
/usr/local/bin/elan-touchpad force 1
