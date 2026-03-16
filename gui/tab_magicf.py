
import tkinter as tk
from tkinter import ttk
from gui.theme import (
    BG_COLOR, BG_DARK, FG_COLOR, FG_DIM, FG_ACCENT, FONT_FAMILY,
    AHKCheckbox,
)
from core.state import state

# Fonts for Magic F tab
_FONT_HEADER = (FONT_FAMILY, 11, "bold")
_FONT_CB     = (FONT_FAMILY, 10)
_FONT_BTN    = (FONT_FAMILY, 10, "bold")    # START button
_FONT_HINT   = (FONT_FAMILY, 9)             # Q/Z hint text
_FONT_SMALL  = (FONT_FAMILY, 7, "bold")     # +/- buttons
_FONT_REFILL = (FONT_FAMILY, 9, "bold")     # Take/Refill button

# The 24 resource names in grid order
_RESOURCE_NAMES = [
    "Beer",    "Berry",   "Charc",   "Cooked",
    "Crystal", "Dust",    "Fert",    "Fiber",
    "Flint",   "Hide",    "Honey",   "Metal",
    "Narcotic","Oil",     "Paste",   "Pearl",
    "Poly",    "Raw",     "Spoiled", "Stim",
    "Stone",   "Sulfur",  "Thatch",  "Wood",
]

# Grid geometry for the 24 checkboxes (4 columns)
_COL_X = [75, 150, 230, 310]
_GIVE_Y_START = 44
_TAKE_Y_START = 198
_ROW_H = 18
_CB_H = 20
# Per-name width overrides; default is 65
_WIDTH_OVERRIDE = {"Cooked": 70, "Narcotic": 72, "Spoiled": 72}


class TabMagicF:
    """Builds all widgets for the Magic F tab inside *parent_frame*."""

    def __init__(self, parent_frame: ttk.Frame, state):
        self.frame = parent_frame
        self.state = state
        self.refill_mode = False
        self._build()

    # ------------------------------------------------------------------
    def _build(self):
        f = self.frame

        # --- "Give:" header ---
        self.give_label = tk.Label(f, text="Give:", font=_FONT_HEADER, fg=FG_ACCENT,
                                   bg=BG_COLOR)
        self.give_label.place(x=190, y=25)

        # --- Help button ---
        self.help_btn = tk.Button(f, text="?", font=(FONT_FAMILY, 9, "bold"),
                                  fg=FG_ACCENT, bg=BG_DARK,
                                  activebackground=BG_DARK,
                                  activeforeground=FG_ACCENT,
                                  relief="raised", borderwidth=1,
                                  command=self._show_help)
        self.help_btn.place(x=385, y=32, width=28, height=20)

        # --- Give checkboxes (24) ---
        self.give_vars = {}
        self.give_chks = {}
        for idx, name in enumerate(_RESOURCE_NAMES):
            row, col = divmod(idx, 4)
            y = _GIVE_Y_START + row * _ROW_H
            x = _COL_X[col]
            w = _WIDTH_OVERRIDE.get(name, 65)
            var = tk.BooleanVar(value=False)
            chk = AHKCheckbox(f, text=name, variable=var,
                              font=_FONT_CB, fg=FG_COLOR, bg=BG_COLOR,
                              command=self._on_give_clicked)
            chk.place(x=x, y=y, width=w, height=_CB_H)
            self.give_vars[name] = var
            self.give_chks[name] = chk

        # --- Give custom row ---
        self.give_custom_var = tk.BooleanVar(value=False)
        self.give_custom_chk = AHKCheckbox(
            f, text="Custom:", variable=self.give_custom_var,
            font=_FONT_CB, fg=FG_COLOR, bg=BG_COLOR,
            command=self._on_give_clicked,
        )
        self.give_custom_chk.place(x=75, y=158, width=70, height=_CB_H)

        self.give_custom_combo = ttk.Combobox(f, font=_FONT_CB)
        self.give_custom_combo.place(x=150, y=156, width=185, height=21)

        self.give_add_btn = tk.Button(f, text="+", font=_FONT_SMALL,
                                      fg=FG_ACCENT, bg=BG_DARK,
                                      activebackground=BG_DARK,
                                      activeforeground=FG_ACCENT,
                                      relief="raised", borderwidth=1,
                                      command=self._give_add)
        self.give_add_btn.place(x=337, y=156, width=13, height=21)

        self.give_del_btn = tk.Button(f, text="-", font=_FONT_SMALL,
                                      fg=FG_ACCENT, bg=BG_DARK,
                                      activebackground=BG_DARK,
                                      activeforeground=FG_ACCENT,
                                      relief="raised", borderwidth=1,
                                      command=self._give_remove)
        self.give_del_btn.place(x=352, y=156, width=13, height=21)

        # --- "Take:" header ---
        self.take_label = tk.Label(f, text="Take:", font=_FONT_HEADER, fg=FG_ACCENT,
                                   bg=BG_COLOR)
        self.take_label.place(x=190, y=180)

        # --- Take checkboxes (24) ---
        self.take_vars = {}
        self.take_chks = {}
        for idx, name in enumerate(_RESOURCE_NAMES):
            row, col = divmod(idx, 4)
            y = _TAKE_Y_START + row * _ROW_H
            x = _COL_X[col]
            w = _WIDTH_OVERRIDE.get(name, 65)
            var = tk.BooleanVar(value=False)
            chk = AHKCheckbox(f, text=name, variable=var,
                              font=_FONT_CB, fg=FG_COLOR, bg=BG_COLOR,
                              command=self._on_take_clicked)
            chk.place(x=x, y=y, width=w, height=_CB_H)
            self.take_vars[name] = var
            self.take_chks[name] = chk

        # --- Take custom row ---
        self.take_custom_var = tk.BooleanVar(value=False)
        self.take_custom_chk = AHKCheckbox(
            f, text="Custom:", variable=self.take_custom_var,
            font=_FONT_CB, fg=FG_COLOR, bg=BG_COLOR,
            command=self._on_take_clicked,
        )
        self.take_custom_chk.place(x=75, y=312, width=70, height=_CB_H)

        self.take_custom_combo = ttk.Combobox(f, font=_FONT_CB)
        self.take_custom_combo.place(x=150, y=310, width=185, height=21)

        self.take_add_btn = tk.Button(f, text="+", font=_FONT_SMALL,
                                      fg=FG_ACCENT, bg=BG_DARK,
                                      activebackground=BG_DARK,
                                      activeforeground=FG_ACCENT,
                                      relief="raised", borderwidth=1,
                                      command=self._take_add)
        self.take_add_btn.place(x=337, y=310, width=13, height=21)

        self.take_del_btn = tk.Button(f, text="-", font=_FONT_SMALL,
                                      fg=FG_ACCENT, bg=BG_DARK,
                                      activebackground=BG_DARK,
                                      activeforeground=FG_ACCENT,
                                      relief="raised", borderwidth=1,
                                      command=self._take_remove)
        self.take_del_btn.place(x=352, y=310, width=13, height=21)

        # --- Take/Refill button ---
        self.refill_btn = tk.Button(f, text="Take/Refill", font=_FONT_REFILL,
                                    fg=FG_COLOR, bg=BG_DARK,
                                    activebackground=BG_DARK,
                                    activeforeground=FG_COLOR,
                                    relief="raised", borderwidth=1,
                                    command=self._toggle_refill)
        self.refill_btn.place(x=75, y=338, width=90, height=28)

        # --- START button ---
        self.start_btn = tk.Button(f, text="START", font=_FONT_BTN, fg=FG_ACCENT,
                                   bg=BG_DARK, activebackground=BG_DARK,
                                   activeforeground=FG_ACCENT,
                                   relief="raised", borderwidth=1,
                                   command=self._start)
        self.start_btn.place(x=265, y=338, width=100, height=28)

        # Lift headers above checkboxes (created later, so they overlap)
        self.give_label.lift()
        self.take_label.lift()

        # --- Hint labels ---
        tk.Label(f, text="Q = Cycle selected presets", font=_FONT_HINT, fg=FG_DIM,
                 bg=BG_COLOR).place(x=145, y=370)
        tk.Label(f, text="Z = Swap Give \u2194 Take", font=_FONT_HINT, fg=FG_DIM,
                 bg=BG_COLOR).place(x=145, y=386)

    # ------------------------------------------------------------------
    def _on_give_clicked(self):
        """When any Give checkbox is clicked, clear all Take checkboxes (unless refill)."""
        if self.refill_mode:
            return
        for var in self.take_vars.values():
            var.set(False)
        self.take_custom_var.set(False)
        self.take_custom_combo.set("")

    def _on_take_clicked(self):
        """When any Take checkbox is clicked, clear all Give checkboxes (unless refill)."""
        if self.refill_mode:
            return
        for var in self.give_vars.values():
            var.set(False)
        self.give_custom_var.set(False)
        self.give_custom_combo.set("")

    def _toggle_refill(self):
        self.refill_mode = not self.refill_mode
        if self.refill_mode:
            self.refill_btn.configure(text="\u25b6 Take/Refill", bg="#445544")
        else:
            self.refill_btn.configure(text="Take/Refill", bg=BG_DARK)
            # When turning refill OFF, also stop any running magic F
            if state.run_magic_f_script:
                from modules.magic_f import stop_magic_f
                stop_magic_f()
                from gui.tooltip import hide_tooltip
                hide_tooltip()

    def _start(self):
        """Read all checkbox states, arm Magic F, hide GUI, show tooltip."""
        from modules.magic_f import run_magic_f, magic_f_build_tooltip, GIVE_PRESETS, TAKE_PRESETS
        from gui.tooltip import show_tooltip

        # Set refill mode on state before building presets
        state.magic_f_refill_mode = self.refill_mode

        # Build give checks: (is_checked, label, filter_text)
        give_checks = []
        for label, filt in GIVE_PRESETS:
            var = self.give_vars.get(label)
            give_checks.append((var.get() if var else False, label, filt))

        # Build take checks
        take_checks = []
        for label, filt in TAKE_PRESETS:
            var = self.take_vars.get(label)
            take_checks.append((var.get() if var else False, label, filt))

        run_magic_f(
            give_checks, take_checks,
            custom_give_active=self.give_custom_var.get(),
            custom_give_text=self.give_custom_combo.get(),
            custom_take_active=self.take_custom_var.get(),
            custom_take_text=self.take_custom_combo.get(),
        )

        # Hide GUI, show tooltip
        if state.main_gui:
            state.main_gui.hide()
        show_tooltip(magic_f_build_tooltip(), 0, 0)

    # ------------------------------------------------------------------
    # Add / Remove callbacks
    # ------------------------------------------------------------------
    def _give_add(self):
        from util.list_manager import ListManager
        text = self.give_custom_combo.get().strip()
        if not text or text in state.mf_give_filter_list:
            return
        state.mf_give_filter_list.append(text)
        ListManager("MagicFGiveFilters", state.mf_give_filter_list).save()
        self.give_custom_combo["values"] = state.mf_give_filter_list
        self.give_custom_combo.set(text)

    def _give_remove(self):
        from util.list_manager import ListManager
        text = self.give_custom_combo.get().strip()
        if not text or text not in state.mf_give_filter_list:
            return
        state.mf_give_filter_list.remove(text)
        ListManager("MagicFGiveFilters", state.mf_give_filter_list).save()
        self.give_custom_combo["values"] = state.mf_give_filter_list
        self.give_custom_combo.set(state.mf_give_filter_list[0] if state.mf_give_filter_list else "")

    def _take_add(self):
        from util.list_manager import ListManager
        text = self.take_custom_combo.get().strip()
        if not text or text in state.mf_take_filter_list:
            return
        state.mf_take_filter_list.append(text)
        ListManager("MagicFTakeFilters", state.mf_take_filter_list).save()
        self.take_custom_combo["values"] = state.mf_take_filter_list
        self.take_custom_combo.set(text)

    def _take_remove(self):
        from util.list_manager import ListManager
        text = self.take_custom_combo.get().strip()
        if not text or text not in state.mf_take_filter_list:
            return
        state.mf_take_filter_list.remove(text)
        ListManager("MagicFTakeFilters", state.mf_take_filter_list).save()
        self.take_custom_combo["values"] = state.mf_take_filter_list
        self.take_custom_combo.set(state.mf_take_filter_list[0] if state.mf_take_filter_list else "")

    def _show_help(self):
        from gui.dialogs import show_help_dialog
        show_help_dialog("Magic F Help",
            "Select Give OR Take presets (any amount)\n"
            "  F at inventory = transfer current preset\n"
            "  Q = cycle presets  |  Z = swap give\u2194take\n\n"
            "Take/Refill:\n"
            "  Press Take/Refill then select one preset from BOTH Give and Take\n"
            "  F at inventory = take all, then give all\n"
            "Custom: type filter text + check Custom\n"
            "F1 = stop / show UI",
            self.frame)
