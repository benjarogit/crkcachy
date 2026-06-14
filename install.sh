#!/usr/bin/env bash
# CRKCACHY master installer – system baseline for CachyOS + Steam gaming

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$SCRIPT_DIR"

# shellcheck source=lib/common.sh
source "${CRKCACHY_ROOT}/lib/common.sh"
# shellcheck source=lib/cachyos.sh
source "${CRKCACHY_ROOT}/lib/cachyos.sh"
# shellcheck source=lib/steam.sh
source "${CRKCACHY_ROOT}/lib/steam.sh"
# shellcheck source=lib/proton.sh
source "${CRKCACHY_ROOT}/lib/proton.sh"

BASE_PACKAGES=(
  protonup-rs-bin
  vkd3d
  lib32-vkd3d
  lib32-gamemode
  gvfs
  winetricks
)

OPTIONAL_PACKAGES=(
  protonup-qt
)

VULKAN_PACKAGES=(
  vulkan-icd-loader
  lib32-vulkan-icd-loader
)

preflight() {
  log_info "=== Preflight ==="
  check_cachyos || true
  check_paru || true
  check_steam || true
  echo ""
}

install_base_packages() {
  log_info "=== Base packages (paru) ==="
  install_packages_paru "${BASE_PACKAGES[@]}" || true

  if confirm "Also install optional protonup-qt (GUI)?"; then
    install_packages_paru "${OPTIONAL_PACKAGES[@]}" || true
  fi

  if confirm "Install Vulkan ICD loaders (recommended for NVIDIA/AMD)?"; then
    install_packages_paru "${VULKAN_PACKAGES[@]}" || true
  fi

  if ! pacman_installed steam; then
    log_warn "Steam is not installed."
    if confirm "Try installing steam via paru now?"; then
      install_packages_paru steam || true
    fi
  fi
  echo ""
}

setup_proton() {
  log_info "=== GE-Proton ==="
  if check_protonup; then
  if verify_ge_proton; then
    if confirm "GE-Proton already present. Re-install/update latest?"; then
      install_ge_proton || true
    fi
  else
    install_ge_proton || true
  fi
  else
    log_warn "Install protonup-rs-bin first, then re-run install.sh"
  fi
  echo ""
}

setup_spacewar() {
  log_info "=== Spacewar (App 480) ==="
  check_spacewar || true
  echo ""
}

run_tools() {
  log_info "=== Game tools ==="
  if list_tools; then
    echo ""
    if confirm "Run a game setup tool now?"; then
      run_tool_menu || true
    fi
  else
    log_warn "No tools in tools/ yet."
  fi
  echo ""
}

main() {
  print_banner
  log_info "Legal: This project does not distribute games or fix files."
  log_info "See docs/legal.md before continuing."
  echo ""

  if ! confirm "Continue with system setup?"; then
    log_info "Aborted."
    exit 0
  fi

  preflight
  install_base_packages
  setup_proton
  setup_spacewar
  print_overlay_hint
  run_tools

  log_ok "CRKCACHY master install finished."
  log_info "Next: open the tool README for your game (e.g. tools/house-of-ashes/README.md)"
}

main "$@"
