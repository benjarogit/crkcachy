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

preflight_check_line() {
  local ok="$1"
  local label="$2"
  if [[ "$ok" == true ]]; then
    echo "✓ $label"
  else
    echo "○ $label – $(msg runtime.missing_suffix)"
  fi
}

preflight_print_checklist() {
  local ok lines=() os_label

  if [[ "$PREFLIGHT_REQUIRED_FAIL" -eq 0 && "$PREFLIGHT_RECOMMENDED_FAIL" -eq 0 ]]; then
    log_ok "$(msg runtime.check_all_ok)"
    return
  fi

  ok=true
  command_exists gum && preflight_gum_version || ok=false
  [[ "$ok" != true ]] && PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL + 1))
  lines+=("$(preflight_check_line "$ok" "$(msg runtime.item_menu)")")

  ok=true
  command_exists glow || ok=false
  [[ "$ok" != true ]] && PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL + 1))
  lines+=("$(preflight_check_line "$ok" "$(msg runtime.item_reader)")")

  ok=true
  preflight_has_installer || ok=false
  [[ "$ok" != true ]] && PREFLIGHT_REQUIRED_FAIL=$((PREFLIGHT_REQUIRED_FAIL + 1))
  lines+=("$(preflight_check_line "$ok" "$(msg runtime.item_packages)")")

  ok=true
  [[ -n "$PLATFORM_AUR_HELPER" ]] || ok=false
  [[ "$ok" != true ]] && PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL + 1))
  lines+=("$(preflight_check_line "$ok" "$(msg runtime.item_paru)")")

  ok=true
  platform_os_check_ok || ok=false
  os_label="$(platform_os_checklist_label)"
  [[ "$ok" != true ]] && PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL + 1))
  lines+=("$(preflight_check_line "$ok" "$os_label")")

  ok=true
  if command_exists steam || platform_logical_installed steam; then
    ok=true
  else
    ok=false
    PREFLIGHT_RECOMMENDED_FAIL=$((PREFLIGHT_RECOMMENDED_FAIL + 1))
  fi
  lines+=("$(preflight_check_line "$ok" "$(msg runtime.item_steam)")")

  cui_section "$(msg runtime.check_title)" "$(msg runtime.check_subtitle)"
  cui_list "${lines[@]}"
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

  [[ "$fixed" == true ]]
}

preflight_onboard() {
  preflight_run
  echo ""
  preflight_print_checklist
  echo ""

  if [[ "$PREFLIGHT_REQUIRED_FAIL" -gt 0 ]]; then
    log_error "$(msg runtime.required_fail)"
  fi

  if [[ "$PLATFORM_TIER" == unsupported ]]; then
    log_warn "$(msg platform.tier_unsupported_warn)"
  elif [[ "$PLATFORM_TIER" == partial ]]; then
    log_warn "$(msg platform.tier_partial_warn)"
  fi

  if [[ "$PREFLIGHT_RECOMMENDED_FAIL" -gt 0 ]]; then
    log_warn "$(msgf runtime.recommended_open "$PREFLIGHT_RECOMMENDED_FAIL")"
    if confirm "$(msg runtime.fix_recommended)" false; then
      preflight_fix_recommended || true
      echo ""
      preflight_run
      preflight_print_checklist
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
  preflight_print_checklist
}
