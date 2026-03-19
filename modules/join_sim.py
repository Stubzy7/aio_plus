
import logging
import time

from core.state import state
from core.timers import timers
from input.window import (
    win_exist, win_activate, win_get_pos, win_move,
    control_click, get_foreground_window, find_input_child,
    _get_class_name,
)
from input.keyboard import send, send_text, control_send, control_send_text

log = logging.getLogger(__name__)

TIMER_NAME = "sim_loop"
SIM_INTERVAL_MS = 10

STATES = [
    "MainMenu", "MiddleMenu", "ServerBrowser", "ServerSelected",
    "ModMenu", "ServerFull", "ServerFull2", "ServerFull3",
    "ConnectionTimeout", "WaitingToJoin", "NoSessions",
    "SinglePlayer", "ContentFailed", "Unknown",
]


def _tooltip(text: str | None = None):
    try:
        from gui.tooltip import show_tooltip, hide_tooltip, update_tooltip
        if text:
            update_tooltip(text)
        else:
            hide_tooltip()
    except Exception:
        if text:
            log.info("tooltip: %s", text)


def sim_log_msg(msg: str):
    ts = time.strftime("%H:%M:%S")
    state.sim_log.append(f"{ts} {msg}")
    if len(state.sim_log) > 100:
        state.sim_log.pop(0)
    log.debug("Sim: %s", msg)


def update_sim_status(text: str):
    state.sim_cycle_status = text
    _update_gui_status(text)
    if state.toolbox_enabled:
        _tooltip(f"Simming for: {_server_number()} | {text}")


def _update_gui_status(text: str):
    try:
        root = state.root
        js = getattr(state, "_tab_joinsim", None)
        if root is None or js is None:
            return
        root.after(0, lambda: js.sim_status.configure(text=text))
    except Exception:
        pass


def _server_number() -> str:
    return state.server_number or ""


def _game_hwnd() -> int:
    return win_exist(state.game_window)


def _input_hwnd() -> int:
    cached = getattr(state, "_sim_input_hwnd", 0)
    if cached and win_exist(state.game_window):
        return cached
    return _game_hwnd()


def _click_window(x: int, y: int):
    hwnd = _input_hwnd()
    if hwnd:
        ix, iy = int(x), int(y)
        log.debug("ClickWindow: hwnd=%s target=(%d,%d)", hwnd, ix, iy)
        control_click(hwnd, ix, iy)


def _send_window(keys: str):
    hwnd = _input_hwnd()
    if hwnd:
        control_send(hwnd, keys)


def _send_window_text(text: str):
    hwnd = _input_hwnd()
    if hwnd:
        control_send_text(hwnd, text)


def check_state() -> str:
    try:
        from input.capture import capture_window, get_pixel_argb, release_capture
    except ImportError:
        return ""

    hwnd = _game_hwnd()
    if not hwnd:
        return ""

    img = capture_window(hwnd)
    if img is None:
        return ""

    result = ""
    color_dump = ""

    state_table = getattr(state, "sim_state_table_a", [])

    for item in state_table:
        color = get_pixel_argb(img, item["x"], item["y"])
        color_dump += f'{item["name"]}={color:#010x} '

        match = (color == item["c"])
        if not match and item.get("calt") is not None:
            match = (color == item["calt"])

        if not match:
            from input.pixel import is_color_similar
            match = is_color_similar(color & 0xFFFFFF, item["c"] & 0xFFFFFF, state.col_tol)
            if not match and item.get("calt") is not None:
                match = is_color_similar(color & 0xFFFFFF, item["calt"] & 0xFFFFFF, state.col_tol)

        if match:
            # NoSessions 3-pixel guard — prevents false detections during loading
            if item["name"] == "NoSessions":
                gw = state.game_width or 2560
                gh = state.game_height or 1440
                confirm_x = int(0.3786458333 * gw)
                confirm_y = int(0.2101851852 * gh)
                confirm_col = get_pixel_argb(img, confirm_x, confirm_y)
                if not is_color_similar(confirm_col & 0xFFFFFF, 0xFFFFFF, state.col_tol):
                    continue
                row_x = int(0.2083333333 * gw)
                row_y = int(0.2305555556 * gh)
                row_col = get_pixel_argb(img, row_x, row_y) & 0xFFFFFF
                row_r = (row_col >> 16) & 0xFF
                row_g = (row_col >> 8) & 0xFF
                row_b = row_col & 0xFF
                if (row_r + row_g + row_b) > 150:
                    continue
                be_x = int(0.056250000000000001 * gw)
                be_y = int(0.3037037037037037 * gh)
                be_col = get_pixel_argb(img, be_x, be_y)
                be_logo = 0xFFFFFFBC
                if be_col == be_logo or is_color_similar(be_col & 0xFFFFFF, be_logo & 0xFFFFFF, state.col_tol):
                    continue

            if "x2" in item and "y2" in item and "c2" in item:
                c2 = get_pixel_argb(img, item["x2"], item["y2"])
                if c2 == item["c2"] or is_color_similar(c2 & 0xFFFFFF, item["c2"] & 0xFFFFFF, state.col_tol):
                    result = item["name"]
                    break
            else:
                result = item["name"]
                break

    state.sim_last_colors = color_dump
    state.sim_last_state = result if result else "Unknown"
    release_capture(img)
    return result


def check_state_b() -> str:
    try:
        from input.capture import capture_window, get_pixel_argb, release_capture
    except ImportError:
        return ""

    hwnd = _game_hwnd()
    if not hwnd:
        return ""

    img = capture_window(hwnd)
    if img is None:
        return ""

    result = ""
    color_dump = ""

    state_table = getattr(state, "sim_state_table_b", [])

    for item in state_table:
        color = get_pixel_argb(img, item["x"], item["y"])
        color_dump += f'{item["name"]}={color:#010x} '

        match = (color == item["c"])
        if not match and item.get("calt") is not None:
            match = (color == item["calt"])

        if match:
            if "x2" in item and "y2" in item and "c2" in item:
                c2 = get_pixel_argb(img, item["x2"], item["y2"])
                if c2 == item["c2"]:
                    result = item["name"]
                    break
            else:
                result = item["name"]
                break

    state.sim_last_colors = color_dump
    state.sim_last_state = result if result else "Unknown"
    release_capture(img)
    return result


def _off(name: str, default: int = 0) -> int:
    return int(getattr(state, name, default))


def _joinsim_anim(method: str):
    js = getattr(state, "_tab_joinsim", None)
    if js and state.root:
        state.root.after(0, getattr(js, method))


def _handle_main_menu():
    _send_window("{Enter}")
    time.sleep(0.1)
    _click_window(_off("back_offset_x"), _off("back_offset_y"))
    time.sleep(0.5)
    _click_window(_off("back_offset_x"), _off("back_offset_y"))
    time.sleep(0.5)
    hwnd = _game_hwnd()
    if hwnd:
        gx, gy, _, _ = win_get_pos(hwnd)
        if gx == 0 and gy == 0:
            win_move(hwnd, 1, 0)
            state.incounter = 0


def sim_loop():
    if not getattr(state, "auto_sim_check", False):
        return
    state.sim_cycle_count += 1
    if state.sim_mode == 2:
        sim_loop_b()
    else:
        sim_loop_a()


def sim_loop_a():
    s = check_state()

    if s != "WaitingToJoin":
        state.wm = 0

    if s == state.stuck_state and s != "" and s != "WaitingToJoin":
        state.stuck_count += 1
    else:
        state.stuck_state = s
        state.stuck_count = 0

    if state.stuck_count >= 150 and s != "WaitingToJoin" and s != "":
        sim_log_msg(f"[{state.sim_cycle_count}] STUCK RECOVERY — state '{s}' repeated {state.stuck_count} times, clicking Back")
        update_sim_status(f"Stuck in {s} — recovering")
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        state.stuck_count = 0
        state.nosessions = 0
        state.sm = 0
        state.mm = 0
        return

    if s == "SinglePlayer":
        sim_log_msg(f"[{state.sim_cycle_count}] SinglePlayer — backing out")
        update_sim_status("SinglePlayer - backing out")
        _click_window(_off("sp_back_offset_x"), _off("sp_back_offset_y"))
        time.sleep(0.25)

    elif s in ("ServerFull", "ServerFull2", "ServerFull3"):
        hwnd = _game_hwnd()
        if hwnd:
            gx, gy, _, _ = win_get_pos(hwnd)
            if gx == 0 and gy == 0:
                win_move(hwnd, 1, 0)
                state.incounter = 0
        sim_log_msg(f"[{state.sim_cycle_count}] {s} — Enter + Back")
        update_sim_status("Server Full - retrying")
        _send_window("{Enter}")
        time.sleep(0.1)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        state.jl = 0
        state.sm = 0

    elif s == "ConnectionTimeout":
        sim_log_msg(f"[{state.sim_cycle_count}] ConnectionTimeout — Enter + double Back")
        update_sim_status("Connection Timeout - backing out")
        _send_window("{Enter}")
        time.sleep(0.1)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        state.jl = 0
        state.sm = 0

    elif s == "ServerSelected":
        if not state.sim_initial_search_done and not state.use_last:
            sim_log_msg(f"[{state.sim_cycle_count}] ServerSelected but initial search not done — searching first")
            update_sim_status("Server Selected - searching first")
            _click_window(_off("server_search_offset_x"), _off("server_search_offset_y"))
            time.sleep(0.1)
            # Ctrl+A doesn't work via PostMessage — modifier state not set
            for _ in range(20):
                _send_window("{BackSpace}")
            time.sleep(0.1)
            _send_window_text(_server_number())
            time.sleep(0.2)
            _click_window(_off("click_session_offset_x"), _off("click_session_offset_y"))
            state.sim_initial_search_done = True
            return
        sim_log_msg(f"[{state.sim_cycle_count}] ServerSelected — clicking Join")
        update_sim_status("Server Selected - joining")
        _click_window(_off("server_join_offset_x"), _off("server_join_offset_y"))

    elif s == "NoSessions":
        state.nosessions += 1
        update_sim_status(f"No Sessions ({state.nosessions}/50)")
        if state.nosessions % 25 == 0:
            sim_log_msg(f"[{state.sim_cycle_count}] NoSessions — count={state.nosessions}")
        if state.nosessions > 50:
            sim_log_msg(f"[{state.sim_cycle_count}] NoSessions — refreshing")
            _click_window(_off("refresh_offset_x"), _off("refresh_offset_y"))
            state.nosessions = 0

    elif s == "WaitingToJoin":
        state.wm += 1
        update_sim_status(f"Waiting To Join ({state.wm}/180)")
        if state.wm % 30 == 0:
            sim_log_msg(f"[{state.sim_cycle_count}] WaitingToJoin — WM={state.wm}/180")
        if state.wm >= 180:
            sim_log_msg(f"[{state.sim_cycle_count}] WaitingToJoin — timeout, backing out")
            _click_window(_off("back_offset_x"), _off("back_offset_y"))
            state.wm = 0
        time.sleep(0.5)

    elif s == "ServerBrowser":
        state.sm += 1
        update_sim_status(f"Server Browser - waiting ({state.sm}/40)")
        if state.sm >= 40 or not state.sim_initial_search_done:
            state.sm = 0
            if state.use_last:
                state.jl += 1
                sim_log_msg(f"[{state.sim_cycle_count}] ServerBrowser — JoinLast ({state.jl}/40)")
                update_sim_status(f"Server Browser - Join Last ({state.jl}/40)")
                if state.jl >= 40:
                    sim_log_msg(f"[{state.sim_cycle_count}] ServerBrowser — JoinLast failed 40 times, backing out")
                    _click_window(_off("back_offset_x"), _off("back_offset_y"))
                    time.sleep(0.5)
                    state.jl = 0
                else:
                    _click_window(_off("join_last_offset_x"), _off("join_last_offset_y"))
                    time.sleep(0.5)
                state.sim_initial_search_done = True
            else:
                sim_log_msg(f"[{state.sim_cycle_count}] ServerBrowser — search + click session")
                update_sim_status("Server Browser - searching")
                _click_window(_off("server_search_offset_x"), _off("server_search_offset_y"))
                time.sleep(0.1)
                # Ctrl+A doesn't work via PostMessage — modifier state not set
                for _ in range(20):
                    _send_window("{BackSpace}")
                time.sleep(0.1)
                _send_window_text(_server_number())
                time.sleep(0.2)
                _click_window(_off("click_session_offset_x"), _off("click_session_offset_y"))
                state.sim_initial_search_done = True

    elif s == "ModMenu":
        sim_log_msg(f"[{state.sim_cycle_count}] ModMenu — clicking join")
        update_sim_status("Mod Menu - clicking join")
        _click_window(_off("mod_join_offset_x"), _off("mod_join_offset_y"))

    elif s == "ContentFailed":
        sim_log_msg(f"[{state.sim_cycle_count}] ContentFailed — Esc")
        update_sim_status("Content Failed - escaping")
        _send_window("{Escape}")
        time.sleep(2.0)

    elif s == "MainMenu":
        sim_log_msg(f"[{state.sim_cycle_count}] MainMenu — Enter + Back")
        update_sim_status("Main Menu - navigating")
        _handle_main_menu()

    elif s == "MiddleMenu":
        sim_log_msg(f"[{state.sim_cycle_count}] MiddleMenu — clicking JoinGame")
        update_sim_status("Middle Menu - joining")
        _click_window(_off("join_game_offset_x"), _off("join_game_offset_y"))
        time.sleep(0.25)

    else:
        hwnd = _game_hwnd()
        if hwnd:
            gx, gy, _, _ = win_get_pos(hwnd)
            if gx == 0 and gy == 0:
                state.incounter += 1
                update_sim_status(f"Maybe In Server: {state.incounter}/50")
                if state.incounter % 25 == 0:
                    sim_log_msg(f"[{state.sim_cycle_count}] Unknown state — maybe in? {state.incounter}/50")
                if state.incounter >= 50:
                    _sim_success()
            else:
                state.incounter = 0


def sim_loop_b():
    s = check_state_b()

    if s == state.stuck_state and s != "":
        state.stuck_count += 1
    else:
        state.stuck_state = s
        state.stuck_count = 0

    if state.stuck_count >= 150 and s != "":
        sim_log_msg(f"[{state.sim_cycle_count}] B STUCK RECOVERY — state '{s}' repeated {state.stuck_count} times, clicking Back")
        update_sim_status(f"Stuck in {s} — recovering")
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        state.stuck_count = 0
        state.nosessions = 0
        return

    if s == "ServerFull":
        hwnd = _game_hwnd()
        if hwnd:
            gx, gy, _, _ = win_get_pos(hwnd)
            if gx == 0 and gy == 0:
                win_move(hwnd, 1, 0)
                state.incounter = 0
        sim_log_msg(f"[{state.sim_cycle_count}] B ServerFull — Enter + Back")
        update_sim_status("Server Full")
        _send_window("{Enter}")
        time.sleep(0.1)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))

    elif s == "ConnectionTimeout":
        sim_log_msg(f"[{state.sim_cycle_count}] B ConnectionTimeout — Enter + double Back")
        update_sim_status("Connection Timeout")
        _send_window("{Enter}")
        time.sleep(0.1)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))
        time.sleep(0.5)
        _click_window(_off("back_offset_x"), _off("back_offset_y"))

    elif s == "ServerSelected":
        if not state.sim_initial_search_done and not state.use_last:
            sim_log_msg(f"[{state.sim_cycle_count}] B ServerSelected but initial search not done — searching first")
            update_sim_status("Server Selected - searching first")
            _click_window(_off("server_search_offset_x"), _off("server_search_offset_y"))
            time.sleep(0.1)
            # Ctrl+A doesn't work via PostMessage — modifier state not set
            for _ in range(20):
                _send_window("{BackSpace}")
            time.sleep(0.1)
            _send_window_text(_server_number())
            time.sleep(0.2)
            _click_window(_off("click_session_b_offset_x"), _off("click_session_b_offset_y"))
            state.sim_initial_search_done = True
            return
        sim_log_msg(f"[{state.sim_cycle_count}] B ServerSelected — clicking Join")
        update_sim_status("Server Selected")
        _click_window(_off("server_join_offset_x"), _off("server_join_offset_y"))

    elif s == "ServerBrowser":
        sim_log_msg(f"[{state.sim_cycle_count}] B ServerBrowser — searching")
        if not state.use_last:
            update_sim_status("Server Browser - searching")
            _click_window(_off("server_search_offset_x"), _off("server_search_offset_y"))
            time.sleep(0.1)
            # Ctrl+A doesn't work via PostMessage — modifier state not set
            for _ in range(20):
                _send_window("{BackSpace}")
            time.sleep(0.1)
            _send_window_text(_server_number())
            time.sleep(0.2)
            _click_window(_off("click_session_b_offset_x"), _off("click_session_b_offset_y"))
            state.sim_initial_search_done = True
        else:
            update_sim_status("Server Browser - Join Last")
            _click_window(_off("join_last_offset_x"), _off("join_last_offset_y"))
            state.sim_initial_search_done = True

    elif s == "ModMenu":
        sim_log_msg(f"[{state.sim_cycle_count}] B ModMenu — clicking join")
        update_sim_status("Mod Menu")
        _click_window(_off("mod_join_offset_x"), _off("mod_join_offset_y"))

    elif s == "MainMenu":
        sim_log_msg(f"[{state.sim_cycle_count}] B MainMenu — Enter + Back")
        update_sim_status("Main Menu - navigating")
        _handle_main_menu()

    elif s == "MiddleMenu":
        sim_log_msg(f"[{state.sim_cycle_count}] B MiddleMenu — clicking JoinGame")
        update_sim_status("Middle Menu")
        _click_window(_off("join_game_offset_x"), _off("join_game_offset_y"))
        time.sleep(0.25)

    elif s == "NoSessions":
        state.nosessions += 1
        update_sim_status(f"No Sessions ({state.nosessions}/50)")
        if state.nosessions <= 50:
            return
        sim_log_msg(f"[{state.sim_cycle_count}] B NoSessions — refreshing")
        _click_window(_off("refresh_offset_x"), _off("refresh_offset_y"))
        state.nosessions = 0

    else:
        hwnd = _game_hwnd()
        if hwnd:
            gx, gy, _, _ = win_get_pos(hwnd)
            if gx == 0 and gy == 0:
                state.incounter += 1
                update_sim_status(f"Maybe In Server: {state.incounter}/50")
                if state.incounter >= 50:
                    _sim_success()
            else:
                state.incounter = 0


def _sim_success():
    sim_log_msg(f"[{state.sim_cycle_count}] IN SERVER — success after {state.sim_cycle_count} cycles")
    timers.stop_timer(TIMER_NAME)
    state.auto_sim_check = False
    state.jl = 0
    state.sim_cycle_status = "Idle"
    _tooltip(None)

    _update_gui_status("")
    _reset_gui_button()

    _joinsim_anim("anim_stop")

    state.gui_visible = False
    _minimize_gui()

    hwnd = _game_hwnd()
    if hwnd:
        import sys
        if sys.platform == "win32":
            import ctypes as _ct
            _ct.windll.user32.SetWindowPos(
                hwnd, 0, 0, 0, 0, 0,
                0x0001 | 0x0004,
            )
        state._sim_input_hwnd = 0
        win_activate(hwnd)

    try:
        _taskbar_restore()
    except Exception:
        pass

    try:
        from util.ntfy import ntfy_push
        ntfy_push("max", f"You are in server {_server_number()}", key=state.ntfy_key)
    except Exception:
        pass


def _reset_gui_button():
    try:
        root = state.root
        js = getattr(state, "_tab_joinsim", None)
        if root and js:
            root.after(0, lambda: js.start_btn.configure(text="Start"))
    except Exception:
        pass


def _minimize_gui():
    try:
        root = state.root
        if root:
            root.after(0, root.iconify)
    except Exception:
        pass


_taskbar_saved_state = None


def _taskbar_appbar_msg(msg, lp=0):
    import ctypes
    import ctypes.wintypes as wt

    class APPBARDATA(ctypes.Structure):
        _fields_ = [
            ("cbSize", wt.DWORD),
            ("hWnd", wt.HWND),
            ("uCallbackMessage", wt.UINT),
            ("uEdge", wt.UINT),
            ("rc", wt.RECT),
            ("lParam", ctypes.c_long),
        ]

    tray_hwnd = ctypes.windll.user32.FindWindowW("Shell_TrayWnd", None)
    if not tray_hwnd:
        return 0
    abd = APPBARDATA()
    abd.cbSize = ctypes.sizeof(APPBARDATA)
    abd.hWnd = tray_hwnd
    abd.lParam = lp
    return ctypes.windll.shell32.SHAppBarMessage(msg, ctypes.byref(abd))


def _taskbar_auto_hide():
    global _taskbar_saved_state
    import sys
    if sys.platform != "win32":
        return

    try:
        cur = _taskbar_appbar_msg(0x00000004)  # ABM_GETSTATE
        if not (cur & 0x01):
            _taskbar_saved_state = cur
            _taskbar_appbar_msg(0x0000000A, cur | 0x01)  # ABM_SETSTATE
    except Exception:
        pass


def _taskbar_restore():
    global _taskbar_saved_state
    import sys
    if sys.platform != "win32":
        return

    try:
        if _taskbar_saved_state is not None:
            _taskbar_appbar_msg(0x0000000A, _taskbar_saved_state)  # ABM_SETSTATE
            _taskbar_saved_state = None
    except Exception:
        pass


def auto_sim_button_toggle():
    state.auto_sim_check = not getattr(state, "auto_sim_check", False)

    if state.auto_sim_check:
        state.mm = 0
        state.rm = 0
        state.sm = 0
        state.wm = 0
        state.jl = 0
        state.nosessions = 0
        state.incounter = 0
        state.sim_cycle_count = 0
        state.search_done = False
        state.sim_initial_search_done = False
        state.stuck_state = ""
        state.stuck_count = 0
        state.sim_log = []

        hwnd = _game_hwnd()
        if hwnd:
            gx, gy, gw, gh = win_get_pos(hwnd)
            sim_log_msg(f"=== SIM STARTED (SIM {'A' if state.sim_mode == 1 else 'B'}) ===")
            sim_log_msg(f"Server: {_server_number()}  UseLast: {state.use_last}  Mods: {state.mods_enabled}")
            sim_log_msg(f"GameWindow: {gw}x{gh} at ({gx},{gy})")

            main_class = _get_class_name(hwnd)
            sim_log_msg(f"MainHwnd: {hwnd} class='{main_class}'")
            input_hwnd = find_input_child(hwnd)
            if input_hwnd != hwnd:
                child_class = _get_class_name(input_hwnd)
                sim_log_msg(f"InputHwnd: {input_hwnd} class='{child_class}' (child)")
            else:
                sim_log_msg(f"InputHwnd: {hwnd} (no child — using main)")
            state._sim_input_hwnd = input_hwnd

            if state.sim_mode == 1:
                sim_log_msg(f"Tolerance: {state.col_tol}")

            # Offset window to (1,0) so game is slightly off-origin
            import sys
            if sys.platform == "win32":
                import ctypes as _ct
                _ct.windll.user32.SetWindowPos(
                    hwnd, 0, 1, 0, 0, 0,
                    0x0001 | 0x0004,
                )

        _taskbar_auto_hide()
        state.sim_cycle_status = "Running"
        timers.set_timer(TIMER_NAME, sim_loop, SIM_INTERVAL_MS)
        sim_loop()

        _joinsim_anim("anim_start")

        if state.toolbox_enabled:
            _tooltip(f"Simming for: {_server_number()} | Starting...")
    else:
        hwnd = _game_hwnd()
        if hwnd:
            import sys
            if sys.platform == "win32":
                import ctypes as _ct
                _ct.windll.user32.SetWindowPos(
                    hwnd, 0, 0, 0, 0, 0,
                    0x0001 | 0x0004,
                )
            state._sim_input_hwnd = 0

        _taskbar_restore()
        timers.stop_timer(TIMER_NAME)
        state.jl = 0
        state.sim_cycle_status = "Idle"
        _update_gui_status("")

        _joinsim_anim("anim_stop")

        if state.toolbox_enabled:
            _tooltip("Sim Stopped")

            def _clear():
                _tooltip(None)
            timers.set_timer("sim_stop_tip", _clear, -2000)
