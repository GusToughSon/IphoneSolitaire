#!/usr/bin/env python3
"""Check for iPhone screen mirroring on macOS.

The script detects whether an iPhone is connected via USB and if QuickTime
Player is running. If both conditions are satisfied, we assume the user might
be mirroring their iPhone screen to the Mac.

This script is intended for macOS.
"""
from __future__ import annotations

import subprocess
import sys


def device_connected() -> bool:
    """Return True if an iPhone is connected over USB."""
    try:
        result = subprocess.run(
            ["system_profiler", "-detailLevel", "mini", "SPUSBDataType"],
            capture_output=True,
            text=True,
            check=True,
        )
        return "iPhone" in result.stdout
    except (subprocess.SubprocessError, FileNotFoundError):
        return False


def quicktime_running() -> bool:
    """Return True if QuickTime Player is running."""
    try:
        result = subprocess.run(
            ["pgrep", "-x", "QuickTime Player"], capture_output=True
        )
        return result.returncode == 0
    except FileNotFoundError:
        # pgrep might not be available; fall back to ps
        try:
            result = subprocess.run(
                ["ps", "aux"], capture_output=True, text=True, check=True
            )
            return "QuickTime Player" in result.stdout
        except subprocess.SubprocessError:
            return False


def is_mirroring() -> bool:
    """Determine if iPhone mirroring appears to be active."""
    return device_connected() and quicktime_running()


if __name__ == "__main__":
    if is_mirroring():
        print("iPhone mirroring appears to be active.")
        sys.exit(0)
    else:
        print("No iPhone mirroring detected.")
        sys.exit(1)
