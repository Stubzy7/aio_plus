
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
from input.window import win_exist, win_activate, control_click, find_window
from util.color import color_r, color_g, color_b, color_distance
from modules.nvidia_filter import nft as _nft


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _per_channel_match(c1: int, c2: int, tol: int) -> bool:
    """Per-channel tolerance check.

    Each R/G/B channel is compared independently — all must be within *tol*.
    This is per-channel, NOT sum-of-channels.
    """
    return (abs(color_r(c1) - color_r(c2)) <= tol
            and abs(color_g(c1) - color_g(c2)) <= tol
            and abs(color_b(c1) - color_b(c2)) <= tol)


def _nf_search_tol(x1, y1, x2, y2, color, tol):
    """Check a single-pixel region for a color within tolerance.

    Returns True if the pixel at (x1, y1) matches *color* within *tol*.
    Mirrors ``NFSearchTol()`` → ``PxSearch()`` → ``PixelSearch()`` which
    uses per-channel tolerance.
    """
    c = px_get(x1, y1)
    return _per_channel_match(c, color, tol)


def _nf_pixel_wait(x, y, color, tol):
    """Single-sample color check used inside polling loops."""
    c = px_get(x, y)
    return _per_channel_match(c, color, tol)


def _nf_color_bright(c, threshold):
    """True if all three channels exceed *threshold*."""
    return color_r(c) > threshold and color_g(c) > threshold and color_b(c) > threshold


def _ark_hwnd():
    """Return the HWND of the ARK window (0 if not found)."""
    return win_exist(state.ark_window)


def _tick():
    """Return a monotonic millisecond counter."""
    return int(time.monotonic() * 1000)


def _sleep(ms):
    """Sleep for *ms* milliseconds."""
    time.sleep(ms / 1000.0)


def _log(msg):
    """Append a message to the OB log list on state."""
    state.ob_log.append(msg)


# ---------------------------------------------------------------------------
# Status / Tooltip
# ---------------------------------------------------------------------------

def ob_set_status(msg: str):
    """Update the OB upload status text, GUI label, and tooltip."""
    state.ob_status_text = msg
    try:
        from gui.tab_joinsim import update_ob_status
        update_ob_status(msg)
    except Exception:
        pass
    try:
        from gui.tooltip import update_tooltip
        if msg:
            update_tooltip(f" {msg}")
        else:
            from gui.tooltip import hide_tooltip
            hide_tooltip()
    except Exception:
        pass


def ob_tooltip_off():
    """Disable in-game tooltips checkbox if it was on, tracking prior state."""
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
        col2 = px_get(state.ob_tooltip_pix_x, state.ob_tooltip_pix_y)
        g2 = color_g(col2)
        b2 = color_b(col2)
        still_on = g2 > _nft(200, 1) and b2 > _nft(240, 1)
        _log(f"[TOOLTIP] after click: 0x{col2:06X} — {'STILL ON (click failed!)' if still_on else 'OFF ok'}")
    else:
        state.ob_tooltips_were_on = False
        _log("[TOOLTIP] was already OFF — no action")


def ob_tooltip_restore():
    """Restore in-game tooltips if they were on before upload."""
    if state.ob_tooltips_were_on:
        _log("[TOOLTIP] restoring ON")
        hwnd = _ark_hwnd()
        if hwnd:
            control_click(hwnd, state.ob_tooltip_pix_x, state.ob_tooltip_pix_y)
        _sleep(120)
        state.ob_tooltips_were_on = False


# ---------------------------------------------------------------------------
# Slot-empty detection
# ---------------------------------------------------------------------------

def ob_get_empty_slot_color(x: int, y: int) -> int:
    """Return the current color at a slot position (for empty-reference capture).

    Used to capture a reference color for empty-slot detection.
    """
    return px_get(x, y)


def ob_slot_is_empty(x: int, y: int, empty_ref: int = 0) -> bool:
    """Return True if the inventory slot at *(x, y)* looks empty.

    Ignores *empty_ref* and simply checks
    whether all RGB channels are below 50 (dark/black slot).
    """
    c = px_get(x, y)
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF
    return r < 50 and g < 50 and b < 50


# ---------------------------------------------------------------------------
# Character upload — load server from INI
# ---------------------------------------------------------------------------

def ob_char_load_server():
    """Load the character-upload server number from INI config.

    Reads [OBUpload] CharServer from INI and
    populates the server list state for arrow-key cycling.
    """
    from core.config import read_ini
    saved = read_ini("UploadChar", "CustomServer", "2386")
    state.ob_char_custom_server = saved if saved else "2386"
    svr = read_ini("OBUpload", "ServerList", "").strip()
    if svr:
        state.svr_list = [s.strip() for s in svr.split(",") if s.strip()]
    if state.ob_char_custom_server in state.svr_list:
        state.ob_char_svr_idx = state.svr_list.index(state.ob_char_custom_server)
    else:
        state.ob_char_svr_idx = 0
    _log(f"Char server loaded: {state.ob_char_custom_server}  list={state.svr_list}")


# ---------------------------------------------------------------------------
# Stop / cleanup
# ---------------------------------------------------------------------------

def ob_stop_all(hide_gui: bool = True):
    """Reset all OB upload state flags."""
    state.ob_upload_mode = 0
    state.ob_upload_armed = False
    state.ob_upload_running = False
    state.ob_upload_paused = False
    state.ob_active_filter = ""
    state.ob_upload_filter = ""
    ob_set_status("")  # clears tooltip + GUI label
    _ob_char_unregister_arrows()
    if hide_gui and state.main_gui is not None:
        try:
            state.gui_visible = False
            state.main_gui.hide()
        except Exception:
            pass


# ---------------------------------------------------------------------------
# Overlay / inventory helpers
# ---------------------------------------------------------------------------

def ob_overlay_clear() -> bool:
    """Check whether the 'Refreshing Inventory' overlay has cleared.

    Returns True when the overlay pixel's red channel is bright enough,
    meaning the normal inventory background is visible.
    """
    col = px_get(state.ob_ov_pix_x, state.ob_ov_pix_y)
    r = color_r(col)
    return r > _nft(180, 1)


def ob_check_inv_failed() -> bool:
    """Detect and dismiss the 'Refreshing Inventory Failed' popup.

    Returns True if the popup was found and dismissed.
    """
    col = px_get(state.ob_inv_fail_btn_x, state.ob_inv_fail_btn_y)
    if _nf_color_bright(col, 220):
        hwnd = _ark_hwnd()
        if hwnd:
            control_click(hwnd, state.ob_inv_fail_btn_x, state.ob_inv_fail_btn_y)
        _sleep(300)
        return True
    return False


def ob_item_present(filter_text: str) -> bool:
    """Check if items matching *filter_text* are visible in the first slot.

    Uses pixel-color heuristics specific to each item category.
    """
    if filter_text == "cryop":
        wait = 0
        while not ob_overlay_clear() and wait < 60:
            if not state.ob_upload_running:
                return False
            _sleep(50)
            wait += 1

        nc = px_get(state.ob_item_name_pix_x, state.ob_item_name_pix_y)
        ng = color_g(nc)
        nb = color_b(nc)
        if ng > _nft(160, 1) and nb > _nft(220, 1):
            return True

        tc = px_get(state.ob_timer_pix_x, state.ob_timer_pix_y)
        tr = color_r(tc)
        tg = color_g(tc)
        tb = color_b(tc)
        if tr > _nft(160, 1) and tg > _nft(120, 1) and tb < _nft(80, -1):
            return True

        _sleep(30)
        nc2 = px_get(state.ob_item_name_pix_x, state.ob_item_name_pix_y)
        ng2 = color_g(nc2)
        nb2 = color_b(nc2)
        if ng2 > _nft(160, 1) and nb2 > _nft(220, 1):
            return True

        tc2 = px_get(state.ob_timer_pix_x, state.ob_timer_pix_y)
        tr2 = color_r(tc2)
        tg2 = color_g(tc2)
        tb2 = color_b(tc2)
        if tr2 > _nft(160, 1) and tg2 > _nft(120, 1) and tb2 < _nft(80, -1):
            return True

        dc2 = px_get(state.ob_dayd_pix_x, state.ob_dayd_pix_y)
        dr2 = color_r(dc2)
        dg2 = color_g(dc2)
        db2 = color_b(dc2)
        if dr2 > _nft(160, 1) and dg2 > _nft(120, 1) and db2 < _nft(80, -1):
            return True

        return False

    elif filter_text in ("ek et", "ek che", "ek gg", "ek ot", "ek sw", "ek fl", "ek leg"):
        wait = 0
        while not ob_overlay_clear() and wait < 60:
            if not state.ob_upload_running:
                return False
            _sleep(50)
            wait += 1

        tek_pix_x = round(251 * width_multiplier)
        tek_pix_y = round(331 * height_multiplier)
        for attempt in range(3):
            tc = px_get(tek_pix_x, tek_pix_y)
            tr = color_r(tc)
            tg = color_g(tc)
            tb = color_b(tc)
            is_tek = tg > _nft(210, 1) and tb > _nft(210, 1) and tg > tr
            _log(f"[TEK-CHECK#{attempt}] tekPix({tek_pix_x},{tek_pix_y})=0x{tc:06X} "
                 f"R={tr} G={tg} B={tb} -> {'FOUND' if is_tek else 'empty'}")
            if is_tek:
                return True
            if attempt < 2:
                _sleep(150)
        return False

    else:
        col = px_get(state.ob_all_pix_x, state.ob_all_pix_y)
        r = color_r(col)
        g = color_g(col)
        b = color_b(col)
        if (r > _nft(90, 1) and r < _nft(140, -1)
                and g > _nft(110, 1) and g < _nft(165, -1)
                and b > _nft(110, 1) and b < _nft(165, -1)
                and abs(g - b) < _nft(15, -1)):
            return True
        return False


def ob_clear_filter():
    """Clear the OB search bar — click it, select all, delete."""
    _log("[clear] Clearing search filter")
    mouse_move(int(state.my_search_bar_x), int(state.my_search_bar_y), 0)
    _sleep(50)
    click()
    _sleep(80)
    send("^a")
    _sleep(20)
    send("{Delete}")
    _sleep(100)


def ob_apply_their_filter(filter_text: str):
    """Type a filter into the OB search bar using clipboard paste."""
    mouse_move(int(state.my_search_bar_x), int(state.my_search_bar_y), 0)
    _sleep(50)
    click()
    _sleep(80)
    if filter_text:
        _set_clipboard(filter_text)
        send("^a")
        _sleep(20)
        send("^v")
    else:
        send("^a")
        _sleep(20)
        send("{Delete}")
    _sleep(150)


def _set_clipboard(text: str):
    """Set the Windows clipboard to *text*."""
    from util.clipboard import set_clipboard_text
    if not set_clipboard_text(text):
        _log("[CLIPBOARD] set_clipboard_text failed")


# ---------------------------------------------------------------------------
# OCR timer check
# ---------------------------------------------------------------------------

def ob_check_upload_timer(filter_text: str = "") -> bool:
    """Check for a cryofridge upload cooldown timer via OCR.

    If a timer is detected, wait it out and re-arm so the user can press F
    again once it expires.  Returns True if a timer was found (caller should
    return early), False otherwise.
    """
    if state.gui_visible and state.main_gui is not None:
        state.gui_visible = False
        try:
            state.main_gui.hide()
        except Exception:
            pass

    inv_open = False
    inv_wait = 0
    while state.ob_upload_running and inv_wait < 250:
        try:
            if _nf_search_tol(state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                              state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                              0xFFFFFF, 15):
                inv_open = True
                break
        except Exception:
            pass
        _sleep(16)
        inv_wait += 1

    if not inv_open:
        _log(f"Timer check: inventory not detected ({inv_wait * 16}ms) — skipping")
        return False
    _sleep(200)

    if filter_text:
        _log(f"Timer check: filtering [{filter_text}]")
        ob_apply_their_filter(filter_text)
        _sleep(200)

    scan_x = state.ob_ocr_x[4]
    scan_y = state.ob_ocr_y[4]
    scan_w = state.ob_ocr_w[4]
    scan_h = state.ob_ocr_h[4]
    timer_sec = 0
    try:
        t_ocr = from_rect(scan_x, scan_y, scan_w, scan_h, scale=2)
        _log(f"Timer OCR ({scan_x},{scan_y} {scan_w}x{scan_h}): [{t_ocr[:200]}]")
        max_sec = 0
        for m in re.finditer(r"(\d{1,2}):(\d{2})", t_ocr):
            mins = int(m.group(1))
            secs = int(m.group(2))
            if mins <= 15 and secs < 60:
                total = mins * 60 + secs
                if total > max_sec:
                    max_sec = total
        if max_sec > 0:
            timer_sec = max_sec + 3
            _log(f"Upload timer found: {max_sec // 60}:{max_sec % 60:02d} "
                 f"+ 3s buffer = {timer_sec}s")
    except Exception as e:
        _log(f"Timer OCR failed: {e}")

    if timer_sec > 0:
        hwnd = _ark_hwnd()
        if hwnd:
            control_send(hwnd, "{Escape}")
        else:
            send("{Escape}")
        _sleep(200)
        _log(f"Timer active — closing inv, countdown {timer_sec}s")
        state.ob_timer_counting = True
        while timer_sec > 0 and state.ob_upload_running:
            m = timer_sec // 60
            s = timer_sec % 60
            ob_set_status(f"Upload timer: {m}:{s:02d} — Waiting...")
            _sleep(1000)
            timer_sec -= 1
        state.ob_timer_counting = False
        if not state.ob_upload_running:
            return True
        state.ob_upload_running = False
        state.ob_upload_armed = True
        mode_label = {1: "Cryos", 2: "Tek+Cryos", 3: "Upload Char"}.get(
            state.ob_upload_mode, "Upload"
        )
        ob_set_status(f"Timer done — F at transmitter ({mode_label})")
        _log(f"Timer expired — re-armed ({mode_label})")
        return True

    if filter_text:
        _log(f"Timer check: no timer on [{filter_text}] — proceeding")
    return False


# ---------------------------------------------------------------------------
# Main upload loop
# ---------------------------------------------------------------------------

def ob_run_upload(filter_text: str, start_msg: str, done_msg: str,
                  check_empty: bool, close_on_done: bool = True,
                  skip_nav: bool = False, skip_clear: bool = False,
                  detect_as: str = "") -> bool:
    """Core upload loop: navigate to upload tab, apply filter, then repeatedly
    click-and-transfer items until the slot is empty or a stop condition fires.

    Returns True if at least one item was present / processed, False otherwise.
    """
    hwnd = _ark_hwnd()
    state.ob_upload_early_exit = False
    state.ob_init_failed = False
    detect_filter = detect_as if detect_as else filter_text

    # ── Navigation to upload tab ──────────────────────────────────────────
    if not skip_nav:
        ob_set_status("Waiting for OB inventory...")
        wait_count = 0
        while True:
            if not state.ob_upload_running:
                return False
            if _nf_search_tol(state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                              state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                              0xFFFFFF, 15):
                break
            _sleep(16)
            wait_count += 1
            if wait_count > 250:
                ob_set_status("Not at transmitter — re-arming")
                state.ob_init_failed = True
                return False

        ob_set_status("Waiting for inventory to load...")
        ob_tooltip_off()
        wait_count = 0
        while not _nf_pixel_wait(state.ob_right_tab_pix_x, state.ob_right_tab_pix_y,
                                 0x5D94A0, 25):
            if not state.ob_upload_running:
                return False
            _sleep(16)
            wait_count += 1
            if wait_count == 125:
                ob_set_status("Waiting for OB tab (lag)...")
            if wait_count > 625:
                actual_col = px_get(state.ob_right_tab_pix_x, state.ob_right_tab_pix_y)
                ob_set_status(f"Timeout — right tab pixel: 0x{actual_col:06X}")
                _sleep(3000)
                return False

        if hwnd:
            control_click(hwnd, state.ob_right_tab_pix_x, state.ob_right_tab_pix_y)
        _sleep(100)
        ob_set_status("Opening upload tab...")
        if hwnd:
            control_click(hwnd, state.ob_upload_tab_x, state.ob_upload_tab_y)

        wait_count = 0
        while not _nf_pixel_wait(state.ob_upload_ready_pix_x, state.ob_upload_ready_pix_y,
                                 0xBCF4FF, 20):
            if not state.ob_upload_running:
                return False
            _sleep(16)
            wait_count += 1
            if wait_count == 125:
                ob_set_status("Waiting for upload tab (lag)...")
            if wait_count > 625:
                ob_set_status("Timeout — upload tab not detected")
                _sleep(2500)
                return False
    else:
        wait_count = 0
        while not ob_overlay_clear() and wait_count < 313:
            if not state.ob_upload_running:
                return False
            wait_count += 1
            _sleep(16)
        _sleep(50)
        wait_count = 0
        while not _nf_pixel_wait(state.ob_upload_ready_pix_x, state.ob_upload_ready_pix_y,
                                 0xBCF4FF, 20):
            if not state.ob_upload_running:
                return False
            _sleep(16)
            wait_count += 1
            if wait_count > state.ob_inv_timeout:
                ob_set_status("Timeout — upload tab not visible (lag?)")
                _sleep(2500)
                return False

    _log(f"--- OBRunUpload({filter_text}) {datetime.now():%H:%M:%S} ---")
    _log("[1] Upload tab confirmed open")

    # ── Wait for ARK data to load ─────────────────────────────────────────
    data_wait_start = _tick()
    data_loaded = False
    if not skip_nav:
        ob_set_status("Waiting for Ark data to load...")
    last_dc = 0
    for poll_i in range(500):
        if not state.ob_upload_running:
            return False
        dc = px_get(state.ob_data_loaded_pix_x, state.ob_data_loaded_pix_y)
        last_dc = dc
        dr = color_r(dc)
        dg = color_g(dc)
        db = color_b(dc)
        if 130 < dr < 190 and 180 < dg < 230 and 195 < db < 245:
            data_loaded = True
            break
        if poll_i < 3 or poll_i % 50 == 0:
            _log(f"[1b-poll#{poll_i}] dataLoadPix=0x{dc:06X} R={dr} G={dg} B={db}")
        _sleep(16)
    data_wait_ms = _tick() - data_wait_start
    if data_loaded:
        pv = px_get(state.ob_data_loaded_pix_x, state.ob_data_loaded_pix_y)
        _log(f"[1b] ARK data loaded after {data_wait_ms}ms "
             f"pix({state.ob_data_loaded_pix_x},{state.ob_data_loaded_pix_y})=0x{pv:06X}")
    else:
        pv = last_dc
        _log(f"[1b] ARK data load TIMEOUT after {data_wait_ms}ms "
             f"pix({state.ob_data_loaded_pix_x},{state.ob_data_loaded_pix_y})=0x{pv:06X} "
             f"R={color_r(pv)} G={color_g(pv)} B={color_b(pv)}")
        ob_set_status("Data load timeout — aborting")
        _sleep(2000)
        return False

    # ── Apply search filter ───────────────────────────────────────────────
    state.ob_active_filter = filter_text
    ob_apply_their_filter(filter_text)
    _log(f"[2] Filter applied: '{filter_text}' — search bar typed")

    mouse_move(int(state.my_first_slot_x) - 30, int(state.my_first_slot_y), 0)
    _sleep(60)
    mouse_move(int(state.my_first_slot_x), int(state.my_first_slot_y), 0)
    _sleep(150)
    click()
    mouse_move(int(state.my_first_slot_x) - 150, int(state.my_first_slot_y), 0)
    _sleep(150)
    _log("[3] Clicked slot 1 to defocus, moved mouse away, waiting for icon to settle")

    # ── Check if items are actually present ───────────────────────────────
    item_check = ob_item_present(detect_filter)
    _log(f"[4] OBItemPresent check: {'FOUND' if item_check else 'NOT FOUND'}")

    if not item_check:
        if check_empty:
            _log("[5] checkEmpty=true — returning false silently")
            return False
        ob_set_status("No items found — debug log stored")
        _sleep(4000)
        ob_clear_filter()
        return False

    # ── Upload loop ───────────────────────────────────────────────────────
    _log("[5] Items confirmed present — starting upload loop")
    ob_set_status(start_msg)
    state.ob_upload_running = True
    last_upload_tick = _tick()
    run_start_tick = _tick()
    upload_count = 0
    is_tek_filter = detect_filter in ("ek et", "ek che", "ek gg", "ek ot",
                                      "ek sw", "ek fl")

    while True:
        if not state.ob_upload_running:
            break

        if state.ob_upload_paused:
            ob_set_status("PAUSED — F6 to resume")
            while state.ob_upload_paused and state.ob_upload_running:
                _sleep(100)
            if not state.ob_upload_running:
                break
            if state.ob_active_filter:
                _set_clipboard(state.ob_active_filter)
                mouse_move(int(state.my_search_bar_x), int(state.my_search_bar_y), 0)
                _sleep(30)
                click()
                _sleep(60)
                send("^a")
                _sleep(20)
                send("^v")
                _sleep(150)
                mouse_move(int(state.my_first_slot_x), int(state.my_first_slot_y), 0)
                _sleep(80)
            ob_set_status("Resuming...")
        if not state.ob_upload_running:
            break

        # ── First upload extra settle ─────────────────────────────────────
        if state.ob_first_upload:
            _sleep(300)
            state.ob_first_upload = False
            _log("[first-T] extra 300ms settle before very first upload")

        # ── Click slot and press T to upload ──────────────────────────────
        mouse_move(int(state.my_first_slot_x), int(state.my_first_slot_y), 0)
        click()
        _sleep(state.ob_click_settle_ms)
        _sleep(state.ob_pre_upload_ms)
        if hwnd:
            control_send(hwnd, "t")
        else:
            send("t")

        refresh_wait = 0
        overlay_appeared = False
        while refresh_wait < 8:
            if not ob_overlay_clear():
                overlay_appeared = True
                break
            if refresh_wait == 4 and ob_check_inv_failed():
                _log("[!] Inv failed popup in T-wait — dismissed")
                _sleep(300)
                overlay_appeared = False
                break
            _sleep(50)
            refresh_wait += 1

        if not overlay_appeared:
            if not state.ob_upload_running:
                break
            _sleep(300)
            re_check = ob_item_present(detect_filter)
            _log(f"[T#{upload_count + 1}] no overlay — re-check="
                 f"{'FOUND' if re_check else 'EMPTY'} +{_tick() - run_start_tick}ms")
            if re_check:
                retry_wait = 0
                while not ob_overlay_clear() and retry_wait < 60:
                    if not state.ob_upload_running:
                        break
                    _sleep(50)
                    retry_wait += 1
                _log(f"[T#{upload_count + 1}] retry — waited {retry_wait * 50}ms for overlay clear")
                continue
            _sleep(500)
            re_check2 = ob_item_present(detect_filter)
            if re_check2:
                _log(f"[T#{upload_count + 1}] no overlay — late re-check2=FOUND "
                     f"+{_tick() - run_start_tick}ms — retrying")
                retry_wait2 = 0
                while not ob_overlay_clear() and retry_wait2 < 60:
                    if not state.ob_upload_running:
                        break
                    _sleep(50)
                    retry_wait2 += 1
                continue
            _log(f"[T#{upload_count + 1}] no overlay after T — slot empty.")
            break

        _log(f"[T#{upload_count + 1}] +{_tick() - run_start_tick}ms "
             f"upload confirmed via overlay")

        # ── Wait for overlay to clear (inventory refresh) ─────────────────
        if overlay_appeared:
            clear_wait = 0
            while not ob_overlay_clear() and clear_wait < 900:
                if not state.ob_upload_running:
                    break
                if clear_wait == 60:
                    ob_set_status("Waiting — inventory refreshing...")
                elif clear_wait == 140:
                    ob_set_status("Still refreshing — possible lag...")
                elif clear_wait == 300:
                    ob_set_status("Refreshing 15s — heavy lag or ARK issue...")
                elif clear_wait == 600:
                    ob_set_status("Refreshing 30s — may be stuck...")

                if clear_wait % 20 == 0 and ob_check_inv_failed():
                    ob_set_status("Inv failed popup — dismissed, retrying...")
                    _log(f"[!] Refreshing Inventory Failed popup detected and "
                         f"dismissed at clearWait={clear_wait}")
                    _sleep(500)
                    mouse_move(int(state.my_first_slot_x), int(state.my_first_slot_y), 0)
                    click()
                    _sleep(state.ob_click_settle_ms)
                    if hwnd:
                        control_send(hwnd, "t")
                    else:
                        send("t")
                    clear_wait = 0

                if clear_wait % 20 == 0:
                    mc = px_get(state.ob_max_items_pix_x, state.ob_max_items_pix_y)
                    mr = color_r(mc)
                    mg = color_g(mc)
                    mb = color_b(mc)
                    if mr > _nft(200, 1) and mg < _nft(40, -1) and mb < _nft(40, -1):
                        _log(f"[!] Max items popup during refresh at clearWait={clear_wait}")
                        ob_set_status("Max Items Reached")
                        _sleep(500)
                        if hwnd:
                            control_click(hwnd, state.ob_max_items_pix_x,
                                          state.ob_max_items_pix_y)
                        _sleep(300)
                        state.ob_upload_running = False
                        break

                clear_wait += 1
                _sleep(50)

            if clear_wait >= 900:
                _log("[!] Stuck in Refreshing Inventory after 45s — bailing")
                ob_set_status("Stuck in refresh 45s — stopping")
                _sleep(2500)
                state.ob_upload_running = False
                ob_clear_filter()
                ob_set_status(f"{done_msg} (refresh stuck)")
                _sleep(1200)
                return True

        # ── Max items / OB full checks ────────────────────────────────────
        max_col = px_get(state.ob_max_items_pix_x, state.ob_max_items_pix_y)
        max_r = color_r(max_col)
        max_g = color_g(max_col)
        max_b = color_b(max_col)
        if max_r > _nft(200, 1) and max_g < _nft(40, -1) and max_b < _nft(40, -1):
            _log(f"[!] Max items reached after {upload_count} items — "
                 f"pixel 0x{max_col:06X}")
            ob_set_status("Max Items Reached")
            _sleep(500)
            if hwnd:
                control_click(hwnd, state.ob_max_items_pix_x, state.ob_max_items_pix_y)
            _sleep(300)
            break

        ob_full_col = px_get(state.ob_full_pix_x, state.ob_full_pix_y)
        if (color_r(ob_full_col) > _nft(200, 1)
                and color_g(ob_full_col) < _nft(30, -1)
                and color_b(ob_full_col) < _nft(30, -1)):
            _log(f"[!] OB full detected after {upload_count} items")
            ob_set_status("OB full — stopping")
            _sleep(2000)
            break

        # ── Early exit (Q pressed) ────────────────────────────────────────
        if state.ob_upload_early_exit:
            ob_set_status("Q pressed — waiting for refresh to clear...")
            early_wait = 0
            while not ob_overlay_clear() and early_wait < 200:
                early_wait += 1
                _sleep(50)
            state.ob_upload_early_exit = False
            ob_set_status(f"Stopped by Q — {upload_count} items uploaded")
            _sleep(1500)
            break

        _sleep(30)
        upload_count += 1

        refresh_clear_wait = 0
        while not ob_overlay_clear() and refresh_clear_wait < 60:
            if not state.ob_upload_running:
                break
            refresh_clear_wait += 1
            _sleep(50)
        _sleep(50)

        # ── Post-upload slot check ────────────────────────────────────────
        check1 = ob_item_present(detect_filter)

        if check1:
            last_upload_tick = _tick()
        else:
            if is_tek_filter:
                _log(f"[slot#{upload_count}] TEK pixel confirmed empty — done")
                _log(f"[6] Upload loop done after {upload_count} items")
                break

            w_tmp = px_get(state.ob_item_name_pix_x, state.ob_item_name_pix_y)
            t_tmp = px_get(state.ob_timer_pix_x, state.ob_timer_pix_y)
            w_r = color_r(w_tmp)
            w_g = color_g(w_tmp)
            w_b = color_b(w_tmp)
            t_r = color_r(t_tmp)
            t_g = color_g(t_tmp)
            t_b = color_b(t_tmp)
            looks_empty = (w_r < _nft(50, -1) and w_g < _nft(100, -1)
                           and w_b < _nft(130, -1) and t_r < _nft(50, -1)
                           and t_g < _nft(100, -1) and t_b < _nft(130, -1))
            if looks_empty:
                _log(f"[slot#{upload_count}] EMPTY (dark blue confirmed)")
                _log(f"[6] Upload loop done after {upload_count} items")
                break

            _log(f"[slot#{upload_count}] check1 EMPTY but not dark blue — polling for render...")
            render_wait = 0
            slot_rendered = False
            while render_wait < 30:
                if not state.ob_upload_running:
                    break
                _sleep(100)
                if ob_item_present(detect_filter):
                    slot_rendered = True
                    _log(f"[slot#{upload_count}] slot rendered after {(render_wait + 1) * 100}ms")
                    break
                render_wait += 1

            if slot_rendered:
                last_upload_tick = _tick()
            else:
                check2 = ob_item_present(detect_filter)
                _sleep(150)
                check3 = ob_item_present(detect_filter)
                if not check2 and not check3:
                    w_final = px_get(state.ob_item_name_pix_x, state.ob_item_name_pix_y)
                    t_final = px_get(state.ob_timer_pix_x, state.ob_timer_pix_y)
                    still_not_empty = not (
                        color_r(w_final) < _nft(50, -1)
                        and color_g(w_final) < _nft(100, -1)
                        and color_b(w_final) < _nft(130, -1)
                        and color_r(t_final) < _nft(50, -1)
                        and color_g(t_final) < _nft(100, -1)
                        and color_b(t_final) < _nft(130, -1)
                    )
                    if still_not_empty:
                        _log(f"[slot#{upload_count}] STILL not dark blue after "
                             f"render wait — re-applying filter to force refresh")
                        ob_clear_filter()
                        _sleep(200)
                        ob_apply_their_filter(filter_text)
                        _sleep(300)
                        mouse_move(int(state.my_first_slot_x), int(state.my_first_slot_y), 0)
                        _sleep(100)
                        click()
                        mouse_move(int(state.my_first_slot_x) - 150,
                                   int(state.my_first_slot_y), 0)
                        _sleep(300)
                        if ob_item_present(detect_filter):
                            _log(f"[slot#{upload_count}] filter re-apply found items — continuing")
                            last_upload_tick = _tick()
                        else:
                            _log(f"[6] Upload loop done after {upload_count} items "
                                 f"— confirmed empty after filter re-apply")
                            break
                    else:
                        _log(f"[6] Upload loop done after {upload_count} items "
                             f"— confirmed empty after render wait")
                        break
                else:
                    last_upload_tick = _tick()

        if _tick() - last_upload_tick > state.ob_upload_stall_ms:
            _log(f"[6] Stall timeout after {upload_count} items — OB may be full")
            ob_set_status("Stalled — OB may be full")
            _sleep(2000)
            break

    # ── Cleanup ───────────────────────────────────────────────────────────
    state.ob_upload_running = False
    if not skip_clear:
        ob_clear_filter()
    if close_on_done:
        if hwnd:
            control_send(hwnd, "{Escape}")
        else:
            send("{Escape}")
        _sleep(300)

    _log(f"Result: {done_msg} | Filter: {filter_text} | Uploaded: {upload_count}")
    ob_set_status(done_msg)
    _sleep(2000)
    ob_set_status("")
    return True


# ---------------------------------------------------------------------------
# Character upload — server cycling via arrow keys
# ---------------------------------------------------------------------------

def _ob_char_target_server() -> str:
    """Determine which server to show as target.

    Alternates between the custom server and 2386:
    - If custom is not 2386 and we last uploaded to custom → show 2386
    - Otherwise → show custom
    """
    custom = state.ob_char_custom_server or "2386"
    if custom != "2386" and state.ob_char_last_dest == custom:
        return "2386"
    return custom


def _ob_char_update_status():
    """Update the tooltip/status to show current char upload target."""
    target = _ob_char_target_server()
    ob_set_status(f"Upload Char F at trans {target}")


def _ob_char_cycle_server(direction: int):
    """Cycle through the server list with arrow keys (left=-1, right=+1)."""
    if not state.svr_list:
        return
    state.ob_char_svr_idx = (state.ob_char_svr_idx + direction) % len(state.svr_list)
    state.ob_char_custom_server = state.svr_list[state.ob_char_svr_idx]
    _ob_char_save_server()
    _ob_char_update_status()


def _ob_char_save_server():
    """Persist the current custom server to INI."""
    from core.config import write_ini
    if state.ob_char_custom_server:
        write_ini("UploadChar", "CustomServer", state.ob_char_custom_server)


def _ob_char_register_arrows():
    """Register left/right arrow hotkeys for server cycling while in char mode."""
    try:
        from core.hotkeys import HotkeyManager
        hk: HotkeyManager = state._hotkey_mgr
        hk.register("up", lambda: _ob_char_cycle_server(-1), suppress=True)
        hk.register("down", lambda: _ob_char_cycle_server(1), suppress=True)
    except Exception:
        pass


def _ob_char_unregister_arrows():
    """Unregister arrow key hotkeys when leaving char upload mode."""
    try:
        from core.hotkeys import HotkeyManager
        hk: HotkeyManager = state._hotkey_mgr
        hk.unregister("up")
        hk.unregister("down")
    except Exception:
        pass


# ---------------------------------------------------------------------------
# Upload cycle (F6 handler)
# ---------------------------------------------------------------------------

def ob_upload_cycle():
    """Cycle through upload modes: 0=off, 1=cryos, 2=tek+cryos, 3=character.

    Called when the user presses the F6 hotkey.  If a run is in progress,
    toggles pause instead.
    """
    if state.pc_mode > 0 or state.pc_f10_step > 0:
        state.pc_f10_step = 0
        state.pc_mode = 0
        state.pc_running = False
        ob_set_status("Switched to OB Upload — popcorn off")

    if state.ob_upload_running:
        if state.ob_upload_paused:
            state.ob_upload_paused = False
            ob_set_status("Resumed...")
        else:
            state.ob_upload_paused = True
            ob_set_status("OB Upload PAUSED — F6 = resume")
        return

    if state.ob_upload_mode == 3:
        _ob_char_unregister_arrows()

    state.ob_upload_mode = (state.ob_upload_mode + 1) % 4

    if state.ob_upload_mode == 0:
        ob_stop_all(hide_gui=False)
        return

    ark = _ark_hwnd()
    if ark:
        win_activate(ark)

    if state.ob_upload_mode == 1:
        state.ob_upload_filter = "cryop"
        state.ob_upload_armed = True
        uf_note = ""
        if state.uf_list:
            uf_note = f" — Filters: {', '.join(state.uf_list)}"
        ob_set_status(f"Cryos{uf_note}")

    elif state.ob_upload_mode == 2:
        state.ob_upload_filter = "Tek"
        state.ob_upload_armed = True
        ob_set_status("Tek+Cryos")

    elif state.ob_upload_mode == 3:
        state.ob_upload_armed = True
        if not state.svr_list:
            state.ob_char_custom_server = "2386"
        else:
            state.ob_char_svr_idx = state.ob_char_svr_idx % len(state.svr_list)
            state.ob_char_custom_server = state.svr_list[state.ob_char_svr_idx]
        _ob_char_update_status()
        _ob_char_register_arrows()


# ---------------------------------------------------------------------------
# F key handler
# ---------------------------------------------------------------------------

def ob_f_pressed():
    """Handle the F key press to start the appropriate upload mode.

    Must be called only when ``state.ob_upload_armed`` is True.
    Spawns a background thread for the actual upload work.
    """
    if not state.ob_upload_armed:
        return

    state.ob_upload_armed = False
    start_tick = _tick()

    if state.ob_upload_mode == 1:
        state.gui_visible = False
        if state.main_gui is not None:
            try:
                state.main_gui.hide()
            except Exception:
                pass
        state.ob_upload_running = True
        state.ob_init_failed = False
        state.ob_log = []
        state.ob_first_upload = True

        use_filter_list = bool(state.uf_list)

        def _run_cryo():
            try:
                if use_filter_list:
                    _log(f"=== CRYO run {datetime.now():%Y-%m-%d %H:%M:%S} "
                         f"filters={len(state.uf_list)} ===")
                    if ob_check_upload_timer(state.uf_list[0]):
                        return
                    for fi, uf in enumerate(state.uf_list, 1):
                        if state.ob_upload_early_exit:
                            break
                        state.ob_upload_running = True
                        state.ob_first_upload = (fi == 1)
                        skip_nav = fi > 1
                        skip_clear = True  # never clear between filters; final clear at end
                        ob_set_status(f"Cryos {fi}/{len(state.uf_list)} [{uf}]")
                        _log(f"[UF {fi}/{len(state.uf_list)}] filter='{uf}' skipNav={skip_nav}")
                        found = ob_run_upload(uf, f"Uploading {uf}", f"{uf} done",
                                              True, False, skip_nav, skip_clear, "cryop")
                        if state.ob_init_failed:
                            state.ob_upload_running = False
                            state.ob_upload_armed = True
                            ob_set_status("Not at transmitter — F to retry")
                            return
                        _log(f"[UF {fi}/{len(state.uf_list)}] result="
                             f"{'found items' if found else 'no items'}")
                        if state.ob_upload_early_exit:
                            _log(f"[UF] stopped by user at filter {fi}")
                            break
                    ob_clear_filter()
                else:
                    _log(f"=== CRYO run {datetime.now():%Y-%m-%d %H:%M:%S} "
                         f"filter=cryop ===")
                    if ob_check_upload_timer("cryop"):
                        return
                    ob_run_upload("cryop", "Uploading cryos", "Cryos done", False)
                    if state.ob_init_failed:
                        state.ob_upload_running = False
                        state.ob_upload_armed = True
                        ob_set_status("Not at transmitter — F to retry")
                        return

                ob_tooltip_restore()
                ob_stop_all()
            except Exception as e:
                import traceback
                _log(f"[ERROR] cryo thread: {e}")
                _log(f"[TRACEBACK] {traceback.format_exc()}")
                ob_stop_all()

        t = threading.Thread(target=_run_cryo, daemon=True, name="ob_upload_cryo")
        t.start()

    elif state.ob_upload_mode == 2:
        state.gui_visible = False
        if state.main_gui is not None:
            try:
                state.main_gui.hide()
            except Exception:
                pass
        state.ob_init_failed = False
        state.ob_log = []
        state.ob_first_upload = True
        state.ob_upload_running = True

        def _run_tek_cryo():
            try:
                _log(f"=== TEK+CRYO run {datetime.now():%Y-%m-%d %H:%M:%S} ===")
                if ob_check_upload_timer():
                    return

                tek_filters = ["ek et", "ek che", "ek gg", "ek ot", "ek sw", "ek fl"]
                tek_labels = ["Tek helmet/gauntlet", "Tek chest", "Tek leggings",
                              "Tek boots", "Tek sword", "Tek rifle"]
                any_tek_found = False

                for i, tf in enumerate(tek_filters):
                    if state.ob_upload_paused:
                        ob_set_status("PAUSED — F6 to resume")
                        while state.ob_upload_paused and state.ob_upload_running:
                            _sleep(100)
                        if not state.ob_upload_running:
                            break
                        if state.ob_active_filter:
                            _set_clipboard(state.ob_active_filter)
                            mouse_move(int(state.my_search_bar_x),
                                       int(state.my_search_bar_y), 0)
                            _sleep(30)
                            click()
                            _sleep(60)
                            send("^a")
                            _sleep(20)
                            send("^v")
                            _sleep(150)
                            mouse_move(int(state.my_first_slot_x),
                                       int(state.my_first_slot_y), 0)
                            _sleep(80)
                        ob_set_status("Resuming...")

                    state.ob_upload_running = True
                    state.ob_upload_early_exit = False
                    skip_nav = i > 0
                    skip_clear = True
                    ob_set_status(f"Tek {i + 1}/{len(tek_filters)} [{tf}]: {tek_labels[i]}...")
                    _log(f"[TEK {i + 1}/{len(tek_filters)}] filter='{tf}' skipNav={skip_nav}")
                    found = ob_run_upload(tf, f"Uploading {tek_labels[i]}",
                                          f"{tek_labels[i]} done",
                                          True, False, skip_nav, skip_clear)
                    if state.ob_init_failed:
                        state.ob_upload_running = False
                        state.ob_upload_armed = True
                        ob_set_status("Not at transmitter — F to retry")
                        return
                    _log(f"[TEK {i + 1}/{len(tek_filters)}] result="
                         f"{'found items' if found else 'no items found'}")
                    if found:
                        any_tek_found = True
                    if state.ob_upload_early_exit:
                        _log(f"[TEK] stopped by user (Q) at filter {i + 1}")
                        break

                _log(f"[TEK] phase complete. anyTekFound={'yes' if any_tek_found else 'no'}")

                if state.ob_upload_early_exit:
                    _log("[TEK+CRYO] stopped by user — skipping cryo phase")
                    state.ob_upload_early_exit = False
                    ob_tooltip_restore()
                    ob_stop_all()
                    return

                if not any_tek_found:
                    ob_set_status("No tek found — moving to cryos")
                _sleep(400)

                state.ob_upload_running = True
                state.ob_upload_early_exit = False
                _log("[CRYO] starting cryo phase")
                _set_clipboard("cryop")
                cryo_found = ob_run_upload("cryop", "Uploading cryos", "Cryos done",
                                           True, True, True)
                _log(f"[CRYO] result={'found items' if cryo_found else 'no cryos found'}")
                if not cryo_found:
                    ob_set_status("No cryos found")
                    _sleep(2000)

                ob_tooltip_restore()
                ob_stop_all()
            except Exception as e:
                _log(f"[ERROR] tek+cryo thread: {e}")
                ob_stop_all()

        t = threading.Thread(target=_run_tek_cryo, daemon=True, name="ob_upload_tek_cryo")
        t.start()

    elif state.ob_upload_mode == 3:
        _ob_char_unregister_arrows()
        state.gui_visible = False
        if state.main_gui is not None:
            try:
                state.main_gui.hide()
            except Exception:
                pass
        state.ob_upload_running = True
        state.ob_log = []
        _log(f"=== UPLOAD CHARACTER {datetime.now():%Y-%m-%d %H:%M:%S} ===")
        ob_set_status("Upload Character — waiting for transmitter screen")
        t = threading.Thread(target=ob_upload_character_thread, daemon=True,
                             name="ob_upload_char")
        t.start()


# ---------------------------------------------------------------------------
# Character upload
# ---------------------------------------------------------------------------

def ob_upload_character_thread():
    """Multi-step character transfer sequence.

    1. Wait for transmitter screen
    2. Check upload timer
    3. Click 'Travel to Another Server'
    4. Wait for server browser
    5. Search for target server
    6. Click session and join
    """
    wm = width_multiplier
    hm = height_multiplier
    state.ob_char_travel_x = round(1271 * wm)
    state.ob_char_travel_y = round(1060 * hm)

    if state.game_width == 0 or state.game_height == 0:
        hwnd = _ark_hwnd()
        if hwnd:
            from input.window import win_get_pos
            _, _, state.game_width, state.game_height = win_get_pos(hwnd)

    server_num = _ob_char_target_server()
    _log(f"Server: {server_num}  custom={state.ob_char_custom_server}  "
         f"lastDest={state.ob_char_last_dest}")

    # ── Step 1: Wait for transmitter ──────────────────────────────────────
    ob_set_status("Waiting for transmitter...")
    wait_count = 0
    found = False
    while state.ob_upload_running and wait_count < 250:
        try:
            if _nf_search_tol(state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                              state.ob_confirm_pix_x, state.ob_confirm_pix_y,
                              0xFFFFFF, 15):
                found = True
                break
        except Exception:
            pass
        _sleep(16)
        wait_count += 1

    if not found:
        _log(f"Transmitter not detected — timeout ({wait_count * 16}ms)")
        state.ob_upload_armed = True
        state.ob_upload_running = False
        ob_set_status("Not at transmitter — F to retry")
        return
    _log(f"Transmitter detected after {wait_count * 16}ms")

    # ── Step 2: Check upload timer ────────────────────────────────────────
    if ob_check_upload_timer():
        return

    state.ob_char_last_dest = server_num

    # ── Step 3: Click Travel to Another Server ────────────────────────────
    ob_set_status("Clicking Travel to Another Server...")
    _sleep(200)
    set_cursor_pos(state.ob_char_travel_x, state.ob_char_travel_y)
    _sleep(50)
    click()
    _sleep(500)
    _log("Clicked Travel button")

    obc_browser_x = round(1299 * wm)
    obc_browser_y = round(157 * hm)
    obc_search_x = round(1927 * wm)
    obc_search_y = round(245 * hm)
    obc_session_x = round(1316 * wm)
    obc_session_y = round(419 * hm)
    obc_join_x = round(2180 * wm)
    obc_join_y = round(1189 * hm)

    # ── Step 4: Wait for server browser ───────────────────────────────────
    ob_set_status("Waiting for server browser...")
    browser_found = False
    b_wait = 0
    while state.ob_upload_running and b_wait < 375:
        try:
            if _nf_search_tol(obc_browser_x, obc_browser_y,
                              obc_browser_x, obc_browser_y,
                              0xC1F5FF, 15):
                browser_found = True
                break
        except Exception:
            pass
        _sleep(16)
        b_wait += 1
    _log(f"Browser wait: {b_wait * 16}ms  found={browser_found}")

    if not browser_found:
        _log("Browser timeout")
        ob_set_status("Browser timeout")
        _sleep(2000)
        ob_stop_all()
        return

    if not state.ob_upload_running:
        return

    # ── Step 5: Search for server ─────────────────────────────────────────
    ob_set_status(f"Searching for server {server_num}...")
    _sleep(300)
    set_cursor_pos(obc_search_x, obc_search_y)
    _sleep(50)
    click()
    _sleep(100)
    send("^a")
    _sleep(50)
    send("{Delete}")
    _sleep(50)
    send_text(server_num)
    _sleep(300)
    _log(f"Searched for: {server_num}")

    obc_be_logo_x = round(235 * wm)
    obc_be_logo_y = round(427 * hm)
    set_cursor_pos(0, 0)
    _sleep(50)
    try:
        pre_be_col = px_get(obc_be_logo_x, obc_be_logo_y)
    except Exception:
        pre_be_col = None

    ob_set_status("Waiting for server to load...")
    be_found = False
    be_wait = 0
    while state.ob_upload_running and be_wait < 250:
        try:
            be_col = px_get(obc_be_logo_x, obc_be_logo_y)
            r = color_r(be_col)
            g = color_g(be_col)
            b = color_b(be_col)
            if r > _nft(100, 1) and g > _nft(200, 1) and b > _nft(230, 1):
                be_found = True
                _log(f"BE detected (color match): 0x{be_col:06X} @{be_wait * 16}ms")
                break
            if (state.nf_enabled and pre_be_col is not None and be_wait > 10):
                if color_distance(pre_be_col, be_col) > 40:
                    be_found = True
                    _log(f"BE detected (change): 0x{be_col:06X} @{be_wait * 16}ms")
                    break
        except Exception:
            pass
        _sleep(16)
        be_wait += 1

    if not be_found:
        _log(f"Server list timeout — BE logo not found after {be_wait * 16}ms")
        ob_set_status("Server list timeout")
        _sleep(2000)
        ob_stop_all()
        return
    _sleep(200)

    # ── Step 6: Click session ─────────────────────────────────────────────
    ob_set_status("Clicking session...")
    set_cursor_pos(obc_session_x, obc_session_y)
    _sleep(50)
    click()
    _sleep(500)
    set_cursor_pos(obc_session_x, obc_session_y)
    _sleep(50)
    click()
    _sleep(300)
    _log(f"Clicked session x2 ({obc_session_x},{obc_session_y})")

    # ── Step 7: Join server ───────────────────────────────────────────────
    ob_set_status(f"Joining server {server_num}...")
    join_confirmed = False
    join_attempts = 0

    while state.ob_upload_running and join_attempts < 10:
        join_attempts += 1
        set_cursor_pos(obc_join_x, obc_join_y)
        _sleep(50)
        click()
        _sleep(800)

        try:
            still_in_browser = _nf_search_tol(
                obc_browser_x, obc_browser_y,
                obc_browser_x, obc_browser_y,
                0xC1F5FF, 15)
            if not still_in_browser:
                join_confirmed = True
                _log(f"Join confirmed (browser gone) after {join_attempts} attempts")
                break
        except Exception:
            pass

        if join_attempts % 3 == 0:
            _log(f"Join not confirmed after {join_attempts} — re-clicking session")
            set_cursor_pos(obc_session_x, obc_session_y)
            _sleep(50)
            click()
            _sleep(500)
            set_cursor_pos(obc_session_x, obc_session_y)
            _sleep(50)
            click()
            _sleep(300)
        else:
            _sleep(300)

    if not join_confirmed:
        _log(f"Join not confirmed after {join_attempts} attempts — proceeding anyway")

    # ── Done ──────────────────────────────────────────────────────────────
    state.ob_upload_running = False
    state.ob_upload_armed = False
    state.ob_upload_mode = 0
    _log(f"Upload Char complete -> server {server_num}")
    ob_set_status(f"Upload Char done -> {server_num}")
    _sleep(2000)
    ob_set_status("")
