
import logging

from core.state import state
from core.timers import timers
from input.window import win_exist, control_click

log = logging.getLogger(__name__)

TIMER_NAME = "mammoth_drum_tick"
DRUM_INTERVAL_MS = 1840


# ---------------------------------------------------------------------------
#  Tooltip helper
# ---------------------------------------------------------------------------

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
    """Attempt to restore the OB character tooltip if one was active."""
    try:
        from modules.ob_upload import ob_char_restore_tooltip
        ob_char_restore_tooltip()
    except Exception:
        pass


# ---------------------------------------------------------------------------
#  Start / Stop / Toggle
# ---------------------------------------------------------------------------

def toggle_mammoth_script():
    """Toggle the mammoth drums on or off (F8 handler)."""
    if state.run_mammoth_script:
        stop_mammoth_script()
    else:
        start_mammoth_script()


def start_mammoth_script():
    """Start the mammoth drum automation.

    Activates the ARK window, fires an initial click, then starts a
    recurring 1840 ms timer.
    """
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
    """Stop the mammoth drum automation and clear the tooltip."""
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
    """Timer callback — send a click to the ARK window.

    If the mammoth script has been stopped externally or the ARK window
    no longer exists, stops itself cleanly.
    """
    if not state.run_mammoth_script:
        stop_mammoth_script()
        return

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        stop_mammoth_script()
        return

    control_click(hwnd, 1, 1)
