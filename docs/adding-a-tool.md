# Neues Tool hinzufügen

Template für Spiel-Tool #2 und weitere Einträge in CRKCACHY.

## Ordnerstruktur

```
tools/<game-slug>/
├── tool.json           # Metadaten (Name, exe, Steam-Name, Standardpfad)
├── README.md           # DE – vollständige Anleitung = Installation
├── README.en.md        # EN
├── install.sh          # Interaktiv: Pfad, Steam-Checkliste
├── checks.sh           # Nur Lesen: DLLs, ini, App-IDs
├── launch-options.txt  # Copy-Paste für Steam
├── lib.sh              # Optional: Konstanten aus tool.json
├── check.sh            # Prüfen / Validieren
├── uninstall.sh
└── reset.sh            # Optional: Test-Reset (nur CLI)
```

`<game-slug>`: Kleinbuchstaben, Bindestriche, z. B. `house-of-ashes`.

## Katalog (GitHub + lokal)

1. **`tools/index.json`** – zentrale Liste aller verfügbaren Tools (für Menü und Auto-Download)
2. **`tools/<game-slug>/tool.json`** – spielspezifische Infos

Beispiel `tool.json`:

```json
{
  "slug": "my-game",
  "name": { "de": "Mein Spiel", "en": "My Game" },
  "description": {
    "de": "Kurzbeschreibung für die Auswahl-Liste",
    "en": "Short description for the picker"
  },
  "game_exe": "MyGame.exe",
  "steam_display_name": "My Game",
  "desktop_slug": "my-game",
  "default_game_dir": ""
}
```

`default_game_dir` ist **optional** – leer lassen. CRKCACHY ermittelt den Pfad dynamisch:
letzter Pfad (`~/.local/share/crkcachy/tools/<slug>/last_game_dir`),
Steam-Verknüpfung, optionale Suche unter Games/Downloads/Laufwerken, oder User-Eingabe.

```json
{
  "slug": "my-game",
  "name": { "de": "Mein Spiel", "en": "My Game" },
  "description": { "de": "…", "en": "…" }
}
```

Der Master-`install.sh` bleibt **allgemein** – er erkennt:

- **lokal** – Tool liegt im Repo unter `tools/<slug>/`
- **heruntergeladen** – Tool wurde schon aus dem Cache geladen
- **von GitHub laden** – Tool nur im Katalog, wird bei Auswahl automatisch geholt

Kein manuelles Eintragen in `install.sh` nötig.

Sprachkeys `_MSG[tool.<slug>.name/desc]` in `lib/lang/*.sh` sind optional (Fallback, wenn kein `tool.json`).

## install.sh

- `source` aus `lib.sh` oder direkt `../../lib/common.sh`
- Spielpfad aus `tool.json` / User-Eingabe (kein Hardcode von User-Homes)
- `checks.sh` aufrufen
- Launch-Optionen aus `launch-options.txt`

## checks.sh

- Nur **read-only** Prüfungen
- Erwartete Pfade relativ zum Spielroot dokumentieren
- App-IDs in ini-Dateien prüfen (`FakeAppId`, `RealAppId`)
- Warnung bei konkurrierenden Fix-Stacks (FLT vs. Online-Fix)

## README

Jedes Tool-README muss enthalten:

1. Voraussetzungen (CRKCACHY Basis, Proton, Spacewar falls nötig)
2. **Selbst beschaffter** Fix – Pfade, keine Dateien im Repo
3. Steam-Schritte (manuell oder Automatik)
4. Launch-Optionen mit Erklärung
5. Multiplayer-Hinweise falls zutreffend
6. Kurze Fehlertabelle
7. Link zu `docs/troubleshooting.md`

## CLI

```bash
./install.sh --tools
./install.sh --install --tool=house-of-ashes
./install.sh --check --tool=house-of-ashes
```

## PR-Checklist

Siehe [CONTRIBUTING.md](../CONTRIBUTING.md):

- Keine DLLs/Exe/Crack im Diff
- `tool.json` + Eintrag in `tools/index.json`
- DE + EN README
- Legal-Hinweis unverändert oder erweitert
