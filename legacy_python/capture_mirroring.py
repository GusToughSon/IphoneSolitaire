#!/usr/bin/env python3
import os
import datetime
import subprocess
from PIL import Image
from Quartz import (
    CGWindowListCopyWindowInfo, kCGWindowListOptionOnScreenOnly,
    kCGNullWindowID, CGWindowListCreateImage, CGRectMake,
    kCGWindowImageDefault, CGImageGetWidth, CGImageGetHeight,
    CGImageGetBitsPerPixel, CGImageGetBytesPerRow,
    CGDataProviderCopyData, CGImageGetDataProvider
)

def bring_iphone_mirroring_to_front():
    script = '''
    tell application "System Events"
        set frontmost of process "iPhone Mirroring" to true
    end tell
    '''
    subprocess.run(["osascript", "-e", script])

def get_iphone_mirroring_bounds():
    windows = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID)
    for win in windows:
        if win.get("kCGWindowOwnerName") == "iPhone Mirroring" and win.get("kCGWindowName") == "iPhone Mirroring":
            bounds = win.get("kCGWindowBounds", {})
            return (
                int(bounds.get("X", 0)),
                int(bounds.get("Y", 0)),
                int(bounds.get("Width", 0)),
                int(bounds.get("Height", 0))
            )
    return None

def ensure_snapshot_dir():
    snap_dir = os.path.join(os.getcwd(), "snapshot")
    if not os.path.exists(snap_dir):
        os.makedirs(snap_dir)
    return snap_dir

def cleanup_old_snapshots(snap_dir, new_file):
    snapshots = sorted(
        [f for f in os.listdir(snap_dir) if f.endswith(".png") and f != "last.png"],
        key=lambda f: os.path.getmtime(os.path.join(snap_dir, f))
    )
    if len(snapshots) >= 1:
        prev_snapshot = snapshots[-1]
        prev_path = os.path.join(snap_dir, prev_snapshot)
        last_path = os.path.join(snap_dir, "last.png")
        Image.open(prev_path).save(last_path)
    for f in snapshots[:-1]:
        os.remove(os.path.join(snap_dir, f))

def capture_iphone_mirroring_window():
    bounds = get_iphone_mirroring_bounds()
    if not bounds:
        print("❌ iPhone Mirroring window not found.")
        return

    x, y, w, h = bounds
    print(f"📸 Capturing: ({x},{y}) → {w}x{h}")

    rect = CGRectMake(x, y, w, h)
    image_ref = CGWindowListCreateImage(rect, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault)

    if not image_ref:
        print("❌ Could not capture window image.")
        return

    data = CGDataProviderCopyData(CGImageGetDataProvider(image_ref))
    img_bytes = bytes(data)
    width = CGImageGetWidth(image_ref)
    height = CGImageGetHeight(image_ref)
    bpp = CGImageGetBitsPerPixel(image_ref)
    bpr = CGImageGetBytesPerRow(image_ref)

    # Fix macOS color channel order (BGRA → RGBA)
    img = Image.frombytes("RGBA", (width, height), img_bytes, "raw", "BGRA", bpr)

    # === Final Trim Settings ===
    left_trim = 12
    right_trim = 12
    top_trim = 74
    bottom_trim = 20

    img = img.crop((
        left_trim,
        top_trim,
        width - right_trim,
        height - bottom_trim
    ))

    snap_dir = ensure_snapshot_dir()
    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    out_path = os.path.join(snap_dir, f"{timestamp}.png")
    img.save(out_path)

    cleanup_old_snapshots(snap_dir, out_path)

    print(f"✅ Saved snapshot to: {out_path}")

if __name__ == "__main__":
    bring_iphone_mirroring_to_front()
    capture_iphone_mirroring_window()
