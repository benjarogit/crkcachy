#!/usr/bin/env bash
# Download game tools from GitHub on demand (sparse clone)

set -euo pipefail

tool_fetch_git_available() {
  command_exists git
}

tool_fetch_ensure_repo() {
  local repo_url="${CRKCACHY_REPO_URL}"
  local branch="${CRKCACHY_REPO_BRANCH}"
  local cache="${CRKCACHY_TOOLS_CACHE}"

  if ! tool_fetch_git_available; then
    log_warn "$(msg tools.fetch_no_git)"
    return 1
  fi

  if [[ ! -d "${cache}/.git" ]]; then
    log_info "$(msg tools.fetch_cloning)"
    mkdir -p "$(dirname "$cache")"
    if ! git clone --depth 1 --filter=blob:none --sparse -b "$branch" "$repo_url" "$cache" 2>/dev/null; then
      log_error "$(msg tools.fetch_clone_failed)"
      return 1
    fi
    git -C "$cache" sparse-checkout set lib tools 2>/dev/null || true
    log_ok "$(msg tools.fetch_clone_ok)"
    return 0
  fi

  log_debug "updating tool cache: $cache"
  if ! git -C "$cache" pull --ff-only --quiet 2>/dev/null; then
    log_warn "$(msg tools.fetch_pull_warn)"
  fi
  return 0
}

tool_fetch_slug() {
  local slug="$1"
  local cache="${CRKCACHY_TOOLS_CACHE}"
  local tool_path="${cache}/tools/${slug}"

  if [[ -f "${tool_path}/install.sh" ]]; then
    log_ok "$(msgf tools.fetch_already "$slug")"
    tool_fetch_chmod_tool "$tool_path"
    return 0
  fi

  if ! tool_fetch_ensure_repo; then
    return 1
  fi

  ui_action "$(msgf tools.fetch_downloading "$(tool_catalog_get_name "$slug")")"

  if ! git -C "$cache" sparse-checkout add "tools/${slug}" 2>/dev/null; then
    log_error "$(msgf tools.fetch_failed "$slug")"
    return 1
  fi

  if ! git -C "$cache" checkout --quiet 2>/dev/null; then
    log_error "$(msgf tools.fetch_failed "$slug")"
    return 1
  fi

  if [[ ! -f "${tool_path}/install.sh" ]]; then
    log_error "$(msgf tools.fetch_failed "$slug")"
    return 1
  fi

  tool_fetch_chmod_tool "$tool_path"
  log_ok "$(msgf tools.fetch_ok "$(tool_catalog_get_name "$slug")")"
  return 0
}

tool_fetch_chmod_tool() {
  local tool_dir="$1"
  local f
  for f in "${tool_dir}"/*.sh; do
    [[ -f "$f" ]] || continue
    chmod +x "$f" 2>/dev/null || true
  done
}

tool_fetch_update_catalog() {
  tool_catalog_fetch_index >/dev/null 2>&1 || true
}

# Ensure tool is on disk; download from GitHub if listed in catalog only.
tool_ensure_ready() {
  local slug="$1"

  if tool_resolve_install_path "$slug" >/dev/null 2>&1; then
    return 0
  fi

  log_info "$(msgf tools.fetch_downloading "$(tool_catalog_get_name "$slug")")"
  tool_fetch_update_catalog
  tool_fetch_slug "$slug"
}
