#!/usr/bin/env bash
# GE-Proton via protonup-rs

set -euo pipefail

PROTON_GE_DIR="${HOME}/.local/share/Steam/compatibilitytools.d"
PROTONUP_TOOL="GEProton"

check_protonup() {
  if command_exists protonup-rs; then
    log_ok "protonup-rs found."
    return 0
  fi

  log_warn "protonup-rs not found. Install: paru -S protonup-rs-bin"
  return 1
}

list_ge_proton() {
  if [[ ! -d "$PROTON_GE_DIR" ]]; then
    return 1
  fi

  local found=0
  for dir in "$PROTON_GE_DIR"/GE-Proton*; do
    [[ -d "$dir" ]] || continue
    echo "  - $(basename "$dir")"
    found=1
  done

  return "$((found == 0))"
}

install_ge_proton() {
  require_command protonup-rs "Install: paru -S protonup-rs-bin"

  if confirm "Install latest GE-Proton for Steam via protonup-rs?"; then
    log_info "Running: protonup-rs -q --tool ${PROTONUP_TOOL} --version latest --for steam"
    protonup-rs -q --tool "$PROTONUP_TOOL" --version latest --for steam
    log_ok "protonup-rs finished."
  else
    log_warn "Skipped GE-Proton install."
    return 1
  fi

  if list_ge_proton; then
    log_ok "GE-Proton installations in compatibilitytools.d:"
    list_ge_proton
  else
    log_warn "No GE-Proton folder found in ${PROTON_GE_DIR}"
    return 1
  fi

  return 0
}

verify_ge_proton() {
  if list_ge_proton >/dev/null 2>&1; then
    log_ok "GE-Proton present in ${PROTON_GE_DIR}"
    return 0
  fi

  log_warn "No GE-Proton found. Run install step or use protonup-qt GUI."
  return 1
}
