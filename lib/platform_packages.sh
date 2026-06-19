#!/usr/bin/env bash
# Cross-distro package Rosetta – logical names → native package names
# Inspired by Arch Wiki Rosetta / Rosetta Stone patterns

set -euo pipefail

# Logical packages only available on Arch/CachyOS (AUR or arch-specific repos)
PLATFORM_ROSETTA_ARCH_ONLY=(
  paru
  protonup
)

# All logical package keys in the Rosetta table
PLATFORM_ROSETTA_LOGICAL=(
  nodejs
  glow
  steam
  paru
  winetricks
  vkd3d
  gamemode
  gvfs
  vulkan-loader
  protonup
  python-vdf
  icoutils
  imagemagick
)

platform_logical_known() {
  local logical="$1"
  local key
  for key in "${PLATFORM_ROSETTA_LOGICAL[@]}"; do
    [[ "$key" == "$logical" ]] && return 0
  done
  return 1
}

platform_logical_arch_only() {
  local logical="$1"
  local key
  for key in "${PLATFORM_ROSETTA_ARCH_ONLY[@]}"; do
    [[ "$key" == "$logical" ]] && return 0
  done
  return 1
}

# Returns space-separated native package names for logical name on current family.
# Empty return = not mapped (manual install on this distro).
platform_resolve_packages() {
  local logical="$1"
  local -a pkgs=()

  case "$logical" in
    nodejs)
      case "$PLATFORM_FAMILY" in
        arch|debian|fedora|suse) pkgs=(nodejs) ;;
      esac
      ;;
    glow)
      case "$PLATFORM_FAMILY" in
        arch|debian|fedora|suse) pkgs=(glow) ;;
      esac
      ;;
    steam)
      case "$PLATFORM_FAMILY" in
        arch|debian|fedora|suse) pkgs=(steam) ;;
      esac
      ;;
    paru)
      case "$PLATFORM_FAMILY" in
        arch) pkgs=(paru) ;;
      esac
      ;;
    winetricks)
      case "$PLATFORM_FAMILY" in
        arch|debian|fedora|suse) pkgs=(winetricks) ;;
      esac
      ;;
    vkd3d)
      case "$PLATFORM_FAMILY" in
        arch) pkgs=(vkd3d lib32-vkd3d) ;;
        fedora) pkgs=(vkd3d) ;;
        debian|suse) pkgs=() ;;
      esac
      ;;
    gamemode)
      case "$PLATFORM_FAMILY" in
        arch) pkgs=(gamemode lib32-gamemode) ;;
        debian) pkgs=(gamemode) ;;
        fedora) pkgs=(gamemode gamemode.i686) ;;
        suse) pkgs=(gamemode gamemode-32bit) ;;
      esac
      ;;
    gvfs)
      case "$PLATFORM_FAMILY" in
        arch|suse) pkgs=(gvfs) ;;
        debian) pkgs=(gvfs-backends) ;;
        fedora) pkgs=(gvfs) ;;
      esac
      ;;
    vulkan-loader)
      case "$PLATFORM_FAMILY" in
        arch) pkgs=(vulkan-icd-loader lib32-vulkan-icd-loader) ;;
        debian) pkgs=(libvulkan1 libvulkan1:i386) ;;
        fedora) pkgs=(vulkan-loader vulkan-loader.i686) ;;
        suse) pkgs=(libvulkan1 libvulkan1-32bit) ;;
      esac
      ;;
    protonup)
      case "$PLATFORM_FAMILY" in
        arch) pkgs=(protonup-rs-bin) ;;
      esac
      ;;
    python-vdf)
      case "$PLATFORM_FAMILY" in
        arch) pkgs=(python-vdf) ;;
        debian) pkgs=(python3-vdf) ;;
        fedora) pkgs=(python3-vdf) ;;
        suse) pkgs=(python3-vdf) ;;
      esac
      ;;
    icoutils)
      case "$PLATFORM_FAMILY" in
        arch|debian|fedora|suse) pkgs=(icoutils) ;;
      esac
      ;;
    imagemagick)
      case "$PLATFORM_FAMILY" in
        arch|debian|fedora|suse) pkgs=(imagemagick) ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac

  if [[ ${#pkgs[@]} -gt 0 ]]; then
    echo "${pkgs[*]}"
  fi
}

# Primary native package name (first part) – for simple single-package installs.
platform_resolve_package() {
  local logical="$1"
  local resolved

  if ! platform_logical_known "$logical"; then
    echo "$logical"
    return 0
  fi

  resolved="$(platform_resolve_packages "$logical")"
  if [[ -z "$resolved" ]]; then
    return 1
  fi

  echo "${resolved%% *}"
}

platform_logical_has_mapping() {
  local logical="$1"
  [[ -n "$(platform_resolve_packages "$logical")" ]]
}

platform_logical_installed() {
  local logical="$1"
  local resolved pkg

  resolved="$(platform_resolve_packages "$logical")"
  [[ -n "$resolved" ]] || return 1

  for pkg in $resolved; do
    package_is_installed "$pkg" || return 1
  done
  return 0
}

# Print missing logical package names (one per line).
platform_logical_packages_missing() {
  local logical
  for logical in "$@"; do
    if platform_logical_arch_only "$logical" && ! platform_is_arch_family; then
      continue
    fi
    if ! platform_logical_has_mapping "$logical"; then
      continue
    fi
    if ! platform_logical_installed "$logical"; then
      echo "$logical"
    fi
  done
}

# Human-readable label: logical (native1, native2)
platform_logical_display_name() {
  local logical="$1"
  local resolved

  resolved="$(platform_resolve_packages "$logical")"
  if [[ -z "$resolved" ]]; then
    echo "$logical"
    return 0
  fi

  echo "${logical} (${resolved// /, })"
}

platform_manual_install_cmd_logical() {
  local logical="$1"
  local -a pkgs=()

  if platform_logical_known "$logical"; then
    read -ra pkgs <<< "$(platform_resolve_packages "$logical")"
    if [[ ${#pkgs[@]} -gt 0 ]]; then
      platform_manual_install_cmd "${pkgs[@]}"
      return 0
    fi
  fi

  platform_manual_install_cmd "$logical"
}
