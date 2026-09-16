# Rust-Bausteine: exakte Fassungen und der komplette Quelltext

Hier liegt, was ein Build der Camados-Firmware Jahre später noch reproduzierbar
macht — und was die Quelltext-Zusage für die Rust-Seite abdeckt.

## Die `.lock`-Dateien

Eine je ausgeliefertem Programm. Sie nageln **jede** Abhängigkeit auf eine exakte
Fassung fest, mitsamt Prüfsumme. Das ist der eigentliche Kern: Solange diese
Dateien existieren, ist eindeutig, woraus ein Binary gebaut wurde — auch dann,
wenn eine Crate-Fassung inzwischen zurückgezogen wurde oder crates.io eines
Tages anders aussieht.

```bash
# Alle Abhängigkeiten eines Programms in exakt diesen Fassungen holen:
cp rust/camados-rs.Cargo.lock <dein-checkout>/camados-rs/Cargo.lock
cd <dein-checkout>/camados-rs && cargo fetch --locked
```

## Der vollständige Quelltext aller Abhängigkeiten

Zu jeder Firmware-Fassung liegt unter
[Releases](../../releases) ein Archiv `camados-rust-vendor-<Fassung>.tar.gz` —
der Quelltext **aller** Rust-Abhängigkeiten, wie `cargo vendor` ihn erzeugt.

```
196 Crates, 255 MB entpackt
```

Damit lässt sich ohne jede Netzverbindung bauen:

```bash
tar -xzf camados-rust-vendor-0.2.20.tar.gz
mkdir -p .cargo && cat > .cargo/config.toml <<'EOF'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "/pfad/zu/vendor-all"
EOF
cargo build --release --offline
```

## Warum wir das aufheben

Weil sonst niemand — wir eingeschlossen — in drei Jahren noch sagen kann, woraus
eine ausgelieferte Box eigentlich besteht. Die Lizenzen der Rust-Bausteine
(fast durchweg MIT oder Apache-2.0) verlangen keine Quelltext-Weitergabe; die
Nennung steht auf
[camados.com/pages/open-source](https://camados.com/pages/open-source).

Aufgehoben wird es trotzdem, aus einem praktischen Grund: Ein Build, der sich
nicht wiederholen lässt, ist ein Build, den man nicht untersuchen kann. Und
genau das braucht man an dem Tag, an dem etwas im Feld schiefgeht.
