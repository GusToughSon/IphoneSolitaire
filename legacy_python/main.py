#!/usr/bin/env python3
"""
main.py – iPhone Mirroring detector (strict match, no false positives)

Controls:
    [  → Check mirroring status (only if real iPhone Mirroring window exists)
    ]  → Reset to red + NOT DETECTED
"""

import tkinter as tk
from tkinter import ttk
import threading
import subprocess
import Quartz
from Quartz import (
    CGEventTapCreate, kCGHeadInsertEventTap, kCGEventTapOptionDefault,
    CGEventMaskBit, kCGEventKeyDown, CFMachPortCreateRunLoopSource,
    CFRunLoopAddSource, CFRunLoopRun, CFRunLoopGetCurrent,
    CGEventGetIntegerValueField, kCGKeyboardEventKeycode,
    CGWindowListCopyWindowInfo, kCGWindowListOptionOnScreenOnly,
    kCGNullWindowID
)

# ----------------------
# Globals
# ----------------------
run_loop = None
mirror_status_var: tk.StringVar
status_color_canvas: tk.Canvas

# ----------------------
# Mirroring Check
# ----------------------
def iphone_mirroring_window_exists_strict() -> bool:
    try:
        options = kCGWindowListOptionOnScreenOnly
        window_info = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
        for w in window_info:
            owner = w.get("kCGWindowOwnerName", "")
            name = w.get("kCGWindowName", "")
            if owner == "iPhone Mirroring" and name == "iPhone Mirroring":
                return True
        return False
    except Exception as e:
        print("Strict check failed:", e)
        return False

# ----------------------
# UI helpers
# ----------------------
def set_mirroring_active():
    mirror_status_var.set("Mirroring: ACTIVE")
    status_color_canvas.configure(bg="green")

def set_mirroring_inactive():
    mirror_status_var.set("Mirroring: NOT DETECTED")
    status_color_canvas.configure(bg="red")

# ----------------------
# Keyboard Tap
# ----------------------
def keyboard_callback(proxy, type_, event, refcon):
    keycode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode)

    # '[' key
    if keycode == 33:
        if iphone_mirroring_window_exists_strict():
            set_mirroring_active()
        else:
            set_mirroring_inactive()

    # ']' key
    elif keycode == 30:
        set_mirroring_inactive()

    return event

def setup_keyboard_tap():
    global run_loop
    mask = CGEventMaskBit(kCGEventKeyDown)
    tap = CGEventTapCreate(
        Quartz.kCGSessionEventTap,
        kCGHeadInsertEventTap,
        kCGEventTapOptionDefault,
        mask,
        keyboard_callback,
        None
    )
    run_loop = CFRunLoopGetCurrent()
    source = CFMachPortCreateRunLoopSource(None, tap, 0)
    CFRunLoopAddSource(run_loop, source, Quartz.kCFRunLoopCommonModes)
    threading.Thread(target=CFRunLoopRun, daemon=True).start()

# ----------------------
# UI Setup
# ----------------------
root = tk.Tk()
root.title("iPhone Mirroring Checker")
root.geometry("320x170")
root.resizable(False, False)

mirror_status_var = tk.StringVar(value="Press [ to check mirroring")

status_label = ttk.Label(root, textvariable=mirror_status_var,
                         font=("Arial", 13))
status_label.pack(pady=(15, 8))

status_color_canvas = tk.Canvas(root, width=60, height=60,
                                bg="gray", highlightthickness=0)
status_color_canvas.pack(pady=8)

instruction = ttk.Label(root,
    text="Controls: [ = check • ] = reset • Close window to quit",
    font=("Arial", 9))
instruction.pack(pady=(0, 6))

setup_keyboard_tap()
root.mainloop()
