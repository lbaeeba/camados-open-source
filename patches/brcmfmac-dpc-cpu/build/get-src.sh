#!/usr/bin/env bash
set -e
cd /root
BASE=http://archive.raspberrypi.com/debian/pool/main/l/linux
echo "=== download orig + debian (exakt 6.12.47-1+rpt1) ==="
wget -q "$BASE/linux_6.12.47.orig.tar.xz" "$BASE/linux_6.12.47-1+rpt1.debian.tar.xz"
ls -la linux_6.12.47*
echo "=== brcm80211 aus orig extrahieren (selektiv) ==="
tar -xf linux_6.12.47.orig.tar.xz --wildcards \
  'linux-6.12.47/drivers/net/wireless/broadcom/brcm80211/*' \
  'linux-6.12.47/drivers/net/wireless/broadcom/Makefile' \
  'linux-6.12.47/drivers/net/wireless/broadcom/Kconfig'
test -f linux-6.12.47/drivers/net/wireless/broadcom/brcm80211/brcmfmac/sdio.c && echo "SDIO-DA"
echo "=== debian-patches: gibt es brcmfmac/brcm80211-Patches? ==="
mkdir -p deb && tar -xf linux_6.12.47-1+rpt1.debian.tar.xz -C deb
echo "--- series-count: $(wc -l < deb/debian/patches/series 2>/dev/null) ---"
HITS=$(grep -rliE 'brcmfmac|brcm80211' deb/debian/patches/ 2>/dev/null || true)
if [ -n "$HITS" ]; then echo "BRCM-PATCHES:"; echo "$HITS"; else echo "KEINE-BRCM-PATCHES (vanilla 6.12.47 = rpt fuer diese Datei)"; fi
echo GET-SRC-DONE
