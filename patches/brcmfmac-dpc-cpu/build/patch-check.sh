#!/usr/bin/env bash
set -e
cd /root/linux-6.12.47
RP=/root/deb/debian/patches/rpi/rpi.patch
echo "=== rpi.patch: betroffene brcm80211-Dateien ==="
grep -E '^\+\+\+ b/drivers/net/wireless/broadcom/brcm80211/' "$RP" || echo "(keine brcm80211-Dateien)"
echo "=== beruehrt rpi.patch den WQ-Code (brcmf_wq/alloc_workqueue/queue_work)? ==="
grep -nE 'brcmf_wq|alloc_ordered_workqueue|alloc_workqueue|queue_work' "$RP" | head || echo "(WQ-Code NICHT von rpi.patch beruehrt)"
echo "=== dry-run: nur brcm80211-Hunks anwenden ==="
patch -p1 --include='drivers/net/wireless/broadcom/brcm80211/*' --dry-run < "$RP" 2>&1 | tail -15
echo CHECK-DONE
