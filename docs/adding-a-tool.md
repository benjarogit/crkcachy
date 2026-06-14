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

## Plugin-Liste (automatisch)

Der Master-Installer scannt `tools/*/install.sh` – **kein** manuelles Eintragen in `install.sh` nötig.

Für Namen in der Auswahl-Liste in **beiden** Sprachdateien ergänzen:

- `lib/lang/de.sh`: `_MSG[tool.<game-slug>.name]` und `_MSG[tool.<game-slug>.desc]`
- `lib/lang/en.sh`: dieselben Keys auf Englisch

Beispiel:

```bash
_MSG[tool.my-game.name]="Mein Spiel"
_MSG[tool.my-game.desc]="Kurzbeschreibung für die Liste"
```

Danach erscheint das Spiel in `./install.sh` → Option 1 oder 3.

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

`tools/*/install.sh` wird automatisch gefunden (`lib/tools.sh`). Mehrere Spiele: User wählt nacheinander oder `a` für alle.

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
