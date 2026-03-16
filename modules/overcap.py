
import time
import threading
import logging

from core.state import state
from input.keyboard import send
from input.window import win_exist, win_activate

log = logging.getLogger(__name__)

_timer_thread: threading.Thread | None = None
_stop_event = threading.Event()


def _tooltip(text: str | None = None):
    try:
        from gui.tooltip import show_tooltip, hide_tooltip
        if text:
            show_tooltip(text)
        else:
            hide_tooltip()
    except Exception:
        pass


def _tooltip_update(text: str):
    """Update existing tooltip text without recreating the window."""
    try:
        from gui.tooltip import update_tooltip
        update_tooltip(text)
    except Exception:
        pass


def _update_status(text: str):
    try:
        from gui.tab_joinsim import update_overcap_status
        update_overcap_status(text)
    except Exception:
        pass


# ---------------------------------------------------------------------------
#  Dedi duration lookup
# ---------------------------------------------------------------------------

def overcap_dedi_ms(n: int) -> int:
    """Return the total milliseconds required to overcap *n* dedis.

    Uses the pre-populated lookup table on ``state.overcap_dedi_table``.
    For values beyond the table it linearly extrapolates from the last
    two entries.
    """
    table = state.overcap_dedi_table
    if n in table:
        return table[n]
    last_known = 9
    second_last = 8
    ms_per_dedi = table[last_known] - table[second_last]
    return table[last_known] + ((n - last_known) * ms_per_dedi)


# ---------------------------------------------------------------------------
#  Loop internals
# ---------------------------------------------------------------------------

def _overcap_loop():
    """Background thread: spam 1-2-3 keys and manage countdown."""
    while not _stop_event.is_set():
        if not state.run_overcap_script:
            break

        send("{1}")
        time.sleep(0.010)
        send("{2}")
        time.sleep(0.010)
        send("{3}")
        time.sleep(0.010)

        # ── Timer check ─────────────────────────────────────────────
        _overcap_timer_check()

        # Pace: 20ms polling interval
        time.sleep(0.020)


def overcap_loop():
    """Single iteration of the overcap loop.

    In the Python port the background thread calls this implicitly; it
    is exposed here for symmetry / direct testing.
    """
    if not state.run_overcap_script:
        return
    time.sleep(0.010)
    send("{1}")
    time.sleep(0.010)
    send("{2}")
    time.sleep(0.010)
    send("{3}")


def _overcap_timer_check():
    """Check elapsed time vs. dedi target and auto-stop if done.

    Auto-stops when elapsed time reaches the dedi target.
    """
    if not state.run_overcap_script or state.overcap_dedi_target == 0:
        return

    elapsed = state.overcap_accum_ms + (
        (time.monotonic() * 1000) - state.overcap_start_tick
    )
    target = overcap_dedi_ms(state.overcap_dedi_target)
    remaining = max(0, target - elapsed)
    rem_sec = int(remaining) // 1000
    rem_ms = (int(remaining) % 1000) // 10

    # Live countdown — update Tab 1 label + tooltip text in-place
    _update_status(f"Overcapping {state.overcap_dedi_target} Dedis  {rem_sec}.{rem_ms:02d}s")
    _tooltip_update(
        f" Overcap RUNNING {state.overcap_dedi_target} dedi  ({rem_sec}.{rem_ms:02d}s left)\n"
        f"F2 = Pause  |  Q = Stop"
    )

    if elapsed >= target:
        dedi = state.overcap_dedi_target
        stop_overcap_script()
        _update_status(f"{dedi} Dedis done")
        _tooltip(f" Overcap done  {dedi} dedi complete!")
        from core.timers import timers
        timers.set_timer("oc_done_tip", lambda: (_tooltip(None), _update_status("")), -3000)
        log.info("Overcap done — %d dedis complete", dedi)


def overcap_timer_check():
    """Public alias for the timer check."""
    _overcap_timer_check()


# ---------------------------------------------------------------------------
#  Public start / stop / toggle
# ---------------------------------------------------------------------------

def start_overcap_script():
    """Begin sending 1-2-3 keys on a 50 ms timer.

    Starts the background thread sending 1-2-3 keys on a 50ms timer.
    """
    global _timer_thread
    _stop_event.clear()

    state.run_overcap_script = True
    state.overcap_accum_ms = 0
    state.overcap_start_tick = time.monotonic() * 1000

    # Read dedi target from the Tab 1 edit field
    try:
        js = getattr(state, "_tab_joinsim", None)
        if js:
            val = js.overcap_dedi_edit.get().strip()
            state.overcap_dedi_target = int(val) if val else 0
    except (ValueError, AttributeError):
        pass

    if state.overcap_dedi_target > 0:
        target_sec = overcap_dedi_ms(state.overcap_dedi_target) // 1000
        log.info(
            "Overcap RUNNING — %d dedi (%d.00s)",
            state.overcap_dedi_target, target_sec,
        )
        _update_status(f"Overcapping {state.overcap_dedi_target} Dedis  {target_sec}.00s")
        _tooltip(f" Overcap RUNNING {state.overcap_dedi_target} dedi ({target_sec}.00s)\n"
                 f"F2 = Pause  |  Q = Stop")
    else:
        log.info("Overcap RUNNING — free mode")
        _update_status("Overcapping...")
        _tooltip(" Overcap RUNNING — free mode\nF2 = Pause  |  Q = Stop")

    # Activate ARK window
    hwnd = win_exist(state.ark_window)
    if hwnd:
        win_activate(hwnd)

    _timer_thread = threading.Thread(target=_overcap_loop, daemon=True)
    _timer_thread.start()


def stop_overcap_script():
    """Stop the overcap key-spam loop.

    Signals the background thread to stop and waits for it.
    """
    global _timer_thread
    state.run_overcap_script = False
    _stop_event.set()

    if state.overcap_start_tick > 0:
        state.overcap_accum_ms += (
            (time.monotonic() * 1000) - state.overcap_start_tick
        )
    state.overcap_start_tick = 0

    if _timer_thread is not None and _timer_thread is not threading.current_thread():
        _timer_thread.join(timeout=2.0)
    _timer_thread = None

    _tooltip(None)
    _update_status("")
    log.info("Overcap stopped")


def toggle_overcap_script():
    """Start or stop overcap.

    Toggles between running and stopped states.
    """
    if state.run_overcap_script:
        stop_overcap_script()
    else:
        start_overcap_script()
