
import sys
import os
import time
import threading
import tkinter as tk

from pal import system as _sys

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core.state import state
from core.scaling import screen_width, screen_height, check_resolution
from core.config import read_ini, write_ini, ensure_defaults, read_ini_int, read_ini_bool
from core.hotkeys import HotkeyManager
from core.timers import timers
from gui.main_window import MainWindow
from gui.tooltip import TooltipManager
from gui.tray import TrayManager
from input.window import win_exist, win_move, win_get_pos

# Module imports
from modules import (
    magic_f, popcorn, sheep, auto_level, ob_upload, ob_download,
    quick_hatch, name_spay, auto_craft, overcap, autoclicker,
    auto_pin, mammoth_drums, grab_my_kit, quick_feed,
    join_sim, auto_imprint, macro_system, nvidia_filter, debug_panel,
)


class AIOApp:
    """Main application class."""

    def __init__(self):
        self.root: tk.Tk | None = None
        self.main_window: MainWindow | None = None
        self.hotkeys: HotkeyManager | None = None
        self.tooltips: TooltipManager | None = None
        self.tray: TrayManager | None = None
        self._mutex = None

    def run(self):
        """Start the application."""
        # Single instance check
        if not self._acquire_mutex():
            _sys.message_box("AIO is already running!")
            sys.exit(1)

        # Check resolution warnings
        for warning in check_resolution():
            print(f"Warning: {warning}")

        # Ensure INI defaults exist
        ensure_defaults()

        # Load config values
        self._load_config()

        # Detect ARK
        ark_hwnd = win_exist("ArkAscended")
        if ark_hwnd:
            state.ark_running = True
            state.ark_window = "ArkAscended"
            win_move(ark_hwnd, 0, 0)
            _, _, gw, gh = win_get_pos(ark_hwnd)
            state.game_width = gw
            state.game_height = gh
            self._init_joinsim_offsets()
        else:
            # Show warning but don't exit — allow UI to open
            _sys.message_box("Ark Not Detected.\nStart ARK then restart AIO.")

        # Validate resolution / aspect ratio
        for warn in check_resolution():
            _sys.message_box(warn, "GG AIO — Resolution")

        # Build GUI
        self.root = tk.Tk()
        state.root = self.root

        # High-precision timer for popcorn
        _sys.begin_timer_period(1)

        self.main_window = MainWindow(self.root)
        state.main_gui = self.main_window

        self.tooltips = TooltipManager(self.root)
        state._tooltip_mgr = self.tooltips
        self.tray = TrayManager(
            on_quit=self._on_quit,
            on_show=lambda: self.main_window.show(),
        )
        self.tray.start()
        self.tray.notify("GG AIO", "AIO is running")

        # Build tab contents
        self._build_tabs()

        # Set up hotkey manager
        self.hotkeys = HotkeyManager(self.root)
        state._hotkey_mgr = self.hotkeys
        self._register_hotkeys()
        self.hotkeys.start()

        # Tab change handler
        self.main_window.set_tab_change_callback(self._on_tab_change)

        # Load lists
        self._load_lists()

        # Load auto-pin settings
        auto_pin.pin_load_settings()

        # Start main loop
        self.root.mainloop()

        # Cleanup
        self._cleanup()

    def _acquire_mutex(self) -> bool:
        """Acquire a named mutex for single-instance enforcement."""
        self._mutex, ok = _sys.acquire_mutex()
        return ok

    def _init_joinsim_offsets(self):
        """Compute JoinSim fractional offsets from game window dimensions."""
        gw = state.game_width
        gh = state.game_height
        state.back_offset_x = int(0.0859375 * gw)
        state.back_offset_y = int(0.8148148148 * gh)
        state.sp_back_offset_x = int(0.10052083333333334 * gw)
        state.sp_back_offset_y = int(0.88055555555555554 * gh)
        state.main_menu_join_offset_x = int(0.5828125 * gw)
        state.main_menu_join_offset_y = int(0.81111111111111112 * gh)
        state.join_game_offset_x = int(0.2864583333 * gw)
        state.join_game_offset_y = int(0.5092592593 * gh)
        state.server_search_offset_x = int(0.8723958333 * gw)
        state.server_search_offset_y = int(0.1805555556 * gh)
        state.server_join_offset_x = int(0.88020833333333337 * gw)
        state.server_join_offset_y = int(0.875 * gh)
        state.click_session_offset_x = int(0.2052083333 * gw)
        state.click_session_offset_y = int(0.3009259259 * gh)
        state.click_session_b_offset_x = int(0.5052083333 * gw)
        state.click_session_b_offset_y = int(0.3009259259 * gh)
        state.join_last_offset_x = int(0.89270833333333333 * gw)
        state.join_last_offset_y = int(0.82777777777777772 * gh)
        state.refresh_offset_x = int(0.4895833333 * gw)
        state.refresh_offset_y = int(0.8703703704 * gh)
        state.mod_join_offset_x = int(0.28125 * gw)
        state.mod_join_offset_y = int(0.86388888888888893 * gh)

        # --- State detection tables (pixel x/y as fractional × game dims) ---
        def _gx(f):
            return int(f * gw)

        def _gy(f):
            return int(f * gh)

        state.sim_state_table_a = [
            {"name": "ServerFull",
             "x": _gx(0.5666666667), "y": _gy(0.3277777778),
             "c": 0xFFC1F5FF},
            {"name": "ServerFull2",
             "x": _gx(0.46354166666666669), "y": _gy(0.3351851851851852),
             "c": 0xFFC1F5FF},
            {"name": "ServerFull3",
             "x": _gx(0.52708333333333335), "y": _gy(0.37037037037037035),
             "c": 0xFFC1F5FF},
            {"name": "ConnectionTimeout",
             "x": _gx(0.5489583333), "y": _gy(0.3481481481),
             "c": 0xFFFF0000},
            {"name": "WaitingToJoin",
             "x": _gx(0.8640625), "y": _gy(0.875),
             "c": 0xFF556D69},
            {"name": "NoSessions",
             "x": _gx(0.5447916667), "y": _gy(0.4462962963),
             "c": 0xFFC1F5FF,
             "x2": _gx(0.050520833333333334), "y2": _gy(0.09166666666666666),
             "c2": 0xFFC1F5FF},
            {"name": "ServerSelected",
             "x": _gx(0.056250000000000001), "y": _gy(0.3037037037037037),
             "c": 0xFFFFFFBC, "calt": 0xFFFFFFFF,
             "x2": _gx(0.88020833333333337), "y2": _gy(0.875),
             "c2": 0xFFFFFFFF},
            {"name": "ServerBrowser",
             "x": _gx(0.050520833333333334), "y": _gy(0.09166666666666666),
             "c": 0xFFC1F5FF, "calt": 0xFF9CB1B7},
            {"name": "ModMenu",
             "x": _gx(0.14270833333333333), "y": _gy(0.56388888888888888),
             "c": 0xFF85D8ED,
             "x2": _gx(0.28125), "y2": _gy(0.86388888888888893),
             "c2": 0xFFFFFFFF},
            {"name": "ContentFailed",
             "x": _gx(0.53125), "y": _gy(0.5120570370),
             "c": 0xFF88DDF2},
            {"name": "MainMenu",
             "x": _gx(0.5828125), "y": _gy(0.81111111111111112),
             "c": 0xFFFFFFFF},
            {"name": "MiddleMenu",
             "x": _gx(0.49843749999999998), "y": _gy(0.89351851851851849),
             "c": 0xFF86EAFF, "calt": 0xFFA4F0FF},
            {"name": "SinglePlayer",
             "x": _gx(0.76406249999999998), "y": _gy(0.83981481481481479),
             "c": 0xFFFFC000},
        ]

        state.sim_state_table_b = [
            {"name": "ServerFull",
             "x": _gx(0.5666666667), "y": _gy(0.3277777778),
             "c": 0xFFC1F5FF},
            {"name": "ConnectionTimeout",
             "x": _gx(0.5489583333), "y": _gy(0.3481481481),
             "c": 0xFFFF0000},
            {"name": "NoSessions",
             "x": _gx(0.5447916667), "y": _gy(0.4462962963),
             "c": 0xFFC1F5FF},
            {"name": "ServerSelected",
             "x": _gx(0.056250000000000001), "y": _gy(0.3037037037037037),
             "c": 0xFFFFFFBC, "calt": 0xFFFFFFFF,
             "x2": _gx(0.88020833333333337), "y2": _gy(0.875),
             "c2": 0xFFFFFFFF},
            {"name": "ServerBrowser",
             "x": _gx(0.050520833333333334), "y": _gy(0.09166666666666666),
             "c": 0xFFC1F5FF, "calt": 0xFF9CB1B7},
            {"name": "ModMenu",
             "x": _gx(0.14270833333333333), "y": _gy(0.56388888888888888),
             "c": 0xFF85D8ED,
             "x2": _gx(0.28125), "y2": _gy(0.86388888888888893),
             "c2": 0xFFFFFFFF},
            {"name": "MainMenu",
             "x": _gx(0.5828125), "y": _gy(0.81111111111111112),
             "c": 0xFFFFFFFF},
            {"name": "MiddleMenu",
             "x": _gx(0.49843749999999998), "y": _gy(0.89351851851851849),
             "c": 0xFF86EAFF},
        ]

    def _load_config(self):
        """Load configuration from INI file."""
        # Timings
        state.mf_search_bar_click_ms = read_ini_int("Timings", "SearchBarClickMs", 30)
        state.mf_filter_settle_ms = read_ini_int("Timings", "FilterSettleMs", 100)
        state.mf_transfer_settle_ms = read_ini_int("Timings", "TransferSettleMs", 100)

        # NTFY
        ntfy = read_ini("ntfy", "key")
        state.ntfy_key = "" if ntfy == "Default" else ntfy

        # INI command key
        cmd_key = read_ini("ini", "commandkey")
        state.ini_command_key = "{vkC0}" if cmd_key == "Default" else cmd_key

        # Custom command
        custom = read_ini("ini", "customcommand")
        state.ini_custom_command = "" if custom == "Default" else custom

        # Popcorn keys — load from INI (empty until user sets them)
        inv_key = read_ini("Popcorn", "InvKey", "")
        if inv_key:
            state.pc_inv_key = inv_key
        drop_key = read_ini("Popcorn", "DropKey", "")
        if drop_key:
            state.pc_drop_key = drop_key

        # Popcorn speed + timings
        state.pc_speed_mode = read_ini_int("Popcorn", "SpeedMode", 1)
        popcorn.pc_apply_speed()
        ds = read_ini("Popcorn", "DropSleep")
        if ds != "Default":
            state.pc_drop_sleep = int(ds)
        cs = read_ini("Popcorn", "CycleSleep")
        if cs != "Default":
            state.pc_cycle_sleep = int(cs)
        hd = read_ini("Popcorn", "HoverDelay")
        if hd != "Default":
            state.pc_hover_delay = int(hd)
        cf = read_ini("Popcorn", "CustomFilter")
        if cf != "Default":
            state.pc_custom_filter = cf

        # Popcorn scan area
        popcorn.pc_load_scan_area()

        # Sheep keys
        toggle = read_ini("Sheep", "ToggleKey")
        if toggle != "Default":
            state.sheep_toggle_key = toggle
        oc = read_ini("Sheep", "OvercapKey")
        if oc != "Default":
            state.sheep_overcap_key = oc
        inv = read_ini("Sheep", "InventoryKey", "")
        if not inv:
            # Fall back to shared Popcorn InvKey
            inv = read_ini("Popcorn", "InvKey", "")
        if inv:
            state.sheep_inventory_key = inv
        alvl = read_ini("Sheep", "AutoLvlKey")
        if alvl != "Default":
            state.sheep_auto_lvl_key = alvl

        # Imprint — scan area, inventory key, hide overlay
        try:
            from modules.auto_imprint import imprint_load_config
            imprint_load_config()
        except Exception:
            pass

        # NVIDIA Filter
        state.nf_enabled = read_ini_bool("NVIDIAFilter", "Enabled", False)

        # OB Download OCR regions
        try:
            ob_download.ob_ocr_load_config()
        except Exception:
            pass

        # Auto Craft OCR scan area
        try:
            from modules.auto_craft import ac_ocr_load_config
            ac_ocr_load_config()
        except Exception:
            pass

        # Craft settings
        state.ac_extra_clicks = read_ini_int("Craft", "ExtraClicks", 0)

        # Grid settings
        state.ac_grid_cols = read_ini_int("Grid", "Cols", 1)
        state.ac_grid_rows = read_ini_int("Grid", "Rows", 11)
        state.ac_grid_hwalk = read_ini_int("Grid", "HWalk", 0)
        state.ac_grid_vwalk = read_ini_int("Grid", "VWalk", 850)

        # Hatch settings
        state.qh_mode = read_ini_int("Hatch", "HatchMode", 0)
        state.cn_enabled = read_ini_bool("Hatch", "ClaimNameEnabled", False)
        state.ns_enabled = read_ini_bool("Hatch", "NameSpayEnabled", False)
        state.qh_cryo_after = read_ini_bool("Hatch", "CryoEnabled", False)
        dino = read_ini("Hatch", "DinoName")
        if dino != "Default":
            state.dino_name = dino

    def _build_tabs(self):
        """Initialize tab content (import and instantiate tab builders)."""
        from gui.tab_joinsim import TabJoinSim
        from gui.tab_magicf import TabMagicF
        from gui.tab_autolvl import TabAutoLvl
        from gui.tab_popcorn import TabPopcorn
        from gui.tab_sheep import TabSheep
        from gui.tab_craft import TabCraft
        from gui.tab_macro import TabMacro
        from gui.tab_misc import TabMisc

        frames = self.main_window.tab_frames
        self.tab_joinsim = TabJoinSim(frames["JoinSim"], state)
        state._tab_joinsim = self.tab_joinsim
        self.tab_magicf = TabMagicF(frames["Magic F"], state)
        state._tab_magicf = self.tab_magicf
        self.tab_autolvl = TabAutoLvl(frames["AutoLvL"], state)
        self.tab_popcorn = TabPopcorn(frames["Popcorn"], state)
        state._tab_popcorn = self.tab_popcorn
        self.tab_sheep = TabSheep(frames["Sheep"], state)
        self.tab_craft = TabCraft(frames["Craft"], state)
        self.tab_macro = TabMacro(frames["Macro"], state)
        state._tab_macro = self.tab_macro
        self.tab_misc = TabMisc(frames["Misc"], state)
        state._tab_misc = self.tab_misc

    def _register_hotkeys(self):
        """Register all global hotkeys."""
        hk = self.hotkeys

        # F1 — Show/Hide UI + Stop All
        hk.register("f1", self._f1_handler, suppress=True)

        # F2 — Overcap toggle
        hk.register("f2", lambda: overcap.toggle_overcap_script(),
                     suppress=True)

        # F3 — Macro play (if macro tab) or Quick Feed cycle
        hk.register("f3", self._f3_handler, suppress=True)

        # F4 — Exit
        hk.register("f4", lambda: self.root.after(0, self._on_quit), suppress=True)

        # F5 — Apply INI
        hk.register("f5", self._apply_ini, suppress=True)

        # F6 — OB Upload cycle
        hk.register("f6", lambda: ob_upload.ob_upload_cycle(), suppress=True)

        # F7 — OB Download
        hk.register("f7", lambda: ob_download.ob_download_cycle(),
                     suppress=True)

        # F8 — Mammoth Drums (passthrough)
        hk.register("f8", lambda: mammoth_drums.toggle_mammoth_script(),
                     suppress=False, passthrough=True)

        # F9 — Autoclicker
        hk.register("f9", lambda: autoclicker.toggle_autoclicker(),
                     suppress=True)

        # F10 — Quick Popcorn cycle
        hk.register("f10", lambda: popcorn.pc_f10_cycle(), suppress=True)

        # F11 — Debug panel (suppress so ARK doesn't toggle fullscreen)
        hk.register("f11", lambda: debug_panel.show_debug_panel(),
                     suppress=True, passthrough=False)

        # F12 — Grab My Kit
        hk.register("f12", lambda: grab_my_kit.gmk_toggle(), suppress=True)

        # F key — Main action key (routes based on active mode)
        hk.register("f", self._f_handler, suppress=False, passthrough=True)

        # Z key — Context-dependent
        hk.register("z", self._z_handler, suppress=False, passthrough=True)

        # Q key — Context-dependent
        hk.register("q", self._q_handler, suppress=False, passthrough=True)

        # E key — Auto Pin / Name+Spay
        hk.register("e", self._e_handler, suppress=False, passthrough=True)

        # R key — Imprint read & process
        hk.register("r", self._r_handler, suppress=False, passthrough=True)

        # Bracket keys — Speed adjustment
        hk.register("[", self._bracket_left, suppress=False, passthrough=True)
        hk.register("]", self._bracket_right, suppress=False, passthrough=True)

    def _f1_handler(self):
        """F1: If GUI hidden → stop flags + show GUI. If visible → hide GUI."""
        if not self.main_window:
            return
        if not state.gui_visible:
            # Only set stop flags — do NOT call module stop functions
            # that might send input to the game
            self._stop_flags()
            state.gui_visible = True
            self.main_window.show()
            # Reset button text for modules stopped by _stop_flags
            try:
                if hasattr(self, "tab_misc"):
                    self.tab_misc.imprint_start_btn.configure(text="Start")
            except Exception:
                pass
            try:
                tab = getattr(state, "_tab_macro", None)
                if tab and hasattr(tab, "play_btn"):
                    tab.play_btn.configure(text="Start")
            except Exception:
                pass
        else:
            state.gui_visible = False
            self.main_window.hide()

    def _f3_handler(self):
        """F3: If macro tab active → play/disarm selected macro. Else → quick feed."""
        if state.macro_tab_active and state.gui_visible:
            # Sync selected macro from treeview before arming
            tab = getattr(state, "_tab_macro", None)
            if tab:
                idx = tab.get_selected_index()
                if idx is not None:
                    state.macro_selected_idx = idx + 1  # 1-based
            macro_system.macro_play_selected()
        elif state.macro_armed or state.macro_playing:
            # Disarm/stop if macro is active
            macro_system.macro_stop_play()
        else:
            quick_feed.quick_feed_cycle()

    def _stop_flags(self):
        """Set all stop flags WITHOUT calling module functions.

        Safe to call while ARK is focused — no mouse/keyboard input is sent.
        """
        state.run_magic_f_script = False
        state.magic_f_preset_idx = 1
        state.pc_early_exit = True
        state.pc_f1_abort = True
        state.pc_mode = 0
        state.pc_f10_step = 0
        state.pc_running = False
        state.run_overcap_script = False
        state.run_mammoth_script = False
        state.run_auto_lvl_script = False
        state.run_claim_and_name_script = False
        state.run_name_and_spay_script = False
        state.qh_armed = False
        state.qh_running = False
        state.ac_simple_armed = False
        state.ac_timed_armed = False
        state.ac_grid_armed = False
        state.ac_running = False
        if not state.ob_timer_counting:
            state.ob_upload_armed = False
            state.ob_upload_running = False
        state.ob_download_armed = False
        state.ob_download_running = False
        state.macro_armed = False
        state.macro_playing = False
        state.combo_running = False
        state.quick_feed_mode = 0
        state.autoclicking = False
        state.gmk_mode = "off"
        # Additional flags reset by F1
        state.depo_eggs_active = False
        state.depo_embryo_active = False
        state.depo_cycle.clear()
        state.depo_cycle_idx = 0
        state.ac_grid_running = False
        state.ac_timed_multi_active = False
        state.ac_craft_loop_running = False
        state.ac_early_exit = True
        state.imprint_scanning = False
        state.imprint_auto_mode = False
        state.auto_sim_check = False
        state.pc_tooltip_gen += 1      # cancel any queued popcorn tooltips
        if self.tooltips:
            self.tooltips.hide_all()

    def _stop_all(self):
        """Stop all active automation — calls module stop functions.

        Only safe to call when we're ready to send input to the game.
        """
        magic_f.stop_magic_f()
        popcorn.stop_popcorn()
        sheep.sheep_stop_script()
        overcap.stop_overcap_script()
        autoclicker.toggle_autoclicker() if state.autoclicking else None
        mammoth_drums.stop_mammoth_script() if state.run_mammoth_script else None
        ob_upload.ob_stop_all()
        ob_download.ob_down_stop_all()
        state.ac_early_exit = True if state.ac_running else None
        quick_feed.quick_feed_stop()
        grab_my_kit.gmk_toggle() if state.gmk_mode != "off" else None
        macro_system.macro_stop_play()
        self._stop_flags()

    def _f_handler(self):
        """Route F key press to the active module."""
        if state.run_magic_f_script:
            magic_f.magic_f_pressed_async()
        elif (state.pc_mode > 0
              and not state.pc_running
              and (state.pc_tab_active or state.pc_f10_step > 0)
              and not state.sheep_running
              and not state.sheep_auto_lvl_active):
            popcorn.pc_f_pressed_async()
        elif state.ac_count_only_active:
            auto_craft.ac_count_only_f_pressed()
        elif state.ac_simple_armed:
            auto_craft.ac_do_simple_craft()
        elif state.ac_timed_armed and not state.ac_running:
            # First F press — launch timed loop
            state.ac_timed_armed = False
            state.ac_running = True
            state.ac_timed_f_pressed = False
            state.last_debug_context = "craft"
            auto_craft.craft_log("F pressed — Inventory Timed armed, launching loop")
            threading.Thread(target=auto_craft.ac_timed_loop, daemon=True).start()
        elif state.ac_running and not state.ac_grid_armed:
            # Subsequent F during timed loop
            state.ac_timed_f_pressed = True
        elif state.ac_grid_armed:
            # First F press — launch grid loop
            state.ac_grid_armed = False
            state.ac_grid_running = True
            state.ac_running = True
            state.last_debug_context = "craft"
            auto_craft.craft_log("F pressed — Grid Walk armed, launching loop")
            c = state.ac_grid_cols
            r = state.ac_grid_rows
            hw = state.ac_grid_hwalk
            vw = state.ac_grid_vwalk
            threading.Thread(target=auto_craft.ac_grid_loop,
                             args=(c, r, hw, vw), daemon=True).start()
        elif (state.depo_eggs_active or state.depo_embryo_active) and state.depo_cycle:
            # Depo cycle active — check if current step is depo or hatch
            idx = state.depo_cycle_idx
            if 1 <= idx <= len(state.depo_cycle) and state.depo_cycle[idx - 1]["filter"]:
                threading.Thread(target=quick_hatch.depo_f_pressed, daemon=True).start()
            elif state.qh_armed:
                threading.Thread(target=quick_hatch.qh_f_pressed, daemon=True).start()
        elif state.qh_armed:
            threading.Thread(target=quick_hatch.qh_f_pressed, daemon=True).start()
        elif state.sheep_auto_lvl_active:
            sheep.sheep_auto_lvl_f_pressed()
        elif state.ob_upload_armed:
            ob_upload.ob_f_pressed()
        elif state.ob_download_armed:
            ob_download.ob_down_f_pressed()
        elif state.run_auto_lvl_script:
            auto_level.auto_lvl_f_pressed()
        elif state.quick_feed_mode > 0:
            quick_feed.quick_feed_f_pressed()
        elif state.gmk_mode != "off":
            grab_my_kit.gmk_f_pressed()
        elif state.macro_armed or state.combo_armed:
            macro_system._macro_hotkey_handler(state.macro_selected_idx)

    def _z_handler(self):
        """Route Z key press to the active module."""
        if state.run_magic_f_script:
            if state.magic_f_refill_mode:
                return  # blocked in refill mode
            magic_f.magic_f_swap_direction()
            # Swap GUI give↔take checkboxes
            mf = self.tab_magicf
            root = self.root
            if mf and root:
                def _swap_gui():
                    from gui.tab_magicf import _RESOURCE_NAMES
                    for name in _RESOURCE_NAMES:
                        gv = mf.give_vars.get(name)
                        tv = mf.take_vars.get(name)
                        if gv and tv:
                            g, t = gv.get(), tv.get()
                            gv.set(t)
                            tv.set(g)
                    # Swap custom checkboxes and combo text
                    gc, tc = mf.give_custom_var.get(), mf.take_custom_var.get()
                    mf.give_custom_var.set(tc)
                    mf.take_custom_var.set(gc)
                    gt = mf.give_custom_combo.get()
                    tt = mf.take_custom_combo.get()
                    mf.give_custom_combo.set(tt)
                    mf.take_custom_combo.set(gt)
                root.after(0, _swap_gui)
            # Update tooltip
            from gui.tooltip import show_tooltip
            show_tooltip(magic_f.magic_f_build_tooltip(), 0, 0)
        elif state.pc_tab_active or state.pc_mode > 0:
            popcorn.pc_cycle_speed()
            name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
            # Update speed label on Popcorn tab (needs main thread)
            if self.tab_popcorn and self.root:
                self.root.after(0, lambda n=name: self.tab_popcorn.speed_txt.configure(text=f"{n} [Z]"))
            # Update tooltip — show_tooltip already marshals to main thread
            from gui.tooltip import show_tooltip
            if state.pc_f10_step == 1:
                show_tooltip(
                    f" F10 Quick: All (no filter)  |  F at inventory  |  Q = Stop  |  F1 = Stop/UI\n"
                    f"Z = Change drop speed  |  Speed: {name}", 0, 0)
            elif state.pc_f10_step == 2:
                show_tooltip(
                    f" F10 Quick: +Transfer  |  F at inventory  |  Q = Stop  |  F1 = Stop/UI\n"
                    f"Z = Change drop speed  |  Speed: {name}", 0, 0)
            else:
                tip = popcorn.pc_build_tooltip()
                if tip:
                    show_tooltip(tip, 0, 0)
        elif state.macro_tab_active or state.macro_armed or state.macro_playing:
            macro_system.macro_z_cycle()

    def _q_handler(self):
        """Route Q key press to the active module."""
        if state.run_magic_f_script:
            if state.magic_f_refill_mode:
                return  # blocked in refill mode
            magic_f.magic_f_cycle_preset()
            from gui.tooltip import show_tooltip
            show_tooltip(magic_f.magic_f_build_tooltip(), 0, 0)
        elif getattr(state, "imprint_scanning", False):
            auto_imprint.imprint_toggle_auto_mode()
        elif state.depo_eggs_active or state.depo_embryo_active:
            # Depo cycle active — Q cycles to next step
            if len(state.depo_cycle) > 1:
                quick_hatch.depo_cycle_next()
                from gui.tooltip import show_tooltip
                show_tooltip(quick_hatch.depo_build_tooltip(), 0, 0)
            return
        elif state.qh_armed or state.run_claim_and_name_script or state.run_name_and_spay_script:
            # Stop ALL of these in one Q press (not elif), then show GUI
            stopped_any = False
            if state.qh_armed:
                state.qh_armed = False
                state.qh_running = False
                state.qh_mode = 0
                from gui.tooltip import hide_tooltip
                hide_tooltip(1)
                # Reset GUI checkboxes
                if self.tab_misc and self.root:
                    def _reset_qh():
                        self.tab_misc.qh_all_var.set(False)
                        self.tab_misc.qh_single_var.set(False)
                        self.tab_misc.qh_status.configure(text="Select a mode then press START")
                    self.root.after(0, _reset_qh)
                stopped_any = True
            if state.run_claim_and_name_script:
                state.run_claim_and_name_script = False
                from gui.tooltip import hide_tooltip
                hide_tooltip(2)
                stopped_any = True
            if state.run_name_and_spay_script:
                state.run_name_and_spay_script = False
                from input.keyboard import send
                send("{e up}")
                from gui.tooltip import hide_tooltip
                hide_tooltip(2)
                stopped_any = True
            # Clear depo state
            state.depo_eggs_active = False
            state.depo_embryo_active = False
            state.depo_cycle.clear()
            state.depo_cycle_idx = 0
            if stopped_any and self.root:
                def _show_gui():
                    if state.main_gui:
                        state.main_gui.show()
                    state.gui_visible = True
                self.root.after(0, _show_gui)
            return
        elif state.run_auto_lvl_script:
            auto_level.auto_lvl_q_pressed()
        elif state.run_overcap_script:
            overcap.stop_overcap_script()
        elif state.ob_upload_running:
            ob_upload.ob_stop_all()
        elif state.ob_download_armed or state.ob_download_running:
            ob_download.ob_down_stop_all()
        elif state.pc_running:
            # Q during popcorn = early exit (advance to next filter in multi-step).
            # Do NOT call stop_popcorn() which also sets pc_f1_abort.
            state.pc_early_exit = True
        elif state.ac_simple_armed or state.ac_timed_armed or state.ac_grid_armed:
            # Cycle to next preset if multiple
            if len(state.ac_preset_names) > 1:
                state.ac_preset_idx = (state.ac_preset_idx % len(state.ac_preset_names)) + 1
                # Update tooltip to show new active preset
                mode = "Simple" if state.ac_simple_armed else "Timed" if state.ac_timed_armed else "Grid"
                from gui.tooltip import show_tooltip
                show_tooltip(auto_craft.ac_build_craft_tooltip(mode), 0, 0)
        elif state.ac_running and state.ac_timed_multi_active:
            # Q during multi-preset timed loop = cycle preset
            if len(state.ac_preset_names) > 1:
                state.ac_preset_idx = (state.ac_preset_idx % len(state.ac_preset_names)) + 1
        elif state.ac_running:
            state.ac_early_exit = True
        elif state.run_mammoth_script:
            mammoth_drums.stop_mammoth_script()
        elif state.autoclicking:
            autoclicker.toggle_autoclicker()

    def _e_handler(self):
        """Route E key press."""
        if state.run_claim_and_name_script:
            threading.Thread(target=name_spay.claim_and_name_e_pressed,
                             args=(state.dino_name,), daemon=True).start()
        elif state.run_name_and_spay_script:
            threading.Thread(target=name_spay.name_and_spay_e_pressed,
                             args=(state.dino_name,), daemon=True).start()
        elif state.pin_auto_open:
            auto_pin.pin_start_poll()

    def _r_handler(self):
        """R key — trigger imprint read & process when scanning."""
        if state.imprint_scanning:
            auto_imprint.imprint_on_read_and_process()

    def _bracket_left(self):
        """[ key — slow down."""
        if state.ob_download_running:
            state.ob_down_item_delay_ms = min(
                state.ob_down_item_delay_ms + state.ob_down_item_delay_step,
                state.ob_down_item_delay_max,
            )
        elif state.pc_tab_active:
            popcorn.pc_adjust_drop_sleep(1)
        elif state.autoclicking:
            autoclicker.autoclick_slower()

    def _bracket_right(self):
        """] key — speed up."""
        if state.ob_download_running:
            state.ob_down_item_delay_ms = max(
                state.ob_down_item_delay_ms - state.ob_down_item_delay_step,
                state.ob_down_item_delay_min,
            )
        elif state.pc_tab_active:
            popcorn.pc_adjust_drop_sleep(-1)
        elif state.autoclicking:
            autoclicker.autoclick_faster()

    def _apply_ini(self):
        """F5: Apply INI console commands to the game.

        Save clipboard → set clipboard to full command string →
        open command bar → Ctrl+V paste → Enter → restore clipboard.
        """
        from input.keyboard import send, key_press
        from input.window import win_exist, win_activate

        commands = state.ini_custom_command or state.ini_default_command

        hwnd = win_exist(state.ark_window)
        if not hwnd:
            return

        # Hide GUI
        self.root.after(0, self.root.withdraw)
        state.gui_visible = False

        # Activate ARK window
        win_activate(hwnd)
        time.sleep(0.300)

        # Save clipboard, set to command string, paste, restore
        try:
            from util.clipboard import get_clipboard_text, set_clipboard_text

            saved_clip = get_clipboard_text()

            set_clipboard_text(commands)

            # Open command bar
            key_press(state.ini_command_key.strip("{}"))
            time.sleep(0.400)

            # Paste with Ctrl+V
            send("^v")
            time.sleep(0.400)

            # Execute
            key_press("enter")
            time.sleep(0.500)

            # Restore clipboard
            if saved_clip is not None:
                set_clipboard_text(saved_clip)
        except Exception:
            pass

    def _on_tab_change(self, tab_name: str):
        """Handle tab changes — register/unregister module hotkeys."""
        # Reset tab-active flags
        state.pc_tab_active = (tab_name in ("Popcorn", "JoinSim"))
        state.sheep_tab_active = (tab_name == "Sheep")
        state.ac_tab_active = (tab_name == "Craft")
        state.macro_tab_active = (tab_name == "Macro")

        # Register sheep hotkeys when on sheep tab
        if tab_name == "Sheep" and self.hotkeys:
            sheep.sheep_register_hotkeys(self.hotkeys)
        else:
            sheep.sheep_unregister_hotkeys(self.hotkeys)

        # Register macro hotkeys when on macro tab
        if tab_name == "Macro" and self.hotkeys:
            macro_system.macro_register_hotkeys(True)
        else:
            macro_system.macro_block_all_hotkeys()

    def _load_lists(self):
        """Load all filter/name lists from INI."""
        from util.list_manager import ListManager

        managers = {
            "MagicFGiveFilters": state.mf_give_filter_list,
            "MagicFTakeFilters": state.mf_take_filter_list,
            "PopcornFilters": state.pc_custom_filter_list,
            "NameList": state.cn_name_list,
            "CraftSimpleFilters": state.ac_simple_filter_list,
            "CraftTimedFilters": state.ac_timed_filter_list,
            "CraftGridFilters": state.ac_grid_filter_list,
            "UploadFilters": state.uf_list,
            "Servers": state.svr_list,
        }

        for section, target_list in managers.items():
            lm = ListManager(section)
            loaded = lm.load()
            target_list.clear()
            target_list.extend(loaded)

        # Default name entry
        if not state.cn_name_list:
            state.cn_name_list.append("GG FFA")

        # Load server notes from INI
        from core.config import read_ini
        for i, svr in enumerate(state.svr_list, start=1):
            note = read_ini("Servers", f"Note{i}", "")
            if note:
                state.svr_notes[svr] = note

        # Populate comboboxes from loaded lists
        self._populate_combos()

        # Load macros
        macro_system.macro_load_all()

        # Populate macro treeview
        self._populate_macro_list()

    def _populate_combos(self):
        """Push loaded lists into their combobox widgets."""
        misc = self.tab_misc
        misc.name_combo["values"] = state.cn_name_list
        if state.cn_name_list:
            misc.name_combo.set(state.cn_name_list[0])

        misc.uf_combo["values"] = state.uf_list
        if state.uf_list:
            misc.uf_combo.set(state.uf_list[0])

        js = self.tab_joinsim
        js.refresh_server_combo()
        if state.svr_list:
            js.server_combo.set(js._svr_display_for(state.svr_list[0]))
            # Initialize ob_char_custom_server from the first server
            if not state.ob_char_custom_server:
                state.ob_char_custom_server = state.svr_list[0]

        # Pre-populate NTFY key edit
        if state.ntfy_key:
            js.ntfy_edit.delete(0, "end")
            js.ntfy_edit.insert(0, state.ntfy_key)

        # Magic F custom combos
        mf = self.tab_magicf
        mf.give_custom_combo["values"] = state.mf_give_filter_list
        mf.take_custom_combo["values"] = state.mf_take_filter_list

        # Popcorn custom combo
        pc = self.tab_popcorn
        pc.custom_combo["values"] = state.pc_custom_filter_list
        if state.pc_custom_filter:
            pc.custom_combo.set(state.pc_custom_filter)

        # Popcorn speed + drop key labels
        speed_name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
        pc.speed_txt.configure(text=f"{speed_name} [Z]")
        pc.drop_key_txt.configure(text=state.pc_drop_key.upper())

        # Craft tab combos
        ct = self.tab_craft
        ct.simple_filter_combo["values"] = state.ac_simple_filter_list
        ct.timed_filter_combo["values"] = state.ac_timed_filter_list
        ct.grid_filter_combo["values"] = state.ac_grid_filter_list

    def _populate_macro_list(self):
        """Push loaded macros into the Macro tab treeview."""
        macros = []
        for m in state.macro_list:
            speed = ""
            if m["type"] in ("recorded", "pyro", "guided"):
                speed = f"{m.get('speed_mult', 1.0):.1f}x"
            elif m["type"] == "repeat":
                speed = f"{m.get('repeat_interval', 1000)}ms"
            macros.append({
                "name": m.get("name", ""),
                "type": m.get("type", ""),
                "key": m.get("hotkey", ""),
                "speed": speed,
            })
        self.tab_macro.populate(macros)

    def _on_quit(self):
        """Clean exit."""
        self._stop_flags()
        timers.stop_all()
        if self.hotkeys:
            self.hotkeys.stop()
        if self.tray:
            self.tray.stop()
        if not getattr(self, '_timer_period_ended', False):
            _sys.end_timer_period(1)
            self._timer_period_ended = True
        if self.root:
            self.root.quit()
        sys.exit(0)

    def _cleanup(self):
        """Final cleanup."""
        if not getattr(self, '_timer_period_ended', False):
            _sys.end_timer_period(1)
            self._timer_period_ended = True
        timers.stop_all()
        if self.hotkeys:
            self.hotkeys.stop()
        if self.tray:
            self.tray.stop()
