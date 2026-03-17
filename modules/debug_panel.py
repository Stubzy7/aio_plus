
import logging
import time

from core.state import state
from core.scaling import screen_width, screen_height, width_multiplier, height_multiplier
from input.pixel import pixel_get_color

log = logging.getLogger(__name__)


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


def _clipboard_set(text: str):
    try:
        root = state.root
        if root:
            root.clipboard_clear()
            root.clipboard_append(text)
            root.update()
            return
    except Exception:
        pass
    try:
        from util.clipboard import set_clipboard_text
        if not set_clipboard_text(text):
            log.error("Clipboard write failed")
    except Exception as e:
        log.error("Clipboard write failed: %s", e)


def _debug_px_check(label: str, x: int, y: int, expect: int, tol: int = 30) -> str:
    try:
        c = pixel_get_color(int(x), int(y))
    except Exception:
        c = 0
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF
    er = (expect >> 16) & 0xFF
    eg = (expect >> 8) & 0xFF
    eb = expect & 0xFF
    dist = abs(r - er) + abs(g - eg) + abs(b - eb)
    verdict = "PASS" if dist <= tol else "FAIL"
    return (
        f"  {label} ({x},{y}): 0x{c:06X}  R={r} G={g} B={b}"
        f"  [expect 0x{expect:06X} dist={dist} {verdict}]\n"
    )


def _debug_px(label: str, x: int, y: int) -> str:
    try:
        c = pixel_get_color(int(x), int(y))
    except Exception:
        c = 0
    r = (c >> 16) & 0xFF
    g = (c >> 8) & 0xFF
    b = c & 0xFF
    return f"  {label} ({x},{y}): 0x{c:06X}  R={r} G={g} B={b}\n"


def perf_log_push(module: str, start_tick: float, outcome: str = "done"):
    elapsed_ms = int((time.perf_counter() - start_tick) * 1000)
    ts = time.strftime("%H:%M:%S")
    state.perf_log.append({
        "module": module,
        "time": ts,
        "elapsed": elapsed_ms,
        "outcome": outcome,
    })
    if len(state.perf_log) > 50:
        state.perf_log.pop(0)


def _get_debug_context() -> str:
    if state.last_debug_context:
        return state.last_debug_context
    if state.qh_armed or state.qh_running or state.qh_log_entries:
        return "quickhatch"
    if state.run_name_and_spay_script or state.ns_log_entries:
        return "nameandspay"
    if state.run_claim_and_name_script:
        return "nameandspay"
    # Flag checks alone can't distinguish tabs that share a flag
    # (e.g. Popcorn and JoinSim both set pc_tab_active) — read notebook tab name
    try:
        gui = state.main_gui
        if gui and gui.notebook:
            idx = gui.notebook.index("current")
            tab_name = gui.notebook.tab(idx, "text").strip().lower()
            tab_map = {
                "joinsim": "joinsim",
                "magic f": "magicf",
                "autolvl": "autolvl",
                "popcorn": "popcorn",
                "sheep": "sheep",
                "craft": "craft",
                "macro": "macro",
                "misc": "misc",
            }
            if tab_name in tab_map:
                return tab_map[tab_name]
    except Exception:
        pass
    if state.macro_tab_active:
        return "macro"
    if state.pc_tab_active:
        return "popcorn"
    if state.ac_tab_active:
        return "craft"
    if state.sheep_tab_active:
        return "sheep"
    if state.run_magic_f_script:
        return "magicf"
    return "misc"


def show_debug_panel():
    ctx = _get_debug_context()

    ts = time.strftime("%H:%M:%S")
    out = f"AIO — Debug  [{ctx}]  {ts}\n{'=' * 30}\n"

    if ctx == "joinsim":
        out += _section_joinsim()
    elif ctx in ("craft",) or state.ac_running or state.ac_timed_armed or state.ac_grid_armed or state.ac_simple_armed:
        out += _section_craft()
    elif ctx == "popcorn":
        out += _section_popcorn()
    elif ctx == "feed":
        mode_str = {0: "Off", 1: "Raw Meat", 2: "Berry"}.get(state.quick_feed_mode, "?")
        out += f"Quick Feed mode: {mode_str}\n"
    elif ctx == "autoclick":
        if state.autoclicking:
            out += f"Autoclicker: ON — interval {state.autoclick_interval}ms\n"
        else:
            out += "Autoclicker: OFF\n"
    elif ctx == "quickhatch":
        out += _section_quickhatch()
    elif ctx == "macro":
        out += _section_macro()
    elif ctx == "gmk":
        out += f"Grab My Kit: {state.gmk_mode}\n"
    elif ctx == "magicf":
        out += _section_magicf()
    elif ctx == "nameandspay":
        out += _section_nameandspay()
    elif ctx == "misc":
        if state.qh_armed or state.qh_running or state.qh_log_entries:
            out += _section_quickhatch()
        elif state.run_name_and_spay_script or state.run_claim_and_name_script or state.ns_log_entries:
            out += _section_nameandspay()
        else:
            out += "Misc tab — no active module\n"
    else:
        out += "No hotkey used yet — open a tab or press a hotkey first\n"

    if ctx != "popcorn" and (state.pc_log_entries or state.pc_mode > 0 or state.pc_f10_step > 0):
        out += "\n=== POPCORN ===\n"
        out += f"Mode: {state.pc_mode}  F10: {state.pc_f10_step}  Speed: {state.pc_speed_names.get(state.pc_speed_mode, '?')}\n"
        if state.pc_log_entries:
            for v in state.pc_log_entries:
                out += f" {v}\n"
        else:
            out += "(no popcorn log entries)\n"

    out += _section_imprint()
    out += _section_autopin()

    out += f"\n=== NVIDIA FILTER (Per-Step Calibration) ===\n"
    out += f"Enabled: {'ON' if state.nf_enabled else 'OFF'}\n"

    out += _section_pixel_coordinates()
    out += _section_perf_summary()

    _clipboard_set(out)
    _tooltip(f"Debug copied  [{ctx}]")

    from core.timers import timers
    timers.set_timer("debug_tip", lambda: _tooltip(None), -2000)


def _section_joinsim() -> str:
    auto = getattr(state, "auto_sim_check", False)
    mode_str = "A" if state.sim_mode == 1 else "B"
    out = (
        f"Sim: {'RUNNING' if auto else 'OFF'}  Mode: SIM {mode_str}"
        f"  State: {state.sim_last_state}  Cycles: {state.sim_cycle_count}\n"
    )
    out += f"Tolerance: {state.col_tol}  UseLast: {state.use_last}  Mods: {state.mods_enabled}\n"
    out += (
        f"Counters: MM={state.mm} RM={state.rm} SM={state.sm}"
        f" WM={state.wm} JL={state.jl} nosessions={state.nosessions}"
        f" in={state.incounter}\n"
    )
    out += f"Stuck: state='{state.stuck_state}' count={state.stuck_count}\n\n"

    if state.sim_last_colors:
        out += "=== LAST COLOR SCAN ===\n"
        for item in state.sim_last_colors.split(" "):
            if item:
                out += f" {item}\n"
        out += "\n"

    if state.sim_log:
        out += "=== SIM LOG ===\n"
        for v in state.sim_log:
            out += f" {v}\n"
    else:
        out += "(no sim log entries)\n"
    return out


def _section_craft() -> str:
    craft_state = "idle"
    if state.ac_count_only_active:
        craft_state = f"Count Only active ({state.ac_ocr_stations} stations, {state.ac_ocr_total} items)"
    elif state.ac_simple_armed:
        craft_state = "Simple armed"
    elif state.ac_timed_armed:
        craft_state = f"Inventory Timed armed — {state.ac_active_item_name}"
    elif state.ac_grid_armed:
        craft_state = "Grid Walk armed"
    elif state.ac_running:
        craft_state = f"Running — {state.ac_active_item_name}"

    out = f"State : {craft_state}\n"
    out += f"Filter: {state.ac_active_filter or '—'}\n"

    if state.ac_preset_names:
        out += f"Presets ({len(state.ac_preset_names)}):  current=#{state.ac_preset_idx}\n"
        for i, n in enumerate(state.ac_preset_names):
            arrow = " > " if i + 1 == state.ac_preset_idx else "   "
            filt = state.ac_preset_filters[i] if i < len(state.ac_preset_filters) else ""
            out += f"{arrow}{n} [{filt}]\n"

    if state.ac_log:
        out += "=== CRAFT LOG ===\n"
        for v in state.ac_log:
            out += f" {v}\n"
    else:
        out += "(no craft log entries)\n"
    return out


def _section_popcorn() -> str:
    out = f"Popcorn mode: {state.pc_mode}  running: {state.pc_running}  earlyExit: {state.pc_early_exit}\n"
    presets = ""
    if state.pc_grinder_poly:
        presets += "Poly "
    if state.pc_grinder_metal:
        presets += "Metal "
    if state.pc_grinder_crystal:
        presets += "Crystal "
    if state.pc_preset_raw:
        presets += "Raw "
    if state.pc_preset_cooked:
        presets += "Cooked "
    out += f"Presets: {presets or '(none)'}\n"
    out += f"Custom: {'ON' if state.pc_all_custom_active else 'OFF'}  filter: [{state.pc_custom_filter}]\n"
    out += f"Speed: {state.pc_speed_names.get(state.pc_speed_mode, '?')}  F10 step: {state.pc_f10_step}\n\n"

    if state.pc_log_entries:
        out += "=== POPCORN LOG ===\n"
        for v in state.pc_log_entries:
            out += f" {v}\n"
    else:
        out += "(no popcorn log entries)\n"
    return out


def _section_quickhatch() -> str:
    mode_str = {0: "None", 1: "All", 2: "Single"}.get(state.qh_mode, "?")
    out = f"Quick Hatch mode: {mode_str}  armed: {state.qh_armed}  running: {state.qh_running}\n"
    out += f"Click1: ({state.qh_click1_x},{state.qh_click1_y})  Click2: ({state.qh_click2_x},{state.qh_click2_y})\n"
    out += f"InvPix: ({state.qh_inv_pix_x},{state.qh_inv_pix_y})  delay: {state.qh_click_delay}ms\n"
    out += (f"EmptyPix: ({state.qh_empty_pix_x},{state.qh_empty_pix_y})  "
            f"emptyColor: 0x{state.qh_empty_color:06X}  tol: {state.qh_empty_tol}\n")
    try:
        live = pixel_get_color(int(state.qh_empty_pix_x), int(state.qh_empty_pix_y))
        from modules.quick_hatch import _color_diff_sum
        diff = _color_diff_sum(live, state.qh_empty_color)
        out += f"EmptyPix LIVE: 0x{live:06X}  diff={diff}  {'MATCH' if diff <= state.qh_empty_tol else 'NO MATCH'}\n"
    except Exception:
        pass
    out += f"Cryo: {state.qh_cryo_after}  DinoName: {state.dino_name}\n"
    out += f"CN: {state.run_claim_and_name_script}  NS: {state.run_name_and_spay_script}\n"
    if state.depo_cycle:
        out += f"Depo cycle ({len(state.depo_cycle)} steps, idx={state.depo_cycle_idx}):\n"
        for i, step in enumerate(state.depo_cycle, 1):
            arrow = " > " if i == state.depo_cycle_idx else "   "
            out += f"{arrow}{step['label']} [{step['filter'] or 'hatch'}]\n"
    out += f"DepoEggsActive: {state.depo_eggs_active}  DepoEmbryoActive: {state.depo_embryo_active}\n"

    if state.qh_log_entries:
        out += "=== QUICK HATCH LOG ===\n"
        for v in state.qh_log_entries:
            out += f" {v}\n"
    else:
        out += "(no quick hatch log entries)\n"
    return out


def _section_macro() -> str:
    sel_name = "(none)"
    sel_type = ""
    idx = state.macro_selected_idx
    if 1 <= idx <= len(state.macro_list):
        sel_name = state.macro_list[idx - 1]["name"]
        sel_type = state.macro_list[idx - 1]["type"]

    out = f"Selected: #{idx} {sel_name} [{sel_type}]\n"
    out += (
        f"Armed: {state.macro_armed}  Playing: {state.macro_playing}"
        f"  ActiveIdx: {state.macro_active_idx}\n"
    )
    out += (
        f"Recording: {state.macro_recording}  GuidedRecording: {state.guided_recording}"
        f"  SingleItem: {state.guided_single_item}\n"
    )
    out += (
        f"ComboRunning: {state.combo_running}  ComboMode: {state.combo_mode}"
        f"  ComboFilterIdx: {state.combo_filter_idx}\n"
    )
    out += f"TabActive: {state.macro_tab_active}  HotkeysLive: {state.macro_hotkeys_live}\n"
    out += f"Macros ({len(state.macro_list)}):\n"

    for i, m in enumerate(state.macro_list):
        arrow = " > " if i + 1 == state.macro_selected_idx else "   "
        extra = ""
        mtype = m["type"]
        if mtype == "guided":
            fc = len(m.get("search_filters", []))
            ec = len(m.get("events", []))
            extra = f" inv:{m.get('inv_type','?')} filters:{fc} events:{ec}"
            if m.get("turbo"):
                extra += f" turbo:ON({m.get('turbo_delay', 30)})"
        elif mtype == "combo":
            pc = len(m.get("popcorn_filters", []))
            mf = len(m.get("magic_f_filters", []))
            extra = f" pop:{pc} mf:{mf}"
        elif mtype == "recorded":
            ec = len(m.get("events", []))
            extra = f" events:{ec} spd:{m.get('speed_mult', 1.0):.2f}"
            if m.get("loop_enabled"):
                extra += " LOOP"

        hk = m.get("hotkey", "") or "-"
        out += f"{arrow}{m['name']} ({mtype}) hk:{hk}{extra}\n"

    out += "\n"
    if state.macro_log_entries:
        out += "=== MACRO LOG ===\n"
        for v in state.macro_log_entries:
            out += f" {v}\n"
    else:
        out += "(no macro log entries)\n"
    return out


def _section_magicf() -> str:
    out = f"Magic F: {'ARMED' if state.run_magic_f_script else 'OFF'}\n"
    if state.magic_f_preset_names:
        out += f"Presets ({len(state.magic_f_preset_names)}):  current=#{state.magic_f_preset_idx}\n"
        for i, n in enumerate(state.magic_f_preset_names):
            arrow = " > " if i + 1 == state.magic_f_preset_idx else "   "
            d = state.magic_f_preset_dirs[i] if i < len(state.magic_f_preset_dirs) else ""
            f = state.magic_f_preset_filters[i] if i < len(state.magic_f_preset_filters) else ""
            out += f"{arrow}{d} {n} [{f}]\n"
    else:
        out += "(no presets built)\n"
    return out


def _section_nameandspay() -> str:
    out = f"Name/Spay: {'ON' if state.run_name_and_spay_script else 'OFF'}\n"
    out += f"RadialPix: ({state.ns_radial_x},{state.ns_radial_y})  SpayPix: ({state.ns_spay_x},{state.ns_spay_y})\n"
    out += f"wm: {width_multiplier}  hm: {height_multiplier}\n\n"
    if state.ns_log_entries:
        out += "=== NAME AND SPAY LOG ===\n"
        for v in state.ns_log_entries:
            out += f" {v}\n"
    else:
        out += "(no name and spay log entries)\n"
    return out


def _section_imprint() -> str:
    out = "\n=== AUTO IMPRINT ===\n"
    out += (
        f"Scanning: {'YES' if state.imprint_scanning else 'no'}"
        f"  AutoMode: {'YES' if state.imprint_auto_mode else 'no'}\n"
    )
    out += (
        f"InvKey: {state.imprint_inventory_key}"
        f"  Snap: ({state.imprint_snap_x},{state.imprint_snap_y}"
        f" {state.imprint_snap_w}x{state.imprint_snap_h})\n"
    )
    out += (
        f"InvPix: ({state.imprint_inv_pix_x},{state.imprint_inv_pix_y})"
        f"  Search: ({state.imprint_search_x},{state.imprint_search_y})"
        f"  Result: ({state.imprint_result_x},{state.imprint_result_y})\n"
    )
    if state.imprint_log:
        out += "--- LOG ---\n"
        for v in state.imprint_log:
            out += f" {v}\n"
    else:
        out += "(no imprint log)\n"
    return out


def _section_autopin() -> str:
    out = "\n=== AUTO PIN ===\n"
    out += f"Enabled: {'ON' if state.pin_auto_open else 'OFF'}  Polling: {'YES' if state.pin_poll_active else 'no'}\n"
    out += (
        f"Pixels (scaled): ({state.pin_pix1_x},{state.pin_pix1_y})"
        f" ({state.pin_pix2_x},{state.pin_pix2_y})"
        f" ({state.pin_pix3_x},{state.pin_pix3_y})"
        f" ({state.pin_pix4_x},{state.pin_pix4_y})\n"
    )
    out += f"Click target: ({state.pin_click_x},{state.pin_click_y})  tol: {state.pin_tol}\n"
    if state.pin_log:
        for v in state.pin_log:
            out += f" {v}\n"
    else:
        out += "(no pin log entries)\n"
    return out


def _section_pixel_coordinates() -> str:
    wm = width_multiplier
    hm = height_multiplier
    out = f"\n=== ALL PIXEL COORDINATES BY MODE ===\n"
    out += f"Resolution: {screen_width}x{screen_height}  wMult: {wm}  hMult: {hm}\n\n"

    out += "--- Shared (inv detect / search bar) ---\n"
    out += _debug_px_check("invyDetect", state.invy_detect_x, state.invy_detect_y, 0xFFFFFF)
    out += _debug_px("searchBar", state.my_search_bar_x, state.my_search_bar_y)
    out += _debug_px("firstSlot", state.my_first_slot_x, state.my_first_slot_y)
    out += _debug_px_check("invOpen", round(1495 * wm), round(226 * hm), 0xFFFFFF)

    out += "\n--- Auto Pin ---\n"
    out += _debug_px_check("pinPix1", state.pin_pix1_x, state.pin_pix1_y, 0xC1F5FF, 60)
    out += _debug_px_check("pinPix2", state.pin_pix2_x, state.pin_pix2_y, 0xC1F5FF, 60)
    out += _debug_px_check("pinPix3", state.pin_pix3_x, state.pin_pix3_y, 0xC1F5FF, 60)
    out += _debug_px_check("pinPix4", state.pin_pix4_x, state.pin_pix4_y, 0xC1F5FF, 60)

    out += "\n--- Macros (Guided/Combo) ---\n"
    out += _debug_px_check("pcInvDetect", state.pc_inv_detect_x, state.pc_inv_detect_y, 0xFFFFFF)

    out += "\n--- Macros (Pyro) ---\n"
    out += _debug_px("dismount", state.pyro_dismount_x, state.pyro_dismount_y)
    out += _debug_px("astTekDet", state.pyro_ast_tek_det_x, state.pyro_ast_tek_det_y)
    out += _debug_px("throwCheck", state.pyro_throw_check_x, state.pyro_throw_check_y)
    out += _debug_px("rideConfirm", state.pyro_ride_confirm_x, state.pyro_ride_confirm_y)

    out += "\n--- Imprint ---\n"
    out += _debug_px_check("imprintInvPix", state.imprint_inv_pix_x, state.imprint_inv_pix_y, 0xFFFFFF)
    out += _debug_px("imprintSearch", state.imprint_search_x, state.imprint_search_y)
    out += _debug_px("imprintResult", state.imprint_result_x, state.imprint_result_y)

    out += "\n--- OB Upload ---\n"
    out += _debug_px_check("obConfirm", state.ob_confirm_pix_x, state.ob_confirm_pix_y, 0xFFFFFF, 15)
    out += _debug_px("obRightTab", state.ob_right_tab_pix_x, state.ob_right_tab_pix_y)
    out += _debug_px("obUploadReady", state.ob_upload_ready_pix_x, state.ob_upload_ready_pix_y)
    dlc = pixel_get_color(int(state.ob_data_loaded_pix_x), int(state.ob_data_loaded_pix_y))
    dl_r = (dlc >> 16) & 0xFF
    dl_g = (dlc >> 8) & 0xFF
    dl_b = dlc & 0xFF
    dl_pass = 130 < dl_r < 190 and 180 < dl_g < 230 and 195 < dl_b < 245
    out += (f"  obDataLoaded ({state.ob_data_loaded_pix_x},{state.ob_data_loaded_pix_y}): "
            f"0x{dlc:06X}  R={dl_r} G={dl_g} B={dl_b}  "
            f"[need R:131-189 G:181-229 B:196-244 {'PASS' if dl_pass else 'FAIL'}]\n")
    out += _debug_px("obOverlay", state.ob_ov_pix_x, state.ob_ov_pix_y)
    out += _debug_px("obMaxItems", state.ob_max_items_pix_x, state.ob_max_items_pix_y)
    out += _debug_px("obFullPix", state.ob_full_pix_x, state.ob_full_pix_y)
    out += _debug_px("obItemName", state.ob_item_name_pix_x, state.ob_item_name_pix_y)
    out += _debug_px("obTimer", state.ob_timer_pix_x, state.ob_timer_pix_y)
    out += _debug_px("obInvFail", state.ob_inv_fail_btn_x, state.ob_inv_fail_btn_y)

    if state.ob_log:
        out += "\n--- OB Log (last 20) ---\n"
        for entry in state.ob_log[-20:]:
            out += f"  {entry}\n"

    return out


def _section_perf_summary() -> str:
    out = f"\n=== PERF SUMMARY (last {len(state.perf_log)} ops) ===\n"
    if not state.perf_log:
        out += "  (no operations logged yet)\n"
    else:
        for e in reversed(state.perf_log):
            out += f"  {e['time']} {e['module']} — {e['elapsed']}ms [{e['outcome']}]\n"
    return out
