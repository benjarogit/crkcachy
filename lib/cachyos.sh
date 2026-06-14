#!/usr/bin/env bash
# CachyOS / Arch detection

set -euo pipefail

check_cachyos() {
  local is_cachyos=false
  local is_arch=false

  if [[ -f /etc/cachyos-release ]] || grep -qi 'cachyos' /etc/os-release 2>/dev/null; then
    is_cachyos=true
  fi

  if grep -qi '^ID=arch' /etc/os-release 2>/dev/null || \
     grep -qi '^ID=cachyos' /etc/os-release 2>/dev/null; then
    is_arch=true
  fi

  if [[ "$is_cachyos" == "true" ]]; then
    log_ok "CachyOS detected."
    return 0
  fi

  if [[ "$is_arch" == "true" ]]; then
    log_warn "Arch-based system detected, but not CachyOS."
    log_warn "CRKCACHY is tested on CachyOS; package names may differ."
    return 1
  fi

  log_warn "Non-Arch system detected. CRKCACHY targets CachyOS/Arch."
  return 2
}

check_paru() {
  if command_exists paru; then
    log_ok "paru is available."
    return 0
  fi

  log_warn "paru not found. Install with: sudo pacman -S paru"
  return 1
}
