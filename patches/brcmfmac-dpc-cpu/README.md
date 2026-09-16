<!-- Oeffentliche Fassung. Dieser Patch aendert den Linux-Kernel (GPL-2);
     deshalb muss sein Quelltext mit dem Geraet weitergegeben werden. -->

# brcmfmac-Patch: SDIO-Datawork auf einen isolierten Kern (`brcmf_dpc_cpu`)

Der Broadcom-WLAN-Treiber schiebt seine SDIO-Datenarbeit auf einen beliebigen Kern. Auf einer
Box, die nebenher Echtzeit-Audio verteilt, kollidiert das mit dem Sender. Dieser Patch pinnt die
Datawork fest auf einen Kern (Standard: **cpu2**, isoliert per `isolcpus=2,3`).

Gemessene Wirkung: die kontinuierliche Mesh-Drift ist weg. 4-Stunden-Test, 2895 Messpunkte:
**p50 0,043 ms / p99 0,207 / max 0,391**, zwei Ausreißer über 0,3 ms, `silence_fill=0`.
Die Messreihen dazu liegen in unserem internen Entwicklungs-Repo; die Zahlen oben sind daraus übernommen.

## Was der Patch ändert

Genau drei Stellen in `drivers/net/wireless/broadcom/brcm80211/brcmfmac/sdio.c`
(`build/patch-wq.sh`, mit Marker-Prüfung am Ende):

1. **Neuer Modulparameter** `brcmf_dpc_cpu` (Default 2, Modus `0644`) — zur Laufzeit
   schreibbar über `/sys/module/brcmfmac/parameters/brcmf_dpc_cpu`. Das war Absicht: so lässt
   sich cpu2-gegen-cpu0 als Kausalitätstest umschalten, ohne das Modul neu zu laden.
2. `alloc_ordered_workqueue("brcmf_wq/%s", …)` → `alloc_workqueue(…, 1, …)` — die Queue muss
   **per-CPU gebunden** sein, sonst geht das Pinnen ins Leere.
3. Dreimal `queue_work(bus->brcmf_wq, &bus->datawork)` → `queue_work_on(brcmf_dpc_cpu, …)`
   in `brcmf_sdio_trigger_dpc`, `brcmf_sdio_isr`, `brcmf_sdio_bus_watchdog`.

## Neu bauen (nach einem Kernelwechsel)

Läuft in einem Wegwerf-Container unter **arm64-Emulation** — das Ergebnis ist ein nativer
aarch64-Build, deshalb stimmt die `vermagic` exakt.

> ⚠️ **Docker Desktop startet Lars**, nicht das Skript und nicht Claude — automatisches Starten
> bringt die Engine hier reproduzierbar zum Absturz.
>
> ⚠️ Nicht mit dem Rust-Build verwechseln: die aarch64-**Rust**-Binaries werden ohne
> `--platform` in `rust:1.85-bookworm` gebaut (dort hängt die Emulation). Für das **Kernelmodul**
> ist die Emulation genau richtig und beabsichtigt.

```bash
docker run -dit --platform linux/arm64 --name brcmf-build debian:trixie
# dann der Reihe nach, jedes Skript endet mit einem eigenen ...-DONE-Marker:
#   setup.sh      Pi-Repo + exakte linux-headers-<KREL> (prüft PREEMPT_RT/SMP/MODVERSIONS)
#   source.sh     Versuch über apt source  (darf fehlschlagen — Pi-Repo führt oft keine Sources)
#   get-src.sh    Fallback: orig+debian-Tarball direkt aus dem Pool, brcm80211 selektiv
#   apply-rpi.sh  die brcm80211-Hunks aus debian/patches/rpi/rpi.patch via filterdiff
#   patch-wq.sh   UNSER Eingriff (siehe oben) + Marker-Prüfung
#   build.sh      make -C /lib/modules/$KREL/build M=<brcm80211> modules
#   inspect.sh    Abnahme
```

**Abnahmekriterium** (`build.sh` gibt es am Ende aus — nicht überspringen):

```
vermagic: 6.12.47+rpt-rpi-v8-rt SMP preempt_rt mod_unload modversions aarch64
depends:  brcmutil,cfg80211
parm:     brcmf_dpc_cpu:CPU to steer brcmf_wq SDIO datawork to (default 2)
```

Stimmt die `vermagic` nicht, lädt das Modul nicht — und `modprobe` sagt nur „Invalid module
format", nicht warum. Niemals mit `--force` nachhelfen.

## Was hier liegt

| Pfad | Inhalt |
|---|---|
| `build/` | die komplette Pipeline + `setup.log`/`build.log` des Originallaufs (21.06.2026) |
| `artifacts/` | die gebauten Module + `modules.sha256` |
| `stock-backup/` | die unveränderten Debian-Module derselben Kernelversion + `SHA256SUMS` |

`artifacts/brcmfmac.ko` = `571ec684cab4e4792f5fd075e4e615fb882bbaea713ada8a78cbbd34ba0aa3d1`.
Am 2026-07-28 gegengeprüft: **byte-identisch** mit dem, was auf FR und 108 unter
`/lib/modules/6.12.47+rpt-rpi-v8-rt/updates/` geladen ist.

## Installieren und zurückbauen

Installiert wird per Tree-Install — `updates/` hat Vorrang vor `kernel/`:

```bash
sudo install -m0644 artifacts/brcmfmac.ko /lib/modules/$(uname -r)/updates/
sudo depmod -a && sudo reboot
```

Der Kern-Parameter kommt aus `/etc/modprobe.d/` (`options brcmfmac brcmf_dpc_cpu=2`).

Zurück auf Stock: die Dateien aus `stock-backup/` zurückspielen, oder schlicht
`updates/brcmfmac.ko` entfernen und `depmod -a` — dann greift wieder das Modul aus `kernel/`.

## Offene Punkte für das Golden-Image

1. **Kernel festnageln, und zwar einheitlich.** Heute sichert sich jede Box anders ab: FR
   maskiert `apt-daily-upgrade.timer`, hält aber kein Paket; 108 hält
   `linux-image-6.12.47+rpt-rpi-v8-rt`, lässt den Timer aber laufen — und hat sich darüber
   bereits Kernel 6.18.34 eingefangen. Beide Maßnahmen gehören ins Image, aus einer Quelle.
2. **Der Rückfall ist stumm.** Passt das Modul nicht zum laufenden Kernel, lädt klaglos der
   Stock-Treiber, `brcmf_dpc_cpu` verschwindet, die Datawork wandert zurück auf einen
   beliebigen Kern. Kein Fehler, keine Meldung — nur schlechterer Sync. Deshalb: **zur Laufzeit
   prüfen**, dass der Parameter existiert und seinen Wert hat, und das nach `/status` melden.
3. **DKMS erwägen**, damit ein Kernel-Update das Modul neu baut statt es zu verlieren.

## Kern-Karte (aus dem Messbericht §4f, dort bewiesen)

```
cpu0   Dongle + Quellen (xhci-IRQ, rtw-WQ, librespot …)
cpu1   brcmf-Mesh-IRQ, allein
cpu2   brcmf-Datawork  ← dieser Patch
cpu3   Sender-RT + arecord
```

⚠️ `mmc1`-IRQ und Datawork dürfen **nicht** denselben Kern teilen: der RT-IRQ (prio 90) hungert
den Worker aus, das erzeugte reproduzierbar ~12-ms-Spitzen. Der IRQ gehört auf **cpu1**.
