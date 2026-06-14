#!/usr/bin/env bash
# House of Ashes tool installer – path validation + Steam checklist

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$(cd "${TOOL_DIR}/../../" && pwd)"

# shellcheck source=lib/common.sh
source "${CRKCACHY_ROOT}/lib/common.sh"
# shellcheck source=lib/steam.sh
source "${CRKCACHY_ROOT}/lib/steam.sh"
# shellcheck source=lib/proton.sh
source "${CRKCACHY_ROOT}/lib/proton.sh"

GAME_EXE="HouseOfAshes.exe"
DEFAULT_HINT="~/Downloads/extracted/The Dark Pictures Anthology - House of Ashes"

print_steam_checklist() {
  local exe_path="$1"
  local launch_opts
  launch_opts="$(cat "${TOOL_DIR}/launch-options.txt")"

  echo ""
  echo -e "${_C_BOLD}=== Steam checklist (manual) ===${_C_RESET}"
  echo ""
  echo "1. Steam → Add a Game → Add a Non-Steam Game"
  echo "   Select: ${exe_path}"
  echo ""
  echo "2. Properties → Compatibility"
  echo "   Force: GE-Proton10-34 (or latest GE-Proton from protonup)"
  echo "   Alternative: proton-cachyos-* (one-time sniper runtime download is normal)"
  echo ""
  echo "3. Properties → General → Launch Options (copy exactly):"
  echo ""
  echo "   ${launch_opts}"
  echo ""
  echo "4. Steam → Settings → In-Game → Enable Steam Overlay"
  echo "   Test with Shift+Tab in the lobby (needed for invites)."
  echo ""
  echo "5. Spacewar (App 480) must be installed – see master install.sh"
  echo ""
  echo "6. First launch may download Steam Linux Runtime (sniper) – wait until finished."
  echo ""
}

main() {
  print_banner
  log_info "Tool: The Dark Picture Anthology – House of Ashes"
  log_info "Legal: You need legal game files and a self-applied online fix."
  echo ""

  check_steam || true
  check_spacewar || true
  verify_ge_proton || true
  echo ""

  log_info "Enter path to your extracted game folder."
  log_info "Hint: ${DEFAULT_HINT}"
  read -r -p "Game directory: " game_dir

  game_dir="${game_dir/#\~/$HOME}"
  game_dir="${game_dir%/}"

  if [[ -z "$game_dir" ]]; then
    die "No path entered."
  fi

  if [[ ! -d "$game_dir" ]]; then
    die "Directory does not exist: $game_dir"
  fi

  echo ""
  bash "${TOOL_DIR}/checks.sh" "$game_dir" || log_warn "Some checks failed – see messages above."
  echo ""

  local exe_path="${game_dir}/${GAME_EXE}"
  print_steam_checklist "$exe_path"

  log_info "Multiplayer: Host → Shared Story → Invite."
  log_info "Friend needs: same fix, Steam online, same launch options."
  log_info "Full guide: ${TOOL_DIR}/README.md"
  log_ok "House of Ashes tool finished."
}

main "$@"
