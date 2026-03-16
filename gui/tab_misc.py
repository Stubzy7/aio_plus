
import tkinter as tk
from tkinter import ttk
from gui.theme import *  # noqa: F401,F403
from gui.theme import CB_OPTS, CB_OPTS_NOLABEL
from core.state import state


class TabMisc:
    """Builds the Misc tab UI inside the given parent frame."""

    def __init__(self, parent_frame: ttk.Frame, state: dict):
        self.parent = parent_frame
        self.state = state

        # ══════════════════════════════════════════════════════
        # QUICK HATCH section
        # ══════════════════════════════════════════════════════

        # Mode checkboxes (mutually exclusive via callbacks)
        self.qh_all_var = tk.BooleanVar(value=(getattr(state, "qh_mode", 0) == 1))
        self.qh_all_cb = tk.Checkbutton(
            parent_frame, text="Quick Hatch (All)", variable=self.qh_all_var,
            command=lambda: self._qh_toggle_mode(1), **CB_OPTS,
        )
        self.qh_all_cb.place(x=22, y=7, width=130, height=23)

        self.qh_single_var = tk.BooleanVar(value=(getattr(state, "qh_mode", 0) == 2))
        self.qh_single_cb = tk.Checkbutton(
            parent_frame, text="Quick Hatch (Single)", variable=self.qh_single_var,
            command=lambda: self._qh_toggle_mode(2), **CB_OPTS,
        )
        self.qh_single_cb.place(x=160, y=7, width=140, height=23)

        # Help button
        self.qh_help_btn = tk.Button(
            parent_frame, text="?", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._show_ns_help,
        )
        self.qh_help_btn.place(x=350, y=7, width=24, height=23)

        # Status text
        self.qh_status = tk.Label(
            parent_frame, text="Select a mode then press START",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC,
        )
        self.qh_status.place(x=22, y=37, width=200, height=14)

        # ── Claim / Name row ─────────────────────────────────
        self.cn_label = tk.Label(
            parent_frame, text="Claim/Name",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.cn_label.place(x=22, y=65, width=80)

        self.cn_enable_var = tk.BooleanVar(value=getattr(state, "cn_enabled", False))
        self.cn_enable_cb = tk.Checkbutton(
            parent_frame, variable=self.cn_enable_var,
            command=self._cn_toggled, **CB_OPTS_NOLABEL,
        )
        self.cn_enable_cb.place(x=105, y=65, width=15, height=20)

        self.depo_embryo_var = tk.BooleanVar()
        self.depo_embryo_cb = tk.Checkbutton(
            parent_frame, text="Depo Embryo", variable=self.depo_embryo_var,
            command=self._depo_embryo_toggled, **CB_OPTS,
        )
        self.depo_embryo_cb.place(x=135, y=65, width=110, height=20)

        # ── Name / Spay row ──────────────────────────────────
        self.ns_label = tk.Label(
            parent_frame, text="Name/Spay",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.ns_label.place(x=22, y=89, width=80)

        self.ns_enable_var = tk.BooleanVar(value=getattr(state, "ns_enabled", False))
        self.ns_enable_cb = tk.Checkbutton(
            parent_frame, variable=self.ns_enable_var,
            command=self._ns_toggled, **CB_OPTS_NOLABEL,
        )
        self.ns_enable_cb.place(x=105, y=89, width=15, height=20)

        self.depo_eggs_var = tk.BooleanVar()
        self.depo_eggs_cb = tk.Checkbutton(
            parent_frame, text="Depo Eggs", variable=self.depo_eggs_var,
            command=self._depo_eggs_toggled, **CB_OPTS,
        )
        self.depo_eggs_cb.place(x=135, y=89, width=100, height=20)

        # ── Dino Name row ────────────────────────────────────
        self.name_label = tk.Label(
            parent_frame, text="Name:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_BOLD,
        )
        self.name_label.place(x=22, y=115, width=55, height=25)

        self.name_combo = ttk.Combobox(parent_frame, font=FONT_DEFAULT)
        self.name_combo.place(x=78, y=115, width=128, height=21)

        self.name_add_btn = tk.Button(
            parent_frame, text="+", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._cn_add_name,
        )
        self.name_add_btn.place(x=208, y=115, width=16, height=21)

        self.name_del_btn = tk.Button(
            parent_frame, text="-", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._cn_remove_name,
        )
        self.name_del_btn.place(x=226, y=115, width=16, height=21)

        # Cryo checkbox
        self.cryo_var = tk.BooleanVar(value=getattr(state, "qh_cryo_after", False))
        self.cryo_cb = tk.Checkbutton(
            parent_frame, text="Cryo", variable=self.cryo_var,
            command=lambda: setattr(state, "qh_cryo_after", self.cryo_var.get()), **CB_OPTS,
        )
        self.cryo_cb.place(x=248, y=115, width=55, height=25)

        # START button for quick hatch
        self.qh_start_btn = tk.Button(
            parent_frame, text="START", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._qh_start,
        )
        self.qh_start_btn.place(x=308, y=112, width=70, height=28)

        # ── Separator ────────────────────────────────────────
        self.sep1 = tk.Frame(parent_frame, bg=FG_DIM, height=1)
        self.sep1.place(x=8, y=145, width=366)

        # ══════════════════════════════════════════════════════
        # INI section
        # ══════════════════════════════════════════════════════
        self.ini_title = tk.Label(
            parent_frame, text="Apply INI  \u2014  F5",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.ini_title.place(x=22, y=153, width=200)

        self.ini_subtitle = tk.Label(
            parent_frame, text="Pastes INI into command bar",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL,
        )
        self.ini_subtitle.place(x=22, y=171, width=200)

        # Command key row
        self.cmd_key_label = tk.Label(
            parent_frame, text="Cmd Key:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.cmd_key_label.place(x=22, y=191, width=55, height=20)

        self.cmd_key_edit = tk.Entry(parent_frame, font=FONT_SMALL)
        self.cmd_key_edit.insert(0, getattr(state, "ini_command_key", "Tab"))
        self.cmd_key_edit.place(x=78, y=191, width=55, height=20)

        self.cmd_key_detect_btn = tk.Button(
            parent_frame, text="Set", font=FONT_SMALL, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._ini_detect_key,
        )
        self.cmd_key_detect_btn.place(x=136, y=191, width=36, height=20)

        self.cmd_key_save_btn = tk.Button(
            parent_frame, text="Save", font=FONT_SMALL, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._ini_save_cmd_key,
        )
        self.cmd_key_save_btn.place(x=175, y=191, width=44, height=20)

        # Custom INI
        self.custom_ini_label = tk.Label(
            parent_frame, text="Custom INI (blank = default):",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL,
        )
        self.custom_ini_label.place(x=22, y=215, width=200)

        self.custom_ini_edit = tk.Text(
            parent_frame, font=FONT_SMALL, wrap="word", height=3,
        )
        self.custom_ini_edit.insert("1.0", getattr(state, "ini_custom_command", ""))
        self.custom_ini_edit.place(x=22, y=231, width=200, height=40)

        self.save_custom_ini_btn = tk.Button(
            parent_frame, text="Save Custom INI", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._ini_save_custom,
        )
        self.save_custom_ini_btn.place(x=22, y=275, width=96, height=20)

        self.save_hatch_btn = tk.Button(
            parent_frame, text="Save Hatch", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._save_hatch_settings,
        )
        self.save_hatch_btn.place(x=22, y=299, width=96, height=20)

        # ── Auto Pin / NVIDIA Filter ─────────────────────────
        self.sep_pin = tk.Label(
            parent_frame, text="|", bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.sep_pin.place(x=122, y=299, width=10, height=40)

        self.pin_var = tk.BooleanVar(value=getattr(state, "pin_auto_open", False))
        self.pin_cb = tk.Checkbutton(
            parent_frame, text="Auto Pin", variable=self.pin_var,
            command=self._pin_toggle, **CB_OPTS,
        )
        self.pin_cb.place(x=136, y=299, width=80, height=20)

        self.nf_var = tk.BooleanVar(value=getattr(state, "nf_enabled", False))
        self.nf_cb = tk.Checkbutton(
            parent_frame, text="NVIDIA Filter", variable=self.nf_var,
            command=self._nf_toggle, **CB_OPTS,
        )
        self.nf_cb.place(x=136, y=319, width=120, height=20)

        # ══════════════════════════════════════════════════════
        # AUTO IMPRINT section (right column)
        # ══════════════════════════════════════════════════════
        self.imprint_sep = tk.Frame(parent_frame, bg=FG_ACCENT, width=1)
        self.imprint_sep.place(x=230, y=171, width=1, height=40)

        self.imprint_title = tk.Label(
            parent_frame, text="Auto Imprint",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_BOLD,
        )
        self.imprint_title.place(x=242, y=153, width=190)

        self.imprint_start_btn = tk.Button(
            parent_frame, text="Start", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._imprint_toggle,
        )
        self.imprint_start_btn.place(x=242, y=175, width=100, height=26)

        self.imprint_help_btn = tk.Button(
            parent_frame, text="?", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._imprint_show_help,
        )
        self.imprint_help_btn.place(x=344, y=175, width=24, height=26)

        self.imprint_hide_var = tk.BooleanVar(value=getattr(state, "imprint_hide_overlay", False))
        self.imprint_hide_cb = tk.Checkbutton(
            parent_frame, text="Hide scan outline", variable=self.imprint_hide_var,
            command=self._imprint_hide_toggled, **CB_OPTS,
        )
        self.imprint_hide_cb.place(x=242, y=205, width=140, height=16)

        # Inv Key
        self.imprint_key_label = tk.Label(
            parent_frame, text="Inv Key:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_SMALL,
        )
        self.imprint_key_label.place(x=242, y=227, width=50, height=20)

        self.imprint_inv_key_edit = tk.Entry(parent_frame, font=FONT_SMALL)
        self.imprint_inv_key_edit.insert(0, getattr(state, "imprint_inventory_key", "i"))
        self.imprint_inv_key_edit.place(x=296, y=227, width=28, height=20)

        self.imprint_resize_btn = tk.Button(
            parent_frame, text="Resize", font=FONT_SMALL, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._imprint_toggle_resize,
        )
        self.imprint_resize_btn.place(x=326, y=227, width=52, height=20)

        self.imprint_status = tk.Label(
            parent_frame, text="Press Start then R=read Q=auto",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC,
        )
        self.imprint_status.place(x=242, y=253, width=190, height=16)

        # ══════════════════════════════════════════════════════
        # UPLOAD FILTER section (right column, bottom)
        # ══════════════════════════════════════════════════════
        self.uf_sep = tk.Frame(parent_frame, bg=FG_DIM, height=1)
        self.uf_sep.place(x=236, y=273, width=180)

        self.uf_title = tk.Label(
            parent_frame, text="Upload Filter",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_SMALL_BOLD,
        )
        self.uf_title.place(x=242, y=279, width=100, height=14)

        self.uf_enable_var = tk.BooleanVar()
        self.uf_enable_cb = tk.Checkbutton(
            parent_frame, variable=self.uf_enable_var,
            command=lambda: setattr(state, "uf_enabled", self.uf_enable_var.get()), **CB_OPTS_NOLABEL,
        )
        self.uf_enable_cb.place(x=342, y=277, width=15, height=18)

        self.uf_combo = ttk.Combobox(parent_frame, font=FONT_SMALL)
        self.uf_combo.place(x=242, y=297, width=128, height=21)

        self.uf_add_btn = tk.Button(
            parent_frame, text="+", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._uf_add,
        )
        self.uf_add_btn.place(x=374, y=297, width=18, height=21)

        self.uf_del_btn = tk.Button(
            parent_frame, text="-", font=FONT_SMALL_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._uf_remove,
        )
        self.uf_del_btn.place(x=394, y=297, width=18, height=21)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _qh_toggle_mode(self, mode: int):
        """Ensure only one Quick Hatch mode is active at a time."""
        if mode == 1:
            if self.qh_all_var.get():
                self.qh_single_var.set(False)
        elif mode == 2:
            if self.qh_single_var.get():
                self.qh_all_var.set(False)

    def _cn_toggled(self):
        """Claim/Name and Name/Spay are mutually exclusive."""
        if self.cn_enable_var.get():
            self.ns_enable_var.set(False)

    def _ns_toggled(self):
        if self.ns_enable_var.get():
            self.cn_enable_var.set(False)

    def _depo_embryo_toggled(self):
        state.depo_embryo_enabled = self.depo_embryo_var.get()
        if self.depo_embryo_var.get():
            self.depo_eggs_var.set(False)
            state.depo_eggs_enabled = False

    def _depo_eggs_toggled(self):
        state.depo_eggs_enabled = self.depo_eggs_var.get()
        if self.depo_eggs_var.get():
            self.depo_embryo_var.set(False)
            state.depo_embryo_enabled = False

    # ------------------------------------------------------------------
    # Stub callbacks
    # ------------------------------------------------------------------
    def _show_ns_help(self):
        from gui.dialogs import show_help_dialog
        show_help_dialog("Hatch & Name Modes",
            "Run at standard gamma\n\n"
            "Hatch\n"
            "All: hatches every egg  |  Single: hatches one at a time\n"
            "F at inventory to hatch\n\n"
            "Claim/Name\n"
            "E on a tame to name it\n\n"
            "Name/Spay\n"
            "E on a tame to name/spay\n\n"
            "Running Together\n"
            "Select a hatch mode then press a name mode START\n"
            "F for hatching, E for naming  |  Q = Stop all",
            self.parent)

    def _qh_start(self):
        """Arm Quick Hatch — sync mode/options from checkboxes, call module."""
        import logging
        _log = logging.getLogger(__name__)
        from modules.quick_hatch import qh_start
        from gui.tooltip import show_tooltip

        # Sync mode from checkboxes
        if self.qh_all_var.get():
            state.qh_mode = 1
        elif self.qh_single_var.get():
            state.qh_mode = 2
        else:
            state.qh_mode = 0

        # Sync name/claim options — use separate "enabled" flags so the
        # disarm check in qh_start() can distinguish already-armed state
        # from fresh checkbox state (reads btn.Value separately from
        # the active flags).
        state.cn_enabled = self.cn_enable_var.get()
        state.ns_enabled = self.ns_enable_var.get()
        state.depo_embryo_enabled = self.depo_embryo_var.get()
        state.depo_eggs_enabled = self.depo_eggs_var.get()
        state.qh_cryo_after = self.cryo_var.get()

        _log.info("_qh_start: mode=%d cn=%s ns=%s depo_e=%s depo_em=%s cryo=%s",
                  state.qh_mode, state.cn_enabled, state.ns_enabled,
                  state.depo_eggs_enabled, state.depo_embryo_enabled,
                  state.qh_cryo_after)

        # Sync dino name from combo
        name = self.name_combo.get().strip()
        if name:
            state.dino_name = name

        qh_start()

        _log.info("_qh_start: after qh_start() — armed=%s cn_script=%s ns_script=%s "
                  "depo_eggs_active=%s depo_embryo_active=%s depo_cycle=%s",
                  state.qh_armed, state.run_claim_and_name_script,
                  state.run_name_and_spay_script, state.depo_eggs_active,
                  state.depo_embryo_active, state.depo_cycle)

        # Always hide GUI on arm (not just when hatch enabled)
        any_armed = (state.qh_armed or state.run_claim_and_name_script
                     or state.run_name_and_spay_script
                     or state.depo_eggs_active or state.depo_embryo_active)
        _log.info("_qh_start: any_armed=%s main_gui=%s", any_armed, state.main_gui)
        if any_armed:
            state.gui_visible = False
            # Build tooltip text
            if state.depo_cycle:
                from modules.quick_hatch import depo_build_tooltip
                tt = depo_build_tooltip()
            else:
                # No depo cycle — simple hatch/CN/NS tooltip
                parts = []
                if state.qh_armed:
                    mode_label = "All" if state.qh_mode == 1 else "Single"
                    parts.append(f"Hatch {mode_label} [F=hatch]")
                if state.run_claim_and_name_script:
                    parts.append("E = Claim/Name (always on)")
                elif state.run_name_and_spay_script:
                    parts.append("E = Name/Spay (always on)")
                parts.append("F1 = stop")
                tt = "\n".join(parts)
            _log.info("_qh_start: showing tooltip: %r", tt)
            # Show tooltip first, then hide GUI — tooltip is a separate
            # Toplevel but needs root visible during creation on some systems
            show_tooltip(tt, 0, 0)
            if state.main_gui:
                # Defer hide so the tooltip Toplevel gets created first
                self.parent.after(50, state.main_gui.hide)
        else:
            _log.info("_qh_start: nothing armed, no tooltip")

    def _cn_add_name(self):
        from util.list_manager import ListManager
        text = self.name_combo.get().strip()
        if not text or text in state.cn_name_list:
            return
        state.cn_name_list.append(text)
        ListManager("NameList", state.cn_name_list).save()
        self.name_combo["values"] = state.cn_name_list
        self.name_combo.set(text)

    def _cn_remove_name(self):
        from util.list_manager import ListManager
        text = self.name_combo.get().strip()
        if not text or text not in state.cn_name_list:
            return
        state.cn_name_list.remove(text)
        ListManager("NameList", state.cn_name_list).save()
        self.name_combo["values"] = state.cn_name_list
        self.name_combo.set(state.cn_name_list[0] if state.cn_name_list else "")

    def _ini_detect_key(self):
        """Bind next key press to fill the command key entry."""
        toplevel = self.parent.winfo_toplevel()
        self.cmd_key_edit.delete(0, tk.END)
        self.cmd_key_edit.insert(0, "Press a key...")

        def on_key(event):
            self.cmd_key_edit.delete(0, tk.END)
            self.cmd_key_edit.insert(0, event.keysym)
            toplevel.unbind("<Key>", bind_id)

        bind_id = toplevel.bind("<Key>", on_key)

    def _ini_save_cmd_key(self):
        from core.config import write_ini
        self.state.ini_command_key = self.cmd_key_edit.get()
        write_ini("ini", "commandkey", self.state.ini_command_key)

    def _ini_save_custom(self):
        from core.config import write_ini
        self.state.ini_custom_command = self.custom_ini_edit.get("1.0", tk.END).strip()
        write_ini("ini", "customcommand", self.state.ini_custom_command)

    def _save_hatch_settings(self):
        """Persist hatch-related settings to INI."""
        from core.config import write_ini
        mode = 0
        if self.qh_all_var.get():
            mode = 1
        elif self.qh_single_var.get():
            mode = 2
        write_ini("Hatch", "HatchMode", str(mode))
        write_ini("Hatch", "ClaimNameEnabled", str(int(self.cn_enable_var.get())))
        write_ini("Hatch", "NameSpayEnabled", str(int(self.ns_enable_var.get())))
        write_ini("Hatch", "CryoEnabled", str(int(self.cryo_var.get())))
        write_ini("Hatch", "DinoName", self.name_combo.get().strip())

    def _pin_toggle(self):
        from core.config import write_ini
        self.state.pin_auto_open = self.pin_var.get()
        write_ini("AutoPin", "Enabled", str(int(self.pin_var.get())))

    def _nf_toggle(self):
        from core.config import write_ini
        self.state.nf_enabled = self.nf_var.get()
        write_ini("NVIDIAFilter", "Enabled", str(int(self.nf_var.get())))

    def _imprint_toggle(self):
        """Toggle the Auto Imprint scanner on/off."""
        from modules.auto_imprint import imprint_toggle_armed

        # Sync inventory key from edit
        inv_key = self.imprint_inv_key_edit.get().strip()
        if inv_key:
            state.imprint_inventory_key = inv_key

        imprint_toggle_armed()

        # Update button text
        if getattr(state, "imprint_scanning", False):
            self.imprint_start_btn.configure(text="Stop")
            if state.main_gui:
                state.main_gui.hide()
        else:
            self.imprint_start_btn.configure(text="Start")

    def _imprint_show_help(self):
        from gui.dialogs import show_help_dialog
        show_help_dialog("Auto Imprint Help",
            "AUTO IMPRINT \u2014 HOW TO USE\n\n"
            "1) Set your Inventory key in the edit field\n"
            "2) Click Start to arm the scanner\n"
            "3) Look at the baby's imprint tooltip in-game\n"
            "4) Press R to read + process the food request\n"
            "   OR press Q to toggle auto-scan mode\n\n"
            "Auto-scan continuously reads the screen center\n"
            "for imprint food names, opens your inventory,\n"
            "searches for it, moves it to hotbar slot 0,\n"
            "then waits 1s before resuming.\n\n"
            "F1 = stop and return to AIO UI\n"
            "Q while armed = toggle auto-scan on/off\n"
            "R while armed = single manual read",
            self.parent)

    def _imprint_hide_toggled(self):
        from core.config import write_ini
        state.imprint_hide_overlay = self.imprint_hide_var.get()
        write_ini("Imprint", "HideOverlay", str(int(state.imprint_hide_overlay)))

    def _imprint_toggle_resize(self):
        from modules.auto_imprint import imprint_toggle_resize
        imprint_toggle_resize()

    def _uf_add(self):
        from util.list_manager import ListManager
        text = self.uf_combo.get().strip()
        if not text or text in state.uf_list:
            return
        state.uf_list.append(text)
        ListManager("UploadFilters", state.uf_list).save()
        self.uf_combo["values"] = state.uf_list
        self.uf_combo.set(text)

    def _uf_remove(self):
        from util.list_manager import ListManager
        text = self.uf_combo.get().strip()
        if not text or text not in state.uf_list:
            return
        state.uf_list.remove(text)
        ListManager("UploadFilters", state.uf_list).save()
        self.uf_combo["values"] = state.uf_list
        self.uf_combo.set(state.uf_list[0] if state.uf_list else "")
