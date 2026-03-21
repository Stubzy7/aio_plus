
import time
import logging

from core.state import state
from input.pixel import px_get, pixel_search
from input.mouse import mouse_move, click, mouse_down, mouse_up
from input.keyboard import send, send_text, key_down, key_up
from modules.nvidia_filter import nf_is_bright, nf_pixel_wait, nf_search_tol

log = logging.getLogger(__name__)

_MAX_LOG = 50


def ns_log(msg: str):
    ts = time.strftime("%H:%M:%S")
    entry = f"{ts} {msg}"
    state.ns_log_entries.append(entry)
    if len(state.ns_log_entries) > _MAX_LOG:
        state.ns_log_entries.pop(0)
    log.debug(msg)


def _wait_for_name_dialog(timeout_polls: int = 94) -> bool:
    wm = state.width_multiplier
    hm = state.height_multiplier
    x1 = int(1034 * wm)
    y1 = int(665 * hm)
    x2 = int(1036 * wm)
    y2 = int(667 * hm)

    baseline = 0
    for _ in range(timeout_polls):
        matched, baseline = nf_pixel_wait(x1, y1, x2, y2, 0x94D2EA, 30,
                                          baseline)
        if matched:
            return True
        time.sleep(0.016)
    return False


def _type_name_and_confirm(name: str):
    wm = state.width_multiplier
    hm = state.height_multiplier

    mouse_move(int(1241 * wm), int(664 * hm))
    click()
    time.sleep(0.020)

    send_text(name)
    time.sleep(0.020)

    mouse_move(int(1122 * wm), int(1014 * hm))
    click()


def claim_and_name_e_pressed(name: str):
    if nf_is_bright(state.invy_detect_x, state.invy_detect_y):
        return

    ns_log("E pressed — Claim & Name")
    if not _wait_for_name_dialog():
        ns_log("Name dialog NOT found — aborting")
        return

    ns_log("Name dialog found — typing name")
    _type_name_and_confirm(name)
    ns_log(f"Name applied: {name}")

    if state.qh_cryo_after:
        time.sleep(0.600)
        click()
        ns_log("Cryo click sent")


def name_and_spay_e_pressed(name: str):
    if not state.run_name_and_spay_script:
        return
    if nf_is_bright(state.invy_detect_x, state.invy_detect_y):
        return

    ns_log("E pressed — starting Name/Spay")
    ns_log(
        f"radial=({state.ns_radial_x},{state.ns_radial_y})  "
        f"altDetect=({state.ns_alt_radial_x},{state.ns_alt_radial_y})  "
        f"altClick=({state.ns_alt_click_x},{state.ns_alt_click_y})"
    )
    ns_log(
        f"alt2Detect=({state.ns_alt2_radial_x},{state.ns_alt2_radial_y})  "
        f"alt2Click=({state.ns_alt2_click_x},{state.ns_alt2_click_y})"
    )
    ns_log(
        f"spay=({state.ns_spay_x},{state.ns_spay_y})  "
        f"adminDetect=({state.ns_admin_pix_x},{state.ns_admin_pix_y})  "
        f"adminSpay=({state.ns_admin_spay_x},{state.ns_admin_spay_y})"
    )

    ns_log("[1] Waiting for name dialog pixel...")
    if not _wait_for_name_dialog():
        ns_log("[1] Name dialog NOT found — aborting")
        return

    ns_log("[1] Name dialog found — typing name")
    _type_name_and_confirm(name)
    ns_log(f"[1] Name applied: {name}")

    if not state.run_name_and_spay_script:
        ns_log("[!] Stopped by Q after naming")
        return

    ns_log("[2] Waiting 600ms before radial wheel...")
    time.sleep(0.600)
    ns_log("[2] Sending E down (hold)")
    key_down("e")
    time.sleep(0.300)

    radial_layout = "standard"
    for _ in range(20):
        result = nf_search_tol(
            state.ns_alt2_radial_x, state.ns_alt2_radial_y,
            state.ns_alt2_radial_x + 1, state.ns_alt2_radial_y + 1,
            0xFFFFFF, 10,
        )
        if result is not None:
            radial_layout = "alt2"
            break
        result = nf_search_tol(
            state.ns_alt_radial_x, state.ns_alt_radial_y,
            state.ns_alt_radial_x + 1, state.ns_alt_radial_y + 1,
            0xFFFFFF, 10,
        )
        if result is not None:
            radial_layout = "alt"
            break
        time.sleep(0.020)

    ns_log(f"[2] Radial wheel open — layout={radial_layout}")

    if radial_layout == "alt":
        ns_log(f"[3] Alt radial — clicking ({state.ns_alt_click_x},{state.ns_alt_click_y})")
        mouse_move(state.ns_alt_click_x, state.ns_alt_click_y)
    elif radial_layout == "alt2":
        ns_log(f"[3] Alt2 radial — clicking ({state.ns_alt2_click_x},{state.ns_alt2_click_y})")
        mouse_move(state.ns_alt2_click_x, state.ns_alt2_click_y)
    else:
        ns_log(f"[3] Standard radial — clicking ({state.ns_radial_x},{state.ns_radial_y})")
        mouse_move(state.ns_radial_x, state.ns_radial_y)
    time.sleep(0.100)
    click()
    ns_log("[3] Clicked radial option")
    time.sleep(0.100)

    is_admin = nf_search_tol(
        state.ns_admin_pix_x, state.ns_admin_pix_y,
        state.ns_admin_pix_x + 1, state.ns_admin_pix_y + 1,
        0xFFFFFF, 10,
    ) is not None

    if is_admin:
        ns_log(f"[4] Admin detected — holding at ({state.ns_admin_spay_x},{state.ns_admin_spay_y}) for 5.1s")
        mouse_move(state.ns_admin_spay_x, state.ns_admin_spay_y)
    else:
        ns_log(f"[4] Standard confirm — holding at ({state.ns_spay_x},{state.ns_spay_y}) for 5.1s")
        mouse_move(state.ns_spay_x, state.ns_spay_y)

    time.sleep(0.100)
    mouse_down("left")
    time.sleep(5.100)
    mouse_up("left")
    ns_log("[4] Released click after 5.1s hold")

    key_up("e")
    time.sleep(0.200)
    ns_log("[5] Released E — spay complete")

    if state.qh_cryo_after:
        time.sleep(0.300)
        click()
        ns_log("[6] Cryo click sent")
