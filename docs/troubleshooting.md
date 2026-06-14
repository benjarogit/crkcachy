# Troubleshooting

Häufige Probleme bei CachyOS + Steam + Proton + Community-Fixes.

## Trial-Modus: „Buy full game to unlock“

**Ursache:** Online-Fix-DLLs werden unter Proton nicht geladen ohne `WINEDLLOVERRIDES`.

**Lösung:** Startoptionen in Steam (Beispiel House of Ashes):

```
WINEDLLOVERRIDES="OnlineFix64=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api64=n;winhttp=n,b" SteamAppId=480 %command%
```

Kompatibilität: GE-Proton erzwingen.

## Invite tut nichts / kein Overlay

**Ursache:** Steam Overlay nicht aktiv oder Spiel nicht über Steam gestartet.

**Lösung:**

1. Steam → Einstellungen → Im Spiel → Overlay aktivieren
2. Im Spiel **Shift+Tab** testen
3. Spiel als **Nicht-Steam-Spiel** mit `HouseOfAshes.exe` hinzufügen
4. Start immer über Steam-Bibliothek
5. Freund: gleicher Fix, Steam online, gleiche Startoptionen

## Spacewar-Cloud-Symbol / „Trick ok“

Wenn Spacewar (480) installiert ist und `SteamAppId=480` gesetzt ist, ist ein Cloud-Status bei Spacewar oft **normal** – kein Fehler an sich.

## Steam Linux Runtime (sniper) Download hängt

**Ursache:** Erster Start mit neuem Proton (z. B. proton-cachyos).

**Lösung:**

- Warten (kann Minuten dauern)
- Steam neu starten
- GE-Proton vs. proton-cachyos testen
- Speicherplatz prüfen unter `~/.local/share/Steam/steamapps/common/`

## Kryptischer Name in der Lobby

Oft Encoding oder Steam-Emu-Anzeige – blockiert Invites meist **nicht**. Overlay und Startoptionen zuerst prüfen.

## FLT vs. Online-Fix Konflikt

Wenn `flt.ini` oder `steamclient64.dll` (FLT) neben Online-Fix liegen, Fix bereinigen – nur eine Emu-Lösung.

## VC++ / DirectX unter Proton

Falls DLL-Fehler (z. B. `D3DCOMPILER_43`):

```bash
winetricks d3dcompiler_43 d3dcompiler_47
```

Im Proton-Prefix des Spiels (Steam startet Prefix automatisch).

## Bottles (Fallback Singleplayer)

Nicht der CRKCACHY-Standard für Multiplayer. Für Offline:

- Bottle „Gaming“, DXVK/VKD3D aktiv
- Winetricks für fehlende DLLs
- Multiplayer/Invites: zurück zu Steam + Proton

## Checks erneut ausführen

```bash
./tools/house-of-ashes/checks.sh "/pfad/zum/Spiel"
```

## Weitere Hilfe

- Tool-README: `tools/house-of-ashes/README.md`
- Issues: [GitHub Issues](https://github.com/benjarogit/crkcachy/issues)
