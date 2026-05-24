#!/bin/bash
set -euo pipefail

KVERSION=$(uname -r)
MODDIR="/lib/modules/$KVERSION/extra"

echo "=== acer-ec uninstaller ==="

if lsmod | grep -q "^acer_fanctl"; then
    echo "Removing acer_fanctl..."
    rmmod acer_fanctl
fi
if lsmod | grep -q "^acer_ec_core"; then
    echo "Removing acer_ec_core..."
    rmmod acer_ec_core
fi

echo "Removing module files..."
rm -f "$MODDIR/acer_ec_core.ko" "$MODDIR/acer_fanctl.ko"
depmod -a

echo "Removing config files..."
rm -f /etc/modprobe.d/acer-ec.conf
rm -f /etc/modules-load.d/acer-ec.conf

echo "=== Done ==="
