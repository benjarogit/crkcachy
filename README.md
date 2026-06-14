# CRKCACHY – So geht’s (einfach)

**CRKCACHY** hilft dir, **Standalone- und Portable-Spiele** über **Steam + Proton** zu nutzen – ohne Bottles oder Wineboot.  
Kein Spiel im Paket: Anleitung, Checks, Mods und Community-Fixes.

> Nur Hilfe, kein Crack. [Rechtliches](docs/legal.md)  
> **English:** [README.en.md](README.en.md)

---

## Schritt 1 – Konsole öffnen

**Ctrl + Alt + T** oder im Menü **Konsole** suchen.

---

## Schritt 2 – CRKCACHY holen (einmal)

```bash
git clone https://github.com/benjarogit/crkcachy.git
cd crkcachy
chmod +x install.sh lib/*.sh tools/*/install.sh tools/*/checks.sh
```

---

## Schritt 3 – Starten

```bash
./install.sh
```

Das Programm:

1. richtet bei Bedarf **Pfeil-Menü** und **Anleitung-Leser** ein (einmal, mit deiner Erlaubnis)  
2. prüft deinen **PC**  
3. hilft beim **Spiel in Steam**

**Pfeiltasten** = auswählen · **Enter** = bestätigen

---

## Nur ansehen (ohne Spiel-Setup)

```bash
./install.sh --status
```

---

## House of Ashes

[tools/house-of-ashes/README.md](tools/house-of-ashes/README.md)

---

## Hilfe

- [Voraussetzungen](docs/prerequisites.md)
- [Troubleshooting](docs/troubleshooting.md)

## Lizenz

MIT – [LICENSE](LICENSE)
