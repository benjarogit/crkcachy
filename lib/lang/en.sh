#!/usr/bin/env bash
# English strings – loaded by lib/i18n.sh

_MSG[tag.info]="INFO"
_MSG[tag.ok]=" OK "
_MSG[tag.warn]="NOTE"
_MSG[tag.error]="ERROR"

_MSG[lang.detected]="Language: English (auto-detected)"
_MSG[lang.override]="Language: English (--lang)"

_MSG[banner.subtitle]="Help for CachyOS + Steam – step by step"

_MSG[confirm.suffix_no]="(y=yes / N=no, Enter=no): "
_MSG[confirm.suffix_yes]="(Y=yes / n=no, Enter=yes): "

_MSG[cmd.not_found]="not found."
_MSG[cmd.not_found_hint]="not found. %s"

_MSG[paru.all_installed]="All packages are already installed."
_MSG[paru.missing]="These packages are still missing: %s"
_MSG[paru.explain_title]="What happens now?"
_MSG[paru.explain_body]=$'paru installs missing programs from CachyOS/Arch.\nYou may need to enter your password (sudo).\nDuration: a few minutes depending on your internet.'
_MSG[paru.confirm_install]="Install missing packages now?"
_MSG[paru.install_paru_hint]="Install paru first: sudo pacman -S paru"
_MSG[paru.done]="Package installation finished."
_MSG[paru.skipped]="Installation skipped."
_MSG[paru.manual]="Install manually later: paru -S --needed %s"

_MSG[tools.none]="No game tools found."
_MSG[tools.setup_title]="Which game do you want to set up?"
_MSG[tools.setup_body]=$'CRKCACHY auto-discovers games in the tools/ folder.\nYou pick a game – the tool checks your folder and shows Steam steps.\nNothing hidden is installed unless you confirm system packages.'
_MSG[tools.list_title]="Available games (plugin list):"
_MSG[tools.list_dynamic]="New games appear here automatically when a tools/<name>/ package is added."
_MSG[tools.opt_all]="Set up all games one after another"
_MSG[tools.pick_number]="Enter number (a=all, empty=skip): "
_MSG[tools.none_selected]="No game selected."
_MSG[tools.invalid]="Invalid input – pick a number from the list."
_MSG[tools.starting]="Starting: %s …"
_MSG[tools.another]="Set up another game?"
_MSG[tools.done]="Game setup finished."

_MSG[tool.house-of-ashes.name]="House of Ashes"
_MSG[tool.house-of-ashes.desc]="The Dark Pictures – Steam + Proton + multiplayer"

_MSG[wizard.title]="What do you want to do?"
_MSG[wizard.body]=$'The installer does not know what you need – you choose here.\nEverything is numbered: type the number, press Enter.'
_MSG[wizard.opt1]="Everything: prepare PC + pick game (recommended for beginners)"
_MSG[wizard.opt2]="Only prepare PC (packages, Proton, Spacewar)"
_MSG[wizard.opt3]="Only set up a game (PC already ready)"
_MSG[wizard.opt4]="Check only – install nothing"
_MSG[wizard.prompt]="Your choice (1–4): "
_MSG[wizard.invalid]="Invalid choice – enter 1, 2, 3, or 4."

_MSG[cachyos.ok]="CachyOS detected – OK."
_MSG[cachyos.arch_warn]="Arch Linux detected, but not CachyOS."
_MSG[cachyos.arch_hint]="CRKCACHY is tested on CachyOS – may still work."
_MSG[cachyos.other_warn]="Non-Arch/CachyOS system detected."
_MSG[cachyos.other_hint]="CRKCACHY targets CachyOS/Arch."

_MSG[paru.ok]="paru is installed (package installer for extras)."
_MSG[paru.missing_warn]="paru is missing."
_MSG[paru.install_hint]="Install with: sudo pacman -S paru"

_MSG[steam.ok]="Steam is installed."
_MSG[steam.missing_warn]="Steam is not installed."
_MSG[steam.install_hint]="Install with: paru -S steam"
_MSG[steam.data_ok]="Steam data found: %s"
_MSG[steam.data_missing]="Steam folder not found."
_MSG[steam.data_hint]="Launch Steam and log in once, then try again."

_MSG[spacewar.ok]="Spacewar (App %s) is installed."
_MSG[spacewar.missing]="Spacewar missing – needed for some games (free Steam title)."
_MSG[spacewar.hint1]="Open in Steam: steam://install/480"
_MSG[spacewar.hint2]="Or search library for “Spacewar” and install."

_MSG[overlay.title]="Steam overlay (important for in-game invites)"
_MSG[overlay.body]=$'The overlay is the Steam menu in-game (usually Shift+Tab).\nWithout overlay, invites often fail.\n\nIn Steam: Settings → In-Game →\n“Enable Steam Overlay while in-game” must be ON.'

_MSG[protonup.ok]="protonup-rs is installed (installs Proton for Steam)."
_MSG[protonup.missing]="protonup-rs is missing."
_MSG[protonup.install_hint]="Install with: paru -S protonup-rs-bin"
_MSG[proton.install_title]="Install GE-Proton"
_MSG[proton.install_body]=$'GE-Proton is a special Steam build of Proton.\nIt runs many Windows games on Linux.\nprotonup-rs downloads GE-Proton for Steam.\nDuration: 1–5 minutes depending on internet.'
_MSG[proton.confirm_install]="Install GE-Proton for Steam now?"
_MSG[proton.install_cmd_hint]="Install first: paru -S protonup-rs-bin"
_MSG[proton.running]="Running protonup-rs …"
_MSG[proton.done]="protonup-rs finished."
_MSG[proton.skipped]="GE-Proton installation skipped."
_MSG[proton.versions]="Installed GE-Proton versions:"
_MSG[proton.not_found_dir]="No GE-Proton in %s found."
_MSG[proton.verified]="GE-Proton is installed:"
_MSG[proton.missing]="No GE-Proton found."
_MSG[proton.run_install]="Install with ./install.sh"

_MSG[install.step1]="═══ Step 1: Quick check if your PC is ready ═══"
_MSG[install.step2]="═══ Step 2: Install helper programs ═══"
_MSG[install.step3]="═══ Step 3: GE-Proton (Windows games on Linux) ═══"
_MSG[install.step4]="═══ Step 4: Check Spacewar (small free Steam game) ═══"
_MSG[install.step5]="═══ Step 5: Set up your game ═══"
_MSG[install.status_title]="═══ Check only – nothing will be installed ═══"
_MSG[install.packages_title]="═══ Individual packages ═══"
_MSG[install.pkg_missing]="missing: %s"

_MSG[install.packages_explain_title]="What are these packages?"
_MSG[install.packages_explain_body]=$'Small extras so games run on Linux:\n• protonup-rs – installs Proton (Windows games on Linux)\n• vkd3d / gamemode – graphics and performance\n• winetricks – if DLL errors appear later\n\nIf it says “already installed” below: nothing to do.'

_MSG[install.qt_title]="Optional: protonup-qt (program with windows)"
_MSG[install.qt_body]=$'protonup-qt is ONLY a graphical interface – a settings menu for Proton.\nYou already have protonup-rs (command line). That is enough almost always.\n\n→ GE-Proton already installed? Answer: N (Enter)\n→ Only y if you want a mouse-driven Proton GUI'
_MSG[install.qt_confirm]="Also install protonup-qt (GUI)?"
_MSG[install.qt_skipped]="protonup-qt skipped – that is fine."

_MSG[install.vulkan_title]="Optional: Vulkan driver helpers"
_MSG[install.vulkan_body]=$'Vulkan helps your GPU (NVIDIA or AMD) display games.\nIf already installed: N (Enter).\nIf unsure and not everything is installed yet: y'
_MSG[install.vulkan_confirm]="Install Vulkan helpers (vulkan-icd-loader)?"
_MSG[install.vulkan_skipped]="Vulkan installation skipped."

_MSG[install.steam_missing]="Steam is still missing."
_MSG[install.steam_title]="Install Steam"
_MSG[install.steam_body]="Steam is the game client – this setup requires it."
_MSG[install.steam_confirm]="Install Steam now?"

_MSG[install.protonup_missing]="protonup-rs missing – confirm step 2 with y first."
_MSG[install.ge_present_title]="GE-Proton is already installed"
_MSG[install.ge_present_body]=$'You already have a GE-Proton version.\nUpdating is usually NOT needed.\n\n→ Continue normally: N (Enter)\n→ Only y if you explicitly want the latest version'
_MSG[install.ge_update_confirm]="Re-install / update GE-Proton anyway?"
_MSG[install.ge_kept]="GE-Proton stays as is – good."
_MSG[install.ge_missing_title]="GE-Proton is still missing"
_MSG[install.ge_missing_body]=$'It will be downloaded now. In Steam you can later pick\n“GE-Proton10-34” (or similar) under Compatibility.'

_MSG[install.spacewar_title]="Why Spacewar?"
_MSG[install.spacewar_body]=$'Some setups (e.g. House of Ashes) need a hidden Steam game called Spacewar.\nIt is free and small.\n\nIf OK below: do nothing.\nIf missing: install in Steam (link shown).'

_MSG[install.tool_confirm]="Start game tool now (e.g. House of Ashes)?"
_MSG[install.tool_later]="Run later with:"
_MSG[install.tools_none]="No game tools found."

_MSG[install.all_ready]="All ready! Next step:"
_MSG[install.points_open]="%s item(s) open, %s OK."
_MSG[install.run_setup]="Start setup: ./install.sh"

_MSG[install.legal_title]="Important before you start"
_MSG[install.legal_body]=$'CRKCACHY does NOT include games or fix files.\nYou need a legal copy and must apply fixes yourself.\nDetails: docs/legal.md'
_MSG[install.how_title]="How to answer?"
_MSG[install.how_body]=$'For each question:\n  y or j = yes, do it\n  N or Enter = no, skip\n\nIf something is already installed, “no” is usually correct.'
_MSG[install.start_confirm]="Start setup?"
_MSG[install.cancelled]="Cancelled."
_MSG[install.status_hint]="Check only: ./install.sh --status"
_MSG[install.finished]="═══ CRKCACHY setup finished ═══"
_MSG[install.next_readme]="Continue with the game guide:"

_MSG[ha.intro_title]="Set up House of Ashes"
_MSG[ha.intro_body]=$'This tool checks your game folder and shows\nwhat to enter in Steam.\nIt does not install anything automatically – follow the list.'
_MSG[ha.pc_check]="═══ Quick PC check ═══"
_MSG[ha.folder_title]="Game folder"
_MSG[ha.folder_body]=$'The folder that contains HouseOfAshes.exe.\nNot the .exe itself – the parent folder!'
_MSG[ha.default_path]="Default path (Enter = use this):"
_MSG[ha.folder_prompt]="Game folder (or Enter): "
_MSG[ha.using_path]="Using: %s"
_MSG[ha.dir_missing]="Folder does not exist: %s"
_MSG[ha.check_folder]="═══ Check game folder (read-only) ═══"
_MSG[ha.fix_missing]="Fix files missing – see README part B"
_MSG[ha.readme_hint]="Full guide: tools/house-of-ashes/README.en.md"
_MSG[ha.done]="Done – complete the Steam steps above."

_MSG[ha.steam_title]="  Now in Steam – step by step with the mouse"
_MSG[ha.steam_step1]="① Add game"
_MSG[ha.steam_step1_detail]=$'   Steam → Game → Add a Non-Steam Game → Browse\n   Select this file:'
_MSG[ha.steam_step2]="② Enable Proton"
_MSG[ha.steam_step2_detail]=$'   Right-click game → Properties → Compatibility\n   “Force Steam Play” ON → pick GE-Proton10-34'
_MSG[ha.steam_step3]="③ Launch options (General tab) – copy and paste ALL of this:"
_MSG[ha.steam_step3_warn]="   Without this line: trial “Buy full game” often appears!"
_MSG[ha.steam_step4]="④ Overlay"
_MSG[ha.steam_step4_detail]=$'   Steam Settings → In-Game → Overlay ON\n   Test in game: Shift + Tab'
_MSG[ha.steam_step5]="⑤ Launch only from Steam library (Play), not double-click!"

_MSG[ha.check.usage]="Usage: %s <game_folder>"
_MSG[ha.check.usage_desc]="  Validates extract folder – changes nothing."
_MSG[ha.check.checking]="Checking: %s"
_MSG[ha.check.exe_ok]="HouseOfAshes.exe found"
_MSG[ha.check.exe_missing]="HouseOfAshes.exe missing in game folder"
_MSG[ha.check.dir_missing]="Folder missing: %s"
_MSG[ha.check.file_ok]="%s"
_MSG[ha.check.file_missing]="missing: %s"
_MSG[ha.check.ini_ok]="OnlineFix.ini: FakeAppId=%s, RealAppId=%s"
_MSG[ha.check.ini_bad]="OnlineFix.ini: App IDs do not match."
_MSG[ha.check.ini_hint]="Expected: FakeAppId=%s and RealAppId=%s"
_MSG[ha.check.steam_api_ok]="steam_api64.dll present"
_MSG[ha.check.steam_api_missing]="missing: %s"
_MSG[ha.check.steam_api_hint]="Online fix usually replaces this file"
_MSG[ha.check.flt_warn]="%s/%s found – may conflict with Online-Fix"
_MSG[ha.check.appid_warn]="steam_appid.txt in game folder – usually not needed for Steam launch"
_MSG[ha.check.all_ok]="All OK – continue with Steam (see README)"
_MSG[ha.check.errors]="%s problem(s) – check online fix / paths (README part B)"
_MSG[ha.check.dir_not_found]="Folder not found: %s"
