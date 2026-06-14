#!/usr/bin/env bash
# English strings – loaded by lib/i18n.sh

_MSG[tag.info]="INFO"
_MSG[tag.ok]=" OK "
_MSG[tag.warn]="NOTE"
_MSG[tag.error]="ERROR"

_MSG[lang.detected]="Language: English (auto-detected)"
_MSG[lang.override]="Language: English (--lang)"

_MSG[banner.subtitle]="Standalone games via Steam + Proton – no Bottles"

_MSG[confirm.suffix]="[y=Yes · n=No · Enter=recommended]"
_MSG[confirm.yes_label]="Yes"
_MSG[confirm.no_label]="No"

_MSG[cmd.not_found]="not found."
_MSG[cmd.not_found_hint]="not found. %s"

_MSG[paru.all_installed]="All packages are already installed."
_MSG[paru.missing]="These packages are still missing: %s"
_MSG[paru.explain_title]="What happens now?"
_MSG[paru.explain_body]=$'paru installs missing programs from CachyOS/Arch.\nYou may need to enter your password (sudo).\nDuration: a few minutes depending on your internet.'
_MSG[paru.confirm_install]="Install missing packages now?"
_MSG[paru.installing]="Installing packages …"
_MSG[paru.install_failed]="Installation did not succeed."
_MSG[paru.confirm_self]="Install paru now?"
_MSG[paru.self_title]="paru is missing"
_MSG[paru.self_body]=$'paru installs extra programs on CachyOS.\nYou can install it automatically now or run the command below manually.'
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
_MSG[tools.opt_skip]="Skip"
_MSG[tools.pick_number]="Number (a=all · Enter=skip): "
_MSG[tools.none_selected]="No game selected."
_MSG[tools.invalid]="Invalid input – pick a number from the list."
_MSG[tools.starting]="Starting: %s …"
_MSG[tools.another]="Set up another game?"
_MSG[tools.done]="Game setup finished."

_MSG[tool.house-of-ashes.name]="House of Ashes"
_MSG[tool.house-of-ashes.desc]="The Dark Pictures – Steam + Proton + multiplayer"

_MSG[wizard.title]="What do you want to do now?"
_MSG[wizard.choose_hint]="↑↓ pick · Enter confirms"
_MSG[wizard.hint_ready]="Your PC is ready – set up the game next."
_MSG[wizard.hint_fix]="Something is still missing on your PC – fix that first."
_MSG[wizard.hint_full]="Best to start with the full walkthrough."
_MSG[wizard.opt1]="PC + game (full walkthrough)"
_MSG[wizard.opt2]="Fix PC only (if something is missing above)"
_MSG[wizard.opt3]="Set up game in Steam (House of Ashes, etc.)"
_MSG[wizard.opt4]="Show list again"
_MSG[wizard.prompt]="1–4 or Enter: "
_MSG[wizard.invalid]="That was not 1, 2, 3, or 4. Try again."

_MSG[assess.title]="Quick check: is your PC ready for the game?"
_MSG[assess.all_ready]="All OK – Steam, Proton, and helper packages are there."
_MSG[assess.all_ready_hint]="Nothing left to install on your PC. Next: add the game in Steam."
_MSG[assess.not_ready]="Something is still missing on your PC – see list below."
_MSG[assess.score]="%s checks OK · %s open"
_MSG[assess.missing_list]="Still missing:"
_MSG[assess.missing_pkgs]="Missing programs (asked one by one):"
_MSG[assess.next_title]="Your next step"
_MSG[assess.next_ready_body]=$'Your PC is ready.\n\nNow it is about the game:\n• Check your game folder\n• Guide for what to enter in Steam\n• Launch options to copy\n\n→ Type 3 below or just press Enter.'
_MSG[assess.next_fix_body]=$'Something is still missing on your PC for Linux gaming.\n\n→ Type 2 below or just Enter.\nThen check again, then game with 3.'
_MSG[assess.next_full_body]=$'You are new or much is still missing.\n\n→ Type 1 below or just Enter.'
_MSG[assess.menu_recommended]="  ← recommended"
_MSG[assess.menu_recommended_plain]="← recommended"
_MSG[assess.issue.cachyos]="Not CachyOS (note – often still OK)"
_MSG[assess.issue.paru]="paru missing (package installer)"
_MSG[assess.issue.steam_data]="Steam folder not found – launch Steam & log in"
_MSG[assess.issue.protonup]="protonup-rs missing"
_MSG[assess.issue.ge_proton]="GE-Proton missing"
_MSG[assess.issue.spacewar]="Spacewar (App 480) missing"
_MSG[assess.issue.platform_partial]="Non-Arch Linux – game help possible, auto-setup limited"
_MSG[assess.issue_pkg]="Package missing: %s"

_MSG[platform.detected]="System: %s (%s)"
_MSG[platform.helper]="Extra installer: %s"
_MSG[platform.tier_full]="full support"
_MSG[platform.tier_partial]="partial support"
_MSG[platform.tier_unsupported]="not tested"
_MSG[platform.tier_partial_hint]="Game packages (Proton-GE, Vulkan) are optimized for Arch/CachyOS."
_MSG[platform.tier_partial_warn]="Your Linux is only partially supported – game auto-setup may be limited."
_MSG[platform.tier_unsupported_warn]="This Linux is not tested – installation may fail."
_MSG[platform.rosetta_hint]="Package names are adapted for your system – the correct commands are used automatically."
_MSG[platform.rosetta_manual]="No package mapping for %s on this Linux – install manually (see docs/platform-rosetta.md)."

_MSG[assess.issue.arch_only]="%s is Arch/CachyOS only – check manually on your Linux"
_MSG[assess.issue_pkg_manual]="%s – install manually on your Linux (see docs/platform-rosetta.md)"

_MSG[runtime.item_os_cachyos]="CachyOS"
_MSG[runtime.item_os_arch]="Linux (%s)"
_MSG[runtime.item_os_other]="Linux (%s, limited)"
_MSG[runtime.item_os_unknown]="Linux (%s, unknown)"
_MSG[assess.install_one]="Single package: %s"
_MSG[assess.confirm_one]="Install package %s now?"
_MSG[assess.pkg_already]="%s is already installed."
_MSG[assess.fix_title]="Step-by-step repair"
_MSG[assess.fix_body]=$'We will fix missing items one by one.\nFor each package: y = install, N = skip.\nWhen all green, you can continue.'
_MSG[assess.fix_round]="Repair round %s"
_MSG[assess.fix_continue]="Keep trying even though something is still open?"
_MSG[assess.fix_stopped]="Repair stopped – PC not fully ready yet."
_MSG[assess.block_game]="Game setup blocked: PC is not ready yet."
_MSG[assess.fix_now]="Fix missing parts now?"
_MSG[assess.block_game_still]="Game setup cancelled – fix PC first (menu item 2)."
_MSG[assess.pc_already_ok]="PC is already ready – nothing to install."
_MSG[assess.status_hint]="Start setup: ./install.sh"

_MSG[status.view_only]="Quick overview"
_MSG[status.view_only_body]=$'That was only an overview.\n\nTo set up, run:\n  ./install.sh\n\nThen press Enter or 3.'
_MSG[status.ready_next]="All OK? Start now: ./install.sh"

_MSG[ui.running]="Running: %s …"
_MSG[ui.done]="Done: %s"
_MSG[ui.press_enter]="Continue?"
_MSG[ui.ok_label]="Continue"
_MSG[ui.markdown_scroll_hint]="Mouse wheel = scroll in the window"
_MSG[ui.badge_recommended]="★ RECOMMENDED"
_MSG[cui.choice_yes]="✓ Yes"
_MSG[cui.choice_no]="✗ No"
_MSG[cui.input_prompt]="›"
_MSG[ui.legal_confirm]="Understood – continue?"
_MSG[ui.section_pc]="PC check"
_MSG[tools.choose_hint]="↑↓ pick game · Enter confirms"

_MSG[flow.chose]="You chose: %s"
_MSG[flow.chose_3]="Game setup – starting now."
_MSG[flow.chose_2]="Fix PC – starting now."
_MSG[flow.chose_1]="Full walkthrough – starting now."
_MSG[flow.chose_enter]="Enter with no number – starting recommended step."
_MSG[flow.game_tool]="Loading game tool …"

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
_MSG[steam.tooling_title]="Programs for Steam automation"
_MSG[steam.tooling_body]=$'CRKCACHY needs these for name, launch options and icon:\n• python-vdf (read Steam list)\n• icoutils (icon from .exe)\n• imagemagick (format image)\n\nOne-time install – then automatic.'
_MSG[steam.tooling_failed]="Programs missing – automation not possible. Continue manually or retry."
_MSG[steam.close_title]="Close Steam briefly"
_MSG[steam.close_body]=$'For name, launch options and icon to save safely,\nSteam must be **fully** closed (not just the window).\n\nThen restart Steam.'
_MSG[steam.close_confirm]="Steam is closed – continue?"
_MSG[steam.close_still_running]="Steam is still running – please exit fully (Steam → Exit)."
_MSG[steam.close_ok]="Steam is closed – writing data now."
_MSG[steam.close_abort]="Cancelled – automation not possible while Steam is running."
_MSG[steam.shortcut_not_found]="Game not found in Steam list."
_MSG[steam.restart_steam]="Restart Steam now – name, icon and launch options will be active."
_MSG[steam.launch_ok]="Launch options were applied."
_MSG[steam.launch_already]="Launch options were already correct."
_MSG[steam.icon_applied]="Icon set for “%s”"
_MSG[steam.icon_extract_failed]="Could not read icon from .exe."
_MSG[steam.name_renamed]="Name changed: “%s” → “%s”"
_MSG[steam.name_ok]="Name already correct: “%s”"
_MSG[steam.manual_launch_title]="Launch options (manual)"
_MSG[steam.manual_launch_body]="Steam → game → right-click → Properties → General → Launch options:"
_MSG[steam.manual_launch_hint]="Copy and paste all of this – without it you often get Trial “Buy full game”!"
_MSG[steam.desktop_title]="Desktop & app menu"
_MSG[steam.desktop_body]=$'We create a launcher that starts the game **through Steam**\n(with Proton and launch options – not double-clicking the .exe).\n\nName and icon are set correctly.'
_MSG[steam.desktop_confirm]="Create desktop and app menu launcher?"
_MSG[steam.desktop_apps]="App menu: %s"
_MSG[steam.desktop_desktop]="Desktop: %s"
_MSG[steam.desktop_no_icon]="No icon found – launcher without picture (restart Steam or run tool again)."
_MSG[steam.desktop_hint]="Launch via the new entry or Steam library – never double-click the .exe directly."
_MSG[steam.desktop_remove_old]="Remove old broken launcher? (%s)"
_MSG[steam.desktop_removed]="Removed: %s"

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
_MSG[proton.manual_cmd]="Manual: protonup-rs -q --tool GEProton --version latest --for steam"
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

_MSG[install.legal_title]="Quick read, then continue"
_MSG[install.legal_teaser]="No game in the package – guides only. Steam + Proton instead of Bottles."
_MSG[install.legal_body]=$'CRKCACHY does NOT include games or fix files.\nDetails: docs/legal.md'
_MSG[install.start_confirm]="Ready to start?"
_MSG[install.cancelled]="Cancelled."
_MSG[install.status_hint]="Start: ./install.sh"
_MSG[install.finished]="═══ CRKCACHY setup finished ═══"
_MSG[install.next_readme]="Continue with the game guide:"
_MSG[install.show_readme]="Show the game guide now?"

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
_MSG[ha.show_readme]="Show the full guide now?"
_MSG[ha.done]="Done – complete the Steam steps above."

_MSG[ha.steam_title]="  Now in Steam – step by step with the mouse"
_MSG[ha.steam_auto_title]="Set up Steam"
_MSG[ha.steam_auto_body]=$'Automation sets: name “House of Ashes”, launch options and icon.\nSteam must be closed briefly – we will ask you.'
_MSG[ha.steam_auto_confirm]="Set up automatically? (recommended)"
_MSG[ha.steam_auto_done]="Automation done – only Proton and overlay left (see below)."
_MSG[ha.steam_auto_failed]="Automation did not complete everything."
_MSG[ha.steam_manual_fallback]="Show manual steps?"
_MSG[ha.steam_manual_title]="Steam – manual"
_MSG[ha.steam_add_first_title]="Add game to Steam first"
_MSG[ha.steam_add_first_body]=$'Steam → Game → Add a Non-Steam Game → Browse\nSelect this file:'
_MSG[ha.steam_added_confirm]="Game is now added in Steam?"
_MSG[ha.steam_still_missing]="Still not found in Steam – please complete the step above."
_MSG[ha.steam_step1]="① Add game"
_MSG[ha.steam_step1_detail]=$'   Steam → Game → Add a Non-Steam Game → Browse\n   Select this file:'
_MSG[ha.steam_step1_name]="   Name: House of Ashes – CRKCACHY fixes this automatically later."
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

_MSG[offer.manual_label]="Run manually in terminal:"
_MSG[pkg.no_installer]="No package manager found (pacman, apt, dnf, zypper) – cannot install."
_MSG[pkg.explain.title]="What gets installed – and why?"
_MSG[pkg.explain.steam_title]="Install Steam"
_MSG[pkg.confirm_install]="Install now?"
_MSG[pkg.explain.footer]=$'One-time install – your PC may ask for your password (sudo).\nThen we continue. You can say No and run the command manually.'
_MSG[pkg.explain.fallback]="%s – required for CRKCACHY."
_MSG[pkg.explain.gum]=$'**gum** – small menu program.\nYou pick with arrow keys (↑↓) and Enter – like in a game.\nWithout gum there are no choice menus in CRKCACHY.'
_MSG[pkg.explain.glow]=$'**glow** – shows guides in a nice formatted layout.\nEasier to read than raw terminal text.\nWithout glow there are no game guides in CRKCACHY.'
_MSG[pkg.explain.steam]=$'**Steam** – app to play and launch games.\nCRKCACHY sets up your game as a non-Steam game – with Proton for Windows titles.'
_MSG[pkg.explain.paru]=$'**paru** – installs extra programs on CachyOS/Arch.\nNeeded for some packages from the AUR (extra catalog).'
_MSG[pkg.explain.python-vdf]=$'**python-vdf** – reads the Steam game list (shortcuts.vdf).\nLets CRKCACHY set name and launch options automatically.'
_MSG[pkg.explain.icoutils]=$'**icoutils** – reads the game icon from the .exe file.\nWithout it: gray box in Steam.'
_MSG[pkg.explain.imagemagick]=$'**imagemagick** – formats icons as PNG for Steam and desktop.\nUsed with icoutils for the game picture.'
_MSG[pkg.explain.protonup]=$'**ProtonUp** – installs GE-Proton for Steam.\nGE-Proton runs many Windows games better than default Proton.'
_MSG[pkg.explain.winetricks]=$'**winetricks** – Windows helper components for Wine/Proton.\nSome games need extra Windows pieces.'
_MSG[pkg.explain.gamemode]=$'**gamemode** – can make games a bit faster (optional).\nFrees performance while gaming.'
_MSG[pkg.explain.vkd3d]=$'**vkd3d** – DirectX 12 via Vulkan for Proton.\nImportant for modern 3D games.'
_MSG[pkg.explain.gvfs]=$'**gvfs** – file access for programs.\nHelps Steam with folder pick dialogs.'
_MSG[pkg.explain.vulkan-loader]=$'**Vulkan** – graphics base for games on Linux.\nWithout Vulkan many games won’t run or run slowly.'

_MSG[onboard.title]="Let's go"
_MSG[onboard.subtitle]="We check your PC and run the right tools."

_MSG[runtime.intro_title]="What CRKCACHY does"
_MSG[runtime.intro_body]=$'We provide tools so games can run on your PC.\n\nQuick check now:\n• Arrow menu (we set that up)\n• Steam for your game\n• Whether your PC still needs something'
_MSG[runtime.check_title]="Startup check"
_MSG[runtime.check_subtitle]="Checks whether CRKCACHY can run on your PC."
_MSG[runtime.check_all_ok]="All set – menu, guides, and Steam. Let's continue."
_MSG[runtime.missing_suffix]="still missing"
_MSG[runtime.item_menu]="Arrow-key menu (gum)"
_MSG[runtime.item_reader]="Show guides (glow)"
_MSG[runtime.item_packages]="Can install programs"
_MSG[runtime.item_paru]="paru (extra programs, optional)"
_MSG[runtime.item_os]="CachyOS or Linux"
_MSG[runtime.item_steam]="Steam (games app)"
_MSG[runtime.required_fail]="Something important is still missing – see list above."
_MSG[runtime.recommended_open]="%s more point(s) would be nice – not required."
_MSG[runtime.fix_recommended]="Install missing programs now?"
_MSG[runtime.install_steam]="Install Steam now?"
_MSG[runtime.cannot_continue]="Cannot continue without the important items."
_MSG[runtime.legal_ok]="OK – continue"
_MSG[runtime.legal_abort]="Cancelled."
_MSG[runtime.legal_hint]="Help & docs only – no liability. docs/legal.md"

_MSG[runtime.bootstrap_title]="CRKCACHY needs programs on your PC"
_MSG[runtime.bootstrap_body]=$'First two programs for the interface:\n• **gum** – menus with arrow keys (↑↓)\n• **glow** – guides easy to read\n\nLater during game setup other programs may be missing\n(Steam, icon helpers, Proton …) – we explain each one.'
_MSG[runtime.bootstrap_hint]="If something is missing you’ll see what it is and why CRKCACHY needs it."

_MSG[gum.what_is]="gum = menus with arrow keys (↑↓ and Enter)"
_MSG[gum.missing_title]="Now: install gum"
_MSG[gum.missing_body]=$'The program is called gum.\nIt lets you pick in CRKCACHY with arrow keys – like a game menu.\nCRKCACHY needs gum for all choice menus.\n\nInstall once – then we continue.'
_MSG[gum.no_tty]="Please open the terminal (black window) and run it there."
_MSG[gum.pick_title]="How should I install it?"
_MSG[gum.opt_auto]="Do it for me (recommended)"
_MSG[gum.opt_manual]="I'll do it myself"
_MSG[gum.pick_prompt]="1 or 2 (Enter = 1): "
_MSG[gum.pick_invalid]="Please enter 1 or 2."
_MSG[gum.installed]="All good – continuing!"
_MSG[gum.install_failed]="That did not work – try option 2."
_MSG[gum.password_hint]="Your PC may ask for your password."
_MSG[gum.manual_steps_intro]="Type this line in the black window:"
_MSG[gum.manual_pacman]="sudo pacman -S gum"
_MSG[gum.manual_wait]="When done: press Enter …"
_MSG[gum.still_missing]="Not there yet – try again."

_MSG[glow.what_is]="glow = show guides in a nice, easy-to-read layout"
_MSG[glow.missing_title]="Now: install glow"
_MSG[glow.missing_body]=$'The program is called glow.\nIt shows CRKCACHY guides and tips in a clean, readable format.\nCRKCACHY needs glow to display game guides.\n\nInstall once – then we continue.'
_MSG[glow.no_tty]="Please open the terminal (black window) and run it there."
_MSG[glow.pick_title]="How should I install it?"
_MSG[glow.opt_auto]="Do it for me (recommended)"
_MSG[glow.opt_manual]="I'll do it myself"
_MSG[glow.pick_prompt]="1 or 2 (Enter = 1): "
_MSG[glow.pick_invalid]="Please enter 1 or 2."
_MSG[glow.installed]="All good – continuing!"
_MSG[glow.install_failed]="That did not work – try option 2."
_MSG[glow.password_hint]="Your PC may ask for your password."
_MSG[glow.manual_steps_intro]="Type this line in the black window:"
_MSG[glow.manual_pacman]="sudo pacman -S glow"
_MSG[glow.manual_wait]="When done: press Enter …"
_MSG[glow.still_missing]="Not there yet – try again."
_MSG[glow.file_missing]="Guide file not found."
