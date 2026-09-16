#!/usr/bin/env bash
SDIO=/root/linux-6.12.47/drivers/net/wireless/broadcom/brcm80211/brcmfmac/sdio.c
echo "=== ALLOC (4674-4690) ==="; sed -n '4674,4690p' "$SDIO"
echo "=== queue_work @3834-3839 ==="; sed -n '3834,3839p' "$SDIO"
echo "=== queue_work @3861-3866 ==="; sed -n '3861,3866p' "$SDIO"
echo "=== queue_work @3898-3903 ==="; sed -n '3898,3903p' "$SDIO"
echo "=== module/moduleparam includes? ==="; grep -nE '#include <linux/(module|moduleparam)\.h>' "$SDIO"
echo "=== include-block (erste ~35 Zeilen) ==="; grep -nE '#include' <(sed -n '1,40p' "$SDIO")
