import ctypes

user32 = ctypes.windll.user32
user32.SetProcessDPIAware()

def get_screen_size() -> tuple[int, int]:
    return user32.GetSystemMetrics(0), user32.GetSystemMetrics(1)

def set_dpi_aware():
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        user32.SetProcessDPIAware()
