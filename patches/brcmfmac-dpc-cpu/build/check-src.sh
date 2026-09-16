#!/usr/bin/env bash
echo "=== showsrc linux (Package/Version/Binary) ==="
apt-cache showsrc linux 2>&1 | grep -iE '^(Package|Version|Binary):' | head -12
echo "=== welche source-version wuerde apt holen ==="
apt-get source --print-uris linux 2>&1 | grep -oE "linux[_-][0-9][^ ']*" | head -6
echo "=== pool: exakte 6.12.47 source-dateien (HTTP-code) ==="
for f in linux_6.12.47-1+rpt1.dsc linux_6.12.47.orig.tar.xz linux_6.12.47.orig.tar.gz linux_6.12.47-1+rpt1.debian.tar.xz; do
  url="http://archive.raspberrypi.com/debian/pool/main/l/linux/$f"
  code=$(wget -S --spider "$url" 2>&1 | awk '/HTTP\//{print $2}' | tail -1)
  echo "  $f -> ${code:-keine}"
done
