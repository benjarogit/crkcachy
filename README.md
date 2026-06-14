# CRKCACHY

[![CachyOS](https://img.shields.io/badge/CachyOS-ready-blue)](https://cachyos.org/)
[![Steam](https://img.shields.io/badge/Steam-required-1b2838)](https://store.steampowered.com/)
[![Proton-GE](https://img.shields.io/badge/Proton-GE-supported-4c1)](https://github.com/GloriousEggroll/proton-ge-custom)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**CRKCACHY** ist eine Tool-Sammlung für **CachyOS** mit **Steam**: interaktive Bash-Installer für System-Abhängigkeiten und Proton, plus ausführliche Anleitungen pro Spiel.

> **Kein Spiel, kein Crack, kein Online-Fix** – nur Setup, Prüfungen und der dokumentierte Weg. Siehe [docs/legal.md](docs/legal.md).

**English:** [README.en.md](README.en.md)

## Quick Start

```bash
git clone https://github.com/benjarogit/crkcachy.git
cd crkcachy
chmod +x install.sh lib/*.sh tools/*/install.sh tools/*/checks.sh
./install.sh
```

Der Master-Installer:

1. Prüft CachyOS / `paru` / Steam
2. Installiert empfohlene Pakete (Vulkan, Protonup, Gaming-Runtime)
3. Installiert **GE-Proton** via `protonup-rs`
4. Prüft **Spacewar (App 480)** für Steam-Tricks
5. Startet optional ein Spiel-Tool (z. B. House of Ashes)

## Verfügbare Tools

| Tool | Beschreibung |
|------|--------------|
| [house-of-ashes](tools/house-of-ashes/) | The Dark Picture Anthology: House of Ashes – Proton + Online-Fix-Setup |

## Repository-Struktur

```
crkcachy/
├── install.sh              # Master-Installer
├── lib/                    # Gemeinsame Bash-Bibliothek
├── tools/<spiel>/           # Pro Spiel: README, install.sh, checks.sh
└── docs/                   # Legal, Prerequisites, Troubleshooting
```

## Voraussetzungen

- [CachyOS](https://cachyos.org/) (oder Arch mit Warnung)
- `paru` als AUR-Helfer
- Steam installiert und eingeloggt
- Legale Spieldateien + selbst beschaffter Online-Fix (falls Multiplayer)

Details: [docs/prerequisites.md](docs/prerequisites.md)

## Troubleshooting

[docs/troubleshooting.md](docs/troubleshooting.md) – Trial-Modus, Invites, Overlay, Runtime-Download.

## Neues Tool hinzufügen

[docs/adding-a-tool.md](docs/adding-a-tool.md)

## Lizenz

MIT – siehe [LICENSE](LICENSE).
