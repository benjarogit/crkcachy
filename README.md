# CRKCACHY – So geht’s (einfach)

**CRKCACHY** bringt **Windows-Spiele auf Linux** – über **Steam + Proton**, ohne Bottles.  
Kein Spiel dabei: Setup-Hilfe, Ordner-Check (nur lesen), Mods und Fixes.  
**Keine Spieldateien, keine Fix-Downloads** – du legst Dateien selbst in den Ordner.

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

1. richtet **Menü** und **Anleitungen** ein (einmal, mit Bestätigung)  
2. prüft deinen **PC**  
3. richtet dein **Spiel in Steam** ein

**Pfeiltasten** = auswählen · **Enter** = bestätigen

**Direkt (Spiel-Tool):**

```bash
./install.sh --tools       # Tool + Aktion wählen
./install.sh --install     # installieren
./install.sh --uninstall   # deinstallieren
./install.sh --check       # prüfen (inkl. Steam-Validierung)
```

---

## Nur ansehen (ohne Spiel-Setup)

```bash
./install.sh --status
```

---

## House of Ashes

Pfad-Hilfe und Steam-Automatik für **TDPAHOA_Fix_Repair_Steam_Generic** (von dir selbst eingelegt).  
[tools/house-of-ashes/README.md](tools/house-of-ashes/README.md)

---

## Hilfe

- [Voraussetzungen](docs/prerequisites.md)
- [Troubleshooting](docs/troubleshooting.md)

## Lizenz

MIT – [LICENSE](LICENSE)
