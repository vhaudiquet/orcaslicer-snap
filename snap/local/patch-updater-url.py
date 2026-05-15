#!/usr/bin/env python3
"""
Patch the OrcaSlicer binary to disable the built-in update checker.

Snaps are updated through the store, so the in-app updater is redundant.
More importantly, it fetches release notes that contain emoji which crash
pango's font resolution code (NULL pointer dereference in ensure_faces() /
pango_fc_font_map_get_face) on certain system pango versions.

Redirecting to localhost makes the request fail silently with a connection
error and no dialog is shown.  The replacement must be the same byte length
as the original string so the binary layout and all offsets are preserved.
"""

import sys


def patch(binary_path: str) -> None:
    old = b"https://check-version.orcaslicer.com/latest"
    new_url = b"https://localhost/"
    new = new_url + b"\x00" * (len(old) - len(new_url))
    assert len(old) == len(new), "replacement length mismatch"

    with open(binary_path, "rb") as f:
        data = f.read()

    count = data.count(old)
    if count == 0:
        print(
            "WARNING: update-check URL not found in binary - patch skipped",
            flush=True,
        )
        return

    patched = data.replace(old, new)
    with open(binary_path, "wb") as f:
        f.write(patched)

    print(f"Patched update-check URL ({count} occurrence(s))", flush=True)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <binary>", file=sys.stderr)
        sys.exit(1)
    patch(sys.argv[1])
