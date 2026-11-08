#!/bin/sh
# Install the Yoga 9N UCM profile (speakers + headphones, playback only)
# for the MT8901 SoundWire card.
# Run as: sudo ./install.sh        Uninstall: sudo ./install.sh --uninstall
set -e
cd "$(dirname "$0")"

CONFD=/usr/share/alsa/ucm2/conf.d/mt8901-soundwir/mt8901-soundwir.conf
VERB=/usr/share/alsa/ucm2/MediaTek/mt8901-soundwir/Yoga9N-HiFi.conf
OLD=/usr/share/alsa/ucm2/MediaTek/mt8901-soundwir/Yoga9N-playback.conf  # earlier name

if [ "$1" = "--uninstall" ]; then
    rm -f /usr/share/alsa/ucm2/conf.d/mt8901-soundwir/mt8901-soundwir.conf \
          /usr/share/alsa/ucm2/MediaTek/mt8901-soundwir/Yoga9N-HiFi.conf \
          /usr/share/alsa/ucm2/MediaTek/mt8901-soundwir/Yoga9N-playback.conf
    rmdir /usr/share/alsa/ucm2/conf.d/mt8901-soundwir \
          /usr/share/alsa/ucm2/MediaTek/mt8901-soundwir 2>/dev/null || true
    echo "uninstalled; now: systemctl --user restart wireplumber pipewire pipewire-pulse"
    exit 0
fi

for f in "$CONFD" "$VERB" "$OLD"; do
    if [ -e "$f" ] && ! grep -q "Lenovo Yoga 9 2-in-1 16N1X11" "$f"; then
        echo "refusing to overwrite $f (not ours; alsa-ucm-conf may ship it now)" >&2
        exit 1
    fi
done
install -D -m 0644 ucm2/conf.d/mt8901-soundwir/mt8901-soundwir.conf "$CONFD"
install -D -m 0644 ucm2/MediaTek/mt8901-soundwir/Yoga9N-HiFi.conf "$VERB"
rm -f /usr/share/alsa/ucm2/MediaTek/mt8901-soundwir/Yoga9N-playback.conf
echo "installed; now restart PipeWire as your user:"
echo "  systemctl --user restart wireplumber pipewire pipewire-pulse"
