
import tkinter as tk
from tkinter import ttk
from gui.theme import *
from core.state import state

# Standard button style matching craft tab: dark bg, red accent text
BTN_STYLE = dict(fg=FG_ACCENT, bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT)


def _update_label(label_name: str, text: str):
    """Update a Tab 1 status label from any thread. Safe to call from modules."""
    try:
        root = state.root
        js = getattr(state, "_tab_joinsim", None)
        if root is None or js is None:
            return
        setter = getattr(js, f"set_{label_name}", None)
        if setter:
            root.after(0, lambda: setter(text))
    except Exception:
        pass


def update_overcap_status(text: str):
    _update_label("overcap_status", text)


def update_ob_status(text: str):
    _update_label("ob_status", text)


def update_ob_down_status(text: str):
    _update_label("ob_down_status", text)


def update_f10_status(text: str):
    _update_label("f10_status", text)


def update_gmk_status(text: str):
    _update_label("gmk_status", text)


class TabJoinSim:
    """Builds all widgets for the JoinSim tab inside *parent_frame*."""

    def __init__(self, parent_frame: ttk.Frame, state):
        self.frame = parent_frame
        self.state = state
        self._build()

    # ------------------------------------------------------------------
    def _build(self):
        f = self.frame

        # --- Info banner ---
        self.info_text = tk.Label(
            f, text="\nRUN AT STANDARD GAMMA\nSTART ON MAIN MENU OR SERVER LIST",
            font=FONT_SMALL_BOLD, fg=FG_ACCENT, bg=BG_COLOR,
            relief="solid", bd=1, justify="center",
        )
        self.info_text.place(x=40, y=5, width=280, height=44)

        # --- Server row ---
        tk.Label(f, text="Server:", font=FONT_DEFAULT, fg=FG_COLOR, bg=BG_COLOR,
                 anchor="w").place(x=25, y=53, width=65, height=23)

        self.server_combo = ttk.Combobox(f, font=FONT_DEFAULT, width=18)
        self.server_combo.place(x=90, y=53, width=180, height=21)

        # Buttons — craft tab style (dark bg, red text)
        self.svr_add_btn = tk.Button(f, text="+", font=FONT_SMALL_BOLD, **BTN_STYLE,
                                      command=self._svr_add)
        self.svr_add_btn.place(x=274, y=53, width=22, height=21)

        self.svr_del_btn = tk.Button(f, text="-", font=FONT_SMALL_BOLD, **BTN_STYLE,
                                      command=self._svr_remove)
        self.svr_del_btn.place(x=298, y=53, width=22, height=21)

        self.svr_note_btn = tk.Button(f, text="Note", font=FONT_TINY, **BTN_STYLE,
                                      command=self._svr_edit_note)
        self.svr_note_btn.place(x=322, y=53, width=30, height=21)

        # --- Option checkboxes ---
        opt_checks = [
            ("Download Mod / Event", 78, "mods_enabled"),
            ("Use Join Last",        98, "use_last"),
            ("Enable Tooltips",      118, "toolbox_enabled"),
        ]
        self.mods_var = tk.BooleanVar(value=False)
        self.use_last_var = tk.BooleanVar(value=False)
        self.tooltips_var = tk.BooleanVar(value=True)
        _opt_vars = [self.mods_var, self.use_last_var, self.tooltips_var]

        for (label_text, y, attr), var in zip(opt_checks, _opt_vars):
            tk.Label(f, text=label_text, font=FONT_DEFAULT, fg=FG_COLOR,
                     bg=BG_COLOR, anchor="w").place(x=25, y=y, width=140, height=23)
            chk = tk.Checkbutton(f, variable=var,
                                  command=lambda a=attr, v=var: setattr(state, a, v.get()),
                                  **CB_OPTS_NOLABEL)
            chk.place(x=175, y=y + 1, width=40, height=20)

        self.mods_chk = None  # checkboxes built inline above
        self.use_last_chk = None
        self.tooltips_chk = None
        # Pre-check Enable Tooltips
        self.tooltips_var.set(True)

        # --- Sim A / Sim B checkboxes ---
        self.sim_a_var = tk.BooleanVar(value=True)
        self.sim_a_chk = tk.Checkbutton(f, text="Sim A", variable=self.sim_a_var,
                                        command=self._select_sim_a, **CB_OPTS)
        self.sim_a_chk.place(x=30, y=145, width=65, height=20)

        self.sim_b_var = tk.BooleanVar(value=False)
        self.sim_b_chk = tk.Checkbutton(f, text="Sim B", variable=self.sim_b_var,
                                        command=self._select_sim_b, **CB_OPTS)
        self.sim_b_chk.place(x=30, y=165, width=65, height=20)

        # --- Start button ---
        self.start_btn = tk.Button(f, text="Start", font=FONT_BOLD, **BTN_STYLE,
                                   command=self._toggle_sim)
        self.start_btn.place(x=130, y=147, width=90, height=28)

        # --- Status text ---
        self.sim_status = tk.Label(f, text="", font=FONT_SMALL, fg=FG_GREEN,
                                   bg=BG_COLOR, anchor="center")
        self.sim_status.place(x=25, y=190, width=300, height=14)

        # --- Ntfy row ---
        tk.Label(f, text="Ntfy Key:", font=FONT_DEFAULT, fg=FG_COLOR, bg=BG_COLOR,
                 anchor="w").place(x=25, y=207, width=60, height=23)

        self.ntfy_edit = tk.Entry(f, font=FONT_DEFAULT)
        self.ntfy_edit.place(x=90, y=207, width=100, height=20)

        # Ntfy buttons — craft tab style
        self.ntfy_save_btn = tk.Button(f, text="Save", font=FONT_SMALL, **BTN_STYLE,
                                       command=self._ntfy_save)
        self.ntfy_save_btn.place(x=195, y=207, width=42, height=20)

        self.ntfy_test_btn = tk.Button(f, text="Test", font=FONT_SMALL, **BTN_STYLE,
                                       command=self._ntfy_test)
        self.ntfy_test_btn.place(x=241, y=207, width=42, height=20)

        self.ntfy_help_btn = tk.Button(f, text="?", font=FONT_SMALL_BOLD, **BTN_STYLE,
                                       command=self._show_ntfy_help)
        self.ntfy_help_btn.place(x=287, y=207, width=22, height=20)

        # --- F-key hint labels (16px spacing, 16px height for descenders) ---
        hint_font = (FONT_FAMILY, 9, "italic")
        hints = [
            (230, " F1 \u2014 Show / Hide UI"),
            (246, " F2 \u2014 Overcap"),
            (262, " F3 \u2014 Quick Feed  (Raw \u2192 Berry \u2192 Off)"),
            (278, " F5 \u2014 Apply INI  (paste custom in Misc)"),
            (294, " F6 \u2014 Fill OB  (F to upload)"),
            (310, " F7 \u2014 Empty OB  (F7 at trans)"),
            (326, " F8 \u2014 BG Mammoth Drums"),
            (342, " F9 \u2014 BG Autoclick"),
            (358, " F10 \u2014 Quick Popcorn"),
            (374, " F12 \u2014 Grab My Kit"),
        ]
        for y, text in hints:
            tk.Label(f, text=text, font=hint_font, fg=FG_DIM, bg=BG_COLOR,
                     anchor="w").place(x=25, y=y, width=300, height=16)

        # --- Overcap dedi edit + countdown (on F2 line) ---
        self.overcap_dedi_edit = tk.Entry(f, font=FONT_TINY, justify="center")
        self.overcap_dedi_edit.insert(0, "3")
        self.overcap_dedi_edit.place(x=135, y=246, width=18, height=16)
        self.overcap_dedi_edit.bind("<KeyRelease>", self._overcap_dedi_edit_changed)

        self.overcap_countdown = tk.Label(f, text="", font=FONT_SMALL, fg=FG_GREEN,
                                          bg=BG_COLOR, anchor="w")
        self.overcap_countdown.place(x=157, y=248, width=170, height=14)

        # --- OB status text (on F6 line) ---
        self.ob_status_text = tk.Label(f, text="", font=FONT_SMALL, fg=FG_GREEN,
                                       bg=BG_COLOR, anchor="w")
        self.ob_status_text.place(x=190, y=294, height=16)

        # --- OB download text (on F7 line) ---
        self.ob_down_text = tk.Label(f, text="", font=FONT_SMALL, fg=FG_GREEN,
                                     bg=BG_COLOR, anchor="w")
        self.ob_down_text.place(x=190, y=310, height=16)

        # --- F10 Quick Popcorn status ---
        self.pc_f10_status = tk.Label(f, text="", font=FONT_SMALL, fg=FG_GREEN,
                                      bg=BG_COLOR, anchor="w")
        self.pc_f10_status.place(x=150, y=358, width=60, height=16)

        # --- F12 Grab My Kit status ---
        self.gmk_status = tk.Label(f, text="", font=FONT_SMALL, fg=FG_GREEN,
                                   bg=BG_COLOR, anchor="w")
        self.gmk_status.place(x=150, y=374, width=60, height=16)

        # --- Art: Delta Spiral (upper-right) + GG Relief (bottom-right) ---
        self._art_refs = []  # prevent garbage collection of PhotoImages
        try:
            from PIL import ImageTk
            from gui.art import render_delta_spiral, render_gg_art

            # Delta spiral — upper-right, clipped at GUI edge
            delta_img = render_delta_spiral()
            delta_photo = ImageTk.PhotoImage(delta_img)
            delta_label = tk.Label(f, image=delta_photo, borderwidth=0, bg=BG_COLOR)
            delta_label.place(x=275, y=75)
            delta_label.lower()  # behind all other widgets
            self._art_refs.append(delta_photo)

            # GG relief text — bottom-right
            gg_img = render_gg_art()
            gg_photo = ImageTk.PhotoImage(gg_img)
            gg_label = tk.Label(f, image=gg_photo, borderwidth=0, bg=BG_COLOR)
            gg_label.place(x=240, y=260)
            self._art_refs.append(gg_photo)

            # Lift status labels above the GG art so they aren't covered
            self.ob_status_text.lift()
            self.ob_down_text.lift()
            self.pc_f10_status.lift()
            self.gmk_status.lift()
        except ImportError:
            pass  # Pillow not available — skip art

    # ------------------------------------------------------------------
    def _select_sim_a(self):
        self.sim_a_chk.select()
        self.sim_b_chk.deselect()
        state.sim_mode = 1

    def _select_sim_b(self):
        self.sim_a_chk.deselect()
        self.sim_b_chk.select()
        state.sim_mode = 2

    def _toggle_sim(self):
        """Start/Stop the sim loop."""
        # Sync checkbox state into state before toggling
        state.mods_enabled = self.mods_var.get()
        state.use_last = self.use_last_var.get()
        state.toolbox_enabled = self.tooltips_var.get()

        # Read server from combo (parse number from "2386 - main" format)
        svr = self._svr_parse_number(self.server_combo.get())
        if svr:
            state.server_number = svr

        from modules.join_sim import auto_sim_button_toggle
        auto_sim_button_toggle()

        # Update button text
        if getattr(state, "auto_sim_check", False):
            self.start_btn.configure(text="Stop")
        else:
            self.start_btn.configure(text="Start")
            self.sim_status.configure(text="")

    def _overcap_dedi_edit_changed(self, event=None):
        """Update the countdown preview when the dedi count changes.

        Updates the countdown preview when the dedi count changes.
        """
        try:
            val = int(self.overcap_dedi_edit.get().strip())
        except (ValueError, TypeError):
            if not state.run_overcap_script:
                self.overcap_countdown.configure(text="")
            return
        if val <= 0:
            if not state.run_overcap_script:
                self.overcap_countdown.configure(text="")
            return
        from modules.overcap import overcap_dedi_ms
        target_sec = overcap_dedi_ms(val) // 1000
        self.overcap_countdown.configure(text=f"~{target_sec}s for {val} dedi")

    def _ntfy_save(self):
        """Save the NTFY key to INI and update state."""
        from core.config import write_ini
        key = self.ntfy_edit.get().strip()
        if not key:
            return
        state.ntfy_key = key
        write_ini("ntfy", "key", key)
        # Brief green flash to confirm save — keep text visible
        self.ntfy_save_btn.configure(text="Saved!", fg=FG_GREEN)
        self.frame.after(1500, lambda: self.ntfy_save_btn.configure(text="Save", **BTN_STYLE))

    def _ntfy_test(self):
        """Send a test NTFY notification."""
        from util.ntfy import ntfy_push
        ntfy_push("low", "Test Button", key=state.ntfy_key)

    # --- Status label update API (called from modules) ---
    def set_overcap_status(self, text: str):
        self.overcap_countdown.configure(text=text)

    def set_ob_status(self, text: str):
        self.ob_status_text.configure(text=text)

    def set_ob_down_status(self, text: str):
        self.ob_down_text.configure(text=text)

    def set_f10_status(self, text: str):
        self.pc_f10_status.configure(text=text)

    def set_gmk_status(self, text: str):
        self.gmk_status.configure(text=text)

    def _show_ntfy_help(self):
        from gui.dialogs import show_help_dialog
        show_help_dialog("NTFY Setup",
            "NTFY can send a notif to your phone when you get in serv\n\n"
            "Install NTFY \u2014 search NTFY in your phone's app store\n\n"
            "Open NTFY and tap \"+\" then type your own unique topic\n"
            "name  e.g. \"StubzyGG\"\n\n"
            "Type that same topic name into the NTFY key field in sim menu\n\n"
            "Click Test to ensure they match and notifs are working\n\n"
            "Save and start sim",
            self.frame)

    def _svr_display_values(self) -> list[str]:
        """Build combo display values like '2386 - main' when note exists."""
        result = []
        for svr in state.svr_list:
            note = state.svr_notes.get(svr, "")
            result.append(f"{svr} - {note}" if note else svr)
        return result

    def _svr_display_for(self, svr: str) -> str:
        """Return display string for a single server number."""
        note = state.svr_notes.get(svr, "")
        return f"{svr} - {note}" if note else svr

    @staticmethod
    def _svr_parse_number(display: str) -> str:
        """Extract the server number from a display string like '2386 - main'."""
        return display.split(" - ", 1)[0].strip()

    def refresh_server_combo(self):
        """Rebuild the combo dropdown with notes. Call after any svr_list/notes change."""
        self.server_combo["values"] = self._svr_display_values()

    def _save_server_notes(self):
        """Re-persist notes after list_save wipes the [Servers] section."""
        from core.config import write_ini
        for i, svr in enumerate(state.svr_list, start=1):
            write_ini("Servers", f"Note{i}", state.svr_notes.get(svr, ""))

    def _svr_add(self):
        from util.list_manager import ListManager
        raw = self._svr_parse_number(self.server_combo.get())
        if not raw or raw in state.svr_list:
            return
        state.svr_list.append(raw)
        ListManager("Servers", state.svr_list).save()
        self._save_server_notes()
        self.refresh_server_combo()
        self.server_combo.set(self._svr_display_for(raw))

    def _svr_remove(self):
        from util.list_manager import ListManager
        raw = self._svr_parse_number(self.server_combo.get())
        if not raw or raw not in state.svr_list:
            return
        state.svr_list.remove(raw)
        state.svr_notes.pop(raw, None)
        ListManager("Servers", state.svr_list).save()
        self._save_server_notes()
        self.refresh_server_combo()
        if state.svr_list:
            self.server_combo.set(self._svr_display_for(state.svr_list[0]))
        else:
            self.server_combo.set("")

    def _svr_edit_note(self):
        """Open a dialog to edit the note for the currently selected server.

        Opens a note editor for the selected server.
        """
        from gui.theme import BG_DARK, FG_COLOR, FG_ACCENT, FG_WHITE, FONT_DEFAULT, FONT_BOLD
        from gui.tooltip import show_tooltip, hide_tooltip
        from core.config import write_ini

        num = self._svr_parse_number(self.server_combo.get())
        if not num:
            return

        # Server must exist in list
        if num not in state.svr_list:
            show_tooltip(" Add server first with +", 0, 0)
            if state.root:
                state.root.after(1500, hide_tooltip)
            return

        # Destroy existing note dialog if open (toggle behaviour)
        if state.svr_note_gui is not None:
            try:
                state.svr_note_gui.destroy()
            except Exception:
                pass
            state.svr_note_gui = None
            return

        dlg = tk.Toplevel(self.frame)
        dlg.title("Server Note")
        dlg.configure(bg=BG_DARK)
        dlg.attributes("-topmost", True)
        dlg.resizable(False, False)
        state.svr_note_gui = dlg

        tk.Label(dlg, text=f"Note for server {num}", bg=BG_DARK, fg=FG_ACCENT,
                 font=FONT_BOLD).place(x=20, y=15, width=230)

        note_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        note_edit.insert(0, state.svr_notes.get(num, ""))
        note_edit.place(x=20, y=40, width=230, height=24)
        note_edit.focus_set()

        def _save():
            state.svr_notes[num] = note_edit.get().strip()
            # Persist notes to INI
            for i, svr in enumerate(state.svr_list, start=1):
                write_ini("Servers", f"Note{i}", state.svr_notes.get(svr, ""))
            # Refresh combo to show updated notes
            self.refresh_server_combo()
            self.server_combo.set(self._svr_display_for(num))
            try:
                dlg.destroy()
            except Exception:
                pass
            state.svr_note_gui = None

        def _cancel():
            try:
                dlg.destroy()
            except Exception:
                pass
            state.svr_note_gui = None

        save_btn = tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_WHITE,
                             bg="#334433", relief=tk.FLAT, padx=10, command=_save)
        save_btn.place(x=70, y=72, width=80, height=26)

        cancel_btn = tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_WHITE,
                               bg="#443333", relief=tk.FLAT, padx=10, command=_cancel)
        cancel_btn.place(x=155, y=72, width=80, height=26)

        dlg.protocol("WM_DELETE_WINDOW", _cancel)
        dlg.geometry("270x110")
