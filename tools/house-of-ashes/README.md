# House of Ashes – Setup (CachyOS + Steam + Proton)

**The Dark Picture Anthology: House of Ashes** – Multiplayer/Shared Story unter Linux via **Steam + GE-Proton** und **selbst eingebundenen Online-Fix**.

**English:** [README.en.md](README.en.md)

> CRKCACHY liefert **keine** Spieldateien und **keinen** Online-Fix. Du brauchst eine legale Vollversion und beschaffst den Fix selbst gemäß [online-fix.me FAQ](https://online-fix.me/guides/16258-site-usage-faq.html).

## Voraussetzungen

1. **CachyOS** mit `paru` und **Steam**
2. **GE-Proton** (z. B. GE-Proton10-34) – `../../install.sh` oder `protonup-rs`
3. **Spacewar (App 480)** in Steam installiert (für `SteamAppId=480`)
4. **Legale Spieldateien** im Extract-Ordner (nicht ins Repo kopieren)
5. **Online-Fix** selbst angewendet (siehe unten)

## Schritt 1 – System-Basis

```bash
cd /path/to/crkcachy
./install.sh
```

## Schritt 2 – Online-Fix (selbst, nicht aus CRKCACHY)

Nach dem Fix-Autor in deinen **Extract-Ordner** legen (kein Kopieren ins Root außerhalb des Spiels):

| Pfad | Dateien |
|------|---------|
| `SMG025/Binaries/Win64/` | `OnlineFix64.dll`, `OnlineFix.ini`, `winmm.dll`, `StubDRM64.dll`, `dlllist.txt` |
| `Engine/Binaries/ThirdParty/Steamworks/Steamv147/Win64/` | `steam_api64.dll` (überschreiben) |

`OnlineFix.ini` sollte enthalten:

- `FakeAppId=480` (Spacewar)
- `RealAppId=1281590` (House of Ashes)

**Nicht** FLT-Dateien (`flt.ini`, `steamclient64.dll`) parallel zu Online-Fix nutzen – Konflikt.

## Schritt 3 – Tool-Installer (Prüfung)

```bash
./tools/house-of-ashes/install.sh
```

Oder nur Prüfung:

```bash
./tools/house-of-ashes/checks.sh "/pfad/zum/Spiel"
```

Der Installer liest nur – er kopiert nichts.

## Schritt 4 – Steam (manuell)

1. **Spiel hinzufügen** → Nicht-Steam-Spiel → `HouseOfAshes.exe` im Extract-Ordner
2. **Kompatibilität** → GE-Proton10-34 erzwingen  
   Alternative: `proton-cachyos-*` (einmaliger **sniper** Runtime-Download ist normal)
3. **Startoptionen** (kritisch unter Linux):

```
WINEDLLOVERRIDES="OnlineFix64=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api64=n;winhttp=n,b" SteamAppId=480 %command%
```

Siehe auch [launch-options.txt](launch-options.txt).

4. **Overlay** aktivieren: Einstellungen → Im Spiel → Steam Overlay  
   Test: **Shift+Tab** in der Lobby (Invites brauchen Overlay)

## Schritt 5 – Erster Start

- Steam Linux Runtime (**sniper**) kann einmalig heruntergeladen werden – warten bis fertig
- Trial-Hinweis „Buy full game“ → Startoptionen prüfen (`WINEDLLOVERRIDES` fehlt oft)

## Multiplayer

1. Host: **Shared Story** → Lobby → **Invite**
2. Freund: gleicher Online-Fix, Steam **online**, gleiche Startoptionen
3. Freund muss **nicht** schon im Spiel sein, aber Overlay/Steam müssen funktionieren

## Fehlerkurzreferenz

| Problem | Lösung |
|---------|--------|
| Trial „Buy full game“ | `WINEDLLOVERRIDES` in Startoptionen setzen |
| Invite ohne Reaktion | Overlay an, Shift+Tab testen, Spiel über Steam starten |
| Kryptischer Lobby-Name | Encoding/Emu – meist kein Invite-Blocker |
| Runtime hängt | Proton-Version wechseln, Steam neu starten |

Details: [../../docs/troubleshooting.md](../../docs/troubleshooting.md)

## App-IDs

| ID | Verwendung |
|----|------------|
| 1281590 | House of Ashes (RealAppId) |
| 480 | Spacewar (FakeAppId / SteamAppId Trick) |
