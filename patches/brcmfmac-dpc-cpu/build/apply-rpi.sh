#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get install -y patchutils >/dev/null 2>&1
cd /root/linux-6.12.47
RP=/root/deb/debian/patches/rpi/rpi.patch
echo "=== brcm80211-Hunks aus rpi.patch extrahieren ==="
filterdiff -i '*/brcm80211/*' "$RP" > /root/brcm80211-rpi.patch
echo "  patch-zeilen: $(wc -l < /root/brcm80211-rpi.patch)  betroffene dateien:"
lsdiff /root/brcm80211-rpi.patch | sed 's/^/    /'
echo "=== dry-run ==="
if patch -p1 --dry-run < /root/brcm80211-rpi.patch 2>&1 | tail -25; then :; fi
echo "=== real apply ==="
patch -p1 < /root/brcm80211-rpi.patch 2>&1 | tail -25
echo "=== sdio.c jetzt rpt-gepatcht? (Marker) ==="
grep -nE 'brcmf_wq|alloc_ordered_workqueue|queue_work\(' drivers/net/wireless/broadcom/brcm80211/brcmfmac/sdio.c | head
echo APPLY-DONE
