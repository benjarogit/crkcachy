# House of Ashes – Setup (CachyOS + Steam + Proton)

**The Dark Picture Anthology: House of Ashes** – multiplayer / Shared Story on Linux via **Steam + GE-Proton** and a **self-applied online fix**.

**Deutsch:** [README.md](README.md)

> CRKCACHY does **not** ship game files or online-fix binaries. You need a legal full copy and must obtain the fix yourself per [online-fix.me FAQ](https://online-fix.me/guides/16258-site-usage-faq.html).

## Prerequisites

1. **CachyOS** with `paru` and **Steam**
2. **GE-Proton** (e.g. GE-Proton10-34) – run `../../install.sh` or use `protonup-rs`
3. **Spacewar (App 480)** installed in Steam (for `SteamAppId=480`)
4. **Legal game files** in your extract folder (do not commit to git)
5. **Online fix** applied by you (see below)

## Step 1 – System baseline

```bash
cd /path/to/crkcachy
./install.sh
```

## Step 2 – Online fix (self-sourced, not from CRKCACHY)

Place files from the fix author into your **extract folder**:

| Path | Files |
|------|-------|
| `SMG025/Binaries/Win64/` | `OnlineFix64.dll`, `OnlineFix.ini`, `winmm.dll`, `StubDRM64.dll`, `dlllist.txt` |
| `Engine/Binaries/ThirdParty/Steamworks/Steamv147/Win64/` | `steam_api64.dll` (replace) |

`OnlineFix.ini` should include:

- `FakeAppId=480` (Spacewar)
- `RealAppId=1281590` (House of Ashes)

Do **not** mix FLT files (`flt.ini`, `steamclient64.dll`) with Online-Fix – conflict.

## Step 3 – Tool installer (validation)

```bash
./tools/house-of-ashes/install.sh
```

Or checks only:

```bash
./tools/house-of-ashes/checks.sh "/path/to/game"
```

The installer only reads – it does not copy files.

## Step 4 – Steam (manual)

1. **Add a game** → Non-Steam game → `HouseOfAshes.exe` in extract folder
2. **Compatibility** → force GE-Proton10-34  
   Alternative: `proton-cachyos-*` (one-time **sniper** runtime download is normal)
3. **Launch options** (critical on Linux):

```
WINEDLLOVERRIDES="OnlineFix64=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api64=n;winhttp=n,b" SteamAppId=480 %command%
```

See [launch-options.txt](launch-options.txt).

4. **Overlay** enabled: Settings → In-Game → Steam Overlay  
   Test: **Shift+Tab** in lobby (invites need overlay)

## Step 5 – First launch

- Steam Linux Runtime (**sniper**) may download once – wait until complete
- Trial “Buy full game” → check launch options (`WINEDLLOVERRIDES` often missing)

## Multiplayer

1. Host: **Shared Story** → lobby → **Invite**
2. Friend: same online fix, Steam **online**, same launch options
3. Friend does **not** need to be in-game already, but overlay/Steam must work

## Quick troubleshooting

| Issue | Fix |
|-------|-----|
| Trial “Buy full game” | Set `WINEDLLOVERRIDES` in launch options |
| Invite does nothing | Enable overlay, test Shift+Tab, launch via Steam |
| Garbled lobby name | Encoding/emu – usually not blocking invites |
| Runtime stuck | Switch Proton version, restart Steam |

Details: [../../docs/troubleshooting.md](../../docs/troubleshooting.md)

## App IDs

| ID | Usage |
|----|-------|
| 1281590 | House of Ashes (RealAppId) |
| 480 | Spacewar (FakeAppId / SteamAppId trick) |
