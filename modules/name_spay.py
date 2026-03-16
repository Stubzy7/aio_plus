
import time
import logging

from core.state import state
from input.pixel import px_get, pixel_search
from input.mouse import mouse_move, click, mouse_down, mouse_up
from input.keyboard import send, send_text, key_down, key_up
from modules.nvidia_filter import nf_is_bright, nf_pixel_wait, nf_search_tol

log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
#  Circular log
# ---------------------------------------------------------------------------

_MAX_LOG = 50


def ns_log(msg: str):
    """Append a timestamped message to the Name/Spay circular log.

    Appends a timestamped message to the circular log.
    """
    ts = time.strftime("%H:%M:%S")
    entry = f"{ts} {msg}"
    state.ns_log_entries.append(entry)
    if len(state.ns_log_entries) > _MAX_LOG:
        state.ns_log_entries.pop(0)
    log.debug(msg)


# ---------------------------------------------------------------------------
#  Internal helpers
# ---------------------------------------------------------------------------

def _wait_for_name_dialog(timeout_polls: int = 94) -> bool:
    """Wait for the blue naming dialog pixel (0x94D2EA) to appear.

    Polls at ~16 ms intervals.  Returns True on detection.
    """
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
    """Click the name field, type the name, click OK."""
    wm = state.width_multiplier
    hm = state.height_multiplier

    mouse_move(int(1241 * wm), int(664 * hm))
    click()
    time.sleep(0.020)

    send_text(name)
    time.sleep(0.020)

    mouse_move(int(1122 * wm), int(1014 * hm))
    click()


# ---------------------------------------------------------------------------
#  Claim & Name  (E key handler)
# ---------------------------------------------------------------------------

def claim_and_name_e_pressed(name: str):
    """E key handler for Claim & Name mode.

    Claims the dino, opens rename dialog, pastes name. Reads cryo from checkbox state.
    """
    # Abort if an inventory is already open (bright pixel at detect coords)
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


# ---------------------------------------------------------------------------
#  Name & Spay  (E key handler)
# ---------------------------------------------------------------------------

def name_and_spay_e_pressed(name: str):
    """E key handler for Name & Spay mode.

    Names the dino and uses radial wheel to spay/neuter. Reads cryo from checkbox state.

    Sequence:
      1. Wait for & fill name dialog.
      2. Open radial wheel (hold E).
      3. Detect standard vs. alternate radial layout.
      4. Click the spay option; detect admin vs. standard confirm.
      5. Hold-click for 5.1 s to complete spay.
      6. Release E.
      7. Optionally cryo.
    """
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
        f"spay=({state.ns_spay_x},{state.ns_spay_y})  "
        f"adminDetect=({state.ns_admin_pix_x},{state.ns_admin_pix_y})  "
        f"adminSpay=({state.ns_admin_spay_x},{state.ns_admin_spay_y})"
    )

    # ── Step 1: Name dialog ─────────────────────────────────────────
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

    # ── Step 2: Open radial wheel ───────────────────────────────────
    ns_log("[2] Waiting 600ms before radial wheel...")
    time.sleep(0.600)
    ns_log("[2] Sending E down (hold)")
    key_down("e")
    time.sleep(0.300)

    alt_layout = False
    for _ in range(20):
        result = nf_search_tol(
            state.ns_alt_radial_x, state.ns_alt_radial_y,
            state.ns_alt_radial_x + 1, state.ns_alt_radial_y + 1,
            0xFFFFFF, 10,
        )
        if result is not None:
            alt_layout = True
            break
        time.sleep(0.020)

    ns_log(f"[2] Radial wheel open — alt={'YES' if alt_layout else 'NO'}")

    # ── Step 3: Click radial option ─────────────────────────────────
    if alt_layout:
        ns_log(f"[3] Alt radial — clicking ({state.ns_alt_click_x},{state.ns_alt_click_y})")
        mouse_move(state.ns_alt_click_x, state.ns_alt_click_y)
    else:
        ns_log(f"[3] Standard radial — clicking ({state.ns_radial_x},{state.ns_radial_y})")
        mouse_move(state.ns_radial_x, state.ns_radial_y)
    time.sleep(0.100)
    click()
    ns_log("[3] Clicked radial option")
    time.sleep(0.100)

    # ── Step 4: Spay/neuter hold ────────────────────────────────────
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

    # ── Step 5: Release E ───────────────────────────────────────────
    key_up("e")
    time.sleep(0.200)
    ns_log("[5] Released E — spay complete")

    # ── Step 6: Optional cryo ───────────────────────────────────────
    if state.qh_cryo_after:
        time.sleep(0.300)
        click()
        ns_log("[6] Cryo click sent")
