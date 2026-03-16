import sys

IS_WINDOWS = sys.platform == "win32"
IS_LINUX = sys.platform.startswith("linux")

if IS_WINDOWS:
    from .win32 import keyboard, mouse, window, pixel, capture, clipboard, scaling, hotkeys, system, gui_helpers
elif IS_LINUX:
    from .linux import keyboard, mouse, window, pixel, capture, clipboard, scaling, hotkeys, system, gui_helpers
else:
    raise RuntimeError(f"Unsupported platform: {sys.platform}")
