# House of Ashes – Anleitung Schritt für Schritt

**Spiel:** The Dark Picture Anthology: House of Ashes  
**Ziel:** Spiel starten unter Linux mit Steam – inkl. Multiplayer (mit selbst eingebundenem Online-Fix).

**English:** [README.en.md](README.en.md)

---

## Bevor du startest – Checkliste

| # | Hast du das? | Woher? |
|---|--------------|--------|
| 1 | CachyOS + Steam | auf dem PC |
| 2 | CRKCACHY eingerichtet | `./install.sh` (siehe Haupt-[README](../../README.md)) |
| 3 | Spieldateien | legaler Kauf – Ordner mit `HouseOfAshes.exe` |
| 4 | Online-Fix eingebunden | **selbst** besorgen – **nicht** aus CRKCACHY |
| 5 | Spacewar in Steam | kostenlos – `steam://install/480` |

---

## Teil A – System (einmalig, Terminal)

### A1 – Terminal öffnen

`Ctrl+Alt+T` oder Startmenü → **Konsole**

### A2 – CRKCACHY Einrichtung

```bash
cd ~/Dokumente/test/crkcachy
./install.sh
```

**Antworten wenn schon alles installiert ist:**

- protonup-qt? → **N** (nur GUI, nicht nötig)
- Vulkan? → **N**
- GE-Proton update? → **N**
- Spiel-Tool? → **j**

### A3 – Prüfen ob Spielordner stimmt

```bash
./tools/house-of-ashes/checks.sh \
  "$HOME/Downloads/extracted/The Dark Pictures Anthology - House of Ashes"
```

Jede Zeile soll `[  OK ]` zeigen. Bei `[FEHLER]` → Teil B.

---

## Teil B – Online-Fix (selbst, nicht aus CRKCACHY)

Dein Spiel liegt in einem Ordner. Darin `HouseOfAshes.exe` – **in diesen Ordner** kommen die Fix-Dateien.

### B1 – In Ordner `SMG025/Binaries/Win64/` legen:

- `OnlineFix64.dll`
- `OnlineFix.ini`
- `winmm.dll`
- `StubDRM64.dll`
- `dlllist.txt`

### B2 – In Ordner `Engine/Binaries/ThirdParty/Steamworks/Steamv147/Win64/`:

- `steam_api64.dll` → **alte Datei ersetzen**

### B3 – Nochmal prüfen

```bash
./tools/house-of-ashes/checks.sh "/pfad/zum/Spielordner"
```

---

## Teil C – Steam (mit Maus, ~5 Minuten)

CRKCACHY kann Steam **nicht** automatisch ändern. Folge diesen Schritten **genau**:

### C1 – Spiel zu Steam hinzufügen

1. **Steam** starten und einloggen
2. Oben links: **Spiel** klicken
3. **„Nicht-Steam-Spiel zu meiner Bibliothek hinzufügen…“**
4. **„Durchsuchen…“** klicken
5. Zu deinem Spielordner gehen
6. **`HouseOfAshes.exe`** auswählen (die .exe Datei, keine DLL!)
7. **„Ausgewählte Programme hinzufügen“**

### C2 – Proton aktivieren

1. In der Bibliothek: **Rechtsklick** auf das neue Spiel
2. **„Eigenschaften“**
3. Links: **„Kompatibilität“**
4. Häkchen: **„Steam Play verwenden“** → **AN**
5. Dropdown: **GE-Proton10-34** wählen (oder dein GE-Proton)

### C3 – Startoptionen (sehr wichtig!)

1. In den Eigenschaften: Tab **„Allgemein“**
2. Feld **„Startoptionen“**
3. **Alles** in diesem Feld löschen und **genau** das einfügen:

```
WINEDLLOVERRIDES="OnlineFix64=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api64=n;winhttp=n,b" SteamAppId=480 %command%
```

4. Fenster schließen – Steam speichert automatisch

(Kopie: [launch-options.txt](launch-options.txt))

**Ohne diese Zeile:** oft Trial-Meldung „Buy full game to unlock“.

### C4 – Overlay aktivieren

1. Steam **„Einstellungen“** (oben links)
2. **„Im Spiel“**
3. **„Steam-Overlay im Spiel aktivieren“** → **AN**
4. Im Spiel testen: **Shift + Tab** → Steam-Menü soll erscheinen

### C5 – Spacewar (falls noch nicht installiert)

Browser oder Steam: `steam://install/480`  
Oder Bibliothek → Suche **Spacewar** → Installieren (kostenlos).

---

## Teil D – Spiel starten

1. **Nur** über die **Steam-Bibliothek** starten (Play-Button)
2. **Nicht** Doppelklick auf `HouseOfAshes.exe` im Dateimanager!
3. Beim ersten Mal kann „Steam Linux Runtime“ laden – **warten** (kann Minuten dauern)
4. Spiel sollte **ohne** Trial-Hinweis starten

---

## Multiplayer (kurz)

1. Im Spiel: **Shared Story** → Lobby
2. **Invite** an Freund
3. Freund braucht: gleichen Fix, Steam online, **gleiche Startoptionen** (C3)

---

## Häufige Probleme

| Problem | Lösung |
|---------|--------|
| „Buy full game to unlock“ | Startoptionen aus C3 fehlen – nochmal einfügen |
| Invite tut nichts | Overlay an (C4), Shift+Tab testen |
| Spiel startet nicht | Über Steam starten, nicht per Doppelklick |
| Langer Download | Normal beim ersten Start – warten |

Mehr: [../../docs/troubleshooting.md](../../docs/troubleshooting.md)

---

## Hilfe im Terminal

```bash
./tools/house-of-ashes/install.sh
```

Zeigt nochmal die Steam-Checkliste mit deinem Pfad.
