#!/usr/bin/env bash
# German strings – loaded by lib/i18n.sh

_MSG[tag.info]="INFO"
_MSG[tag.ok]=" OK "
_MSG[tag.warn]="HINWEIS"
_MSG[tag.error]="FEHLER"

_MSG[lang.detected]="Sprache: Deutsch (automatisch erkannt)"
_MSG[lang.override]="Sprache: Deutsch (--lang)"

_MSG[banner.subtitle]="Hilfe für CachyOS + Steam – Schritt für Schritt"

_MSG[confirm.suffix_no]="(j=ja / N=nein, Enter=nein): "
_MSG[confirm.suffix_yes]="(J=ja / n=nein, Enter=ja): "

_MSG[cmd.not_found]="nicht gefunden."
_MSG[cmd.not_found_hint]="nicht gefunden. %s"

_MSG[paru.all_installed]="Alle Pakete sind schon installiert."
_MSG[paru.missing]="Diese Pakete fehlen noch: %s"
_MSG[paru.explain_title]="Was passiert jetzt?"
_MSG[paru.explain_body]=$'paru installiert fehlende Programme von CachyOS/Arch.\nDu musst vielleicht dein Passwort eingeben (sudo).\nDauer: je nach Internet ein paar Minuten.'
_MSG[paru.confirm_install]="Fehlende Pakete jetzt installieren?"
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
_MSG[tools.pick_number]="Nummer eingeben (a=alle, leer=überspringen): "
_MSG[tools.none_selected]="Kein Spiel gewählt."
_MSG[tools.invalid]="Ungültige Eingabe – bitte Nummer aus der Liste."
_MSG[tools.starting]="Starte: %s …"
_MSG[tools.another]="Noch ein weiteres Spiel einrichten?"
_MSG[tools.done]="Spiel-Setup abgeschlossen."

_MSG[tool.house-of-ashes.name]="House of Ashes"
_MSG[tool.house-of-ashes.desc]="The Dark Pictures – Steam + Proton + Multiplayer"

_MSG[wizard.title]="Was möchtest du tun?"
_MSG[wizard.body]=$'Der Installer weiß nicht im Voraus was du brauchst – du sagst es hier.\nAlles ist nummeriert: Zahl eingeben, Enter drücken.'
_MSG[wizard.opt1]="Alles: PC vorbereiten + Spiel wählen (empfohlen für Neulinge)"
_MSG[wizard.opt2]="Nur PC vorbereiten (Pakete, Proton, Spacewar)"
_MSG[wizard.opt3]="Nur ein Spiel einrichten (PC ist schon fertig)"
_MSG[wizard.opt4]="Nur prüfen – nichts installieren"
_MSG[wizard.prompt]="Deine Auswahl (1–4): "
_MSG[wizard.invalid]="Ungültige Auswahl – bitte 1, 2, 3 oder 4 eingeben."

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

_MSG[install.legal_title]="Wichtig vor dem Start"
_MSG[install.legal_body]=$'CRKCACHY enthält KEINE Spiele und KEINE Fix-Dateien.\nDu brauchst dein Spiel legal und bindest Fixes selbst ein.\nDetails: docs/legal.md'
_MSG[install.how_title]="Wie antworten?"
_MSG[install.how_body]=$'Bei jeder Frage:\n  j oder y = ja, machen\n  N oder Enter = nein, überspringen\n\nWenn etwas schon installiert ist, ist „nein“ meist richtig.'
_MSG[install.start_confirm]="Mit der Einrichtung starten?"
_MSG[install.cancelled]="Abgebrochen."
_MSG[install.status_hint]="Nur anzeigen ohne Install: ./install.sh --status"
_MSG[install.finished]="═══ CRKCACHY Einrichtung abgeschlossen ═══"
_MSG[install.next_readme]="Weiter mit der Spiel-Anleitung:"

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
_MSG[ha.done]="Fertig – jetzt die Steam-Schritte oben abarbeiten."

_MSG[ha.steam_title]="  Jetzt in Steam – Schritt für Schritt mit der Maus"
_MSG[ha.steam_step1]="① Spiel hinzufügen"
_MSG[ha.steam_step1_detail]=$'   Steam → Spiel → Nicht-Steam-Spiel hinzufügen → Durchsuchen\n   Diese Datei wählen:'
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
_MSG[ha.check.dir_not_found]="Ordner nicht gefunden: %s"
