# Voraussetzungen

CRKCACHY zielt auf **CachyOS** mit **Steam** und **Proton-GE**. Diese Seite listet die erwartete Systembasis.

**English summary:** CachyOS (or Arch with caution), `paru`, Steam, GE-Proton via `protonup-rs`, Vulkan loaders, legal game files, self-applied fixes.

## Betriebssystem

| Komponente | Empfehlung |
|------------|------------|
| OS | CachyOS (getestet) |
| Arch (ohne CachyOS) | Warnung – Paketnamen können abweichen |
| `paru` | AUR-Helfer: `sudo pacman -S paru` |

## Steam

- Paket: `steam` (`paru -S steam`)
- Account eingeloggt
- **Overlay** aktiv: Einstellungen → Im Spiel
- Für Spacewar-Trick: **Spacewar (480)** installiert (`steam://install/480`)

Steam-Daten typisch unter: `~/.local/share/Steam/`

## Proton

- **GE-Proton** via `protonup-rs-bin`:
  ```bash
  protonup-rs -q --tool GEProton --version latest --for steam
  ```
- Optional GUI: `protonup-qt`
- Installationspfad: `~/.local/share/Steam/compatibilitytools.d/GE-Proton*`
- Alternative in Steam: `proton-cachyos-*` (CachyOS)

## Gaming-Runtime (paru)

Der Master-Installer schlägt vor:

```bash
paru -S --needed protonup-rs-bin vkd3d lib32-vkd3d lib32-gamemode gvfs winetricks
```

Optional: `protonup-qt`

## Vulkan (NVIDIA / AMD)

```bash
paru -S --needed vulkan-icd-loader lib32-vulkan-icd-loader
```

Zusätzlich GPU-spezifische Treiber (z. B. `nvidia-dkms`, `mesa`) wie auf CachyOS üblich.

## Spiele & Fixes

- **Legale Vollversion** oder vom Publisher erlaubte Demo
- Online-Fix nur **selbst** vom Fix-Autor – CRKCACHY liefert keine DLLs
- Extract-Ordner starten (`HouseOfAshes.exe` etc.) – kein Kopieren ins Repo

## Bottles (optional, nicht Standard)

CRKCACHY ist **Steam-first**. Bottles kann für Singleplayer hilfreich sein, ist aber nicht der dokumentierte Multiplayer-Pfad für House of Ashes. Siehe Troubleshooting.

## Recht

[legal.md](legal.md)
