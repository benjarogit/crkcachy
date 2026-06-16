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

# Parse --debug, --reset, --validate-only, --install, --uninstall, --check, --action= (call before common.sh)
parse_cli_arg() {
  local arg prev=""
  for arg in "$@"; do
    if [[ "$prev" == "--tool" ]]; then
      CRKCACHY_TOOL="$arg"
    elif [[ "$prev" == "--game-dir" ]]; then
      CRKCACHY_GAME_DIR="$arg"
    else
      case "$arg" in
        --debug) CRKCACHY_DEBUG=1 ;;
        --reset) CRKCACHY_RESET=1; CRKCACHY_ACTION=reset ;;
        --skip-intro) CRKCACHY_SKIP_INTRO=1 ;;
        --force-intro) CRKCACHY_FORCE_INTRO=1 ;;
        --validate-only|--validate) CRKCACHY_CHECK_ONLY=1; CRKCACHY_ACTION=check ;;
        --install) CRKCACHY_INSTALL=1; CRKCACHY_ACTION=install ;;
        --uninstall) CRKCACHY_UNINSTALL=1; CRKCACHY_ACTION=uninstall ;;
        --check) CRKCACHY_CHECK_ONLY=1; CRKCACHY_ACTION=check ;;
        --tool=*) CRKCACHY_TOOL="${arg#*=}" ;;
        --game-dir=*) CRKCACHY_GAME_DIR="${arg#*=}" ;;
        --tool|--game-dir) ;;
        --action=*) CRKCACHY_ACTION="${arg#*=}" ;;
      esac
    fi
    prev="$arg"
  done
}

filter_cli_args() {
  local filtered=()
  local arg prev=""

  for arg in "$@"; do
    if [[ "$prev" == "--tool" ]]; then
      prev="$arg"
      continue
    fi
    if [[ "$prev" == "--game-dir" ]]; then
      prev="$arg"
      continue
    fi
    case "$arg" in
      --debug|--reset|--validate-only|--validate|--install|--uninstall|--check|--tool|--game-dir|--skip-intro|--force-intro)
        prev="$arg"
        continue
        ;;
      --tool=*|--game-dir=*|--action=*) prev="$arg"; continue ;;
      *) filtered+=("$arg") ;;
    esac
    prev="$arg"
  done

  FILTERED_CLI_ARGS=("${filtered[@]}")
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
