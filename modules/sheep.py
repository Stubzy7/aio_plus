
import threading
import time
import logging

from core.state import state
from core.scaling import scale_x, scale_y
from input.pixel import px_get, pixel_search, wait_for_pixel
from input.mouse import click, mouse_move, mouse_down, mouse_up, set_cursor_pos
from input.keyboard import send, key_press, control_send
from input.window import win_exist, win_activate, get_foreground_window, find_window
from util.color import is_bright

log = logging.getLogger(__name__)


def _tooltip(text: str | None = None):
    try:
        from gui.tooltip import show_tooltip, hide_tooltip
        if text:
            show_tooltip(text)
        else:
            hide_tooltip()
    except Exception:
        if text:
            log.info("tooltip: %s", text)

_sheep_thread: threading.Thread | None = None
_auto_lvl_thread: threading.Thread | None = None


def sheep_register_hotkeys(hk_manager):
    key_toggle = state.sheep_toggle_key
    key_overcap = state.sheep_overcap_key
    key_auto_lvl = state.sheep_auto_lvl_key

    if key_toggle:
        hk_manager.register(key_toggle, _hotkey_toggle, suppress=True)
    if key_overcap:
        hk_manager.register(key_overcap, _hotkey_overcap, suppress=True)
    if key_auto_lvl:
        hk_manager.register(key_auto_lvl, _hotkey_auto_lvl, suppress=True)


def sheep_unregister_hotkeys(hk_manager):
    if state.sheep_toggle_key:
        hk_manager.unregister(state.sheep_toggle_key, _hotkey_toggle)
    if state.sheep_overcap_key:
        hk_manager.unregister(state.sheep_overcap_key, _hotkey_overcap)
    if state.sheep_auto_lvl_key:
        hk_manager.unregister(state.sheep_auto_lvl_key, _hotkey_auto_lvl)


def _is_ark_active() -> bool:
    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return False
    return get_foreground_window() == hwnd


def _hotkey_toggle():
    if not state.sheep_tab_active or not _is_ark_active():
        send("{" + state.sheep_toggle_key + "}")
        return
    sheep_toggle_script()


def _hotkey_overcap():
    if not state.sheep_tab_active or not _is_ark_active():
        send("{" + state.sheep_overcap_key + "}")
        return
    sheep_toggle_overcap()


def _hotkey_auto_lvl():
    ark_active = _is_ark_active()
    if not ark_active or (not state.sheep_tab_active and not state.sheep_mode_active):
        send("{" + state.sheep_auto_lvl_key + "}")
        return
    sheep_toggle_auto_lvl()


def sheep_toggle_script():
    if state.sheep_running:
        sheep_stop_script()
    else:
        if not state.sheep_inventory_key:
            from core.config import read_ini
            saved_inv = read_ini("Popcorn", "InvKey", "")
            if not saved_inv:
                log.warning("Sheep: inventory key not set — showing prompt")
                try:
                    tab_pc = getattr(state, "_tab_popcorn", None)
                    if tab_pc and state.root:
                        state.root.after(0, tab_pc._show_set_keys_prompt)
                    else:
                        _tooltip(" Sheep: inventory key not set!\n Open Popcorn tab → Set Keys")
                except Exception:
                    _tooltip(" Sheep: inventory key not set!\n Open Popcorn tab → Set Keys")
                return
            state.sheep_inventory_key = saved_inv
        state.sheep_running = True
        state.gui_visible = False
        if state.main_gui:
            state.main_gui.hide()
        log.info("Sheep STARTED")
        hwnd = win_exist(state.ark_window)
        if hwnd:
            win_activate(hwnd)
        sheep_show_status_gui()
        _tooltip(
            f" \U0001f411 SheepV2 Running\n"
            f" {state.sheep_toggle_key.upper()} = Pause  |  "
            f"{state.sheep_overcap_key.upper()} = Overcap"
        )
        _launch_sheep_thread()


def sheep_stop_script():
    state.sheep_running = False
    mouse_up("left")
    time.sleep(0.2)
    sheep_drop_all(is_final_drop=True)
    sheep_hide_status_gui()
    _tooltip(" Sheep PAUSED")
    state.gui_visible = True
    if state.main_gui:
        state.main_gui.show_passive()
    hwnd = win_exist(state.ark_window)
    if hwnd:
        win_activate(hwnd)
    log.info("Sheep PAUSED")


def sheep_toggle_overcap():
    state.overcapping_toggle = not state.overcapping_toggle
    status = "ON" if state.overcapping_toggle else "OFF"
    _tooltip(f" Overcapping: {status}")
    log.info("Overcapping: %s", status)


def sheep_toggle_auto_lvl():
    state.sheep_auto_lvl_active = not state.sheep_auto_lvl_active

    if state.sheep_auto_lvl_active:
        state.sheep_mode_active = True
        state.gui_visible = False
        if state.main_gui:
            state.main_gui.hide()
        hwnd = win_exist(state.ark_window)
        if hwnd:
            win_activate(hwnd)
            time.sleep(0.1)
        if state.sheep_level_action_key != state.sheep_auto_lvl_key:
            try:
                hk = state._hotkey_mgr
                hk.register(state.sheep_level_action_key, sheep_do_auto_level, suppress=True)
            except Exception:
                pass
        sheep_show_auto_lvl_gui()
        _tooltip(
            f" Sheep Auto LvL ON\n"
            f" [{state.sheep_auto_lvl_key.upper()}] = Toggle"
        )
        log.info("Sheep Auto LvL ON — F to level, %s to toggle off",
                 state.sheep_auto_lvl_key)
    else:
        if state.sheep_level_action_key != state.sheep_auto_lvl_key:
            try:
                hk = state._hotkey_mgr
                hk.unregister(state.sheep_level_action_key, sheep_do_auto_level)
            except Exception:
                pass
        sheep_hide_auto_lvl_gui()
        state.sheep_mode_active = False
        _tooltip(None)
        state.gui_visible = True
        if state.main_gui:
            state.main_gui.show_passive()
        hwnd = win_exist(state.ark_window)
        if hwnd:
            win_activate(hwnd)
        log.info("Sheep Auto LvL OFF")


def sheep_stop_auto_lvl():
    if state.sheep_level_action_key != state.sheep_auto_lvl_key:
        try:
            hk = state._hotkey_mgr
            hk.unregister(state.sheep_level_action_key, sheep_do_auto_level)
        except Exception:
            pass
    sheep_hide_auto_lvl_gui()
    state.sheep_auto_lvl_active = False
    state.sheep_mode_active = False
    _tooltip(None)
    state.gui_visible = True
    if state.main_gui:
        state.main_gui.show_passive()
    hwnd = win_exist(state.ark_window)
    if hwnd:
        win_activate(hwnd)
    log.info("Sheep Auto LvL stopped")


def _launch_sheep_thread():
    global _sheep_thread
    if _sheep_thread is not None and _sheep_thread.is_alive():
        return
    _sheep_thread = threading.Thread(target=sheep_start_loop, daemon=True,
                                     name="sheep-loop")
    _sheep_thread.start()


def sheep_start_loop():
    hwnd = win_exist(state.ark_window)
    if hwnd:
        win_activate(hwnd)
    time.sleep(0.15)

    while state.sheep_running:
        mouse_down("left")

        if state.overcapping_toggle:
            check_x = state.overcap_box_x
            check_y = state.overcap_box_y
        else:
            check_x = state.black_box_x
            check_y = state.black_box_y

        color = px_get(check_x, check_y)
        r = (color >> 16) & 0xFF
        g = (color >> 8) & 0xFF
        b = color & 0xFF
        is_black = r < 15 and g < 15 and b < 15

        if is_black:
            mouse_up("left")
            time.sleep(0.5)
            if not state.sheep_running:
                return

            sheep_drop_all()

            while state.sheep_running:
                time.sleep(0.2)
                c = px_get(check_x, check_y)
                cr = (c >> 16) & 0xFF
                cg = (c >> 8) & 0xFF
                cb = c & 0xFF
                if not (cr < 15 and cg < 15 and cb < 15):
                    break

            if not state.sheep_running:
                mouse_up("left")
                return
            time.sleep(0.5)

        time.sleep(0.05)

    mouse_up("left")


def sheep_wait_for_inventory(is_final_drop: bool = False,
                             max_iterations: int = 100) -> bool:
    for i in range(max_iterations):
        if not state.sheep_running and not is_final_drop:
            return False
        color = px_get(state.invy_detect_x, state.invy_detect_y)
        r = (color >> 16) & 0xFF
        g = (color >> 8) & 0xFF
        b = color & 0xFF
        if r > 200 and g > 200 and b > 200:
            log.info("SheepWaitInv: detected at tick %d color=0x%06X", i, color)
            return True
        time.sleep(0.05)
    log.warning("SheepWaitInv: timeout after %d ticks", max_iterations)
    return False


def sheep_drop_all(is_final_drop: bool = False):
    if not state.sheep_running and not is_final_drop:
        return

    inv_key = state.sheep_inventory_key
    log.info("SheepDropAll: opening inventory with key '%s'", inv_key)

    key_press(inv_key)

    if not sheep_wait_for_inventory(is_final_drop):
        log.warning("SheepDropAll: inventory did not open — aborting")
        return
    log.info("SheepDropAll: inventory detected, clicking search bar at (%s,%s)",
             state.invy_search_x, state.invy_search_y)

    _sheep_click_inventory_search()
    time.sleep(0.3)

    if not state.sheep_running and not is_final_drop:
        return

    log.info("SheepDropAll: typing 't' into search bar")
    key_press("t")
    time.sleep(0.2)

    log.info("SheepDropAll: clicking Drop All at (%s,%s)",
             state.drop_all_x, state.drop_all_y)
    _sheep_click_drop_all()
    time.sleep(0.15)

    key_press(inv_key)
    time.sleep(0.15)
    log.info("SheepDropAll: done")


def _sheep_click_drop_all():
    mouse_move(state.drop_all_x, state.drop_all_y)
    click()


def _sheep_click_inventory_search():
    mouse_move(state.invy_search_x, state.invy_search_y)
    click()


def sheep_do_auto_level():
    if not state.sheep_auto_lvl_active or not _is_ark_active():
        send("{" + state.sheep_level_action_key + "}")
        return

    hwnd = win_exist(state.ark_window)
    if hwnd:
        control_send(hwnd, state.sheep_level_action_key)

    pix_x = state.sheep_lvl_pixel_x
    pix_y = state.sheep_lvl_pixel_y
    for wait_count in range(30):
        result = pixel_search(pix_x, pix_y, pix_x + 1, pix_y + 1,
                              0xFFFFFF, tolerance=0)
        if result is not None:
            break
        time.sleep(0.05)
    else:
        return

    mouse_move(state.sheep_lvl_click_x, state.sheep_lvl_click_y)
    click(count=70)

    if hwnd:
        control_send(hwnd, "{Esc}")


def sheep_show_auto_lvl_gui():
    root = state.root
    if root is None:
        return

    def _build():
        import tkinter as tk
        if state.sheep_auto_lvl_gui is not None:
            try:
                state.sheep_auto_lvl_gui.destroy()
            except Exception:
                pass
            state.sheep_auto_lvl_gui = None

        win = tk.Toplevel(root)
        win.title("SheepAutoLvL")
        win.overrideredirect(True)
        win.attributes("-topmost", True)
        win.configure(bg="#1A1A1A")

        tk.Label(win, text="Auto LvL Running", font=("Segoe UI", 10, "bold"),
                 fg="#FF4444", bg="#1A1A1A").pack(anchor="w", padx=8, pady=(8, 0))
        tk.Label(win, text=f"Press {state.sheep_level_action_key.upper()}",
                 font=("Segoe UI", 9), fg="#00FF00", bg="#1A1A1A").pack(anchor="w", padx=8, pady=(6, 0))
        tk.Label(win, text=f"{state.sheep_auto_lvl_key} = Toggle",
                 font=("Segoe UI", 8, "italic"), fg="#FF4444", bg="#1A1A1A").pack(anchor="w", padx=8, pady=(5, 0))
        tk.Label(win, text=f"Res: {state.screen_width}x{state.screen_height}",
                 font=("Segoe UI", 8), fg="#888888", bg="#1A1A1A").pack(anchor="w", padx=8, pady=(5, 8))

        win.update_idletasks()
        gui_h = win.winfo_reqheight()

        if state.sheep_status_bottom_anchor == 0:
            state.sheep_status_bottom_anchor = 364 + gui_h
        new_y = max(0, state.sheep_status_bottom_anchor - gui_h + 65)

        win.geometry(f"+0+{new_y}")
        state.sheep_auto_lvl_gui = win

    root.after(0, _build)


def sheep_hide_auto_lvl_gui():
    root = state.root

    def _destroy():
        if state.sheep_auto_lvl_gui is not None:
            try:
                state.sheep_auto_lvl_gui.destroy()
            except Exception:
                pass
            state.sheep_auto_lvl_gui = None

    if root:
        root.after(0, _destroy)
    else:
        _destroy()


def sheep_show_status_gui():
    root = state.root
    if root is None:
        return

    def _build():
        import tkinter as tk
        if state.sheep_status_gui is not None:
            try:
                state.sheep_status_gui.destroy()
            except Exception:
                pass
            state.sheep_status_gui = None

        win = tk.Toplevel(root)
        win.title("SheepStatus")
        win.overrideredirect(True)
        win.attributes("-topmost", True)
        win.configure(bg="#1A1A1A")

        tk.Label(win, text="\U0001f411 SheepV2 Running", font=("Segoe UI", 10, "bold"),
                 fg="#FF4444", bg="#1A1A1A").pack(anchor="w", padx=8, pady=(8, 0))
        tk.Label(win, text=f"Start\\Pause: {state.sheep_toggle_key}",
                 font=("Segoe UI", 9), fg="#00FF00", bg="#1A1A1A").pack(anchor="w", padx=8, pady=(6, 0))
        tk.Label(win, text=f"Res: {state.screen_width}x{state.screen_height}",
                 font=("Segoe UI", 8), fg="#888888", bg="#1A1A1A").pack(anchor="w", padx=8, pady=(5, 8))

        win.update_idletasks()
        gui_h = win.winfo_reqheight()

        if state.sheep_status_bottom_anchor == 0:
            state.sheep_status_bottom_anchor = 364 + gui_h
        new_y = max(0, state.sheep_status_bottom_anchor - gui_h + 65)

        win.geometry(f"+0+{new_y}")
        state.sheep_status_gui = win

    root.after(0, _build)


def sheep_hide_status_gui():
    root = state.root

    def _destroy():
        if state.sheep_status_gui is not None:
            try:
                state.sheep_status_gui.destroy()
            except Exception:
                pass
            state.sheep_status_gui = None

    if root:
        root.after(0, _destroy)
    else:
        _destroy()


def sheep_auto_lvl_f_pressed():
    if not state.sheep_auto_lvl_active or not _is_ark_active():
        return

    pix_x = state.sheep_lvl_pixel_x
    pix_y = state.sheep_lvl_pixel_y

    for _ in range(30):
        result = pixel_search(pix_x, pix_y, pix_x + 1, pix_y + 1,
                              0xFFFFFF, tolerance=0)
        if result is not None:
            break
        time.sleep(0.05)
    else:
        return

    mouse_move(state.sheep_lvl_click_x, state.sheep_lvl_click_y)
    click(count=70)

    hwnd = win_exist(state.ark_window)
    if hwnd:
        control_send(hwnd, "{Esc}")
