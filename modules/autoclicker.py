
import logging

from core.state import state
from core.timers import timers
from input.window import win_exist, control_click

log = logging.getLogger(__name__)

TIMER_NAME = "autoclick_loop"


# ---------------------------------------------------------------------------
#  Tooltip helper (thin shim — real implementation lives in the GUI layer)
# ---------------------------------------------------------------------------

def _tooltip(text: str | None = None):
    """Show/hide a tooltip. Imported lazily to avoid circular deps."""
    try:
        from gui.tooltip import show_tooltip, hide_tooltip
        if text:
            show_tooltip(text)
        else:
            hide_tooltip()
    except Exception:
        if text:
            log.info("tooltip: %s", text)


def _update_tooltip():
    """Display the current autoclick status tooltip."""
    _tooltip(
        f" AUTOCLICK ON  (Interval: {state.autoclick_interval}ms)\n"
        f"[ = Slower   ] = Faster\nF9 = Stop"
    )


# ---------------------------------------------------------------------------
#  Core functions
# ---------------------------------------------------------------------------

def toggle_autoclicker():
    """Toggle the autoclicker on/off (F9 handler).

    When starting:
      - Verifies ARK window exists
      - Hides the GUI, activates ARK
      - Starts the autoclick timer at ``state.autoclick_interval``
      - Registers [ / ] hotkeys for speed adjustment
    When stopping:
      - Stops the timer
      - Unregisters speed hotkeys
      - Shows a brief "off" tooltip
    """
    state.last_debug_context = "autoclick"
    state.autoclicking = not state.autoclicking

    if state.autoclicking:
        hwnd = win_exist(state.ark_window)
        if not hwnd:
            log.warning("ARK window not found — aborting autoclicker")
            state.autoclicking = False
            return

        # Stop popcorn if running
        if state.pc_running:
            state.pc_early_exit = True
            state.pc_f10_step = 0
            state.pc_mode = 0
            state.pc_running = False

        state.gui_visible = False
        root = getattr(state, "root", None)
        if root:
            root.after(0, root.withdraw)
        _update_tooltip()

        timers.set_timer(TIMER_NAME, autoclick_loop, state.autoclick_interval)

        # Register speed-adjust hotkeys
        try:
            from core.hotkeys import HotkeyManager
            hk: HotkeyManager = state._hotkey_mgr  # type: ignore[attr-defined]
            hk.register("[", autoclick_slower, suppress=True)
            hk.register("]", autoclick_faster, suppress=True)
        except Exception:
            pass

        log.info("Autoclicker started at %d ms", state.autoclick_interval)
    else:
        timers.stop_timer(TIMER_NAME)

        try:
            hk = state._hotkey_mgr  # type: ignore[attr-defined]
            hk.unregister("[", autoclick_slower)
            hk.unregister("]", autoclick_faster)
        except Exception:
            pass

        _tooltip(" AUTOCLICK Off")

        def _clear():
            if not state.autoclicking:
                _tooltip(None)
        timers.set_timer("autoclick_off_tip", _clear, -1500)

        state.gui_visible = True
        root = getattr(state, "root", None)
        if root:
            root.after(0, root.deiconify)
        log.info("Autoclicker stopped")


def autoclick_loop():
    """Timer callback — sends a left-click to the ARK window.

    If the window disappears or autoclicking is toggled off externally,
    the callback silently returns.
    """
    if not state.autoclicking:
        return
    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    control_click(hwnd, 1, 1)


def autoclick_slower():
    """Increase the click interval by one step ([ key handler)."""
    state.autoclick_interval += state.autoclick_interval_step

    if state.autoclicking:
        # Restart timer at new interval
        timers.stop_timer(TIMER_NAME)
        timers.set_timer(TIMER_NAME, autoclick_loop, state.autoclick_interval)
        _update_tooltip()

    log.debug("Autoclicker slower: %d ms", state.autoclick_interval)


def autoclick_faster():
    """Decrease the click interval by one step (] key handler).

    Will not go below ``state.autoclick_min_interval``.
    """
    state.autoclick_interval = max(
        state.autoclick_min_interval,
        state.autoclick_interval - state.autoclick_interval_step,
    )

    if state.autoclicking:
        timers.stop_timer(TIMER_NAME)
        timers.set_timer(TIMER_NAME, autoclick_loop, state.autoclick_interval)
        _update_tooltip()

    log.debug("Autoclicker faster: %d ms", state.autoclick_interval)
