
import re
import time
import threading
import logging

from core.state import state
from input.pixel import px_get, pixel_search, is_color_similar
from input.mouse import mouse_move, click as mouse_click
from input.keyboard import send, send_text_vk, key_press, key_down, key_up, control_send
from input.window import win_exist, control_click
from input.ocr import from_rect as ocr_from_rect
from modules.nvidia_filter import nf_pixel_wait

log = logging.getLogger(__name__)


def craft_log(msg: str):
    ts = time.strftime("%H:%M:%S")
    state.ac_log.append(f"{ts} {msg}")
    if len(state.ac_log) > 200:
        state.ac_log.pop(0)
    log.debug(msg)


def _ark_send_f():
    hwnd = win_exist(state.ark_window)
    if hwnd:
        control_send(hwnd, "{f}")


def ac_wait_for_inventory(max_ms: int = 6000) -> bool:
    wm = state.width_multiplier
    hm = state.height_multiplier
    px1 = round(1943 * wm)
    py1 = round(215 * hm)

    diag_col = px_get(px1, py1)
    craft_log(f"WaitForInv: color at ({px1},{py1}) = 0x{diag_col:06X}")

    interval = 0.016
    max_polls = max_ms // 16
    baseline = 0
    for _ in range(max_polls):
        x1 = px1 - 2
        y1 = py1 - 2
        x2 = px1 + 2
        y2 = py1 + 2
        matched, baseline = nf_pixel_wait(x1, y1, x2, y2, 0xFFFFFF, 10,
                                          baseline)
        if matched:
            return True
        time.sleep(interval)

    diag_col2 = px_get(px1, py1)
    craft_log(f"WaitForInv: TIMEOUT — color now = 0x{diag_col2:06X}")
    return False


def ac_take_all_if_enabled(filter_text: str):
    if not getattr(state, "take_all_enabled", False):
        return
    craft_log(f"TakeAll: transferring [{filter_text}] to me")

    ark_hwnd = win_exist(state.ark_window)
    if not ark_hwnd:
        return

    control_click(ark_hwnd,
                  int(state.their_inv_search_bar_x),
                  int(state.their_inv_search_bar_y))
    time.sleep(0.030)
    send_text_vk(filter_text)
    time.sleep(0.100)
    control_click(ark_hwnd,
                  int(state.transfer_to_me_btn_x),
                  int(state.transfer_to_me_btn_y))
    time.sleep(0.150)


def ac_feed_if_due():
    now_ms = time.monotonic() * 1000
    if now_ms - state.ac_feed_last_ms < state.ac_feed_interval_ms:
        return

    ark_hwnd = win_exist(state.ark_window)
    if not ark_hwnd:
        return

    send("{9}")
    time.sleep(0.150)
    send("{0}")
    time.sleep(0.150)
    state.ac_feed_last_ms = now_ms


def _ocr_read_slots() -> int:
    attempts = 0
    while attempts < 3:
        attempts += 1
        try:
            text = ocr_from_rect(
                state.ac_ocr_snap_x, state.ac_ocr_snap_y,
                state.ac_ocr_snap_w, state.ac_ocr_snap_h,
                scale=3,
            )
            cleaned = text.replace("o", "0").replace("O", "0")
            cleaned = re.sub(r"[Il|]", "1", cleaned)
            cleaned = re.sub(r"s(?=\d)", "5", cleaned)
            cleaned = cleaned.replace(",", "")

            m = re.search(r"(-?\d+)\s*/\s*(\d+)", cleaned)
            if m:
                val = int(m.group(1))
                if val < 0:
                    val = 0
                if val == 0 and len(m.group(1)) > 1:
                    craft_log(
                        f"GridOCR: suspicious 0 from [{m.group(1)}] "
                        f"({len(m.group(1))} digits) — retrying  raw=[{text}]"
                    )
                    time.sleep(0.080)
                    continue
                craft_log(
                    f"GridOCR: raw=[{text}] cleaned=[{cleaned}] "
                    f"val={val}/{m.group(2)} attempt {attempts}"
                )
                return val

            m = re.search(r"(\d+)", cleaned)
            if m:
                val = int(m.group(1))
                craft_log(
                    f"GridOCR: raw=[{text}] cleaned=[{cleaned}] "
                    f"val={val} (no slash) attempt {attempts}"
                )
                return val

            craft_log(
                f"GridOCR: no number found raw=[{text}] "
                f"cleaned=[{cleaned}] attempt {attempts}"
            )
        except Exception as exc:
            craft_log(f"GridOCR: OCR failed attempt {attempts} — {exc}")
        time.sleep(0.100)

    craft_log(f"GridOCR: no valid reading after {attempts} attempts")
    return -1


def ac_ocr_read_storage():
    slot_count = _ocr_read_slots()
    if slot_count < 0:
        return

    s_key = state.ac_ocr_current_station
    station_map = state.ac_ocr_station_map

    if s_key in station_map:
        prev_slots = station_map[s_key]
        delta = max(0, slot_count - prev_slots)
        station_map[s_key] = slot_count
        items = delta * 100
        state.ac_ocr_total += items
        craft_log(
            f"GridOCR: station {s_key} slots={slot_count} prev={prev_slots} "
            f"delta={delta} x100={items} -> total={state.ac_ocr_total}"
        )
    else:
        station_map[s_key] = slot_count
        items = slot_count * 100
        state.ac_ocr_total += items
        state.ac_ocr_stations += 1
        craft_log(
            f"GridOCR: station {s_key} slots={slot_count} (first visit) "
            f"x100={items} -> total={state.ac_ocr_total} "
            f"stations={state.ac_ocr_stations}"
        )

    ac_ocr_update_count_tooltip()


def _craft_sequence(filter_text: str):
    wm = state.width_multiplier
    hm = state.height_multiplier

    ac_take_all_if_enabled(filter_text)

    mouse_click(round(1692 * wm), round(267 * hm))
    time.sleep(0.080)

    key_down("ctrl")
    key_press("a")
    key_up("ctrl")
    time.sleep(0.040)
    send_text_vk(filter_text)
    time.sleep(0.150)

    mouse_click(round(1664 * wm), round(379 * hm))
    time.sleep(0.050)

    for _ in range(16 + state.ac_extra_clicks):
        if state.ac_early_exit:
            break
        send("{a}")
        time.sleep(0.030)
    time.sleep(0.050)

    if state.ac_ocr_enabled and state.ac_grid_running:
        time.sleep(0.200)
        ac_ocr_read_storage()


def ac_do_craft(filter_text: str) -> bool:
    start = time.perf_counter()
    craft_log(f"DoCraft: sending F, filter=[{filter_text}]")

    _ark_send_f()

    if not ac_wait_for_inventory():
        elapsed = (time.perf_counter() - start) * 1000
        craft_log(f"DoCraft: pixel not found — aborting +{elapsed:.0f}ms")
        if not state.ac_grid_running:
            log.info("AutoCraft: waiting for inventory...")
        time.sleep(0.500)
        return False

    elapsed = (time.perf_counter() - start) * 1000
    craft_log(f"DoCraft: pixel found +{elapsed:.0f}ms")

    _craft_sequence(filter_text)

    _ark_send_f()
    time.sleep(0.300)

    elapsed = (time.perf_counter() - start) * 1000
    craft_log(f"DoCraft: complete +{elapsed:.0f}ms")
    return True


def _do_craft_already_open(filter_text: str) -> bool:
    craft_log(f"DoCraftAlreadyOpen: waiting for inventory pixel, filter=[{filter_text}]")
    if not ac_wait_for_inventory():
        craft_log("DoCraftAlreadyOpen: pixel not found — aborting")
        if not state.ac_grid_running:
            log.info("AutoCraft: waiting for inventory...")
        time.sleep(0.500)
        return False

    craft_log("DoCraftAlreadyOpen: pixel found — proceeding")
    _craft_sequence(filter_text)

    _ark_send_f()
    time.sleep(0.300)
    return True


def _get_current_filter() -> str:
    if not state.ac_preset_filters:
        return ""
    idx = state.ac_preset_idx - 1
    if 0 <= idx < len(state.ac_preset_filters):
        return state.ac_preset_filters[idx]
    return ""


def ac_start_simple():
    if not state.ac_preset_names:
        from gui.tooltip import temp_tooltip
        temp_tooltip(" AutoCraft: choose a preset or enter a filter first", 2000)
        return

    state.ac_simple_armed = not state.ac_simple_armed

    if state.ac_simple_armed:
        state.gui_visible = False
        from gui.tooltip import show_tooltip
        show_tooltip(ac_build_craft_tooltip("Simple"), 0, 0)
        log.info("Simple craft armed — press F at inventory")
    else:
        state.gui_visible = True
        from gui.tooltip import hide_tooltip
        hide_tooltip()
        log.info("Simple craft disarmed")


def ac_do_simple_craft():
    if not state.ac_simple_armed or not state.ac_tab_active:
        return

    filter_text = _get_current_filter()
    if not filter_text:
        return

    if state.ac_craft_loop_running:
        state.ac_running = True
        state.ac_early_exit = False
        craft_log(f"SimpleLoop: sending F, filter=[{filter_text}]")
        _ark_send_f()
        if not ac_wait_for_inventory():
            craft_log("SimpleLoop: inventory not found — aborting")
            state.ac_running = False
            state.ac_craft_loop_running = False
            time.sleep(0.500)
            return

        wm = state.width_multiplier
        hm = state.height_multiplier
        mouse_click(round(1692 * wm), round(267 * hm))
        time.sleep(0.080)
        key_down("ctrl")
        key_press("a")
        key_up("ctrl")
        time.sleep(0.040)
        send_text_vk(filter_text)
        time.sleep(0.150)
        mouse_click(round(1664 * wm), round(379 * hm))
        time.sleep(0.050)

        while not state.ac_early_exit:
            for _ in range(16 + state.ac_extra_clicks):
                if state.ac_early_exit:
                    break
                send("{a}")
                time.sleep(0.030)
            time.sleep(0.200)

        _ark_send_f()
        time.sleep(0.300)
        craft_log("SimpleLoop: stopped")
        state.ac_running = False
        state.ac_early_exit = False
        state.ac_craft_loop_running = False
        state.ac_simple_armed = False
        state.gui_visible = True
    else:
        state.ac_early_exit = False
        ac_do_craft(filter_text)


def ac_start_timed(timer_secs: int = 120):
    if not state.ac_preset_names:
        from gui.tooltip import temp_tooltip
        temp_tooltip(" AutoCraft: choose a preset or enter a filter first", 2000)
        return

    filter_text = _get_current_filter()
    state.ac_active_filter = filter_text
    state.ac_active_timer_secs = timer_secs
    idx = state.ac_preset_idx - 1
    if 0 <= idx < len(state.ac_preset_names):
        state.ac_active_item_name = state.ac_preset_names[idx]

    state.ac_timed_f_pressed = False

    if state.ac_running:
        state.ac_timed_restart = True
        state.ac_early_exit = True
    else:
        state.ac_early_exit = False
        state.ac_simple_armed = False
        state.ac_grid_armed = False
        state.ac_timed_armed = True
        state.gui_visible = False
        from gui.tooltip import show_tooltip
        show_tooltip(ac_build_craft_tooltip("Timed"), 0, 0)
        log.info("Timed craft armed — %s (%ds)", state.ac_active_item_name, timer_secs)


def ac_timed_loop():
    if state.ac_craft_loop_running:
        _timed_loop_craft_loop()
        return

    if len(state.ac_preset_names) > 1:
        _timed_multi_loop()
        return

    from gui.tooltip import show_tooltip, hide_tooltip, update_tooltip

    craft_log(f"TimedLoop: crafting {state.ac_active_item_name} filter=[{state.ac_active_filter}]")
    _do_craft_already_open(state.ac_active_filter)
    craft_log("TimedLoop: craft done")

    if state.ac_early_exit:
        state.ac_running = False
        state.ac_early_exit = False
        if state.ac_timed_restart:
            state.ac_timed_restart = False
            state.ac_timed_armed = True
            state.ac_timed_f_pressed = False
            show_tooltip(ac_build_craft_tooltip("Timed"), 0, 0)
        else:
            hide_tooltip()
            state.gui_visible = True
        return

    state.ac_timed_f_pressed = False
    deadline = time.perf_counter() + state.ac_active_timer_secs

    while not state.ac_early_exit:
        if state.ac_timed_f_pressed:
            state.ac_timed_f_pressed = False
            craft_log(f"TimedLoop: F pressed — crafting {state.ac_active_item_name}")
            _do_craft_already_open(state.ac_active_filter)
            if state.ac_early_exit:
                break
            if time.perf_counter() >= deadline:
                deadline = time.perf_counter() + state.ac_active_timer_secs

        remaining = max(0, int(deadline - time.perf_counter()))
        if remaining <= 0:
            status = "READY"
        else:
            m, s = divmod(remaining, 60)
            status = f"{m}:{s:02d}"
        update_tooltip(
            f"\u25ba {state.ac_active_item_name}  {status}\n"
            f"Q = Stop  |  F = Craft  |  F1 = Stop")
        time.sleep(0.250)

    state.ac_running = False
    state.ac_early_exit = False
    if state.ac_timed_restart:
        state.ac_timed_restart = False
        state.ac_timed_armed = True
        state.ac_timed_f_pressed = False
        show_tooltip(ac_build_craft_tooltip("Timed"), 0, 0)
    else:
        hide_tooltip()
        state.gui_visible = True


def _timed_loop_craft_loop():
    state.ac_craft_loop_running = True
    craft_log(f"TimedLoop(loop): crafting {state.ac_active_item_name} filter=[{state.ac_active_filter}]")
    _ark_send_f()
    if not ac_wait_for_inventory():
        craft_log("TimedLoop(loop): inventory not found — aborting")
        state.ac_running = False
        state.ac_craft_loop_running = False
        time.sleep(0.500)
        return

    wm = state.width_multiplier
    hm = state.height_multiplier
    mouse_click(round(1692 * wm), round(267 * hm))
    time.sleep(0.080)
    key_down("ctrl")
    key_press("a")
    key_up("ctrl")
    time.sleep(0.040)
    send_text_vk(state.ac_active_filter)
    time.sleep(0.150)
    mouse_click(round(1664 * wm), round(379 * hm))
    time.sleep(0.050)

    while not state.ac_early_exit:
        for _ in range(16 + state.ac_extra_clicks):
            if state.ac_early_exit:
                break
            send("{a}")
            time.sleep(0.030)
        time.sleep(0.200)

    _ark_send_f()
    time.sleep(0.300)
    craft_log("TimedLoop(loop): stopped")
    state.ac_running = False
    state.ac_early_exit = False
    state.ac_craft_loop_running = False
    state.gui_visible = True


def _timed_multi_loop():
    from gui.tooltip import show_tooltip, hide_tooltip, update_tooltip

    state.ac_timed_multi_active = True

    state.ac_timed_deadlines = [0] * len(state.ac_preset_names)

    idx = state.ac_preset_idx - 1
    filter_text = state.ac_preset_filters[idx]
    craft_log(f"TimedMulti: crafting {state.ac_preset_names[idx]} filter=[{filter_text}]")
    _do_craft_already_open(filter_text)
    craft_log("TimedMulti: craft done")

    if state.ac_early_exit:
        _timed_multi_cleanup()
        return

    timer_secs = state.ac_preset_timer_secs[idx] if idx < len(state.ac_preset_timer_secs) else 120
    state.ac_timed_deadlines[idx] = time.perf_counter() + timer_secs

    state.ac_timed_f_pressed = False
    while not state.ac_early_exit:
        if state.ac_timed_f_pressed:
            state.ac_timed_f_pressed = False
            idx = state.ac_preset_idx - 1
            craft_log(f"TimedMulti: F pressed — crafting {state.ac_preset_names[idx]}")
            _do_craft_already_open(state.ac_preset_filters[idx])
            if state.ac_early_exit:
                break
            t_secs = state.ac_preset_timer_secs[idx] if idx < len(state.ac_preset_timer_secs) else 120
            dl = state.ac_timed_deadlines[idx]
            if dl == 0 or time.perf_counter() >= dl:
                state.ac_timed_deadlines[idx] = time.perf_counter() + t_secs

        lines = []
        for i, name in enumerate(state.ac_preset_names):
            arrow = "\u25ba" if i == (state.ac_preset_idx - 1) else "  "
            dl = state.ac_timed_deadlines[i]
            if dl == 0:
                status = "--:--"
            else:
                remaining = max(0, int(dl - time.perf_counter() + 0.999))
                if remaining <= 0:
                    status = "READY"
                else:
                    m, s = divmod(remaining, 60)
                    status = f"{m}:{s:02d}"
            lines.append(f"{arrow} {name}  {status}")
        lines.append("Q = Cycle  |  F = Craft  |  F1 = Stop")
        update_tooltip("\n".join(lines))

        time.sleep(0.250)

    _timed_multi_cleanup()


def _timed_multi_cleanup():
    from gui.tooltip import show_tooltip, hide_tooltip

    state.ac_timed_multi_active = False
    state.ac_running = False
    state.ac_early_exit = False

    if state.ac_timed_restart:
        state.ac_timed_restart = False
        state.ac_timed_armed = True
        state.ac_timed_f_pressed = False
        show_tooltip(ac_build_craft_tooltip("Timed"), 0, 0)
    else:
        hide_tooltip()
        state.gui_visible = True


def _grid_move(key_down_name: str, key_up_name: str, delay_ms: int):
    if state.ac_early_exit:
        return
    key_down(key_down_name)
    time.sleep(delay_ms / 1000.0)
    key_up(key_up_name)
    time.sleep(0.150)


def ac_start_grid(cols: int = 1, rows: int = 1,
                  h_walk: int = 850, v_walk: int = 850):
    if not state.ac_preset_names:
        from gui.tooltip import temp_tooltip
        temp_tooltip(" AutoCraft: choose a preset or enter a filter first", 2000)
        return

    state.ac_simple_armed = False
    state.ac_timed_armed = False
    state.ac_count_only_active = False
    state.ac_grid_cols = cols
    state.ac_grid_rows = rows
    state.ac_grid_hwalk = h_walk
    state.ac_grid_vwalk = v_walk

    if state.ac_running:
        state.ac_grid_restart = True
        state.ac_early_exit = True
    else:
        state.ac_early_exit = False
        state.ac_grid_armed = True
        state.ac_feed_last_ms = time.monotonic() * 1000
        state.gui_visible = False
        from gui.tooltip import show_tooltip
        show_tooltip(ac_build_craft_tooltip("Grid"), 0, 0)
        log.info("Grid craft armed — %dx%d", cols, rows)


def ac_grid_loop(cols: int = 1, rows: int = 1,
                 h_walk: int = 850, v_walk: int = 850):
    # GUI labels are swapped: GUI "Cols" = forward/back rows (W/S),
    # GUI "Rows" = side columns (A/D). Walk delays also swapped.
    rows, cols = cols, rows
    h_walk, v_walk = v_walk, h_walk

    back_ratio = 1.53
    first_craft = True

    state.ac_ocr_total = 0
    state.ac_ocr_stations = 0
    state.ac_ocr_station_map = {}
    state.ac_ocr_current_station = 0

    while state.ac_running and not state.ac_early_exit:
        station_idx = 0

        for r in range(rows):
            if state.ac_early_exit:
                break

            if r % 2 == 0:
                c = cols - 1
                while c >= 0 and not state.ac_early_exit:
                    filter_text = _get_current_filter()
                    state.ac_ocr_current_station = station_idx

                    if first_craft:
                        _do_craft_already_open(filter_text)
                        first_craft = False
                    else:
                        ac_do_craft(filter_text)

                    station_idx += 1
                    from gui.tooltip import show_tooltip
                    show_tooltip(ac_build_craft_tooltip("Grid"), 0, 0)
                    ac_feed_if_due()

                    if c > 0 and not state.ac_early_exit:
                        _grid_move("a", "a", h_walk)
                    c -= 1
            else:
                c = 0
                while c < cols and not state.ac_early_exit:
                    filter_text = _get_current_filter()
                    state.ac_ocr_current_station = station_idx

                    ac_do_craft(filter_text)
                    station_idx += 1
                    from gui.tooltip import show_tooltip
                    show_tooltip(ac_build_craft_tooltip("Grid"), 0, 0)
                    ac_feed_if_due()

                    if c < cols - 1 and not state.ac_early_exit:
                        _grid_move("d", "d", h_walk)
                    c += 1

            if r < rows - 1 and not state.ac_early_exit:
                _grid_move("w", "w", v_walk)

        if not state.ac_early_exit:
            ended_left = (rows % 2) == 1
            if ended_left:
                for _ in range(cols - 1):
                    _grid_move("d", "d", h_walk)
            if rows > 1:
                _grid_move("s", "s", round(v_walk * (rows - 1) * back_ratio))

    state.ac_running = False
    state.ac_early_exit = False
    state.ac_grid_running = False

    if state.ac_grid_restart:
        state.ac_grid_restart = False
        state.ac_grid_running = True
        state.ac_grid_armed = True
        state.ac_feed_last_ms = time.monotonic() * 1000
        state.ac_ocr_total = 0
        state.ac_ocr_stations = 0
        state.ac_ocr_station_map = {}
        state.ac_ocr_current_station = 0
    else:
        state.gui_visible = True


def _ocr_resize_register():
    hk = getattr(state, "_hotkey_mgr", None)
    if not hk:
        return
    hk.register("up",    ac_ocr_size_up,    suppress=True)
    hk.register("down",  ac_ocr_size_down,  suppress=True)
    hk.register("left",  ac_ocr_size_left,  suppress=True)
    hk.register("right", ac_ocr_size_right, suppress=True)
    hk.register("w",     ac_ocr_move_up,    suppress=True)
    hk.register("s",     ac_ocr_move_down,  suppress=True)
    hk.register("a",     ac_ocr_move_left,  suppress=True)
    hk.register("d",     ac_ocr_move_right, suppress=True)
    hk.register("enter", ac_ocr_resize_done, suppress=True)


def _ocr_resize_unregister():
    hk = getattr(state, "_hotkey_mgr", None)
    if not hk:
        return
    hk.unregister("up",    ac_ocr_size_up)
    hk.unregister("down",  ac_ocr_size_down)
    hk.unregister("left",  ac_ocr_size_left)
    hk.unregister("right", ac_ocr_size_right)
    hk.unregister("w",     ac_ocr_move_up)
    hk.unregister("s",     ac_ocr_move_down)
    hk.unregister("a",     ac_ocr_move_left)
    hk.unregister("d",     ac_ocr_move_right)
    hk.unregister("enter", ac_ocr_resize_done)


def ac_ocr_toggle_resize():
    if state.ac_ocr_resizing:
        ac_ocr_exit_resize()
        return

    if getattr(state, "ob_ocr_resizing", False) or getattr(state, "imprint_resizing", False):
        return

    state.ac_ocr_resizing = True
    ac_ocr_show_overlay()
    _ocr_resize_register()
    _ac_tooltip(
        " OCR Resize: WASD=move  Arrows=size  Enter=done"
    )
    craft_log("[OCR-RESIZE] entered")


def ac_ocr_exit_resize():
    _ocr_resize_unregister()
    state.ac_ocr_resizing = False
    ac_ocr_hide_overlay()
    ac_ocr_save_config()
    ac_ocr_update_size_txt()
    _ac_tooltip(None)
    craft_log("[OCR-RESIZE] exited")


def ac_ocr_resize_done():
    ac_ocr_exit_resize()


def ac_ocr_size_up():
    state.ac_ocr_snap_h = max(20, state.ac_ocr_snap_h + 10)
    ac_ocr_show_overlay()
    ac_ocr_update_size_txt()


def ac_ocr_size_down():
    state.ac_ocr_snap_h = max(20, state.ac_ocr_snap_h - 10)
    ac_ocr_show_overlay()
    ac_ocr_update_size_txt()


def ac_ocr_size_right():
    state.ac_ocr_snap_w = max(40, state.ac_ocr_snap_w + 20)
    ac_ocr_show_overlay()
    ac_ocr_update_size_txt()


def ac_ocr_size_left():
    state.ac_ocr_snap_w = max(40, state.ac_ocr_snap_w - 20)
    ac_ocr_show_overlay()
    ac_ocr_update_size_txt()


def ac_ocr_move_up():
    state.ac_ocr_snap_y = max(0, state.ac_ocr_snap_y - 10)
    ac_ocr_show_overlay()


def ac_ocr_move_down():
    from core.scaling import screen_height
    state.ac_ocr_snap_y = min(screen_height - state.ac_ocr_snap_h,
                              state.ac_ocr_snap_y + 10)
    ac_ocr_show_overlay()


def ac_ocr_move_left():
    state.ac_ocr_snap_x = max(0, state.ac_ocr_snap_x - 10)
    ac_ocr_show_overlay()


def ac_ocr_move_right():
    from core.scaling import screen_width
    state.ac_ocr_snap_x = min(screen_width - state.ac_ocr_snap_w,
                              state.ac_ocr_snap_x + 10)
    ac_ocr_show_overlay()


def ac_ocr_update_size_txt():
    craft_log(f"[OCR-RESIZE] {state.ac_ocr_snap_w}x{state.ac_ocr_snap_h} "
              f"at ({state.ac_ocr_snap_x},{state.ac_ocr_snap_y})")


def ac_ocr_show_overlay():
    # Must marshal to main thread — tkinter Toplevel creation requires it
    root = getattr(state, "root", None)
    if root is None:
        return

    def _do():
        ac_ocr_hide_overlay()
        try:
            from gui.overlay import show_rect_overlay
            state.ac_ocr_overlay = show_rect_overlay(
                state.ac_ocr_snap_x, state.ac_ocr_snap_y,
                state.ac_ocr_snap_w, state.ac_ocr_snap_h,
                color="cyan", border=2,
            )
        except Exception:
            pass

    root.after(0, _do)


def ac_ocr_hide_overlay():
    if state.ac_ocr_overlay is not None:
        try:
            from gui.overlay import hide_rect_overlay
            hide_rect_overlay(state.ac_ocr_overlay)
        except Exception:
            pass
        state.ac_ocr_overlay = None


def _ac_tooltip(text: str | None):
    try:
        if text:
            from gui.tooltip import show_tooltip
            show_tooltip(text)
        else:
            from gui.tooltip import hide_tooltip
            hide_tooltip()
    except Exception:
        pass


def ac_ocr_save_config():
    from core.config import write_ini
    write_ini("GridOCR", "Enabled", "1" if state.ac_ocr_enabled else "0")
    write_ini("GridOCR", "X", str(state.ac_ocr_snap_x))
    write_ini("GridOCR", "Y", str(state.ac_ocr_snap_y))
    write_ini("GridOCR", "W", str(state.ac_ocr_snap_w))
    write_ini("GridOCR", "H", str(state.ac_ocr_snap_h))


def ac_ocr_load_config():
    from core.config import read_ini
    val = read_ini("GridOCR", "Enabled", "0")
    state.ac_ocr_enabled = val in ("1", "true", "True")

    x = read_ini("GridOCR", "X", "")
    y = read_ini("GridOCR", "Y", "")
    w = read_ini("GridOCR", "W", "")
    h = read_ini("GridOCR", "H", "")
    if x:
        try:
            state.ac_ocr_snap_x = int(x)
        except ValueError:
            pass
    if y:
        try:
            state.ac_ocr_snap_y = int(y)
        except ValueError:
            pass
    if w:
        try:
            v = int(w)
            if v >= 40:
                state.ac_ocr_snap_w = v
        except ValueError:
            pass
    if h:
        try:
            v = int(h)
            if v >= 20:
                state.ac_ocr_snap_h = v
        except ValueError:
            pass


def ac_ocr_read_slots() -> int:
    for attempt in range(3):
        try:
            text = ocr_from_rect(state.ac_ocr_snap_x, state.ac_ocr_snap_y,
                                 state.ac_ocr_snap_w, state.ac_ocr_snap_h,
                                 scale=3)
            if not text:
                time.sleep(0.100)
                continue

            corrected = text
            corrected = re.sub(r"[oO]", "0", corrected)
            corrected = re.sub(r"[Il|]", "1", corrected)
            corrected = re.sub(r"s(?=\d)", "5", corrected)
            corrected = corrected.replace(",", "")

            craft_log(f"[OCR-SLOTS#{attempt}] raw='{text[:60]}' corrected='{corrected[:60]}'")

            m = re.search(r"(-?\d+)\s*/\s*(\d+)", corrected)
            if m:
                val = int(m.group(1))
                if val < 0:
                    val = 0
                # Suspicious single "0" from long text — likely misread
                if val == 0 and len(corrected.strip()) > 3:
                    time.sleep(0.100)
                    continue
                return val

            m2 = re.search(r"(\d+)", corrected)
            if m2:
                return int(m2.group(1))

        except Exception as e:
            craft_log(f"[OCR-SLOTS#{attempt}] error: {e}")

        time.sleep(0.100)

    return -1


def ac_ocr_read_storage_count_only():
    slots = ac_ocr_read_slots()
    if slots < 0:
        craft_log("[COUNT-ONLY] OCR failed")
        return

    items = slots * 100
    state.ac_ocr_total += items
    state.ac_ocr_stations += 1
    craft_log(f"[COUNT-ONLY] station #{state.ac_ocr_stations}: {slots} slots = {items} items, "
              f"total = {state.ac_ocr_total}")
    ac_ocr_update_count_tooltip()


def ac_ocr_format_total() -> str:
    total = int(state.ac_ocr_total)
    if total < 1000:
        return str(total)
    formatted = f"{total:,}"
    if total >= 1_000_000:
        millions = round(total / 1_000_000, 1)
        formatted += f" ({millions}m)"
    return formatted


def ac_ocr_update_count_tooltip():
    # Uses tooltip ID 2 at y=58 — a separate tooltip below the main one
    from gui.tooltip import show_tooltip, hide_tooltip
    if not state.ac_ocr_enabled and not state.ac_count_only_active:
        hide_tooltip(tooltip_id=2)
        return
    formatted = ac_ocr_format_total()
    show_tooltip(f" Storage: {formatted}  ({state.ac_ocr_stations} stations)",
                 0, 58, tooltip_id=2)


def ac_ocr_reset_total():
    state.ac_ocr_total = 0
    state.ac_ocr_stations = 0
    state.ac_ocr_station_map = {}
    state.ac_ocr_current_station = 0


def ac_count_only_f_pressed():
    if not state.ac_count_only_active:
        return

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return

    if not ac_wait_for_inventory(6000):
        craft_log("[COUNT-ONLY] inventory not detected, aborting")
        return

    ac_ocr_read_storage_count_only()
    ac_ocr_update_count_tooltip()


def ac_tally_toggle():
    state.ac_count_only_active = not state.ac_count_only_active

    if state.ac_count_only_active:
        state.ac_ocr_enabled = False
        state.ac_simple_armed = False
        state.ac_timed_armed = False
        state.ac_grid_armed = False
        if state.ac_running:
            state.ac_early_exit = True

        ac_ocr_reset_total()
        state.gui_visible = False
        from gui.tooltip import show_tooltip
        show_tooltip(" Count: F at each inventory  |  Count again to stop", 0, 0)
        craft_log("[COUNT-ONLY] activated, totals reset")
    else:
        from gui.tooltip import hide_tooltip
        hide_tooltip()
        hide_tooltip(tooltip_id=2)
        state.gui_visible = True
        craft_log("[COUNT-ONLY] deactivated")


def ac_build_craft_tooltip(mode: str) -> str:
    presets = getattr(state, "ac_preset_names", [])
    idx = getattr(state, "ac_preset_idx", 1) - 1

    if not presets:
        return f" AutoCraft: no presets selected"

    if len(presets) == 1:
        return (f" {mode}: {presets[0]}\n"
                f" F at inventory  |  F1 = Stop")

    current = presets[idx] if 0 <= idx < len(presets) else "?"
    next_idx = (idx + 1) % len(presets)
    next_name = presets[next_idx] if 0 <= next_idx < len(presets) else "?"

    lines = [f" {mode}: {current}  (Q \u2192 {next_name})"]
    for i, name in enumerate(presets):
        marker = " \u25ba " if i == idx else "   "
        lines.append(f"{marker}{name}")
    lines.append(f" F at inventory  |  F1 = Stop")
    return "\n".join(lines)
