#!/usr/bin/env bash
set +e
cd /root
echo "=== deb-src fuer Pi-Repo + dpkg-dev ==="
cat >> /etc/apt/sources.list.d/raspi.sources <<'SRC'

Types: deb-src
URIs: http://archive.raspberrypi.com/debian/
Suites: trixie
Components: main
Trusted: yes
SRC
export DEBIAN_FRONTEND=noninteractive
apt-get install -y dpkg-dev >/dev/null 2>&1
echo "--- apt update (Sources?) ---"
apt-get update -o Acquire::Check-Valid-Until=false 2>&1 | grep -iE 'Sources|raspberrypi.com' | tail -4
echo "=== apt source linux=1:6.12.47-1+rpt1 ==="
apt-get source linux=1:6.12.47-1+rpt1 2>&1 | tail -10
echo "=== Ergebnis ==="
D=$(ls -d /root/linux-*/ 2>/dev/null | head -1)
if [ -n "$D" ]; then
  echo "APT-SOURCE-OK: $D"
  ls "$D/drivers/net/wireless/broadcom/brcm80211/brcmfmac/sdio.c" && echo "SDIO-C-DA"
else
  echo "APT-SOURCE-FEHLT (Pi-Repo evtl. ohne Sources)"
fi
