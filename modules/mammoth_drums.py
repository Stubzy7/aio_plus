
import logging

from core.state import state
from core.timers import timers
from input.window import win_exist, control_click

log = logging.getLogger(__name__)

TIMER_NAME = "mammoth_drum_tick"
DRUM_INTERVAL_MS = 1840


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


def _restore_tooltip():
    try:
        from modules.ob_upload import ob_char_restore_tooltip
        ob_char_restore_tooltip()
    except Exception:
        pass


def toggle_mammoth_script():
    if state.run_mammoth_script:
        stop_mammoth_script()
    else:
        start_mammoth_script()


def start_mammoth_script():
    state.run_mammoth_script = True
    _tooltip(" BG Mammoth Drums RUNNING\nF8 = Stop")

    state.gui_visible = False
    root = getattr(state, "root", None)
    if root:
        root.after(0, root.withdraw)

    hwnd = win_exist(state.ark_window)
    if hwnd:
        control_click(hwnd, 1, 1)

    timers.set_timer(TIMER_NAME, mammoth_drum_tick, DRUM_INTERVAL_MS)
    log.info("Mammoth drums started (every %d ms)", DRUM_INTERVAL_MS)


def stop_mammoth_script():
    state.run_mammoth_script = False
    timers.stop_timer(TIMER_NAME)
    _tooltip(None)
    _restore_tooltip()

    state.gui_visible = True
    root = getattr(state, "root", None)
    if root:
        root.after(0, root.deiconify)

    log.info("Mammoth drums stopped")


def mammoth_drum_tick():
    if not state.run_mammoth_script:
        stop_mammoth_script()
        return

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        stop_mammoth_script()
        return

    control_click(hwnd, 1, 1)
