
import threading
import time
import logging

from core.state import state
from core.scaling import scale_x, scale_y, width_multiplier, height_multiplier
from input.pixel import px_get, pixel_search, wait_for_pixel
from input.mouse import click, mouse_move, set_cursor_pos
from input.keyboard import send, key_press, control_send
from input.window import win_exist, win_activate, get_foreground_window, control_click

log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Scaled pixel-detection coordinates for each stat.
# Base values (2560x1440) are multiplied at module import time.
# ---------------------------------------------------------------------------
_auto_lvl_health_pix_x = round(1075 * width_multiplier)
_auto_lvl_health_pix_y = round(513 * height_multiplier)
_auto_lvl_stam_pix_x = round(1066 * width_multiplier)
_auto_lvl_stam_pix_y = round(546 * height_multiplier)
_auto_lvl_oxy_pix_x = round(1075 * width_multiplier)
_auto_lvl_oxy_pix_y = round(575 * height_multiplier)
_auto_lvl_food_pix_x = round(1075 * width_multiplier)
_auto_lvl_food_pix_y = round(608 * height_multiplier)
_auto_lvl_weight_pix_x = round(1076 * width_multiplier)
_auto_lvl_weight_pix_y = round(650 * height_multiplier)
_auto_lvl_melee_xp_pix_x = round(1112 * width_multiplier)
_auto_lvl_melee_xp_pix_y = round(482 * height_multiplier)

_lvl_btn_x = round(1507 * width_multiplier)
_health_btn_y = round(667 * height_multiplier)
_stam_btn_y = round(713 * height_multiplier)
_oxy_btn_y = round(757 * height_multiplier)
_food_btn_y = round(801 * height_multiplier)
_weight_btn_y = round(845 * height_multiplier)
_melee_btn_y = round(900 * height_multiplier)

# Inventory-open detection pixel (white at top of dino inventory).
_inv_detect_x = round(1632 * width_multiplier)
_inv_detect_y = round(215 * height_multiplier)

# Timeouts (ms)
AUTO_LVL_STAT_TIMEOUT = 2000
AUTO_LVL_INV_TIMEOUT = 250  # max poll iterations (~16 ms each)

# Module thread reference
_auto_lvl_thread: threading.Thread | None = None

# ---------------------------------------------------------------------------
# Stat descriptor table: (pixel_x, pixel_y, button_y, dict_key)
# ---------------------------------------------------------------------------
_STAT_TABLE_BASE = [
    # (pix_x, pix_y, btn_y, key, affected_by_no_oxy)
    (_auto_lvl_health_pix_x, _auto_lvl_health_pix_y, _health_btn_y, "health", False),
    (_auto_lvl_stam_pix_x, _auto_lvl_stam_pix_y, _stam_btn_y, "stam", False),
    (_auto_lvl_oxy_pix_x, _auto_lvl_oxy_pix_y, _oxy_btn_y, "oxygen", False),
    (_auto_lvl_food_pix_x, _auto_lvl_food_pix_y, _food_btn_y, "food", False),
    (_auto_lvl_weight_pix_x, _auto_lvl_weight_pix_y, _weight_btn_y, "weight", True),
    (_auto_lvl_melee_xp_pix_x, _auto_lvl_melee_xp_pix_y, _melee_btn_y, "melee", True),
]


# ---------------------------------------------------------------------------
# Tooltip builder
# ---------------------------------------------------------------------------

def auto_lvl_build_tooltip() -> str:
    """Build the tooltip string showing stat queue and current selection."""
    params = getattr(state, "_auto_lvl_params", None)
    if params is None:
        return " AutoLvL: No stats set"

    stat_points = params["stat_points"]
    combine = params.get("combine", True)
    stat_queue = params.get("stat_queue", [])
    stat_idx = params.get("stat_idx", 0)

    if combine:
        parts = []
        for key in ("health", "stam", "food", "weight", "melee"):
            n = stat_points.get(key, 0)
            if n > 0:
                parts.append(f"{key.capitalize()} +{n}")
        summary = "  |  ".join(parts) if parts else "No stats set"
        return f" AutoLvL: {summary}\n F at inventory  |  F1 = Stop/UI"
    else:
        parts = []
        for i, (key, count) in enumerate(stat_queue):
            marker = "\u25b6 " if i == stat_idx else "  "
            parts.append(f"{marker}{key.capitalize()} +{count}")
        stat_list = "\n".join(parts) if parts else "No stats set"
        return f" AutoLvL (cycle mode):\n{stat_list}\n F = Level  |  Q = Next  |  F1 = Stop"


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def run_auto_lvl(stat_points: dict | None = None,
                 no_oxy: bool = False,
                 auto_saddle: bool = False,
                 cryo_after: bool = False,
                 combine: bool = True):
    """Start auto-leveling in a background thread."""
    if stat_points is None:
        stat_points = {}
    state.run_auto_lvl_script = True
    state.gui_visible = False

    # Build the stat queue for cycle mode (ordered list of stats with points > 0)
    stat_queue = []
    for key in ("health", "stam", "food", "weight", "melee"):
        n = stat_points.get(key, 0)
        if n > 0:
            stat_queue.append((key, n))

    parts = []
    for key, n in stat_queue:
        parts.append(f"{key.capitalize()} +{n}")
    log.info("AutoLvL: %s  |  combine=%s  |  F1 = Pause",
             "  |  ".join(parts) if parts else "No stats set", combine)

    global _auto_lvl_thread
    _auto_lvl_thread = threading.Thread(
        target=_auto_lvl_thread_entry,
        args=(stat_points, no_oxy, auto_saddle, cryo_after, combine, stat_queue),
        daemon=True,
        name="auto-lvl",
    )
    _auto_lvl_thread.start()


def _auto_lvl_thread_entry(stat_points: dict, no_oxy: bool,
                           auto_saddle: bool, cryo_after: bool,
                           combine: bool, stat_queue: list):
    """Background entry — keeps the module armed until the user cancels."""
    state._auto_lvl_params = {
        "stat_points": stat_points,
        "no_oxy": no_oxy,
        "auto_saddle": auto_saddle,
        "cryo_after": cryo_after,
        "combine": combine,
        "stat_queue": stat_queue,
        "stat_idx": 0,
    }
    while state.run_auto_lvl_script:
        time.sleep(0.1)
    state.gui_visible = True
    log.info("AutoLvL: stopped")


# ---------------------------------------------------------------------------
# Q-press callback: cycle to next stat in cycle mode
# ---------------------------------------------------------------------------

def auto_lvl_q_pressed():
    """Cycle to the next stat in the queue (cycle mode only)."""
    params = getattr(state, "_auto_lvl_params", None)
    if params is None or params.get("combine", True):
        return

    stat_queue = params.get("stat_queue", [])
    if not stat_queue:
        return

    idx = params.get("stat_idx", 0)
    idx = (idx + 1) % len(stat_queue)
    params["stat_idx"] = idx

    log.info("AutoLvL: cycled to %s", stat_queue[idx][0])

    # Update tooltip
    from gui.tooltip import show_tooltip
    show_tooltip(auto_lvl_build_tooltip(), 0, 0)


# ---------------------------------------------------------------------------
# F-press callback (called by hotkey system when F is pressed at inventory)
# ---------------------------------------------------------------------------

def auto_lvl_f_pressed():
    """Called when the user presses F with auto-level armed."""
    if not state.run_auto_lvl_script:
        return

    params = getattr(state, "_auto_lvl_params", None)
    if params is None:
        return

    combine = params.get("combine", True)

    if combine:
        _auto_lvl_f_combine(params)
    else:
        _auto_lvl_f_cycle(params)


def _auto_lvl_f_combine(params: dict):
    """Combine mode: level all stats in one F press (original behavior)."""
    stat_points = params["stat_points"]
    no_oxy = params["no_oxy"]
    auto_saddle = params["auto_saddle"]
    cryo_after = params["cryo_after"]

    if not _wait_for_inventory():
        return

    no_oxy_diff = round(50 * height_multiplier) if no_oxy else 0

    for pix_x, pix_y, btn_y, key, affected in _STAT_TABLE_BASE:
        count = stat_points.get(key, 0)
        if count <= 0:
            continue

        actual_btn_y = btn_y - no_oxy_diff if affected else btn_y
        col_before = px_get(pix_x, pix_y)
        lvl_stat(count, _lvl_btn_x, actual_btn_y)

        if not auto_lvl_wait_stat_change(pix_x, pix_y, col_before):
            log.debug("AutoLvL: %s stat did not confirm — aborting", key)
            return

    _auto_lvl_finish(auto_saddle, cryo_after)


def _auto_lvl_f_cycle(params: dict):
    """Cycle mode: level only the current stat on F press."""
    stat_queue = params.get("stat_queue", [])
    stat_idx = params.get("stat_idx", 0)
    no_oxy = params["no_oxy"]
    auto_saddle = params["auto_saddle"]
    cryo_after = params["cryo_after"]

    if not stat_queue:
        return

    key, count = stat_queue[stat_idx]

    if not _wait_for_inventory():
        return

    no_oxy_diff = round(50 * height_multiplier) if no_oxy else 0

    for pix_x, pix_y, btn_y, tbl_key, affected in _STAT_TABLE_BASE:
        if tbl_key == key:
            actual_btn_y = btn_y - no_oxy_diff if affected else btn_y
            col_before = px_get(pix_x, pix_y)
            lvl_stat(count, _lvl_btn_x, actual_btn_y)

            if not auto_lvl_wait_stat_change(pix_x, pix_y, col_before):
                log.debug("AutoLvL: %s stat did not confirm — aborting", key)
                _close_inventory()
                return

            log.info("AutoLvL: %s +%d done", key, count)
            break

    _auto_lvl_finish(auto_saddle, cryo_after)


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def _wait_for_inventory() -> bool:
    """Wait for the dino inventory to open. Returns True if detected."""
    for _ in range(AUTO_LVL_INV_TIMEOUT):
        result = pixel_search(
            _inv_detect_x, _inv_detect_y,
            _inv_detect_x + 1, _inv_detect_y + 1,
            0xFFFFFF, tolerance=0,
        )
        if result is not None:
            return True
        time.sleep(0.016)
    log.debug("AutoLvL: inventory did not open in time")
    return False


def _close_inventory():
    """Send Escape to close the inventory."""
    hwnd = win_exist(state.ark_window)
    if hwnd:
        control_send(hwnd, "{Esc}")


def _auto_lvl_finish(auto_saddle: bool, cryo_after: bool):
    if auto_saddle:
        time.sleep(0.1)
        saddle_x = round(413 * width_multiplier)
        saddle_y = round(386 * height_multiplier)
        mouse_move(saddle_x, saddle_y)
        time.sleep(0.1)
        click()
        time.sleep(0.2)
        hwnd = win_exist(state.ark_window)
        if hwnd:
            control_send(hwnd, "e")
        time.sleep(0.025)

    _close_inventory()

    if cryo_after:
        # Poll until inv pixel goes dark — ControlSend Esc is async
        for _ in range(60):
            col = px_get(_inv_detect_x, _inv_detect_y)
            r = (col >> 16) & 0xFF
            g = (col >> 8) & 0xFF
            b = col & 0xFF
            if r < 200 or g < 200 or b < 200:
                break
            time.sleep(0.016)
        time.sleep(1.9)
        click()


# ---------------------------------------------------------------------------
# Stat helpers
# ---------------------------------------------------------------------------

def auto_lvl_wait_stat_change(x: int, y: int, col_before: int,
                              timeout_ms: int = AUTO_LVL_STAT_TIMEOUT) -> bool:
    """Poll a pixel until its color differs from *col_before*."""
    deadline = time.perf_counter() + timeout_ms / 1000.0
    while True:
        current = px_get(x, y)
        if current != col_before:
            return True
        if time.perf_counter() >= deadline:
            return False
        time.sleep(0.030)


def lvl_stat(count: int, x: int, y: int):
    """Click (x, y) *count* times with no inter-click delay."""
    mouse_move(x, y, 0)
    click(count=count)
    # Brief settle so the game can process all the queued clicks
    # before we start polling the stat-change pixel
    time.sleep(0.05)
