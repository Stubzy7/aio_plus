
import re
import time
import threading
import logging

from pal import system as _sys
from core.state import state
from input.pixel import px_get, is_color_similar, pixel_search
from input.keyboard import send, key_press
from input.mouse import click, set_cursor_pos
from input.ocr import from_rect
from input.window import win_exist

log = logging.getLogger(__name__)


def _pc_log(msg: str):
    ts = time.strftime("%H:%M:%S")
    state.pc_log_entries.append(f"{ts} {msg}")
    if len(state.pc_log_entries) > 50:
        state.pc_log_entries.pop(0)
    log.info("Popcorn: %s", msg)


try:
    _sys.begin_timer_period(1)
except Exception:
    pass


def precise_sleep(ms: float):
    if ms <= 0:
        return
    target = time.perf_counter() + ms / 1000.0
    if ms > 2:
        time.sleep((ms - 1) / 1000.0)
    while time.perf_counter() < target:
        pass


def pc_wait_for_inventory(max_ms: int = 5000) -> bool:
    x = int(state.pc_inv_detect_x)
    y = int(state.pc_inv_detect_y)
    start = time.perf_counter()
    while True:
        color = px_get(x, y)
        r = (color >> 16) & 0xFF
        g = (color >> 8) & 0xFF
        b = color & 0xFF
        passed = (abs(r - 255) <= 10 and abs(g - 255) <= 10 and abs(b - 255) <= 10)
        if passed:
            log.info("WaitInv: PASS at (%d,%d) color=0x%06X r=%d g=%d b=%d",
                     x, y, color, r, g, b)
            return True
        elapsed = (time.perf_counter() - start) * 1000
        if elapsed > max_ms:
            log.warning("WaitInv: FAIL at (%d,%d) color=0x%06X r=%d g=%d b=%d "
                        "after %.0fms", x, y, color, r, g, b, elapsed)
            return False
        time.sleep(0.016)


def pc_is_tame_inventory() -> bool:
    # Check player inventory pixel first — if present, it's player not tame
    px = int(state.pc_player_inv_detect_x)
    py = int(state.pc_player_inv_detect_y)
    pc = px_get(px, py)
    pr = (pc >> 16) & 0xFF
    pg = (pc >> 8) & 0xFF
    pb = pc & 0xFF
    epr = (state.pc_player_inv_detect_color >> 16) & 0xFF
    epg = (state.pc_player_inv_detect_color >> 8) & 0xFF
    epb = state.pc_player_inv_detect_color & 0xFF
    ptol = state.pc_player_inv_detect_tol
    if abs(pr - epr) <= ptol and abs(pg - epg) <= ptol and abs(pb - epb) <= ptol:
        _pc_log(f"TameDetect: PLAYER inv at ({px},{py}) color=0x{pc:06X} — not tame")
        return False

    # Check tame pixel
    x = int(state.pc_tame_detect_x)
    y = int(state.pc_tame_detect_y)
    color = px_get(x, y)
    r = (color >> 16) & 0xFF
    g = (color >> 8) & 0xFF
    b = color & 0xFF
    tr = (state.pc_tame_detect_color >> 16) & 0xFF
    tg = (state.pc_tame_detect_color >> 8) & 0xFF
    tb = state.pc_tame_detect_color & 0xFF
    tol = state.pc_tame_detect_tol
    matched = (abs(r - tr) <= tol and abs(g - tg) <= tol and abs(b - tb) <= tol)
    if matched:
        _pc_log(f"TameDetect: TAME at ({x},{y}) color=0x{color:06X}")
    return matched


def pc_popcorn_grid(skip_first: bool = False,
                    is_final_cycle: bool = True,
                    max_drops: int = 0,
                    drops_so_far: int = 0) -> str:
    start_x = int(state.pc_start_slot_x)
    start_y = int(state.pc_start_slot_y)
    slot_w = int(state.pc_slot_w)
    slot_h = int(state.pc_slot_h)
    rows = state.pc_rows
    cols = state.pc_columns
    drop_count = 0

    _pc_log(f"Grid: dropKey={state.pc_drop_key} dropSleep={state.pc_drop_sleep} "
            f"hoverDelay={state.pc_hover_delay} skipFirst={skip_first} "
            f"isFinal={is_final_cycle} grid={cols}x{rows} "
            f"start=({start_x},{start_y}) slotW={slot_w} slotH={slot_h}"
            + (f" maxDrops={max_drops} soFar={drops_so_far}" if max_drops else ""))
    _pc_log(f"Grid: abort flags at entry — earlyExit={state.pc_early_exit} "
            f"f1Abort={state.pc_f1_abort}")

    VK_Q = 0x51
    _get_key = _sys.get_async_key_state

    for row in range(rows):
        for col in range(cols):
            if skip_first and row == 0 and col == 0:
                continue

            # F1 abort: use state flag only (set by _f1_handler via _stop_flags
            # on the hook thread). Cannot use GetAsyncKeyState(VK_F1) because
            # F1 is suppress=True in the hook — the hook eats the keystroke but
            # GetAsyncKeyState still sees it due to Win32 raw input timing.
            # Q abort: poll physical key state (Q is passthrough, not suppressed).
            if _get_key(VK_Q) and not state.pc_f1_abort:
                state.pc_early_exit = True
            if state.pc_early_exit or state.pc_f1_abort:
                _pc_log(f"Grid: abort at row={row} col={col} "
                        f"earlyExit={state.pc_early_exit} f1Abort={state.pc_f1_abort}")
                return "early"

            x = start_x + col * slot_w
            y = start_y + row * slot_h

            set_cursor_pos(int(x), int(y))

            # Read live from state so Z speed changes apply mid-run
            if is_final_cycle and row == 0:
                precise_sleep(state.pc_hover_delay)

            key_press(state.pc_drop_key)
            drop_count += 1

            if max_drops and (drops_so_far + drop_count) >= max_drops:
                _pc_log(f"Grid: max_drops reached ({drops_so_far + drop_count}/{max_drops})")
                return "max_reached"

            if state.pc_drop_sleep > 0:
                precise_sleep(state.pc_drop_sleep)

    _pc_log(f"Grid: done — {drop_count} drops fired")
    return "done"


def pc_popcorn_top_row():
    start_x = int(state.pc_start_slot_x)
    start_y = int(state.pc_start_slot_y)
    slot_w = int(state.pc_slot_w)
    cols = state.pc_columns

    for col in range(cols):
        x = start_x + col * slot_w
        set_cursor_pos(int(x), int(start_y))
        key_press(state.pc_drop_key)
        if state.pc_drop_sleep > 0:
            precise_sleep(state.pc_drop_sleep)

    log.debug("TopRow: %d drops fired", cols)


def pc_apply_filter(filter_text: str):
    if not filter_text:
        return

    from input.window import control_click, win_activate
    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    win_activate(hwnd)

    search_x = int(state.pc_search_bar_x)
    search_y = int(state.pc_search_bar_y)
    slot_x = int(state.pc_start_slot_x)
    slot_y = int(state.pc_start_slot_y)

    time.sleep(0.080)
    control_click(hwnd, search_x, search_y)
    time.sleep(0.120)
    _pc_set_clipboard(filter_text)
    send("^a")
    time.sleep(0.030)
    send("^v")
    time.sleep(0.250)
    # Physical click to defocus search bar — ControlClick (PostMessage) may not
    # transfer keyboard focus in ARK/Unreal, leaving "g" keystrokes going to
    # the search bar as text instead of being processed as drop commands.
    click(slot_x, slot_y)
    time.sleep(0.120)
    _pc_log(f"ApplyFilter: [{filter_text}] applied")


def _pc_set_clipboard(text: str):
    from util.clipboard import set_clipboard_text
    set_clipboard_text(text)


def pc_clear_filter():
    from input.window import control_click, win_activate
    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    win_activate(hwnd)

    search_x = int(state.pc_search_bar_x)
    search_y = int(state.pc_search_bar_y)
    slot_x = int(state.pc_start_slot_x)
    slot_y = int(state.pc_start_slot_y)

    time.sleep(0.060)
    control_click(hwnd, search_x, search_y)
    time.sleep(0.080)
    send("^a")
    time.sleep(0.020)
    send("{Delete}")
    time.sleep(0.150)
    # Physical click to defocus search bar (see ApplyFilter comment)
    click(slot_x, slot_y)
    time.sleep(0.100)
    _pc_log("ClearFilter: done")


def pc_transfer_all():
    from input.window import control_click
    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    time.sleep(0.080)
    control_click(hwnd, int(state.pc_transfer_all_x), int(state.pc_transfer_all_y))
    time.sleep(0.100)


def pc_check_storage_empty() -> int:
    sx = int(state.pc_storage_scan_x)
    sy = int(state.pc_storage_scan_y)
    sw = int(state.pc_storage_scan_w)
    sh = int(state.pc_storage_scan_h)

    attempts = 0
    while attempts < 3:
        attempts += 1
        try:
            if attempts == 1:
                log.info("StorageOCR: region=(%d,%d %dx%d) scale=3", sx, sy, sw, sh)
            raw_text = from_rect(sx, sy, sw, sh, scale=3)
            cleaned = re.sub(r"[oO]", "0", raw_text)
            cleaned = re.sub(r"[Il|]", "1", cleaned)
            cleaned = re.sub(r"s(?=\d)", "5", cleaned)
            cleaned = re.sub(r"\d+\.\d+\s*/?\s*\d*\.?\d*", "", cleaned)
            cleaned = re.sub(r"\s+", " ", cleaned)

            m = re.search(r"(-?\d+)\s*/\s*(\d+)", cleaned)
            if m:
                val = int(m.group(1))
                max_val = int(m.group(2))
                if val < 0:
                    val = 0
                if val == 0 and len(m.group(1)) > 1:
                    _pc_log(f"OCR: suspicious 0 from [{m.group(1)}] raw=[{raw_text.strip()}] — retrying")
                    time.sleep(0.080)
                    continue
                if 6 <= max_val <= 999:
                    _pc_log(f"OCR: {val}/{max_val} raw=[{raw_text.strip()}]")
                    return val

            bag_m = re.search(r"(\d+)\s*/\s*[-\u2014\u2013]+", cleaned)
            if bag_m:
                val = max(0, int(bag_m.group(1)))
                _pc_log(f"OCR: {val}/-- (bag) raw=[{raw_text.strip()}]")
                return val

            if not state.pc_is_bag and attempts >= 2:
                if re.match(r"^\s*/", cleaned):
                    _pc_log(f"OCR: bare slash -> -1 (read fail) raw=[{raw_text.strip()}]")
                    return -1

            _pc_log(f"OCR: no pattern match raw=[{raw_text.strip()}] cleaned=[{cleaned.strip()}]")

        except Exception as exc:
            _pc_log(f"OCR: FAIL attempt {attempts} — {exc}")

        time.sleep(0.080)

    _pc_log(f"OCR: no valid reading after {attempts} attempts -> -1")
    return -1


def pc_check_weight() -> float:
    sx = int(state.pc_weight_ocr_x)
    sy = int(state.pc_weight_ocr_y)
    sw = int(state.pc_weight_ocr_w)
    sh = int(state.pc_weight_ocr_h)

    attempts = 0
    while attempts < 3:
        attempts += 1
        try:
            if attempts == 1:
                log.info("WeightOCR: region=(%d,%d %dx%d) scale=3", sx, sy, sw, sh)
            raw_text = from_rect(sx, sy, sw, sh, scale=3)
            cleaned = re.sub(r"[oO]", "0", raw_text)
            cleaned = re.sub(r"[Il|]", "1", cleaned)
            cleaned = re.sub(r"s(?=\d)", "5", cleaned)

            m = re.search(r"(\d+\.?\d*)\s*/\s*(\d+\.?\d*)", cleaned)
            if m:
                val = float(m.group(1))
                _pc_log(f"WeightOCR: {val}/{m.group(2)} raw=[{raw_text.strip()}]")
                return val

            _pc_log(f"WeightOCR: no match raw=[{raw_text.strip()}] cleaned=[{cleaned.strip()}]")

        except Exception as exc:
            _pc_log(f"WeightOCR: FAIL attempt {attempts} — {exc}")

        time.sleep(0.080)

    _pc_log(f"WeightOCR: no valid reading after {attempts} attempts -> -1")
    return -1.0


def pc_wait_weight_stable(timeout_s: float = 5.0) -> float:
    last = pc_check_weight()
    start = time.perf_counter()
    while time.perf_counter() - start < timeout_s:
        time.sleep(0.250)
        cur = pc_check_weight()
        if cur < 0:
            continue
        if last >= 0 and abs(cur - last) < 0.1:
            _pc_log(f"WeightStable: settled at {cur} after "
                    f"{(time.perf_counter() - start) * 1000:.0f}ms")
            return cur
        last = cur
    _pc_log(f"WeightStable: timeout after {timeout_s}s, last={last}")
    return last


def pc_apply_speed():
    mode = state.pc_speed_mode
    speeds = state.pc_speed_map.get(mode, [4, 15, 20])
    state.pc_drop_sleep = speeds[0]
    state.pc_cycle_sleep = speeds[1]
    state.pc_hover_delay = speeds[2]
    log.debug("Speed applied: mode=%d  drop=%d  cycle=%d  hover=%d",
              mode, speeds[0], speeds[1], speeds[2])


def pc_cycle_speed():
    state.pc_speed_mode = (state.pc_speed_mode + 1) % 3
    pc_apply_speed()
    log.debug("Speed cycled to %s", state.pc_speed_names.get(state.pc_speed_mode, "?"))


def pc_build_tooltip() -> str:
    if state.pc_mode == 0:
        return ""

    parts: list[str] = []
    if state.pc_all_no_filter:
        parts.append("All (no filter)")
    if state.pc_grinder_poly:
        parts.append("Poly")
    if state.pc_grinder_metal:
        parts.append("Metal")
    if state.pc_grinder_crystal:
        parts.append("Crystal")
    if state.pc_preset_raw:
        parts.append("Raw")
    if state.pc_preset_cooked:
        parts.append("Cooked")
    if state.pc_all_custom_active:
        for pf in state.pc_custom_filter_list:
            parts.append(f"Custom [{pf}]")
        if (state.pc_custom_filter
                and state.pc_custom_filter not in state.pc_custom_filter_list):
            parts.append(f"Custom [{state.pc_custom_filter}]")

    desc = " + ".join(parts) if parts else "Nothing selected"

    flags: list[str] = []
    if state.pc_forge_transfer_all:
        flags.append("Transfer All")
    if state.pc_forge_skip_first:
        flags.append("Skip 1st")

    line1 = f" Popcorn: {desc}"
    if flags:
        line1 += f"  ({', '.join(flags)})"

    speed_name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
    line2 = f"Speed: {speed_name}  |  Z = Change drop speed"

    if len(parts) > 1:
        line3 = "F to start  |  Q = Cycle presets  |  F1 = Stop/UI"
    else:
        line3 = "F to start  |  Q = Stop  |  F1 = Stop/UI"

    return f"{line1}\n{line2}\n{line3}"


def _run_drop_loop(label: str, max_drops: int = 0) -> tuple[int, bool]:
    is_tame = pc_is_tame_inventory()
    state.pc_is_tame = is_tame

    if is_tame:
        return _run_drop_loop_tame(label, max_drops=max_drops)
    return _run_drop_loop_storage(label, max_drops=max_drops)


def pc_select_weight_region():
    x = int(state.pc_oxy_detect_x)
    y = int(state.pc_oxy_detect_y)
    color = px_get(x, y)
    r = (color >> 16) & 0xFF
    g = (color >> 8) & 0xFF
    b = color & 0xFF
    er = (state.pc_oxy_detect_color >> 16) & 0xFF
    eg = (state.pc_oxy_detect_color >> 8) & 0xFF
    eb = state.pc_oxy_detect_color & 0xFF
    tol = state.pc_oxy_detect_tol
    has_oxy = (abs(r - er) <= tol and abs(g - eg) <= tol and abs(b - eb) <= tol)

    if has_oxy:
        state.pc_weight_ocr_x = state.pc_weight_o_x
        state.pc_weight_ocr_y = state.pc_weight_o_y
        state.pc_weight_ocr_w = state.pc_weight_o_w
        state.pc_weight_ocr_h = state.pc_weight_o_h
        _pc_log(f"OxyDetect: HAS oxy at ({x},{y}) color=0x{color:06X} — using has-oxy weight region")
    else:
        state.pc_weight_ocr_x = state.pc_weight_n_x
        state.pc_weight_ocr_y = state.pc_weight_n_y
        state.pc_weight_ocr_w = state.pc_weight_n_w
        state.pc_weight_ocr_h = state.pc_weight_n_h
        _pc_log(f"OxyDetect: NO oxy at ({x},{y}) color=0x{color:06X} — using no-oxy weight region")


def _run_drop_loop_tame(label: str, max_drops: int = 0) -> tuple[int, bool]:
    pc_select_weight_region()
    _pc_log(f"DropLoop(tame): {label} — starting"
            + (f" maxDrops={max_drops}" if max_drops else ""))

    pass_num = 0
    zero_count = 0
    total_drops = 0

    while not state.pc_early_exit and not state.pc_f1_abort:
        pass_num += 1
        result = pc_popcorn_grid(state.pc_forge_skip_first,
                                 max_drops=max_drops, drops_so_far=total_drops)
        grid_drops = int(state.pc_rows) * int(state.pc_columns)
        if max_drops:
            grid_drops = min(grid_drops, max_drops - total_drops)
        total_drops += grid_drops

        if result == "max_reached":
            _pc_log(f"DropLoop(tame): max_drops reached after pass {pass_num}")
            break
        if state.pc_early_exit or state.pc_f1_abort:
            _pc_log(f"DropLoop(tame): pass {pass_num} — early exit")
            break

        cur = pc_check_weight()
        _pc_log(f"DropLoop(tame): pass {pass_num} weight={cur}")

        if cur >= 0 and cur < 20.1:
            zero_count += 1
            if zero_count >= 2:
                _pc_log(f"DropLoop(tame): weight<=20 (saddle only) — done")
                pc_popcorn_top_row()
                break
        else:
            zero_count = 0

        precise_sleep(state.pc_cycle_sleep)

    _pc_log(f"DropLoop(tame): {label} ended after {pass_num} passes, {total_drops} drops")
    return pass_num, False


def _run_drop_loop_storage(label: str, max_drops: int = 0) -> tuple[int, bool]:
    # Wait for inventory items to load — OCR shows -x/x or 0/x while
    # loading, then updates to the actual count once items render.
    _wait_start = time.perf_counter()
    _stable = 0
    for _poll in range(60):
        if state.pc_early_exit or state.pc_f1_abort:
            break
        chk = pc_check_storage_empty()
        if chk > 0:
            _pc_log(f"DropLoop: items loaded ({chk}) after {_poll + 1} polls "
                    f"({(time.perf_counter() - _wait_start) * 1000:.0f}ms)")
            break
        if chk == 0:
            _stable += 1
            if _stable >= 3:
                _pc_log(f"DropLoop: storage=0 confirmed after {_poll + 1} polls — nothing to drop")
                return 0, False
        else:
            _stable = 0
        time.sleep(0.050)
    else:
        _pc_log(f"DropLoop: items never loaded after 60 polls — proceeding anyway")

    pass_num = 0
    ocr_fails = 0
    last_storage = -99
    stall_count = 0
    stall_start = 0.0
    stalled = False
    total_drops = 0

    STALL_MIN_SEC = 1.5

    while not state.pc_early_exit and not state.pc_f1_abort:
        pass_num += 1
        result = pc_popcorn_grid(state.pc_forge_skip_first,
                                 max_drops=max_drops, drops_so_far=total_drops)
        grid_drops = int(state.pc_rows) * int(state.pc_columns)
        if max_drops:
            grid_drops = min(grid_drops, max_drops - total_drops)
        total_drops += grid_drops

        if result == "max_reached":
            _pc_log(f"DropLoop: max_drops reached after pass {pass_num}")
            break
        if state.pc_early_exit or state.pc_f1_abort:
            _pc_log(f"DropLoop: {label} pass {pass_num} — early exit")
            break

        if pass_num == 1:
            precise_sleep(state.pc_cycle_sleep)
            continue

        chk = pc_check_storage_empty()
        _pc_log(f"DropLoop: {label} pass {pass_num} OCR={chk}")

        if chk == 0:
            _pc_log(f"DropLoop: storage=0 after pass {pass_num} — top row cleanup")
            pc_popcorn_top_row()
            break

        if chk == -1:
            ocr_fails += 1
            if ocr_fails >= 6:
                _pc_log(f"DropLoop: 6 OCR fails after pass {pass_num} — assuming empty")
                pc_popcorn_top_row()
                break
        else:
            ocr_fails = 0
            if chk == last_storage:
                stall_count += 1
                elapsed = time.perf_counter() - stall_start
                if stall_count >= 3 and elapsed >= STALL_MIN_SEC:
                    _pc_log(f"DropLoop: stalled at {chk} x{stall_count} "
                            f"for {elapsed:.1f}s after pass {pass_num}")
                    stalled = True
                    break
            else:
                last_storage = chk
                stall_count = 0
                stall_start = time.perf_counter()

        precise_sleep(state.pc_cycle_sleep)

    _pc_log(f"DropLoop: {label} ended after {pass_num} passes")
    return pass_num, stalled


def pc_unified_run():
    filters: list[str] = []
    labels: list[str] = []
    is_clear: list[bool] = []

    if state.pc_all_no_filter:
        filters.append("")
        labels.append("All (no filter)")
        is_clear.append(True)
    if state.pc_grinder_poly:
        filters.append(state.pc_grinder_filter_poly)
        labels.append("Poly")
        is_clear.append(False)
    if state.pc_grinder_metal:
        filters.append(state.pc_grinder_filter_metal)
        labels.append("Metal")
        is_clear.append(False)
    if state.pc_grinder_crystal:
        filters.append(state.pc_grinder_filter_crystal)
        labels.append("Crystal")
        is_clear.append(False)
    if state.pc_preset_raw:
        filters.append(state.pc_raw_filter)
        labels.append("Raw")
        is_clear.append(False)
    if state.pc_preset_cooked:
        filters.append(state.pc_cooked_filter)
        labels.append("Cooked")
        is_clear.append(False)
    if state.pc_all_custom_active:
        for pf in state.pc_custom_filter_list:
            filters.append(pf)
            labels.append(f"Custom [{pf}]")
            is_clear.append(False)
        if (state.pc_custom_filter
                and state.pc_custom_filter not in state.pc_custom_filter_list):
            filters.append(state.pc_custom_filter)
            labels.append(f"Custom [{state.pc_custom_filter}]")
            is_clear.append(False)

    time.sleep(0.050)
    stalled = False

    state.pc_early_exit = False
    state.pc_f1_abort = False

    if len(filters) > 1:
        _pc_log(f"UnifiedRun: START multi-step  count={len(filters)}  "
                f"skipFirst={state.pc_forge_skip_first}  "
                f"xferAll={state.pc_forge_transfer_all}")
        for i, (f, label, clr) in enumerate(zip(filters, labels, is_clear)):
            if state.pc_f1_abort:
                _pc_log(f"UnifiedRun: F1 abort before step {i + 1}")
                break

            state.pc_early_exit = False

            if i > 0:
                VK_Q = 0x51
                _get_key = _sys.get_async_key_state
                while _get_key(VK_Q) and not state.pc_f1_abort:
                    time.sleep(0.050)
                time.sleep(0.050)
                if state.pc_f1_abort:
                    _pc_log(f"UnifiedRun: F1 abort during KeyWait for step {i + 1}")
                    break
                _pc_log(f"UnifiedRun: KeyWait+debounce done for step {i + 1}")

            remaining = len(filters) - i - 1
            next_label = labels[i + 1] if remaining > 0 else ""
            _pc_log(f"UnifiedRun: step {i + 1} [{f}] for {label}  "
                    f"({remaining} remaining)")
            status = label
            if remaining > 0:
                status += f"  (Q \u2192 {next_label})"
            else:
                status += "  (Q \u2192 Done)"
            pc_set_status(status)

            if clr:
                pc_clear_filter()
            else:
                pc_apply_filter(f)

            _pc_tooltip(pc_build_tooltip())

            while not state.pc_early_exit and not state.pc_f1_abort:
                pc_popcorn_grid(state.pc_forge_skip_first)
                precise_sleep(state.pc_cycle_sleep)

            _pc_log(f"UnifiedRun: {label} ended (earlyExit={state.pc_early_exit} f1Abort={state.pc_f1_abort})")

            if state.pc_f1_abort:
                break

        _pc_log("UnifiedRun: all steps done")

    elif len(filters) == 1:
        _pc_log(f"UnifiedRun: START single [{labels[0]}]  "
                f"skipFirst={state.pc_forge_skip_first}  "
                f"xferAll={state.pc_forge_transfer_all}")
        if is_clear[0]:
            pc_clear_filter()
        else:
            pc_apply_filter(filters[0])
        _, stalled = _run_drop_loop(labels[0])

    else:
        _pc_log(f"UnifiedRun: START fallback all mode  "
                f"skipFirst={state.pc_forge_skip_first}  "
                f"xferAll={state.pc_forge_transfer_all}")
        fallback_filter = ""
        if state.pc_custom_filter:
            fallback_filter = state.pc_custom_filter
        elif state.pc_custom_filter_list:
            fallback_filter = state.pc_custom_filter_list[0]

        if fallback_filter:
            pc_apply_filter(fallback_filter)
            _pc_log(f"UnifiedRun: fallback applied filter [{fallback_filter}]")
        else:
            pc_clear_filter()

        _, stalled = _run_drop_loop("Dropping")

    if state.pc_f1_abort:
        _pc_log("UnifiedRun: F1 abort — PAUSED")
        return

    if stalled:
        time.sleep(0.100)
        if state.pc_is_bag:
            _pc_log("UnifiedRun: bag stalled — skipping close")
        else:
            _pc_log("UnifiedRun: closing inventory (stalled — pick up & depo, then F to continue)")
            send("{f}")
            time.sleep(0.200)
        pc_set_status("Stalled — pick up items, F to continue")
        _pc_log("UnifiedRun: STALLED")
        return

    if state.pc_forge_transfer_all and not state.pc_is_bag:
        _pc_log("UnifiedRun: applying Transfer All")
        pc_transfer_all()

    time.sleep(0.100)
    if state.pc_is_bag:
        _pc_log("UnifiedRun: bag — skipping close")
    else:
        _pc_log("UnifiedRun: closing inventory")
        send("{f}")
        time.sleep(0.200)

    _pc_log("UnifiedRun: DONE")


def pc_f_pressed():
    _pc_log(f"FPressed: mode={state.pc_mode}  running={state.pc_running}")

    if not win_exist(state.ark_window):
        _pc_log("FPressed: ARK window not found")
        return

    _pc_log("FPressed: waiting for inventory pixel")
    if not pc_wait_for_inventory(3000):
        _pc_log("FPressed: inventory pixel not found within 3s — aborting")
        return

    _pc_log("FPressed: inventory pixel detected")

    from core.config import read_ini
    saved_drop = read_ini("Popcorn", "DropKey", "")
    if not saved_drop:
        try:
            tab_pc = getattr(state, "_tab_popcorn", None)
            if tab_pc and state.root:
                state.root.after(0, tab_pc._show_set_keys_prompt)
        except Exception:
            pass
        return

    state.pc_running = True

    if state.main_gui and state.gui_visible:
        state.gui_visible = False
        try:
            state.root.after(0, state.main_gui.hide)
        except Exception:
            pass

    if state.pc_mode > 0:
        pc_register_speed_hotkeys(True)

    _pc_run_current_mode()


def _pc_run_current_mode():
    state.pc_f1_abort = False
    state.pc_early_exit = False
    _pc_log(f"RunCurrentMode: mode={state.pc_mode}")

    hwnd = win_exist(state.ark_window)
    if hwnd:
        from input.window import win_activate
        win_activate(hwnd)
        time.sleep(0.150)
        _pc_log("RunCurrentMode: ARK activated — 150ms settle")

    state.pc_is_bag = False
    state.pc_is_tame = False
    try:
        result = pixel_search(
            int(state.pc_bag_detect_x), int(state.pc_bag_detect_y),
            int(state.pc_bag_detect_x) + 2, int(state.pc_bag_detect_y) + 2,
            state.pc_bag_detect_color, tolerance=state.pc_bag_detect_tol,
        )
        if result is not None:
            state.pc_is_bag = True
            _pc_log("RunCurrentMode: bag/cache detected")
    except Exception:
        pass

    if state.pc_f10_step > 0:
        _pc_tooltip(pc_build_f10_tooltip())
    else:
        _pc_tooltip(pc_build_tooltip())

    try:
        pc_unified_run()
    finally:
        state.pc_running = False
        state.pc_early_exit = False
        state.pc_f1_abort = False
        _pc_log("RunCurrentMode: finished — mode staying active")

    if state.pc_f10_step > 0 or state.pc_mode > 0:
        pc_register_speed_hotkeys(True)
        pc_show_armed_tooltip()
    else:
        pc_register_speed_hotkeys(False)
        _pc_tooltip(None)


def pc_f_pressed_async():
    t = threading.Thread(target=pc_f_pressed, daemon=True,
                         name="popcorn-exec")
    t.start()


def stop_popcorn():
    state.pc_early_exit = True
    state.pc_f1_abort = True
    pc_register_speed_hotkeys(False)
    log.info("Popcorn: stop requested")


_F10_NAMES = {1: "All", 2: "+Transfer"}


def _f10_update_status(text: str):
    try:
        from gui.tab_joinsim import update_f10_status
        update_f10_status(text)
    except Exception:
        pass


def _pc_tooltip(text: str | None = None):
    # Guards against a race where the tooltip show is queued via root.after()
    # but F1's _stop_flags() runs hide_all() before the queued show executes.
    # Uses a generation counter: _stop_flags increments pc_tooltip_gen, and the
    # queued callback checks if gen still matches — if not, F1 cancelled it.
    try:
        from gui.tooltip import show_tooltip, hide_tooltip
        if text:
            gen = state.pc_tooltip_gen
            root = getattr(state, "root", None)
            if root is None:
                return
            def _show():
                if state.pc_tooltip_gen != gen:
                    return  # F1 fired between queue and execute
                show_tooltip(text, 0, 0)
            root.after(0, _show)
        else:
            hide_tooltip()
    except Exception:
        pass


def pc_f10_cycle():
    if state.pc_f10_step == 0:
        from core.config import read_ini
        saved_drop = read_ini("Popcorn", "DropKey", "")
        if not saved_drop:
            try:
                tab_pc = getattr(state, "_tab_popcorn", None)
                if tab_pc and state.root:
                    state.root.after(0, tab_pc._show_set_keys_prompt)
            except Exception:
                pass
            return

    if state.ob_upload_armed or state.ob_upload_running:
        from modules.ob_upload import ob_stop_all
        ob_stop_all()
    if state.ob_download_armed or state.ob_download_running:
        from modules.ob_download import ob_down_stop_all
        ob_down_stop_all(hide_gui=False)
    if state.gmk_mode != "off":
        state.gmk_mode = "off"
        try:
            from gui.tab_joinsim import update_gmk_status
            update_gmk_status("")
        except Exception:
            pass

    state.pc_f10_step = (state.pc_f10_step + 1) % 3

    state.pc_grinder_poly = False
    state.pc_grinder_metal = False
    state.pc_grinder_crystal = False
    state.pc_preset_raw = False
    state.pc_preset_cooked = False
    state.pc_all_custom_active = False
    state.pc_all_no_filter = False

    if state.pc_f10_step == 0:
        state.pc_mode = 0
        state.pc_custom_filter = ""
        _f10_update_status("")
        _pc_tooltip(" Popcorning Off")
        from core.timers import timers
        timers.set_timer("f10_tip_off", lambda: _pc_tooltip(None), -1500)
        if state.main_gui and not state.gui_visible:
            state.gui_visible = True
            state.root.after(0, state.main_gui.show)
    elif state.pc_f10_step == 1:
        state.pc_mode = 3
        state.pc_custom_filter = ""
        state.pc_forge_transfer_all = False
        _f10_update_status("All")
        speed_name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
        _pc_tooltip(
            f" F10 Quick: All (no filter)  |  F at inventory  |  Q = Stop  |  F1 = Stop/UI\n"
            f"Z = Change drop speed  |  Speed: {speed_name}"
        )
        if state.main_gui and state.gui_visible:
            state.gui_visible = False
            state.root.after(0, state.main_gui.hide)
    elif state.pc_f10_step == 2:
        state.pc_mode = 3
        state.pc_custom_filter = ""
        state.pc_forge_transfer_all = True
        _f10_update_status("+Transfer")
        speed_name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
        _pc_tooltip(
            f" F10 Quick: +Transfer  |  F at inventory  |  Q = Stop  |  F1 = Stop/UI\n"
            f"Z = Change drop speed  |  Speed: {speed_name}"
        )

    _pc_log(f"F10 cycle: step={state.pc_f10_step}")


def pc_register_speed_hotkeys(enable: bool = True):
    try:
        hk = state._hotkey_mgr
    except AttributeError:
        return

    if enable:
        try:
            hk.register("z", pc_hotkey_speed, suppress=True)
        except Exception:
            pass
        if not getattr(state, "autoclicking", False):
            try:
                hk.register("[", pc_hotkey_bracket_left, suppress=True)
                hk.register("]", pc_hotkey_bracket_right, suppress=True)
            except Exception:
                pass
    else:
        try:
            hk.unregister("z", pc_hotkey_speed)
        except Exception:
            pass
        if not getattr(state, "autoclicking", False):
            try:
                hk.unregister("[", pc_hotkey_bracket_left)
                hk.unregister("]", pc_hotkey_bracket_right)
            except Exception:
                pass


def pc_hotkey_speed():
    pc_cycle_speed()
    pc_save_speed_to_ini()
    pc_update_f10_speed()
    pc_show_armed_tooltip()
    _pc_log(f"Z speed cycle → {state.pc_speed_names.get(state.pc_speed_mode, '?')}")


def pc_hotkey_bracket_left():
    pc_adjust_drop_sleep(-1)


def pc_hotkey_bracket_right():
    pc_adjust_drop_sleep(1)


def pc_save_speed_to_ini():
    from core.config import write_ini
    write_ini("Popcorn", "SpeedMode", str(state.pc_speed_mode))
    write_ini("Popcorn", "DropSleep", str(state.pc_drop_sleep))
    write_ini("Popcorn", "CycleSleep", str(state.pc_cycle_sleep))
    write_ini("Popcorn", "HoverDelay", str(state.pc_hover_delay))


def pc_load_scan_area():
    from core.config import read_ini
    wm = state.width_multiplier or 1
    hm = state.height_multiplier or 1

    for key, attr, mult in [
        ("StorageScanX", "pc_storage_scan_x", wm),
        ("StorageScanY", "pc_storage_scan_y", hm),
        ("StorageScanW", "pc_storage_scan_w", wm),
        ("StorageScanH", "pc_storage_scan_h", hm),
        ("WeightNX", "pc_weight_n_x", wm),
        ("WeightNY", "pc_weight_n_y", hm),
        ("WeightNW", "pc_weight_n_w", wm),
        ("WeightNH", "pc_weight_n_h", hm),
        ("WeightOX", "pc_weight_o_x", wm),
        ("WeightOY", "pc_weight_o_y", hm),
        ("WeightOW", "pc_weight_o_w", wm),
        ("WeightOH", "pc_weight_o_h", hm),
    ]:
        val = read_ini("Popcorn", key, "")
        if val and val != "Default":
            try:
                setattr(state, attr, round(int(val) * mult))
            except (ValueError, TypeError):
                pass


def pc_set_status(msg: str):
    try:
        tab = getattr(state, "_tab_popcorn", None)
        if tab and hasattr(tab, "status_txt"):
            root = getattr(state, "root", None)
            if root:
                root.after(0, lambda: tab.status_txt.configure(text=msg))
    except Exception:
        pass


def pc_update_f10_speed():
    try:
        tab = getattr(state, "_tab_popcorn", None)
        if not tab:
            return
        root = getattr(state, "root", None)
        if not root:
            return

        speed_colors = {0: "#FFAA00", 1: "#FF4444", 2: "#FF2222"}
        name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
        color = speed_colors.get(state.pc_speed_mode, "#FF4444")

        def _update():
            if state.pc_mode > 0:
                if hasattr(tab, "f10_speed_txt"):
                    tab.f10_speed_txt.configure(text=name, fg=color)
                if hasattr(tab, "speed_txt"):
                    tab.speed_txt.configure(text=f"{name} [Z]")
            else:
                if hasattr(tab, "f10_speed_txt"):
                    tab.f10_speed_txt.configure(text="")

        root.after(0, _update)
    except Exception:
        pass


def pc_show_armed_tooltip():
    if state.pc_f10_step > 0:
        _pc_tooltip(pc_build_f10_tooltip())
    elif state.pc_mode > 0:
        _pc_tooltip(pc_build_tooltip())
    else:
        _pc_tooltip(None)


def pc_build_f10_tooltip() -> str:
    f10_names = {1: "All (no filter)", 2: "Transfer"}
    name = f10_names.get(state.pc_f10_step, "")
    if not name:
        return ""
    speed_name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
    return (
        f" F10 Quick: {name}  |  F at inventory  |  Q = Stop  |  F1 = Stop/UI\n"
        f" Z = Change drop speed  |  Speed: {speed_name}"
    )


def pc_adjust_drop_sleep(direction: int):
    step = 2
    state.pc_drop_sleep = max(1, state.pc_drop_sleep + direction * step)
    log.debug("Drop sleep adjusted to %d", state.pc_drop_sleep)
    try:
        from gui.tooltip import show_tooltip
        show_tooltip(f" Drop sleep: {state.pc_drop_sleep}ms  (\u00b1{step}ms)")
    except Exception:
        pass
    try:
        from core.config import write_ini
        write_ini("Popcorn", "DropSleep", str(state.pc_drop_sleep))
    except Exception:
        pass
