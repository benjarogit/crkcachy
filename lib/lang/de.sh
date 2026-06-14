#!/usr/bin/env bash
# German strings – loaded by lib/i18n.sh

_MSG[tag.info]="INFO"
_MSG[tag.ok]=" OK "
_MSG[tag.warn]="HINWEIS"
_MSG[tag.error]="FEHLER"

_MSG[lang.detected]="Sprache: Deutsch (automatisch erkannt)"
_MSG[lang.override]="Sprache: Deutsch (--lang)"

_MSG[banner.subtitle]="Standalone-Spiele über Steam + Proton – ohne Bottles"

_MSG[confirm.suffix]="[j=Ja · n=Nein · Enter=empfohlen]"
_MSG[confirm.yes_label]="Ja"
_MSG[confirm.no_label]="Nein"

_MSG[cmd.not_found]="nicht gefunden."
_MSG[cmd.not_found_hint]="nicht gefunden. %s"

_MSG[paru.all_installed]="Alle Pakete sind schon installiert."
_MSG[paru.missing]="Diese Pakete fehlen noch: %s"
_MSG[paru.explain_title]="Was passiert jetzt?"
_MSG[paru.explain_body]=$'paru installiert fehlende Programme von CachyOS/Arch.\nDu musst vielleicht dein Passwort eingeben (sudo).\nDauer: je nach Internet ein paar Minuten.'
_MSG[paru.confirm_install]="Fehlende Pakete jetzt installieren?"
_MSG[paru.installing]="Pakete werden installiert …"
_MSG[paru.install_failed]="Installation hat nicht geklappt."
_MSG[paru.confirm_self]="paru jetzt installieren?"
_MSG[paru.self_title]="paru fehlt"
_MSG[paru.self_body]=$'paru installiert Zusatzprogramme auf CachyOS.\nDu kannst es jetzt automatisch installieren oder den Befehl unten manuell nutzen.'
_MSG[paru.install_paru_hint]="Installiere zuerst paru: sudo pacman -S paru"
_MSG[paru.done]="Paket-Installation abgeschlossen."
_MSG[paru.skipped]="Installation übersprungen."
_MSG[paru.manual]="Manuell später: paru -S --needed %s"

_MSG[tools.none]="Keine Spiel-Tools gefunden."
_MSG[tools.setup_title]="Welches Spiel möchtest du einrichten?"
_MSG[tools.setup_body]=$'CRKCACHY findet Spiele automatisch im Ordner tools/.\nDu wählst ein Spiel – das Tool prüft deinen Ordner und zeigt die Steam-Schritte.\nEs wird nichts heimlich installiert außer du bestätigst System-Pakete.'
_MSG[tools.list_title]="Verfügbare Spiele (Plugin-Liste):"
_MSG[tools.list_dynamic]="Neue Spiele erscheinen hier automatisch, sobald jemand ein tools/<name>/ Paket hinzufügt."
_MSG[tools.opt_all]="Alle Spiele der Reihe einrichten"
_MSG[tools.opt_skip]="Überspringen"
_MSG[tools.pick_number]="Nummer (a=alle · Enter=überspringen): "
_MSG[tools.none_selected]="Kein Spiel gewählt."
_MSG[tools.invalid]="Ungültige Eingabe – bitte Nummer aus der Liste."
_MSG[tools.starting]="Starte: %s …"
_MSG[tools.another]="Noch ein weiteres Spiel einrichten?"
_MSG[tools.done]="Spiel-Setup abgeschlossen."

_MSG[tool.house-of-ashes.name]="House of Ashes"
_MSG[tool.house-of-ashes.desc]="The Dark Pictures – Steam + Proton + Multiplayer"

_MSG[wizard.title]="Was möchtest du jetzt machen?"
_MSG[wizard.choose_hint]="↑↓ wählen · Enter bestätigt"
_MSG[wizard.hint_ready]="Dein PC ist bereit – Spiel einrichten ist der beste nächste Schritt."
_MSG[wizard.hint_fix]="Am PC fehlt noch etwas – zuerst reparieren."
_MSG[wizard.hint_full]="Am besten alles in einem Durchgang starten."
_MSG[wizard.opt1]="PC + Spiel (alles in einem Durchgang)"
_MSG[wizard.opt2]="Nur PC reparieren (wenn oben etwas fehlt)"
_MSG[wizard.opt3]="Spiel in Steam einrichten (House of Ashes usw.)"
_MSG[wizard.opt4]="Liste nochmal anzeigen"
_MSG[wizard.prompt]="1–4 oder Enter: "
_MSG[wizard.invalid]="Das war keine 1, 2, 3 oder 4. Bitte nochmal."

_MSG[assess.title]="Kurz-Check: Ist dein PC bereit fürs Spiel?"
_MSG[assess.all_ready]="Alles OK – Steam, Proton und Hilfspakete sind da."
_MSG[assess.all_ready_hint]="Du musst am PC nichts mehr installieren. Nächster Schritt: Spiel in Steam einbinden."
_MSG[assess.not_ready]="Am PC fehlt noch etwas – siehe Liste unten."
_MSG[assess.score]="%s Checks OK · %s offen"
_MSG[assess.missing_list]="Das fehlt noch:"
_MSG[assess.missing_pkgs]="Fehlende Programme (werden einzeln nachgefragt):"
_MSG[assess.next_title]="Dein nächster Schritt"
_MSG[assess.next_ready_body]=$'Dein PC ist fertig.\n\nJetzt geht es ums Spiel:\n• Spielordner prüfen\n• Anleitung was du in Steam eintragen musst\n• Startoptionen zum Kopieren\n\n→ Unten die Zahl 3 eintippen oder nur Enter drücken.'
_MSG[assess.next_fix_body]=$'Auf deinem PC fehlt noch etwas für Spiele unter Linux.\n\n→ Unten die Zahl 2 eintippen oder nur Enter.\nDanach nochmal prüfen, dann Spiel mit 3.'
_MSG[assess.next_full_body]=$'Du startest neu oder vieles fehlt noch.\n\n→ Unten die Zahl 1 eintippen oder nur Enter.'
_MSG[assess.menu_recommended]="  ← empfohlen"
_MSG[assess.menu_recommended_plain]="← empfohlen"
_MSG[assess.issue.cachyos]="Kein CachyOS (Hinweis – oft trotzdem OK)"
_MSG[assess.issue.paru]="paru fehlt (Paket-Installer)"
_MSG[assess.issue.steam_data]="Steam-Ordner nicht gefunden – Steam starten & einloggen"
_MSG[assess.issue.protonup]="protonup-rs fehlt"
_MSG[assess.issue.ge_proton]="GE-Proton fehlt"
_MSG[assess.issue.spacewar]="Spacewar (App 480) fehlt"
_MSG[assess.issue.platform_partial]="Linux ohne Arch-Pakete – Spiel-Hilfe möglich, Auto-Setup eingeschränkt"
_MSG[assess.issue_pkg]="Paket fehlt: %s"

_MSG[platform.detected]="System: %s (%s)"
_MSG[platform.helper]="Zusatz-Installer: %s"
_MSG[platform.tier_full]="volle Unterstützung"
_MSG[platform.tier_partial]="teilweise Unterstützung"
_MSG[platform.tier_unsupported]="nicht getestet"
_MSG[platform.tier_partial_hint]="Spiel-Pakete (Proton-GE, Vulkan) sind für Arch/CachyOS optimiert."
_MSG[platform.tier_partial_warn]="Dein Linux wird nur teilweise unterstützt – Spiel-Auto-Setup kann eingeschränkt sein."
_MSG[platform.tier_unsupported_warn]="Dieses Linux ist nicht getestet – Installation kann fehlschlagen."
_MSG[platform.rosetta_hint]="Paketnamen werden für dein System angepasst – die richtigen Befehle werden automatisch genutzt."
_MSG[platform.rosetta_manual]="Kein Paket-Mapping für %s auf diesem Linux – bitte manuell installieren (siehe docs/platform-rosetta.md)."

_MSG[assess.issue.arch_only]="%s nur auf Arch/CachyOS – auf deinem Linux manuell prüfen"
_MSG[assess.issue_pkg_manual]="%s – auf deinem Linux manuell installieren (siehe docs/platform-rosetta.md)"

_MSG[runtime.item_os_cachyos]="CachyOS"
_MSG[runtime.item_os_arch]="Linux (%s)"
_MSG[runtime.item_os_other]="Linux (%s, eingeschränkt)"
_MSG[runtime.item_os_unknown]="Linux (%s, unbekannt)"
_MSG[assess.install_one]="Einzelnes Paket: %s"
_MSG[assess.confirm_one]="Paket %s jetzt installieren?"
_MSG[assess.pkg_already]="%s ist schon installiert."
_MSG[assess.fix_title]="Schrittweise reparieren"
_MSG[assess.fix_body]=$'Wir beheben jetzt nacheinander was fehlt.\nBei jedem Paket kannst du j = installieren oder N = überspringen.\nWenn alles grün ist, geht es weiter.'
_MSG[assess.fix_round]="Reparatur-Runde %s"
_MSG[assess.fix_continue]="Weiter versuchen obwohl etwas offen ist?"
_MSG[assess.fix_stopped]="Reparatur beendet – PC noch nicht vollständig bereit."
_MSG[assess.block_game]="Spiel-Setup blockiert: PC ist noch nicht bereit."
_MSG[assess.fix_now]="Fehlende Teile jetzt beheben?"
_MSG[assess.block_game_still]="Spiel-Einrichtung abgebrochen – zuerst PC reparieren (Menüpunkt 2)."
_MSG[assess.pc_already_ok]="PC ist schon bereit – nichts zu installieren."
_MSG[assess.status_hint]="Einrichtung starten: ./install.sh"

_MSG[status.view_only]="Kurz-Übersicht"
_MSG[status.view_only_body]=$'Das war nur die Übersicht.\n\nZum Einrichten starten:\n  ./install.sh\n\nDann Enter oder 3 drücken.'
_MSG[status.ready_next]="Alles OK? Starte jetzt: ./install.sh"

_MSG[ui.running]="Starte: %s …"
_MSG[ui.done]="Fertig: %s"
_MSG[ui.press_enter]="Weiter?"
_MSG[ui.ok_label]="Weiter"
_MSG[ui.markdown_scroll_hint]="Mausrad = im Fenster scrollen"
_MSG[ui.badge_recommended]="★ EMPFOHLEN"
_MSG[cui.choice_no]="✗ Nein"
_MSG[cui.input_prompt]="›"
_MSG[ui.legal_confirm]="Alles verstanden – weiter?"
_MSG[ui.section_pc]="PC-Check"
_MSG[tools.choose_hint]="↑↓ Spiel wählen · Enter bestätigt"

_MSG[flow.chose]="Du hast gewählt: %s"
_MSG[flow.chose_3]="Spiel einrichten – wir starten jetzt."
_MSG[flow.chose_2]="PC reparieren – wir starten jetzt."
_MSG[flow.chose_1]="Alles in einem Durchgang – wir starten jetzt."
_MSG[flow.chose_enter]="Enter ohne Zahl – empfohlener Schritt wird gestartet."
_MSG[flow.game_tool]="Spiel-Tool wird geladen …"

_MSG[cachyos.ok]="CachyOS erkannt – passt."
_MSG[cachyos.arch_warn]="Arch Linux erkannt, aber nicht CachyOS."
_MSG[cachyos.arch_hint]="CRKCACHY ist für CachyOS getestet – kann trotzdem funktionieren."
_MSG[cachyos.other_warn]="Kein Arch/CachyOS erkannt."
_MSG[cachyos.other_hint]="CRKCACHY ist für CachyOS/Arch gedacht."

_MSG[paru.ok]="paru ist installiert (Programm-Installer für Zusatzpakete)."
_MSG[paru.missing_warn]="paru fehlt."
_MSG[paru.install_hint]="Installieren mit: sudo pacman -S paru"

_MSG[steam.ok]="Steam ist installiert."
_MSG[steam.missing_warn]="Steam ist nicht installiert."
_MSG[steam.install_hint]="Installieren mit: paru -S steam"
_MSG[steam.data_ok]="Steam-Daten gefunden: %s"
_MSG[steam.data_missing]="Steam-Ordner nicht gefunden."
_MSG[steam.data_hint]="Steam einmal starten und einloggen, dann erneut versuchen."
_MSG[steam.tooling_title]="Kurz Programme für Steam-Automatik"
_MSG[steam.tooling_body]=$'Für Name, Startoptionen und Icon braucht CRKCACHY:\n• python-vdf (Steam-Liste lesen)\n• icoutils (Icon aus der .exe)\n• imagemagick (Bild formatieren)\n\nEinmal installieren – dann automatisch.'
_MSG[steam.tooling_failed]="Programme fehlen – Automatik nicht möglich. Manuell weiter oder nochmal versuchen."
_MSG[steam.close_title]="Steam kurz schließen"
_MSG[steam.close_body]=$'Damit Name, Startoptionen und Icon sicher gespeichert werden,\nmuss Steam **komplett** beendet sein (nicht nur Fenster schließen).\n\nDanach startest du Steam neu.'
_MSG[steam.close_confirm]="Steam ist geschlossen – weiter?"
_MSG[steam.close_still_running]="Steam läuft noch – bitte wirklich beenden (Steam → Beenden)."
_MSG[steam.close_ok]="Steam ist geschlossen – wir schreiben jetzt die Daten."
_MSG[steam.close_abort]="Abgebrochen – Automatik nicht möglich während Steam läuft."
_MSG[steam.shortcut_not_found]="Spiel nicht in der Steam-Liste gefunden."
_MSG[steam.restart_steam]="Jetzt Steam neu starten – dann Name, Icon und Startoptionen sind aktiv."
_MSG[steam.launch_ok]="Startoptionen wurden eingetragen."
_MSG[steam.launch_already]="Startoptionen waren schon korrekt."
_MSG[steam.icon_applied]="Icon gesetzt für „%s“"
_MSG[steam.icon_extract_failed]="Icon konnte nicht aus der .exe gelesen werden."
_MSG[steam.name_renamed]="Name geändert: „%s“ → „%s“"
_MSG[steam.name_ok]="Name ist schon korrekt: „%s“"
_MSG[steam.manual_launch_title]="Startoptionen (manuell)"
_MSG[steam.manual_launch_body]="Steam → Spiel → Rechtsklick → Eigenschaften → Tab Allgemein → Startoptionen:"
_MSG[steam.manual_launch_hint]="Alles kopieren und einfügen – ohne diese Zeile oft Trial „Buy full game“!"
_MSG[steam.desktop_title]="Desktop & Startmenü"
_MSG[steam.desktop_body]=$'Wir legen einen Start-Eintrag an, der das Spiel **über Steam** startet\n(mit Proton und Startoptionen – nicht Doppelklick auf die .exe).\n\nName und Icon werden korrekt gesetzt.'
_MSG[steam.desktop_confirm]="Desktop- und Startmenü-Eintrag erstellen?"
_MSG[steam.desktop_apps]="Startmenü: %s"
_MSG[steam.desktop_desktop]="Desktop: %s"
_MSG[steam.desktop_no_icon]="Kein Icon gefunden – Eintrag ohne Bild (Steam neu starten oder Tool nochmal starten)."
_MSG[steam.desktop_hint]="Start über den neuen Eintrag oder Steam-Bibliothek – nie die .exe direkt doppelklicken."
_MSG[steam.desktop_remove_old]="Alten fehlerhaften Eintrag entfernen? (%s)"
_MSG[steam.desktop_removed]="Entfernt: %s"

_MSG[spacewar.ok]="Spacewar (App %s) ist installiert."
_MSG[spacewar.missing]="Spacewar fehlt – wird für manche Spiele gebraucht (kostenloses Steam-Spiel)."
_MSG[spacewar.hint1]="In Steam öffnen: steam://install/480"
_MSG[spacewar.hint2]="Oder in der Bibliothek nach „Spacewar“ suchen und installieren."

_MSG[overlay.title]="Steam Overlay (wichtig für Einladungen im Spiel)"
_MSG[overlay.body]=$'Das Overlay ist das Steam-Menü im Spiel (meist mit Shift+Tab).\nOhne Overlay funktionieren Einladungen oft nicht.\n\nIn Steam: Einstellungen → Im Spiel →\n„Steam-Overlay im Spiel aktivieren“ muss AN sein.'

_MSG[protonup.ok]="protonup-rs ist installiert (installiert Proton für Steam)."
_MSG[protonup.missing]="protonup-rs fehlt."
_MSG[protonup.install_hint]="Installieren mit: paru -S protonup-rs-bin"
_MSG[proton.install_title]="GE-Proton installieren"
_MSG[proton.install_body]=$'GE-Proton ist eine spezielle Steam-Version von Proton.\nDamit laufen viele Windows-Spiele unter Linux.\nDas Programm protonup-rs lädt GE-Proton für Steam herunter.\nDauer: je nach Internet 1–5 Minuten.'
_MSG[proton.confirm_install]="GE-Proton jetzt für Steam installieren?"
_MSG[proton.install_cmd_hint]="Installiere zuerst: paru -S protonup-rs-bin"
_MSG[proton.running]="Starte protonup-rs …"
_MSG[proton.done]="protonup-rs fertig."
_MSG[proton.skipped]="GE-Proton-Installation übersprungen."
_MSG[proton.manual_cmd]="Manuell: protonup-rs -q --tool GEProton --version latest --for steam"
_MSG[proton.versions]="Installierte GE-Proton Versionen:"
_MSG[proton.not_found_dir]="Kein GE-Proton in %s gefunden."
_MSG[proton.verified]="GE-Proton ist installiert:"
_MSG[proton.missing]="Kein GE-Proton gefunden."
_MSG[proton.run_install]="Installieren mit ./install.sh"

_MSG[install.step1]="═══ Schritt 1: Kurz prüfen ob dein PC passt ═══"
_MSG[install.step2]="═══ Schritt 2: Hilfsprogramme installieren ═══"
_MSG[install.step3]="═══ Schritt 3: GE-Proton (Windows-Spiele auf Linux) ═══"
_MSG[install.step4]="═══ Schritt 4: Spacewar prüfen (kleines kostenloses Steam-Spiel) ═══"
_MSG[install.step5]="═══ Schritt 5: Dein Spiel einrichten ═══"
_MSG[install.status_title]="═══ Nur Prüfung – es wird nichts installiert ═══"
_MSG[install.packages_title]="═══ Einzelne Pakete ═══"
_MSG[install.pkg_missing]="fehlt: %s"

_MSG[install.packages_explain_title]="Was sind diese Pakete?"
_MSG[install.packages_explain_body]=$'Kleine Zusatzprogramme damit Spiele unter Linux laufen:\n• protonup-rs – installiert Proton (Windows-Spiele auf Linux)\n• vkd3d / gamemode – Grafik und Performance\n• winetricks – falls später DLL-Fehler auftreten\n\nWenn unten „schon installiert“ steht: nichts weiter tun.'

_MSG[install.qt_title]="Optional: protonup-qt (Programm mit Fenstern)"
_MSG[install.qt_body]=$'protonup-qt ist NUR eine grafische Oberfläche – wie ein Einstellungs-Menü für Proton.\nDu hast bereits protonup-rs (Kommandozeile). Damit reicht es fast immer.\n\n→ GE-Proton schon installiert? Dann antworten: N (Enter)\n→ Nur j wenn du extra ein Proton-Programm mit Maus willst'
_MSG[install.qt_confirm]="protonup-qt (GUI) zusätzlich installieren?"
_MSG[install.qt_skipped]="protonup-qt übersprungen – das ist in Ordnung."

_MSG[install.vulkan_title]="Optional: Vulkan-Treiber-Helfer"
_MSG[install.vulkan_body]=$'Vulkan hilft der Grafikkarte (NVIDIA oder AMD) Spiele darzustellen.\nWenn schon installiert: N (Enter).\nWenn du unsicher bist und noch nicht alles installiert hast: j'
_MSG[install.vulkan_confirm]="Vulkan-Helfer (vulkan-icd-loader) installieren?"
_MSG[install.vulkan_skipped]="Vulkan-Installation übersprungen."

_MSG[install.steam_missing]="Steam fehlt noch."
_MSG[install.steam_title]="Steam installieren"
_MSG[install.steam_body]="Steam ist der Spiele-Client – ohne Steam geht dieser Weg nicht."
_MSG[install.steam_confirm]="Steam jetzt installieren?"

_MSG[install.protonup_missing]="protonup-rs fehlt – zuerst Schritt 2 nochmal mit j bestätigen."
_MSG[install.ge_present_title]="GE-Proton ist schon da"
_MSG[install.ge_present_body]=$'Du hast bereits eine GE-Proton Version installiert.\nEin Update ist meist NICHT nötig.\n\n→ Normal weiter mit: N (Enter)\n→ Nur j wenn du explizit die neueste Version willst'
_MSG[install.ge_update_confirm]="GE-Proton trotzdem neu installieren / aktualisieren?"
_MSG[install.ge_kept]="GE-Proton bleibt wie es ist – gut so."
_MSG[install.ge_missing_title]="GE-Proton fehlt noch"
_MSG[install.ge_missing_body]=$'Das wird jetzt heruntergeladen. In Steam kannst du später\n„GE-Proton10-34“ (oder ähnlich) als Kompatibilität wählen.'

_MSG[install.spacewar_title]="Warum Spacewar?"
_MSG[install.spacewar_body]=$'Manche Setups (z. B. House of Ashes) brauchen ein verstecktes Steam-Spiel namens Spacewar.\nEs ist kostenlos und klein.\n\nWenn unten OK steht: nichts tun.\nWenn fehlt: in Steam installieren (Link wird angezeigt).'

_MSG[install.tool_confirm]="Jetzt das Spiel-Tool starten (z. B. House of Ashes)?"
_MSG[install.tool_later]="Später starten mit:"
_MSG[install.tools_none]="Keine Spiel-Tools gefunden."

_MSG[install.all_ready]="Alles bereit! Nächster Schritt:"
_MSG[install.points_open]="%s Punkt(e) offen, %s OK."
_MSG[install.run_setup]="Einrichtung starten: ./install.sh"

_MSG[install.legal_title]="Kurz lesen, dann weiter"
_MSG[install.legal_teaser]="Kein Spiel im Paket – nur Anleitung. Steam + Proton statt Bottles."
_MSG[install.legal_body]=$'CRKCACHY enthält KEINE Spiele und KEINE Fix-Dateien.\nDetails: docs/legal.md'
_MSG[install.start_confirm]="Los geht's?"
_MSG[install.cancelled]="Abgebrochen."
_MSG[install.status_hint]="Starten: ./install.sh"
_MSG[install.finished]="═══ CRKCACHY Einrichtung abgeschlossen ═══"
_MSG[install.next_readme]="Weiter mit der Spiel-Anleitung:"
_MSG[install.show_readme]="Spiel-Anleitung jetzt anzeigen?"

_MSG[ha.intro_title]="House of Ashes einrichten"
_MSG[ha.intro_body]=$'Dieses Tool prüft deinen Spielordner und zeigt dir,\nwas du in Steam eintragen musst.\nEs installiert nichts automatisch – du arbeitest die Liste ab.'
_MSG[ha.pc_check]="═══ Kurz-Check deines PCs ═══"
_MSG[ha.folder_title]="Spielordner"
_MSG[ha.folder_body]=$'Das ist der Ordner in dem HouseOfAshes.exe liegt.\nNicht die .exe selbst – der Ordner darüber!'
_MSG[ha.default_path]="Standard-Pfad (Enter = diesen verwenden):"
_MSG[ha.folder_prompt]="Spielordner (oder Enter): "
_MSG[ha.using_path]="Verwende: %s"
_MSG[ha.dir_missing]="Ordner existiert nicht: %s"
_MSG[ha.check_folder]="═══ Prüfe Spielordner (nur lesen) ═══"
_MSG[ha.fix_missing]="Fix-Dateien fehlen – siehe README Teil B"
_MSG[ha.readme_hint]="Vollständige Anleitung: tools/house-of-ashes/README.md"
_MSG[ha.show_readme]="Vollständige Anleitung jetzt anzeigen?"
_MSG[ha.done]="Fertig – jetzt die Steam-Schritte oben abarbeiten."

_MSG[ha.steam_title]="  Jetzt in Steam – Schritt für Schritt mit der Maus"
_MSG[ha.steam_auto_title]="Steam einrichten"
_MSG[ha.steam_auto_body]=$'Automatik setzt: Name „House of Ashes“, Startoptionen und Icon.\nSteam muss dafür kurz geschlossen werden – wir fragen dich.'
_MSG[ha.steam_auto_confirm]="Automatisch einrichten? (empfohlen)"
_MSG[ha.steam_auto_done]="Automatik fertig – nur noch Proton und Overlay prüfen (siehe unten)."
_MSG[ha.steam_auto_failed]="Automatik hat nicht alles geklappt."
_MSG[ha.steam_manual_fallback]="Manuelle Schritte anzeigen?"
_MSG[ha.steam_manual_title]="Steam – manuell"
_MSG[ha.steam_add_first_title]="Spiel zuerst in Steam hinzufügen"
_MSG[ha.steam_add_first_body]=$'Steam → Spiel → Nicht-Steam-Spiel hinzufügen → Durchsuchen\nDiese Datei wählen:'
_MSG[ha.steam_added_confirm]="Spiel ist jetzt in Steam hinzugefügt?"
_MSG[ha.steam_still_missing]="Noch nicht in Steam gefunden – bitte Schritt oben erledigen."
_MSG[ha.steam_step1]="① Spiel hinzufügen"
_MSG[ha.steam_step1_detail]=$'   Steam → Spiel → Nicht-Steam-Spiel hinzufügen → Durchsuchen\n   Diese Datei wählen:'
_MSG[ha.steam_step1_name]="   Name: House of Ashes – CRKCACHY korrigiert das später automatisch."
_MSG[ha.steam_step2]="② Proton einschalten"
_MSG[ha.steam_step2_detail]=$'   Rechtsklick auf Spiel → Eigenschaften → Kompatibilität\n   „Steam Play verwenden“ AN → GE-Proton10-34 wählen'
_MSG[ha.steam_step3]="③ Startoptionen (Tab Allgemein) – ALLES kopieren und einfügen:"
_MSG[ha.steam_step3_warn]="   Ohne diese Zeile: oft Trial „Buy full game“!"
_MSG[ha.steam_step4]="④ Overlay"
_MSG[ha.steam_step4_detail]=$'   Steam Einstellungen → Im Spiel → Overlay AN\n   Test im Spiel: Shift + Tab'
_MSG[ha.steam_step5]="⑤ Starten nur über Steam-Bibliothek (Play-Button), nicht Doppelklick!"

_MSG[ha.check.usage]="Nutzung: %s <Spielordner>"
_MSG[ha.check.usage_desc]="  Prüft den Extract-Ordner – ändert nichts."
_MSG[ha.check.checking]="Prüfe: %s"
_MSG[ha.check.exe_ok]="HouseOfAshes.exe gefunden"
_MSG[ha.check.exe_missing]="HouseOfAshes.exe fehlt im Spielordner"
_MSG[ha.check.dir_missing]="Ordner fehlt: %s"
_MSG[ha.check.file_ok]="%s"
_MSG[ha.check.file_missing]="fehlt: %s"
_MSG[ha.check.ini_ok]="OnlineFix.ini: FakeAppId=%s, RealAppId=%s"
_MSG[ha.check.ini_bad]="OnlineFix.ini: App-IDs stimmen nicht."
_MSG[ha.check.ini_hint]="Erwartet: FakeAppId=%s und RealAppId=%s"
_MSG[ha.check.steam_api_ok]="steam_api64.dll vorhanden"
_MSG[ha.check.steam_api_missing]="fehlt: %s"
_MSG[ha.check.steam_api_hint]="Online-Fix ersetzt meist diese Datei"
_MSG[ha.check.flt_warn]="%s/%s gefunden – kann mit Online-Fix kollidieren"
_MSG[ha.check.appid_warn]="steam_appid.txt im Spielordner – meist nicht nötig bei Steam-Start"
_MSG[ha.check.all_ok]="Alles OK – weiter mit Steam (siehe README.md)"
_MSG[ha.check.errors]="%s Problem(e) – Online-Fix / Pfade prüfen (README Teil B)"
_MSG[ha.check.dir_not_found]="Folder not found: %s"

_MSG[offer.manual_label]="Manuell im Terminal:"
_MSG[pkg.no_installer]="Kein Paket-Manager gefunden (pacman, apt, dnf, zypper) – Installation nicht möglich."
_MSG[pkg.explain.title]="Was wird installiert – und warum?"
_MSG[pkg.explain.steam_title]="Steam installieren"
_MSG[pkg.confirm_install]="Jetzt installieren?"
_MSG[pkg.explain.footer]=$'Einmal installieren – der PC fragt vielleicht nach deinem Passwort (sudo).\nDanach geht es weiter. Du kannst auch „Nein“ sagen und den Befehl manuell nutzen.'
_MSG[pkg.explain.fallback]="%s – wird für CRKCACHY benötigt."
_MSG[pkg.explain.gum]=$'**gum** – kleines Menü-Programm.\nDu wählst mit Pfeiltasten (↑↓) und Enter – wie in einem Spiel.\nOhne gum keine Auswahl-Menüs in CRKCACHY.'
_MSG[pkg.explain.glow]=$'**glow** – zeigt Anleitungen schön formatiert an.\nLeichter zu lesen als roher Text im Terminal.\nOhne glow keine Spiel-Anleitungen in CRKCACHY.'
_MSG[pkg.explain.steam]=$'**Steam** – Programm zum Spielen und Starten von Spielen.\nCRKCACHY richtet dein Spiel als Nicht-Steam-Spiel ein – mit Proton für Windows-Spiele.'
_MSG[pkg.explain.paru]=$'**paru** – installiert Zusatzprogramme auf CachyOS/Arch.\nBrauchst du für manche Pakete aus dem AUR (Zusatz-Katalog).'
_MSG[pkg.explain.python-vdf]=$'**python-vdf** – liest die Steam-Spieleliste (shortcuts.vdf).\nDamit setzt CRKCACHY Name und Startoptionen automatisch.'
_MSG[pkg.explain.icoutils]=$'**icoutils** – liest das Spiel-Icon aus der .exe-Datei.\nOhne Icon: graues Kästchen in Steam.'
_MSG[pkg.explain.imagemagick]=$'**imagemagick** – formatiert Icons als PNG für Steam und Desktop.\nWird zusammen mit icoutils für das Spiel-Bild gebraucht.'
_MSG[pkg.explain.protonup]=$'**ProtonUp** – installiert GE-Proton für Steam.\nGE-Proton startet viele Windows-Spiele besser als Standard-Proton.'
_MSG[pkg.explain.winetricks]=$'**winetricks** – Windows-Hilfsprogramme für Wine/Proton.\nManche Spiele brauchen zusätzliche Windows-Komponenten.'
_MSG[pkg.explain.gamemode]=$'**gamemode** – kann Spiele etwas schneller machen (optional).\nSchaltet beim Spielen Leistung frei.'
_MSG[pkg.explain.vkd3d]=$'**vkd3d** – DirectX 12 über Vulkan für Proton.\nWichtig für moderne 3D-Spiele.'
_MSG[pkg.explain.gvfs]=$'**gvfs** – Dateizugriff für Programme.\nHilft Steam beim Ordner-Auswahl-Dialog.'
_MSG[pkg.explain.vulkan-loader]=$'**Vulkan** – Grafik-Basis für Spiele auf Linux.\nOhne Vulkan laufen viele Spiele nicht oder nur langsam.'

_MSG[onboard.title]="Los geht's"
_MSG[onboard.subtitle]="Wir prüfen deinen PC und starten die passenden Tools."

_MSG[runtime.intro_title]="Was CRKCACHY macht"
_MSG[runtime.intro_body]=$'Wir stellen Tools bereit, damit Spiele auf deinem PC laufen.\n\nJetzt kurz prüfen:\n• Pfeil-Menü (richten wir gleich ein)\n• Steam fürs Spiel\n• Ob am PC noch etwas fehlt'
_MSG[runtime.check_title]="Startcheck"
_MSG[runtime.check_subtitle]="Prüft, ob CRKCACHY auf deinem PC laufen kann."
_MSG[runtime.check_all_ok]="Alles da – Menü, Anleitungen und Steam. Weiter geht's."
_MSG[runtime.missing_suffix]="fehlt noch"
_MSG[runtime.item_menu]="Menü mit Pfeiltasten (gum)"
_MSG[runtime.item_reader]="Anleitungen anzeigen (glow)"
_MSG[runtime.item_packages]="Programme installieren geht"
_MSG[runtime.item_paru]="paru (Zusatz-Programme, optional)"
_MSG[runtime.item_os]="CachyOS oder Linux"
_MSG[runtime.item_steam]="Steam (Spiele-Programm)"
_MSG[runtime.required_fail]="Etwas Wichtiges fehlt noch – siehe Liste oben."
_MSG[runtime.recommended_open]="%s Punkt(e) wären noch schön – nicht zwingend."
_MSG[runtime.fix_recommended]="Fehlende Programme jetzt installieren?"
_MSG[runtime.install_steam]="Steam jetzt installieren?"
_MSG[runtime.cannot_continue]="Ohne die wichtigen Punkte geht es nicht weiter."
_MSG[runtime.legal_ok]="OK – weiter"
_MSG[runtime.legal_abort]="Abgebrochen."
_MSG[runtime.legal_hint]="Nur Hilfe & Doku – keine Haftung. docs/legal.md"

_MSG[runtime.bootstrap_title]="CRKCACHY braucht Programme auf deinem PC"
_MSG[runtime.bootstrap_body]=$'Zuerst zwei Programme für die Oberfläche:\n• **gum** – Menüs mit Pfeiltasten (↑↓)\n• **glow** – Anleitungen schön lesbar\n\nSpäter beim Spiel-Setup können noch andere Programme fehlen\n(Steam, Icon-Helfer, Proton …) – wir erklären jedes einzeln.'
_MSG[runtime.bootstrap_hint]="Fehlt etwas, siehst du gleich: Was es ist und warum CRKCACHY es braucht."

_MSG[gum.what_is]="gum = Menüs mit Pfeiltasten (↑↓ und Enter)"
_MSG[gum.missing_title]="Jetzt: gum installieren"
_MSG[gum.missing_body]=$'Das Programm heißt gum.\nDamit wählst du in CRKCACHY mit Pfeiltasten – wie in einem Spiel-Menü.\nCRKCACHY braucht gum für alle Auswahl-Menüs.\n\nEinmal installieren – dann geht es weiter.'
_MSG[gum.no_tty]="Bitte das schwarze Fenster (Konsole) öffnen und dort starten."
_MSG[gum.pick_title]="Wie soll ich das installieren?"
_MSG[gum.opt_auto]="Mach du das für mich (empfohlen)"
_MSG[gum.opt_manual]="Ich mache es selbst"
_MSG[gum.pick_prompt]="1 oder 2 (Enter = 1): "
_MSG[gum.pick_invalid]="Bitte 1 oder 2 eingeben."
_MSG[gum.installed]="Alles klar – weiter geht's!"
_MSG[gum.install_failed]="Das hat nicht geklappt – probier Option 2."
_MSG[gum.password_hint]="Vielleicht fragt der PC nach deinem Passwort."
_MSG[gum.manual_steps_intro]="Tippe diese Zeile ins schwarze Fenster:"
_MSG[gum.manual_pacman]="sudo pacman -S gum"
_MSG[gum.manual_wait]="Wenn fertig: Enter drücken …"
_MSG[gum.still_missing]="Noch nicht da – nochmal versuchen."

_MSG[glow.what_is]="glow = Anleitungen schön und übersichtlich anzeigen"
_MSG[glow.missing_title]="Jetzt: glow installieren"
_MSG[glow.missing_body]=$'Das Programm heißt glow.\nDamit zeigt CRKCACHY Anleitungen und Hinweise schön formatiert an – leicht zu lesen.\nCRKCACHY braucht glow zum Anzeigen der Spiel-Anleitungen.\n\nEinmal installieren – dann geht es weiter.'
_MSG[glow.no_tty]="Bitte das schwarze Fenster (Konsole) öffnen und dort starten."
_MSG[glow.pick_title]="Wie soll ich das installieren?"
_MSG[glow.opt_auto]="Mach du das für mich (empfohlen)"
_MSG[glow.opt_manual]="Ich mache es selbst"
_MSG[glow.pick_prompt]="1 oder 2 (Enter = 1): "
_MSG[glow.pick_invalid]="Bitte 1 oder 2 eingeben."
_MSG[glow.installed]="Alles klar – weiter geht's!"
_MSG[glow.install_failed]="Das hat nicht geklappt – probier Option 2."
_MSG[glow.password_hint]="Vielleicht fragt der PC nach deinem Passwort."
_MSG[glow.manual_steps_intro]="Tippe diese Zeile ins schwarze Fenster:"
_MSG[glow.manual_pacman]="sudo pacman -S glow"
_MSG[glow.manual_wait]="Wenn fertig: Enter drücken …"
_MSG[glow.still_missing]="Noch nicht da – nochmal versuchen."
_MSG[glow.file_missing]="Anleitung-Datei nicht gefunden."
