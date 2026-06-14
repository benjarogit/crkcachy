# Contributing to CRKCACHY

Thank you for considering a contribution.

## What we accept

- New game tools (`tools/<name>/`) with README, `checks.sh`, `install.sh`, and launch options
- Improvements to installers and documentation (DE + EN where practical)
- Bug fixes for scripts on CachyOS / Arch

## What we do **not** accept

- Game files, repacks, or ROMs
- Crack or online-fix binaries (DLLs, `steam_api`, etc.)
- Links to illegal download sites
- Automated patching of third-party fix files

## Pull request checklist

- [ ] No copyrighted game assets or fix binaries in the diff
- [ ] Scripts are POSIX-friendly Bash, `shellcheck` clean where possible
- [ ] README documents manual Steam steps the script cannot automate
- [ ] `checks.sh` only **reads** user paths; never copies fix files
- [ ] Legal notice unchanged or appropriately extended

## Code style

- UI: use `lib/cui.sh` (logo, panels, `cui_yes_no`, `cui_choose`) – not raw `gum` in feature code
- Packages: use `lib/platform.sh` and logical names from `lib/platform_packages.sh` (`install_repo_packages`, `platform_resolve_package`) – never hard-code `pacman`/`paru` flags. See `docs/platform-rosetta.md`.
- Match existing `lib/common.sh` logging (`log_info`, `log_warn`, `confirm`)
- Interactive prompts default to safe choices (`[y/N]`)
- User paths via prompts, never hardcoded home directories in docs examples from your machine
