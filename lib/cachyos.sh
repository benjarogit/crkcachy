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
    log_ok "$(msg cachyos.ok)"
    return 0
  fi

  if [[ "$is_arch" == "true" ]]; then
    log_warn "$(msg cachyos.arch_warn)"
    log_hint "$(msg cachyos.arch_hint)"
    return 1
  fi

  log_warn "$(msg cachyos.other_warn)"
  log_hint "$(msg cachyos.other_hint)"
  return 2
}

check_paru() {
  if command_exists paru; then
    log_ok "$(msg paru.ok)"
    return 0
  fi

  log_warn "$(msg paru.missing_warn)"
  log_hint "$(msg paru.install_hint)"
  return 1
}
