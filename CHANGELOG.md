# Changelog

## [0.1.88] - 2026-06-17

### Changed
- **Installer-Wizard komplett in TypeScript** (`lib/prompter/dist/wizard.js`) – OpenClaw-Stil mit `@clack/prompts` (intro → note → select), kein Bash-Menü-Loop mehr
- **Runtime-Bootstrap im Wizard**: `nodejs` + `glow` klar erklärt und per Clack installiert (kein Banner-Flash + Checkliste davor)
- **Bash nur noch Backend** (`lib/wizard-bridge.sh`) für Assess, Paketinstallation und Tool-Dispatch

### Fixed
- Kein leeres Terminal / kein doppelter Header mehr beim Start
- Paket-Hinweis: `nodejs` + `glow` Pflicht, `gum` optional entfernen
