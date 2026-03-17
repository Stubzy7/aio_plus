import subprocess


def _xdo_run(*args: str) -> str:
    try:
        result = subprocess.run(["xdotool"] + list(args),
                                capture_output=True, text=True, timeout=5)
        return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""


def _xdo(*args: str):
    try:
        subprocess.run(["xdotool"] + list(args),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=5)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass


def _get_class_name(hwnd: int) -> str:
    try:
        result = subprocess.run(
            ["xprop", "-id", str(hwnd), "WM_CLASS"],
            capture_output=True, text=True, timeout=2
        )
        if "=" in result.stdout:
            return result.stdout.split("=", 1)[1].strip().strip('"')
    except Exception:
        pass
    return ""


def find_window(class_name=None, title=None) -> int:
    args = ["search"]
    if class_name:
        args += ["--class", class_name]
    if title:
        args += ["--name", title]
    if not class_name and not title:
        return 0
    output = _xdo_run(*args)
    if output:
        first_line = output.split('\n')[0].strip()
        if first_line.isdigit():
            return int(first_line)
    return 0


def win_exist(title: str) -> int:
    return find_window(title=title)


def win_activate(hwnd: int):
    _xdo("windowactivate", "--sync", str(hwnd))


def win_get_pos(hwnd: int) -> tuple[int, int, int, int]:
    output = _xdo_run("getwindowgeometry", "--shell", str(hwnd))
    x, y, w, h = 0, 0, 0, 0
    for line in output.split('\n'):
        line = line.strip()
        if line.startswith("X="):
            x = int(line[2:])
        elif line.startswith("Y="):
            y = int(line[2:])
        elif line.startswith("WIDTH="):
            w = int(line[6:])
        elif line.startswith("HEIGHT="):
            h = int(line[7:])
    return x, y, w, h


def win_move(hwnd: int, x: int, y: int, w: int = 0, h: int = 0):
    _xdo("windowmove", str(hwnd), str(x), str(y))
    if w > 0 and h > 0:
        _xdo("windowsize", str(hwnd), str(w), str(h))


def find_input_child(hwnd: int) -> int:
    # On Linux, no separate HWND for input controls
    return hwnd


def control_click(hwnd: int, x: int, y: int):
    _xdo("mousemove", "--window", str(hwnd), "--sync", str(x), str(y))
    _xdo("click", "--window", str(hwnd), "1")


def get_client_rect(hwnd: int) -> tuple[int, int, int, int]:
    return win_get_pos(hwnd)


def is_window_visible(hwnd: int) -> bool:
    output = _xdo_run("getwindowgeometry", str(hwnd))
    return len(output) > 0


def get_foreground_window() -> int:
    output = _xdo_run("getactivewindow")
    if output.strip().isdigit():
        return int(output.strip())
    return 0


def _flash_activate(hwnd: int) -> int:
    prev = get_foreground_window()
    win_activate(hwnd)
    return prev


def _flash_restore(prev_hwnd: int, game_hwnd: int):
    if prev_hwnd and prev_hwnd != game_hwnd:
        win_activate(prev_hwnd)
    else:
        win_activate(game_hwnd)
