
import logging
import time

from core.state import state
from input.pixel import pixel_search
from input.mouse import click
from input.keyboard import send, send_text
from input.window import win_exist, control_click

log = logging.getLogger(__name__)


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
    try:
        from modules.ob_upload import ob_char_restore_tooltip
        ob_char_restore_tooltip()
    except Exception:
        pass


# ---------------------------------------------------------------------------
#  Inventory detection
# ---------------------------------------------------------------------------

def _wait_inv_open(max_ticks: int = 375) -> bool:
    """Poll for the inventory-open white pixel (at 1495,226 scaled)."""
    x = int(round(1495 * state.width_multiplier))
    y = int(round(226 * state.height_multiplier))
    for _ in range(max_ticks):
        result = pixel_search(x, y, x + 2, y + 2, 0xFFFFFF, tolerance=0)
        if result is not None:
            return True
        time.sleep(0.016)
    return False


# ---------------------------------------------------------------------------
#  Core functions
# ---------------------------------------------------------------------------

def quick_feed_cycle():
    """Cycle the quick-feed mode:  Off(0) -> Raw(1) -> Berry(2) -> Off(0).

    Hides the GUI and activates ARK when first entering an armed mode.
    """
    state.quick_feed_mode = (state.quick_feed_mode + 1) % 3

    if state.quick_feed_mode == 1:
        state.gui_visible = False
        hwnd = win_exist(state.ark_window)
        if hwnd:
            from input.window import win_activate
            win_activate(hwnd)
        _tooltip(
            " Quick Feed — Raw Meat armed\n"
            "F at dino to feed  |  F3 = Berry  |  F3 again = Off"
        )
        log.info("Quick Feed: Raw Meat armed")

    elif state.quick_feed_mode == 2:
        _tooltip(
            " Quick Feed — Berry armed\n"
            "F at dino to feed  |  F3 = Off"
        )
        log.info("Quick Feed: Berry armed")

    else:
        quick_feed_stop()


def quick_feed_stop():
    """Disable quick-feed mode and restore the GUI."""
    state.quick_feed_mode = 0
    _tooltip(None)
    _restore_tooltip()
    state.gui_visible = True
    log.info("Quick Feed: Off")


def quick_feed_f_pressed():
    """Handle the F key while Quick Feed is active.

    1. Wait for the dino inventory to be open.
    2. Click the search bar in *my* inventory panel.
    3. Type the filter ("raw" or "berry").
    4. Click "Transfer All to Them".
    5. Press Escape to close the inventory.
    6. Re-display the armed tooltip.
    """
    if state.quick_feed_mode == 0:
        return

    if not _wait_inv_open(375):
        return

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return

    filter_text = "raw" if state.quick_feed_mode == 1 else "berry"

    search_x = int(state.my_search_bar_x)
    search_y = int(state.my_search_bar_y)
    control_click(hwnd, search_x, search_y)
    time.sleep(0.030)

    send_text(filter_text)
    time.sleep(0.100)

    transfer_x = int(state.transfer_to_other_btn_x)
    transfer_y = int(state.transfer_to_other_btn_y)
    control_click(hwnd, transfer_x, transfer_y)
    time.sleep(0.100)

    send("{Escape}")
    time.sleep(0.100)

    if state.quick_feed_mode == 1:
        mode_str = "Raw Meat"
        next_str = "F3 = Berry"
    else:
        mode_str = "Berry"
        next_str = "F3 = Off"

    _tooltip(
        f" Quick Feed — {mode_str} armed\n"
        f"F at dino to feed  |  {next_str}"
    )
