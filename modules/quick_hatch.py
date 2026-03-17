
import time
import logging

from core.state import state
from input.pixel import px_get, pixel_search, is_color_similar
from input.mouse import mouse_move, click as mouse_click
from input.keyboard import send, key_press
from input.window import win_exist
from modules.nvidia_filter import nf_search_tol, nf_pixel_wait

from input.window import win_exist, control_click

log = logging.getLogger(__name__)

_MODE_NAMES = {1: "All", 2: "Single"}
_MAX_LOG = 50


def qh_log(msg: str):
    ts = time.strftime("%H:%M:%S")
    entry = f"{ts} {msg}"
    state.qh_log_entries.append(entry)
    if len(state.qh_log_entries) > _MAX_LOG:
        state.qh_log_entries.pop(0)
    log.debug(msg)


def _color_diff_sum(c1: int, c2: int) -> int:
    r1 = (c1 >> 16) & 0xFF
    g1 = (c1 >> 8) & 0xFF
    b1 = c1 & 0xFF
    r2 = (c2 >> 16) & 0xFF
    g2 = (c2 >> 8) & 0xFF
    b2 = c2 & 0xFF
    return abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)


def qh_count_eggs() -> int:
    ref = state.qh_empty_color
    tol = state.qh_empty_tol
    count = 0
    for i in range(10):
        col = px_get(state.qh_egg_slot_x[i], state.qh_egg_slot_y[i])
        if _color_diff_sum(col, ref) <= tol:
            count += 1
    return count


def wait_for_pixel(x: int, y: int, color: int, tol: int = 10,
                   timeout_ms: int = 6000) -> bool:
    interval = 0.016
    max_polls = timeout_ms // 16
    baseline = 0
    for _ in range(max_polls):
        x1 = x - 2
        y1 = y - 2
        x2 = x + 2
        y2 = y + 2
        matched, baseline = nf_pixel_wait(x1, y1, x2, y2, color, tol,
                                          baseline)
        if matched:
            return True
        time.sleep(interval)
    return False


def qh_toggle_mode(mode: int):
    if state.qh_armed:
        return
    state.qh_mode = mode
    if mode in _MODE_NAMES:
        log.info("Quick Hatch mode: %s", _MODE_NAMES[mode])
    else:
        log.info("Quick Hatch mode: off")


def depo_build_tooltip() -> str:
    cycle = state.depo_cycle
    idx = state.depo_cycle_idx
    if not cycle or idx < 1:
        return ""
    parts = []
    for i, step in enumerate(cycle, start=1):
        arrow = " \u25ba " if i == idx else "   "
        if step["filter"]:
            parts.append(f'{arrow}Depo {step["label"]} [F=give]')
        else:
            mode_label = _MODE_NAMES.get(state.qh_mode, "Hatch")
            hatch_txt = f"Hatch {mode_label}" if state.qh_armed else "Hatch"
            parts.append(f"{arrow}{hatch_txt} [F=hatch]")
    tt = "\n".join(parts)
    if state.run_claim_and_name_script:
        tt += "\n E = Claim/Name (always on)"
    elif state.run_name_and_spay_script:
        tt += "\n E = Name/Spay (always on)"
    tt += "\n Q = cycle  |  F1 = stop"
    return tt


def depo_cycle_next():
    cycle = state.depo_cycle
    if not cycle:
        return
    state.depo_cycle_idx = (state.depo_cycle_idx % len(cycle)) + 1
    log.info("Depo cycle -> step %d/%d: %s", state.depo_cycle_idx, len(cycle),
             cycle[state.depo_cycle_idx - 1]["label"])


def depo_f_pressed():
    if state.qh_running:
        return

    from input.window import get_foreground_window, find_window
    from input.keyboard import send_text_vk

    cycle = state.depo_cycle
    idx = state.depo_cycle_idx
    if not cycle or idx < 1 or idx > len(cycle):
        return
    cur = cycle[idx - 1]
    if not cur["filter"]:
        return

    ark_hwnd = find_window(title=state.ark_window)
    if not ark_hwnd or get_foreground_window() != ark_hwnd:
        return

    wm = state.width_multiplier
    hm = state.height_multiplier

    their_inv_x = int(1495 * wm)
    their_inv_y = int(226 * hm)
    wait_count = 0
    inv_found = False
    while wait_count < 375:
        col = px_get(their_inv_x, their_inv_y)
        if is_color_similar(col, 0xFFFFFF, tolerance=10):
            inv_found = True
            break
        time.sleep(0.016)
        wait_count += 1
    if not inv_found:
        return

    hwnd = find_window(title=state.ark_window)
    from input.window import control_click
    control_click(hwnd, int(state.my_search_bar_x), int(state.my_search_bar_y))
    time.sleep(0.030)
    send_text_vk(cur["filter"])
    time.sleep(0.100)
    control_click(hwnd, int(state.transfer_to_other_btn_x), int(state.transfer_to_other_btn_y))
    time.sleep(0.100)
    send("{Escape}")
    time.sleep(0.100)
    qh_log(f"Depo {cur['label']}: transferred '{cur['filter']}'")


def qh_start():
    if (
        state.qh_armed
        or state.run_claim_and_name_script
        or state.run_name_and_spay_script
        or state.depo_eggs_active
        or state.depo_embryo_active
    ):
        state.qh_armed = False
        state.qh_running = False
        state.run_claim_and_name_script = False
        state.run_name_and_spay_script = False
        state.depo_eggs_active = False
        state.depo_embryo_active = False
        state.depo_cycle.clear()
        state.depo_cycle_idx = 0
        state.gui_visible = True
        log.info("Quick Hatch disarmed")
        return

    has_hatch = state.qh_mode > 0
    has_cn = getattr(state, "cn_enabled", False)
    has_ns = getattr(state, "ns_enabled", False)
    has_depo_e = getattr(state, "depo_eggs_enabled", False)
    has_depo_em = getattr(state, "depo_embryo_enabled", False)
    has_depo = has_depo_e or has_depo_em

    if not has_hatch and not has_cn and not has_ns and not has_depo:
        log.warning("Select at least one mode before starting Quick Hatch")
        return

    state.gui_visible = False

    state.depo_cycle = []
    if has_depo_e:
        state.depo_eggs_active = True
        state.depo_cycle.append({"label": "Eggs", "filter": "egg"})
    if has_depo_em:
        state.depo_embryo_active = True
        state.depo_cycle.append({"label": "Embryo", "filter": "Embryo"})
    if has_hatch and has_depo:
        state.depo_cycle.append({"label": "Hatch", "filter": ""})
    if has_depo:
        state.depo_cycle_idx = 1

    if has_hatch:
        state.qh_armed = True

    if has_cn:
        state.run_claim_and_name_script = True
        state.run_name_and_spay_script = False
    elif has_ns:
        state.run_name_and_spay_script = True
        state.run_claim_and_name_script = False

    mode_label = _MODE_NAMES.get(state.qh_mode, "?")
    log.info("Quick Hatch armed — %s mode, cn=%s ns=%s depo_cycle=%d steps",
             mode_label, has_cn, has_ns, len(state.depo_cycle))


def qh_f_pressed():
    if not state.qh_armed or state.qh_running:
        return

    from input.window import get_foreground_window, find_window
    ark_hwnd = find_window(title=state.ark_window)
    fg = get_foreground_window()
    if not ark_hwnd or fg != ark_hwnd:
        return

    state.qh_running = True
    start_tick = time.perf_counter()

    wm = state.width_multiplier
    hm = state.height_multiplier

    qh_log(
        f"F pressed — mode={state.qh_mode}  delay={state.qh_click_delay}ms  "
        f"click1=({state.qh_click1_x},{state.qh_click1_y})  "
        f"click2=({state.qh_click2_x},{state.qh_click2_y})"
    )
    qh_log(
        f"Inv pixel=({state.qh_inv_pix_x},{state.qh_inv_pix_y})  "
        f"res={state.screen_width}x{state.screen_height}  "
        f"wm={wm}  hm={hm}"
    )

    time.sleep(0.100)

    col_before = px_get(state.qh_inv_pix_x, state.qh_inv_pix_y)
    qh_log(f"Pre-wait color at inv pixel: 0x{col_before:06X}")

    inv_ready = wait_for_pixel(
        state.qh_inv_pix_x, state.qh_inv_pix_y, 0xFFFFFF, 10, 6000,
    )

    col_after = px_get(state.qh_inv_pix_x, state.qh_inv_pix_y)
    elapsed = (time.perf_counter() - start_tick) * 1000
    qh_log(f"WaitForPixel result={inv_ready}  color after: 0x{col_after:06X}  +{elapsed:.0f}ms")

    if inv_ready:
        qh_log("Inventory frame open — waiting for contents to load")

        content_loaded = False
        for poll in range(100):
            col1 = px_get(state.qh_egg_slot_x[0], state.qh_egg_slot_y[0])
            col_e = px_get(state.qh_empty_pix_x, state.qh_empty_pix_y)
            ref = state.qh_empty_color
            tol = state.qh_empty_tol

            if _color_diff_sum(col1, ref) <= tol or _color_diff_sum(col_e, ref) <= tol:
                content_loaded = True
                qh_log(f"Contents loaded after {poll + 1} polls  slot1=0x{col1:06X} emptyPix=0x{col_e:06X}")
                break
            time.sleep(0.020)

        if not content_loaded:
            qh_log(
                f"Contents load timeout — proceeding anyway  "
                f"slot1=0x{px_get(state.qh_egg_slot_x[0], state.qh_egg_slot_y[0]):06X}"
            )

        time.sleep(0.200)
        elapsed = (time.perf_counter() - start_tick) * 1000
        qh_log(f"Inventory ready — starting clicks +{elapsed:.0f}ms")

        # Enforce a minimum of 15ms to account for system timer granularity
        delay = max(state.qh_click_delay, 15) / 1000.0

        if state.qh_mode == 1:
            click_pairs = 0
            max_pairs = 200
            min_pairs = 3
            qh_log(
                f"All mode — emptyPix({state.qh_empty_pix_x},{state.qh_empty_pix_y}) "
                f"target=0x{state.qh_empty_color:06X} tol={state.qh_empty_tol}"
            )
            pre_col = px_get(state.qh_empty_pix_x, state.qh_empty_pix_y)
            qh_log(f"All mode — pre-loop pixel color: 0x{pre_col:06X}")

            while True:
                if click_pairs >= max_pairs:
                    qh_log(f"All mode — hit safety cap at {max_pairs} pairs")
                    break
                if not state.qh_running:
                    qh_log(f"All mode — stopped by Q after {click_pairs} pairs")
                    break

                mouse_move(state.qh_click1_x, state.qh_click1_y)
                time.sleep(delay)
                mouse_click()
                time.sleep(delay)
                mouse_move(state.qh_click2_x, state.qh_click2_y)
                time.sleep(delay)
                mouse_click()
                time.sleep(delay)
                click_pairs += 1

                if click_pairs >= min_pairs:
                    col = px_get(state.qh_empty_pix_x, state.qh_empty_pix_y)
                    diff = _color_diff_sum(col, state.qh_empty_color)
                    qh_log(f"All mode — pair {click_pairs}  emptyPix=0x{col:06X}  diff={diff}  tol={state.qh_empty_tol}")
                    if diff > state.qh_empty_tol:
                        # Triple-check to avoid transient UI shifts causing false positives
                        time.sleep(0.050)
                        col2 = px_get(state.qh_empty_pix_x, state.qh_empty_pix_y)
                        diff2 = _color_diff_sum(col2, state.qh_empty_color)
                        if diff2 > state.qh_empty_tol:
                            time.sleep(0.050)
                            col3 = px_get(state.qh_empty_pix_x, state.qh_empty_pix_y)
                            diff3 = _color_diff_sum(col3, state.qh_empty_color)
                            if diff3 > state.qh_empty_tol:
                                qh_log(f"All mode — empty confirmed after {click_pairs} pairs  "
                                       f"pixel=0x{col:06X}({diff}) -> 0x{col2:06X}({diff2}) -> 0x{col3:06X}({diff3})")
                                break
                            qh_log(f"All mode — false positive (3rd check) at pair {click_pairs} "
                                   f"(0x{col:06X} -> 0x{col2:06X} -> 0x{col3:06X}) — continuing")
                        else:
                            qh_log(f"All mode — false positive at pair {click_pairs} (0x{col:06X}({diff}) -> 0x{col2:06X}({diff2})) — continuing")

            qh_log(f"All mode — {click_pairs} click pairs done")

        else:
            scan1 = qh_count_eggs()
            time.sleep(0.050)
            scan2 = qh_count_eggs()
            egg_count = min(scan1, scan2)
            qh_log(f"Single mode — scan1: {scan1}  scan2: {scan2}  using: {egg_count}")

            if egg_count == 0:
                qh_log("Single mode — no eggs in inventory")
                from gui.tooltip import show_tooltip
                show_tooltip(" No eggs detected", 0, 0)
                import threading as _th
                def _restore_tt():
                    if state.depo_cycle:
                        show_tooltip(depo_build_tooltip(), 0, 0)
                    else:
                        tt = (f" Quick Hatch \u2014 {_MODE_NAMES.get(state.qh_mode, '?')}\n"
                              f"Press F at inventory  |  Q = Stop")
                        if state.run_claim_and_name_script:
                            tt += "\nE = Claim/Name (always on)"
                        elif state.run_name_and_spay_script:
                            tt += "\nE = Name/Spay (always on)"
                        show_tooltip(tt, 0, 0)
                _th.Timer(1.5, _restore_tt).start()
            else:
                mouse_move(state.qh_click1_x, state.qh_click1_y)
                time.sleep(delay)
                mouse_click()
                time.sleep(delay)
                mouse_move(state.qh_click2_x, state.qh_click2_y)
                time.sleep(delay)
                mouse_click()

                remaining = egg_count
                poll_count = 0
                for _ in range(80):
                    time.sleep(0.020)
                    poll_count += 1
                    remaining = qh_count_eggs()
                    if remaining < egg_count:
                        break

                qh_log(f"Single mode — pre: {egg_count}  post: {remaining}  polls: {poll_count}")

                from gui.tooltip import show_tooltip
                if state.depo_cycle:
                    show_tooltip(depo_build_tooltip(), 0, 0)
                else:
                    if remaining > 0:
                        s = "s" if remaining > 1 else ""
                        tt = f" Single \u2014 {remaining} egg{s} remaining\n"
                    else:
                        tt = f" Single \u2014 inventory empty\n"
                    tt += "Press F at inventory  |  Q = Stop"
                    if state.run_claim_and_name_script:
                        tt += "\nE = Claim/Name (always on)"
                    elif state.run_name_and_spay_script:
                        tt += "\nE = Name/Spay (always on)"
                    show_tooltip(tt, 0, 0)

        time.sleep(0.100)
        pix_x = int(1495 * wm)
        pix_y = int(226 * hm)
        pix_x2 = int(1490 * wm)
        pix_y2 = int(230 * hm)
        if nf_search_tol(pix_x2, pix_y, pix_x, pix_y2, 0xFFFFFF) is not None:
            from input.window import find_window
            from input.keyboard import control_send
            ark_hwnd = find_window(title=state.ark_window)
            if ark_hwnd:
                control_send(ark_hwnd, "{f}")
            else:
                send("{f}")
            qh_log("Sent F to close inventory (ControlSend)")
        else:
            qh_log("Inventory already closed — skipping close")

        # Auto-deposit only when NOT using depo cycle
        # (depo cycle = user controls depo/hatch order via Q + F)
        if not state.depo_cycle:
            if state.depo_eggs_active:
                qh_log("Deposit eggs cycle starting")
                _run_deposit_cycle("eggs")
            if state.depo_embryo_active:
                qh_log("Deposit embryo cycle starting")
                _run_deposit_cycle("embryo")
    else:
        qh_log("Inventory NOT detected — timed out")

    state.qh_running = False


def _run_deposit_cycle(item_type: str):
    from input.keyboard import send_text_vk

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        qh_log(f"Deposit {item_type}: no ARK window")
        return

    wm = state.width_multiplier
    hm = state.height_multiplier

    qh_log(f"Deposit {item_type}: looking down")
    time.sleep(0.3)

    send("{f}")
    time.sleep(0.1)

    their_inv_x = int(1495 * wm)
    their_inv_y = int(226 * hm)
    inv_opened = False
    for _ in range(250):
        col = px_get(their_inv_x, their_inv_y)
        if is_color_similar(col, 0xFFFFFF, tolerance=10):
            inv_opened = True
            break
        time.sleep(0.016)

    if not inv_opened:
        qh_log(f"Deposit {item_type}: container inventory did not open")
        return

    time.sleep(0.2)

    my_search_x = int(state.my_search_bar_x)
    my_search_y = int(state.my_search_bar_y)
    control_click(hwnd, my_search_x, my_search_y)
    time.sleep(0.05)

    search_term = "egg" if item_type == "eggs" else "embryo"
    send_text_vk(search_term)
    time.sleep(0.3)

    transfer_x = int(state.transfer_to_other_btn_x)
    transfer_y = int(state.transfer_to_other_btn_y)
    control_click(hwnd, transfer_x, transfer_y)
    time.sleep(0.2)

    send("{Escape}")
    time.sleep(0.3)
    qh_log(f"Deposit {item_type}: done")
