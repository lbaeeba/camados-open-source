#!/usr/bin/env bash
set -e
KREL=6.12.47+rpt-rpi-v8-rt
BL=/lib/modules/$KREL/build
SRC=/root/linux-6.12.47/drivers/net/wireless/broadcom/brcm80211
echo "=== build (brcm80211 dir gegen rt-headers) ==="
make -C "$BL" M="$SRC" modules 2>&1 | tail -30
echo "=== Ergebnis-Module ==="
find "$SRC" -name '*.ko' | sed 's/^/  /'
echo "=== vermagic + depends (GATE) ==="
for ko in $(find "$SRC" -name 'brcmfmac.ko' -o -name 'brcmutil.ko' -o -name 'brcmfmac-wcc.ko'); do
  echo "[$ko]"; modinfo "$ko" 2>/dev/null | grep -E '^vermagic|^depends' | sed 's/^/  /'
done
echo "=== brcmf_dpc_cpu param im Modul? ==="
modinfo $SRC/brcmfmac/brcmfmac.ko 2>/dev/null | grep -i 'parm:.*brcmf_dpc_cpu'
echo "=== ZIEL: 6.12.47+rpt-rpi-v8-rt SMP preempt_rt mod_unload modversions aarch64 | brcmutil,cfg80211 ==="
echo BUILD-DONE
