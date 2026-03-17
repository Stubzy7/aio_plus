
import time
import threading
import logging

from core.state import state
from input.pixel import pixel_search, is_color_similar, px_get
from input.mouse import click, set_cursor_pos
from input.keyboard import send, send_text_vk, key_press
from input.window import win_exist, control_click

log = logging.getLogger(__name__)


def _show_tooltip(text: str | None = None):
    try:
        from gui.tooltip import show_tooltip, hide_tooltip
        if text:
            show_tooltip(text, 0, 0)
        else:
            hide_tooltip()
    except Exception:
        pass


GIVE_PRESETS = [
    ("Beer",     "Beer"),
    ("Berry",    "berry"),
    ("Charc",    "charc"),
    ("Cooked",   "coo"),
    ("Crystal",  "crystal"),
    ("Dust",     "dust"),
    ("Fert",     "fert"),
    ("Fiber",    "fiber"),
    ("Flint",    "flint"),
    ("Hide",     "hide"),
    ("Honey",    "honey"),
    ("Metal",    "metal"),
    ("Narcotic", "narco"),
    ("Oil",      "oil"),
    ("Paste",    "paste"),
    ("Pearl",    "pearl"),
    ("Poly",     "poly"),
    ("Raw",      "raw"),
    ("Spoiled",  "spoiled"),
    ("Stim",     "stim"),
    ("Stone",    "stone"),
    ("Sulfur",   "sulfur"),
    ("Thatch",   "thatch"),
    ("Wood",     "wood"),
]

TAKE_PRESETS = list(GIVE_PRESETS)


def _wait_for_their_inventory(timeout_ms: int = 6000) -> bool:
    x = int(1495 * state.width_multiplier)
    y = int(226 * state.height_multiplier)
    deadline = time.perf_counter() + timeout_ms / 1000.0
    while time.perf_counter() < deadline:
        color = px_get(x, y)
        if is_color_similar(color, 0xFFFFFF, tolerance=10):
            return True
        time.sleep(0.016)
    return False


def _get_ark_hwnd() -> int:
    return win_exist(state.ark_window)


def check_take(filter_text: str):
    hwnd = _get_ark_hwnd()
    if not hwnd:
        return
    control_click(hwnd, int(state.their_inv_search_bar_x), int(state.their_inv_search_bar_y))
    time.sleep(state.mf_search_bar_click_ms / 1000.0)
    send_text_vk(filter_text)
    time.sleep(state.mf_filter_settle_ms / 1000.0)
    control_click(hwnd, int(state.transfer_to_me_btn_x), int(state.transfer_to_me_btn_y))
    time.sleep(state.mf_transfer_settle_ms / 1000.0)


def check_give(filter_text: str):
    hwnd = _get_ark_hwnd()
    if not hwnd:
        return
    control_click(hwnd, int(state.my_search_bar_x), int(state.my_search_bar_y))
    time.sleep(state.mf_search_bar_click_ms / 1000.0)
    send_text_vk(filter_text)
    time.sleep(state.mf_filter_settle_ms / 1000.0)
    control_click(hwnd, int(state.transfer_to_other_btn_x), int(state.transfer_to_other_btn_y))
    time.sleep(state.mf_transfer_settle_ms / 1000.0)


def drop_one(filter_text: str):
    hwnd = _get_ark_hwnd()
    if not hwnd:
        return
    time.sleep(0.050)
    control_click(hwnd, int(state.their_inv_search_bar_x), int(state.their_inv_search_bar_y))
    time.sleep(0.010)
    send_text_vk(filter_text)
    time.sleep(0.100)
    control_click(hwnd, int(state.their_inv_drop_all_btn_x), int(state.their_inv_drop_all_btn_y))
    time.sleep(0.200)


def magic_f_build_tooltip() -> str:
    names = state.magic_f_preset_names
    dirs_ = state.magic_f_preset_dirs
    idx = state.magic_f_preset_idx

    if not names:
        return " Magic F \u2014 no presets selected\nF1 = Stop/UI"

    if state.magic_f_refill_mode:
        takes = [n for n, d in zip(names, dirs_) if d == "Take"]
        gives = [n for n, d in zip(names, dirs_) if d == "Give"]
        tt = " Take/Refill:"
        if takes:
            tt += "\n  Take: " + " + ".join(takes)
        if gives:
            tt += "\n  Give: " + " + ".join(gives)
        tt += "\nF at inventory  |  F1 = Stop/UI"
        return tt

    cur = names[idx - 1]
    direction = dirs_[idx - 1]

    if len(names) == 1:
        return f" Magic F: {direction} {cur}\nZ = Swap  |  F1 = Stop/UI"

    next_idx = (idx % len(names)) + 1
    next_label = f"Q \u2192 {names[next_idx - 1]}"

    line1 = f" Magic F: {direction} {cur}  ({next_label})"
    items_lines = []
    for i, (n, d) in enumerate(zip(names, dirs_), start=1):
        arrow = "\u25ba" if i == idx else " "
        items_lines.append(f"{arrow} {d} {n}")
    items = "\n".join(items_lines)
    return f"{line1}\n{items}\nQ = Cycle selected presets  |  Z = Swap  |  F1 = Stop/UI"


def magic_f_cycle_preset():
    if not state.run_magic_f_script:
        return
    if state.magic_f_refill_mode:
        return
    names = state.magic_f_preset_names
    if len(names) <= 1:
        return
    state.magic_f_preset_idx = (state.magic_f_preset_idx % len(names)) + 1
    log.debug("Magic F cycle -> preset %d: %s", state.magic_f_preset_idx,
              names[state.magic_f_preset_idx - 1])


def magic_f_swap_direction():
    if not state.run_magic_f_script:
        return
    if state.magic_f_refill_mode:
        return

    with state.lock:
        state.magic_f_preset_dirs = [
            "Take" if d == "Give" else "Give"
            for d in state.magic_f_preset_dirs
        ]

    try:
        tab = getattr(state, "_tab_magicf", None)
        root = state.root
        if tab and root:
            def _sync():
                give_vals = {n: v.get() for n, v in tab.give_vars.items()}
                take_vals = {n: v.get() for n, v in tab.take_vars.items()}
                for n in give_vals:
                    if n in tab.take_vars:
                        tab.take_vars[n].set(give_vals[n])
                    if n in tab.give_vars:
                        tab.give_vars[n].set(take_vals.get(n, False))
            root.after(0, _sync)
    except Exception:
        pass
    log.debug("Magic F: directions swapped")


def run_magic_f(give_checks: list[tuple[bool, str, str]],
                take_checks: list[tuple[bool, str, str]],
                custom_give_active: bool = False,
                custom_give_text: str = "",
                custom_take_active: bool = False,
                custom_take_text: str = ""):
    state.run_magic_f_script = True
    names: list[str] = []
    filters: list[str] = []
    dirs: list[str] = []

    give_entries: list[tuple[str, str]] = []
    for checked, label, filt in give_checks:
        if checked:
            give_entries.append((label, filt))
    if custom_give_active:
        for cf in state.mf_give_filter_list:
            give_entries.append((f"Custom [{cf}]", cf))
        ct = custom_give_text.strip()
        if ct and ct not in state.mf_give_filter_list:
            give_entries.append((f"Custom [{ct}]", ct))

    take_entries: list[tuple[str, str]] = []
    for checked, label, filt in take_checks:
        if checked:
            take_entries.append((label, filt))
    if custom_take_active:
        for cf in state.mf_take_filter_list:
            take_entries.append((f"Custom [{cf}]", cf))
        ct = custom_take_text.strip()
        if ct and ct not in state.mf_take_filter_list:
            take_entries.append((f"Custom [{ct}]", ct))

    if state.magic_f_refill_mode:
        for label, filt in take_entries:
            names.append(label)
            filters.append(filt)
            dirs.append("Take")
        for label, filt in give_entries:
            names.append(label)
            filters.append(filt)
            dirs.append("Give")
    else:
        for label, filt in give_entries:
            names.append(label)
            filters.append(filt)
            dirs.append("Give")
        for label, filt in take_entries:
            names.append(label)
            filters.append(filt)
            dirs.append("Take")

    with state.lock:
        state.magic_f_preset_names = names
        state.magic_f_preset_filters = filters
        state.magic_f_preset_dirs = dirs
        state.magic_f_preset_idx = 1

    log.info("Magic F armed: %d presets, refill=%s", len(names),
             state.magic_f_refill_mode)


def magic_f_pressed():
    names = state.magic_f_preset_names
    filters = state.magic_f_preset_filters
    dirs_ = state.magic_f_preset_dirs
    idx = state.magic_f_preset_idx

    if not names:
        return

    if not _wait_for_their_inventory(6000):
        log.warning("Magic F: inventory not detected within 6 s")
        return

    if state.magic_f_refill_mode:
        for i, (filt, direction) in enumerate(zip(filters, dirs_)):
            if not state.run_magic_f_script:
                break
            if direction == "Take":
                check_take(filt)
            else:
                check_give(filt)
        send("{Escape}")
        time.sleep(state.mf_transfer_settle_ms / 1000.0)
        _show_tooltip(magic_f_build_tooltip())
        return

    filt = filters[idx - 1]
    direction = dirs_[idx - 1]

    if direction == "Give":
        check_give(filt)
    else:
        check_take(filt)

    send("{Escape}")
    time.sleep(state.mf_transfer_settle_ms / 1000.0)
    _show_tooltip(magic_f_build_tooltip())


def magic_f_pressed_async():
    t = threading.Thread(target=magic_f_pressed, daemon=True,
                         name="magic-f-exec")
    t.start()


def stop_magic_f():
    state.run_magic_f_script = False
    state.magic_f_preset_idx = 1
    log.info("Magic F stopped")
