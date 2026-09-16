#!/usr/bin/env bash
set -e
KREL=6.12.47+rpt-rpi-v8-rt
echo "=== arch ==="; uname -m; dpkg --print-architecture
echo "=== Pi-Repo (trixie main, trusted fuer Throwaway-Container) ==="
cat > /etc/apt/sources.list.d/raspi.sources <<'SRC'
Types: deb
URIs: http://archive.raspberrypi.com/debian/
Suites: trixie
Components: main
Trusted: yes
SRC
export DEBIAN_FRONTEND=noninteractive
echo "=== apt update ==="
apt-get update -o Acquire::Check-Valid-Until=false 2>&1 | tail -3
echo "=== build-tools + EXAKTE rt-header installieren ==="
apt-get install -y --no-install-recommends \
  build-essential bc bison flex libssl-dev libelf-dev kmod cpio wget xz-utils git \
  "linux-headers-${KREL}" 2>&1 | tail -6
echo "=== header-build-dir da? ==="
ls -ld /lib/modules/$KREL/build
test -f /lib/modules/$KREL/build/Module.symvers && echo "SYMVERS-OK" || echo "SYMVERS-FEHLT"
echo "=== config-flags (muessen PREEMPT_RT=y + SMP=y) ==="
CFG=/lib/modules/$KREL/build/.config
if [ -f "$CFG" ]; then grep -E '^CONFIG_PREEMPT_RT=|^CONFIG_SMP=|^CONFIG_MODVERSIONS=' "$CFG"; else echo "(.config fehlt -> $CFG)"; fi
echo "=== vermagic-Ziel (kernel.release) ==="
cat /lib/modules/$KREL/build/include/config/kernel.release 2>/dev/null || true
echo "=== aarch64-toolchain native (kein cross noetig) ==="
gcc --version | head -1
echo "SETUP-DONE"
