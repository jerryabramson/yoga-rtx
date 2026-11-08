#!/bin/sh
# Install Realtek's out-of-tree r8152 driver via DKMS, for the RTL8159 10 GbE
# USB adapter (0bda:815a), which the 7.0 kernel's r8152 doesn't support
# (support lands in 7.2). Without it the adapter falls back to cdc_ncm and
# downloads cap out near 2 Gbit/s.
#
# Usage: sudo ./install.sh /path/to/r8152-vX.Y.Z.tar.gz
#        sudo ./install.sh --uninstall
# Get the tarball from Realtek's download page for the RTL8152/RTL815x USB
# Ethernet "Linux driver". Tested with v2.22.1 (2026-06-03).
#
# DKMS installs into updates/dkms, which takes priority over the kernel's own
# r8152.ko without deleting it (Realtek's `make install` deletes it), and
# rebuilds automatically for new kernels.
set -e
cd "$(dirname "$0")"

if [ "$1" = "--uninstall" ]; then
    for v in $(dkms status r8152 2>/dev/null | sed -n 's|^r8152/\([^,]*\),.*|\1|p' | sort -u); do
        dkms remove "r8152/$v" --all || true
        if [ -n "$v" ] && [ -d "/usr/src/r8152-$v" ]; then rm -r "/usr/src/r8152-$v"; fi
    done
    rm -f /etc/udev/rules.d/50-usb-realtek-net.rules
    udevadm control --reload
    depmod -a
    echo "uninstalled; replug the adapter (it goes back to cdc_ncm)"
    exit 0
fi

TARBALL="$1"
[ -f "$TARBALL" ] || { echo "usage: sudo $0 /path/to/r8152-vX.Y.Z.tar.gz" >&2; exit 1; }
VER=$(basename "$TARBALL" | sed -n 's/^r8152-v\{0,1\}\([0-9][0-9.]*[0-9]\)\.tar\.gz$/\1/p')
[ -n "$VER" ] || { echo "can't read a version from $(basename "$TARBALL")" >&2; exit 1; }
SRC="/usr/src/r8152-$VER"

if dkms status "r8152/$VER" 2>/dev/null | grep -q .; then
    dkms remove "r8152/$VER" --all
fi
mkdir -p "$SRC"
tar -xzf "$TARBALL" -C "$SRC" --strip-components=1
sed "s/@VERSION@/$VER/" dkms.conf > "$SRC/dkms.conf"

dkms add "r8152/$VER"
dkms build "r8152/$VER"
dkms install "r8152/$VER"

# Realtek's rule switches the adapter to its vendor configuration so r8152,
# not cdc_ncm, binds it.
install -m 0644 "$SRC/50-usb-realtek-net.rules" /etc/udev/rules.d/50-usb-realtek-net.rules
udevadm control --reload
depmod -a
# A stock r8152 already in memory keeps running until it's reloaded.
modprobe -r r8152 2>/dev/null || true
modprobe r8152
echo
dkms status r8152
echo "loaded r8152 $(cat /sys/module/r8152/version 2>/dev/null || echo '(stock?)')"
echo "installed r8152 $VER; now unplug and replug the adapter"
