
import tkinter as tk
from tkinter import ttk
from gui.theme import *
from core.state import state


class TabPopcorn:

    def __init__(self, parent_frame: ttk.Frame, state):
        self.frame = parent_frame
        self.state = state
        self._build()

    def _build(self):
        f = self.frame

        self.help_btn = tk.Button(f, text="?", font=(FONT_FAMILY, 7, "bold"),
                                  fg=FG_ACCENT, bg=BG_DARK, activebackground=BG_DARK,
                                  activeforeground=FG_ACCENT,
                                  command=self._show_help)
        self.help_btn.place(x=370, y=28, width=32, height=18)

        self.all_no_filter_var = tk.BooleanVar(value=False)
        self.all_no_filter_chk = tk.Checkbutton(
            f, text="All (no filter)", variable=self.all_no_filter_var,
            command=self._toggle_all_no_filter, **CB_OPTS,
        )
        self.all_no_filter_chk.place(x=32, y=50, width=120, height=20)

        filters = [
            ("Poly",    32,  60),
            ("Metal",   98,  65),
            ("Crystal", 168, 72),
            ("Raw",     246, 55),
            ("Cooked",  306, 72),
        ]
        self.filter_vars = {}
        self.filter_chks = {}
        for name, x, w in filters:
            var = tk.BooleanVar(value=False)
            chk = tk.Checkbutton(f, text=name, variable=var,
                                 command=lambda n=name.lower(): self._toggle_filter(n), **CB_OPTS)
            chk.place(x=x, y=72, width=w, height=20)
            self.filter_vars[name.lower()] = var
            self.filter_chks[name.lower()] = chk

        self.custom_var = tk.BooleanVar(value=False)
        self.custom_chk = tk.Checkbutton(
            f, text="Custom:", variable=self.custom_var,
            command=self._toggle_custom, **CB_OPTS,
        )
        self.custom_chk.place(x=32, y=108, width=72, height=20)

        self.custom_combo = ttk.Combobox(f, font=FONT_DEFAULT)
        self.custom_combo.place(x=108, y=106, width=104, height=21)

        self.custom_add_btn = tk.Button(f, text="+", font=("Segoe UI", 6, "bold"),
                                        fg=FG_ACCENT, bg=BG_DARK, activebackground=BG_DARK,
                                        activeforeground=FG_ACCENT,
                                        command=self._custom_add)
        self.custom_add_btn.place(x=214, y=102, width=14, height=13)

        self.custom_del_btn = tk.Button(f, text="-", font=("Segoe UI", 6, "bold"),
                                        fg=FG_ACCENT, bg=BG_DARK, activebackground=BG_DARK,
                                        activeforeground=FG_ACCENT,
                                        command=self._custom_remove)
        self.custom_del_btn.place(x=214, y=116, width=14, height=13)

        self.transfer_all_var = tk.BooleanVar(value=False)
        self.transfer_all_chk = tk.Checkbutton(
            f, text="Transfer All", variable=self.transfer_all_var,
            command=lambda: setattr(state, "pc_forge_transfer_all", self.transfer_all_var.get()),
            **CB_OPTS,
        )
        self.transfer_all_chk.place(x=245, y=102, width=110, height=18)

        self.skip_first_var = tk.BooleanVar(value=False)
        self.skip_first_chk = tk.Checkbutton(
            f, text="Skip First Slot", variable=self.skip_first_var,
            command=lambda: setattr(state, "pc_forge_skip_first", self.skip_first_var.get()),
            **CB_OPTS,
        )
        self.skip_first_chk.place(x=245, y=120, width=120, height=18)

        tk.Label(f, text="Speed:", font=FONT_SMALL, fg=FG_DIM,
                 bg=BG_COLOR, anchor="w").place(x=32, y=146, width=44, height=16)
        _speed_name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
        self.speed_txt = tk.Label(f, text=f"{_speed_name} [Z]", font=FONT_SMALL, fg=FG_ACCENT,
                                  bg=BG_COLOR, anchor="w")
        self.speed_txt.place(x=78, y=146, width=88, height=16)

        tk.Label(f, text="Drop Key:", font=FONT_SMALL, fg=FG_DIM,
                 bg=BG_COLOR, anchor="w").place(x=32, y=166, width=72, height=16)
        self.drop_key_txt = tk.Label(f, text=state.pc_drop_key.upper(), font=FONT_SMALL, fg=FG_ACCENT,
                                     bg=BG_COLOR, anchor="w")
        self.drop_key_txt.place(x=98, y=166, width=60, height=16)

        self.set_keys_btn = tk.Button(f, text="Set Keys", font=FONT_DEFAULT,
                                      fg=FG_ACCENT, bg=BG_DARK, activebackground=BG_DARK,
                                      activeforeground=FG_ACCENT,
                                      command=self._show_set_keys)
        self.set_keys_btn.place(x=32, y=188, width=120, height=28)

        self.scan_area_btn = tk.Button(f, text="Scan Area", font=FONT_SMALL,
                                       fg=FG_ACCENT, bg=BG_DARK, activebackground=BG_DARK,
                                       activeforeground=FG_ACCENT,
                                       command=self._toggle_scan_resize)
        self.scan_area_btn.place(x=280, y=188, width=80, height=28)
        self._scan_overlay = None
        self._scan_resize_active = False

        self.start_btn = tk.Button(f, text="Start", font=FONT_BOLD, fg=FG_ACCENT,
                                   bg=BG_DARK, activebackground=BG_DARK,
                                   activeforeground=FG_ACCENT,
                                   command=self._start)
        self.start_btn.place(x=168, y=188, width=100, height=28)

        hint_font = FONT_SMALL
        tk.Label(f, text="Z = Change drop speed  |  Q = Cycle selected presets",
                 font=hint_font, fg=FG_COLOR, bg=BG_COLOR,
                 anchor="center").place(x=32, y=219, width=354, height=14)
        tk.Label(f, text="Auto-stops when storage empty  |  F1 = Stop",
                 font=hint_font, fg=FG_COLOR, bg=BG_COLOR,
                 anchor="center").place(x=32, y=233, width=354, height=14)

        self.status_txt = tk.Label(
            f, text="Select a mode then press F at an inventory",
            font=hint_font, fg=FG_COLOR, bg=BG_COLOR, anchor="center",
        )
        self.status_txt.place(x=32, y=249, width=354, height=14)

    def _toggle_all_no_filter(self):
        state.pc_all_no_filter = self.all_no_filter_var.get()
        if state.pc_all_no_filter:
            for var in self.filter_vars.values():
                var.set(False)
            self.custom_var.set(False)
            state.pc_grinder_poly = False
            state.pc_grinder_metal = False
            state.pc_grinder_crystal = False
            state.pc_preset_raw = False
            state.pc_preset_cooked = False
            state.pc_all_custom_active = False

    def _toggle_filter(self, name: str):
        state_map = {
            "poly": "pc_grinder_poly",
            "metal": "pc_grinder_metal",
            "crystal": "pc_grinder_crystal",
            "raw": "pc_preset_raw",
            "cooked": "pc_preset_cooked",
        }
        val = self.filter_vars[name].get()
        setattr(state, state_map[name], val)
        if val:
            self.all_no_filter_var.set(False)
            state.pc_all_no_filter = False

    def _toggle_custom(self):
        state.pc_all_custom_active = self.custom_var.get()
        if state.pc_all_custom_active:
            self.all_no_filter_var.set(False)
            state.pc_all_no_filter = False

    def _custom_add(self):
        from util.list_manager import ListManager
        text = self.custom_combo.get().strip()
        if not text or text in state.pc_custom_filter_list:
            return
        state.pc_custom_filter_list.append(text)
        ListManager("PopcornFilters", state.pc_custom_filter_list).save()
        self.custom_combo["values"] = state.pc_custom_filter_list
        self.custom_combo.set(text)

    def _custom_remove(self):
        from util.list_manager import ListManager
        text = self.custom_combo.get().strip()
        if not text or text not in state.pc_custom_filter_list:
            return
        state.pc_custom_filter_list.remove(text)
        ListManager("PopcornFilters", state.pc_custom_filter_list).save()
        self.custom_combo["values"] = state.pc_custom_filter_list
        self.custom_combo.set(state.pc_custom_filter_list[0] if state.pc_custom_filter_list else "")

    def _start(self):
        from gui.tooltip import show_tooltip
        from core.config import read_ini, write_ini
        from input.window import win_exist
        from modules.popcorn import (pc_set_status, pc_register_speed_hotkeys,
                                     pc_show_armed_tooltip, stop_popcorn)

        if state.pc_running:
            state.pc_early_exit = True
            pc_set_status("Stopping...")
            return

        state.pc_all_no_filter = self.all_no_filter_var.get()
        state.pc_grinder_poly = self.filter_vars.get("poly", tk.BooleanVar()).get()
        state.pc_grinder_metal = self.filter_vars.get("metal", tk.BooleanVar()).get()
        state.pc_grinder_crystal = self.filter_vars.get("crystal", tk.BooleanVar()).get()
        state.pc_preset_raw = self.filter_vars.get("raw", tk.BooleanVar()).get()
        state.pc_preset_cooked = self.filter_vars.get("cooked", tk.BooleanVar()).get()
        state.pc_all_custom_active = self.custom_var.get()
        state.pc_custom_filter = self.custom_combo.get().strip()
        state.pc_forge_transfer_all = self.transfer_all_var.get()
        state.pc_forge_skip_first = self.skip_first_var.get()

        if state.pc_custom_filter:
            write_ini("Popcorn", "CustomFilter", state.pc_custom_filter)

        checked = []
        if state.pc_all_no_filter:
            checked.append("all")
        if state.pc_grinder_poly:
            checked.append("poly")
        if state.pc_grinder_metal:
            checked.append("metal")
        if state.pc_grinder_crystal:
            checked.append("crystal")
        if state.pc_preset_raw:
            checked.append("raw")
        if state.pc_preset_cooked:
            checked.append("cooked")
        if state.pc_all_custom_active and state.pc_custom_filter:
            checked.append("custom")

        if not checked:
            pc_set_status("Select a mode first")
            return

        saved_drop = read_ini("Popcorn", "DropKey", "")
        if not saved_drop or saved_drop == "Default":
            self._show_set_keys_prompt()
            return

        if not win_exist(state.ark_window):
            pc_set_status("ARK window not found")
            return

        state.pc_mode = 3
        state.pc_tab_active = True

        pc_register_speed_hotkeys(True)

        state.gui_visible = False
        if state.main_gui:
            state.main_gui.hide()

        pc_set_status("Armed — press F at an inventory")
        pc_show_armed_tooltip()

    def _show_set_keys(self):
        from core.config import write_ini

        existing = getattr(self, '_set_keys_dlg', None)
        if existing is not None:
            try:
                existing.destroy()
            except Exception:
                pass
            self._set_keys_dlg = None
            return

        dlg = tk.Toplevel(self.frame)
        dlg.title("Set Keys")
        dlg.configure(bg=BG_DARK)
        dlg.attributes("-topmost", True)
        dlg.resizable(False, False)
        self._set_keys_dlg = dlg

        tk.Label(dlg, text="Drop Key:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=15, width=80, height=24)
        drop_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        drop_edit.insert(0, getattr(state, "pc_drop_key", "o"))
        drop_edit.place(x=100, y=15, width=80, height=24)

        tk.Label(dlg, text="Inv Key:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=48, width=80, height=24)
        inv_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        inv_edit.insert(0, getattr(state, "pc_inv_key", "f"))
        inv_edit.place(x=100, y=48, width=80, height=24)

        def _detect_into(entry):
            entry.delete(0, tk.END)
            entry.insert(0, "Press key...")
            def on_key(event):
                entry.delete(0, tk.END)
                entry.insert(0, event.keysym.lower())
                dlg.unbind("<Key>", bid)
            bid = dlg.bind("<Key>", on_key)

        tk.Button(dlg, text="Detect", font=FONT_SMALL, fg=FG_COLOR,
                  bg=BG_COLOR, command=lambda: _detect_into(drop_edit)
                  ).place(x=185, y=15, width=50, height=24)
        tk.Button(dlg, text="Detect", font=FONT_SMALL, fg=FG_COLOR,
                  bg=BG_COLOR, command=lambda: _detect_into(inv_edit)
                  ).place(x=185, y=48, width=50, height=24)

        def _save():
            state.pc_drop_key = drop_edit.get().strip().lower()
            inv_val = inv_edit.get().strip().lower()
            state.pc_inv_key = inv_val
            write_ini("Popcorn", "DropKey", state.pc_drop_key)
            write_ini("Popcorn", "InvKey", inv_val)
            # Shared inventory key — persist for Sheep and Imprint too
            state.sheep_inventory_key = inv_val
            state.imprint_inventory_key = inv_val
            write_ini("Sheep", "InventoryKey", inv_val)
            write_ini("Imprint", "InventoryKey", inv_val)
            self.drop_key_txt.configure(text=state.pc_drop_key.upper())
            try:
                dlg.destroy()
            except Exception:
                pass
            self._set_keys_dlg = None

        def _close():
            try:
                dlg.destroy()
            except Exception:
                pass
            self._set_keys_dlg = None

        tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT,
                  bg=BG_COLOR, command=_save).place(x=50, y=82, width=80, height=26)
        tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                  bg=BG_COLOR, command=_close).place(x=140, y=82, width=80, height=26)

        dlg.protocol("WM_DELETE_WINDOW", _close)
        dlg.geometry("250x118")

    def _show_help(self):
        from gui.dialogs import show_help_dialog
        show_help_dialog("Popcorn Help",
            "Presets: Select any or all presets\n"
            "  1 preset = Popcorn until Q (Q = stop)\n"
            "  2+ presets = Q cycles to next last Q = Stop, F1 = Stop/UI\n\n"
            "All (no filter): drops everything\n"
            "Custom: Can add custom filter to preset cycle\n"
            "  Can combine with presets for cycling\n\n"
            "Transfer All: transfers your inventory on stop\n"
            "Skip First Slot: skips top-left slot (ele for forges etc)\n\n"
            "F10:  cycles quick modes\n"
            "Z:  change drop speed  (Safe / Fast / Very Fast)\n"
            "Q:  stop (1 preset) / cycle selected presets (2+)\n"
            "F1:  stop / UI\n\n"
            "Set Drop/key before first use",
            self.frame)

    def _toggle_scan_resize(self):
        if self._scan_resize_active:
            self._exit_scan_resize()
        else:
            self._enter_scan_resize()

    def _enter_scan_resize(self):
        self._scan_resize_active = True
        self.scan_area_btn.configure(text="Done")
        self._show_scan_overlay()

        from gui.tooltip import show_tooltip
        show_tooltip("Scan Area: WASD=move  Arrows=resize  Enter=done")

        root = state.root
        if root:
            self._bindings = []
            for seq, handler in [
                ("<w>", lambda e: self._scan_move(0, -10)),
                ("<s>", lambda e: self._scan_move(0, 10)),
                ("<a>", lambda e: self._scan_move(-10, 0)),
                ("<d>", lambda e: self._scan_move(10, 0)),
                ("<Up>", lambda e: self._scan_resize(0, -10)),
                ("<Down>", lambda e: self._scan_resize(0, 10)),
                ("<Left>", lambda e: self._scan_resize(-10, 0)),
                ("<Right>", lambda e: self._scan_resize(10, 0)),
                ("<Return>", lambda e: self._exit_scan_resize()),
            ]:
                bid = root.bind(seq, handler)
                self._bindings.append((seq, bid))

    def _exit_scan_resize(self):
        self._scan_resize_active = False
        self.scan_area_btn.configure(text="Scan Area")
        self._hide_scan_overlay()

        from gui.tooltip import hide_tooltip
        hide_tooltip()

        root = state.root
        if root:
            for seq, bid in getattr(self, "_bindings", []):
                try:
                    root.unbind(seq, bid)
                except Exception:
                    pass
            self._bindings = []

        from core.config import write_ini
        wm = state.width_multiplier or 1
        hm = state.height_multiplier or 1
        write_ini("Popcorn", "StorageScanX", str(round(state.pc_storage_scan_x / wm)))
        write_ini("Popcorn", "StorageScanY", str(round(state.pc_storage_scan_y / hm)))
        write_ini("Popcorn", "StorageScanW", str(round(state.pc_storage_scan_w / wm)))
        write_ini("Popcorn", "StorageScanH", str(round(state.pc_storage_scan_h / hm)))

    def _scan_move(self, dx: int, dy: int):
        state.pc_storage_scan_x = max(0, state.pc_storage_scan_x + dx)
        state.pc_storage_scan_y = max(0, state.pc_storage_scan_y + dy)
        self._show_scan_overlay()

    def _scan_resize(self, dw: int, dh: int):
        state.pc_storage_scan_w = max(20, state.pc_storage_scan_w + dw)
        state.pc_storage_scan_h = max(10, state.pc_storage_scan_h + dh)
        self._show_scan_overlay()

    def _show_scan_overlay(self):
        self._hide_scan_overlay()
        try:
            from gui.overlay import show_rect_overlay
            self._scan_overlay = show_rect_overlay(
                state.pc_storage_scan_x, state.pc_storage_scan_y,
                state.pc_storage_scan_w, state.pc_storage_scan_h,
                color="red", border=2,
            )
        except Exception:
            pass

    def _hide_scan_overlay(self):
        if self._scan_overlay is not None:
            try:
                from gui.overlay import hide_rect_overlay
                hide_rect_overlay(self._scan_overlay)
            except Exception:
                pass
            self._scan_overlay = None

    def _show_set_keys_prompt(self):
        state.gui_visible = True
        if state.main_gui:
            state.main_gui.show()

        dlg = tk.Toplevel(self.frame)
        dlg.title("Keys Not Set")
        dlg.configure(bg="#1A1A1A")
        dlg.attributes("-topmost", True)
        dlg.resizable(False, False)

        tk.Label(dlg, text="Set your keys before continuing",
                 bg="#1A1A1A", fg="#DDDDDD",
                 font=("Segoe UI", 10)).place(x=20, y=20, width=300, height=20)

        def _ok():
            dlg.destroy()
            self._show_set_keys()

        tk.Button(dlg, text="Set Keys Now", font=("Segoe UI", 9, "bold"),
                  fg="#FF4444", bg="#1A1A1A",
                  command=_ok).place(x=20, y=58, width=150, height=28)
        tk.Button(dlg, text="Do It Later", font=("Segoe UI", 9),
                  fg="#888888", bg="#1A1A1A",
                  command=dlg.destroy).place(x=180, y=58, width=140, height=28)

        dlg.geometry("340x100")
        dlg.focus_force()

    def _custom_filter_clear(self):
        state.pc_custom_filter = ""
        self.custom_combo.set("")
        try:
            from core.config import write_ini
            write_ini("Popcorn", "CustomFilter", "")
        except Exception:
            pass

    def _calibrate(self):
        from modules.popcorn import pc_set_status
        from core.config import write_ini

        def _wait_key(title, subtitle, callback):
            dlg = tk.Toplevel(self.frame)
            dlg.title("Calibrate")
            dlg.configure(bg="#1A1A1A")
            dlg.attributes("-topmost", True)
            dlg.resizable(False, False)

            tk.Label(dlg, text=title, bg="#1A1A1A", fg="#DDDDDD",
                     font=("Segoe UI", 10, "bold")).place(x=20, y=18, width=300)
            tk.Label(dlg, text=subtitle, bg="#1A1A1A", fg="#888888",
                     font=("Segoe UI", 9)).place(x=20, y=42, width=300)
            tk.Label(dlg, text="Hover the cursor and press any key (20s timeout)",
                     bg="#1A1A1A", fg="#555555",
                     font=("Segoe UI", 9, "italic")).place(x=20, y=64, width=300)

            dlg.geometry("340x95")

            timeout_id = [None]

            def on_key(event):
                if timeout_id[0]:
                    dlg.after_cancel(timeout_id[0])
                dlg.destroy()
                from input.mouse import get_cursor_pos
                mx, my = get_cursor_pos()
                callback(mx, my)

            def on_timeout():
                dlg.destroy()
                callback(None, None)

            dlg.bind("<Key>", on_key)
            timeout_id[0] = dlg.after(20000, on_timeout)

        def step1():
            pc_set_status("Calibrate: hover over TOP-LEFT slot")
            _wait_key(
                "Step 1 of 2 — Top-Left Slot",
                "Hover cursor over the top-left inventory slot",
                on_step1_done
            )

        def on_step1_done(x, y):
            if x is None:
                pc_set_status("Timed out — calibration cancelled")
                return
            self._cal_x1 = x
            self._cal_y1 = y
            pc_set_status(f"Got top-left: ({x}, {y}) — now bottom-right")
            step2()

        def step2():
            _wait_key(
                "Step 2 of 2 — Bottom-Right Slot",
                "Hover cursor over the bottom-right inventory slot",
                on_step2_done
            )

        def on_step2_done(x, y):
            if x is None:
                pc_set_status("Timed out — calibration cancelled")
                return

            x1, y1 = self._cal_x1, self._cal_y1
            cols = state.pc_columns or 6
            rows = state.pc_rows or 6
            w = max(1, (x - x1) // (cols - 1)) if cols > 1 else 50
            h = max(1, (y - y1) // (rows - 1)) if rows > 1 else 50

            state.pc_start_slot_x = x1
            state.pc_start_slot_y = y1
            state.pc_slot_w = w
            state.pc_slot_h = h

            wm = state.width_multiplier or 1
            hm = state.height_multiplier or 1
            write_ini("Popcorn", "StartSlotX", str(round(x1 / wm)))
            write_ini("Popcorn", "StartSlotY", str(round(y1 / hm)))
            write_ini("Popcorn", "SlotW", str(round(w / wm)))
            write_ini("Popcorn", "SlotH", str(round(h / hm)))

            pc_set_status(f"Calibrated: start=({x1},{y1}) slot={w}x{h}")

        step1()

    def pc_update_ui(self):
        from modules.popcorn import pc_update_f10_speed

        if hasattr(self, "status_txt"):
            if state.pc_running:
                self.status_txt.configure(text="Running...")
            elif state.pc_mode > 0:
                self.status_txt.configure(text="Armed")
            else:
                self.status_txt.configure(text="")

        pc_update_f10_speed()

        if hasattr(self, "speed_txt"):
            name = state.pc_speed_names.get(state.pc_speed_mode, "Fast")
            self.speed_txt.configure(text=f"{name} [Z]" if state.pc_mode > 0 else name)

        if hasattr(self, "drop_key_txt"):
            self.drop_key_txt.configure(
                text=(state.pc_drop_key or "?").upper())

        if state.pc_f10_step == 0:
            if hasattr(self, "f10_status_txt"):
                self.f10_status_txt.configure(text="")
            if hasattr(self, "f10_speed_txt"):
                self.f10_speed_txt.configure(text="")
