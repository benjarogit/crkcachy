# Neues Tool hinzufügen

Template für Spiel-Tool #2 und weitere Einträge in CRKCACHY.

## Ordnerstruktur

```
tools/<game-slug>/
├── README.md           # DE – vollständige Anleitung = Installation
├── README.en.md        # EN
├── install.sh          # Interaktiv: Pfad, Steam-Checkliste
├── checks.sh           # Nur Lesen: DLLs, ini, App-IDs
└── launch-options.txt  # Copy-Paste für Steam
```

`<game-slug>`: Kleinbuchstaben, Bindestriche, z. B. `house-of-ashes`.

## install.sh

- `source` aus `../../lib/common.sh` (und bei Bedarf `steam.sh`, `proton.sh`)
- Spielpfad abfragen (kein Hardcode von User-Homes in Skripten)
- `checks.sh` aufrufen
- Manuelle Steam-Schritte ausgeben (kein `shortcuts.vdf` editieren)
- Launch-Optionen aus `launch-options.txt` anzeigen

## checks.sh

- Nur **read-only** Prüfungen
- Erwartete Pfade relativ zum Spielroot dokumentieren
- App-IDs in ini-Dateien prüfen (`FakeAppId`, `RealAppId`)
- Warnung bei konkurrierenden Fix-Stacks (FLT vs. Online-Fix)
- Exit-Code 0/1 für CI optional

## README

Jedes Tool-README muss enthalten:

1. Voraussetzungen (CRKCACHY Basis, Proton, Spacewar falls nötig)
2. **Selbst beschaffter** Fix – Pfade, keine Dateien im Repo
3. Steam-Schritte (manuell)
4. Launch-Optionen mit Erklärung
5. Multiplayer-Hinweise falls zutreffend
6. Kurze Fehlertabelle
7. Link zu `docs/troubleshooting.md`

## Master-Installer

`tools/*/install.sh` wird automatisch in `install.sh` Menü gelistet (`list_tools` / `run_tool_menu`).

## App-IDs dokumentieren

| Feld | Beispiel (House of Ashes) |
|------|---------------------------|
| RealAppId | 1281590 |
| FakeAppId | 480 (Spacewar) |
| SteamAppId in Launch | 480 |

## PR-Checklist

Siehe [CONTRIBUTING.md](../CONTRIBUTING.md):

- Keine DLLs/Exe/Crack im Diff
- DE + EN README
- Legal-Hinweis unverändert oder erweitert

## English

For English-only docs, mirror structure in `README.en.md`. Shared docs (`prerequisites.md`, `troubleshooting.md`) may stay bilingual sections or link to EN tool READMEs.
