#!/usr/bin/env bash
# GE-Proton via protonup-rs

set -euo pipefail

PROTON_GE_DIR="${HOME}/.local/share/Steam/compatibilitytools.d"
PROTONUP_TOOL="GEProton"

check_protonup() {
  if command_exists protonup-rs; then
    log_ok "$(msg protonup.ok)"
    return 0
  fi

  log_warn "$(msg protonup.missing)"
  log_hint "$(msg protonup.install_hint)"
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

# Gibt den Namen der neuesten installierten GE-Proton-Version zurück (numerisch sortiert).
# Gibt leer zurück wenn nichts gefunden.
ge_proton_latest_name() {
  [[ -d "$PROTON_GE_DIR" ]] || return 0

  local _cur_major=0 _cur_minor=0 _latest="" _name _major _minor _dir
  for _dir in "$PROTON_GE_DIR"/GE-Proton*; do
    [[ -d "$_dir" ]] || continue
    _name="$(basename "$_dir")"
    if [[ "$_name" =~ GE-Proton([0-9]+)-([0-9]+) ]]; then
      _major="${BASH_REMATCH[1]}"
      _minor="${BASH_REMATCH[2]}"
      if [[ "$_major" -gt "$_cur_major" ]] || \
         { [[ "$_major" -eq "$_cur_major" ]] && [[ "$_minor" -gt "$_cur_minor" ]]; }; then
        _cur_major="$_major"
        _cur_minor="$_minor"
        _latest="$_name"
      fi
    fi
  done

  echo "${_latest:-}"
}

install_ge_proton() {
  if ! command_exists protonup-rs; then
    package_explain_block "$(msg proton.install_title)" protonup
    if ! offer_logical_packages true protonup; then
      log_warn "$(msg proton.skipped)"
      return 1
    fi
  fi

  require_command protonup-rs "$(msg proton.install_cmd_hint)"

  if confirm "$(msg proton.confirm_install)"; then
    ui_running "protonup-rs GE-Proton"
    protonup-rs -q --tool "$PROTONUP_TOOL" --version latest --for steam
    ui_done "$(msg proton.done)"
  else
    log_warn "$(msg proton.skipped)"
    log_hint "$(msg offer.manual_label)"
    log_hint "$(msg proton.manual_cmd)"
    return 1
  fi

  if list_ge_proton; then
    log_ok "$(msg proton.versions)"
    list_ge_proton
  else
    log_warn "$(msgf proton.not_found_dir "$PROTON_GE_DIR")"
    return 1
  fi

  return 0
}

verify_ge_proton() {
  if list_ge_proton >/dev/null 2>&1; then
    log_ok "$(msg proton.verified)"
    list_ge_proton
    return 0
  fi

  log_warn "$(msg proton.missing)"
  log_hint "$(msg proton.run_install)"
  return 1
}
