# House of Ashes – Anleitung

**English:** siehe README.en.md im gleichen Ordner.

## Transparenz

CRKCACHY **verteilt keine Spieldateien und keine Fix-Downloads**.  
Du legst den Online-Fix **selbst** in den Spielordner. Wir prüfen nur (read-only), ob die erwarteten Dateien da sind.

**Getesteter Fix-Stack:** `TDPAHOA_Fix_Repair_Steam_Generic`  
Die Tool-Installation (Pfade, Startoptionen, Icon, Steam-Automatik) ist darauf ausgelegt.

## Zuerst

Folge der **Haupt-Anleitung** im CRKCACHY-Projektordner (`./install.sh` → Enter oder **3**).

## Aktionen (Master oder hier)

```bash
# Projektroot:
./install.sh --tools          # Tool wählen → Aktion wählen
./install.sh --install        # Tool wählen → installieren
./install.sh --uninstall      # deinstallieren
./install.sh --check          # prüfen (+ Reparatur anbieten)
./install.sh --reset          # Reset (nur CLI, für Tests)

# Oder direkt hier:
./install.sh                  # Aktionsmenü
./install.sh --install
```

| Aktion | Zweck |
|--------|--------|
| **Installieren** | Automatik oder manuell, danach Prüfung |
| **Deinstallieren** | CRKCACHY-Einrichtung entfernen, optional aus Steam |
| **Prüfen** | PC + Ordner + Steam – ersetzt separates „Validieren“ |
| **Reset** | Nur `--reset` (CLI): Metadaten zurück, Spiel bleibt in Steam |

## Was du brauchst

- Spiele-Ordner mit `HouseOfAshes.exe`
- Fix **TDPAHOA_Fix_Repair_Steam_Generic** **selbst** ins Spielordner legen (nicht aus CRKCACHY)
- Steam läuft und du bist eingeloggt
- Bei mehreren Steam-Accounts: Tool fragt, welchem Profil Shortcut/Icon gelten soll

## Wenn das Programm fragt

| Frage | Antwort (wenn schon alles da) |
|-------|-------------------------------|
| protonup-qt? | **Enter** (nein) |
| Vulkan? | **Enter** |
| GE-Proton update? | **Enter** |
| Spielordner | **Enter** für Standard-Pfad |
| Steam-Automatik? | **j** (empfohlen) |
| Desktop-Eintrag? | **j** (optional) |

## Danach in Steam

Name, Startoptionen und Icon automatisch (wenn gewählt).  
Proton **GE-Proton10-34** und Overlay prüfen. Start nur über **Play**.

## Probleme?

Siehe **docs/troubleshooting.md** im CRKCACHY-Projektordner.
