#!/usr/bin/env bash
# PC check before setup

set -euo pipefail

PREFLIGHT_REQUIRED_FAIL=0
PREFLIGHT_RECOMMENDED_FAIL=0
GUM_MIN_VERSION="0.14.0"

preflight_version_ge() {
  local have="$1"
  local need="$2"
  [[ "$(printf '%s\n' "$need" "$have" | sort -V | head -1)" == "$need" ]]
}

preflight_gum_version() {
  if ! command_exists gum; then
    return 1
  fi
  local raw ver
  raw="$(gum --version 2>/dev/null | head -1)"
  ver="$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<< "$raw" | head -1)"
  [[ -n "$ver" ]] || return 1
  preflight_version_ge "$ver" "$GUM_MIN_VERSION"
}

preflight_run() {
  PREFLIGHT_REQUIRED_FAIL=0
  PREFLIGHT_RECOMMENDED_FAIL=0
}

preflight_has_installer() {
  platform_has_package_manager
}

# --- Display helpers ---------------------------------------------------------

_pf_ok()   { echo -e "${_C_GREEN}  ✓${_C_RESET} $*"; }
_pf_warn() { echo -e "${_C_YELLOW}  ○${_C_RESET} $*"; }
_pf_fail() { echo -e "${_C_RED}  ✗${_C_RESET} $*"; }

# Always show the full CRKCACHY-tool check (gum, glow, pacman/paru, OS).
preflight_print_tool_checks() {
  local ok os_label ge_ver ge_list=""

  gum style --bold "$(msg runtime.check_title_tools)"
  echo ""

  # gum
  ok=true
  command_exists gum && preflight_gum_version || ok=false
  if [[ "$ok" == true ]]; then
    _pf_ok "gum $(gum --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) – $(msg runtime.item_menu)"
  else
    _pf_fail "gum – $(msg runtime.item_menu)"; PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1))
  fi

  # glow
  ok=true
  command_exists glow || ok=false
  if [[ "$ok" == true ]]; then
    _pf_ok "glow – $(msg runtime.item_reader)"
  else
    _pf_fail "glow – $(msg runtime.item_reader)"; PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1))
  fi

  # pacman / package manager
  ok=true
  preflight_has_installer || ok=false
  if [[ "$ok" == true ]]; then
    local pm="${PLATFORM_AUR_HELPER:-pacman}"
    _pf_ok "$pm – $(msg runtime.item_packages)"
  else
    _pf_fail "$(msg runtime.item_packages)"; PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1))
  fi

  # OS
  os_label="$(platform_os_checklist_label)"
  ok=true
  platform_os_check_ok || ok=false
  if [[ "$ok" == true ]]; then
    _pf_ok "$os_label"
  else
    _pf_warn "$os_label – $(msg platform.tier_partial_hint)"; PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi
}

# Always show the gaming-stack check (Steam, GE-Proton, Spacewar, packages).
preflight_print_gaming_checks() {
  local ok ge_list=""

  echo ""
  gum style --bold "$(msg runtime.check_title_gaming)"
  echo ""

  # Steam installed
  ok=true
  if command_exists steam || platform_logical_installed steam; then ok=true; else ok=false; fi
  if [[ "$ok" == true ]]; then
    _pf_ok "Steam – $(msg runtime.item_steam_ok)"
  else
    _pf_warn "Steam – $(msg runtime.item_steam)"; PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # Steam data dir
  ok=true
  find_steam_root 2>/dev/null || ok=false
  if [[ "$ok" == true ]]; then
    _pf_ok "$(msg runtime.item_steam_data_ok) ($STEAM_ROOT)"
  else
    _pf_warn "$(msg runtime.item_steam_data)"; PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # protonup-rs
  ok=true
  command_exists protonup-rs || platform_logical_installed protonup || ok=false
  if [[ "$ok" == true ]]; then
    _pf_ok "protonup-rs – $(msg runtime.item_protonup_ok)"
  else
    _pf_warn "protonup-rs – $(msg runtime.item_protonup)"; PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # GE-Proton versions
  ok=true
  ge_list="$(list_ge_proton 2>/dev/null | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)"
  if [[ -n "$ge_list" ]]; then
    _pf_ok "GE-Proton: $ge_list"
  else
    _pf_warn "GE-Proton – $(msg runtime.item_ge_proton)"; PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # Spacewar
  ok=true
  find_steam_root 2>/dev/null || true
  if [[ -f "${SPACEWAR_MANIFEST:-}" ]]; then
    _pf_ok "Spacewar (App 480) – $(msg runtime.item_spacewar_ok)"
  else
    _pf_warn "Spacewar (App 480) – $(msg runtime.item_spacewar)"; PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # Key gaming packages
  local pkg
  for pkg in vkd3d gamemode winetricks; do
    ok=true
    platform_logical_installed "$pkg" 2>/dev/null || ok=false
    local display
    display="$(platform_logical_display_name "$pkg" 2>/dev/null || echo "$pkg")"
    if [[ "$ok" == true ]]; then
      _pf_ok "$display"
    else
      _pf_warn "$display – $(msg runtime.item_pkg_missing)"
    fi
  done
}

# Zählt Fails still durch (keine Ausgabe) – nur für Vorher-Nachher-Vergleich
_preflight_count_silent() {
  local ok

  command_exists gum && preflight_gum_version || { PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1)); }
  command_exists glow || { PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1)); }
  preflight_has_installer || { PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1)); }

  if ! (command_exists steam || platform_logical_installed steam 2>/dev/null); then
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi
  find_steam_root 2>/dev/null || PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  command_exists protonup-rs || platform_logical_installed protonup 2>/dev/null || \
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  list_ge_proton >/dev/null 2>&1 || PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  find_steam_root 2>/dev/null || true
  [[ -f "${SPACEWAR_MANIFEST:-/dev/null}" ]] || PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  local pkg
  for pkg in vkd3d gamemode winetricks; do
    platform_logical_installed "$pkg" 2>/dev/null || true
  done
}

preflight_print_checklist() {
  # Always run both check groups (they increment the fail counters as they go)
  preflight_print_tool_checks
  preflight_print_gaming_checks
  echo ""

  if [[ "$PREFLIGHT_REQUIRED_FAIL" -eq 0 && "$PREFLIGHT_RECOMMENDED_FAIL" -eq 0 ]]; then
    cui_status_chip true "$(msg runtime.check_all_ok)"
  elif [[ "$PREFLIGHT_REQUIRED_FAIL" -gt 0 ]]; then
    cui_status_chip false "$(msgf runtime.check_fail_required "$PREFLIGHT_REQUIRED_FAIL")"
  else
    cui_status_chip false "$(msgf runtime.check_warn_recommended "$PREFLIGHT_RECOMMENDED_FAIL")"
  fi
}

preflight_fix_spacewar() {
  # Spacewar (App 480) über Steam direkt installieren
  if command_exists steam || platform_logical_installed steam 2>/dev/null; then
    log_info "$(msg runtime.spacewar_launching)"
    steam steam://install/480 2>/dev/null &
    sleep 3
    # Steam startet async – Manifest erst nach Download da, als OK akzeptieren
    log_ok "$(msg runtime.spacewar_launched)"
    return 0
  fi
  log_warn "$(msg runtime.spacewar_no_steam)"
  return 1
}

preflight_fix_recommended() {
  local fixed=false

  if [[ -z "$PLATFORM_AUR_HELPER" ]] && platform_is_arch_family; then
    if offer_paru_install; then
      fixed=true
    fi
  fi

  if ! command_exists steam && ! platform_logical_installed steam; then
    package_explain_block "$(msg pkg.explain.steam_title)" steam
    if confirm "$(msg runtime.install_steam)"; then
      install_packages_repo steam && fixed=true
    else
      log_warn "$(msg paru.skipped)"
      log_hint "$(msg offer.manual_label)"
      log_hint "$(platform_manual_install_cmd_logical steam)"
    fi
  fi

  # Spacewar automatisch über Steam installieren wenn es fehlt
  if [[ -n "${SPACEWAR_MANIFEST:-}" ]] && [[ ! -f "${SPACEWAR_MANIFEST}" ]]; then
    find_steam_root 2>/dev/null || true
    if [[ ! -f "${SPACEWAR_MANIFEST:-/dev/null}" ]]; then
      echo ""
      log_warn "$(msg runtime.spacewar_missing_fix)"
      if confirm "$(msg runtime.spacewar_install_now)" true; then
        preflight_fix_spacewar && fixed=true
      fi
    fi
  fi

  [[ "$fixed" == true ]]
}

preflight_onboard() {
  preflight_run
  echo ""
  preflight_print_checklist
  echo ""

  if [[ "$PLATFORM_TIER" == unsupported ]]; then
    log_warn "$(msg platform.tier_unsupported_warn)"
  elif [[ "$PLATFORM_TIER" == partial ]]; then
    log_warn "$(msg platform.tier_partial_warn)"
  fi

  if [[ "$PREFLIGHT_RECOMMENDED_FAIL" -gt 0 && "$PREFLIGHT_REQUIRED_FAIL" -eq 0 ]]; then
    echo ""
    if confirm "$(msg runtime.fix_recommended)" false; then
      local _fail_before="$PREFLIGHT_RECOMMENDED_FAIL"
      preflight_fix_recommended || true
      echo ""
      # Still re-count silently to see if anything changed
      preflight_run
      _preflight_count_silent
      if [[ "$PREFLIGHT_RECOMMENDED_FAIL" -lt "$_fail_before" ]]; then
        # Improvement – show updated list
        preflight_print_tool_checks
        preflight_print_gaming_checks
        echo ""
        cui_status_chip true "$(msg runtime.check_all_ok)"
      else
        # Nothing changed (e.g. Spacewar async) – just show hint, no repeated list
        log_hint "$(msg runtime.spacewar_async_hint)"
      fi
      echo ""
    fi
  fi

  if [[ "$PREFLIGHT_REQUIRED_FAIL" -gt 0 ]]; then
    die "$(msg runtime.cannot_continue)"
  fi

  cui_legal_gate
  echo ""
}

preflight_status_only() {
  preflight_run
  platform_log_summary
  echo ""
  preflight_print_tool_checks
  preflight_print_gaming_checks
}
