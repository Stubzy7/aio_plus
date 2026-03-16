
import logging
import time

from core.state import state
from core.config import read_ini, write_ini
from input.pixel import pixel_get_color, pixel_search, is_color_similar
from input.mouse import click, set_cursor_pos
from input.keyboard import send, send_text_vk, key_press
from input.window import win_exist, control_click
from input.ocr import from_rect

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


# ---------------------------------------------------------------------------
#  Imprint log
# ---------------------------------------------------------------------------

def _im_log(msg: str):
    ts = time.strftime("%H:%M:%S")
    state.imprint_log.append(f"{ts} {msg}")
    if len(state.imprint_log) > 50:
        state.imprint_log.pop(0)
    log.debug("Imprint: %s", msg)


# ---------------------------------------------------------------------------
#  Config persistence
# ---------------------------------------------------------------------------

def imprint_load_config():
    """Load imprint settings from AIO_config.ini."""
    from core.scaling import screen_width, screen_height

    saved = read_ini("Imprint", "InventoryKey", "")
    if not saved:
        # Fall back to shared Popcorn InvKey
        saved = read_ini("Popcorn", "InvKey", "")
    if saved:
        state.imprint_inventory_key = saved

    saved_w = read_ini("Imprint", "ScanW", "")
    saved_h = read_ini("Imprint", "ScanH", "")
    if saved_w and int(saved_w) >= 40:
        state.imprint_snap_w = int(saved_w)
    if saved_h and int(saved_h) >= 20:
        state.imprint_snap_h = int(saved_h)

    # Load saved position, or default to screen center
    saved_x = read_ini("Imprint", "ScanX", "")
    saved_y = read_ini("Imprint", "ScanY", "")
    if saved_x:
        state.imprint_snap_x = int(saved_x)
    else:
        state.imprint_snap_x = (screen_width // 2) - (state.imprint_snap_w // 2)
    if saved_y:
        state.imprint_snap_y = int(saved_y)
    else:
        state.imprint_snap_y = (screen_height // 2) - (state.imprint_snap_h // 2) + 20

    saved_hide = read_ini("Imprint", "HideOverlay", "0")
    state.imprint_hide_overlay = saved_hide == "1"


def imprint_save_config():
    """Persist imprint settings to AIO_config.ini."""
    write_ini("Imprint", "InventoryKey", state.imprint_inventory_key)
    write_ini("Imprint", "HideOverlay", "1" if state.imprint_hide_overlay else "0")


def imprint_save_scan_size():
    """Persist the scan-area dimensions and position."""
    write_ini("Imprint", "ScanW", str(state.imprint_snap_w))
    write_ini("Imprint", "ScanH", str(state.imprint_snap_h))
    write_ini("Imprint", "ScanX", str(state.imprint_snap_x))
    write_ini("Imprint", "ScanY", str(state.imprint_snap_y))


def imprint_update_size_txt():
    """Update the scan-area dimension label during resize.

    No-op stub kept for API completeness.
    """
    pass


# ---------------------------------------------------------------------------
#  Overlay (visual scan-area border)
# ---------------------------------------------------------------------------

def imprint_show_scan_overlay():
    """Display a thin red border around the OCR scan rectangle.

    Uses platform-specific overlay windows. Falls back to a no-op if
    the GUI toolkit is unavailable.
    """
    imprint_hide_scan_overlay()
    if state.imprint_hide_overlay and not state.imprint_resizing:
        return
    try:
        from gui.overlay import show_rect_overlay
        state.imprint_scan_overlay = show_rect_overlay(
            state.imprint_snap_x, state.imprint_snap_y,
            state.imprint_snap_w, state.imprint_snap_h,
            color="red", border=1,
        )
    except Exception:
        pass


def imprint_hide_scan_overlay():
    """Destroy the scan-area overlay."""
    if state.imprint_scan_overlay is not None:
        try:
            from gui.overlay import destroy_overlay
            destroy_overlay(state.imprint_scan_overlay)
        except Exception:
            pass
        state.imprint_scan_overlay = None


# ---------------------------------------------------------------------------
#  Arm / Disarm
# ---------------------------------------------------------------------------

def imprint_toggle_armed():
    """Toggle the imprint scanner on/off (Start/Stop button handler).

    When arming:
      - Hides the main GUI, shows the scan overlay.
      - Enables the R hotkey for single reads.
    When disarming:
      - Stops auto-scan if active, hides overlay and tooltip.
    """
    if state.imprint_scanning:
        imprint_stop_all()
        return

    # Gate: inventory key must be set before first use
    if not state.imprint_inventory_key:
        from core.config import read_ini as _ri
        saved_inv = _ri("Popcorn", "InvKey", "")
        if not saved_inv:
            log.warning("Imprint: inventory key not set — showing prompt")
            try:
                tab_pc = getattr(state, "_tab_popcorn", None)
                if tab_pc and state.root:
                    state.gui_visible = True
                    if state.main_gui:
                        state.main_gui.show()
                    state.root.after(0, tab_pc._show_set_keys_prompt)
            except Exception:
                _tooltip(" Imprint: inventory key not set!\n Open Popcorn tab → Set Keys")
            return
        state.imprint_inventory_key = saved_inv

    state.imprint_scanning = True
    state.imprint_auto_mode = False

    imprint_show_scan_overlay()

    state.gui_visible = False
    _tooltip("IMPRINT ARMED — R read | Q auto-scan\nF1 = stop")

    _im_log("Scanner armed")


def imprint_stop_all():
    """Fully stop the imprint scanner — auto mode, hotkeys, overlay."""
    state.imprint_scanning = False
    state.imprint_auto_mode = False

    if state.imprint_resizing:
        imprint_exit_resize()

    imprint_hide_scan_overlay()
    _tooltip(None)
    _im_log("Scanner stopped")


# ---------------------------------------------------------------------------
#  Auto-scan loop
# ---------------------------------------------------------------------------

def imprint_toggle_auto_mode():
    """Toggle auto-scan on/off (Q key handler while armed)."""
    if not state.imprint_scanning:
        return

    if state.imprint_auto_mode:
        state.imprint_auto_mode = False
        _tooltip("Auto-scan OFF\nARMED — R read | Q auto-scan")
        return

    state.imprint_auto_mode = True
    _tooltip("Auto-scan ON — scanning...")

    import threading
    threading.Thread(target=imprint_auto_scan_loop, daemon=True,
                     name="imprint_auto_scan").start()


def imprint_auto_scan_loop():
    """Continuously read the scan rectangle and process matched food names.

    Runs in a blocking loop (should be called from a worker thread or
    dispatched via ``SetTimer(-1)``).

    The loop sleeps 150 ms between OCR reads. When a food name is matched,
    it is processed and the loop pauses 1 s before resuming.
    """
    while state.imprint_scanning and state.imprint_auto_mode:
        try:
            ocr_text = from_rect(
                state.imprint_snap_x, state.imprint_snap_y,
                state.imprint_snap_w, state.imprint_snap_h,
                scale=3,
            )
        except Exception:
            time.sleep(0.150)
            continue

        matched = ""
        for food_name in state.imprint_all_foods:
            if food_name.lower() in ocr_text.lower():
                matched = food_name
                break

        if matched:
            _im_log(f"Auto-scan OCR: [{ocr_text}] -> matched [{matched}]")
            _tooltip(f"Detected: {matched}")
            imprint_process_food(matched, ocr_text)

            if state.imprint_scanning and state.imprint_auto_mode:
                imprint_show_scan_overlay()
                for i in range(2):
                    remaining = f"{(2 - i) * 0.5:.1f}"
                    _tooltip(f"{matched} -> Hotbar 0 — Feed now!\nResuming in {remaining}s...")
                    time.sleep(0.5)
                    if not state.imprint_scanning or not state.imprint_auto_mode:
                        break
                if state.imprint_scanning and state.imprint_auto_mode:
                    _tooltip("Auto-scan ON — scanning...")

        time.sleep(0.150)

    if state.imprint_scanning and not state.imprint_auto_mode:
        _tooltip("Auto-scan OFF\nARMED — R read | Q auto-scan")


# ---------------------------------------------------------------------------
#  Manual single read
# ---------------------------------------------------------------------------

def imprint_on_read_and_process():
    """Single manual OCR read (R key handler while armed)."""
    if not state.imprint_scanning:
        return

    _tooltip("Reading...")
    _im_log("Manual read triggered")

    try:
        ocr_text = from_rect(
            state.imprint_snap_x, state.imprint_snap_y,
            state.imprint_snap_w, state.imprint_snap_h,
            scale=3,
        )
    except Exception as exc:
        _im_log(f"OCR FAILED: {exc}")
        _tooltip("OCR failed — try again\nARMED — R read | Q auto-scan")
        return

    _im_log(f"OCR text: [{ocr_text}]")
    matched = ""
    for food_name in state.imprint_all_foods:
        if food_name.lower() in ocr_text.lower():
            matched = food_name
            break

    if not matched:
        _im_log(f"No match in: [{ocr_text}]")
        _tooltip(f"No food found: [{ocr_text}]\nARMED — R read | Q auto-scan")
        return

    _tooltip(f"Detected: {matched}")
    _im_log(f"Manual OCR: [{ocr_text}] -> matched [{matched}]")
    imprint_process_food(matched, ocr_text)

    if state.imprint_scanning:
        imprint_show_scan_overlay()
        _tooltip(f"Done: {matched}\nARMED — R read | Q auto-scan")


# ---------------------------------------------------------------------------
#  Food processing — the main automation sequence
# ---------------------------------------------------------------------------

def imprint_process_food(food_name: str, ocr_text: str = ""):
    """Open inventory, search for the food, assign to hotbar 0, feed.

    Steps:
      1. If food is "cuddle" — just press E and return.
      2. If the OCR text already contains "[E] Feed <food>" — press E directly.
      3. Otherwise: open inventory, wait for white pixel, click search bar,
         type the food name, click the first result, press 0 (hotbar assign),
         close inventory, wait for [E] feed prompt, press E.
    """
    # Cuddle shortcut
    if food_name.lower() == "cuddle":
        _im_log("Cuddle detected — pressing E")
        send("{e}")
        time.sleep(0.2)
        return

    # Already-visible feed prompt shortcut
    if ocr_text and "[E]" in ocr_text and "Feed" in ocr_text and food_name in ocr_text:
        _im_log(f"[E] Feed [{food_name}] already visible — pressing E directly")
        send("{e}")
        time.sleep(0.2)
        return

    _im_log(f"Opening inventory (key={state.imprint_inventory_key}) for [{food_name}]")
    send("{" + state.imprint_inventory_key + "}")
    time.sleep(0.050)

    inv_x = state.imprint_inv_pix_x
    inv_y = state.imprint_inv_pix_y
    inventory_open = False
    wait_count = 0
    while wait_count < 250:
        result = pixel_search(inv_x - 1, inv_y - 1, inv_x + 1, inv_y + 1, 0xFFFFFF, tolerance=10)
        if result is not None:
            inventory_open = True
            break
        time.sleep(0.016)
        wait_count += 1

    wait_ms = wait_count * 16
    _im_log(f"Inv wait: {wait_ms}ms  open={inventory_open}  pixel=({inv_x},{inv_y})")

    if not inventory_open:
        _im_log("FAIL: inventory timeout")
        _tooltip("[FAIL] Inventory timeout")
        return

    time.sleep(0.200)

    inv_still_open = pixel_search(inv_x - 1, inv_y - 1, inv_x + 1, inv_y + 1, 0xFFFFFF, tolerance=10) is not None
    _im_log(f"Pre-click verify: inv still open={inv_still_open}")
    if not inv_still_open:
        _im_log("FAIL: inventory closed during settle")
        _tooltip("[FAIL] Inventory closed")
        return

    search_x = int(state.my_search_bar_x)
    search_y = int(state.my_search_bar_y)
    hwnd = win_exist(state.ark_window)
    if hwnd:
        control_click(hwnd, search_x, search_y)
    _im_log(f"ControlClick search bar ({search_x},{search_y})")
    time.sleep(0.030)

    _im_log(f"Typing [{food_name}]")
    send_text_vk(food_name)
    time.sleep(0.400)

    result_x = state.imprint_result_x
    result_y = state.imprint_result_y
    _im_log(f"Click first slot ({result_x},{result_y})")
    set_cursor_pos(result_x, result_y)
    time.sleep(0.050)
    click()
    time.sleep(0.100)  # 100ms settle — let ARK register the click before hotbar key

    send("0")
    _im_log("Hotbar 0 assigned")
    time.sleep(0.200)  # critical — let ARK register the hotbar assignment

    _im_log("Closing inv, waiting for [E] feed prompt")
    send("{Escape}")

    close_wait = 0
    while close_wait < 125:
        result = pixel_search(inv_x - 1, inv_y - 1, inv_x + 1, inv_y + 1, 0xFFFFFF, tolerance=10)
        if result is None:
            break
        time.sleep(0.016)
        close_wait += 1

    _im_log(f"Inv closed after {close_wait * 16}ms, scanning for [E] prompt")

    # Wait for [E] Feed prompt via OCR — time-bounded (cap at 1s).
    feed_ready = False
    scan_wait = 0
    deadline = time.perf_counter() + 1.0
    while time.perf_counter() < deadline:
        try:
            e_text = from_rect(
                state.imprint_snap_x, state.imprint_snap_y,
                state.imprint_snap_w, state.imprint_snap_h,
                scale=3,
            )
            scan_wait += 1
            if "[E]" in e_text and "Feed" in e_text and food_name in e_text:
                feed_ready = True
                _im_log(f"[E] Feed [{food_name}] detected: [{e_text}]")
                break
        except Exception:
            pass
        time.sleep(0.016)

    if not feed_ready:
        _im_log(f"Feed prompt not found after {scan_wait} scans — pressing E anyway")

    send("{e}")
    time.sleep(0.100)
    _im_log(f"Done processing [{food_name}]")


# ---------------------------------------------------------------------------
#  Resize mode
# ---------------------------------------------------------------------------

def imprint_toggle_resize():
    """Enter or exit scan-area resize mode."""
    if state.imprint_resizing:
        imprint_exit_resize()
        return

    state.imprint_resizing = True

    # Update button text and status label
    try:
        tab_misc = getattr(state, "_tab_misc", None)
        if tab_misc:
            tab_misc.imprint_resize_btn.configure(text="Done")
            if hasattr(tab_misc, "imprint_status"):
                tab_misc.imprint_status.configure(
                    text="Arrows=resize  WASD=move  Enter=done")
    except Exception:
        pass

    imprint_show_scan_overlay()

    # Register arrow + WASD + Enter hotkeys for resizing/moving
    hk = getattr(state, "_hotkey_mgr", None)
    if hk:
        hk.register("up", imprint_resize_up, suppress=True)
        hk.register("down", imprint_resize_down, suppress=True)
        hk.register("left", imprint_resize_left, suppress=True)
        hk.register("right", imprint_resize_right, suppress=True)
        hk.register("w", imprint_move_up, suppress=True)
        hk.register("s", imprint_move_down, suppress=True)
        hk.register("a", imprint_move_left, suppress=True)
        hk.register("d", imprint_move_right, suppress=True)
        hk.register("return", imprint_exit_resize, suppress=True)

    _im_log("Resize mode entered")


def imprint_exit_resize():
    """Exit resize mode, save new dimensions, and hide overlay."""
    state.imprint_resizing = False

    # Unregister arrow + WASD + Enter hotkeys
    hk = getattr(state, "_hotkey_mgr", None)
    if hk:
        hk.unregister("up", imprint_resize_up)
        hk.unregister("down", imprint_resize_down)
        hk.unregister("left", imprint_resize_left)
        hk.unregister("right", imprint_resize_right)
        hk.unregister("w", imprint_move_up)
        hk.unregister("s", imprint_move_down)
        hk.unregister("a", imprint_move_left)
        hk.unregister("d", imprint_move_right)
        hk.unregister("return", imprint_exit_resize)

    # Restore button text and status label
    try:
        tab_misc = getattr(state, "_tab_misc", None)
        if tab_misc:
            tab_misc.imprint_resize_btn.configure(text="Resize")
            if hasattr(tab_misc, "imprint_status"):
                tab_misc.imprint_status.configure(
                    text="Press Start then R=read Q=auto")
    except Exception:
        pass

    imprint_hide_scan_overlay()
    imprint_save_scan_size()
    _im_log(f"Resize mode exited: {state.imprint_snap_w}x{state.imprint_snap_h}")


def imprint_resize_up():
    """Increase scan height by 20 px."""
    from core.scaling import screen_height
    state.imprint_snap_h = max(20, state.imprint_snap_h + 20)
    state.imprint_snap_y = (screen_height // 2) - (state.imprint_snap_h // 2) + 20
    imprint_show_scan_overlay()


def imprint_resize_down():
    """Decrease scan height by 20 px."""
    from core.scaling import screen_height
    state.imprint_snap_h = max(20, state.imprint_snap_h - 20)
    state.imprint_snap_y = (screen_height // 2) - (state.imprint_snap_h // 2) + 20
    imprint_show_scan_overlay()


def imprint_resize_right():
    """Increase scan width by 20 px."""
    from core.scaling import screen_width
    state.imprint_snap_w = max(40, state.imprint_snap_w + 20)
    state.imprint_snap_x = (screen_width // 2) - (state.imprint_snap_w // 2)
    imprint_show_scan_overlay()


def imprint_resize_left():
    """Decrease scan width by 20 px."""
    from core.scaling import screen_width
    state.imprint_snap_w = max(40, state.imprint_snap_w - 20)
    state.imprint_snap_x = (screen_width // 2) - (state.imprint_snap_w // 2)
    imprint_show_scan_overlay()


def imprint_move_up():
    """Move scan area up by 10 px."""
    state.imprint_snap_y = max(0, state.imprint_snap_y - 10)
    imprint_show_scan_overlay()


def imprint_move_down():
    """Move scan area down by 10 px."""
    from core.scaling import screen_height
    state.imprint_snap_y = min(screen_height - state.imprint_snap_h,
                               state.imprint_snap_y + 10)
    imprint_show_scan_overlay()


def imprint_move_left():
    """Move scan area left by 10 px."""
    state.imprint_snap_x = max(0, state.imprint_snap_x - 10)
    imprint_show_scan_overlay()


def imprint_move_right():
    """Move scan area right by 10 px."""
    from core.scaling import screen_width
    state.imprint_snap_x = min(screen_width - state.imprint_snap_w,
                               state.imprint_snap_x + 10)
    imprint_show_scan_overlay()
