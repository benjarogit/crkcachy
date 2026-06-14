#!/usr/bin/env bash
# Linux platform detection – distro, package manager, safe install flags

set -euo pipefail

# Set by platform_detect()
PLATFORM_ID="unknown"
PLATFORM_ID_LIKE=""
PLATFORM_NAME="Linux"
PLATFORM_FAMILY="unknown"   # arch | debian | fedora | suse | unknown
PLATFORM_TIER="unsupported" # full | partial | unsupported
PLATFORM_PM="unknown"       # pacman | apt | dnf | zypper | unknown
PLATFORM_AUR_HELPER=""      # paru | yay | empty
PLATFORM_IS_CACHYOS=false
PLATFORM_PARU_HAS_REPO=false
PLATFORM_PM_DETECTED=false

platform_cmd_has_flag() {
  local cmd="$1"
  local flag="$2"
  local help

  if ! command_exists "$cmd"; then
    return 1
  fi

  help="$("$cmd" --help 2>&1 || true)"
  grep -qF -- "$flag" <<< "$help"
}

platform_is_arch_family() {
  [[ "$PLATFORM_FAMILY" == arch ]]
}

platform_has_package_manager() {
  [[ "$PLATFORM_PM" != unknown && -n "$PLATFORM_PM" ]]
}

platform_os_checklist_label() {
  if [[ "$PLATFORM_IS_CACHYOS" == true ]]; then
    msg runtime.item_os_cachyos
  elif [[ "$PLATFORM_TIER" == full ]]; then
    msgf runtime.item_os_arch "$PLATFORM_NAME"
  elif [[ "$PLATFORM_TIER" == partial ]]; then
    msgf runtime.item_os_other "$PLATFORM_NAME"
  else
    msgf runtime.item_os_unknown "$PLATFORM_NAME"
  fi
}

platform_os_check_ok() {
  case "$PLATFORM_TIER" in
    full|partial) return 0 ;;
    *) return 1 ;;
  esac
}

platform_gaming_stack_supported() {
  platform_is_arch_family
}

platform_probe_helpers() {
  PLATFORM_AUR_HELPER=""
  PLATFORM_PARU_HAS_REPO=false

  if command_exists paru; then
    PLATFORM_AUR_HELPER=paru
    if platform_cmd_has_flag paru --repo; then
      PLATFORM_PARU_HAS_REPO=true
    fi
    return 0
  fi

  if command_exists yay; then
    PLATFORM_AUR_HELPER=yay
  fi
}

platform_detect_package_manager() {
  PLATFORM_PM=unknown

  if command_exists pacman; then
    PLATFORM_PM=pacman
  elif command_exists apt-get; then
    PLATFORM_PM=apt
  elif command_exists apt; then
    PLATFORM_PM=apt
  elif command_exists dnf; then
    PLATFORM_PM=dnf
  elif command_exists zypper; then
    PLATFORM_PM=zypper
  fi

  [[ "$PLATFORM_PM" != unknown ]]
}

platform_detect_os_release() {
  local id id_like pretty

  PLATFORM_ID=unknown
  PLATFORM_ID_LIKE=""
  PLATFORM_NAME="Linux"
  PLATFORM_FAMILY=unknown
  PLATFORM_IS_CACHYOS=false

  if [[ ! -f /etc/os-release ]]; then
    return 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  id="${ID:-unknown}"
  id_like="${ID_LIKE:-}"
  pretty="${PRETTY_NAME:-$id}"

  PLATFORM_ID="${id,,}"
  PLATFORM_ID_LIKE="$id_like"
  PLATFORM_NAME="$pretty"

  if [[ -f /etc/cachyos-release ]] || [[ "$PLATFORM_ID" == cachyos ]]; then
    PLATFORM_IS_CACHYOS=true
    PLATFORM_FAMILY=arch
    PLATFORM_TIER=full
    return 0
  fi

  case "$PLATFORM_ID" in
    arch|manjaro|manjaro-linux|endeavouros|garuda|artix|hyperbola)
      PLATFORM_FAMILY=arch
      PLATFORM_TIER=full
      ;;
    debian|ubuntu|linuxmint|pop|elementary|zorin|kali|raspbian)
      PLATFORM_FAMILY=debian
      PLATFORM_TIER=partial
      ;;
    fedora|nobara|ultramarine)
      PLATFORM_FAMILY=fedora
      PLATFORM_TIER=partial
      ;;
    opensuse-leap|opensuse-tumbleweed|suse|opensuse)
      PLATFORM_FAMILY=suse
      PLATFORM_TIER=partial
      ;;
    *)
      if [[ "$id_like" == *arch* || "$id_like" == *archlinux* ]]; then
        PLATFORM_FAMILY=arch
        PLATFORM_TIER=full
      elif [[ "$id_like" == *debian* || "$id_like" == *ubuntu* ]]; then
        PLATFORM_FAMILY=debian
        PLATFORM_TIER=partial
      elif [[ "$id_like" == *fedora* || "$id_like" == *rhel* ]]; then
        PLATFORM_FAMILY=fedora
        PLATFORM_TIER=partial
      elif [[ "$id_like" == *suse* ]]; then
        PLATFORM_FAMILY=suse
        PLATFORM_TIER=partial
      fi
      ;;
  esac

  if [[ "$PLATFORM_FAMILY" == unknown ]]; then
    platform_detect_package_manager || true
    case "$PLATFORM_PM" in
      pacman) PLATFORM_FAMILY=arch; PLATFORM_TIER=full ;;
      apt) PLATFORM_FAMILY=debian; PLATFORM_TIER=partial ;;
      dnf) PLATFORM_FAMILY=fedora; PLATFORM_TIER=partial ;;
      zypper) PLATFORM_FAMILY=suse; PLATFORM_TIER=partial ;;
    esac
  fi

  return 0
}

platform_detect() {
  platform_detect_os_release || true
  platform_detect_package_manager || true
  platform_probe_helpers || true
  PLATFORM_PM_DETECTED=true
}

package_is_installed() {
  local pkg="$1"

  case "$PLATFORM_PM" in
    pacman)
      pacman -Q "$pkg" >/dev/null 2>&1
      ;;
    apt)
      dpkg -s "$pkg" >/dev/null 2>&1
      ;;
    dnf|zypper)
      rpm -q "$pkg" >/dev/null 2>&1
      ;;
    *)
      command_exists "$pkg"
      ;;
  esac
}

platform_build_repo_installer() {
  local -n _out=$1

  _out=()

  case "$PLATFORM_PM" in
    pacman)
      _out=(sudo pacman -S --needed --noconfirm)
      return 0
      ;;
    apt)
      _out=(sudo apt-get install -y)
      return 0
      ;;
    dnf)
      _out=(sudo dnf install -y)
      return 0
      ;;
    zypper)
      _out=(sudo zypper --non-interactive install)
      return 0
      ;;
  esac

  return 1
}

platform_build_full_installer() {
  local -n _out=$1

  _out=()

  if [[ "$PLATFORM_FAMILY" == arch && -n "$PLATFORM_AUR_HELPER" ]]; then
    _out=("$PLATFORM_AUR_HELPER" -S --needed --noconfirm)
    if [[ "$PLATFORM_AUR_HELPER" == paru && "$PLATFORM_PARU_HAS_REPO" == true ]]; then
      # Full install may include AUR – do not force --repo here.
      :
    fi
    return 0
  fi

  platform_build_repo_installer _out
}

platform_build_paru_repo_installer() {
  local -n _out=$1

  _out=()

  if [[ "$PLATFORM_AUR_HELPER" == paru ]]; then
    _out=(paru -S --needed --noconfirm)
    if [[ "$PLATFORM_PARU_HAS_REPO" == true ]]; then
      _out+=(--repo)
    fi
    return 0
  fi

  if [[ "$PLATFORM_AUR_HELPER" == yay ]]; then
    _out=(yay -S --needed --noconfirm)
    return 0
  fi

  platform_build_repo_installer _out
}

platform_manual_install_cmd() {
  local packages=("$@")
  local joined="${packages[*]}"

  case "$PLATFORM_PM" in
    pacman)
      echo "sudo pacman -S --needed ${joined}"
      ;;
    apt)
      echo "sudo apt install ${joined}"
      ;;
    dnf)
      echo "sudo dnf install ${joined}"
      ;;
    zypper)
      echo "sudo zypper install ${joined}"
      ;;
    *)
      if [[ -n "$PLATFORM_AUR_HELPER" ]]; then
        echo "${PLATFORM_AUR_HELPER} -S --needed ${joined}"
      else
        echo "# install: ${joined}"
      fi
      ;;
  esac
}

platform_log_summary() {
  local tier_label helper

  case "$PLATFORM_TIER" in
    full) tier_label="$(msg platform.tier_full)" ;;
    partial) tier_label="$(msg platform.tier_partial)" ;;
    *) tier_label="$(msg platform.tier_unsupported)" ;;
  esac

  helper=""
  if [[ -n "$PLATFORM_AUR_HELPER" ]]; then
    helper="$(msgf platform.helper "$PLATFORM_AUR_HELPER")"
  fi

  log_hint "$(msgf platform.detected "$PLATFORM_NAME" "$tier_label")"
  if [[ -n "$helper" ]]; then
    log_hint "$helper"
  fi
  if [[ "$PLATFORM_TIER" == partial ]]; then
    log_hint "$(msg platform.tier_partial_hint)"
    log_hint "$(msg platform.rosetta_hint)"
  fi
}

# shellcheck source=lib/platform_packages.sh
source "${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/platform_packages.sh"
