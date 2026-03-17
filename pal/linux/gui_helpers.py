from . import window as _win


def set_no_activate(hwnd_hex_str: str):
    pass


def flash_activate(hwnd: int) -> int:
    return _win._flash_activate(hwnd)


def flash_restore(prev_hwnd: int, game_hwnd: int):
    _win._flash_restore(prev_hwnd, game_hwnd)
