
import logging
import time

from pal import system as _sys
from core.state import state
from core.timers import timers
from core.config import read_ini, read_ini_bool, write_ini
from input.pixel import pixel_search
from input.mouse import click
from input.window import get_foreground_window, win_exist

log = logging.getLogger(__name__)

TIMER_NAME = "pin_poll_check"
PIN_COLOR = 0xC1F5FF  # cyan tint on the pin screen


# ---------------------------------------------------------------------------
#  Logging helper
# ---------------------------------------------------------------------------

def _pin_log(msg: str):
    """Append a timestamped message to the pin log ring buffer."""
    ts = time.strftime("%H:%M:%S")
    state.pin_log.append(f"{ts} {msg}")
    if len(state.pin_log) > 50:
        state.pin_log.pop(0)
    log.debug("AutoPin: %s", msg)


# ---------------------------------------------------------------------------
#  Poll start / stop
# ---------------------------------------------------------------------------

def pin_start_poll():
    """Begin polling for the pin screen (called on E-press).

    Preconditions that skip the poll:
      - pin_auto_open is disabled
      - ARK is not the foreground window
      - The inventory is already open (bright pixel at invy_detect)
      - Another blocking script is running (magic-F refill, quick-hatch, etc.)
    """
    if not state.pin_auto_open:
        return

    # If already polling, restart
    if state.pin_poll_active:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        _pin_log("Poll restarted (new E press)")

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    # Check ARK is foreground
    if get_foreground_window() != hwnd:
        return

    # Skip if inventory already open (bright white at detect point)
    from input.pixel import pixel_get_color, is_color_similar
    inv_color = pixel_get_color(int(state.invy_detect_x), int(state.invy_detect_y))
    if is_color_similar(inv_color, 0xFFFFFF, 30):
        return

    # Skip if conflicting scripts are active
    if state.run_magic_f_script and state.magic_f_refill_mode:
        return
    if state.qh_running or state.ob_upload_running or state.ob_download_running or state.pc_running or state.ac_running:
        return

    state.pin_poll_active = True
    state.pin_poll_count = 0
    state.pin_poll_start_tick = time.monotonic()
    state.pin_e_was_held = False
    _pin_log("Poll started (E pressed)")

    timers.set_timer(TIMER_NAME, pin_poll_check, state.pin_poll_interval)


def pin_poll_check():
    """Timer callback — check pin-screen pixels and click Last Pin if matched.

    Logic flow:
      1. Increment tick counter; abort on timeout (pin_poll_max_ticks).
      2. If E is still held beyond 300 ms, record that and skip auto-click
         (user is entering a manual PIN).
      3. Check two diagnostic pixels (pix2 and pix3) for the cyan color.
      4. If both match and E was *not* long-held, click the "Last Pin" button.
    """
    state.pin_poll_count += 1

    # Detect long E hold (manual pin entry)
    # Check via ctypes GetAsyncKeyState for physical E hold.
    if not state.pin_e_was_held:
        elapsed_ms = (time.monotonic() - state.pin_poll_start_tick) * 1000
        if elapsed_ms > state.pin_hold_threshold:
            try:
                # VK_E = 0x45. Check if key is currently down.
                if _sys.get_async_key_state(0x45):
                    state.pin_e_was_held = True
                    _pin_log(f"E held >{state.pin_hold_threshold}ms — manual pin entry")
            except Exception:
                pass

    # Timeout
    if state.pin_poll_count > state.pin_poll_max_ticks:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        elapsed_ms = (time.monotonic() - state.pin_poll_start_tick) * 1000
        _pin_log(f"Poll timeout ({elapsed_ms:.0f}ms, {state.pin_poll_count} ticks) — no pin screen")
        return

    # Abort if ARK lost focus
    hwnd = win_exist(state.ark_window)
    if not hwnd or get_foreground_window() != hwnd:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        _pin_log("Poll aborted — ARK lost focus")
        return

    # Check all 4 pin-screen pixels for the cyan color
    try:
        for px, py in [
            (state.pin_pix1_x, state.pin_pix1_y),
            (state.pin_pix2_x, state.pin_pix2_y),
            (state.pin_pix3_x, state.pin_pix3_y),
            (state.pin_pix4_x, state.pin_pix4_y),
        ]:
            m = pixel_search(px, py, px, py, PIN_COLOR, state.pin_tol)
            if m is None:
                return
    except Exception:
        return

    # If E was long-held, skip auto-click
    if state.pin_e_was_held:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        _pin_log("Pin screen detected but E was held >300ms — skipping (manual pin)")
        return

    # Pin screen detected — click "Last Pin"
    timers.stop_timer(TIMER_NAME)
    state.pin_poll_active = False
    elapsed_ms = (time.monotonic() - state.pin_poll_start_tick) * 1000
    _pin_log(f"Pin screen DETECTED after {elapsed_ms:.0f}ms (tick {state.pin_poll_count}) — clicking Last Pin")

    click(state.pin_click_x, state.pin_click_y)
    _pin_log(f"  clicked ({state.pin_click_x},{state.pin_click_y})")


def pin_mark_e_held():
    """Called externally (e.g. from hotkey hook) when E has been physically held
    beyond the threshold, so the auto-click is suppressed."""
    state.pin_e_was_held = True


# ---------------------------------------------------------------------------
#  INI persistence
# ---------------------------------------------------------------------------

def pin_save_settings():
    """Persist the Auto-Pin enabled flag to AIO_config.ini."""
    try:
        write_ini("AutoPin", "Enabled", "1" if state.pin_auto_open else "0")
    except Exception as exc:
        log.warning("pin_save_settings failed: %s", exc)


def pin_load_settings():
    """Load the Auto-Pin enabled flag from AIO_config.ini and sync the GUI.

    Loads from INI and syncs the GUI checkbox.
    """
    try:
        saved = read_ini("AutoPin", "Enabled", "1")
        state.pin_auto_open = saved == "1"
        # Sync GUI checkbox
        root = state.root
        tab = getattr(state, "_tab_misc", None)
        if root and tab and hasattr(tab, "pin_var"):
            root.after(0, lambda: tab.pin_var.set(state.pin_auto_open))
    except Exception as exc:
        log.warning("pin_load_settings failed: %s", exc)
