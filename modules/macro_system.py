
import logging
import threading
import time

from pal import system as _sys
from core.state import state
from core.config import (
    read_ini, read_ini_int, write_ini,
    _ini_path, _read_parser, _write_parser,
)
from core.timers import timers
from input.pixel import pixel_get_color, is_color_similar, pixel_search
from input.mouse import (
    click, mouse_move, mouse_down, mouse_up, set_cursor_pos, get_cursor_pos,
)
from input.keyboard import send, send_text, key_press, key_down, key_up
from input.window import win_exist, win_activate, get_foreground_window, control_click, find_input_child
from core.scaling import screen_width, screen_height

log = logging.getLogger(__name__)


def _tooltip(text: str | None = None):
    try:
        from gui.tooltip import show_tooltip, update_tooltip, hide_tooltip
        if text:
            update_tooltip(text)
        else:
            hide_tooltip()
    except Exception:
        if text:
            log.info("tooltip: %s", text)


def _macro_log(msg: str):
    ts = time.strftime("%H:%M:%S")
    state.macro_log_entries.append(f"{ts} {msg}")
    if len(state.macro_log_entries) > 100:
        state.macro_log_entries.pop(0)
    log.debug("Macro: %s", msg)


def _macro_speed_hint(m: dict) -> str:
    sp = m.get("speed_mult", 1.0)
    return f" Speed: {sp:.1f}x  (arrow-up/down adjust)"


def _macro_speed_bar(sp: float) -> str:
    filled = round((sp - 0.10) / (2.00 - 0.10) * 20)
    filled = max(0, min(20, filled))
    return "[" + "\u2588" * filled + "\u2591" * (20 - filled) + "]"


def _update_play_btn(text: str):
    tab = getattr(state, "_tab_macro", None)
    if tab is None:
        return
    root = getattr(state, "root", None)
    if root is None:
        return
    root.after(0, lambda: tab.play_btn.configure(text=text))


def _macro_is_busy() -> bool:
    return (
        state.guided_recording
        or state.combo_running
        or getattr(state, "pc_running", False)
        or getattr(state, "run_magic_f_script", False)
        or getattr(state, "run_claim_and_name_script", False)
        or getattr(state, "run_name_and_spay_script", False)
        or getattr(state, "ac_running", False)
        or getattr(state, "run_auto_lvl_script", False)
        or getattr(state, "ob_upload_running", False)
        or getattr(state, "ob_download_running", False)
        or getattr(state, "sheep_running", False)
        or getattr(state, "qh_running", False)
        or getattr(state, "quick_feed_mode", 0) > 0
        or getattr(state, "imprint_auto_mode", False)
        or getattr(state, "auto_sim_check", False)
        or getattr(state, "autoclicking", False)
        or getattr(state, "pc_mode", 0) > 0
        or getattr(state, "pc_f10_step", 0) > 0
        or getattr(state, "gmk_mode", "off") != "off"
    )


def macro_load_all():
    import os
    import configparser

    state.macro_list = []
    config_file = _ini_path()
    legacy_file = os.path.join(os.path.dirname(config_file), "AIO_macros.ini")

    if os.path.exists(legacy_file):
        _macro_log("MacroLoad: migrating from AIO_macros.ini")
        config_file = legacy_file

    _macro_log(f"MacroLoad: looking for {config_file}")
    if not os.path.exists(config_file):
        _macro_log("MacroLoad: INI not found — using defaults")
        _macro_ensure_defaults()
        return

    _macro_log("MacroLoad: INI found")
    cp = _read_parser(config_file)

    try:
        count = int(cp.get("MacroCount", "Count", fallback="0"))
        state.macro_selected_idx = int(cp.get("MacroCount", "Selected", fallback="1"))
    except Exception as exc:
        _macro_log(f"MacroLoad: ERROR reading MacroCount — {exc}")
        _macro_ensure_defaults()
        return

    _macro_log(f"MacroLoad: count={count} selected={state.macro_selected_idx}")

    for idx in range(1, count + 1):
        sec = f"Macro_{idx}"
        try:
            m: dict = {}
            m["name"] = cp.get(sec, "Name", fallback="")
            m["type"] = cp.get(sec, "Type", fallback="")
            m["hotkey"] = cp.get(sec, "Hotkey", fallback="")
            _macro_log(f"MacroLoad: [{idx}] name='{m['name']}' type={m['type']} hk={m['hotkey']}")

            if not m["name"] or not m["type"]:
                continue

            if m["type"] == "recorded":
                m["speed_mult"] = float(cp.get(sec, "SpeedMult", fallback="1.0"))
                m["loop_enabled"] = int(cp.get(sec, "Loop", fallback="0"))
                evt_count = int(cp.get(sec, "EventCount", fallback="0"))
                m["events"] = _load_events(cp, sec, evt_count)

            elif m["type"] == "repeat":
                keys_raw = cp.get(sec, "RepeatKeys", fallback="")
                if not keys_raw:
                    keys_raw = cp.get(sec, "RepeatKey", fallback="")
                m["repeat_keys"] = [k.strip() for k in keys_raw.split(",") if k.strip()]
                m["repeat_interval"] = int(cp.get(sec, "RepeatInterval", fallback="1000"))
                m["repeat_spam"] = int(cp.get(sec, "RepeatSpam", fallback="0"))
                m["repeat_movement"] = int(cp.get(sec, "RepeatMovement", fallback="1"))

            elif m["type"] == "pyro":
                m["speed_mult"] = float(cp.get(sec, "SpeedMult", fallback="1.0"))

            elif m["type"] == "guided":
                m["speed_mult"] = float(cp.get(sec, "SpeedMult", fallback="1.0"))
                m["loop_enabled"] = int(cp.get(sec, "Loop", fallback="0"))
                m["inv_type"] = cp.get(sec, "InvType", fallback="storage")
                m["mouse_speed"] = int(cp.get(sec, "MouseSpeed", fallback="0"))
                m["mouse_settle"] = int(cp.get(sec, "MouseSettle", fallback="30"))
                m["inv_load_delay"] = int(cp.get(sec, "InvLoadDelay", fallback="1500"))
                m["turbo"] = int(cp.get(sec, "Turbo", fallback="0"))
                m["turbo_delay"] = int(cp.get(sec, "TurboDelay", fallback="30"))
                m["player_search"] = int(cp.get(sec, "PlayerSearch", fallback="0"))
                filter_raw = cp.get(sec, "SearchFilters", fallback="")
                m["search_filters"] = [f.strip() for f in filter_raw.split("|") if f.strip()] if filter_raw else []
                evt_count = int(cp.get(sec, "EventCount", fallback="0"))
                m["events"] = _load_events(cp, sec, evt_count)

            elif m["type"] == "combo":
                pc_raw = cp.get(sec, "PopcornFilters", fallback="")
                m["popcorn_filters"] = []
                if pc_raw:
                    for part in pc_raw.split("|"):
                        m["popcorn_filters"].append("" if part.strip() == "<all>" else part.strip())
                mf_raw = cp.get(sec, "MagicFFilters", fallback="")
                m["magic_f_filters"] = [f.strip() for f in mf_raw.split("|") if f.strip()] if mf_raw else []
                m["take_count"] = int(cp.get(sec, "TakeCount", fallback="0"))
                m["take_filter"] = cp.get(sec, "TakeFilter", fallback="")

            state.macro_list.append(m)
            _macro_log(f"MacroLoad: [{idx}] '{m['name']}' loaded OK")

        except Exception as exc:
            _macro_log(f"MacroLoad: ERROR loading Macro_{idx} — {exc}")

    _macro_ensure_defaults()

    if os.path.exists(legacy_file):
        macro_save_all()
        try:
            os.remove(legacy_file)
            _macro_log("MacroLoad: migrated to AIO_config.ini, deleted AIO_macros.ini")
        except Exception:
            pass


def _load_events(cp, sec: str, count: int) -> list[dict]:
    events = []
    for i in range(1, count + 1):
        raw = cp.get(sec, f"E{i}", fallback="")
        if not raw:
            continue
        parts = raw.split("|")
        evt: dict = {"type": parts[0]}
        if evt["type"] == "K" and len(parts) >= 4:
            evt["dir"] = parts[1]
            evt["key"] = parts[2]
            evt["delay"] = int(parts[3])
        elif evt["type"] == "M" and len(parts) >= 4:
            evt["x"] = int(parts[1])
            evt["y"] = int(parts[2])
            evt["delay"] = int(parts[3])
        elif evt["type"] == "C" and len(parts) >= 6:
            evt["dir"] = parts[1]
            evt["btn"] = parts[2]
            evt["x"] = int(parts[3])
            evt["y"] = int(parts[4])
            evt["delay"] = int(parts[5])
        events.append(evt)
    return events


def macro_save_all():
    import configparser

    path = _ini_path()
    cp = _read_parser(path)

    try:
        old_count = int(cp.get("MacroCount", "Count", fallback="0"))
    except Exception:
        old_count = 0
    for i in range(1, old_count + 1):
        sec = f"Macro_{i}"
        if cp.has_section(sec):
            cp.remove_section(sec)
    if cp.has_section("MacroCount"):
        cp.remove_section("MacroCount")

    cp.add_section("MacroCount")
    cp.set("MacroCount", "Count", str(len(state.macro_list)))
    cp.set("MacroCount", "Selected", str(state.macro_selected_idx))

    for i, m in enumerate(state.macro_list, 1):
        sec = f"Macro_{i}"
        cp.add_section(sec)
        cp.set(sec, "Name", m["name"])
        cp.set(sec, "Type", m["type"])
        cp.set(sec, "Hotkey", m.get("hotkey", ""))

        if m["type"] == "recorded":
            cp.set(sec, "SpeedMult", f"{m.get('speed_mult', 1.0):.3f}")
            cp.set(sec, "Loop", str(int(m.get("loop_enabled", 0))))
            events = m.get("events", [])
            cp.set(sec, "EventCount", str(len(events)))
            _save_events(cp, sec, events)

        elif m["type"] == "repeat":
            keys_str = ",".join(m.get("repeat_keys", []))
            cp.set(sec, "RepeatKeys", keys_str)
            cp.set(sec, "RepeatInterval", str(m.get("repeat_interval", 1000)))
            cp.set(sec, "RepeatSpam", str(int(m.get("repeat_spam", 0))))
            cp.set(sec, "RepeatMovement", str(int(m.get("repeat_movement", 1))))

        elif m["type"] == "pyro":
            cp.set(sec, "SpeedMult", f"{m.get('speed_mult', 1.0):.3f}")

        elif m["type"] == "guided":
            cp.set(sec, "SpeedMult", f"{m.get('speed_mult', 1.0):.3f}")
            cp.set(sec, "Loop", str(int(m.get("loop_enabled", 0))))
            cp.set(sec, "InvType", m.get("inv_type", "storage"))
            cp.set(sec, "MouseSpeed", str(m.get("mouse_speed", 0)))
            cp.set(sec, "MouseSettle", str(m.get("mouse_settle", 30)))
            cp.set(sec, "InvLoadDelay", str(m.get("inv_load_delay", 1500)))
            cp.set(sec, "Turbo", str(int(m.get("turbo", 0))))
            cp.set(sec, "TurboDelay", str(m.get("turbo_delay", 30)))
            cp.set(sec, "PlayerSearch", str(int(m.get("player_search", 0))))
            cp.set(sec, "SearchFilters", "|".join(m.get("search_filters", [])))
            events = m.get("events", [])
            cp.set(sec, "EventCount", str(len(events)))
            _save_events(cp, sec, events)

        elif m["type"] == "combo":
            pc_list = m.get("popcorn_filters", [])
            cp.set(sec, "PopcornFilters", "|".join("<all>" if f == "" else f for f in pc_list))
            cp.set(sec, "MagicFFilters", "|".join(m.get("magic_f_filters", [])))
            cp.set(sec, "TakeCount", str(m.get("take_count", 0)))
            cp.set(sec, "TakeFilter", m.get("take_filter", ""))

    _write_parser(cp, path)
    _macro_log("MacroSaveAll: saved")


def _save_events(cp, sec: str, events: list[dict]):
    for j, evt in enumerate(events, 1):
        if evt["type"] == "K":
            cp.set(sec, f"E{j}", f"K|{evt['dir']}|{evt['key']}|{evt['delay']}")
        elif evt["type"] == "M":
            cp.set(sec, f"E{j}", f"M|{evt['x']}|{evt['y']}|{evt['delay']}")
        elif evt["type"] == "C":
            cp.set(sec, f"E{j}", f"C|{evt['dir']}|{evt['btn']}|{evt['x']}|{evt['y']}|{evt['delay']}")


def _macro_ensure_defaults():
    has_pyro = any(m["type"] == "pyro" for m in state.macro_list)
    has_yuty = any(m["type"] == "repeat" and "Yuty" in m["name"] for m in state.macro_list)
    has_cap_flak = any(m["type"] == "guided" and "Cap of flak" in m["name"] for m in state.macro_list)

    changed = False

    if not has_pyro:
        state.macro_list.append({
            "name": "Pyro",
            "type": "pyro",
            "hotkey": "r",
            "speed_mult": 1.0,
        })
        changed = True

    if not has_yuty:
        state.macro_list.append({
            "name": "Yuty Fear/Buff",
            "type": "repeat",
            "hotkey": "x",
            "repeat_keys": ["rbutton", "c"],
            "repeat_interval": 2000,
            "repeat_spam": 1,
            "repeat_movement": 0,
        })
        changed = True

    if not has_cap_flak:
        events = []
        slot_count = 60
        drop_key = "g"
        remaining = slot_count
        while remaining > 0:
            slot = 0
            for row in range(6):
                for col in range(int(state.pc_columns)):
                    slot += 1
                    if slot > remaining:
                        break
                    x = int(state.pc_start_slot_x + col * state.pc_slot_w)
                    y = int(state.pc_start_slot_y + row * state.pc_slot_h)
                    events.append({"type": "M", "x": x, "y": y, "delay": 0})
                    events.append({"type": "K", "dir": "p", "key": drop_key, "delay": 20})
                if slot > remaining:
                    break
            remaining -= min(slot, int(state.pc_columns) * 6)

        state.macro_list.append({
            "name": "Cap of flak",
            "type": "guided",
            "hotkey": "f",
            "speed_mult": 1.0,
            "loop_enabled": True,
            "inv_type": "storage",
            "mouse_speed": 0,
            "mouse_settle": 1,
            "inv_load_delay": 1500,
            "turbo": 1,
            "turbo_delay": 1,
            "player_search": 0,
            "search_filters": [],
            "events": events,
        })
        changed = True

    if changed:
        macro_save_all()


def macro_start_record():
    if state.macro_recording or state.macro_playing:
        return
    if len(state.macro_list) >= 10:
        _tooltip(" Max 10 macros — delete one first")
        return

    state.macro_record_events = []
    mx, my = get_cursor_pos()
    state.macro_record_last_mouse_x = mx
    state.macro_record_last_mouse_y = my
    state.macro_recording = True

    state.gui_visible = False
    hwnd = win_exist(state.ark_window)
    if hwnd:
        win_activate(hwnd)
    time.sleep(0.5)

    state.macro_record_last_tick = time.perf_counter()

    timers.set_timer("macro_record_mouse_poll", _macro_record_mouse_poll, 50)
    _tooltip(" RECORDING...  (0 events)\n F1 = Stop & Save")
    _macro_log("Recording started")


def macro_stop_record() -> bool:
    if not state.macro_recording:
        return False
    state.macro_recording = False
    timers.stop_timer("macro_record_mouse_poll")
    _tooltip(None)

    if not state.macro_record_events:
        _tooltip(" Recording empty — discarded")
        timers.set_timer("rec_discard_tip", lambda: _tooltip(None), -2000)
        _macro_log("Recording discarded (empty)")
        return True

    event_count = len(state.macro_record_events)
    _macro_log(f"Recording stopped with {event_count} events")

    idx = state.macro_record_target_idx
    if idx is not None and 0 <= idx < len(state.macro_list):
        m = state.macro_list[idx]
        m["events"] = list(state.macro_record_events)
        if m["type"] == "recorded":
            macro_save_all()
            _tooltip(f" Recording saved: {m.get('name', 'Macro')} ({event_count} events)")
            _macro_log(f"Saved to slot {idx}: {m.get('name', 'Macro')}")
            timers.set_timer("rec_save_tip", lambda: _tooltip(None), -3000)
            state.macro_record_events = []
            return True

    if state.root:
        state.root.after(0, _macro_show_save_dialog)
    else:
        _macro_auto_save_recording()
    return True


def _macro_auto_save_recording():
    event_count = len(state.macro_record_events)
    name = f"Recording {time.strftime('%H:%M')}"
    new_macro = {
        "name": name,
        "type": "recorded",
        "hotkey": "",
        "events": list(state.macro_record_events),
        "speed_mult": 1.0,
        "loop_enabled": 0,
    }
    state.macro_list.append(new_macro)
    macro_save_all()
    _tooltip(f" Recording saved: {name} ({event_count} events)")
    _macro_log(f"Auto-saved new macro: {name}")
    timers.set_timer("rec_save_tip", lambda: _tooltip(None), -3000)
    state.macro_record_events = []


def _macro_show_save_dialog():
    import tkinter as tk
    from gui.theme import (BG_DARK, BG_COLOR, FG_COLOR, FG_ACCENT, FG_DIM,
                           FONT_BOLD, FONT_DEFAULT, FONT_SMALL, FONT_SMALL_ITALIC,
                           CB_OPTS)

    event_count = len(state.macro_record_events)
    events_copy = list(state.macro_record_events)

    dlg = tk.Toplevel()
    dlg.title("Save Recording")
    dlg.configure(bg=BG_DARK)
    dlg.attributes("-topmost", True)
    dlg.resizable(False, False)
    dlg.geometry("280x220")
    state.macro_save_gui = dlg

    tk.Label(dlg, text=f"Recording: {event_count} events", bg=BG_DARK,
             fg=FG_ACCENT, font=FONT_BOLD).place(x=15, y=10, width=250)

    tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
             font=FONT_DEFAULT).place(x=15, y=45, width=55)
    name_edit = tk.Entry(dlg, font=FONT_DEFAULT)
    name_edit.insert(0, f"Recording {time.strftime('%H:%M')}")
    name_edit.place(x=75, y=45, width=180, height=24)

    tk.Label(dlg, text="Hotkey:", bg=BG_DARK, fg=FG_COLOR,
             font=FONT_DEFAULT).place(x=15, y=78, width=55)
    hk_edit = tk.Entry(dlg, font=FONT_DEFAULT)
    hk_edit.place(x=75, y=78, width=100, height=24)

    _excluded = {"shift_l", "shift_r", "control_l", "control_r",
                 "alt_l", "alt_r", "escape", "caps_lock", "tab",
                 "super_l", "super_r", "f1", "f2", "f3"}

    def _detect_hk():
        hk_edit.delete(0, tk.END)
        hk_edit.insert(0, "Press key...")
        def on_key(event):
            k = event.keysym.lower()
            if k in _excluded:
                return
            hk_edit.delete(0, tk.END)
            hk_edit.insert(0, k)
            dlg.unbind("<Key>", bid)
        bid = dlg.bind("<Key>", on_key)

    tk.Button(dlg, text="Detect", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
              command=_detect_hk).place(x=180, y=78, width=75, height=24)

    loop_var = tk.BooleanVar()
    tk.Checkbutton(dlg, text="Loop playback", variable=loop_var,
                   **CB_OPTS).place(x=15, y=112, width=120)

    def _save():
        n = name_edit.get().strip()
        if not n:
            return
        new_macro = {
            "name": n,
            "type": "recorded",
            "hotkey": hk_edit.get().strip().lower(),
            "events": events_copy,
            "speed_mult": 1.0,
            "loop_enabled": int(loop_var.get()),
        }
        state.macro_list.append(new_macro)
        macro_save_all()
        _macro_log(f"SaveDialog: saved '{n}' ({event_count} events)")
        state.macro_record_events = []
        state.macro_save_gui = None
        dlg.destroy()
        if hasattr(state, "_tab_macro") and state._tab_macro:
            state._tab_macro._refresh_list()

    def _discard():
        _macro_log("SaveDialog: recording discarded")
        state.macro_record_events = []
        state.macro_save_gui = None
        dlg.destroy()

    tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT, bg=BG_COLOR,
              command=_save).place(x=15, y=150, width=100, height=26)
    tk.Button(dlg, text="Discard", font=FONT_BOLD, fg=FG_COLOR, bg=BG_COLOR,
              command=_discard).place(x=120, y=150, width=100, height=26)

    dlg.protocol("WM_DELETE_WINDOW", _discard)


def _macro_record_mouse_poll():
    if not state.macro_recording:
        return
    mx, my = get_cursor_pos()
    dx = abs(mx - state.macro_record_last_mouse_x)
    dy = abs(my - state.macro_record_last_mouse_y)
    if dx + dy > 12:
        now = time.perf_counter()
        delay_ms = int((now - state.macro_record_last_tick) * 1000)
        state.macro_record_last_tick = now
        state.macro_record_last_mouse_x = mx
        state.macro_record_last_mouse_y = my
        state.macro_record_events.append({
            "type": "M", "x": mx, "y": my, "delay": delay_ms,
        })


def macro_record_key_event(key: str, direction: str = "p"):
    if not state.macro_recording:
        return
    now = time.perf_counter()
    delay_ms = int((now - state.macro_record_last_tick) * 1000)
    state.macro_record_last_tick = now
    state.macro_record_events.append({
        "type": "K", "dir": direction, "key": key, "delay": delay_ms,
    })
    _tooltip(f" RECORDING...  ({len(state.macro_record_events)} events)\n F1 = Stop & Save")


def macro_record_mouse_event(button: str, direction: str, mx: int, my: int):
    if not state.macro_recording:
        return
    now = time.perf_counter()
    delay_ms = int((now - state.macro_record_last_tick) * 1000)
    state.macro_record_last_tick = now
    state.macro_record_last_mouse_x = mx
    state.macro_record_last_mouse_y = my
    state.macro_record_events.append({
        "type": "C", "dir": direction, "btn": button,
        "x": mx, "y": my, "delay": delay_ms,
    })
    _tooltip(f" RECORDING...  ({len(state.macro_record_events)} events)\n F1 = Stop & Save")


def macro_start_guided_record(name: str, inv_type: str,
                               search_filters: list[str],
                               on_done=None):
    state.guided_recording = True
    state.guided_record_events = []
    state.macro_recording = True
    state.macro_record_events = []

    hwnd = win_exist(state.ark_window)
    if hwnd:
        win_activate(hwnd)

    _tooltip(
        f" GUIDED RECORDING: {name}\n"
        f" Open inventory, do actions, F1 = stop\n"
        f" Inv: {inv_type}  Filters: {len(search_filters)}"
    )

    def _wait_thread():
        while state.macro_recording:
            time.sleep(0.1)
        state.guided_recording = False
        m = {
            "name": name, "type": "guided", "hotkey": "f",
            "speed_mult": 1.0, "loop_enabled": False,
            "inv_type": inv_type,
            "mouse_speed": 0, "mouse_settle": 1,
            "inv_load_delay": 1500, "turbo": 1, "turbo_delay": 1,
            "player_search": 0,
            "search_filters": search_filters,
            "events": list(state.macro_record_events),
        }
        _macro_log(f"GuidedRecord done: {len(m['events'])} events")
        if on_done:
            on_done(m)

    threading.Thread(target=_wait_thread, daemon=True).start()


def macro_play_selected():
    if state.macro_playing:
        return
    if state.macro_selected_idx < 1 or state.macro_selected_idx > len(state.macro_list):
        _tooltip(" Select a macro first")
        return

    state.macro_armed = True
    state.gui_visible = False
    if state.main_gui:
        state.main_gui.hide()
    _update_play_btn("Stop")
    hwnd = win_exist(state.ark_window)
    if hwnd:
        win_activate(hwnd)

    sel = state.macro_list[state.macro_selected_idx - 1]
    _macro_log(f"PlaySelected: armed '{sel['name']}' type={sel['type']} hk={sel.get('hotkey','')}")

    macro_register_hotkeys(True)

    if sel["type"] in ("guided", "combo"):
        _macro_log("PlaySelected: launching immediately")
        macro_play_by_index(state.macro_selected_idx)
    else:
        key_str = f" [{sel['hotkey'].upper()}]" if sel.get("hotkey") else ""
        _tooltip(
            f" > {sel['name']} armed{key_str}\n"
            f"{_macro_speed_hint(sel)}\n"
            f" Tap to run  |  Z = next  |  F1 = disarm"
        )


def macro_play_by_index(idx: int):
    if state.macro_playing or idx < 1 or idx > len(state.macro_list):
        return

    state.macro_selected_idx = idx
    state.macro_playing = True
    state.macro_active_idx = idx

    m = state.macro_list[idx - 1]
    keys = m.get("repeat_keys", [])
    bg_click = (m["type"] == "repeat" and len(keys) == 1
                and keys[0].lower() == "lbutton")

    state.gui_visible = False
    if bg_click:
        root = getattr(state, "root", None)
        if root:
            root.after(0, root.withdraw)
    else:
        hwnd = win_exist(state.ark_window)
        if hwnd and get_foreground_window() != hwnd:
            win_activate(hwnd)
        time.sleep(0.2)
    if m["type"] == "recorded":
        t = threading.Thread(target=macro_play_recorded_thread, args=(m,), daemon=True)
        t.start()
    elif m["type"] == "repeat":
        t = threading.Thread(target=macro_play_repeat_thread, args=(m, bg_click), daemon=True)
        t.start()
    elif m["type"] == "pyro":
        t = threading.Thread(target=_macro_play_pyro_thread, args=(m,), daemon=True)
        t.start()
    elif m["type"] == "guided":
        t = threading.Thread(target=_guided_play_thread, args=(m,), daemon=True)
        t.start()
    elif m["type"] == "combo":
        t = threading.Thread(target=_combo_play_thread, args=(m,), daemon=True)
        t.start()


def macro_play_recorded_thread(m: dict):
    my_idx = state.macro_active_idx
    loop_count = 0

    while True:
        loop_count += 1
        loop_str = f"  (loop {loop_count})" if m.get("loop_enabled") else ""
        tip = (
            f" Playing: {m['name']}{loop_str}\n"
            f"{_macro_speed_hint(m)}\n"
            f" Z = next macro  |  F1 = Stop"
        )
        _tooltip(tip)

        speed = m.get("speed_mult", 1.0)

        for evt in m.get("events", []):
            if not state.macro_playing:
                _tooltip(None)
                return

            scaled_delay = int(evt.get("delay", 0) * speed)
            if scaled_delay > 0:
                time.sleep(scaled_delay / 1000.0)
                _tooltip(tip)

            if not state.macro_playing:
                _tooltip(None)
                return

            _replay_event(evt)

        if not m.get("loop_enabled"):
            break
        if not state.macro_playing:
            break

    if state.macro_active_idx == my_idx:
        state.macro_playing = False
        state.macro_active_idx = 0
        _macro_save_if_dirty()
        _tooltip(
            f" {m['name']} done\n{_macro_speed_hint(m)}\n"
            f" {m.get('hotkey','').upper()} = run again  |  Z = next macro  |  F1 = disarm"
        )


def macro_play_repeat_thread(m: dict, bg_mode: bool = False):
    VK_Q = 0x51

    my_idx = state.macro_active_idx
    state.macro_repeat_key_idx = 0
    keys = m.get("repeat_keys", [])
    if not keys:
        state.macro_playing = False
        state.macro_active_idx = 0
        return

    interval = m.get("repeat_interval", 1000)
    is_spam = m.get("repeat_spam", 0)
    multi = len(keys) > 1

    def _check_q():
        if not multi:
            return
        if _sys.get_async_key_state(VK_Q):
            while _sys.get_async_key_state(VK_Q) and state.macro_playing:
                time.sleep(0.050)
            state.macro_repeat_key_idx = (state.macro_repeat_key_idx + 1) % len(keys)
            cur = keys[state.macro_repeat_key_idx]
            _macro_log(f"RepeatPlay: Q \u2192 key #{state.macro_repeat_key_idx} '{cur}'")
            if is_spam:
                _repeat_build_tooltip(m, keys)

    # ── BG left-click mode ──────────────────────────────────
    if bg_mode:
        _bg_interval = [interval]

        def _bg_slower():
            from core.state import state as _st
            _bg_interval[0] += _st.autoclick_interval_step
            _bg_update_tooltip(m, _bg_interval[0], is_spam)

        def _bg_faster():
            from core.state import state as _st
            _bg_interval[0] = max(_st.autoclick_min_interval,
                                  _bg_interval[0] - _st.autoclick_interval_step)
            _bg_update_tooltip(m, _bg_interval[0], is_spam)

        try:
            hk = state._hotkey_mgr
            hk.register("[", _bg_slower, suppress=True)
            hk.register("]", _bg_faster, suppress=True)
        except Exception:
            pass

        # Resolve the input child hwnd once — matches AHK ControlClick
        # targeting the child render surface, not the top-level window.
        _bg_hwnd = win_exist(state.ark_window)
        if _bg_hwnd:
            _bg_hwnd = find_input_child(_bg_hwnd)

        if is_spam:
            _bg_update_tooltip(m, _bg_interval[0], True)
            while state.macro_playing:
                if not _bg_hwnd:
                    _bg_hwnd = win_exist(state.ark_window)
                    if _bg_hwnd:
                        _bg_hwnd = find_input_child(_bg_hwnd)
                if _bg_hwnd:
                    control_click(_bg_hwnd, 1, 1, activate=False)
                time.sleep(0.016)
        else:
            while state.macro_playing:
                _bg_update_tooltip(m, _bg_interval[0], False)
                remaining = _bg_interval[0]
                while remaining > 0 and state.macro_playing:
                    secs = f"{remaining / 1000:.1f}"
                    _tooltip(
                        f" BG Left Click: {m['name']} in {secs}s\n"
                        f" [ = Slower   ] = Faster\n"
                        f" Z = next macro  |  F1 = Stop"
                    )
                    step = min(remaining, 100)
                    time.sleep(step / 1000.0)
                    remaining -= step

                if not state.macro_playing:
                    break

                if not _bg_hwnd:
                    _bg_hwnd = win_exist(state.ark_window)
                    if _bg_hwnd:
                        _bg_hwnd = find_input_child(_bg_hwnd)
                if _bg_hwnd:
                    control_click(_bg_hwnd, 1, 1, activate=False)

                _tooltip(
                    f" BG Left Click: {m['name']} CLICKED\n"
                    f" [ = Slower   ] = Faster\n"
                    f" Z = next macro  |  F1 = Stop"
                )
                time.sleep(0.050)

        try:
            hk = state._hotkey_mgr
            hk.unregister("[", _bg_slower)
            hk.unregister("]", _bg_faster)
        except Exception:
            pass

        if state.macro_active_idx == my_idx:
            state.macro_playing = False
            state.macro_active_idx = 0
            _macro_save_if_dirty()
            _tooltip(None)
            state.gui_visible = True
            root = getattr(state, "root", None)
            if root:
                root.after(0, root.deiconify)
        return

    # ── Normal (foreground) repeat mode ─────────────────────
    if is_spam:
        _repeat_build_tooltip(m, keys)
        while state.macro_playing:
            _check_q()
            idx = state.macro_repeat_key_idx % len(keys)
            cur_key = keys[idx]
            hwnd = win_exist(state.ark_window)
            if hwnd and get_foreground_window() == hwnd:
                _send_macro_key(cur_key)
            time.sleep(0.016)
    else:
        while state.macro_playing:
            _check_q()
            idx = state.macro_repeat_key_idx % len(keys)
            cur_key = keys[idx]

            remaining = interval
            while remaining > 0 and state.macro_playing:
                _check_q()
                idx = state.macro_repeat_key_idx % len(keys)
                cur_key = keys[idx]
                secs = f"{remaining / 1000:.1f}"
                move_hint = "  (move now)" if m.get("repeat_movement") else ""
                q_hint = "\n Q = next key" if multi else ""
                _tooltip(
                    f" {m['name']}: {cur_key} in {secs}s{move_hint}{q_hint}\n"
                    f" Z = next macro  |  F1 = Stop"
                )
                step = min(remaining, 100)
                time.sleep(step / 1000.0)
                remaining -= step

            if not state.macro_playing:
                break

            idx = state.macro_repeat_key_idx % len(keys)
            cur_key = keys[idx]
            hwnd = win_exist(state.ark_window)
            if hwnd and get_foreground_window() == hwnd:
                _send_macro_key(cur_key)

            _tooltip(
                f" {m['name']}: {cur_key} PRESSED\n"
                f" Z = next macro  |  F1 = Stop"
            )
            time.sleep(0.050)

    if state.macro_active_idx == my_idx:
        state.macro_playing = False
        state.macro_active_idx = 0
        _macro_save_if_dirty()
        _tooltip(None)


def _repeat_build_tooltip(m: dict, keys: list):
    idx = state.macro_repeat_key_idx % len(keys)
    cur_key = keys[idx]
    key_list = ""
    for i, k in enumerate(keys):
        arrow = " > " if i == idx else "   "
        key_list += f"\n{arrow}{k}"
    q_hint = "\n Q = next key" if len(keys) > 1 else ""
    _tooltip(f" Spam: {cur_key}{key_list}{q_hint}\n Z = next macro  |  F1 = Stop")


def _bg_update_tooltip(m: dict, interval_ms: int, is_spam: bool):
    mode = "Spam" if is_spam else f"Interval: {interval_ms}ms"
    _tooltip(
        f" BG Left Click: {m['name']}  ({mode})\n"
        f" [ = Slower   ] = Faster\n"
        f" Z = next macro  |  F1 = Stop"
    )


def _send_macro_key(key: str):
    lower = key.lower()
    if lower == "lbutton":
        click(button="left")
    elif lower == "rbutton":
        click(button="right")
    elif lower == "mbutton":
        click(button="middle")
    else:
        key_press(key)


def _macro_play_pyro_thread(m: dict):
    my_idx = state.macro_active_idx
    sp = m.get("speed_mult", 1.0)

    hwnd = win_exist(state.ark_window)
    if not hwnd or get_foreground_window() != hwnd:
        state.macro_playing = False
        state.macro_active_idx = 0
        return

    try:
        dismount_col = pixel_get_color(state.pyro_dismount_x, state.pyro_dismount_y)
    except Exception:
        dismount_col = 0

    is_dismount = is_color_similar(dismount_col, 0xD45F12, 40)

    if is_dismount:
        _tooltip(" Pyro: Dismounting...\n Spamming Ctrl+C\n F1 = Stop")
        for _ in range(200):
            if not state.macro_playing or state.macro_active_idx != my_idx:
                _tooltip(None)
                return
            if not (win_exist(state.ark_window) and get_foreground_window() == win_exist(state.ark_window)):
                break
            send("^c")
            time.sleep(0.050 * sp)
            try:
                check_col = pixel_get_color(state.pyro_dismount_x, state.pyro_dismount_y)
            except Exception:
                check_col = 0
            if not is_color_similar(check_col, 0xD45F12, 40):
                _tooltip(" Pyro: Back on shoulder!\n R = mount  |  F1 = disarm")
                break
        if state.macro_active_idx == my_idx:
            state.macro_playing = False
            state.macro_active_idx = 0
            _macro_save_if_dirty()
        return

    _tooltip(" Pyro: Mounting...\n Holding R for radial\n F1 = Stop")
    key_down("r")
    time.sleep(0.450 * sp)
    if not state.macro_playing or state.macro_active_idx != my_idx:
        key_up("r")
        _tooltip(None)
        return

    contexts = [
        ("Asteros + Tek", state.pyro_ast_tek_det_x, state.pyro_ast_tek_det_y,
         state.pyro_ast_tek_clk_x, state.pyro_ast_tek_clk_y),
        ("Asteros", state.pyro_ast_no_tek_det_x, state.pyro_ast_no_tek_det_y,
         state.pyro_ast_no_tek_clk_x, state.pyro_ast_no_tek_clk_y),
        ("Tek Helm", state.pyro_non_tek_det_x, state.pyro_non_tek_det_y,
         state.pyro_non_tek_clk_x, state.pyro_non_tek_clk_y),
        ("No Helm", state.pyro_non_no_tek_det_x, state.pyro_non_no_tek_det_y,
         state.pyro_non_no_tek_clk_x, state.pyro_non_no_tek_clk_y),
    ]

    context_name = ""
    first_click_x = first_click_y = 0
    for name, det_x, det_y, clk_x, clk_y in contexts:
        try:
            c = pixel_get_color(det_x, det_y)
            if is_color_similar(c, 0xFFFFFF, 10):
                context_name = name
                first_click_x = clk_x
                first_click_y = clk_y
                break
        except Exception:
            continue

    if not context_name:
        _tooltip(" Pyro: No context detected — aborting\n R = retry  |  F1 = disarm")
        key_up("r")
        if state.macro_active_idx == my_idx:
            state.macro_playing = False
            state.macro_active_idx = 0
            _macro_save_if_dirty()
        return

    _tooltip(f" Pyro: {context_name} detected\n Clicking first option...\n F1 = Stop")
    mouse_move(first_click_x, first_click_y, 0)
    time.sleep(0.050 * sp)
    click()
    time.sleep(0.150 * sp)

    if not state.macro_playing or state.macro_active_idx != my_idx:
        key_up("r")
        _tooltip(None)
        return

    try:
        throw_col = pixel_get_color(state.pyro_throw_check_x, state.pyro_throw_check_y)
    except Exception:
        throw_col = 0
    if is_color_similar(throw_col, 0xFFFFFF, 10):
        _tooltip(" Pyro: THROW detected (enclosed space)\n Aborting — need more room!")
        key_up("r")
        time.sleep(0.5)
        if state.macro_active_idx == my_idx:
            state.macro_playing = False
            state.macro_active_idx = 0
            _macro_save_if_dirty()
        return

    mouse_move(state.pyro_mount_click_x, state.pyro_mount_click_y, 0)
    time.sleep(0.050 * sp)
    click()
    time.sleep(0.100 * sp)
    key_up("r")

    _tooltip(" Pyro: Mounted!\n R = dismount  |  F1 = disarm")
    if state.macro_active_idx == my_idx:
        state.macro_playing = False
        state.macro_active_idx = 0
        _macro_save_if_dirty()


def _guided_clean_recorded_events(events: list[dict]) -> list[dict]:
    """3-phase cleanup:
    1. Strip leading F/mouse/Esc events (junk from opening inventory)
    2. Strip trailing F/Esc events (junk from closing inventory)
    3. Collapse consecutive mouse-move events to the last one
    Also normalizes unpaired click-down to full click (dir=c).
    """
    if not events:
        return events

    cleaned = list(events)

    while cleaned:
        evt = cleaned[0]
        etype = evt.get("type", "")
        key = evt.get("key", "").lower()
        if etype == "M":
            cleaned.pop(0)
        elif etype == "K" and key in ("f", "escape", "esc"):
            cleaned.pop(0)
        else:
            break

    while cleaned:
        evt = cleaned[-1]
        etype = evt.get("type", "")
        key = evt.get("key", "").lower()
        if etype == "K" and key in ("f", "escape", "esc"):
            cleaned.pop()
        elif etype == "M":
            cleaned.pop()
        else:
            break

    collapsed = []
    for i, evt in enumerate(cleaned):
        if evt.get("type") == "M":
            if i + 1 < len(cleaned) and cleaned[i + 1].get("type") == "M":
                continue
        collapsed.append(evt)

    result = []
    for i, evt in enumerate(collapsed):
        if evt.get("type") == "C" and evt.get("dir") == "d":
            has_up = False
            for j in range(i + 1, len(collapsed)):
                if collapsed[j].get("type") == "C" and collapsed[j].get("dir") == "u":
                    has_up = True
                    break
                if collapsed[j].get("type") == "C" and collapsed[j].get("dir") == "d":
                    break
            if not has_up:
                evt = dict(evt)
                evt["dir"] = "c"
        result.append(evt)

    return result


def _guided_play_thread(m: dict):
    VK_F = 0x46
    VK_Q = 0x51

    my_idx = state.macro_active_idx
    is_give = bool(m.get("player_search", 0))
    mouse_spd = m.get("mouse_speed", 0)
    settle = m.get("mouse_settle", 30)
    filters = m.get("search_filters", [])
    state.guided_single_item = False

    _macro_log(f"GuidedPlay: START persistent '{m['name']}' filters={len(filters)} "
               f"events={len(m.get('events', []))} mouseSpd={mouse_spd} settle={settle}ms "
               f"load={m.get('inv_load_delay', 1500)}ms")
    _guided_show_armed_tooltip(m)

    while state.macro_playing and state.macro_active_idx == my_idx:
        if macro_dialog_open():
            time.sleep(0.1)
            continue

        mx, my = get_cursor_pos()
        mouse_on = (0 <= mx < screen_width and 0 <= my < screen_height)

        if _sys.get_async_key_state(VK_Q) and mouse_on:
            while _sys.get_async_key_state(VK_Q) and state.macro_playing:
                time.sleep(0.050)
            state.guided_single_item = not state.guided_single_item
            _macro_log(f"GuidedPlay: Q \u2192 single item mode {'ON' if state.guided_single_item else 'OFF'}")
            _guided_show_armed_tooltip(m)

        ark_hwnd = win_exist(state.ark_window)
        gmk_off = getattr(state, "gmk_mode", "off") == "off"
        if (_sys.get_async_key_state(VK_F) and mouse_on
                and ark_hwnd and get_foreground_window() == ark_hwnd and gmk_off):

            # Inventory already open — wait for F release, don't double-trigger
            inv_already = False
            try:
                c = pixel_get_color(state.pc_inv_detect_x, state.pc_inv_detect_y)
                inv_already = is_color_similar(c, 0xFFFFFF, 10)
            except Exception:
                pass
            if inv_already:
                while _sys.get_async_key_state(VK_F) and state.macro_playing:
                    time.sleep(0.050)
                continue

            while _sys.get_async_key_state(VK_F) and state.macro_playing:
                time.sleep(0.050)

            _macro_log("GuidedPlay: F pressed — waiting for inventory")

            inv_found = False
            deadline = time.perf_counter() + 5.0
            while time.perf_counter() < deadline and state.macro_playing:
                try:
                    c = pixel_get_color(state.pc_inv_detect_x, state.pc_inv_detect_y)
                    if is_color_similar(c, 0xFFFFFF, 10):
                        inv_found = True
                        break
                except Exception:
                    pass
                time.sleep(0.050)

            if not inv_found:
                _macro_log("GuidedPlay: inventory TIMEOUT")
                _tooltip(" Inventory not detected — press F at an inventory\n F1 = Stop")
                time.sleep(2.0)
                _guided_show_armed_tooltip(m)
                continue

            if not state.macro_playing or state.macro_active_idx != my_idx:
                break

            if is_give:
                time.sleep(0.050)
                _macro_log("GuidedPlay: playerSearch — skipping slot-ready wait")
            else:
                load_delay = m.get("inv_load_delay", 1500)
                slots_ready = False
                ready_start = time.perf_counter()
                while (time.perf_counter() - ready_start) < (load_delay / 1000.0):
                    if not state.macro_playing:
                        break
                    try:
                        sc = pixel_get_color(
                            state.guided_inv_ready_x, state.guided_inv_ready_y)
                        if is_color_similar(sc, state.guided_inv_ready_color,
                                            state.guided_inv_ready_tol):
                            slots_ready = True
                            break
                    except Exception:
                        pass
                    time.sleep(0.016)
                ready_ms = int((time.perf_counter() - ready_start) * 1000)
                if slots_ready:
                    _macro_log(f"GuidedPlay: slots READY after {ready_ms}ms — settling 150ms")
                    time.sleep(0.150)
                else:
                    _macro_log(f"GuidedPlay: slots TIMEOUT after {ready_ms}ms — proceeding")

            if not state.macro_playing or state.macro_active_idx != my_idx:
                break

            if filters:
                _guided_apply_search_filter(filters[0], use_player_bar=is_give)

            if not state.macro_playing or state.macro_active_idx != my_idx:
                break

            turbo_on = bool(m.get("turbo", 0))
            mode_label = "SINGLE" if state.guided_single_item else ("FAST" if turbo_on else "FULL")
            _macro_log(f"GuidedPlay: replaying ({mode_label}) {len(m.get('events', []))} events")

            if state.guided_single_item:
                _guided_replay_single(m)
            elif turbo_on:
                _guided_replay_fast_transfer(m)
            else:
                _guided_replay_events(m)

            _macro_log("GuidedPlay: replay done")

            if not state.macro_playing or state.macro_active_idx != my_idx:
                break

            _macro_log("GuidedPlay: closing inventory")
            send("{Escape}")
            close_start = time.perf_counter()
            while (time.perf_counter() - close_start) < 2.0:
                time.sleep(0.050)
                try:
                    c = pixel_get_color(state.pc_inv_detect_x, state.pc_inv_detect_y)
                    if not is_color_similar(c, 0xFFFFFF, 10):
                        break
                except Exception:
                    break
            close_ms = int((time.perf_counter() - close_start) * 1000)
            _macro_log(f"GuidedPlay: inventory closed after {close_ms}ms")

            _guided_show_armed_tooltip(m)

        time.sleep(0.050)

    _macro_log("GuidedPlay: STOPPED")
    state.guided_single_item = False
    if state.macro_active_idx == my_idx:
        state.macro_playing = False
        state.macro_active_idx = 0
        _macro_save_if_dirty()
        _tooltip(None)


def _combo_play_thread(m: dict):
    VK_F, VK_Q, VK_R, VK_Z = 0x46, 0x51, 0x52, 0x5A

    my_idx = state.macro_active_idx
    state.combo_running = True
    state.combo_mode = 1
    state.combo_filter_idx = 0

    pc_filters = m.get("popcorn_filters", [])
    mf_filters = m.get("magic_f_filters", [])
    if not pc_filters:
        pc_filters = [""]
    if not mf_filters:
        mf_filters = [""]

    first_entry = True

    _macro_log(f"ComboPlay: START '{m['name']}' pcFilters={len(pc_filters)} mfFilters={len(mf_filters)}")

    def _wait_release(vk):
        while _sys.get_async_key_state(vk) and state.macro_playing:
            time.sleep(0.050)

    def _inv_is_open() -> bool:
        try:
            c = pixel_get_color(state.pc_inv_detect_x, state.pc_inv_detect_y)
            return is_color_similar(c, 0xFFFFFF, 10)
        except Exception:
            return False

    def _mouse_ok() -> bool:
        mx, my = get_cursor_pos()
        return 0 <= mx < screen_width and 0 <= my < screen_height

    while state.macro_playing and state.combo_running:

        if state.combo_mode == 1:
            if not state.macro_playing or not state.combo_running:
                break
            filt = pc_filters[state.combo_filter_idx % len(pc_filters)]
            _macro_log(f"ComboPlay: POPCORN mode filterIdx={state.combo_filter_idx} filter={filt or '(all)'}")
            _combo_show_tooltip(m)

            if first_entry:
                first_entry = False
                try:
                    ark_hwnd = win_exist(state.ark_window)
                    inv_open = (ark_hwnd and get_foreground_window() == ark_hwnd
                                and _inv_is_open())
                except Exception:
                    inv_open = False
                if inv_open:
                    cur = pc_filters[state.combo_filter_idx % len(pc_filters)]
                    if cur:
                        _combo_apply_their_filter(cur)
                    _combo_popcorn_drop_loop()

            while state.macro_playing and state.combo_running and state.combo_mode == 1:
                if macro_dialog_open():
                    time.sleep(0.1)
                    continue

                if _sys.get_async_key_state(VK_Q):
                    _wait_release(VK_Q)
                    if _inv_is_open():
                        send("{Escape}")
                        time.sleep(0.3)
                    if state.combo_filter_idx < len(pc_filters) - 1:
                        state.combo_filter_idx += 1
                        _macro_log(f"ComboPlay: Q \u2192 next popcorn filter #{state.combo_filter_idx}")
                        _combo_show_tooltip(m)
                    else:
                        state.combo_mode = 2
                        state.combo_filter_idx = 0
                        _macro_log("ComboPlay: Q \u2192 swapped to MAGIC F (armed)")
                        _combo_show_tooltip(m)
                        break
                    continue

                if _sys.get_async_key_state(VK_R):
                    _wait_release(VK_R)
                    if _inv_is_open():
                        _macro_log("ComboPlay: R \u2192 closing inventory, staying popcorn")
                        send("{Escape}")
                        time.sleep(0.3)
                    _combo_show_tooltip(m)
                    continue

                if _sys.get_async_key_state(VK_Z):
                    _wait_release(VK_Z)
                    _macro_log("ComboPlay: Z \u2192 exiting combo")
                    state.combo_running = False
                    break

                ark_hwnd = win_exist(state.ark_window)
                gmk_off = getattr(state, "gmk_mode", "off") == "off"
                if ((_sys.get_async_key_state(VK_F)) and _mouse_ok()
                        and gmk_off and ark_hwnd and get_foreground_window() == ark_hwnd):
                    if _inv_is_open():
                        _wait_release(VK_F)
                        continue
                    _wait_release(VK_F)
                    _macro_log("ComboPlay: F pressed — waiting for inventory")
                    time.sleep(0.1)
                    if not _combo_wait_for_inv(3000):
                        _macro_log("ComboPlay: inventory TIMEOUT")
                        _tooltip(f" Inventory not detected — try again\n"
                                 f" Q = cycle  |  Z = exit")
                    else:
                        cur = pc_filters[state.combo_filter_idx % len(pc_filters)]
                        if cur:
                            _macro_log(f"ComboPlay: applying filter [{cur}]")
                            _combo_apply_their_filter(cur)
                        else:
                            _macro_log("ComboPlay: no filter — dropping all")
                        _combo_popcorn_drop_loop()
                    _combo_show_tooltip(m)

                time.sleep(0.050)

        elif state.combo_mode == 2:
            if not state.macro_playing or not state.combo_running:
                break
            filt = mf_filters[state.combo_filter_idx % len(mf_filters)]
            _macro_log(f"ComboPlay: MAGIC F mode filterIdx={state.combo_filter_idx} filter={filt or '(all)'}")
            _combo_show_tooltip(m)

            while state.macro_playing and state.combo_running and state.combo_mode == 2:
                if macro_dialog_open():
                    time.sleep(0.1)
                    continue

                if _sys.get_async_key_state(VK_Q):
                    _wait_release(VK_Q)
                    if state.combo_filter_idx < len(mf_filters) - 1:
                        state.combo_filter_idx += 1
                        _macro_log(f"ComboPlay: Q \u2192 next MF filter #{state.combo_filter_idx}")
                        _combo_show_tooltip(m)
                    else:
                        state.combo_mode = 1
                        state.combo_filter_idx = 0
                        _macro_log("ComboPlay: Q \u2192 swapped to POPCORN (armed)")
                        _combo_show_tooltip(m)
                        break
                    continue

                if _sys.get_async_key_state(VK_Z):
                    _wait_release(VK_Z)
                    _macro_log("ComboPlay: Z \u2192 exiting combo")
                    state.combo_running = False
                    break

                ark_hwnd = win_exist(state.ark_window)
                gmk_off = getattr(state, "gmk_mode", "off") == "off"
                if ((_sys.get_async_key_state(VK_F)) and _mouse_ok()
                        and gmk_off and ark_hwnd and get_foreground_window() == ark_hwnd):
                    if _inv_is_open():
                        _wait_release(VK_F)
                        continue
                    _wait_release(VK_F)
                    _macro_log("ComboPlay: F pressed — waiting for inventory (MF give)")
                    time.sleep(0.1)
                    if not _combo_wait_for_inv(3000):
                        _macro_log("ComboPlay: MF inventory TIMEOUT")
                        _tooltip(f" Inventory not detected — try again\n"
                                 f" Q = cycle  |  Z = exit")
                    else:
                        cur = mf_filters[state.combo_filter_idx % len(mf_filters)]
                        _macro_log(f"ComboPlay: MF inv found — filter [{cur or '(all)'}] \u2192 Transfer All")
                        if cur:
                            _combo_apply_my_filter(cur)
                        _combo_magic_f_give()
                        _macro_log("ComboPlay: MF give done — closing inv")
                        send("{Escape}")
                        time.sleep(0.3)
                    _combo_show_tooltip(m)

                time.sleep(0.050)

    _macro_log("ComboPlay: STOPPED")
    state.combo_running = False
    state.combo_mode = 0
    state.combo_filter_idx = 0
    if state.macro_active_idx == my_idx:
        state.macro_playing = False
        state.macro_active_idx = 0
        _macro_save_if_dirty()
        _tooltip(None)


def _guided_show_armed_tooltip(m: dict):
    is_give = bool(m.get("player_search", 0))
    events = m.get("events", [])
    has_clicks = any(e.get("type") == "C" for e in events)

    if is_give:
        action = "Give"
    elif has_clicks:
        action = "Take"
    else:
        action = "Drop"

    single = getattr(state, "guided_single_item", False)
    mode_str = "SINGLE (1 item)" if single else f"{action} ({len(events)} events)"

    filters = m.get("search_filters", [])
    filter_str = ""
    if filters:
        filter_str = "\n Filters: " + ", ".join(f for f in filters if f)

    _tooltip(
        f" > {m['name']}  [{mode_str}]{filter_str}\n"
        f"{_macro_speed_hint(m)}\n"
        f" F = run  |  Q = toggle single  |  Z = next  |  F1 = Stop"
    )


def _guided_apply_search_filter(text: str, use_player_bar: bool = False):
    if not text:
        return
    from input.window import control_click
    from util.clipboard import set_clipboard_text, get_clipboard_text

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        _macro_log("GuidedApplyFilter: ARK not found")
        return

    if use_player_bar:
        sb_x, sb_y = int(state.my_search_bar_x), int(state.my_search_bar_y)
        sl_x, sl_y = int(state.pl_start_slot_x), int(state.pl_start_slot_y)
        t1, t2, t3, t4, t5 = 0.030, 0.050, 0.020, 0.120, 0.050
    else:
        sb_x, sb_y = int(state.pc_search_bar_x), int(state.pc_search_bar_y)
        sl_x, sl_y = int(state.pc_start_slot_x), int(state.pc_start_slot_y)
        t1, t2, t3, t4, t5 = 0.080, 0.120, 0.030, 0.250, 0.120

    _macro_log(f"GuidedApplyFilter: applying [{text}] searchBar=({sb_x},{sb_y}) playerBar={use_player_bar}")

    if get_foreground_window() != hwnd:
        win_activate(hwnd)
    time.sleep(t1)

    control_click(hwnd, sb_x, sb_y)
    time.sleep(t2)

    saved_clip = get_clipboard_text()
    try:
        set_clipboard_text(text)
        send("^a")
        time.sleep(t3)
        send("^v")
        time.sleep(t4)
    finally:
        try:
            set_clipboard_text(saved_clip or "")
        except Exception:
            pass

    control_click(hwnd, sl_x, sl_y)
    time.sleep(t5)
    _macro_log(f"GuidedApplyFilter: [{text}] applied")


def _guided_replay_single(m: dict):
    events = m.get("events", [])
    mouse_speed = m.get("mouse_speed", 0)
    settle = m.get("mouse_settle", 1)

    for i, evt in enumerate(events):
        if not state.macro_playing:
            return
        etype = evt.get("type", "")

        if etype == "M":
            mouse_move(evt["x"], evt["y"], mouse_speed)
            if settle > 0:
                time.sleep(settle / 1000.0)
            if i + 1 < len(events) and events[i + 1].get("type") == "K":
                key_press(events[i + 1]["key"])
                return

        elif etype == "C" and evt.get("dir") in ("c", "d"):
            btn_map = {"l": "left", "r": "right", "m": "middle"}
            button = btn_map.get(evt.get("btn", "L").lower(), "left")
            mouse_move(evt["x"], evt["y"], mouse_speed)
            if settle > 0:
                time.sleep(settle / 1000.0)
            click(button=button)
            if i + 1 < len(events) and events[i + 1].get("type") == "K":
                time.sleep(0.020)
                key_press(events[i + 1]["key"])
            return


def _guided_replay_fast_transfer(m: dict):
    events = m.get("events", [])
    mouse_spd = m.get("mouse_speed", 0)
    is_give = bool(m.get("player_search", 0))

    transfer_key = None
    for evt in events:
        if evt.get("type") == "K" and evt.get("dir") == "p":
            transfer_key = evt["key"]
            break
    if transfer_key is None:
        transfer_key = "t"

    slots = []
    for evt in events:
        if evt.get("type") == "C" and evt.get("dir") in ("c", "d"):
            slots.append((evt["x"], evt["y"]))

    if slots:
        give_multi = is_give and len(slots) > 1
        label = "GIVE" if is_give else "TAKE"
        _macro_log(f"GuidedFastXfer: {label} mode — {len(slots)} slots, key={transfer_key}")
        for i, (sx, sy) in enumerate(slots):
            if not state.macro_playing:
                return
            mouse_move(sx, sy, mouse_spd)
            time.sleep(0.080 if give_multi else 0.050)
            click()
            time.sleep(0.050 if give_multi else 0.030)
            if not state.macro_playing:
                return
            send("{" + transfer_key + "}" if len(transfer_key) > 1 else transfer_key)
            if i < len(slots) - 1:
                time.sleep(0.130 if give_multi else 0.100)
        _macro_log(f"GuidedFastXfer: DONE {len(slots)} items")
        return

    drop_slots = []
    for evt in events:
        if evt.get("type") == "M":
            drop_slots.append((evt["x"], evt["y"]))

    if drop_slots:
        _macro_log(f"GuidedFastXfer: POPCORN mode — {len(drop_slots)} slots, key={transfer_key}")
        for i, (sx, sy) in enumerate(drop_slots):
            if not state.macro_playing:
                return
            mouse_move(sx, sy, mouse_spd)
            time.sleep(0.050)
            click()
            time.sleep(0.030)
            if not state.macro_playing:
                return
            send("{" + transfer_key + "}" if len(transfer_key) > 1 else transfer_key)
            if i < len(drop_slots) - 1:
                time.sleep(0.050)
        _macro_log(f"GuidedFastXfer: DONE {len(drop_slots)} drops")
        return

    _macro_log("GuidedFastXfer: no slots found — falling back to generic replay")
    _guided_replay_events(m)


def _guided_replay_events(m: dict):
    # Turbo mode: C->K = 100ms, K->C = 200ms, K->M = 0ms, else min(raw, turboDelay).
    # Non-turbo: uses recorded delays scaled by speed_mult.
    events = m.get("events", [])
    speed = m.get("speed_mult", 1.0)
    mouse_spd = m.get("mouse_speed", 0)
    settle = m.get("mouse_settle", 30)
    turbo = m.get("turbo", 0)
    turbo_delay = m.get("turbo_delay", 30)
    hotkey = m.get("hotkey", "")

    click_to_key_gap = 100
    key_to_click_gap = 200

    # Strip leading hotkey presses (F key that opened inventory)
    # Collapse consecutive mouse moves (keep only last)
    cleaned = []
    i = 0
    while i < len(events):
        evt = events[i]
        etype = evt.get("type", "")
        if (not cleaned and etype == "K" and evt.get("dir") == "p"
                and hotkey and evt.get("key", "").lower() == hotkey.lower()):
            i += 1
            continue
        if etype == "M":
            last_m = evt
            while i + 1 < len(events) and events[i + 1].get("type") == "M":
                i += 1
                last_m = events[i]
            cleaned.append(last_m)
        else:
            cleaned.append(evt)
        i += 1

    prev_type = "K"
    for evt in cleaned:
        if not state.macro_playing:
            return
        etype = evt.get("type", "")
        raw_delay = int(evt.get("delay", 0) * speed)

        if turbo:
            if prev_type == "C" and etype == "K":
                use_delay = click_to_key_gap
            elif prev_type == "K" and etype == "C":
                use_delay = key_to_click_gap
            elif prev_type == "K" and etype == "M":
                use_delay = 0
            else:
                use_delay = min(raw_delay, turbo_delay)
        else:
            use_delay = raw_delay

        if etype == "C":
            prev_type = "C"
        elif etype == "K":
            prev_type = "K"

        if etype == "M":
            mouse_move(evt["x"], evt["y"], mouse_spd)
            if settle > 0:
                time.sleep(settle / 1000.0)
        elif etype == "K":
            if use_delay > 0:
                time.sleep(use_delay / 1000.0)
            if not state.macro_playing:
                return
            d = evt.get("dir", "p")
            k = evt["key"]
            if d == "p":
                key_press(k)
            elif d == "d":
                key_down(k)
            elif d == "u":
                key_up(k)
        elif etype == "C":
            if not state.macro_playing:
                return
            mouse_move(evt["x"], evt["y"], mouse_spd)
            hover_wait = max(use_delay, settle)
            if hover_wait > 0:
                time.sleep(hover_wait / 1000.0)
            d = evt.get("dir", "c")
            btn = evt.get("btn", "L").lower()
            button = {"l": "left", "r": "right", "m": "middle"}.get(btn, "left")
            if d == "c":
                click(button=button)
            elif d == "d":
                mouse_down(button)
            elif d == "u":
                mouse_up(button)


def _combo_cycle_filter(m: dict):
    pc_filters = m.get("popcorn_filters", [])
    mf_filters = m.get("magic_f_filters", [])

    state.combo_filter_idx += 1

    if state.combo_mode == 1:
        if state.combo_filter_idx >= len(pc_filters):
            if mf_filters:
                state.combo_mode = 2
                state.combo_filter_idx = 0
            else:
                state.combo_filter_idx = 0
    elif state.combo_mode == 2:
        if state.combo_filter_idx >= len(mf_filters):
            if pc_filters:
                state.combo_mode = 1
                state.combo_filter_idx = 0
            else:
                state.combo_filter_idx = 0

    _macro_log(f"ComboCycle: mode={state.combo_mode} idx={state.combo_filter_idx}")


def _combo_wait_for_inv(max_ms: int = 5000) -> bool:
    deadline = time.perf_counter() + max_ms / 1000.0
    while time.perf_counter() < deadline and state.macro_playing and state.combo_running:
        try:
            c = pixel_get_color(state.pc_inv_detect_x, state.pc_inv_detect_y)
            if is_color_similar(c, 0xFFFFFF, 10):
                return True
        except Exception:
            pass
        time.sleep(0.050)
    return False


def _combo_apply_their_filter(text: str):
    if not text:
        return
    from input.window import control_click
    from util.clipboard import set_clipboard_text, get_clipboard_text

    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    if get_foreground_window() != hwnd:
        win_activate(hwnd)
    time.sleep(0.080)
    control_click(hwnd, int(state.their_inv_search_bar_x),
                  int(state.their_inv_search_bar_y))
    time.sleep(0.120)
    saved_clip = get_clipboard_text()
    try:
        set_clipboard_text(text)
        send("^a")
        time.sleep(0.030)
        send("^v")
        time.sleep(0.250)
    finally:
        try:
            set_clipboard_text(saved_clip or "")
        except Exception:
            pass


def _combo_apply_my_filter(text: str):
    from input.window import control_click
    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    control_click(hwnd, int(state.my_search_bar_x), int(state.my_search_bar_y))
    time.sleep(0.030)
    send_text(text)
    time.sleep(0.100)


def _combo_popcorn_drop_loop():
    from modules.popcorn import pc_check_storage_empty
    VK_R = 0x52

    ark_hwnd = win_exist(state.ark_window)
    pass_num = 0
    ocr_fails = 0

    while state.macro_playing and state.combo_running:
        pass_num += 1
        for row in range(int(state.pc_rows)):
            for col in range(int(state.pc_columns)):
                if not state.macro_playing or not state.combo_running:
                    return
                if _sys.get_async_key_state(VK_R):
                    while (_sys.get_async_key_state(VK_R)
                           and state.macro_playing):
                        time.sleep(0.050)
                    send("{Escape}")
                    time.sleep(0.3)
                    return
                if ark_hwnd and get_foreground_window() != ark_hwnd:
                    continue

                x = int(state.pc_start_slot_x + col * state.pc_slot_w)
                y = int(state.pc_start_slot_y + row * state.pc_slot_h)
                set_cursor_pos(x, y)
                if row == 0:
                    time.sleep(state.pc_hover_delay / 1000.0)
                key_press(state.pc_drop_key)
                if state.pc_drop_sleep > 0:
                    time.sleep(state.pc_drop_sleep / 1000.0)

        # Skip first pass to let items start dropping before reading the count
        if pass_num >= 2:
            chk = pc_check_storage_empty()
            _macro_log(f"ComboPlay: drop pass {pass_num} OCR={chk}")
            if chk == 0:
                _macro_log(f"ComboPlay: storage empty after pass {pass_num} — done")
                send("{Escape}")
                time.sleep(0.3)
                return
            if chk == -1:
                ocr_fails += 1
                if ocr_fails >= 6:
                    _macro_log(f"ComboPlay: 6 OCR fails — assuming empty")
                    send("{Escape}")
                    time.sleep(0.3)
                    return
            else:
                ocr_fails = 0

        time.sleep(0.005)


def _combo_magic_f_give():
    from input.window import control_click
    hwnd = win_exist(state.ark_window)
    if not hwnd:
        return
    control_click(hwnd, int(state.transfer_to_other_btn_x),
                  int(state.transfer_to_other_btn_y))
    time.sleep(0.100)


def _combo_show_tooltip(m: dict, phase: str | None = None):
    pc_filters = m.get("popcorn_filters", []) or [""]
    mf_filters = m.get("magic_f_filters", []) or [""]

    if phase is None:
        phase = "popcorn" if state.combo_mode == 1 else "magicf"

    idx = state.combo_filter_idx
    lines = [f" === {m['name']} ==="]

    if phase == "popcorn":
        cur = pc_filters[idx % len(pc_filters)] if pc_filters else "?"
        lines.append(f" MODE: POPCORN  [{cur or '(all)'}]")
        if len(pc_filters) > 1:
            parts = []
            for i, f in enumerate(pc_filters):
                label = f or "(all)"
                parts.append(f">{label}<" if i == idx else label)
            lines.append(" Filters: " + " -> ".join(parts))
        q_hint = "Q = -> Magic F" if idx >= len(pc_filters) - 1 else "Q = next filter"
        lines.append(f"\n F = open inv & drop  |  {q_hint}")
        lines.append(f" R = close inv  |  Z = exit combo  |  F1 = Stop")

    elif phase == "dropping":
        cur = pc_filters[idx % len(pc_filters)] if pc_filters else "?"
        lines.append(f" DROPPING  [{cur or '(all)'}]")
        lines.append(f"\n R = close inv & stop  |  F1 = Stop")

    elif phase == "magicf":
        cur = mf_filters[idx % len(mf_filters)] if mf_filters else "?"
        lines.append(f" MODE: MAGIC F GIVE  [{cur or '(all)'}]")
        if len(mf_filters) > 1:
            parts = []
            for i, f in enumerate(mf_filters):
                label = f or "(all)"
                parts.append(f">{label}<" if i == idx else label)
            lines.append(" Filters: " + " -> ".join(parts))
        q_hint = "Q = -> Popcorn" if idx >= len(mf_filters) - 1 else "Q = next filter"
        lines.append(f"\n F = open inv & give (auto-close)")
        lines.append(f" {q_hint}  |  Z = exit combo  |  F1 = Stop")

    _tooltip("\n".join(lines))


def macro_dialog_open() -> bool:
    for gui_attr in ("guided_wiz_gui", "combo_wiz_gui", "macro_save_gui",
                     "macro_edit_gui", "macro_repeat_gui", "macro_help_gui"):
        gui = getattr(state, gui_attr, None)
        if gui is not None:
            try:
                if gui.winfo_exists():
                    return True
            except Exception:
                pass
    return False


def _replay_event(evt: dict, mouse_speed: int = 0, settle: int = 0):
    etype = evt["type"]
    if etype == "K":
        d = evt.get("dir", "p")
        k = evt["key"]
        if d == "p":
            key_press(k)
        elif d == "d":
            key_down(k)
        elif d == "u":
            key_up(k)

    elif etype == "M":
        mouse_move(evt["x"], evt["y"], mouse_speed)
        if settle > 0:
            time.sleep(settle / 1000.0)

    elif etype == "C":
        d = evt.get("dir", "c")
        btn = evt.get("btn", "L").lower()
        button = {"l": "left", "r": "right", "m": "middle"}.get(btn, "left")
        mouse_move(evt["x"], evt["y"], mouse_speed)
        if settle > 0:
            time.sleep(settle / 1000.0)
        else:
            time.sleep(0.005)
        if d == "c":
            click(button=button)
        elif d == "d":
            mouse_down(button)
        elif d == "u":
            mouse_up(button)


def macro_stop_play():
    was_idx = state.macro_active_idx
    was_name = ""
    if 0 < was_idx <= len(state.macro_list):
        m = state.macro_list[was_idx - 1]
        was_name = m["name"]
        if m["type"] == "pyro":
            key_up("r")

    _macro_log(f"StopPlay: stopping '{was_name}' idx={was_idx}")
    state.macro_playing = False
    state.macro_active_idx = 0
    state.macro_armed = False
    state.combo_running = False
    _macro_save_if_dirty()


def _macro_save_if_dirty():
    if state.macro_speed_dirty:
        macro_save_all()
        state.macro_speed_dirty = False


def macro_register_hotkeys(enable: bool):
    state.macro_hotkeys_live = enable

    try:
        hk = state._hotkey_mgr
    except AttributeError:
        return

    if enable:
        if state.pc_mode == 0 and state.pc_f10_step == 0:
            hk.register("z", macro_z_cycle, suppress=True)
        if state.macro_tab_active:
            hk.register("up", _macro_speed_up, suppress=True)
            hk.register("down", _macro_speed_down, suppress=True)
    else:
        hk.unregister("z", macro_z_cycle)
        hk.unregister("up", _macro_speed_up)
        hk.unregister("down", _macro_speed_down)

    for m in state.macro_list:
        hk_key = m.get("hotkey", "")
        if hk_key and hk_key not in ("...", "q", "f"):
            if hk_key == "r" and state.imprint_scanning:
                continue
            hk.unregister(hk_key)

    if enable and state.macro_list:
        idx = state.macro_selected_idx
        if idx < 1 or idx > len(state.macro_list):
            state.macro_selected_idx = 1
            idx = 1
        sel = state.macro_list[idx - 1]
        hk_key = sel.get("hotkey", "")
        if hk_key and hk_key not in ("...", "q", "f"):
            if not (hk_key == "r" and state.imprint_scanning):
                suppress = state.macro_armed and sel["type"] == "pyro"
                hk.register(hk_key, lambda: _macro_hotkey_handler(idx), suppress=suppress)


def macro_block_all_hotkeys():
    state.macro_hotkeys_live = False
    try:
        hk = state._hotkey_mgr
    except AttributeError:
        return

    hk.unregister("z", macro_z_cycle)
    hk.unregister("up", _macro_speed_up)
    hk.unregister("down", _macro_speed_down)

    for m in state.macro_list:
        hk_key = m.get("hotkey", "")
        if hk_key and hk_key not in ("...", "q", "f"):
            if hk_key == "r" and state.imprint_scanning:
                continue
            hk.unregister(hk_key)


def _macro_hotkey_handler(idx: int):
    if not state.macro_hotkeys_live or macro_dialog_open():
        return

    sel = state.macro_list[idx - 1] if 0 < idx <= len(state.macro_list) else None
    if not sel:
        return

    hk = sel.get("hotkey", "")
    ark_hwnd = win_exist(state.ark_window)
    is_ark = ark_hwnd and get_foreground_window() == ark_hwnd
    mx, my = get_cursor_pos()
    mouse_on = (0 <= mx < screen_width and 0 <= my < screen_height)

    if not is_ark and not state.gui_visible and not mouse_on:
        if state.macro_armed and sel["type"] == "pyro" and hk:
            send("{" + hk + "}")
        return

    if idx != state.macro_selected_idx:
        return

    if state.macro_playing:
        if sel["type"] in ("repeat", "recorded"):
            state.macro_playing = False
            state.macro_active_idx = 0
            state.macro_armed = True
            _macro_save_if_dirty()
            key_str = f" [{hk.upper()}]" if hk else ""
            _tooltip(
                f" > {sel['name']} armed{key_str}\n"
                f"{_macro_speed_hint(sel)}\n"
                f" Tap to run  |  Z = next  |  F1 = disarm"
            )
        return

    if _macro_is_busy():
        _tooltip(" Macro paused — another function is running\n Will resume when done")
        from core.timers import timers
        timers.set_timer("busy_tip", lambda: _tooltip(None), -2000)
        return

    if state.gui_visible:
        if sel["type"] in ("guided", "combo", "pyro"):
            return
        if state.main_gui:
            state.main_gui.hide()
        state.gui_visible = False
        state.macro_armed = True
        macro_register_hotkeys(True)
        if ark_hwnd and get_foreground_window() != ark_hwnd:
            win_activate(ark_hwnd)
        key_str = f" [{hk.upper()}]" if hk else ""
        _macro_log(f"HotkeyHandler: armed from GUI — '{sel['name']}' type={sel['type']}")
        _tooltip(
            f" > {sel['name']} armed{key_str}\n"
            f"{_macro_speed_hint(sel)}\n"
            f" Tap to run  |  Z = next  |  F1 = disarm"
        )
        return

    if not state.macro_armed:
        return

    # Pyro: tap vs hold detection (250ms threshold)
    if sel["type"] == "pyro" and hk:
        vk = _key_to_vk(hk)
        if vk:
            deadline = time.perf_counter() + 0.250
            while time.perf_counter() < deadline:
                if not _sys.get_async_key_state(vk):
                    macro_play_by_index(idx)
                    return
                time.sleep(0.010)
            # Held > 250ms = pass through to game
            key_down(hk)
            while _sys.get_async_key_state(vk):
                time.sleep(0.010)
            key_up(hk)
            return

    if sel["type"] in ("guided", "combo"):
        _macro_log(f"HotkeyHandler: {sel['type']} '{sel['name']}' triggered — launching play")
        macro_play_by_index(idx)
        return

    state.macro_armed = False
    macro_register_hotkeys(True)
    macro_play_by_index(idx)


def _key_to_vk(key: str) -> int | None:
    vk_map = {
        "r": 0x52, "q": 0x51, "z": 0x5A, "x": 0x58, "c": 0x43,
        "f": 0x46, "e": 0x45, "g": 0x47, "t": 0x54, "v": 0x56,
        "rbutton": 0x02, "lbutton": 0x01, "mbutton": 0x04,
    }
    return vk_map.get(key.lower())


def macro_z_cycle():
    hwnd = win_exist(state.ark_window)
    if not hwnd or get_foreground_window() != hwnd:
        return
    if not state.macro_list:
        return
    if not state.macro_armed and not state.macro_playing:
        return
    if _macro_is_busy():
        return

    if state.macro_playing:
        macro_stop_play()

    state.macro_selected_idx += 1
    if state.macro_selected_idx > len(state.macro_list):
        state.macro_selected_idx = 1

    state.macro_armed = True
    macro_register_hotkeys(True)

    sel = state.macro_list[state.macro_selected_idx - 1]
    key_str = f" [{sel.get('hotkey','').upper()}]" if sel.get("hotkey") else ""
    _macro_log(f"ZCycle: -> #{state.macro_selected_idx} '{sel['name']}' type={sel['type']}")

    if sel["type"] in ("guided", "combo"):
        macro_play_by_index(state.macro_selected_idx)
    else:
        _tooltip(f" > {sel['name']}{key_str}\n Press hotkey to run  |  Z = next  |  F1 = Stop")


def _macro_speed_down():
    if not state.macro_tab_active or not state.macro_list:
        return
    idx = state.macro_selected_idx
    if idx < 1 or idx > len(state.macro_list):
        return
    m = state.macro_list[idx - 1]
    if "speed_mult" not in m:
        return
    new_speed = min(2.00, m["speed_mult"] + 0.05)
    m["speed_mult"] = round(new_speed, 3)
    state.macro_speed_dirty = True
    bar = _macro_speed_bar(m["speed_mult"])
    _tooltip(
        f" > {m['name']}  {m['speed_mult']:.2f}x  SLOWER\n"
        f" {bar}\n Down = slower  Up = faster  |  0.10x=fast  2.00x=slow"
    )
    timers.set_timer("speed_tip", lambda: _tooltip(None), -3000)


def _macro_speed_up():
    if not state.macro_tab_active or not state.macro_list:
        return
    idx = state.macro_selected_idx
    if idx < 1 or idx > len(state.macro_list):
        return
    m = state.macro_list[idx - 1]
    if "speed_mult" not in m:
        return
    new_speed = max(0.10, m["speed_mult"] - 0.05)
    m["speed_mult"] = round(new_speed, 3)
    state.macro_speed_dirty = True
    bar = _macro_speed_bar(m["speed_mult"])
    _tooltip(
        f" > {m['name']}  {m['speed_mult']:.2f}x  FASTER\n"
        f" {bar}\n Down = slower  Up = faster  |  0.10x=fast  2.00x=slow"
    )
    timers.set_timer("speed_tip", lambda: _tooltip(None), -3000)
