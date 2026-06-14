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


def list_shortcuts(shortcuts_path: str, exe_hint: str, basename: str) -> int:
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
            f"{entry['legacy_unsigned']}\t{entry['appname']}\t{entry['exe']}\t{run_id}"
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("shortcuts_vdf")
    parser.add_argument("--exe", default="", help="Full Linux path to game exe")
    parser.add_argument("--basename", default="", help="Exe basename e.g. HouseOfAshes.exe")
    parser.add_argument("--set-name", default="", help="Rename matching shortcut display name")
    parser.add_argument("--set-launch-options", default="", help="Set LaunchOptions field")
    args = parser.parse_args()

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

    return list_shortcuts(args.shortcuts_vdf, args.exe, args.basename)


if __name__ == "__main__":
    sys.exit(main())
