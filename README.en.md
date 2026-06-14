# CRKCACHY

[![CachyOS](https://img.shields.io/badge/CachyOS-ready-blue)](https://cachyos.org/)
[![Steam](https://img.shields.io/badge/Steam-required-1b2838)](https://store.steampowered.com/)
[![Proton-GE](https://img.shields.io/badge/Proton-GE-supported-4c1)](https://github.com/GloriousEggroll/proton-ge-custom)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**CRKCACHY** is a tool collection for **CachyOS** with **Steam**: interactive Bash installers for system dependencies and Proton, plus detailed per-game guides.

> **No game, no crack, no online-fix files** – only setup, checks, and documented steps. See [docs/legal.en.md](docs/legal.en.md).

**Deutsch:** [README.md](README.md)

## Quick Start

```bash
git clone https://github.com/benjarogit/crkcachy.git
cd crkcachy
chmod +x install.sh lib/*.sh tools/*/install.sh tools/*/checks.sh
./install.sh
```

The master installer:

1. Checks CachyOS / `paru` / Steam
2. Installs recommended packages (Vulkan, Protonup, gaming runtime)
3. Installs **GE-Proton** via `protonup-rs`
4. Verifies **Spacewar (App 480)** for Steam tricks
5. Optionally runs a game tool (e.g. House of Ashes)

## Available tools

| Tool | Description |
|------|-------------|
| [house-of-ashes](tools/house-of-ashes/) | The Dark Picture Anthology: House of Ashes – Proton + online-fix setup |

## Repository layout

```
crkcachy/
├── install.sh              # Master installer
├── lib/                    # Shared Bash library
├── tools/<game>/           # Per game: README, install.sh, checks.sh
└── docs/                   # Legal, prerequisites, troubleshooting
```

## Prerequisites

- [CachyOS](https://cachyos.org/) (or Arch with warning)
- `paru` as AUR helper
- Steam installed and logged in
- Legal game files + self-sourced online fix (for multiplayer)

Details: [docs/prerequisites.md](docs/prerequisites.md)

## Troubleshooting

[docs/troubleshooting.md](docs/troubleshooting.md) – trial mode, invites, overlay, runtime download.

## Adding a new tool

[docs/adding-a-tool.md](docs/adding-a-tool.md)

## License

MIT – see [LICENSE](LICENSE).
