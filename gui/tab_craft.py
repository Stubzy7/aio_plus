
import tkinter as tk
from tkinter import ttk
from gui.theme import *  # noqa: F403
from gui.theme import CB_OPTS, CB_OPTS_NOLABEL
from core.state import state


class TabCraft:
    """Builds the Craft tab UI inside the given parent frame."""

    def __init__(self, parent_frame: ttk.Frame, state: dict):
        self.parent = parent_frame
        self.state = state

        # ── Help button (top-right) ─────────────────────────
        self.grid_help_btn = tk.Button(
            parent_frame, text="?", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._show_grid_help,
        )
        self.grid_help_btn.place(x=357, y=5, width=32, height=18)

        # ── Tally / Count button ─────────────────────────
        self.sep_label_top = tk.Label(
            parent_frame, text="|", bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.sep_label_top.place(x=280, y=14, width=10, height=56)

        self.tally_btn = tk.Button(
            parent_frame, text="Count", font=("Segoe UI", 7, "bold"), fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._tally_toggle,
        )
        self.tally_btn.place(x=293, y=5, width=52, height=18)

        self.tally_hint = tk.Label(
            parent_frame, text="count items crafted",
            bg=BG_COLOR, fg="#666666", font=("Segoe UI", 7, "italic"), justify="center",
        )
        self.tally_hint.place(x=283, y=23, width=100, height=12)

        # ══════════════════════════════════════════════════════
        # SIMPLE CRAFT section
        # ══════════════════════════════════════════════════════
        self.simple_title = tk.Label(
            parent_frame, text="Simple Craft",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.simple_title.place(x=37, y=5, width=120, height=18)

        # Preset checkboxes row 1
        self.simple_spark_var = tk.BooleanVar()
        self.simple_spark_cb = tk.Checkbutton(
            parent_frame, text="spark", variable=self.simple_spark_var,
            command=lambda: self._mode_toggle("simple"), **CB_OPTS,
        )
        self.simple_spark_cb.place(x=37, y=25, width=60, height=23)

        self.simple_gp_var = tk.BooleanVar()
        self.simple_gp_cb = tk.Checkbutton(
            parent_frame, text="gp", variable=self.simple_gp_var,
            command=lambda: self._mode_toggle("simple"), **CB_OPTS,
        )
        self.simple_gp_cb.place(x=105, y=25, width=50, height=23)

        self.simple_elec_var = tk.BooleanVar()
        self.simple_elec_cb = tk.Checkbutton(
            parent_frame, text="electronics", variable=self.simple_elec_var,
            command=lambda: self._mode_toggle("simple"), **CB_OPTS,
        )
        self.simple_elec_cb.place(x=163, y=25, width=90, height=23)

        # Preset checkboxes row 2
        self.simple_adv_var = tk.BooleanVar()
        self.simple_adv_cb = tk.Checkbutton(
            parent_frame, text="adv", variable=self.simple_adv_var,
            command=lambda: self._mode_toggle("simple"), **CB_OPTS,
        )
        self.simple_adv_cb.place(x=37, y=48, width=50, height=23)

        self.simple_poly_var = tk.BooleanVar()
        self.simple_poly_cb = tk.Checkbutton(
            parent_frame, text="poly", variable=self.simple_poly_var,
            command=lambda: self._mode_toggle("simple"), **CB_OPTS,
        )
        self.simple_poly_cb.place(x=95, y=48, width=60, height=23)

        # Extra clicks
        self.extra_clicks_label = tk.Label(
            parent_frame, text="Extra clicks",
            bg=BG_COLOR, fg=FG_DIM, font=("Segoe UI", 7),
        )
        self.extra_clicks_label.place(x=293, y=38, width=55, height=14)

        self.extra_clicks_edit = tk.Entry(
            parent_frame, justify="center", font=("Segoe UI", 7),
        )
        self.extra_clicks_edit.insert(0, str(getattr(state, "ac_extra_clicks", 0)))
        self.extra_clicks_edit.place(x=307, y=52, width=25, height=18)

        # Loop checkbox
        self.simple_loop_var = tk.BooleanVar()
        self.simple_loop_cb = tk.Checkbutton(
            parent_frame, text="Loop", variable=self.simple_loop_var,
            **CB_OPTS,
        )
        self.simple_loop_cb.place(x=201, y=48, width=55, height=23)

        # Custom filter row
        self.simple_custom_var = tk.BooleanVar()
        self.simple_custom_cb = tk.Checkbutton(
            parent_frame, text="Custom:", variable=self.simple_custom_var,
            command=lambda: self._mode_toggle("simple"), **CB_OPTS,
        )
        self.simple_custom_cb.place(x=37, y=72, width=68, height=23)

        self.simple_filter_combo = ttk.Combobox(parent_frame, font=FONT_DEFAULT)
        self.simple_filter_combo.place(x=105, y=72, width=74, height=21)

        self.simple_filter_add_btn = tk.Button(
            parent_frame, text="+", font=("Segoe UI", 6, "bold"), fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._filter_add("simple"),
        )
        self.simple_filter_add_btn.place(x=181, y=68, width=14, height=13)

        self.simple_filter_del_btn = tk.Button(
            parent_frame, text="-", font=("Segoe UI", 6, "bold"), fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._filter_remove("simple"),
        )
        self.simple_filter_del_btn.place(x=181, y=82, width=14, height=13)

        # Simple START button
        self.simple_start_btn = tk.Button(
            parent_frame, text="START", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._start_simple,
        )
        self.simple_start_btn.place(x=201, y=71, width=100, height=28)

        # ── Separator ────────────────────────────────────────
        self.sep1 = tk.Frame(parent_frame, bg=FG_DIM, height=1)
        self.sep1.place(x=23, y=103, width=366)

        # ══════════════════════════════════════════════════════
        # INVENTORY TIMED section
        # ══════════════════════════════════════════════════════
        self.timed_title = tk.Label(
            parent_frame, text="Inventory Timed",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.timed_title.place(x=37, y=108, width=260, height=18)

        # Timed preset checkboxes row 1
        self.timed_elec_var = tk.BooleanVar()
        self.timed_elec_cb = tk.Checkbutton(
            parent_frame, text="electronics  3:20", variable=self.timed_elec_var,
            command=lambda: self._mode_toggle("timed", 200), **CB_OPTS,
        )
        self.timed_elec_cb.place(x=37, y=128, width=120, height=23)

        self.timed_adv_var = tk.BooleanVar()
        self.timed_adv_cb = tk.Checkbutton(
            parent_frame, text="adv  2:00", variable=self.timed_adv_var,
            command=lambda: self._mode_toggle("timed", 120), **CB_OPTS,
        )
        self.timed_adv_cb.place(x=165, y=128, width=90, height=23)

        # Timed preset checkboxes row 2
        self.timed_poly_var = tk.BooleanVar()
        self.timed_poly_cb = tk.Checkbutton(
            parent_frame, text="poly  3:30", variable=self.timed_poly_var,
            command=lambda: self._mode_toggle("timed", 210), **CB_OPTS,
        )
        self.timed_poly_cb.place(x=37, y=150, width=90, height=23)

        # Timed loop checkbox
        self.timed_loop_var = tk.BooleanVar()
        self.timed_loop_cb = tk.Checkbutton(
            parent_frame, text="Loop", variable=self.timed_loop_var,
            **CB_OPTS,
        )
        self.timed_loop_cb.place(x=311, y=150, width=55, height=23)

        # Timed custom filter row
        self.timed_custom_var = tk.BooleanVar()
        self.timed_custom_cb = tk.Checkbutton(
            parent_frame, text="Custom:", variable=self.timed_custom_var,
            command=lambda: self._mode_toggle("timed"), **CB_OPTS,
        )
        self.timed_custom_cb.place(x=37, y=174, width=68, height=23)

        self.timed_filter_combo = ttk.Combobox(parent_frame, font=FONT_SMALL)
        self.timed_filter_combo.place(x=105, y=174, width=74, height=21)

        self.timed_filter_add_btn = tk.Button(
            parent_frame, text="+", font=("Segoe UI", 6, "bold"), fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._filter_add("timed"),
        )
        self.timed_filter_add_btn.place(x=181, y=170, width=14, height=13)

        self.timed_filter_del_btn = tk.Button(
            parent_frame, text="-", font=("Segoe UI", 6, "bold"), fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._filter_remove("timed"),
        )
        self.timed_filter_del_btn.place(x=181, y=184, width=14, height=13)

        # Timer (s) entry
        self.timed_secs_label = tk.Label(
            parent_frame, text="Timer (s):", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.timed_secs_label.place(x=199, y=174, width=52, height=23)

        self.timed_secs_edit = tk.Entry(parent_frame, font=FONT_SMALL)
        self.timed_secs_edit.insert(0, "120")
        self.timed_secs_edit.place(x=253, y=174, width=52, height=23)

        # Timed START button
        self.timed_start_btn = tk.Button(
            parent_frame, text="START", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._start_timed,
        )
        self.timed_start_btn.place(x=311, y=173, width=100, height=28)

        # ── Separator ────────────────────────────────────────
        self.sep2 = tk.Frame(parent_frame, bg=FG_DIM, height=1)
        self.sep2.place(x=23, y=207, width=366)

        # ══════════════════════════════════════════════════════
        # GRID WALK section
        # ══════════════════════════════════════════════════════
        self.grid_title = tk.Label(
            parent_frame, text="Grid Walk",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.grid_title.place(x=37, y=212, width=80, height=18)

        # How many inventories row
        self.grid_inv_label = tk.Label(
            parent_frame, text="How many inventories:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.grid_inv_label.place(x=37, y=232, width=120, height=18)

        self.grid_ud_label = tk.Label(
            parent_frame, text="\u2191\u2193", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.grid_ud_label.place(x=163, y=232, width=20, height=18)

        self.cols_edit = tk.Entry(parent_frame, font=FONT_SMALL)
        self.cols_edit.insert(0, str(getattr(state, "ac_grid_cols", 1)))
        self.cols_edit.place(x=185, y=232, width=50, height=18)

        self.grid_lr_label = tk.Label(
            parent_frame, text="\u2190\u2192", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.grid_lr_label.place(x=241, y=232, width=20, height=18)

        self.rows_edit = tk.Entry(parent_frame, font=FONT_SMALL)
        self.rows_edit.insert(0, str(getattr(state, "ac_grid_rows", 11)))
        self.rows_edit.place(x=263, y=232, width=50, height=18)

        # OCR resize / copy buttons
        self.ocr_resize_btn = tk.Button(
            parent_frame, text="Resize", font=("Segoe UI", 7), fg=FG_COLOR,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_COLOR,
            command=self._ocr_toggle_resize,
        )
        self.ocr_resize_btn.place(x=320, y=232, width=52, height=18)

        self.ocr_copy_btn = tk.Button(
            parent_frame, text="Copy", font=("Segoe UI", 7), fg=FG_COLOR,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_COLOR,
            command=self._ocr_copy_total,
        )
        self.ocr_copy_btn.place(x=374, y=232, width=30, height=18)

        # OCR Count checkbox
        self.ocr_enable_var = tk.BooleanVar(value=getattr(state, "ac_ocr_enabled", False))
        self.ocr_enable_cb = tk.Checkbutton(
            parent_frame, text="Count", variable=self.ocr_enable_var,
            command=lambda: setattr(state, "ac_ocr_enabled", self.ocr_enable_var.get()),
            **CB_OPTS,
        )
        self.ocr_enable_cb.place(x=320, y=253, width=70, height=18)

        # Walk delay row
        self.walk_delay_label = tk.Label(
            parent_frame, text="Walk delay (ms):", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.walk_delay_label.place(x=37, y=252, width=120, height=18)

        self.grid_ud_label2 = tk.Label(
            parent_frame, text="\u2191\u2193", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.grid_ud_label2.place(x=163, y=252, width=20, height=18)

        self.hwalk_edit = tk.Entry(parent_frame, font=FONT_SMALL)
        self.hwalk_edit.insert(0, str(getattr(state, "ac_grid_hwalk", 0)))
        self.hwalk_edit.place(x=185, y=252, width=50, height=18)

        self.grid_lr_label2 = tk.Label(
            parent_frame, text="\u2190\u2192", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.grid_lr_label2.place(x=241, y=252, width=20, height=18)

        self.vwalk_edit = tk.Entry(parent_frame, font=FONT_SMALL)
        self.vwalk_edit.insert(0, str(getattr(state, "ac_grid_vwalk", 850)))
        self.vwalk_edit.place(x=263, y=252, width=50, height=18)

        # Grid preset checkboxes row 1
        self.grid_elec_var = tk.BooleanVar()
        self.grid_elec_cb = tk.Checkbutton(
            parent_frame, text="electronics", variable=self.grid_elec_var,
            command=lambda: self._mode_toggle("grid"), **CB_OPTS,
        )
        self.grid_elec_cb.place(x=37, y=273, width=90, height=23)

        self.grid_adv_var = tk.BooleanVar()
        self.grid_adv_cb = tk.Checkbutton(
            parent_frame, text="adv", variable=self.grid_adv_var,
            command=lambda: self._mode_toggle("grid"), **CB_OPTS,
        )
        self.grid_adv_cb.place(x=135, y=273, width=50, height=23)

        self.grid_poly_var = tk.BooleanVar()
        self.grid_poly_cb = tk.Checkbutton(
            parent_frame, text="poly", variable=self.grid_poly_var,
            command=lambda: self._mode_toggle("grid"), **CB_OPTS,
        )
        self.grid_poly_cb.place(x=193, y=273, width=55, height=23)

        # Grid preset checkboxes row 2
        self.grid_spark_var = tk.BooleanVar()
        self.grid_spark_cb = tk.Checkbutton(
            parent_frame, text="spark", variable=self.grid_spark_var,
            command=lambda: self._mode_toggle("grid"), **CB_OPTS,
        )
        self.grid_spark_cb.place(x=37, y=295, width=60, height=23)

        self.grid_gp_var = tk.BooleanVar()
        self.grid_gp_cb = tk.Checkbutton(
            parent_frame, text="gp", variable=self.grid_gp_var,
            command=lambda: self._mode_toggle("grid"), **CB_OPTS,
        )
        self.grid_gp_cb.place(x=105, y=295, width=50, height=23)

        # Grid custom filter row
        self.grid_custom_var = tk.BooleanVar()
        self.grid_custom_cb = tk.Checkbutton(
            parent_frame, text="Custom:", variable=self.grid_custom_var,
            command=lambda: self._mode_toggle("grid"), **CB_OPTS,
        )
        self.grid_custom_cb.place(x=37, y=319, width=68, height=23)

        self.grid_filter_combo = ttk.Combobox(parent_frame, font=FONT_DEFAULT)
        self.grid_filter_combo.place(x=105, y=319, width=74, height=21)

        self.grid_filter_add_btn = tk.Button(
            parent_frame, text="+", font=("Segoe UI", 6, "bold"), fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._filter_add("grid"),
        )
        self.grid_filter_add_btn.place(x=181, y=315, width=14, height=13)

        self.grid_filter_del_btn = tk.Button(
            parent_frame, text="-", font=("Segoe UI", 6, "bold"), fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._filter_remove("grid"),
        )
        self.grid_filter_del_btn.place(x=181, y=329, width=14, height=13)

        # Grid START button
        self.grid_start_btn = tk.Button(
            parent_frame, text="START", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._start_grid,
        )
        self.grid_start_btn.place(x=201, y=318, width=100, height=28)

        # Take-All checkbox with separator
        self.sep_takeall = tk.Label(
            parent_frame, text="|", bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.sep_takeall.place(x=306, y=318, width=10, height=28)

        self.takeall_var = tk.BooleanVar()
        self.takeall_cb = tk.Checkbutton(
            parent_frame, text="Take-All", variable=self.takeall_var,
            **CB_OPTS,
        )
        self.takeall_cb.place(x=318, y=323, width=100, height=18)

        self.takeall_hint = tk.Label(
            parent_frame, text="(every mode)",
            bg=BG_COLOR, fg=FG_DIM, font=("Segoe UI", 7, "italic"),
        )
        self.takeall_hint.place(x=320, y=340, width=80, height=12)

        # ── Feed interval footer ─────────────────────────────
        self.feed_label = tk.Label(
            parent_frame, text="Food/Water (9-0) feeds char every 45 mins in Grid mode",
            bg=BG_COLOR, fg="#666666", font=("Segoe UI", 7, "italic"), justify="center",
        )
        self.feed_label.place(x=23, y=353, width=366, height=14)

    # ------------------------------------------------------------------
    # Cross-mode mutual exclusion
    # ------------------------------------------------------------------
    def _mode_toggle(self, active_mode: str, timer_secs: int | None = None):
        """When a checkbox in one craft mode is checked, uncheck the other modes."""
        simple_vars = [self.simple_spark_var, self.simple_gp_var, self.simple_elec_var,
                       self.simple_adv_var, self.simple_poly_var, self.simple_custom_var]
        timed_vars = [self.timed_elec_var, self.timed_adv_var, self.timed_poly_var,
                      self.timed_custom_var]
        grid_vars = [self.grid_elec_var, self.grid_adv_var, self.grid_poly_var,
                     self.grid_spark_var, self.grid_gp_var, self.grid_custom_var]

        mode_vars = {"simple": simple_vars, "timed": timed_vars, "grid": grid_vars}
        for mode, vars_list in mode_vars.items():
            if mode != active_mode:
                for v in vars_list:
                    v.set(False)

        # For timed presets, update the timer seconds edit
        if active_mode == "timed" and timer_secs is not None:
            self.timed_secs_edit.delete(0, tk.END)
            self.timed_secs_edit.insert(0, str(timer_secs))

    # ------------------------------------------------------------------
    # Callbacks
    # ------------------------------------------------------------------
    def _show_grid_help(self):
        from gui.dialogs import show_help_dialog
        show_help_dialog("Craft Help",
            "Simple Craft\n"
            "Pick preset or type filter \u2192 START \u2192 F on inventory\n\n"
            "Inventory Timed\n"
            "Same as Simple but crafts on a timer with countdown\n\n"
            "Grid Walk\n"
            "Start at bottom-right inventory\n"
            "\u2191\u2193 = rows of inventories in front of you  |  \u2190\u2192 = amount of inventories in your row (incl. start pos)\n"
            "Walk delay = ms to move between inventories\n"
            "Try 850 for both to get an idea\n\n"
            "Use ladder to lock your camera\n"
            "Default setings to run Megalabs at rivercrafting \u2191\u2193 1 row, \u2190\u2192 11 inventories, walk \u2191\u2193 0, \u2190\u2192 850\n\n"
            "Take-All\n"
            "Transfers matching items from their inv before each craft",
            self.parent)

    def _tally_toggle(self):
        from modules.auto_craft import ac_tally_toggle
        ac_tally_toggle()
        if state.ac_count_only_active:
            self.tally_btn.configure(text="Stop", fg=FG_ACCENT)
            if state.main_gui:
                state.main_gui.hide()
        else:
            self.tally_btn.configure(text="Count", fg=FG_COLOR)

    def _filter_add(self, section: str):
        from util.list_manager import ListManager
        combo_map = {
            "simple": (self.simple_filter_combo, state.ac_simple_filter_list, "CraftSimpleFilters"),
            "timed": (self.timed_filter_combo, state.ac_timed_filter_list, "CraftTimedFilters"),
            "grid": (self.grid_filter_combo, state.ac_grid_filter_list, "CraftGridFilters"),
        }
        combo, state_list, lm_section = combo_map[section]
        text = combo.get().strip()
        if not text or text in state_list:
            return
        state_list.append(text)
        ListManager(lm_section, state_list).save()
        combo["values"] = state_list
        combo.set(text)

    def _filter_remove(self, section: str):
        from util.list_manager import ListManager
        combo_map = {
            "simple": (self.simple_filter_combo, state.ac_simple_filter_list, "CraftSimpleFilters"),
            "timed": (self.timed_filter_combo, state.ac_timed_filter_list, "CraftTimedFilters"),
            "grid": (self.grid_filter_combo, state.ac_grid_filter_list, "CraftGridFilters"),
        }
        combo, state_list, lm_section = combo_map[section]
        text = combo.get().strip()
        if not text or text not in state_list:
            return
        state_list.remove(text)
        ListManager(lm_section, state_list).save()
        combo["values"] = state_list
        combo.set(state_list[0] if state_list else "")

    def _build_presets(self, section: str) -> list[tuple[str, str]]:
        """Build list of (name, filter) from checked presets for the given section."""
        preset_map = {
            "simple": [
                (self.simple_spark_var, "spark", "rk"),
                (self.simple_gp_var, "gp", "np"),
                (self.simple_elec_var, "electronics", "onic"),
                (self.simple_adv_var, "adv", "m dv"),
                (self.simple_poly_var, "poly", "poly"),
            ],
            "timed": [
                (self.timed_elec_var, "electronics", "onic"),
                (self.timed_adv_var, "advanced", "m dv"),
                (self.timed_poly_var, "polymer", "poly"),
            ],
            "grid": [
                (self.grid_elec_var, "electronics", "onic"),
                (self.grid_adv_var, "adv", "m dv"),
                (self.grid_poly_var, "poly", "poly"),
                (self.grid_spark_var, "spark", "rk"),
                (self.grid_gp_var, "gp", "np"),
            ],
        }
        timer_map = {
            "electronics": 200,
            "advanced": 120,
            "polymer": 210,
        }
        result = []
        for var, name, filt in preset_map.get(section, []):
            if var.get():
                secs = timer_map.get(name, 120)
                result.append((name, filt, secs))

        # Custom filter
        custom_var = getattr(self, f"{section}_custom_var")
        custom_combo = getattr(self, f"{section}_filter_combo")
        if custom_var.get():
            ct = custom_combo.get().strip()
            if ct:
                result.append((f"Custom [{ct}]", ct, 120))

        return result

    def _arm_presets(self, presets: list):
        """Load preset names/filters/timer_secs into state."""
        state.ac_preset_names = [p[0] for p in presets]
        state.ac_preset_filters = [p[1] for p in presets]
        state.ac_preset_timer_secs = [p[2] for p in presets]
        state.ac_preset_idx = 1

    def _start_simple(self):
        from modules.auto_craft import ac_start_simple
        from gui.tooltip import show_tooltip

        presets = self._build_presets("simple")
        if not presets:
            from gui.tooltip import temp_tooltip
            temp_tooltip(" AutoCraft: choose a preset or enter a filter first", 2000)
            return
        self._arm_presets(presets)

        from core.config import write_ini
        state.ac_extra_clicks = int(self.extra_clicks_edit.get() or 0)
        write_ini("Craft", "ExtraClicks", str(state.ac_extra_clicks))
        state.ac_craft_loop_running = self.simple_loop_var.get()
        state.take_all_enabled = self.takeall_var.get()

        ac_start_simple()

        if state.ac_simple_armed and state.main_gui:
            state.main_gui.hide()

    def _start_timed(self):
        from modules.auto_craft import ac_start_timed
        from gui.tooltip import show_tooltip

        presets = self._build_presets("timed")
        if not presets:
            from gui.tooltip import temp_tooltip
            temp_tooltip(" AutoCraft: choose a preset or enter a filter first", 2000)
            return
        self._arm_presets(presets)

        state.ac_craft_loop_running = self.timed_loop_var.get()
        state.take_all_enabled = self.takeall_var.get()

        try:
            timer_secs = int(self.timed_secs_edit.get())
        except ValueError:
            timer_secs = 120

        ac_start_timed(timer_secs)

        if state.ac_timed_armed and state.main_gui:
            state.main_gui.hide()

    def _start_grid(self):
        from modules.auto_craft import ac_start_grid
        from gui.tooltip import show_tooltip
        from core.config import write_ini

        presets = self._build_presets("grid")
        if not presets:
            from gui.tooltip import temp_tooltip
            temp_tooltip(" AutoCraft: choose a preset or enter a filter first", 2000)
            return
        self._arm_presets(presets)

        state.take_all_enabled = self.takeall_var.get()
        state.ac_ocr_enabled = self.ocr_enable_var.get()

        try:
            cols = int(self.cols_edit.get())
        except ValueError:
            cols = 1
        try:
            rows = int(self.rows_edit.get())
        except ValueError:
            rows = 11
        try:
            hwalk = int(self.hwalk_edit.get())
        except ValueError:
            hwalk = 0
        try:
            vwalk = int(self.vwalk_edit.get())
        except ValueError:
            vwalk = 850

        # Persist grid settings to INI
        write_ini("Grid", "Cols", str(cols))
        write_ini("Grid", "Rows", str(rows))
        write_ini("Grid", "HWalk", str(hwalk))
        write_ini("Grid", "VWalk", str(vwalk))

        ac_start_grid(cols, rows, hwalk, vwalk)

        if state.ac_grid_armed and state.main_gui:
            state.main_gui.hide()

    def _ocr_toggle_resize(self):
        from modules.auto_craft import ac_ocr_toggle_resize
        ac_ocr_toggle_resize()
        # Update button text when resizing
        if state.ac_ocr_resizing:
            self.ocr_resize_btn.configure(
                text=f"{state.ac_ocr_snap_w}x{state.ac_ocr_snap_h}")
        else:
            self.ocr_resize_btn.configure(text="Resize")

    def _ocr_copy_total(self):
        """Copy the OCR crafted count total to clipboard."""
        try:
            total = getattr(state, "ac_ocr_total", 0)
            self.parent.clipboard_clear()
            self.parent.clipboard_append(str(total))
        except Exception:
            pass
