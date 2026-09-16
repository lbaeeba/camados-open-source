#!/usr/bin/env bash
set -e
SDIO=/root/linux-6.12.47/drivers/net/wireless/broadcom/brcm80211/brcmfmac/sdio.c
cp "$SDIO" "$SDIO.orig"

# --- 1) module_param-Block nach letztem #include einfuegen (awk, robust) ---
cat > /tmp/param.txt <<'EOF'

/* Camados #130: pin the SDIO datawork DPC to an isolated CPU (default 2, isolcpus
 * on this platform). Writable module param (0644) so the cpu2-vs-cpu0 causality
 * control can be flipped live via /sys/module/brcmfmac/parameters/brcmf_dpc_cpu
 * without a module reload. The mmc1 SDIO IRQ already runs on cpu2. */
static int brcmf_dpc_cpu = 2;
module_param(brcmf_dpc_cpu, int, 0644);
MODULE_PARM_DESC(brcmf_dpc_cpu, "CPU to steer brcmf_wq SDIO datawork to (default 2)");
EOF
LAST_INC=$(grep -nE '^#include' "$SDIO" | tail -1 | cut -d: -f1)
awk -v n="$LAST_INC" -v f=/tmp/param.txt 'NR==n{print; while((getline line < f)>0) print line; close(f); next}{print}' "$SDIO" > "$SDIO.new" && mv "$SDIO.new" "$SDIO"

# --- 2) alloc_ordered_workqueue -> alloc_workqueue (per-CPU bound, max_active=1) ---
sed -i 's@alloc_ordered_workqueue("brcmf_wq/%s", WQ_MEM_RECLAIM | WQ_HIGHPRI,@alloc_workqueue("brcmf_wq/%s", WQ_MEM_RECLAIM | WQ_HIGHPRI, 1,@' "$SDIO"

# --- 3) queue_work(bus->brcmf_wq,...) -> queue_work_on(brcmf_dpc_cpu, ...)  (alle 3) ---
sed -i 's@queue_work(bus->brcmf_wq, &bus->datawork);@queue_work_on(brcmf_dpc_cpu, bus->brcmf_wq, \&bus->datawork);@g' "$SDIO"

echo "=== DIFF (orig -> patched) ==="
diff -u "$SDIO.orig" "$SDIO" || true
echo "=== Marker-Check ==="
echo "  param:      $(grep -c 'brcmf_dpc_cpu' "$SDIO") Treffer (erwartet >=4: decl+param+desc+3xqueue)"
echo "  alloc neu:  $(grep -c 'alloc_workqueue("brcmf_wq' "$SDIO") (erwartet 1)"
echo "  alloc alt:  $(grep -c 'alloc_ordered_workqueue("brcmf_wq' "$SDIO") (erwartet 0)"
echo "  qwork_on:   $(grep -c 'queue_work_on(brcmf_dpc_cpu, bus->brcmf_wq' "$SDIO") (erwartet 3)"
echo "  qwork alt:  $(grep -c 'queue_work(bus->brcmf_wq' "$SDIO") (erwartet 0)"
echo PATCH-DONE
