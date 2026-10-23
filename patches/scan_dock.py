"""Check that the yabai macOS 27 patch's Dock patterns still match this Mac's Dock.

Usage: python3 -I scan_dock.py <yabai-macos27.patch>

Replays the payload's hex_find_seq search on every arm64e slice of the Dock,
using the offsets and patterns the patch adds for macOS 27. Exits 1 if any
target is missing from any slice, which happens when a macOS update moves
the Dock code the patch hooks.
"""

import re
import struct
import sys

DOCK = "/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"
SEARCH_WINDOW = 0x1286A0
CPU_TYPE_ARM64 = 0x0100000C


def macos27_targets(patch_path):
    values = {}
    function = None
    awaiting_return = False
    in_payload = False
    for line in open(patch_path):
        if line.startswith("diff --git"):
            in_payload = line.rstrip().endswith("/src/osax/arm64_payload.m")
            function = None
        elif not in_payload:
            continue
        elif m := re.search(r"get_(\w+)_(offset|pattern)\(", line):
            function = m.groups()
        elif "majorVersion == 27" in line and function:
            awaiting_return = True
        elif awaiting_return and (m := re.match(r"\+\s+return (.+);", line)):
            values[function] = m.group(1)
            awaiting_return = False

    targets = {}
    for (name, kind), value in values.items():
        if kind != "pattern" or value == "NULL":
            continue
        targets[name] = (int(values[(name, "offset")], 16), value.strip('"'))
    return targets


def to_regex(pattern):
    # hex_find_seq treats any token starting with '?' as a full-byte wildcard
    return re.compile(
        b"".join(b"." if t[0] == "?" else re.escape(bytes([int(t, 16)])) for t in pattern.split()),
        re.S,
    )


def arm64_slices(path):
    data = open(path, "rb").read()
    _, count = struct.unpack(">II", data[:8])
    for i in range(count):
        cputype, subtype, offset, size, _ = struct.unpack(">iiIII", data[8 + i * 20 : 28 + i * 20])
        if cputype == CPU_TYPE_ARM64:
            yield subtype & 0xFFFFFFFF, data[offset : offset + size]


def main():
    targets = macos27_targets(sys.argv[1])
    missing = []
    for subtype, binary in arm64_slices(DOCK):
        for name, (start, pattern) in targets.items():
            end = start + SEARCH_WINDOW + len(pattern.split())
            if not to_regex(pattern).search(binary, start, end):
                missing.append(f"{name} (slice 0x{subtype:08x})")

    if missing:
        print("Dock patterns not found: " + ", ".join(missing))
        sys.exit(1)
    print(f"All {len(targets)} Dock patterns found")


main()
