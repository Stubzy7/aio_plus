
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


def _pin_log(msg: str):
    ts = time.strftime("%H:%M:%S")
    state.pin_log.append(f"{ts} {msg}")
    if len(state.pin_log) > 50:
        state.pin_log.pop(0)
    log.debug("AutoPin: %s", msg)


def pin_start_poll():
    if not state.pin_auto_open:
        return

    if state.pin_poll_active:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        _pin_log("Poll restarted (new E press)")

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    if get_foreground_window() != hwnd:
        return

    from input.pixel import pixel_get_color, is_color_similar
    inv_color = pixel_get_color(int(state.invy_detect_x), int(state.invy_detect_y))
    if is_color_similar(inv_color, 0xFFFFFF, 30):
        return

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
    state.pin_poll_count += 1

    # Check via ctypes GetAsyncKeyState for physical E hold
    if not state.pin_e_was_held:
        elapsed_ms = (time.monotonic() - state.pin_poll_start_tick) * 1000
        if elapsed_ms > state.pin_hold_threshold:
            try:
                # VK_E = 0x45
                if _sys.get_async_key_state(0x45):
                    state.pin_e_was_held = True
                    _pin_log(f"E held >{state.pin_hold_threshold}ms — manual pin entry")
            except Exception:
                pass

    if state.pin_poll_count > state.pin_poll_max_ticks:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        elapsed_ms = (time.monotonic() - state.pin_poll_start_tick) * 1000
        _pin_log(f"Poll timeout ({elapsed_ms:.0f}ms, {state.pin_poll_count} ticks) — no pin screen")
        return

    hwnd = win_exist(state.ark_window)
    if not hwnd or get_foreground_window() != hwnd:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        _pin_log("Poll aborted — ARK lost focus")
        return

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

    if state.pin_e_was_held:
        timers.stop_timer(TIMER_NAME)
        state.pin_poll_active = False
        _pin_log("Pin screen detected but E was held >300ms — skipping (manual pin)")
        return

    timers.stop_timer(TIMER_NAME)
    state.pin_poll_active = False
    elapsed_ms = (time.monotonic() - state.pin_poll_start_tick) * 1000
    _pin_log(f"Pin screen DETECTED after {elapsed_ms:.0f}ms (tick {state.pin_poll_count}) — clicking Last Pin")

    click(state.pin_click_x, state.pin_click_y)
    _pin_log(f"  clicked ({state.pin_click_x},{state.pin_click_y})")


def pin_mark_e_held():
    state.pin_e_was_held = True


def pin_save_settings():
    try:
        write_ini("AutoPin", "Enabled", "1" if state.pin_auto_open else "0")
    except Exception as exc:
        log.warning("pin_save_settings failed: %s", exc)


def pin_load_settings():
    try:
        saved = read_ini("AutoPin", "Enabled", "1")
        state.pin_auto_open = saved == "1"
        root = state.root
        tab = getattr(state, "_tab_misc", None)
        if root and tab and hasattr(tab, "pin_var"):
            root.after(0, lambda: tab.pin_var.set(state.pin_auto_open))
    except Exception as exc:
        log.warning("pin_load_settings failed: %s", exc)
