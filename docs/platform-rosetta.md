# Platform Rosetta – cross-distro package names

CRKCACHY uses **logical package names** in scripts and maps them to native package
manager names per distro family. This follows the idea of the
[Arch Wiki Rosetta](https://wiki.archlinux.org/title/Rosetta) and
[Rosetta Stone](https://wiki.archlinux.org/title/Rosetta_Stone) pages.

Implementation: `lib/platform_packages.sh`

## API (for contributors)

| Function | Purpose |
|----------|---------|
| `platform_resolve_package logical` | Primary native name (first part) |
| `platform_resolve_packages logical` | All native names (space-separated) |
| `platform_logical_installed logical` | True if all mapped packages are installed |
| `platform_logical_packages_missing …` | Prints missing logical names (one per line) |
| `platform_logical_arch_only logical` | True for Arch-only entries (paru, protonup) |
| `platform_manual_install_cmd_logical logical` | Manual install hint for current PM |

Empty mapping = **manual only** on that distro (no auto-install attempted).

## Mapping table

| Logical | Arch / CachyOS | Debian / Ubuntu | Fedora | openSUSE | Arch-only |
|---------|----------------|-----------------|--------|----------|-----------|
| `gum` | `gum` | — | `gum` | — | no |
| `glow` | `glow` | `glow` | `glow` | `glow` | no |
| `steam` | `steam` | `steam` | `steam` | `steam` | no |
| `paru` | `paru` | — | — | — | **yes** |
| `winetricks` | `winetricks` | `winetricks` | `winetricks` | `winetricks` | no |
| `vkd3d` | `vkd3d`, `lib32-vkd3d` | — | `vkd3d` | — | no |
| `gamemode` | `gamemode`, `lib32-gamemode` | `gamemode` | `gamemode`, `gamemode.i686` | `gamemode`, `gamemode-32bit` | no |
| `gvfs` | `gvfs` | `gvfs-backends` | `gvfs` | `gvfs` | no |
| `vulkan-loader` | `vulkan-icd-loader`, `lib32-vulkan-icd-loader` | `libvulkan1`, `libvulkan1:i386` | `vulkan-loader`, `vulkan-loader.i686` | `libvulkan1`, `libvulkan1-32bit` | no |
| `protonup` | `protonup-rs-bin` | — | — | — | **yes** (AUR) |

**—** = no confirmed Repology mapping; assess reports `pkg_manual` on partial-support distros.

## Adding a mapping

1. Add the logical name to `PLATFORM_ROSETTA_LOGICAL` in `lib/platform_packages.sh`.
2. Extend the `platform_resolve_packages` case block for each family.
3. If Arch-only, add to `PLATFORM_ROSETTA_ARCH_ONLY`.
4. Update this table.
5. Run `bash -n lib/platform_packages.sh`.

Verify names on [Repology](https://repology.org/) before adding uncertain entries.

## Assessment behaviour

- **Full (Arch/CachyOS):** all logical packages checked; AUR helper used for installs.
- **Partial (Debian/Fedora/SUSE):** mapped packages checked with native names; arch-only
  packages get `arch_only:*` issues; unmapped get `pkg_manual:*`.
