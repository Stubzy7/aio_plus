
import tkinter as tk
from tkinter import ttk
from gui.theme import *
from core.scaling import screen_width, screen_height


class TabSheep:
    """Builds the Sheep tab UI inside the given parent frame."""

    def __init__(self, parent_frame: ttk.Frame, state):
        self.parent = parent_frame
        self.state = state

        # --- Info banner ---
        self.info_text = tk.Label(
            parent_frame,
            text=f"\nSet keybinds \u2014 defaults are ready to use\nRes: {screen_width}x{screen_height}",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_SMALL_BOLD,
            justify="center", relief="solid", borderwidth=1,
        )
        self.info_text.place(x=80, y=0, width=270, height=50)

        # --- Keybind rows ---
        label_x = 22
        edit_x = 175
        btn_x = 295
        row_y = 70

        # Row 1: Start / Pause (Toggle Key)
        self.lbl_toggle = tk.Label(
            parent_frame, text="Start / Pause:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_DEFAULT,
        )
        self.lbl_toggle.place(x=label_x, y=row_y, width=145, height=24)

        self.toggle_edit = tk.Entry(
            parent_frame, justify="center", font=FONT_DEFAULT,
        )
        self.toggle_edit.insert(0, getattr(state, "sheep_toggle_key", "F6"))
        self.toggle_edit.place(x=edit_x, y=row_y - 2, width=100, height=24)

        self.toggle_detect_btn = tk.Button(
            parent_frame, text="Set", font=FONT_SMALL, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._detect_key(self.toggle_edit),
        )
        self.toggle_detect_btn.place(x=btn_x, y=row_y - 2, width=60, height=24)

        # Row 2: Overcap toggle
        row_y += 30
        self.lbl_overcap = tk.Label(
            parent_frame, text="Overcap toggle:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_DEFAULT,
        )
        self.lbl_overcap.place(x=label_x, y=row_y, width=145, height=24)

        self.overcap_edit = tk.Entry(
            parent_frame, justify="center", font=FONT_DEFAULT,
        )
        self.overcap_edit.insert(0, getattr(state, "sheep_overcap_key", "F7"))
        self.overcap_edit.place(x=edit_x, y=row_y - 2, width=100, height=24)

        self.overcap_detect_btn = tk.Button(
            parent_frame, text="Set", font=FONT_SMALL, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._detect_key(self.overcap_edit),
        )
        self.overcap_detect_btn.place(x=btn_x, y=row_y - 2, width=60, height=24)

        # Row 3: Inventory key
        row_y += 30
        self.lbl_inventory = tk.Label(
            parent_frame, text="Inventory key:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_DEFAULT,
        )
        self.lbl_inventory.place(x=label_x, y=row_y, width=145, height=24)

        self.inventory_edit = tk.Entry(
            parent_frame, justify="center", font=FONT_DEFAULT,
        )
        self.inventory_edit.insert(0, getattr(state, "sheep_inventory_key", "i"))
        self.inventory_edit.place(x=edit_x, y=row_y - 2, width=100, height=24)

        self.inventory_detect_btn = tk.Button(
            parent_frame, text="Set", font=FONT_SMALL, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._detect_key(self.inventory_edit),
        )
        self.inventory_detect_btn.place(x=btn_x, y=row_y - 2, width=60, height=24)

        # Row 4: Auto LvL toggle
        row_y += 30
        self.lbl_autolvl = tk.Label(
            parent_frame, text="Auto LvL toggle:", anchor="w",
            bg=BG_COLOR, fg=FG_COLOR, font=FONT_DEFAULT,
        )
        self.lbl_autolvl.place(x=label_x, y=row_y, width=145, height=24)

        self.autolvl_edit = tk.Entry(
            parent_frame, justify="center", font=FONT_DEFAULT,
        )
        self.autolvl_edit.insert(0, getattr(state, "sheep_auto_lvl_key", "F8"))
        self.autolvl_edit.place(x=edit_x, y=row_y - 2, width=100, height=24)

        self.autolvl_detect_btn = tk.Button(
            parent_frame, text="Set", font=FONT_SMALL, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=lambda: self._detect_key(self.autolvl_edit),
        )
        self.autolvl_detect_btn.place(x=btn_x, y=row_y - 2, width=60, height=24)

        # --- Hint text ---
        self.hint_label = tk.Label(
            parent_frame, text="Click 'Set' then press a key to bind",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC,
        )
        self.hint_label.place(x=label_x, y=row_y + 30, width=340)

        # --- Save Settings button ---
        self.save_btn = tk.Button(
            parent_frame, text="Save Settings",
            font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._apply_keys,
        )
        self.save_btn.place(x=100, y=row_y + 50, width=220, height=28)

        # --- Bottom hints ---
        self.stack_hint = tk.Label(
            parent_frame, text="Stack sheep to harvest more than one at a time",
            bg=BG_COLOR, fg=FG_ACCENT, font=FONT_SMALL, justify="center",
        )
        self.stack_hint.place(x=label_x, y=row_y + 86, width=340)

        self.start_hint = tk.Label(
            parent_frame, text="Look at sheep, press Start/Pause key to begin...",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC, justify="center",
        )
        self.start_hint.place(x=label_x, y=row_y + 102, width=340)

    # ------------------------------------------------------------------
    def _detect_key(self, entry_widget: tk.Entry):
        """Bind next key press to fill the given entry widget."""
        toplevel = self.parent.winfo_toplevel()
        original_text = entry_widget.get()
        entry_widget.delete(0, tk.END)
        entry_widget.insert(0, "Press a key...")

        def on_key(event):
            entry_widget.delete(0, tk.END)
            key_name = event.keysym
            entry_widget.insert(0, key_name)
            toplevel.unbind("<Key>", bind_id)

        bind_id = toplevel.bind("<Key>", on_key)

    def _apply_keys(self):
        """Save the current keybind values into state, re-register hotkeys, persist to INI."""
        from modules.sheep import sheep_unregister_hotkeys, sheep_register_hotkeys
        from core.config import write_ini

        hk = getattr(self.state, "_hotkey_mgr", None)

        # Unregister old hotkeys
        if hk:
            sheep_unregister_hotkeys(hk)

        # Update state
        self.state.sheep_toggle_key = self.toggle_edit.get().strip().lower()
        self.state.sheep_overcap_key = self.overcap_edit.get().strip().lower()
        self.state.sheep_inventory_key = self.inventory_edit.get().strip().lower()
        self.state.sheep_auto_lvl_key = self.autolvl_edit.get().strip().lower()

        # Re-register with new keys
        if hk:
            sheep_register_hotkeys(hk)

        # Persist to INI
        write_ini("Sheep", "ToggleKey", self.state.sheep_toggle_key)
        write_ini("Sheep", "OvercapKey", self.state.sheep_overcap_key)
        write_ini("Sheep", "InventoryKey", self.state.sheep_inventory_key)
        write_ini("Sheep", "AutoLvlKey", self.state.sheep_auto_lvl_key)

        # Feedback tooltip
        try:
            from gui.tooltip import show_tooltip
            show_tooltip(
                f" Sheep keys saved!\n"
                f" Toggle: {self.state.sheep_toggle_key}\n"
                f" Overcap: {self.state.sheep_overcap_key}\n"
                f" Inventory: {self.state.sheep_inventory_key}\n"
                f" Auto LvL: {self.state.sheep_auto_lvl_key}"
            )
        except Exception:
            pass
