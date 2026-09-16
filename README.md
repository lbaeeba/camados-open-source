# Camados — Open Source

Camados-Lautsprecher laufen zu einem großen Teil auf freier Software. Dieses Repo
enthält, was die Lizenzen dieser Software bei der Weitergabe eines Geräts verlangen:
**die genaue Liste dessen, was ausgeliefert wird, und den Quelltext unserer eigenen
Änderungen daran.**

Die lesbare Übersicht mit allen Projekten steht auf
[camados.com/pages/open-source](https://camados.com/pages/open-source).

---

## Was hier liegt

| Ordner | Inhalt |
|---|---|
| [`pakete/`](pakete/) | Jedes Paket und jeder Baustein der ausgelieferten Firmware — mit exakter Fassung und Lizenz |
| [`patches/`](patches/) | Unsere Änderungen an fremder Software, mit vollständiger Bauanleitung |

Die Listen sind **gemessen, nicht aufgeschrieben**: `dpkg-query` auf einer laufenden
Box und `cargo metadata` über alle ausgelieferten Programme. Deshalb trägt jede Datei
die Firmware-Fassung im Namen, zu der sie gehört.

---

## Quelltext eines bestimmten Pakets bekommen

Fast alles auf der Box kommt unverändert aus Debian und Raspberry Pi OS. Die
Versionsliste in [`pakete/`](pakete/) nennt für jedes Paket die exakte Fassung — damit
lässt sich der zugehörige Quelltext eindeutig beschaffen:

```bash
# Fassung im Manifest nachschlagen
grep '^chrony' pakete/box-pakete-0.2.18.tsv
#   chrony   4.6.1-3+deb13u1   GPL-2   https://chrony-project.org/

# Quelltext genau dieser Fassung holen (snapshot.debian.org archiviert sie dauerhaft)
apt-get source chrony=4.6.1-3+deb13u1
```

Kommst du damit nicht weiter, schreib an **info@camados.com** mit dem Stichwort
*Quelltext* und der Fassung, die auf deiner Box läuft. Du bekommst einen Download-Link.
Dieses Angebot gilt für drei Jahre ab dem Kauf deiner Box.

---

## Unsere eigenen Änderungen

**[`patches/brcmfmac-dpc-cpu/`](patches/brcmfmac-dpc-cpu/)** — ein Patch am WLAN-Treiber
des Linux-Kernels. Er bindet die SDIO-Datenarbeit an einen festen CPU-Kern, damit sie
dem Echtzeit-Audio nicht in die Quere kommt. Der Kernel steht unter GPL-2, also gehört
diese Änderung veröffentlicht.

Der Ordner enthält die vollständige Pipeline: Quelltext holen, patchen, bauen,
installieren — dieselben Skripte, mit denen wir das Modul selbst erzeugen.

Das ist derzeit die **einzige** Änderung an fremder Software, die wir ausliefern.
Kommt eine dazu, kommt sie hierher.

---

## Was hier bewusst nicht liegt

Unsere eigene Software — der Audio-Client, die Gruppensteuerung, die Cloud-Dienste,
die App und die Webseite. Diese Programme stehen unter keiner Copyleft-Lizenz und
müssen es auch nicht:

* Sie laufen als **eigene Prozesse** neben den GPL-Programmen der Box und reden mit
  ihnen über Konfigurationsdateien, systemd und D-Bus. Das macht sie nicht zu
  abgeleiteten Werken.
* Die einzige Bibliothek, gegen die wir tatsächlich linken, ist **ALSA** — und die
  steht unter LGPL, die genau das erlaubt. Wir binden sie **dynamisch** ein
  (`readelf -d` zeigt `libasound.so.2`), sodass sie sich austauschen lässt.
* Die einkompilierten C-Bibliotheken **libopus** und **libsamplerate** stehen unter
  BSD-Lizenzen, die nur die Nennung verlangen — die steht auf der Webseite.

Wir schreiben das hin, weil die Frage berechtigt ist und eine klare Antwort verdient.

---

## English

Camados speakers run largely on free software. This repository holds what the licences
require when a device is distributed: the exact manifest of everything shipped, and the
source of our own modifications to third-party code.

* [`pakete/`](pakete/) — every package and build component of the shipped firmware, with
  exact version and licence. Measured from a running device, not compiled by hand.
* [`patches/`](patches/) — our modifications. Currently one: a Linux kernel WiFi driver
  patch pinning SDIO work to a fixed CPU core, with the full build pipeline.

For the source of any individual package, look up its exact version in the manifest and
fetch it from Debian (`snapshot.debian.org` archives every version permanently). If that
does not work for you, write to **info@camados.com** quoting *Quelltext* and your
firmware version; you will receive a download link. This offer is valid for three years
from the purchase of your device.

A human-readable overview of every project involved is at
[camados.com/pages/open-source](https://camados.com/pages/open-source).
