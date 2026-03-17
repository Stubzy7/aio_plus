
import re
import threading
import time
from datetime import datetime

from core.state import state
from core.scaling import scale_x, scale_y, width_multiplier, height_multiplier
from input.pixel import px_get, is_color_similar, pixel_search, wait_for_pixel
from input.mouse import click, set_cursor_pos, mouse_move
from input.keyboard import send, send_text, key_press, control_send
from input.ocr import from_rect
from input.window import win_exist, win_activate, control_click
from util.color import color_r, color_g, color_b
from modules.nvidia_filter import nft as _nft


def _per_channel_match(c1: int, c2: int, tol: int) -> bool:
    return (abs(color_r(c1) - color_r(c2)) <= tol
            and abs(color_g(c1) - color_g(c2)) <= tol
            and abs(color_b(c1) - color_b(c2)) <= tol)


def _nf_search_tol(x1, y1, x2, y2, color, tol):
    c = px_get(x1, y1)
    return _per_channel_match(c, color, tol)


def _nf_pixel_wait(x, y, color, tol):
    c = px_get(x, y)
    return _per_channel_match(c, color, tol)


def _nf_color_bright(c, threshold):
    return color_r(c) > threshold and color_g(c) > threshold and color_b(c) > threshold


def _ark_hwnd():
    return win_exist(state.ark_window)


def _tick():
    return int(time.monotonic() * 1000)


def _sleep(ms):
    time.sleep(ms / 1000.0)


def _log(msg):
    state.ob_log.append(msg)


def _ob_overlay_clear() -> bool:
    col = px_get(state.ob_ov_pix_x, state.ob_ov_pix_y)
    r = color_r(col)
    return r > _nft(180, 1)


def _ob_check_inv_failed() -> bool:
    col = px_get(state.ob_inv_fail_btn_x, state.ob_inv_fail_btn_y)
    if _nf_color_bright(col, 220):
        hwnd = _ark_hwnd()
        if hwnd:
            control_click(hwnd, state.ob_inv_fail_btn_x, state.ob_inv_fail_btn_y)
        _sleep(300)
        return True
    return False


def _ob_tooltip_off():
    col = px_get(state.ob_tooltip_pix_x, state.ob_tooltip_pix_y)
    g = color_g(col)
    b = color_b(col)
    _log(f"[TOOLTIP] pixel ({state.ob_tooltip_pix_x},{state.ob_tooltip_pix_y}): "
         f"0x{col:06X} G={g} B={b}")
    if g > _nft(200, 1) and b > _nft(240, 1):
        state.ob_tooltips_were_on = True
        _log("[TOOLTIP] was ON — clicking off")
        hwnd = _ark_hwnd()
        if hwnd:
            control_click(hwnd, state.ob_tooltip_pix_x, state.ob_tooltip_pix_y)
        _sleep(120)
    else:
        state.ob_tooltips_were_on = False
        _log("[TOOLTIP] was already OFF")


def _ob_tooltip_restore():
    if state.ob_tooltips_were_on:
        _log("[TOOLTIP] restoring ON")
        hwnd = _ark_hwnd()
        if hwnd:
            control_click(hwnd, state.ob_tooltip_pix_x, state.ob_tooltip_pix_y)
        _sleep(120)
        state.ob_tooltips_were_on = False


def ob_down_set_status(msg: str):
    state.ob_down_text = msg
    try:
        from gui.tab_joinsim import update_ob_down_status
        update_ob_down_status(msg)
    except Exception:
        pass
    try:
        from gui.tooltip import show_tooltip, hide_tooltip
        if msg:
            show_tooltip(f" Auto Empty OB \u2014 {msg}\nF1 = Show UI  |  Q = Stop", 0, 20)
        else:
            hide_tooltip()
    except Exception:
        pass


def ob_down_stop_all(hide_gui: bool = True):
    state.ob_download_armed = False
    state.ob_download_running = False
    state.ob_download_paused = False
    ob_down_set_status("")
    if hide_gui:
        state.gui_visible = False


def _clear_status_after(ms: int = 2000):
    from core.timers import timers

    def _clear():
        ob_down_set_status("")
        state.gui_visible = True
        root = getattr(state, "root", None)
        if root:
            root.after(0, root.deiconify)

    timers.set_timer("ob_down_clear_tip", _clear, -ms)


def ob_bar_count_items() -> int:
    base_start = 1025
    base_per_slot = 10.04
    scan_y = state.ob_bar_pix_y

    for inverse_slot in range(51):
        slot = 50 - inverse_slot
        check_x = round((base_start + slot * base_per_slot) * width_multiplier)
        try:
            col = px_get(check_x, scan_y)
            r = color_r(col)
            g = color_g(col)
            b = color_b(col)
            if r < 30 and g > 100 and b > 80:
                return slot
        except Exception:
            pass
    return 0


def ob_ocr_download_count() -> int:
    try:
        txt = from_rect(state.ob_ocr_x[2], state.ob_ocr_y[2],
                        state.ob_ocr_w[2], state.ob_ocr_h[2], scale=3)
        _log(f"[OCR-DnCount] '{txt[:60]}'")
        m = re.search(r"(\d+)\s*/\s*\d+", txt)
        if m:
            return int(m.group(1))
        return -1
    except Exception as e:
        _log(f"[OCR-DnCount] FAIL: {e}")
        return -1


def ob_download_cycle():
    if state.pc_mode > 0 or state.pc_f10_step > 0:
        state.pc_f10_step = 0
        state.pc_mode = 0
        state.pc_running = False

    if state.ob_download_running:
        state.ob_download_running = False
        state.ob_download_paused = False
        ob_down_set_status("Downloading stopped")
        _clear_status_after(2000)
        return

    if state.ob_download_armed:
        ob_down_stop_all(hide_gui=False)
        return

    ark = _ark_hwnd()
    if ark:
        win_activate(ark)

    state.ob_download_running = True
    state.gui_visible = False
    root = getattr(state, "root", None)
    if root:
        root.after(0, root.withdraw)

    send("{F}")

    t = threading.Thread(target=ob_run_download, daemon=True, name="ob_download")
    t.start()


def ob_down_f_pressed():
    if not state.ob_download_armed:
        return
    state.ob_download_armed = False
    state.gui_visible = False
    root = getattr(state, "root", None)
    if root:
        root.after(0, root.withdraw)
    t = threading.Thread(target=ob_run_download, daemon=True, name="ob_download")
    t.start()


def ob_run_download():
    hwnd = _ark_hwnd()
    nav_start_time = _tick()

    ob_down_set_status("Waiting for OB inventory...")
    wait_count = 0
    while True:
        if not state.ob_download_running:
            return
        if _nf_search_tol(state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                          state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                          0xFFFFFF, 15):
            break
        _sleep(16)
        wait_count += 1
        if wait_count > 250:
            state.ob_download_running = False
            ob_down_set_status("Not at transmitter — F7 to retry")
            _clear_status_after(3000)
            return

    ob_down_set_status("Waiting for inventory")
    _ob_tooltip_off()
    wait_count = 0
    while not _nf_pixel_wait(state.ob_right_tab_pix_x, state.ob_right_tab_pix_y,
                             0x5D94A0, 25):
        _sleep(16)
        wait_count += 1
        if wait_count == 125:
            ob_down_set_status("Waiting for OB tab (lag)...")
        if wait_count > 625:
            actual_col = px_get(state.ob_right_tab_pix_x, state.ob_right_tab_pix_y)
            ob_down_set_status(f"Timeout — right tab pixel: 0x{actual_col:06X}")
            _sleep(1500)
            ob_down_stop_all()
            return

    if hwnd:
        control_click(hwnd, state.ob_right_tab_pix_x, state.ob_right_tab_pix_y)
    _sleep(100)

    if hwnd:
        control_click(hwnd, state.ob_upload_tab_x, state.ob_upload_tab_y)

    wait_count = 0
    while not _nf_pixel_wait(state.ob_upload_ready_pix_x, state.ob_upload_ready_pix_y,
                             0xBCF4FF, 20):
        if not state.ob_download_running:
            return
        _sleep(16)
        wait_count += 1
        if wait_count > state.ob_inv_timeout:
            ob_down_set_status("Timeout — upload tab not detected")
            _sleep(1500)
            ob_down_stop_all()
            return

    ob_down_set_status("Waiting for Ark data to load...")
    data_wait_start = _tick()
    data_loaded = False
    for _ in range(500):
        if not state.ob_download_running:
            return
        dc = px_get(state.ob_data_loaded_pix_x, state.ob_data_loaded_pix_y)
        dr = color_r(dc)
        dg = color_g(dc)
        db = color_b(dc)
        if 130 < dr < 190 and 180 < dg < 230 and 195 < db < 245:
            data_loaded = True
            break
        _sleep(16)

    if not data_loaded:
        state.ob_log = []
        _log(f"=== DOWNLOAD run {datetime.now():%Y-%m-%d %H:%M:%S} ===")
        _log(f"[DL] ARK data load TIMEOUT after {_tick() - data_wait_start}ms")
        ob_down_set_status("Data load timeout")
        _sleep(2000)
        ob_down_stop_all()
        return

    ob_down_set_status("Downloading OB")
    items_downloaded = 0
    state.ob_log = []
    _log(f"=== DOWNLOAD run {datetime.now():%Y-%m-%d %H:%M:%S} ===")
    _log(f"[DL] ARK data loaded after {_tick() - data_wait_start}ms")

    ob_down_set_status("Loading items...")
    first_found = False
    for _ in range(20):
        if not state.ob_download_running:
            break
        bar_col = px_get(state.ob_bar_pix_x, state.ob_bar_pix_y)
        br = color_r(bar_col)
        bg = color_g(bar_col)
        bb = color_b(bar_col)
        if br < _nft(30, -1) and bg > _nft(150, 1) and bb > _nft(130, 1):
            first_found = True
            break
        _sleep(300)

    if not first_found:
        _log("[DL] no items loaded after 6s — ARK data load error")
        ob_down_set_status("Data load error")
        _sleep(500)
        send("{Escape}")
        _sleep(3000)
        ob_down_stop_all()
        return

    ob_down_set_status("Reading item count...")
    mouse_move(round(960 * width_multiplier), round(200 * height_multiplier), 0)
    _sleep(500)

    bar_count1 = ob_bar_count_items()
    _sleep(200)
    bar_count2 = ob_bar_count_items()
    _log(f"[DL] bar count: {bar_count1} -> {bar_count2}")

    if bar_count1 == bar_count2 and bar_count1 >= 0:
        init_count = bar_count1
        _log(f"[DL] bar count confirmed: {init_count}")
    else:
        _log("[DL] bar count mismatch — falling back to OCR")
        init_count = -1
        last_read = -1
        count_attempt = 0
        while count_attempt < 5:
            this_read = ob_ocr_download_count()
            _log(f"[DL] OCR attempt {count_attempt + 1}: {this_read}")
            if this_read >= 0 and this_read == last_read:
                init_count = this_read
                _log(f"[DL] OCR confirmed: {init_count}")
                break
            last_read = this_read
            count_attempt += 1
            _sleep(300)
        if init_count == -1 and last_read >= 0:
            init_count = last_read
            _log(f"[DL] OCR no match — using last valid: {init_count}")

    if init_count == 0:
        ob_down_set_status("OB empty (0/50) — nothing to download")
        _log("[DL] 0/50 — aborting")
        _sleep(2000)
        ob_down_stop_all()
        return
    if init_count == -1:
        _log("[DL] all counts failed — proceeding with max 50")
        init_count = 50

    dl_start_time = _tick()
    nav_ms = dl_start_time - nav_start_time
    _log(f"[NAV] overhead {nav_ms}ms ({round(nav_ms / 1000, 1)}s)")
    _log(f"[DL] target: {init_count} items")

    remaining = init_count if init_count > 0 else 50

    while True:
        if not state.ob_download_running:
            ob_down_set_status("Downloading stopped")
            break
        if remaining <= 0:
            _log(f"[DL] all {init_count} items downloaded")
            ob_down_set_status(f"All items downloaded ({items_downloaded})")
            break

        item_start_time = _tick()

        teal_wait = 0
        teal_found = True
        while True:
            if not state.ob_download_running:
                ob_down_set_status("Downloading stopped")
                teal_found = False
                break
            bar_col = px_get(state.ob_bar_pix_x, state.ob_bar_pix_y)
            bg = color_g(bar_col)
            bb = color_b(bar_col)
            if bg > _nft(150, 1) and bb > _nft(130, 1):
                break
            if teal_wait == 0:
                ob_down_set_status(f"Waiting for slot to load... ({remaining} left)")
            if teal_wait >= 500:
                _log(f"[DL] no teal after 8s — done ({items_downloaded} items)")
                ob_down_set_status(f"All items downloaded ({items_downloaded})")
                remaining = 0
                teal_found = False
                break
            teal_wait += 1
            _sleep(16)

        if not teal_found or remaining <= 0:
            break
        if not state.ob_download_running:
            break

        mouse_move(state.ob_down_slot_x, state.ob_down_slot_y, 0)
        _sleep(20)
        click()
        _sleep(30)
        if hwnd:
            control_send(hwnd, "t")
        else:
            send("t")

        overlay_seen = False
        dl_wait = 0
        for _ in range(63):
            if not state.ob_download_running:
                break
            if not _ob_overlay_clear():
                overlay_seen = True
                break
            if dl_wait == 19 and _ob_check_inv_failed():
                _log(f"[DL#{items_downloaded + 1}] Inv failed popup in T-wait — dismissed")
                _sleep(300)
                break
            dl_wait += 1
            _sleep(16)

        if not overlay_seen:
            item_ms = _tick() - item_start_time
            _log(f"[DL#{items_downloaded + 1}] no overlay after T — retrying ({item_ms}ms)")
            ob_down_set_status(f"No response — retrying... ({remaining} left)")
            _sleep(300)
            continue

        items_downloaded += 1
        remaining -= 1
        ob_down_set_status(f"Downloading {items_downloaded}/{init_count} "
                           f"({remaining} left)")

        clear_wait = 0
        while not _ob_overlay_clear() and state.ob_download_running:
            if clear_wait % 63 == 0 and _ob_check_inv_failed():
                ob_down_set_status("Inv failed popup — dismissed, retrying...")
                _log(f"[DL#{items_downloaded}] Refreshing Inventory Failed popup — dismissed")
                _sleep(500)
                mouse_move(state.ob_down_slot_x, state.ob_down_slot_y, 0)
                click()
                _sleep(30)
                if hwnd:
                    control_send(hwnd, "t")
                else:
                    send("t")
                clear_wait = 0
            clear_wait += 1
            if clear_wait == 500:
                _log(f"[DL#{items_downloaded}] overlay taking 8s — server lag")
            _sleep(16)

        if not state.ob_download_running:
            ob_down_set_status("Downloading stopped")
            break

        if remaining > 0 and state.ob_down_item_delay_ms > 0:
            _sleep(state.ob_down_item_delay_ms)

        item_ms = _tick() - item_start_time
        _log(f"[DL#{items_downloaded}] {item_ms}ms ({remaining} left)")

    _sleep(500)

    ob_close_pix_x = round(1812 * width_multiplier)
    ob_close_pix_y = round(216 * height_multiplier)
    close_wait = 0
    while True:
        if _nf_search_tol(ob_close_pix_x, ob_close_pix_y,
                          ob_close_pix_x + 1, ob_close_pix_y + 1,
                          0xFFFFFF, 10):
            if hwnd:
                control_send(hwnd, "f")
            else:
                send("f")
            break
        close_wait += 1
        if close_wait > 250:
            if hwnd:
                control_send(hwnd, "f")
            else:
                send("f")
            break
        _sleep(20)

    state.ob_download_running = False
    dl_elapsed = round((_tick() - dl_start_time) / 1000, 1)
    dl_per_min = round(items_downloaded / (dl_elapsed / 60), 1) if dl_elapsed > 0 else 0
    nav_ms2 = dl_start_time - nav_start_time
    total_s = round((_tick() - nav_start_time) / 1000, 1)
    _log(f"=== DONE: {items_downloaded} items in {dl_elapsed}s ({dl_per_min}/min) ===")
    _log(f"[NAV] overhead was {round(nav_ms2 / 1000, 1)}s | total from F7: {total_s}s")

    _ob_tooltip_restore()
    ob_down_set_status(f"Done — {items_downloaded} items in {dl_elapsed}s")
    _sleep(2000)
    ob_down_set_status("")
    ob_down_stop_all()


def ob_ocr_toggle_resize(idx: int):
    if state.ob_ocr_resizing:
        ob_ocr_exit_resize()
        return

    if state.ac_ocr_resizing or getattr(state, "imprint_resizing", False):
        return

    state.ob_ocr_resizing = True
    state.ob_ocr_target = idx
    ob_ocr_show_overlay()

    labels = {0: "Upload Slot", 1: "Upload Popup", 2: "Download Count",
              3: "Download Popup", 4: "Timer"}
    label = labels.get(idx, f"Region {idx}")
    _ob_tooltip(f" OB OCR Resize: {label}\n"
                f" Arrows = resize  |  WASD = move\n"
                f" Enter = done")
    _log(f"[OCR-RESIZE] entered for region {idx} ({label})")


def ob_ocr_exit_resize():
    state.ob_ocr_resizing = False
    ob_ocr_hide_overlay()
    ob_ocr_save_config()
    ob_ocr_update_size_txt()
    _ob_tooltip(None)
    _log("[OCR-RESIZE] exited")


def ob_ocr_resize_done():
    ob_ocr_exit_resize()


def ob_ocr_size_up():
    i = state.ob_ocr_target
    state.ob_ocr_h[i] = max(20, state.ob_ocr_h[i] + 10)
    ob_ocr_show_overlay()
    ob_ocr_update_size_txt()


def ob_ocr_size_down():
    i = state.ob_ocr_target
    state.ob_ocr_h[i] = max(20, state.ob_ocr_h[i] - 10)
    ob_ocr_show_overlay()
    ob_ocr_update_size_txt()


def ob_ocr_size_right():
    i = state.ob_ocr_target
    state.ob_ocr_w[i] = max(40, state.ob_ocr_w[i] + 20)
    ob_ocr_show_overlay()
    ob_ocr_update_size_txt()


def ob_ocr_size_left():
    i = state.ob_ocr_target
    state.ob_ocr_w[i] = max(40, state.ob_ocr_w[i] - 20)
    ob_ocr_show_overlay()
    ob_ocr_update_size_txt()


def ob_ocr_move_up():
    i = state.ob_ocr_target
    state.ob_ocr_y[i] = max(0, state.ob_ocr_y[i] - 10)
    ob_ocr_show_overlay()


def ob_ocr_move_down():
    from core.scaling import screen_height
    i = state.ob_ocr_target
    state.ob_ocr_y[i] = min(screen_height - state.ob_ocr_h[i], state.ob_ocr_y[i] + 10)
    ob_ocr_show_overlay()


def ob_ocr_move_left():
    i = state.ob_ocr_target
    state.ob_ocr_x[i] = max(0, state.ob_ocr_x[i] - 10)
    ob_ocr_show_overlay()


def ob_ocr_move_right():
    from core.scaling import screen_width
    i = state.ob_ocr_target
    state.ob_ocr_x[i] = min(screen_width - state.ob_ocr_w[i], state.ob_ocr_x[i] + 10)
    ob_ocr_show_overlay()


def ob_ocr_update_size_txt():
    i = state.ob_ocr_target
    _log(f"[OCR-RESIZE] region {i}: {state.ob_ocr_w[i]}x{state.ob_ocr_h[i]} "
         f"at ({state.ob_ocr_x[i]},{state.ob_ocr_y[i]})")


def ob_ocr_show_overlay():
    ob_ocr_hide_overlay()
    try:
        from gui.overlay import show_rect_overlay
        i = state.ob_ocr_target
        color = "red" if i == 4 else "cyan"
        state.ob_ocr_overlays = show_rect_overlay(
            state.ob_ocr_x[i], state.ob_ocr_y[i],
            state.ob_ocr_w[i], state.ob_ocr_h[i],
            color=color, border=2,
        )
    except Exception:
        pass


def ob_ocr_hide_overlay():
    if state.ob_ocr_overlays is not None:
        try:
            from gui.overlay import hide_rect_overlay
            hide_rect_overlay(state.ob_ocr_overlays)
        except Exception:
            pass
        state.ob_ocr_overlays = None


def _ob_tooltip(text: str | None):
    try:
        if text:
            from gui.tooltip import show_tooltip
            show_tooltip(text)
        else:
            from gui.tooltip import hide_tooltip
            hide_tooltip()
    except Exception:
        pass


def ob_ocr_save_config():
    from core.config import write_ini
    wm = width_multiplier or 1
    hm = height_multiplier or 1
    write_ini("OBDnCount", "X", str(round(state.ob_ocr_x[2] / wm)))
    write_ini("OBDnCount", "Y", str(round(state.ob_ocr_y[2] / hm)))
    write_ini("OBDnCount", "W", str(round(state.ob_ocr_w[2] / wm)))
    write_ini("OBDnCount", "H", str(round(state.ob_ocr_h[2] / hm)))
    write_ini("OBTimer", "X", str(round(state.ob_ocr_x[4] / wm)))
    write_ini("OBTimer", "Y", str(round(state.ob_ocr_y[4] / hm)))
    write_ini("OBTimer", "W", str(round(state.ob_ocr_w[4] / wm)))
    write_ini("OBTimer", "H", str(round(state.ob_ocr_h[4] / hm)))


def ob_ocr_load_config():
    from core.config import read_ini
    wm = width_multiplier or 1
    hm = height_multiplier or 1

    for key, arr, mult, min_val in [
        ("X", state.ob_ocr_x, wm, None),
        ("Y", state.ob_ocr_y, hm, None),
        ("W", state.ob_ocr_w, wm, 40),
        ("H", state.ob_ocr_h, hm, 20),
    ]:
        val = read_ini("OBDnCount", key, "")
        if val:
            try:
                v = round(int(val) * mult)
                if min_val is not None and v < min_val:
                    continue
                arr[2] = v
            except (ValueError, TypeError):
                pass

    for key, arr, mult, min_val in [
        ("X", state.ob_ocr_x, wm, None),
        ("Y", state.ob_ocr_y, hm, None),
        ("W", state.ob_ocr_w, wm, 40),
        ("H", state.ob_ocr_h, hm, 20),
    ]:
        val = read_ini("OBTimer", key, "")
        if val:
            try:
                v = round(int(val) * mult)
                if min_val is not None and v < min_val:
                    continue
                arr[4] = v
            except (ValueError, TypeError):
                pass


def ob_ocr_slot_has_items() -> bool:
    try:
        text = from_rect(state.ob_ocr_x[0], state.ob_ocr_y[0],
                         state.ob_ocr_w[0], state.ob_ocr_h[0], scale=3)
        has = bool(re.search(r"\d", text[:60] if text else ""))
        _log(f"[OCR-SLOT] '{text[:60] if text else ''}' -> {'HAS ITEMS' if has else 'empty'}")
        return has
    except Exception as e:
        _log(f"[OCR-SLOT] error: {e}")
        return False


def ob_ocr_upload_busy() -> bool:
    try:
        text = from_rect(state.ob_ocr_x[1], state.ob_ocr_y[1],
                         state.ob_ocr_w[1], state.ob_ocr_h[1], scale=2)
        lower = (text or "").lower()
        busy = "upload" in lower or "refresh" in lower
        return busy
    except Exception as e:
        _log(f"[OCR-UPLOAD] error: {e}")
        return False


def ob_ocr_download_count() -> int:
    try:
        text = from_rect(state.ob_ocr_x[2], state.ob_ocr_y[2],
                         state.ob_ocr_w[2], state.ob_ocr_h[2], scale=3)
        _log(f"[OCR-DNCOUNT] raw='{text[:60] if text else ''}'")
        if text:
            m = re.search(r"(\d+)\s*/\s*\d+", text)
            if m:
                return int(m.group(1))
        return -1
    except Exception as e:
        _log(f"[OCR-DNCOUNT] error: {e}")
        return -1


def ob_ocr_download_busy() -> bool:
    try:
        text = from_rect(state.ob_ocr_x[3], state.ob_ocr_y[3],
                         state.ob_ocr_w[3], state.ob_ocr_h[3], scale=2)
        lower = (text or "").lower()
        return "download" in lower
    except Exception as e:
        _log(f"[OCR-DOWNLOAD] error: {e}")
        return False


def ob_ocr_wait_popup_clear(max_ms: int = 45000) -> bool:
    start = _tick()
    polls = 0
    deadline = max_ms
    while (_tick() - start) < deadline:
        if not state.ob_upload_running and not state.ob_download_running:
            return False
        if not ob_ocr_upload_busy():
            _log(f"[OCR-POPUP] cleared after {polls} polls ({round((_tick() - start) / 1000, 1)}s)")
            return True
        _sleep(100)
        polls += 1
    _log(f"[OCR-POPUP] timeout after {polls} polls ({max_ms}ms)")
    return False


def ob_ocr_wait_dn_popup_clear(max_ms: int = 30000) -> bool:
    start = _tick()
    polls = 0
    deadline = max_ms
    while (_tick() - start) < deadline:
        if not state.ob_download_running:
            return False
        if not ob_ocr_download_busy():
            _log(f"[OCR-DNPOPUP] cleared after {polls} polls ({round((_tick() - start) / 1000, 1)}s)")
            return True
        _sleep(100)
        polls += 1
    _log(f"[OCR-DNPOPUP] timeout after {polls} polls ({max_ms}ms)")
    return False
