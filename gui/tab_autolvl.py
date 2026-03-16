
import tkinter as tk
from tkinter import ttk
from gui.theme import *
from core.state import state


class TabAutoLvl:
    """Builds all widgets for the AutoLvL tab inside *parent_frame*."""

    def __init__(self, parent_frame: ttk.Frame, state):
        self.frame = parent_frame
        self.state = state
        self._build()

    # ------------------------------------------------------------------
    def _build(self):
        f = self.frame

        # --- Info banner ---
        self.info_text = tk.Label(
            f, text="\nChoose the points below then click START\n",
            font=FONT_SMALL_BOLD, fg=FG_ACCENT, bg=BG_COLOR,
            relief="solid", bd=1, justify="center",
        )
        self.info_text.place(x=85, y=25, width=270, height=45)

        # --- Stat rows ---
        stats = [
            ("Health", 90),
            ("Stam",   125),
            ("Food",   160),
            ("Weight", 195),
            ("Melee",  230),
        ]
        self.stat_vars = {}
        self.stat_edits = {}
        self.stat_spinboxes = {}

        for name, y in stats:
            # Label
            tk.Label(f, text=f"{name} Points:", font=FONT_BOLD, fg=FG_COLOR,
                     bg=BG_COLOR, anchor="w").place(x=70, y=y, width=100, height=25)

            # Spinbox for stat points
            var = tk.IntVar(value=0)
            spin = ttk.Spinbox(f, from_=0, to=85, textvariable=var, width=5,
                               font=FONT_DEFAULT)
            spin.place(x=155, y=y, width=60, height=25)

            self.stat_vars[name.lower()] = var
            self.stat_spinboxes[name.lower()] = spin

        # --- Auto Saddle checkbox ---
        self.auto_saddle_var = tk.BooleanVar(value=False)
        self.auto_saddle_chk = tk.Checkbutton(
            f, text="Auto Saddle", variable=self.auto_saddle_var, **CB_OPTS,
        )
        self.auto_saddle_chk.place(x=45, y=270)

        # --- No Oxy checkbox ---
        self.no_oxy_var = tk.BooleanVar(value=False)
        self.no_oxy_chk = tk.Checkbutton(
            f, text="No Oxy", variable=self.no_oxy_var, **CB_OPTS,
        )
        self.no_oxy_chk.place(x=45, y=293)

        # --- START button ---
        self.start_btn = tk.Button(f, text="START", font=FONT_BOLD, fg=FG_ACCENT,
                                   bg=BG_DARK, activebackground=BG_DARK,
                                   activeforeground=FG_ACCENT,
                                   command=self._start)
        self.start_btn.place(x=160, y=280, width=80, height=28)

        # --- Cryo checkbox ---
        self.cryo_var = tk.BooleanVar(value=False)
        self.cryo_chk = tk.Checkbutton(
            f, text="Cryo", variable=self.cryo_var, **CB_OPTS,
        )
        self.cryo_chk.place(x=250, y=284, width=65, height=20)

        # --- Combine Stats checkbox ---
        self.combine_var = tk.BooleanVar(value=True)
        self.combine_chk = tk.Checkbutton(
            f, text="Combine Stats", variable=self.combine_var, **CB_OPTS,
        )
        self.combine_chk.place(x=250, y=264, width=120, height=20)

    # ------------------------------------------------------------------
    def _start(self):
        """Arm auto-level — read spinbox values, hide GUI, call module."""
        from modules.auto_level import run_auto_lvl
        from gui.tooltip import show_tooltip

        stat_points = {}
        for key, var in self.stat_vars.items():
            try:
                val = var.get()
            except Exception:
                val = 0
            if val > 0:
                stat_points[key] = val

        combine = self.combine_var.get()

        run_auto_lvl(
            stat_points=stat_points,
            no_oxy=self.no_oxy_var.get(),
            auto_saddle=self.auto_saddle_var.get(),
            cryo_after=self.cryo_var.get(),
            combine=combine,
        )

        # Hide GUI
        if state.main_gui:
            state.main_gui.hide()

        from modules.auto_level import auto_lvl_build_tooltip
        show_tooltip(auto_lvl_build_tooltip(), 0, 0)
