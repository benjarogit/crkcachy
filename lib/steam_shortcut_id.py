#!/usr/bin/env python3
"""Read/update Steam shortcuts.vdf – AppIDs, name, launch options."""

from __future__ import annotations

import argparse
import re
import struct
import sys
import zlib

try:
    import vdf
except ImportError:
    vdf = None  # type: ignore

PATTERN = re.compile(
    rb"\x00\x02appid\x00(.{4})\x01appname\x00([^\x08]+?)\x00\x01exe\x00([^\x08]+?)\x00",
    re.IGNORECASE,
)


def unsigned32(value: int) -> int:
    return value & 0xFFFFFFFF


def legacy_grid_id(exe_raw: bytes, name_raw: bytes) -> int:
    return unsigned32(zlib.crc32(exe_raw + name_raw) | 0x80000000)


def normalize_path(path: str) -> str:
    return path.replace("\\", "/").lower().strip('"').strip()


def entry_exe(entry: dict) -> str:
    return str(entry.get("Exe") or entry.get("exe") or "")


def entry_appname(entry: dict) -> str:
    return str(entry.get("AppName") or entry.get("appname") or "")


def entry_launch_options(entry: dict) -> str:
    return str(entry.get("LaunchOptions") or entry.get("launchoptions") or "")


def set_entry_appname(entry: dict, name: str) -> None:
    if "AppName" in entry:
        entry["AppName"] = name
    elif "appname" in entry:
        entry["appname"] = name
    else:
        entry["AppName"] = name


def set_entry_launch_options(entry: dict, launch_opts: str) -> None:
    if "LaunchOptions" in entry:
        entry["LaunchOptions"] = launch_opts
    elif "launchoptions" in entry:
        entry["launchoptions"] = launch_opts
    else:
        entry["LaunchOptions"] = launch_opts


def matches_entry(entry: dict, exe_hint: str, basename: str | None) -> bool:
    exe_norm = normalize_path(entry_exe(entry))
    hint_norm = normalize_path(exe_hint)
    if hint_norm and hint_norm in exe_norm:
        return True
    if basename and basename.lower() in exe_norm:
        return True
    return False


def rungameid_64(unsigned: int) -> int:
    """Steam URI id for non-Steam shortcuts: (unsigned << 32) | 0x02000000."""
    return (unsigned << 32) | 0x02000000


def parse_shortcuts_regex(data: bytes):
    for match in PATTERN.finditer(data):
        appid_signed = struct.unpack("<i", match.group(1))[0]
        name = match.group(2).decode("utf-8", errors="replace")
        exe = match.group(3).decode("utf-8", errors="replace")
        exe_raw = match.group(3)
        name_raw = match.group(2)
        yield {
            "appid_signed": appid_signed,
            "appid_unsigned": unsigned32(appid_signed),
            "legacy_unsigned": legacy_grid_id(exe_raw, name_raw),
            "appname": name,
            "exe": exe,
        }


def load_shortcuts(shortcuts_path: str) -> dict:
    if vdf is None:
        print("error: python-vdf required (pacman -S python-vdf)", file=sys.stderr)
        raise RuntimeError("no vdf")
    with open(shortcuts_path, "rb") as handle:
        return vdf.binary_load(handle)


def save_shortcuts(shortcuts_path: str, data: dict) -> None:
    with open(shortcuts_path, "wb") as handle:
        vdf.binary_dump(data, handle)


def list_shortcuts_from_vdf(shortcuts_path: str, exe_hint: str, basename: str) -> int:
    try:
        data = load_shortcuts(shortcuts_path)
    except (OSError, RuntimeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    shortcuts = data.get("shortcuts", {})
    if not isinstance(shortcuts, dict):
        return 2

    if not basename and exe_hint:
        basename = exe_hint.rsplit("/", 1)[-1]

    found = False
    for entry in shortcuts.values():
        if not isinstance(entry, dict):
            continue
        if not matches_entry(entry, exe_hint, basename):
            continue

        raw_appid = entry.get("appid")
        if raw_appid is None:
            continue

        found = True
        exe = entry_exe(entry)
        name = entry_appname(entry)
        appid_signed = int(raw_appid)
        appid_unsigned = unsigned32(appid_signed)
        exe_raw = exe.encode("utf-8", errors="replace")
        name_raw = name.encode("utf-8", errors="replace")
        legacy = legacy_grid_id(exe_raw, name_raw)
        launch = entry_launch_options(entry)
        run_id = rungameid_64(appid_unsigned)
        print(
            f"{appid_signed}\t{appid_unsigned}\t{legacy}\t{name}\t{exe}\t{run_id}\t{launch}"
        )

    return 0 if found else 2


def list_shortcuts(shortcuts_path: str, exe_hint: str, basename: str) -> int:
    if vdf is not None:
        result = list_shortcuts_from_vdf(shortcuts_path, exe_hint, basename)
        if result != 2:
            return result

    try:
        with open(shortcuts_path, "rb") as handle:
            data = handle.read()
    except OSError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if not basename and exe_hint:
        basename = exe_hint.rsplit("/", 1)[-1]

    found = False
    for entry in parse_shortcuts_regex(data):
        if not matches_entry(
            {"Exe": entry["exe"], "AppName": entry["appname"]},
            exe_hint,
            basename,
        ):
            continue
        found = True
        run_id = rungameid_64(entry["appid_unsigned"])
        print(
            f"{entry['appid_signed']}\t{entry['appid_unsigned']}\t"
            f"{entry['legacy_unsigned']}\t{entry['appname']}\t{entry['exe']}\t{run_id}\t"
        )

    return 0 if found else 2


def update_matching_shortcuts(
    shortcuts_path: str,
    exe_hint: str,
    basename: str,
    update_fn,
) -> int:
    try:
        data = load_shortcuts(shortcuts_path)
    except (OSError, RuntimeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    shortcuts = data.get("shortcuts", {})
    if not isinstance(shortcuts, dict):
        print("error: no shortcuts section", file=sys.stderr)
        return 1

    if not basename and exe_hint:
        basename = exe_hint.rsplit("/", 1)[-1]

    changed = 0
    for entry in shortcuts.values():
        if not isinstance(entry, dict):
            continue
        if not matches_entry(entry, exe_hint, basename):
            continue
        if update_fn(entry):
            changed += 1

    if changed == 0:
        return 2

    try:
        save_shortcuts(shortcuts_path, data)
    except OSError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    return 0


def rename_shortcuts(shortcuts_path: str, exe_hint: str, basename: str, new_name: str) -> int:
    if not new_name.strip():
        print("error: empty name", file=sys.stderr)
        return 1

    def _update(entry: dict) -> bool:
        old_name = entry_appname(entry)
        if old_name == new_name:
            print(f"unchanged-name\t{old_name}")
            return False
        set_entry_appname(entry, new_name)
        print(f"renamed\t{old_name}\t{new_name}")
        return True

    result = update_matching_shortcuts(shortcuts_path, exe_hint, basename, _update)
    if result == 2:
        # only unchanged entries
        return 0
    return result


def set_launch_options_shortcuts(
    shortcuts_path: str,
    exe_hint: str,
    basename: str,
    launch_opts: str,
) -> int:
    launch_opts = launch_opts.strip()
    if not launch_opts:
        print("error: empty launch options", file=sys.stderr)
        return 1

    def _update(entry: dict) -> bool:
        old_opts = entry_launch_options(entry)
        if old_opts == launch_opts:
            print("unchanged-launch")
            return False
        set_entry_launch_options(entry, launch_opts)
        print("launch-updated")
        return True

    result = update_matching_shortcuts(shortcuts_path, exe_hint, basename, _update)
    if result == 2:
        return 0
    return result


def clear_launch_options_shortcuts(
    shortcuts_path: str,
    exe_hint: str,
    basename: str,
) -> int:
    def _update(entry: dict) -> bool:
        old_opts = entry_launch_options(entry)
        if not old_opts.strip():
            print("unchanged-launch")
            return False
        set_entry_launch_options(entry, "")
        print("launch-cleared")
        return True

    result = update_matching_shortcuts(shortcuts_path, exe_hint, basename, _update)
    if result == 2:
        return 0
    return result


def compute_appid(exe_path: str, app_name: str) -> int:
    """Compute the non-Steam shortcut appid (matches Steam's own formula)."""
    exe_bytes = exe_path.encode("utf-8", errors="replace")
    name_bytes = app_name.encode("utf-8", errors="replace")
    # Steam uses: crc32(exe + name) | 0x80000000, then store as signed int32
    crc = zlib.crc32(exe_bytes + name_bytes) & 0xFFFFFFFF
    unsigned = crc | 0x80000000
    return struct.unpack("<i", struct.pack("<I", unsigned & 0xFFFFFFFF))[0]


def add_shortcut(
    shortcuts_path: str,
    exe_path: str,
    app_name: str,
    start_dir: str = "",
    launch_opts: str = "",
) -> int:
    """Add a new non-Steam shortcut entry. Returns 0 on success, 1 on error, 3 if already present."""
    if vdf is None:
        print("error: python-vdf required", file=sys.stderr)
        return 1

    exe_quoted = f'"{exe_path}"'
    if not start_dir:
        start_dir = exe_path.rsplit("/", 1)[0]

    # Check if already present
    try:
        data = load_shortcuts(shortcuts_path)
    except (OSError, RuntimeError):
        # File missing or empty – start fresh
        data = {"shortcuts": {}}

    shortcuts = data.get("shortcuts")
    if not isinstance(shortcuts, dict):
        data["shortcuts"] = {}
        shortcuts = data["shortcuts"]

    for entry in shortcuts.values():
        if isinstance(entry, dict) and matches_entry(entry, exe_path, exe_path.rsplit("/", 1)[-1]):
            print("already-present")
            return 3

    # Next available integer key
    next_key = str(max((int(k) for k in shortcuts if k.isdigit()), default=-1) + 1)

    appid = compute_appid(exe_quoted, app_name)
    new_entry: dict = {
        "appid":               appid,
        "AppName":             app_name,
        "Exe":                 exe_quoted,
        "StartDir":            f'"{start_dir}"',
        "icon":                "",
        "ShortcutPath":        "",
        "LaunchOptions":       launch_opts,
        "IsHidden":            0,
        "AllowDesktopConfig":  1,
        "AllowOverlay":        1,
        "OpenVR":              0,
        "Devkit":              0,
        "DevkitGameID":        "",
        "DevkitOverrideAppID": 0,
        "LastPlayTime":        0,
        "FlatpakAppID":        "",
        "tags":                {},
    }
    shortcuts[next_key] = new_entry

    try:
        save_shortcuts(shortcuts_path, data)
    except OSError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    appid_unsigned = unsigned32(appid)
    exe_raw = exe_quoted.encode("utf-8", errors="replace")
    name_raw = app_name.encode("utf-8", errors="replace")
    legacy = legacy_grid_id(exe_raw, name_raw)
    run_id = rungameid_64(appid_unsigned)
    print(f"added\t{appid}\t{appid_unsigned}\t{legacy}\t{app_name}\t{exe_quoted}\t{run_id}")
    return 0


def remove_matching_shortcuts(
    shortcuts_path: str,
    exe_hint: str,
    basename: str,
) -> int:
    try:
        data = load_shortcuts(shortcuts_path)
    except (OSError, RuntimeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    shortcuts = data.get("shortcuts", {})
    if not isinstance(shortcuts, dict):
        print("error: no shortcuts section", file=sys.stderr)
        return 1

    if not basename and exe_hint:
        basename = exe_hint.rsplit("/", 1)[-1]

    to_delete = []
    for key, entry in shortcuts.items():
        if not isinstance(entry, dict):
            continue
        if matches_entry(entry, exe_hint, basename):
            to_delete.append(key)

    if not to_delete:
        return 2

    for key in to_delete:
        del shortcuts[key]

    try:
        save_shortcuts(shortcuts_path, data)
    except OSError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"removed\t{len(to_delete)}")
    return 0


def set_compat_tool(config_vdf_path: str, app_unsigned_id: str, tool_name: str) -> int:
    """Set the Proton compat tool for a non-Steam shortcut in config.vdf.

    Path: InstallConfigStore > Software > Valve > Steam > CompatToolMapping > <app_id>
    """
    if vdf is None:
        print("error: python-vdf required (pacman -S python-vdf)", file=sys.stderr)
        return 1

    try:
        with open(config_vdf_path, encoding="utf-8") as f:
            data = vdf.load(f)
    except (OSError, Exception) as exc:
        print(f"error reading config.vdf: {exc}", file=sys.stderr)
        return 1

    try:
        compat_map = (
            data
            .setdefault("InstallConfigStore", {})
            .setdefault("Software", {})
            .setdefault("Valve", {})
            .setdefault("Steam", {})
            .setdefault("CompatToolMapping", {})
        )
    except Exception as exc:
        print(f"error navigating config.vdf: {exc}", file=sys.stderr)
        return 1

    compat_map[str(app_unsigned_id)] = {
        "name":     tool_name,
        "config":   "",
        "Priority": "250",
    }

    try:
        with open(config_vdf_path, "w", encoding="utf-8") as f:
            vdf.dump(data, f, pretty=True)
    except OSError as exc:
        print(f"error writing config.vdf: {exc}", file=sys.stderr)
        return 1

    print(f"compat-tool-set\t{app_unsigned_id}\t{tool_name}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("shortcuts_vdf", nargs="?", default="",
                        help="Path to shortcuts.vdf (not needed for --set-compat-tool)")
    parser.add_argument("--exe", default="", help="Full Linux path to game exe")
    parser.add_argument("--basename", default="", help="Exe basename e.g. HouseOfAshes.exe")
    parser.add_argument("--set-name", default="", help="Rename matching shortcut display name")
    parser.add_argument("--set-launch-options", default="", help="Set LaunchOptions field")
    parser.add_argument(
        "--clear-launch-options",
        action="store_true",
        help="Remove LaunchOptions from matching shortcut",
    )
    parser.add_argument(
        "--remove-shortcut",
        action="store_true",
        help="Remove matching shortcut from Steam library",
    )
    parser.add_argument("--add-shortcut", default="", help="Add new shortcut with this display name")
    parser.add_argument("--start-dir", default="", help="StartDir for --add-shortcut")
    parser.add_argument("--launch-options-add", default="", help="LaunchOptions for --add-shortcut")
    # Compat tool setting (uses config.vdf, not shortcuts.vdf)
    parser.add_argument("--config-vdf", default="", help="Path to Steam config.vdf")
    parser.add_argument("--set-compat-tool", default="", help="Proton tool name to set (e.g. GE-Proton10-34)")
    parser.add_argument("--app-unsigned-id", default="", help="Unsigned app ID for --set-compat-tool")
    args = parser.parse_args()

    # Compat tool setting (independent of shortcuts.vdf)
    if args.set_compat_tool:
        if not args.config_vdf:
            print("error: --config-vdf required for --set-compat-tool", file=sys.stderr)
            return 1
        if not args.app_unsigned_id:
            print("error: --app-unsigned-id required for --set-compat-tool", file=sys.stderr)
            return 1
        return set_compat_tool(args.config_vdf, args.app_unsigned_id, args.set_compat_tool)

    if not args.shortcuts_vdf:
        print("error: shortcuts_vdf required", file=sys.stderr)
        return 1

    if args.add_shortcut:
        return add_shortcut(
            args.shortcuts_vdf,
            args.exe,
            args.add_shortcut,
            args.start_dir,
            args.launch_options_add,
        )

    if args.set_name:
        return rename_shortcuts(
            args.shortcuts_vdf,
            args.exe,
            args.basename,
            args.set_name,
        )

    if args.set_launch_options:
        return set_launch_options_shortcuts(
            args.shortcuts_vdf,
            args.exe,
            args.basename,
            args.set_launch_options,
        )

    if args.clear_launch_options:
        return clear_launch_options_shortcuts(
            args.shortcuts_vdf,
            args.exe,
            args.basename,
        )

    if args.remove_shortcut:
        return remove_matching_shortcuts(
            args.shortcuts_vdf,
            args.exe,
            args.basename,
        )

    return list_shortcuts(args.shortcuts_vdf, args.exe, args.basename)


if __name__ == "__main__":
    sys.exit(main())
