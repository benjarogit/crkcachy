#!/usr/bin/env bash
# PC check before setup

set -euo pipefail

PREFLIGHT_REQUIRED_FAIL=0
PREFLIGHT_RECOMMENDED_FAIL=0
NODE_MIN_MAJOR=18

preflight_node_version() {
  if ! command -v node >/dev/null 2>&1; then
    return 1
  fi
  local major
  major="$(node -p "process.versions.node.split('.').map(Number)[0]" 2>/dev/null || echo 0)"
  [[ "${major:-0}" -ge "$NODE_MIN_MAJOR" ]]
}

preflight_run() {
  PREFLIGHT_REQUIRED_FAIL=0
  PREFLIGHT_RECOMMENDED_FAIL=0
}

preflight_has_installer() {
  platform_has_package_manager
}

# --- Display helpers ---------------------------------------------------------
# Nutzen das neue cui_check_row aus dem CRKCACHY Design System.
# Format: cui_check_row <state> <name> [value] [detail]
#   state = ok | warn | fail
#   name  = linksbündig in Spalte 1 (24 Zeichen)
#   value = Spalte 2 (28 Zeichen)
#   detail= Spalte 3, gedimmt

# Always show the full CRKCACHY-tool check (Node.js, glow, pacman/paru, OS).
preflight_print_tool_checks() {
  local ok node_ver os_label

  cui_check_category "$(msg runtime.check_title_tools)"

  # Node.js (Clack-Prompter)
  ok=true
  command_exists node && preflight_node_version || ok=false
  node_ver="$(node --version 2>/dev/null | sed 's/^v//' || echo "")"
  if [[ "$ok" == true ]]; then
    cui_check_row ok "Node.js ${node_ver}" "$(msg runtime.item_menu)"
  else
    cui_check_row fail "Node.js" "$(msg runtime.item_menu)"
    PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1))
  fi

  # glow
  ok=true
  command_exists glow || ok=false
  if [[ "$ok" == true ]]; then
    cui_check_row ok "glow" "$(msg runtime.item_reader)"
  else
    cui_check_row fail "glow" "$(msg runtime.item_reader)"
    PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1))
  fi

  # pacman / paru
  ok=true
  preflight_has_installer || ok=false
  local pm="${PLATFORM_AUR_HELPER:-pacman}"
  if [[ "$ok" == true ]]; then
    cui_check_row ok "$pm" "$(msg runtime.item_packages)"
  else
    cui_check_row fail "$(msg runtime.item_packages)" ""
    PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1))
  fi

  # OS
  os_label="$(platform_os_checklist_label)"
  ok=true
  platform_os_check_ok || ok=false
  if [[ "$ok" == true ]]; then
    cui_check_row ok "$os_label" ""
  else
    cui_check_row warn "$os_label" "$(msg platform.tier_partial_hint)"
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi
}

# Always show the gaming-stack check (Steam, GE-Proton, Spacewar, packages).
preflight_print_gaming_checks() {
  local ok ge_list ge_first ge_rest

  cui_check_category "$(msg runtime.check_title_gaming)"

  # Steam installiert
  ok=true
  if command_exists steam || platform_logical_installed steam; then ok=true; else ok=false; fi
  if [[ "$ok" == true ]]; then
    cui_check_row ok "Steam" "$(msg runtime.item_steam_ok)"
  else
    cui_check_row warn "Steam" "$(msg runtime.item_steam)"
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # Steam-Bibliothek (STEAM_ROOT)
  ok=true
  find_steam_root 2>/dev/null || ok=false
  if [[ "$ok" == true ]]; then
    # Pfad ggf. kürzen damit er in Spalte 3 passt
    local steam_short="${STEAM_ROOT:-}"
    [[ "${#steam_short}" -gt 34 ]] && steam_short="…${steam_short: -33}"
    cui_check_row ok "$(msg runtime.item_steam_data_ok)" "gefunden" "$steam_short"
  else
    cui_check_row warn "$(msg runtime.item_steam_data)" "nicht gefunden" "$(msg runtime.item_steam_data_hint)"
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # protonup-rs
  ok=true
  command_exists protonup-rs || platform_logical_installed protonup || ok=false
  if [[ "$ok" == true ]]; then
    cui_check_row ok "protonup-rs" "$(msg runtime.item_protonup_ok)" "$(msg runtime.item_protonup_detail)"
  else
    cui_check_row warn "protonup-rs" "$(msg runtime.item_protonup)"
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # GE-Proton – ersten Eintrag als Wert, weitere als Detail
  ge_list="$(list_ge_proton 2>/dev/null | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)"
  if [[ -n "$ge_list" ]]; then
    ge_first="$(echo "$ge_list" | awk '{print $1}')"
    ge_rest="$(echo "$ge_list"  | awk 'NF>1{$1=""; print substr($0,2)}')"
    cui_check_row ok "GE-Proton" "$ge_first" "${ge_rest:++${ge_rest}}"
  else
    cui_check_row warn "GE-Proton" "$(msg runtime.item_ge_proton)" "$(msg runtime.item_ge_proton_hint)"
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # Spacewar
  find_steam_root 2>/dev/null || true
  if [[ -f "${SPACEWAR_MANIFEST:-}" ]]; then
    cui_check_row ok "Spacewar" "App 480" "$(msg runtime.item_spacewar_ok)"
  else
    cui_check_row warn "Spacewar" "App 480" "$(msg runtime.item_spacewar)"
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL+1))
  fi

  # Gaming-Pakete (nur logischer Name, keine Package-Liste)
  local pkg
  for pkg in vkd3d gamemode winetricks; do
    ok=true
    platform_logical_installed "$pkg" 2>/dev/null || ok=false
    if [[ "$ok" == true ]]; then
      cui_check_row ok "$pkg" "$(msg runtime.item_pkg_ok)"
    else
      cui_check_row warn "$pkg" "$(msg runtime.item_pkg_missing)"
    fi
  done
}

# Zählt Fails still durch (keine Ausgabe) – nur für Vorher-Nachher-Vergleich
_preflight_count_silent() {
  local ok

  command_exists node && preflight_node_version || { PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL+1)); }
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

_preflight_spacewar_installed() {
  find_steam_root 2>/dev/null || true
  [[ -f "${SPACEWAR_MANIFEST:-/dev/null}" ]]
}

preflight_fix_spacewar() {
  local choice
  choice="$(crk_gate_menu \
    "$(msg runtime.spacewar_gate_title)" \
    "$(msg runtime.spacewar_gate_body)" \
    "$(msg runtime.spacewar_gate_prompt)" \
    "auto|$(msg runtime.spacewar_opt_auto)" \
    "manual|$(msg runtime.spacewar_opt_manual)" \
    "skip|$(msg runtime.spacewar_opt_skip)")" || choice=""

  case "${choice:-}" in
    auto)
      if command_exists steam || platform_logical_installed steam 2>/dev/null; then
        log_info "$(msg runtime.spacewar_launching)"
        steam steam://install/480 >/dev/null 2>&1 &
        disown 2>/dev/null || true
        cui_warning_box "$(msg runtime.spacewar_auto_hint)"
        cui_continue "$(msg runtime.spacewar_wait_continue)"
      else
        log_warn "$(msg runtime.spacewar_no_steam)"
        return 1
      fi
      ;;
    manual)
      cui_info_box "$(msg runtime.spacewar_manual_steps)"
      ;;
    skip|*)
      log_warn "$(msg runtime.spacewar_skipped)"
      return 1
      ;;
  esac

  # Warte auf Bestätigung + Prüfung
  echo ""
  local tries=0
  while true; do
    if _preflight_spacewar_installed; then
      echo ""
      cui_status_chip true "$(msg runtime.spacewar_verified)"
      # Marker schreiben: CRKCACHY hat Spacewar installiert → für Deinstallation merken
      local _sw_marker_dir="${HOME}/.local/share/crkcachy"
      mkdir -p "$_sw_marker_dir" 2>/dev/null || true
      touch "${_sw_marker_dir}/.spacewar_crkcachy_pending" 2>/dev/null || true
      return 0
    fi
    tries=$((tries + 1))
    if [[ "$tries" -gt 3 ]]; then
      echo ""
      log_warn "$(msg runtime.spacewar_not_found_warn)"
      if ! confirm "$(msg runtime.spacewar_skip_anyway)" false; then
        return 1
      fi
      return 0
    fi
    echo ""
    cui_continue "$(msg runtime.spacewar_wait_continue)"
    # Kurz warten damit Steam-Manifest auf Disk erscheint
    sleep 2
  done
}

# ── Gate: protonup-rs ────────────────────────────────────────────────────────

preflight_fix_protonup() {
  local choice
  choice="$(crk_gate_menu \
    "$(msg runtime.protonup_gate_title)" \
    "$(msg runtime.protonup_gate_body)" \
    "$(msg runtime.protonup_gate_prompt)" \
    "auto|$(msg runtime.protonup_opt_auto)" \
    "manual|$(msg runtime.protonup_opt_manual)" \
    "skip|$(msg runtime.protonup_opt_skip)")" || choice=""

  case "${choice:-}" in
    auto)
      log_info "$(msg runtime.protonup_installing)"
      if offer_logical_packages false protonup 2>/dev/null; then
        echo ""
        cui_status_chip true "$(msg runtime.protonup_verified)"
        return 0
      else
        echo ""
        log_warn "$(msg runtime.protonup_install_failed)"
        cui_info_box "$(msg runtime.protonup_manual_steps)"
        if confirm "$(msg runtime.protonup_manual_done)" true; then
          if command_exists protonup-rs; then
            echo ""
            cui_status_chip true "$(msg runtime.protonup_verified)"
            return 0
          fi
          echo ""
          cui_status_chip false "$(msg runtime.protonup_not_found_warn)"
        fi
      fi
      ;;
    manual)
      cui_info_box "$(msg runtime.protonup_manual_steps)"
      if confirm "$(msg runtime.protonup_manual_done)" true; then
        if command_exists protonup-rs; then
          echo ""
          cui_status_chip true "$(msg runtime.protonup_verified)"
          return 0
        fi
        echo ""
        cui_status_chip false "$(msg runtime.protonup_not_found_warn)"
      fi
      ;;
    *)
      log_warn "$(msg runtime.protonup_skipped)"
      return 1
      ;;
  esac
  command_exists protonup-rs
}

# ── Gate: GE-Proton ──────────────────────────────────────────────────────────

preflight_fix_ge_proton() {
  if ! command_exists protonup-rs; then
    log_warn "$(msg runtime.ge_proton_needs_protonup)"
    return 1
  fi

  local choice
  choice="$(crk_gate_menu \
    "$(msg runtime.ge_proton_gate_title)" \
    "$(msg runtime.ge_proton_gate_body)" \
    "$(msg runtime.ge_proton_gate_prompt)" \
    "auto|$(msg runtime.ge_proton_opt_auto)" \
    "manual|$(msg runtime.ge_proton_opt_manual)" \
    "skip|$(msg runtime.ge_proton_opt_skip)")" || choice=""

  case "${choice:-}" in
    auto)
      echo ""
      log_info "$(msg runtime.ge_proton_installing)"
      if protonup-rs -q --tool GEProton --version latest --for steam 2>/dev/null; then
        echo ""
        cui_status_chip true "$(msg runtime.ge_proton_verified)"
        return 0
      else
        log_warn "$(msg runtime.ge_proton_install_failed)"
        cui_info_box "$(msg runtime.ge_proton_manual_steps)"
        if confirm "$(msg runtime.ge_proton_manual_done)" true; then
          if list_ge_proton >/dev/null 2>&1; then
            echo ""
            cui_status_chip true "$(msg runtime.ge_proton_verified)"
            return 0
          fi
          echo ""
          cui_status_chip false "$(msg runtime.ge_proton_not_found_warn)"
        fi
      fi
      ;;
    manual)
      cui_info_box "$(msg runtime.ge_proton_manual_steps)"
      if confirm "$(msg runtime.ge_proton_manual_done)" true; then
        if list_ge_proton >/dev/null 2>&1; then
          echo ""
          cui_status_chip true "$(msg runtime.ge_proton_verified)"
          return 0
        fi
        echo ""
        cui_status_chip false "$(msg runtime.ge_proton_not_found_warn)"
      fi
      ;;
    *)
      log_warn "$(msg runtime.ge_proton_skipped)"
      return 1
      ;;
  esac
  list_ge_proton >/dev/null 2>&1
}

# ── Gate: Steam-Bibliothek (nicht eingeloggt) ─────────────────────────────

preflight_fix_steam_data() {
  local choice
  choice="$(crk_gate_menu \
    "$(msg runtime.steam_data_gate_title)" \
    "$(msg runtime.steam_data_gate_body)" \
    "$(msg runtime.steam_data_gate_prompt)" \
    "open|$(msg runtime.steam_data_opt_open)" \
    "manual|$(msg runtime.steam_data_opt_manual)" \
    "skip|$(msg runtime.steam_data_opt_skip)")" || choice=""

  _steam_data_wait_and_verify() {
    local tries=0
    while true; do
      if find_steam_root 2>/dev/null; then
        echo ""
        cui_status_chip true "$(msg runtime.steam_data_verified)"
        return 0
      fi
      tries=$((tries + 1))
      if [[ "$tries" -gt 4 ]]; then
        log_warn "$(msg runtime.steam_data_not_found_warn)"
        if confirm "$(msg runtime.steam_data_skip_anyway)" false; then
          return 0
        fi
        return 1
      fi
      if ! confirm "$(msg runtime.steam_data_wait_confirm)" true; then
        return 1
      fi
      sleep 2
    done
  }

  case "${choice:-}" in
    open)
      log_info "$(msg runtime.steam_data_opening)"
      (command_exists steam && steam >/dev/null 2>&1 &) || true
      echo ""
      log_ok "$(msg runtime.steam_data_opened)"
      echo ""
      _steam_data_wait_and_verify
      ;;
    manual)
      cui_info_box "$(msg runtime.steam_data_manual_steps)"
      _steam_data_wait_and_verify
      ;;
    *)
      log_warn "$(msg runtime.steam_data_skipped)"
      return 1
      ;;
  esac
}

# ── Spacewar Gate (bereits oben definiert) ────────────────────────────────

# ── Gesamt-Fix-Orchestrator ──────────────────────────────────────────────────

preflight_fix_recommended() {
  local fixed=false

  # paru / AUR-Helfer
  if [[ -z "$PLATFORM_AUR_HELPER" ]] && platform_is_arch_family; then
    if offer_paru_install; then
      fixed=true
    fi
  fi

  # Steam Client
  if ! command_exists steam && ! platform_logical_installed steam 2>/dev/null; then
    package_explain_block "$(msg pkg.explain.steam_title)" steam
    if confirm "$(msg runtime.install_steam)"; then
      install_packages_repo steam && fixed=true
    else
      log_warn "$(msg paru.skipped)"
      log_hint "$(msg offer.manual_label)"
      log_hint "$(platform_manual_install_cmd_logical steam)"
    fi
  fi

  # Steam-Bibliothek (nicht eingeloggt)
  if ! find_steam_root 2>/dev/null; then
    preflight_fix_steam_data && fixed=true || true
  fi

  # protonup-rs
  if ! command_exists protonup-rs && ! platform_logical_installed protonup 2>/dev/null; then
    preflight_fix_protonup && fixed=true || true
  fi

  # GE-Proton
  if ! list_ge_proton >/dev/null 2>&1; then
    preflight_fix_ge_proton && fixed=true || true
  fi

  # Spacewar
  find_steam_root 2>/dev/null || true
  if [[ ! -f "${SPACEWAR_MANIFEST:-/dev/null}" ]]; then
    preflight_fix_spacewar && fixed=true || true
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

  if ! cui_onboard_should_skip; then
    cui_legal_gate
    echo ""
  fi
}

preflight_status_only() {
  preflight_run
  platform_log_summary
  echo ""
  preflight_print_tool_checks
  preflight_print_gaming_checks
}
