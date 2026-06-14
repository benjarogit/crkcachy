#!/usr/bin/env bash
# CRKCACHY i18n – automatic DE/EN from system locale

set -euo pipefail

declare -gA _MSG=()
CRKCACHY_LANG="${CRKCACHY_LANG:-}"

detect_system_lang() {
  local lc="${LANG:-${LC_ALL:-${LC_MESSAGES:-en}}}"

  if [[ "$lc" =~ ^de || "$lc" =~ _DE || "$lc" =~ \.de ]]; then
    return 0 # de
  fi
  return 1 # en
}

init_i18n() {
  local lang="${CRKCACHY_LANG:-}"

  if [[ -z "$lang" ]]; then
    if detect_system_lang; then
      lang=de
    else
      lang=en
    fi
  fi

  case "$lang" in
    de|DE|deutsch) lang=de ;;
    en|EN|english) lang=en ;;
    *)
      log_warn_fallback "Unknown language '$lang', using English."
      lang=en
    ;;
  esac

  CRKCACHY_LANG="$lang"
  export CRKCACHY_LANG

  local lang_file="${CRKCACHY_ROOT}/lib/lang/${CRKCACHY_LANG}.sh"
  if [[ ! -f "$lang_file" ]]; then
    lang_file="${CRKCACHY_ROOT}/lib/lang/en.sh"
    CRKCACHY_LANG=en
  fi

  # shellcheck source=lib/lang/en.sh
  source "$lang_file"
}

log_warn_fallback() {
  echo "[WARN] $*" >&2
}

msg() {
  local key="$1"
  echo "${_MSG[$key]:-$key}"
}

msgf() {
  local key="$1"
  shift
  # shellcheck disable=SC2059
  printf "${_MSG[$key]:-$key}" "$@"
}

# Remove --lang de|en from arguments (for scripts that need other args)
# Parse --lang de|en from script arguments (call before init_i18n)
parse_lang_arg() {
  local arg prev=""
  for arg in "$@"; do
    if [[ "$prev" == "--lang" ]]; then
      CRKCACHY_LANG="$arg"
      CRKCACHY_LANG_PRESET=1
    elif [[ "$arg" == --lang=* ]]; then
      CRKCACHY_LANG="${arg#*=}"
      CRKCACHY_LANG_PRESET=1
    fi
    prev="$arg"
  done
}

# Remove --lang from args (for scripts with other positional arguments)
filter_lang_args() {
  local filtered=()
  local skip_next=false
  local arg

  for arg in "$@"; do
    if [[ "$skip_next" == true ]]; then
      skip_next=false
      continue
    fi
    if [[ "$arg" == --lang ]]; then
      skip_next=true
      continue
    fi
    if [[ "$arg" == --lang=* ]]; then
      continue
    fi
    filtered+=("$arg")
  done

  FILTERED_ARGS=("${filtered[@]}")
}
