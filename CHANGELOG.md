# Changelog

## [0.1.92] - 2026-06-17

### Changed
- Wizard-Start: Willkommen → Weiter → dann Menü (nicht sofort Hauptmenü)
- Kein „Du hast die neueste Version“ bei jedem Start (nur Update-Hinweis)
- Keine doppelte Status-Box + Menü-Hint mehr

## [0.1.91] - 2026-06-17

### Removed
- gum-Migration-Hinweise und Paket-Checklisten im Wizard (irrelevant)
- Abwärtskompatibilitäts-/OpenClaw-Texte in Bootstrap- und Node-Hinweisen

## [0.1.90] - 2026-06-17

### Changed
- **Wizard-Branding:** CRKCACHY-Header (wie `cui_brand_header`) beim Start
- **Farbschema** aus `cui.sh` (Brand, Erfolg, Warnung, Info, gedimmt) in Menüs, Notes und Status
- Empfohlene Option mit ◆/★ in Grün, Deinstall mit Warnfarbe, ✓/✗/○ farbig in Paket-Infos

## [0.1.89] - 2026-06-17

### Removed
- **Alle Bash-Fallback-Menüs** (`_crk_bash_pick`, nummerierte 1/2/3-Prompts, `CRKCACHY_BASH_UI`)
- Clack scheitert → klare Fehlermeldung (`wizard.pick_failed`), kein stilles Umschalten
- Toten Bash-Wizard-Code aus `install.sh` entfernt

## [0.1.88] - 2026-06-17

### Changed
- **Installer-Wizard komplett in TypeScript** (`lib/prompter/dist/wizard.js`) – OpenClaw-Stil mit `@clack/prompts` (intro → note → select), kein Bash-Menü-Loop mehr
- **Runtime-Bootstrap im Wizard**: `nodejs` + `glow` klar erklärt und per Clack installiert (kein Banner-Flash + Checkliste davor)
- **Bash nur noch Backend** (`lib/wizard-bridge.sh`) für Assess, Paketinstallation und Tool-Dispatch

### Fixed
- Kein leeres Terminal / kein doppelter Header mehr beim Start
- Paket-Hinweis: `nodejs` + `glow` Pflicht, `gum` optional entfernen
