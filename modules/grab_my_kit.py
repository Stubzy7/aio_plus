
import logging
import time

from core.state import state
from input.pixel import pixel_search
from input.mouse import click
from input.keyboard import send
from input.window import win_exist, control_click

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


def _gmk_update_label(text: str):
    try:
        from gui.tab_joinsim import update_gmk_status
        update_gmk_status(text)
    except Exception:
        pass


def _restore_tooltip():
    try:
        from modules.ob_upload import ob_char_restore_tooltip
        ob_char_restore_tooltip()
    except Exception:
        pass


def _inv_open_white() -> bool:
    x = int(round(1495 * state.width_multiplier))
    y = int(round(226 * state.height_multiplier))
    result = pixel_search(x, y, x + 2, y + 2, 0xFFFFFF, tolerance=0)
    return result is not None


def _wait_inv_open(max_ticks: int = 375) -> bool:
    for _ in range(max_ticks):
        if _inv_open_white():
            return True
        time.sleep(0.016)
    return False


def gmk_toggle():
    if state.gmk_mode == "off":
        state.gmk_mode = "take"
    elif state.gmk_mode == "take":
        state.gmk_mode = "give"
    else:
        state.gmk_mode = "off"

    if state.gmk_mode != "off":
        if state.run_magic_f_script:
            state.run_magic_f_script = False
        if state.quick_feed_mode > 0:
            state.quick_feed_mode = 0
        if state.macro_playing:
            try:
                from modules.macro_system import macro_stop_play
                macro_stop_play()
            except Exception:
                state.macro_playing = False
        if state.pc_f10_step > 0 or state.pc_mode > 0:
            state.pc_f10_step = 0
            state.pc_mode = 0
            state.pc_running = False

        state.gui_visible = False
        root = getattr(state, "root", None)
        if root:
            root.after(0, root.withdraw)
        _tooltip(gmk_build_tooltip())
        _gmk_update_label(state.gmk_mode.capitalize())
        log.info("Grab My Kit: %s", state.gmk_mode.upper())
    else:
        _tooltip(" Grab My Kit: Off")
        _gmk_update_label("")

        def _clear():
            if state.gmk_mode == "off":
                _tooltip(None)
                _restore_tooltip()

        from core.timers import timers
        timers.set_timer("gmk_off_tip", _clear, -1500)
        log.info("Grab My Kit: OFF")


def gmk_build_tooltip() -> str:
    label = "TAKE" if state.gmk_mode == "take" else "GIVE"
    action = "F = Take All" if state.gmk_mode == "take" else "F = Give All"
    return f" Grab My Kit: {label}\n{action}  |  F12 = cycle  |  F1 = UI"


_gmk_busy = False


def gmk_f_pressed():
    global _gmk_busy
    if state.gmk_mode == "off" or _gmk_busy:
        return
    _gmk_busy = True
    try:
        _gmk_f_pressed_inner()
    finally:
        _gmk_busy = False


def _gmk_f_pressed_inner():
    if state.gmk_mode == "off":
        return

    if not _wait_inv_open(375):
        return

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return

    if state.gmk_mode == "take":
        btn_x = int(state.transfer_to_me_btn_x)
        btn_y = int(state.transfer_to_me_btn_y)
    else:
        btn_x = int(state.transfer_to_other_btn_x)
        btn_y = int(state.transfer_to_other_btn_y)

    control_click(hwnd, btn_x, btn_y)
    time.sleep(0.100)

    if _inv_open_white():
        send("{f}")

    time.sleep(0.100)

    if state.gmk_mode != "off":
        _tooltip(gmk_build_tooltip())
