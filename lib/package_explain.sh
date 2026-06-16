#!/usr/bin/env bash
# Explain logical packages before install – what they are and why CRKCACHY needs them

set -euo pipefail

package_explain_text() {
  local logical="$1"
  local key="pkg.explain.${logical}"
  local text="${_MSG[$key]:-}"

  if [[ -z "$text" ]]; then
    text="$(msgf pkg.explain.fallback "$(platform_logical_display_name "$logical")")"
  fi

  echo "$text"
}

package_explain_short() {
  local logical="$1"
  local key="pkg.explain_short.${logical}"
  local text="${_MSG[$key]:-}"

  if [[ -z "$text" ]]; then
    text="$(platform_logical_display_name "$logical")"
  fi

  echo "$text"
}

package_install_plan_lines() {
  local logical line n=1
  for logical in "$@"; do
    line="$(msgf ui.install_plan_line "$n" "$(platform_logical_display_name "$logical")" "$(package_explain_short "$logical")")"
    echo "$line"
    n=$((n + 1))
  done
}

package_install_plan_block() {
  local title="$1"
  shift
  local -a lines=()

  while IFS= read -r line; do
    [[ -n "$line" ]] && lines+=("$line")
  done < <(package_install_plan_lines "$@")

  cui_install_plan "$title" "$(msg pkg.install_plan_intro)" "${lines[@]}"
}

# Show what each logical package is and why it is needed.
package_explain_block() {
  local title="$1"
  shift
  local logical body="" part

  for logical in "$@"; do
    part="$(package_explain_text "$logical")"
    if [[ -n "$body" ]]; then
      body="${body}

${part}"
    else
      body="$part"
    fi
  done

  body="${body}

$(msg pkg.explain.footer)"

  explain_block "$title" "$body"
}

package_collect_missing_logical() {
  local -n _out_ref=$1
  shift
  local logical

  _out_ref=()
  for logical in "$@"; do
    if platform_logical_known "$logical"; then
      platform_logical_installed "$logical" || _out_ref+=("$logical")
    elif ! pacman_installed "$logical"; then
      _out_ref+=("$logical")
    fi
  done
}

package_missing_display_names() {
  local logical names=()
  for logical in "$@"; do
    names+=("$(platform_logical_display_name "$logical")")
  done
  echo "${names[*]}"
}

# Explain missing packages, then offer install (repo or full/AUR installer).
offer_logical_packages() {
  local use_full_installer="${1:-false}"
  shift
  local packages=("$@")
  local missing=()
  local missing_display resolved_manual=()
  local -a all_native=()

  package_collect_missing_logical missing "${packages[@]}"

  if [[ ${#missing[@]} -eq 0 ]]; then
    log_ok "$(msg paru.all_installed)"
    return 0
  fi

  missing_display="$(package_missing_display_names "${missing[@]}")"
  log_info "$(msgf paru.missing "$missing_display")"
  package_install_plan_block "$(msg pkg.install_plan_title)" "${missing[@]}"
  package_explain_block "$(msg pkg.explain.detail_title)" "${missing[@]}"

  while IFS= read -r -d '' pkg; do
    all_native+=("$pkg")
  done < <(_resolve_install_packages "${missing[@]}")

  if [[ ${#all_native[@]} -gt 0 ]]; then
    resolved_manual="$(platform_manual_install_cmd "${all_native[@]}")"
  else
    resolved_manual="# install: ${missing_display}"
  fi

  if ! confirm "$(msg pkg.confirm_install)"; then
    log_warn "$(msg paru.skipped)"
    log_hint "$(msg offer.manual_label)"
    log_hint "$resolved_manual"
    return 1
  fi

  if [[ "$use_full_installer" == true ]]; then
    if install_system_packages true "${missing[@]}"; then
      log_ok "$(msg paru.done)"
      return 0
    fi
  else
    if install_repo_packages true "${missing[@]}"; then
      log_ok "$(msg paru.done)"
      return 0
    fi
  fi

  log_warn "$(msg paru.install_failed)"
  log_hint "$resolved_manual"
  return 1
}
