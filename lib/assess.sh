#!/usr/bin/env bash
# System assessment – detects setup state and recommends wizard path

set -euo pipefail

# Globals after assess_run()
ASSESS_OK=0
ASSESS_FAIL=0
ASSESS_MISSING_PKGS=()
ASSESS_ISSUES=()       # issue keys for i18n assess.issue.*
ASSESS_SYSTEM_READY=false
ASSESS_RECOMMENDED=1   # wizard option 1-4

assess_reset() {
  ASSESS_OK=0
  ASSESS_FAIL=0
  ASSESS_MISSING_PKGS=()
  ASSESS_ISSUES=()
  ASSESS_SYSTEM_READY=false
  ASSESS_RECOMMENDED=1
}

assess_add_issue() {
  local key="$1"
  ASSESS_ISSUES+=("$key")
  ASSESS_FAIL=$((ASSESS_FAIL + 1))
}

assess_add_ok() {
  ASSESS_OK=$((ASSESS_OK + 1))
}

assess_check_logical_pkg_list() {
  local logical resolved

  for logical in "$@"; do
    if platform_logical_arch_only "$logical" && ! platform_is_arch_family; then
      assess_add_issue "arch_only:$logical"
      continue
    fi

    resolved="$(platform_resolve_packages "$logical")"
    if [[ -z "$resolved" ]]; then
      if ! platform_is_arch_family; then
        assess_add_issue "pkg_manual:$logical"
      fi
      continue
    fi

    if platform_logical_installed "$logical"; then
      assess_add_ok
    else
      ASSESS_MISSING_PKGS+=("$logical")
      assess_add_issue "pkg:$logical"
    fi
  done
}

assess_check_pkg_list() {
  if ! platform_gaming_stack_supported; then
    return 0
  fi

  local pkg
  for pkg in "$@"; do
    if package_is_installed "$pkg"; then
      assess_add_ok
    else
      ASSESS_MISSING_PKGS+=("$pkg")
      assess_add_issue "pkg:$pkg"
    fi
  done
}

# Run full assessment (no side effects except STEAM_ROOT update from find_steam_root)
assess_run() {
  local base_pkgs=("${ASSESS_LOGICAL_BASE[@]}")
  local vulkan_pkgs=("${ASSESS_LOGICAL_VULKAN[@]}")
  local steam_logical="${ASSESS_STEAM_LOGICAL:-steam}"

  assess_reset

  if [[ "$PLATFORM_IS_CACHYOS" == true ]]; then
    assess_add_ok
  else
    assess_add_issue "cachyos"
  fi

  if ! platform_gaming_stack_supported; then
    assess_add_issue "platform_partial"

    if find_steam_root 2>/dev/null; then
      assess_add_ok
    else
      assess_add_issue "steam_data"
    fi

    assess_check_logical_pkg_list "$steam_logical" "${base_pkgs[@]}" "${vulkan_pkgs[@]}"

    local arch_only
    for arch_only in "${PLATFORM_ROSETTA_ARCH_ONLY[@]}"; do
      assess_add_issue "arch_only:$arch_only"
    done

    ASSESS_SYSTEM_READY=true
    for issue in "${ASSESS_ISSUES[@]}"; do
      case "$issue" in
        cachyos|platform_partial|arch_only:*|pkg_manual:*)
          continue
          ;;
      esac
      ASSESS_SYSTEM_READY=false
      break
    done
    assess_compute_recommendation
    return
  fi

  if [[ -n "$PLATFORM_AUR_HELPER" ]]; then
    assess_add_ok
  else
    assess_add_issue "paru"
  fi

  if find_steam_root 2>/dev/null; then
    assess_add_ok
  else
    assess_add_issue "steam_data"
  fi

  if command_exists protonup-rs || platform_logical_installed protonup; then
    assess_add_ok
  else
    assess_add_issue "protonup"
  fi

  if list_ge_proton >/dev/null 2>&1; then
    assess_add_ok
  else
    assess_add_issue "ge_proton"
  fi

  if [[ -f "${SPACEWAR_MANIFEST:-}" ]]; then
    assess_add_ok
  else
    # refresh manifest path
    find_steam_root 2>/dev/null || true
    if [[ -f "${SPACEWAR_MANIFEST:-}" ]]; then
      assess_add_ok
    else
      assess_add_issue "spacewar"
    fi
  fi

  assess_check_logical_pkg_list "$steam_logical" "${base_pkgs[@]}" "${vulkan_pkgs[@]}"

  # System ready = keine blockierenden Issues außer cachyos-Warnung
  ASSESS_SYSTEM_READY=true
  local issue
  for issue in "${ASSESS_ISSUES[@]}"; do
    if [[ "$issue" == "cachyos" || "$issue" == "platform_partial" ]]; then
      continue
    fi
    ASSESS_SYSTEM_READY=false
    break
  done

  assess_compute_recommendation
}

assess_compute_recommendation() {
  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    ASSESS_RECOMMENDED=3
    return
  fi

  local pkg_only=true
  local issue
  for issue in "${ASSESS_ISSUES[@]}"; do
    if [[ "$issue" != cachyos && "$issue" != pkg:* ]]; then
      pkg_only=false
      break
    fi
  done

  if [[ "$pkg_only" == true && ${#ASSESS_MISSING_PKGS[@]} -gt 0 ]]; then
    ASSESS_RECOMMENDED=2
  elif [[ ${#ASSESS_ISSUES[@]} -ge 4 ]]; then
    ASSESS_RECOMMENDED=1
  else
    ASSESS_RECOMMENDED=2
  fi
}

assess_issue_label() {
  local issue="$1"
  if [[ "$issue" == pkg:* ]]; then
    msgf assess.issue_pkg "$(platform_logical_display_name "${issue#pkg:}")"
  elif [[ "$issue" == arch_only:* ]]; then
    msgf assess.issue_arch_only "${issue#arch_only:}"
  elif [[ "$issue" == pkg_manual:* ]]; then
    msgf assess.issue_pkg_manual "${issue#pkg_manual:}"
  else
    msg "assess.issue.${issue}"
  fi
}

assess_recommended_hint() {
  case "$ASSESS_RECOMMENDED" in
    3) msg wizard.hint_ready ;;
    2) msg wizard.hint_fix ;;
    *) msg wizard.hint_full ;;
  esac
}

tui_assess_panel() {
  local issue pkg

  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    return 0
  fi

  for issue in "${ASSESS_ISSUES[@]}"; do
    log_hint "○ $(assess_issue_label "$issue")"
  done
  if [[ ${#ASSESS_MISSING_PKGS[@]} -gt 0 ]]; then
    for pkg in "${ASSESS_MISSING_PKGS[@]}"; do
      log_hint "  · $(platform_logical_display_name "$pkg")"
    done
  fi
  return 1
}

assess_print_report() {
  log_info "$(msg assess.title)"
  echo ""

  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    log_ok "$(msg assess.all_ready)"
    log_hint "$(msg assess.all_ready_hint)"
    log_hint "$(msgf assess.score "$ASSESS_OK" "$ASSESS_FAIL")"
    echo ""
    gum style --border rounded --padding "1 2" --foreground "$CUI_MUTED" "$(msg wizard.checks_body)"
    echo ""
    return 0
  fi

  log_warn "$(msg assess.not_ready)"
  log_hint "$(msgf assess.score "$ASSESS_OK" "$ASSESS_FAIL")"
  echo ""
  log_info "$(msg assess.missing_list)"

  local issue
  for issue in "${ASSESS_ISSUES[@]}"; do
    if [[ "$issue" == "cachyos" ]]; then
      log_warn "$(assess_issue_label "$issue")"
    else
      log_error "$(assess_issue_label "$issue")"
    fi
  done

  if [[ ${#ASSESS_MISSING_PKGS[@]} -gt 0 ]]; then
    echo ""
    log_info "$(msg assess.missing_pkgs)"
    local pkg
    for pkg in "${ASSESS_MISSING_PKGS[@]}"; do
      log_hint "$(platform_logical_display_name "$pkg")"
    done
  fi

  echo ""
  return 1
}

assess_print_next_step() {
  if [[ "$ASSESS_SYSTEM_READY" == true && "$ASSESS_RECOMMENDED" -eq 3 ]]; then
    explain_block "$(msg assess.next_title)" "$(msg assess.next_ready_body)"
  elif [[ "$ASSESS_RECOMMENDED" -eq 2 ]]; then
    explain_block "$(msg assess.next_title)" "$(msg assess.next_fix_body)"
  else
    explain_block "$(msg assess.next_title)" "$(msg assess.next_full_body)"
  fi
}

print_wizard_options() {
  local s1 s2 s3 s4
  s1="$(assess_menu_suffix 1)"
  s2="$(assess_menu_suffix 2)"
  s3="$(assess_menu_suffix 3)"
  s4="$(assess_menu_suffix 4)"

  explain_block "$(msg wizard.title)" "$(msg wizard.body)"

  echo -e "  1) $(msg wizard.opt1)${s1}"
  echo -e "  2) $(msg wizard.opt2)${s2}"
  echo -e "  3) $(msg wizard.opt3)${s3}"
  echo -e "  4) $(msg wizard.opt4)${s4}"
  echo ""
}

assess_menu_suffix() {
  local opt="$1"
  if [[ "$opt" == "$ASSESS_RECOMMENDED" ]]; then
    echo -e "${_C_GREEN}$(msg assess.menu_recommended)${_C_RESET}"
  else
    echo ""
  fi
}

install_single_package() {
  local logical="$1"
  local display

  display="$(platform_logical_display_name "$logical")"

  if platform_logical_known "$logical" && platform_logical_installed "$logical"; then
    log_ok "$(msgf assess.pkg_already "$display")"
    return 0
  fi

  if ! platform_logical_known "$logical" && pacman_installed "$logical"; then
    log_ok "$(msgf assess.pkg_already "$logical")"
    return 0
  fi

  if platform_logical_arch_only "$logical" && ! platform_is_arch_family; then
    log_warn "$(msgf assess.issue_arch_only "$logical")"
    return 1
  fi

  if platform_logical_known "$logical" && ! platform_logical_has_mapping "$logical"; then
    log_warn "$(msgf assess.issue_pkg_manual "$logical")"
    return 1
  fi

  log_info "$(msgf assess.install_one "$display")"
  package_explain_block "$(msg pkg.explain.title)" "$logical"
  offer_package_install \
    "$(msgf assess.confirm_one "$display")" \
    "$(platform_manual_install_cmd_logical "$logical")" \
    "$logical"
}

offer_paru_install() {
  if [[ -n "$PLATFORM_AUR_HELPER" ]] || platform_logical_installed paru; then
    return 0
  fi

  if ! platform_is_arch_family; then
    return 1
  fi

  explain_block "$(msg paru.self_title)" "$(package_explain_text paru)

$(msg pkg.explain.footer)"
  if confirm "$(msg paru.confirm_self)"; then
    if install_packages_repo paru; then
      log_ok "$(msg paru.done)"
      return 0
    fi
    log_warn "$(msg paru.install_failed)"
    log_hint "$(msg paru.install_paru_hint)"
    return 1
  fi

  log_warn "$(msg paru.skipped)"
  log_hint "$(msg offer.manual_label)"
  log_hint "$(msg paru.install_paru_hint)"
  return 1
}

# Fix missing items step by step until ready or user stops
assess_guided_fix() {
  explain_block "$(msg assess.fix_title)" "$(msg assess.fix_body)"

  local round=0
  while [[ "$ASSESS_SYSTEM_READY" != true && $round -lt 10 ]]; do
    assess_run
    if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
      log_ok "$(msg assess.all_ready)"
      return 0
    fi

    round=$((round + 1))
    log_info "$(msgf assess.fix_round "$round")"
    assess_print_report || true
    echo ""

    local fixed=false
    local issue pkg

    for issue in "${ASSESS_ISSUES[@]}"; do
      case "$issue" in
        paru)
          if offer_paru_install; then
            fixed=true
          fi
          ;;
        steam|pkg:steam)
          package_explain_block "$(msg pkg.explain.steam_title)" steam
          if confirm "$(msg install.steam_confirm)"; then
            install_packages_paru steam && fixed=true
          else
            log_warn "$(msg paru.skipped)"
            log_hint "$(msg offer.manual_label)"
            log_hint "$(platform_manual_install_cmd_logical steam)"
          fi
          ;;
        steam_data)
          log_warn "$(assess_issue_label "$issue")"
          ;;
        protonup|arch_only:protonup)
          if platform_is_arch_family; then
            if install_single_package protonup; then fixed=true; fi
          fi
          ;;
        ge_proton)
          if command_exists protonup-rs; then
            if confirm "$(msg proton.confirm_install)"; then
              protonup-rs -q --tool GEProton --version latest --for steam
              fixed=true
            else
              log_warn "$(msg proton.skipped)"
              log_hint "$(msg offer.manual_label)"
              log_hint "$(msg proton.manual_cmd)"
            fi
          elif ! platform_is_arch_family; then
            log_warn "$(assess_issue_label "arch_only:protonup")"
          fi
          ;;
        spacewar)
          log_warn "$(assess_issue_label "$issue")"
          log_hint "$(msg spacewar.hint1)"
          ;;
        cachyos)
          ;;
        arch_only:*)
          log_warn "$(assess_issue_label "$issue")"
          ;;
        pkg_manual:*)
          log_warn "$(assess_issue_label "$issue")"
          ;;
        pkg:*)
          pkg="${issue#pkg:}"
          if install_single_package "$pkg"; then fixed=true; fi
          ;;
      esac
    done

    assess_run
    if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
      log_ok "$(msg assess.all_ready)"
      return 0
    fi

    if [[ "$fixed" != true ]]; then
      if ! confirm "$(msg assess.fix_continue)"; then
        log_warn "$(msg assess.fix_stopped)"
        return 1
      fi
    fi
  done

  return 1
}

# Block game setup until system is ready
assess_ensure_ready() {
  assess_run

  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    return 0
  fi

  log_warn "$(msg assess.block_game)"
  echo ""

  if confirm "$(msg assess.fix_now)"; then
    assess_guided_fix && return 0
  fi

  log_error "$(msg assess.block_game_still)"
  return 1
}
