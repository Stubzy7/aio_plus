
import tkinter as tk
from tkinter import ttk, messagebox
from gui.theme import *
from core.state import state


def _build_guided_events(action: str, count: int, drop_key: str = "g") -> list[dict]:
    start_x = int(state.pc_start_slot_x)
    start_y = int(state.pc_start_slot_y)
    slot_w = int(state.pc_slot_w)
    slot_h = int(state.pc_slot_h)
    cols = int(state.pc_columns)
    grid_size = cols * 6

    events = []
    if count <= 0:
        return events
    remaining = count
    while remaining > 0:
        slot = 0
        for row in range(6):
            for col in range(cols):
                slot += 1
                if slot > remaining or slot > grid_size:
                    break
                x = start_x + col * slot_w
                y = start_y + row * slot_h
                events.append({"type": "M", "x": x, "y": y, "delay": 0})
                if action == "take":
                    events.append({"type": "C", "dir": "c", "btn": "L",
                                   "x": x, "y": y, "delay": 100})
                    events.append({"type": "K", "dir": "p", "key": "t", "delay": 60})
                else:
                    events.append({"type": "K", "dir": "p", "key": drop_key, "delay": 20})
            if slot > remaining or slot > grid_size:
                break
        remaining -= min(slot, grid_size)
    return events


class TabMacro:

    def __init__(self, parent_frame: ttk.Frame, state: dict):
        self.parent = parent_frame
        self.state = state

        self.guided_btn = tk.Button(
            parent_frame, text="+ Guided", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._guided_start,
        )
        self.guided_btn.place(x=12, y=3, width=105, height=26)

        self.repeat_btn = tk.Button(
            parent_frame, text="+ Key Repeat", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._repeat_new,
        )
        self.repeat_btn.place(x=121, y=3, width=105, height=26)

        self.combo_btn = tk.Button(
            parent_frame, text="+ Popcorn+Magic-F", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._combo_start,
        )
        self.combo_btn.place(x=230, y=3, width=180, height=26)

        self.help_btn = tk.Button(
            parent_frame, text="?", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._show_help,
        )
        self.help_btn.place(x=416, y=3, width=26, height=26)

        tree_style = ttk.Style()
        tree_style.configure(
            "Macro.Treeview",
            background=BG_DARK, foreground=FG_COLOR, fieldbackground=BG_DARK,
            font=FONT_SMALL, rowheight=22,
        )
        tree_style.configure(
            "Macro.Treeview.Heading",
            background=BG_DARK, foreground=FG_COLOR, font=FONT_SMALL,
        )
        tree_style.map(
            "Macro.Treeview",
            background=[("selected", "#333333")],
            foreground=[("selected", FG_COLOR)],
        )

        self.tree = ttk.Treeview(
            parent_frame, style="Macro.Treeview",
            columns=("name", "type", "key", "speed"),
            show="headings", selectmode="browse",
        )
        self.tree.heading("name", text="Name")
        self.tree.heading("type", text="Type")
        self.tree.heading("key", text="Key")
        self.tree.heading("speed", text="Speed")
        self.tree.column("name", width=130)
        self.tree.column("type", width=65)
        self.tree.column("key", width=40)
        self.tree.column("speed", width=155)
        self.tree.place(x=12, y=35, width=425, height=180)

        btn_y = 221

        self.play_btn = tk.Button(
            parent_frame, text="Start", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._play_selected,
        )
        self.play_btn.place(x=12, y=btn_y, width=65, height=26)

        self.tune_btn = tk.Button(
            parent_frame, text="Tune", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._tune_selected,
        )
        self.tune_btn.place(x=81, y=btn_y, width=55, height=26)

        self.edit_btn = tk.Button(
            parent_frame, text="Edit", font=FONT_DEFAULT, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._edit_selected,
        )
        self.edit_btn.place(x=140, y=btn_y, width=55, height=26)

        self.delete_btn = tk.Button(
            parent_frame, text="Delete", font=FONT_DEFAULT, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._delete_selected,
        )
        self.delete_btn.place(x=199, y=btn_y, width=60, height=26)

        self.move_up_btn = tk.Button(
            parent_frame, text="\u25B2", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._move_up,
        )
        self.move_up_btn.place(x=380, y=btn_y, width=26, height=26)

        self.move_down_btn = tk.Button(
            parent_frame, text="\u25BC", font=FONT_BOLD, fg=FG_ACCENT,
            bg=BG_DARK, activebackground=BG_DARK, activeforeground=FG_ACCENT,
            command=self._move_down,
        )
        self.move_down_btn.place(x=410, y=btn_y, width=26, height=26)

        self.status_line1 = tk.Label(
            parent_frame,
            text="F3/Start to arm  |  F at inventory  |  Q: single/swap  |  Z: next/exit",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC, justify="center",
        )
        self.status_line1.place(x=12, y=253, width=425, height=14)

        self.status_line2 = tk.Label(
            parent_frame,
            text="F1 = Stop / UI  |  Only \u25BA macro hotkey is live  |  ? for full help",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC, justify="center",
        )
        self.status_line2.place(x=12, y=269, width=425, height=14)

    def populate(self, macros: list[dict]):
        self.tree.delete(*self.tree.get_children())
        for m in macros:
            self.tree.insert(
                "", "end",
                values=(
                    m.get("name", ""),
                    m.get("type", ""),
                    m.get("key", ""),
                    m.get("speed", ""),
                ),
            )
        children = self.tree.get_children()
        if children:
            idx = getattr(state, "macro_selected_idx", 1) - 1
            idx = max(0, min(idx, len(children) - 1))
            self.tree.selection_set(children[idx])
            self.tree.see(children[idx])

    def get_selected_index(self) -> int | None:
        sel = self.tree.selection()
        if not sel:
            return None
        return self.tree.index(sel[0])

    def _make_dlg(self, title: str, w: int = 280, h: int = 250) -> tk.Toplevel:
        dlg = tk.Toplevel(self.parent)
        dlg.title(title)
        dlg.configure(bg=BG_DARK)
        dlg.attributes("-topmost", True)
        dlg.resizable(False, False)
        sx = dlg.winfo_screenwidth()
        px = 177 + 450 + 10
        py = 330
        if px + w > sx:
            px = max(0, 177 - w - 10)
        dlg.geometry(f"{w}x{h}+{px}+{py}")
        return dlg

    _bind_excluded = {"shift_l", "shift_r", "control_l", "control_r",
                       "alt_l", "alt_r", "escape", "caps_lock", "tab",
                       "super_l", "super_r", "f1", "f2", "f3"}

    def _detect_key_into(self, dlg: tk.Toplevel, entry: tk.Entry):
        entry.delete(0, tk.END)
        entry.insert(0, "Press key/click...")
        bind_ids = []

        def _cleanup():
            for ev, bid in bind_ids:
                try:
                    dlg.unbind(ev, bid)
                except Exception:
                    pass

        def on_key(event):
            k = event.keysym.lower()
            if k in self._bind_excluded:
                return
            entry.delete(0, tk.END)
            entry.insert(0, k)
            _cleanup()

        def on_mouse(event):
            btn_map = {1: "lbutton", 2: "mbutton", 3: "rbutton"}
            name = btn_map.get(event.num, f"mouse{event.num}")
            entry.delete(0, tk.END)
            entry.insert(0, name)
            _cleanup()

        bind_ids.append(("<Key>", dlg.bind("<Key>", on_key)))
        bind_ids.append(("<Button-1>", dlg.bind("<Button-1>", on_mouse)))
        bind_ids.append(("<Button-2>", dlg.bind("<Button-2>", on_mouse)))
        bind_ids.append(("<Button-3>", dlg.bind("<Button-3>", on_mouse)))

    def _repeat_new(self):
        dlg = self._make_dlg("Key Repeat", 350, 416)
        key_list: list[str] = []
        pad_x = 16
        y = 16

        tk.Label(dlg, text="Key Repeat", bg=BG_DARK, fg=FG_ACCENT,
                 font=FONT_BOLD).place(x=pad_x, y=y)
        y += 30

        tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        name_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        name_edit.place(x=130, y=y, width=190, height=24)
        y += 30

        tk.Label(dlg, text="Keys:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        key_display = tk.Entry(dlg, font=FONT_DEFAULT, state="readonly")
        key_display.place(x=130, y=y, width=120, height=24)

        _excluded_keys = {"shift_l", "shift_r", "control_l", "control_r",
                          "alt_l", "alt_r", "escape", "caps_lock", "tab",
                          "super_l", "super_r", "f1", "f2", "f3"}

        def _finish_detect(k):
            if k not in key_list:
                key_list.append(k)
            key_display.configure(state="normal")
            key_display.delete(0, tk.END)
            key_display.insert(0, ", ".join(key_list))
            key_display.configure(state="readonly")

        def _add_key():
            key_display.configure(state="normal")
            key_display.delete(0, tk.END)
            key_display.insert(0, "Press key/click...")
            key_display.configure(state="readonly")
            def on_key(event):
                k = event.keysym.lower()
                if k in _excluded_keys:
                    return
                dlg.unbind("<Key>", kid)
                dlg.unbind("<Button-1>", b1id)
                dlg.unbind("<Button-2>", b2id)
                dlg.unbind("<Button-3>", b3id)
                _finish_detect(k)
            def on_mouse(btn_name):
                def handler(event):
                    dlg.unbind("<Key>", kid)
                    dlg.unbind("<Button-1>", b1id)
                    dlg.unbind("<Button-2>", b2id)
                    dlg.unbind("<Button-3>", b3id)
                    _finish_detect(btn_name)
                    return "break"
                return handler
            kid = dlg.bind("<Key>", on_key)
            b1id = dlg.bind("<Button-1>", on_mouse("lbutton"))
            b2id = dlg.bind("<Button-2>", on_mouse("mbutton"))
            b3id = dlg.bind("<Button-3>", on_mouse("rbutton"))

        def _clear_keys():
            key_list.clear()
            key_display.configure(state="normal")
            key_display.delete(0, tk.END)
            key_display.configure(state="readonly")

        tk.Button(dlg, text="Add", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=_add_key).place(x=260, y=y, width=35, height=24)
        tk.Button(dlg, text="X", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=_clear_keys).place(x=298, y=y, width=22, height=24)
        y += 24
        tk.Label(dlg, text="Q cycles between keys during play", bg=BG_DARK,
                 fg=FG_DIM, font=FONT_SMALL_ITALIC).place(x=130, y=y)
        y += 22

        tk.Label(dlg, text="Interval (ms):", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        interval_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        interval_edit.insert(0, "600")
        interval_edit.place(x=130, y=y, width=65, height=24)
        tk.Label(dlg, text="(0 = hold)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=200, y=y + 2)
        y += 30

        tk.Label(dlg, text="Bind:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        bind_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        bind_edit.place(x=130, y=y, width=80, height=24)
        tk.Button(dlg, text="Detect", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=lambda: self._detect_key_into(dlg, bind_edit)
                  ).place(x=215, y=y, width=60, height=24)
        y += 34

        tk.Frame(dlg, bg="#333333", height=1).place(x=pad_x, y=y, width=318)
        y += 8

        pc_var = tk.BooleanVar(value=False)
        pc_check = tk.Checkbutton(dlg, text="Popcorn after repeat",
                                  variable=pc_var, bg=BG_DARK, fg=FG_COLOR,
                                  selectcolor=BG_DARK, activebackground=BG_DARK,
                                  activeforeground=FG_COLOR, font=FONT_DEFAULT,
                                  anchor="w")
        pc_check.place(x=pad_x, y=y)
        y += 26

        pc_frame = tk.Frame(dlg, bg=BG_DARK)
        tk.Label(pc_frame, text="Drop count:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=0)
        pc_drop_var = tk.StringVar(value="0")
        tk.Entry(pc_frame, textvariable=pc_drop_var, width=6,
                 font=FONT_DEFAULT).place(x=114, y=0)
        tk.Label(pc_frame, text="(0 = all)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=170, y=2)

        tk.Label(pc_frame, text="Drop key:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=28)
        dk = getattr(state, "pc_drop_key", "") or "?"
        pc_drop_key_lbl = tk.Label(pc_frame, text=dk.upper(),
                                   bg=BG_DARK, fg=FG_ACCENT, font=FONT_BOLD,
                                   anchor="w")
        pc_drop_key_lbl.place(x=114, y=28)
        pc_frame_y = y

        save_btn = tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT,
                             bg=BG_COLOR)
        cancel_btn = tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                               bg=BG_COLOR, command=dlg.destroy)

        def _toggle_pc(*_):
            if pc_var.get():
                pc_drop_key_lbl.configure(
                    text=(getattr(state, "pc_drop_key", "") or "?").upper())
                pc_frame.place(x=pad_x + 16, y=pc_frame_y,
                               width=302, height=60)
                btn_y = pc_frame_y + 66
            else:
                pc_frame.place_forget()
                btn_y = pc_frame_y + 4
            save_btn.place(x=pad_x, y=btn_y, width=100, height=26)
            cancel_btn.place(x=200, y=btn_y, width=100, height=26)
            dlg.geometry(f"350x{btn_y + 42}")

        def _save():
            n = name_edit.get().strip()
            if not n or not key_list:
                return
            interval = int(interval_edit.get() or 600)
            m = {
                "name": n,
                "type": "repeat",
                "hotkey": bind_edit.get().strip().lower(),
                "repeat_keys": list(key_list),
                "repeat_interval": interval,
                "repeat_spam": int(interval == 0),
                "popcorn_filters": [],
                "popcorn_style": "all",
                "popcorn_drop_count": 0,
            }
            if pc_var.get():
                dc = int(pc_drop_var.get() or 0)
                m["popcorn_filters"] = [""]
                m["popcorn_style"] = "all" if dc == 0 else "amount"
                m["popcorn_drop_count"] = dc
            state.macro_list.append(m)
            from modules.macro_system import macro_save_all
            macro_save_all()
            self._refresh_list()
            dlg.destroy()

        save_btn.configure(command=_save)
        pc_var.trace_add("write", _toggle_pc)
        _toggle_pc()

    def _repeat_popcorn_wizard(self, m: dict):
        """Popcorn attachment wizard for repeat macros.
        Step 1: Add Popcorn? (Yes / Skip)
        Step 2: Style (Drop All / Drop Amount)
        Step 3: Filter count
        Step 4: Filter names (if count > 0)
        Step 5: Drop count (if style = amount)
        Then finalize save.
        """
        pc_data: dict = {}

        def _finalize():
            m["popcorn_filters"] = pc_data.get("popcorn_filters", [])
            m["popcorn_style"] = pc_data.get("popcorn_style", "all")
            m["popcorn_drop_count"] = pc_data.get("popcorn_drop_count", 0)
            state.macro_list.append(m)
            from modules.macro_system import macro_save_all
            macro_save_all()
            self._refresh_list()

        def _step_ask():
            dlg = self._make_dlg("Key Repeat \u2014 Popcorn", 280, 130)
            tk.Label(dlg, text="Add Popcorn?", bg=BG_DARK, fg=FG_ACCENT,
                     font=FONT_BOLD).place(x=15, y=10, width=250)
            tk.Label(dlg, text="F during repeat will open inventory & popcorn",
                     bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                     ).place(x=15, y=35, width=250)

            def _yes():
                dlg.destroy()
                _step_style()

            def _skip():
                dlg.destroy()
                _finalize()

            tk.Button(dlg, text="Yes", font=FONT_BOLD, fg=FG_ACCENT,
                      bg=BG_COLOR, command=_yes).place(x=15, y=75, width=100, height=26)
            tk.Button(dlg, text="Skip", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=_skip).place(x=120, y=75, width=100, height=26)

        def _step_style():
            dlg = self._make_dlg("Key Repeat \u2014 Popcorn Style", 300, 140)
            tk.Label(dlg, text="Popcorn Style", bg=BG_DARK, fg=FG_ACCENT,
                     font=FONT_BOLD).place(x=15, y=10, width=270)
            tk.Label(dlg, text="Drop All = empty inventory. Drop Amount = set number.",
                     bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                     ).place(x=15, y=35, width=270)

            def _all():
                pc_data["popcorn_style"] = "all"
                dlg.destroy()
                _step_filter_count()

            def _amount():
                pc_data["popcorn_style"] = "amount"
                dlg.destroy()
                _step_filter_count()

            tk.Button(dlg, text="Drop All", font=FONT_BOLD, fg=FG_ACCENT,
                      bg=BG_COLOR, command=_all).place(x=15, y=85, width=120, height=26)
            tk.Button(dlg, text="Drop Amount", font=FONT_BOLD, fg=FG_ACCENT,
                      bg=BG_COLOR, command=_amount).place(x=145, y=85, width=120, height=26)

        def _step_filter_count():
            dlg = self._make_dlg("Key Repeat \u2014 Popcorn Filters", 320, 150)
            tk.Label(dlg, text="Popcorn Filters", bg=BG_DARK, fg=FG_ACCENT,
                     font=FONT_BOLD).place(x=15, y=10, width=280)
            tk.Label(dlg, text="How many search filters? (0 = no filter, drop all items)",
                     bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                     ).place(x=15, y=35, width=280)
            tk.Label(dlg, text="Count:", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_DEFAULT).place(x=15, y=70, width=55)
            count_edit = tk.Entry(dlg, font=FONT_DEFAULT)
            count_edit.insert(0, "0")
            count_edit.place(x=75, y=70, width=50, height=24)

            def _next():
                c = int(count_edit.get() or 0)
                pc_data["filter_count"] = c
                dlg.destroy()
                if c > 0:
                    _step_filter_names(c)
                else:
                    pc_data["popcorn_filters"] = [""]
                    if pc_data.get("popcorn_style") == "amount":
                        _step_drop_count()
                    else:
                        _finalize()

            tk.Button(dlg, text="Next \u2192", font=FONT_BOLD, fg=FG_ACCENT,
                      bg=BG_COLOR, command=_next).place(x=15, y=105, width=100, height=26)
            tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=dlg.destroy).place(x=120, y=105, width=100, height=26)

        def _step_filter_names(count: int):
            h = 90 + count * 28 + 40
            dlg = self._make_dlg("Key Repeat \u2014 Filter Names", 350, h)
            tk.Label(dlg, text="Popcorn Filter Names", bg=BG_DARK, fg=FG_ACCENT,
                     font=FONT_BOLD).place(x=15, y=10, width=300)
            edits = []
            for i in range(count):
                y = 40 + i * 28
                tk.Label(dlg, text=f"Filter {i+1}:", bg=BG_DARK, fg=FG_COLOR,
                         font=FONT_DEFAULT).place(x=15, y=y, width=70)
                e = tk.Entry(dlg, font=FONT_DEFAULT)
                e.place(x=90, y=y, width=230, height=24)
                edits.append(e)

            btn_y = 40 + count * 28 + 10

            def _next():
                pc_data["popcorn_filters"] = [
                    e.get().strip() or "" for e in edits
                ]
                dlg.destroy()
                if pc_data.get("popcorn_style") == "amount":
                    _step_drop_count()
                else:
                    _finalize()

            tk.Button(dlg, text="Next \u2192", font=FONT_BOLD, fg=FG_ACCENT,
                      bg=BG_COLOR, command=_next).place(x=15, y=btn_y, width=100, height=26)
            tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=dlg.destroy).place(x=120, y=btn_y, width=100, height=26)

        def _step_drop_count():
            dlg = self._make_dlg("Key Repeat \u2014 Drop Amount", 300, 140)
            tk.Label(dlg, text="Drops Per Filter", bg=BG_DARK, fg=FG_ACCENT,
                     font=FONT_BOLD).place(x=15, y=10, width=270)
            tk.Label(dlg, text="How many items to drop per filter?",
                     bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                     ).place(x=15, y=35, width=270)
            tk.Label(dlg, text="Drops:", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_DEFAULT).place(x=15, y=65, width=55)
            drop_edit = tk.Entry(dlg, font=FONT_DEFAULT)
            drop_edit.insert(0, "10")
            drop_edit.place(x=75, y=65, width=60, height=24)

            def _done():
                pc_data["popcorn_drop_count"] = int(drop_edit.get() or 10)
                dlg.destroy()
                _finalize()

            tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT,
                      bg=BG_COLOR, command=_done).place(x=15, y=100, width=100, height=26)
            tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=dlg.destroy).place(x=120, y=100, width=100, height=26)

        _step_ask()


    def _guided_start(self):
        INV_TYPES = ["Vault", "Player Inventory", "Crafting"]
        dlg = self._make_dlg("Guided Macro", 350, 300)
        pad_x = 16
        y = 16

        tk.Label(dlg, text="Guided Macro", bg=BG_DARK, fg=FG_ACCENT,
                 font=FONT_BOLD).place(x=pad_x, y=y)
        y += 28

        tk.Label(dlg, text="Inventory:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y, width=100)
        inv_var = tk.StringVar(value=INV_TYPES[0])
        inv_cb = ttk.Combobox(dlg, textvariable=inv_var, values=INV_TYPES,
                              state="readonly", width=20, font=FONT_DEFAULT)
        inv_cb.place(x=130, y=y)

        craft_hint = tk.Label(dlg, text="drop/take \u2014 craft tab to craft",
                              bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC)
        y += 28

        tk.Label(dlg, text="Action:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y, width=100)
        action_var = tk.StringVar(value="Popcorn")
        action_cb = ttk.Combobox(dlg, textvariable=action_var,
                                 values=["Popcorn", "Take"],
                                 state="readonly", width=20, font=FONT_DEFAULT)
        action_cb.place(x=130, y=y)
        y += 32

        sep_y = y
        tk.Frame(dlg, bg="#333333", height=1).place(x=pad_x, y=sep_y, width=318)
        field_y = sep_y + 8

        # ── Take/Give fields ──
        take_frame = tk.Frame(dlg, bg=BG_DARK)
        tk.Label(take_frame, text="Count:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=0)
        count_var = tk.StringVar(value="0")
        tk.Entry(take_frame, textvariable=count_var, width=6,
                 font=FONT_DEFAULT).place(x=114, y=0)
        tk.Label(take_frame, text="(0 = all)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=170, y=2)
        tk.Label(take_frame, text="Search filter:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=28)
        take_filter_var = tk.StringVar()
        tk.Entry(take_frame, textvariable=take_filter_var, width=16,
                 font=FONT_DEFAULT).place(x=114, y=28)
        tk.Label(take_frame, text="(blank = no filter)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=114, y=50)

        # ── Popcorn fields ──
        pop_frame = tk.Frame(dlg, bg=BG_DARK)
        tk.Label(pop_frame, text="Drop count:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=0)
        drop_count_var = tk.StringVar(value="0")
        tk.Entry(pop_frame, textvariable=drop_count_var, width=6,
                 font=FONT_DEFAULT).place(x=114, y=0)
        tk.Label(pop_frame, text="(0 = all)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=170, y=2)
        tk.Label(pop_frame, text="Drop key:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=28)
        drop_key_lbl = tk.Label(pop_frame,
                                text=(getattr(state, "pc_drop_key", "") or "?").upper(),
                                bg=BG_DARK, fg=FG_ACCENT, font=FONT_BOLD, anchor="w")
        drop_key_lbl.place(x=114, y=28)
        tk.Label(pop_frame, text="Search filter:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=56)
        pop_filter_var = tk.StringVar()
        tk.Entry(pop_frame, textvariable=pop_filter_var, width=16,
                 font=FONT_DEFAULT).place(x=114, y=56)
        tk.Label(pop_frame, text="(blank = no filter)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=114, y=78)

        # ── Name + buttons (dynamic position) ──
        bottom_sep = tk.Frame(dlg, bg="#333333", height=1)
        name_lbl = tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
                            font=FONT_DEFAULT)
        name_var = tk.StringVar()
        name_entry = tk.Entry(dlg, textvariable=name_var, width=26, font=FONT_DEFAULT)
        save_btn = tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT,
                             bg=BG_COLOR, command=lambda: _save())
        cancel_btn = tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                               bg=BG_COLOR, command=dlg.destroy)

        frame_heights = {"take": 66, "popcorn": 100}

        def _place_bottom(action_key):
            h = frame_heights.get(action_key, 94)
            by = field_y + h + 4
            bottom_sep.place(x=pad_x, y=by, width=318)
            name_lbl.place(x=pad_x, y=by + 8)
            name_entry.place(x=130, y=by + 8)
            save_btn.place(x=pad_x, y=by + 40, width=100, height=26)
            cancel_btn.place(x=200, y=by + 40, width=100, height=26)
            dlg.geometry(f"350x{by + 76}")

        user_edited_name = [False]
        name_entry.bind("<Key>", lambda *_: user_edited_name.__setitem__(0, True))

        def _gen_auto_name():
            action = action_var.get()
            inv = inv_var.get()
            display_inv = "Player" if inv == "Player Inventory" else inv
            if action in ("Take", "Give"):
                c = count_var.get()
                unit = f" {c}" if c and c != "0" else ""
                return f"{display_inv} {action}{unit}"
            elif action == "Popcorn":
                c = drop_count_var.get()
                unit = f" {c}" if c and c != "0" else ""
                return f"{display_inv} Popcorn{unit}"
            return ""

        def _update_name(*_):
            if not user_edited_name[0]:
                name_var.set(_gen_auto_name())

        def _prompt_drop_key_if_needed():
            dk = getattr(state, "pc_drop_key", "")
            if not dk:
                _dk_dlg = self._make_dlg("Drop Key Not Set", 340, 130)
                tk.Label(_dk_dlg, text="Set your ARK drop keybind:",
                         bg=BG_DARK, fg=FG_ACCENT, font=FONT_BOLD).place(x=20, y=10)
                dk_edit = tk.Entry(_dk_dlg, font=FONT_DEFAULT)
                dk_edit.insert(0, "g")
                dk_edit.place(x=20, y=45, width=80, height=24)

                def _dk_save():
                    val = dk_edit.get().strip().lower()
                    if not val:
                        return
                    state.pc_drop_key = val
                    from core.config import write_ini
                    write_ini("Popcorn", "DropKey", val)
                    drop_key_lbl.configure(text=val.upper())
                    _dk_dlg.destroy()

                tk.Button(_dk_dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT,
                          bg=BG_COLOR, command=_dk_save
                          ).place(x=20, y=90, width=140, height=28)
                tk.Button(_dk_dlg, text="Cancel", font=FONT_DEFAULT, fg=FG_DIM,
                          bg=BG_COLOR, command=_dk_dlg.destroy
                          ).place(x=180, y=90, width=140, height=28)

        def _update_fields(*_):
            action = action_var.get()
            take_frame.place_forget()
            pop_frame.place_forget()
            if action in ("Take", "Give"):
                take_frame.place(x=pad_x, y=field_y, width=318, height=66)
                _place_bottom("take")
            elif action == "Popcorn":
                _prompt_drop_key_if_needed()
                drop_key_lbl.configure(
                    text=(getattr(state, "pc_drop_key", "") or "?").upper())
                pop_frame.place(x=pad_x, y=field_y, width=318, height=100)
                _place_bottom("popcorn")
            _update_name()

        def _on_inv_change(*_):
            inv = inv_var.get()
            if inv == "Crafting":
                craft_hint.place(x=130, y=17)
            else:
                craft_hint.place_forget()
            if inv == "Player Inventory":
                action_cb.configure(values=["Give", "Popcorn"], state="readonly")
                if action_var.get() not in ("Give", "Popcorn"):
                    action_var.set("Give")
            else:
                action_cb.configure(values=["Popcorn", "Take"],
                                    state="readonly")
                if action_var.get() == "Give":
                    action_var.set("Popcorn")
            _update_fields()

        action_cb.bind("<<ComboboxSelected>>", _update_fields)
        inv_cb.bind("<<ComboboxSelected>>", _on_inv_change)
        count_var.trace_add("write", _update_name)
        drop_count_var.trace_add("write", _update_name)
        _update_fields()

        def _save():
            action = action_var.get().lower()
            inv = inv_var.get()
            inv_map = {"vault": "vault", "player inventory": "player",
                       "crafting": "crafting"}
            inv_type = inv_map.get(inv.lower(), "vault")
            n = name_var.get().strip()
            if not n:
                return

            if action == "give":
                count = int(count_var.get() or 0)
                if count < 1:
                    count = 1
                filt = take_filter_var.get().strip()
                has_filter = bool(filt)
                skip_first = not has_filter
                events = []
                remaining = count
                while remaining > 0:
                    slot = 0
                    clicked = 0
                    for row in range(6):
                        for col in range(6):
                            slot += 1
                            if skip_first and slot == 1:
                                continue
                            if clicked >= remaining:
                                break
                            x = int(state.pl_start_slot_x + col * state.pl_slot_w)
                            y = int(state.pl_start_slot_y + row * state.pl_slot_h)
                            if events:
                                events.append({"type": "M", "x": x, "y": y,
                                               "delay": 0})
                            events.append({"type": "C", "dir": "c", "btn": "L",
                                           "x": x, "y": y, "delay": 100})
                            events.append({"type": "K", "dir": "p", "key": "t",
                                           "delay": 60})
                            clicked += 1
                        if clicked >= remaining:
                            break
                    remaining -= clicked
                m = {
                    "name": n, "type": "guided", "hotkey": "",
                    "speed_mult": 1.0, "loop_enabled": False,
                    "inv_type": inv_type,
                    "mouse_speed": 0, "mouse_settle": 1,
                    "inv_load_delay": 500, "turbo": 1, "turbo_delay": 1,
                    "player_search": 1,
                    "guided_action": "give", "guided_key": "t",
                    "guided_count": count,
                    "search_filters": [filt] if filt else [],
                    "events": events,
                }
            elif action == "popcorn":
                count = int(drop_count_var.get() or 0)
                filt = pop_filter_var.get().strip()
                dk = getattr(state, "pc_drop_key", "g") or "g"
                events = _build_guided_events("popcorn", count, drop_key=dk)
                m = {
                    "name": n, "type": "guided", "hotkey": "",
                    "speed_mult": 1.0, "loop_enabled": True,
                    "inv_type": inv_type,
                    "mouse_speed": 0, "mouse_settle": 1,
                    "inv_load_delay": 1500, "turbo": 1, "turbo_delay": 1,
                    "player_search": 0,
                    "popcorn_all": int(count == 0),
                    "guided_action": "popcorn", "guided_key": dk,
                    "guided_count": count,
                    "search_filters": [filt] if filt else [],
                    "events": events,
                }
            else:
                count = int(count_var.get() or 0)
                filt = take_filter_var.get().strip()
                events = _build_guided_events("take", count)
                m = {
                    "name": n, "type": "guided", "hotkey": "",
                    "speed_mult": 1.0, "loop_enabled": False,
                    "inv_type": inv_type,
                    "mouse_speed": 0, "mouse_settle": 1,
                    "inv_load_delay": 1500, "turbo": 1, "turbo_delay": 1,
                    "player_search": 0,
                    "guided_action": "take", "guided_key": "t",
                    "guided_count": count,
                    "search_filters": [filt] if filt else [],
                    "events": events,
                }

            state.macro_list.append(m)
            from modules.macro_system import macro_save_all
            macro_save_all()
            self._refresh_list()
            dlg.destroy()

    def _guided_record_filters(self, parent_dlg, inv_type, name, count):
        parent_dlg.destroy()
        h = 80 + count * 28 + 40
        dlg = self._make_dlg("Guided Macro \u2014 Filters", 350, h)
        tk.Label(dlg, text="Enter search filters", bg=BG_DARK,
                 fg=FG_ACCENT, font=FONT_BOLD).place(x=15, y=10, width=300)
        edits = []
        for i in range(count):
            y = 40 + i * 28
            tk.Label(dlg, text=f"Filter {i+1}:", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_DEFAULT).place(x=15, y=y, width=70)
            e = tk.Entry(dlg, font=FONT_DEFAULT)
            e.place(x=90, y=y, width=230, height=24)
            edits.append(e)
        btn_y = 40 + count * 28 + 10

        def _start():
            filters = [e.get().strip() for e in edits]
            dlg.destroy()
            from modules.macro_system import macro_start_guided_record
            macro_start_guided_record(
                name, inv_type, filters,
                on_done=lambda m: self._on_record_done(m),
            )
            if state.main_gui:
                state.main_gui.hide()

        tk.Button(dlg, text="Start Recording", font=FONT_BOLD, fg=FG_ACCENT,
                  bg=BG_COLOR, command=_start
                  ).place(x=15, y=btn_y, width=140, height=26)
        tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                  bg=BG_COLOR, command=dlg.destroy
                  ).place(x=165, y=btn_y, width=100, height=26)


    def _on_record_done(self, macro_dict: dict):
        if macro_dict and macro_dict.get("events"):
            wizard_data = {
                "name": macro_dict.get("name", ""),
                "inv_type": macro_dict.get("inv_type", "vault"),
                "search_filters": macro_dict.get("search_filters", []),
            }
            if state.root:
                state.root.after(0, lambda: self._guided_show_save_dialog(
                    wizard_data, macro_dict.get("events", [])))


    def _combo_start(self):
        dlg = self._make_dlg("Link: Popcorn + Magic F", 350, 228)
        pad_x = 16
        y = 16

        tk.Label(dlg, text="Link: Popcorn + Magic F", bg=BG_DARK, fg=FG_ACCENT,
                 font=FONT_BOLD).place(x=pad_x, y=y)
        y += 34

        tk.Label(dlg, text="Popcorn filters:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y, width=120)
        pc_var = tk.StringVar()
        tk.Entry(dlg, textvariable=pc_var, width=22, font=FONT_DEFAULT
                 ).place(x=140, y=y)
        y += 26
        tk.Label(dlg, text="comma-separated (empty = all)",
                 bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL).place(x=140, y=y)
        y += 22

        tk.Label(dlg, text="Magic F filters:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y, width=120)
        mf_var = tk.StringVar()
        tk.Entry(dlg, textvariable=mf_var, width=22, font=FONT_DEFAULT
                 ).place(x=140, y=y)
        y += 26
        tk.Label(dlg, text="comma-separated",
                 bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL).place(x=140, y=y)
        y += 28

        tk.Frame(dlg, bg="#333333", height=1).place(x=pad_x, y=y, width=318)
        y += 10

        tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y, width=55)
        name_var = tk.StringVar(value="PC+MF")
        tk.Entry(dlg, textvariable=name_var, width=22, font=FONT_DEFAULT
                 ).place(x=140, y=y)
        y += 28

        def _save():
            n = name_var.get().strip()
            if not n:
                return
            pc_filters = [f.strip() for f in pc_var.get().split(",") if f.strip()]
            if not pc_filters:
                pc_filters = [""]
            mf_filters = [f.strip() for f in mf_var.get().split(",") if f.strip()]
            m = {
                "name": n,
                "type": "combo",
                "hotkey": "",
                "popcorn_filters": pc_filters,
                "magic_f_filters": mf_filters,
                "take_count": 0,
                "take_filter": "",
            }
            state.macro_list.append(m)
            from modules.macro_system import macro_save_all
            macro_save_all()
            self._refresh_list()
            dlg.destroy()

        tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT,
                  bg=BG_COLOR, command=_save).place(x=pad_x, y=y, width=100, height=26)
        tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                  bg=BG_COLOR, command=dlg.destroy).place(x=200, y=y, width=100, height=26)

    def _show_help(self):
        from gui.dialogs import show_help_dialog
        show_help_dialog("Macro Tab \u2014 Help",
            "CONTROLS\n"
            "F3 / Start \u2192 arm selected macro\n"
            "F \u2192 run at inventory  |  Q \u2192 cycle / single item\n"
            "Z \u2192 next macro  |  F1 \u2192 stop & show UI\n\n"
            "COMBO (Popcorn+MagicF)\n"
            "F \u2192 open inv & drop/give  |  R \u2192 next MF filter\n"
            "Q \u2192 swap Popcorn \u2194 MagicF  |  Z \u2192 exit",
            self.parent)

    def _play_selected(self):
        idx = self.get_selected_index()
        if idx is None:
            return
        from modules.macro_system import macro_play_selected
        state.macro_selected_idx = idx + 1
        macro_play_selected()
        if state.macro_armed and state.main_gui:
            state.main_gui.hide()

    def _tune_selected(self):
        idx = self.get_selected_index()
        if idx is None or idx >= len(state.macro_list):
            return
        m = state.macro_list[idx]
        if m["type"] not in ("recorded", "guided", "pyro"):
            return

        from modules.macro_system import macro_save_all
        import threading

        tune_low = 0.05
        tune_high = m.get("speed_mult", 1.0)
        tune_current = (tune_low + tune_high) / 2
        iteration = [0]

        def _ask_result():
            dlg = self._make_dlg("Tune Macro", 300, 140)
            tk.Label(dlg, text=f"TUNING: {m['name']} at {tune_current:.2f}x",
                     bg=BG_DARK, fg=FG_ACCENT, font=FONT_BOLD
                     ).place(x=10, y=10, width=280)
            tk.Label(dlg, text="Did it work?", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_DEFAULT).place(x=10, y=40, width=280)

            def _pass():
                nonlocal tune_high, tune_current
                tune_high = tune_current
                tune_current = (tune_low + tune_current) / 2
                iteration[0] += 1
                dlg.destroy()
                _run_next()

            def _fail():
                nonlocal tune_low, tune_current
                tune_low = tune_current
                tune_current = (tune_current + tune_high) / 2
                iteration[0] += 1
                dlg.destroy()
                _run_next()

            def _done():
                m["speed_mult"] = round(tune_high, 3)
                macro_save_all()
                self._refresh_list()
                dlg.destroy()
                from gui.tooltip import show_tooltip
                show_tooltip(f" Tuning done: {m['name']} = {tune_high:.2f}x", 0, 0)

            tk.Button(dlg, text="Y = Pass", font=FONT_BOLD, fg=FG_ACCENT,
                      bg=BG_COLOR, command=_pass).place(x=10, y=80, width=80, height=26)
            tk.Button(dlg, text="N = Fail", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=_fail).place(x=100, y=80, width=80, height=26)
            tk.Button(dlg, text="Done", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=_done).place(x=190, y=80, width=80, height=26)

        def _run_next():
            if iteration[0] >= 10 or (tune_high - tune_low) < 0.03:
                m["speed_mult"] = round(tune_high, 3)
                macro_save_all()
                self._refresh_list()
                from gui.tooltip import show_tooltip
                show_tooltip(f" Tuning done: {m['name']} = {tune_high:.2f}x", 0, 0)
                return
            orig = m.get("speed_mult", 1.0)
            m["speed_mult"] = tune_current
            from gui.tooltip import show_tooltip
            show_tooltip(f" TUNING: {m['name']}\n Speed: {tune_current:.2f}x (run {iteration[0]+1})\n Playing...", 0, 0)
            from modules.macro_system import macro_play_by_index
            def _play_and_ask():
                macro_play_by_index(idx + 1)
                while state.macro_playing:
                    import time
                    time.sleep(0.1)
                m["speed_mult"] = orig
                if state.root:
                    state.root.after(0, _ask_result)
            threading.Thread(target=_play_and_ask, daemon=True).start()

        if state.main_gui:
            state.main_gui.hide()
        _run_next()

    def _edit_selected(self):
        idx = self.get_selected_index()
        if idx is None or idx >= len(state.macro_list):
            return
        m = state.macro_list[idx]
        mtype = m["type"]

        if mtype == "repeat":
            self._edit_repeat(m)
        elif mtype == "combo":
            self._edit_combo(m)
        elif mtype in ("recorded", "pyro", "guided"):
            self._edit_speed_macro(m)

    def _edit_repeat(self, m: dict):
        from modules.macro_system import macro_save_all
        dlg = self._make_dlg("Edit Key Repeat", 350, 416)
        key_list = list(m.get("repeat_keys", []))
        pad_x = 16
        y = 16

        tk.Label(dlg, text=f"Edit: {m['name']}", bg=BG_DARK, fg=FG_ACCENT,
                 font=FONT_BOLD).place(x=pad_x, y=y)
        y += 30

        tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        name_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        name_edit.insert(0, m["name"])
        name_edit.place(x=130, y=y, width=190, height=24)
        y += 30

        tk.Label(dlg, text="Keys:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        key_display = tk.Entry(dlg, font=FONT_DEFAULT, state="readonly")
        key_display.place(x=130, y=y, width=120, height=24)
        key_display.configure(state="normal")
        key_display.insert(0, ", ".join(key_list))
        key_display.configure(state="readonly")

        _edit_excluded = {"shift_l", "shift_r", "control_l", "control_r",
                          "alt_l", "alt_r", "escape", "caps_lock", "tab",
                          "super_l", "super_r", "f1", "f2", "f3"}

        def _finish_edit_detect(k):
            if k not in key_list:
                key_list.append(k)
            key_display.configure(state="normal")
            key_display.delete(0, tk.END)
            key_display.insert(0, ", ".join(key_list))
            key_display.configure(state="readonly")

        def _add_key():
            key_display.configure(state="normal")
            key_display.delete(0, tk.END)
            key_display.insert(0, "Press key/click...")
            key_display.configure(state="readonly")
            def on_key(event):
                k = event.keysym.lower()
                if k in _edit_excluded:
                    return
                dlg.unbind("<Key>", kid)
                dlg.unbind("<Button-1>", b1id)
                dlg.unbind("<Button-2>", b2id)
                dlg.unbind("<Button-3>", b3id)
                _finish_edit_detect(k)
            def on_mouse(btn_name):
                def handler(event):
                    dlg.unbind("<Key>", kid)
                    dlg.unbind("<Button-1>", b1id)
                    dlg.unbind("<Button-2>", b2id)
                    dlg.unbind("<Button-3>", b3id)
                    _finish_edit_detect(btn_name)
                    return "break"
                return handler
            kid = dlg.bind("<Key>", on_key)
            b1id = dlg.bind("<Button-1>", on_mouse("lbutton"))
            b2id = dlg.bind("<Button-2>", on_mouse("mbutton"))
            b3id = dlg.bind("<Button-3>", on_mouse("rbutton"))

        def _clear_keys():
            key_list.clear()
            key_display.configure(state="normal")
            key_display.delete(0, tk.END)
            key_display.configure(state="readonly")

        tk.Button(dlg, text="Add", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=_add_key).place(x=260, y=y, width=35, height=24)
        tk.Button(dlg, text="X", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=_clear_keys).place(x=298, y=y, width=22, height=24)
        y += 24
        tk.Label(dlg, text="Q cycles between keys during play", bg=BG_DARK,
                 fg=FG_DIM, font=FONT_SMALL_ITALIC).place(x=130, y=y)
        y += 22

        tk.Label(dlg, text="Interval (ms):", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        interval_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        display_interval = 0 if m.get("repeat_spam", 0) else m.get(
            "repeat_interval", 600)
        interval_edit.insert(0, str(display_interval))
        interval_edit.place(x=130, y=y, width=65, height=24)
        tk.Label(dlg, text="(0 = hold)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=200, y=y + 2)
        y += 30

        tk.Label(dlg, text="Bind:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=pad_x, y=y)
        bind_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        bind_edit.insert(0, m.get("hotkey", ""))
        bind_edit.place(x=130, y=y, width=80, height=24)
        tk.Button(dlg, text="Detect", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=lambda: self._detect_key_into(dlg, bind_edit)
                  ).place(x=215, y=y, width=60, height=24)
        y += 34

        tk.Frame(dlg, bg="#333333", height=1).place(x=pad_x, y=y, width=318)
        y += 8

        has_pc = bool(m.get("popcorn_filters"))
        pc_var = tk.BooleanVar(value=has_pc)
        pc_check = tk.Checkbutton(dlg, text="Popcorn after repeat",
                                  variable=pc_var, bg=BG_DARK, fg=FG_COLOR,
                                  selectcolor=BG_DARK, activebackground=BG_DARK,
                                  activeforeground=FG_COLOR, font=FONT_DEFAULT,
                                  anchor="w")
        pc_check.place(x=pad_x, y=y)
        y += 26

        pc_frame = tk.Frame(dlg, bg=BG_DARK)
        tk.Label(pc_frame, text="Drop count:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=0)
        pc_drop_var = tk.StringVar(
            value=str(m.get("popcorn_drop_count", 0)))
        tk.Entry(pc_frame, textvariable=pc_drop_var, width=6,
                 font=FONT_DEFAULT).place(x=114, y=0)
        tk.Label(pc_frame, text="(0 = all)", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=170, y=2)

        tk.Label(pc_frame, text="Drop key:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=0, y=28)
        dk = getattr(state, "pc_drop_key", "") or "?"
        pc_drop_key_lbl = tk.Label(pc_frame, text=dk.upper(),
                                   bg=BG_DARK, fg=FG_ACCENT, font=FONT_BOLD,
                                   anchor="w")
        pc_drop_key_lbl.place(x=114, y=28)
        pc_frame_y = y

        save_btn = tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT,
                             bg=BG_COLOR)
        cancel_btn = tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                               bg=BG_COLOR, command=dlg.destroy)

        def _toggle_pc(*_):
            if pc_var.get():
                pc_drop_key_lbl.configure(
                    text=(getattr(state, "pc_drop_key", "") or "?").upper())
                pc_frame.place(x=pad_x + 16, y=pc_frame_y,
                               width=302, height=60)
                btn_y = pc_frame_y + 66
            else:
                pc_frame.place_forget()
                btn_y = pc_frame_y + 4
            save_btn.place(x=pad_x, y=btn_y, width=100, height=26)
            cancel_btn.place(x=200, y=btn_y, width=100, height=26)
            dlg.geometry(f"350x{btn_y + 42}")

        def _save():
            n = name_edit.get().strip()
            if not n or not key_list:
                return
            interval = int(interval_edit.get() or 600)
            m["name"] = n
            m["hotkey"] = bind_edit.get().strip().lower()
            m["repeat_keys"] = list(key_list)
            m["repeat_interval"] = interval
            m["repeat_spam"] = int(interval == 0)
            if pc_var.get():
                dc = int(pc_drop_var.get() or 0)
                m["popcorn_filters"] = [""]
                m["popcorn_style"] = "all" if dc == 0 else "amount"
                m["popcorn_drop_count"] = dc
            else:
                m["popcorn_filters"] = []
                m["popcorn_style"] = "all"
                m["popcorn_drop_count"] = 0
            macro_save_all()
            self._refresh_list()
            dlg.destroy()

        save_btn.configure(command=_save)
        pc_var.trace_add("write", _toggle_pc)
        _toggle_pc()

    def _edit_speed_macro(self, m: dict):
        from modules.macro_system import macro_save_all
        is_guided = m["type"] == "guided"
        dlg = self._make_dlg(f"Edit {m['type'].capitalize()} Macro", 300,
                             280 if is_guided else 200)

        tk.Label(dlg, text=f"Edit: {m['name']}", bg=BG_DARK, fg=FG_ACCENT,
                 font=FONT_BOLD).place(x=15, y=10, width=260)

        tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=42, width=55)
        name_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        name_edit.insert(0, m["name"])
        name_edit.place(x=75, y=42, width=195, height=24)

        tk.Label(dlg, text="Hotkey:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=72, width=55)
        hk_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        hk_edit.insert(0, m.get("hotkey", ""))
        hk_edit.place(x=75, y=72, width=100, height=24)
        tk.Button(dlg, text="Set", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=lambda: self._detect_key_into(dlg, hk_edit)
                  ).place(x=180, y=72, width=35, height=24)

        tk.Label(dlg, text="Speed:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=102, width=55)
        speed_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        speed_edit.insert(0, f"{m.get('speed_mult', 1.0):.3f}")
        speed_edit.place(x=75, y=102, width=65, height=24)
        tk.Label(dlg, text="x mult", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=145, y=102, width=50)

        loop_var = tk.BooleanVar(value=bool(m.get("loop_enabled", 0)))
        if m["type"] != "pyro":
            tk.Checkbutton(dlg, text="Loop", variable=loop_var,
                           **CB_OPTS).place(x=15, y=130, width=60)

        btn_y = 130
        if is_guided:
            ec = len(m.get("events", []))
            give_str = " (Give)" if m.get("player_search") else ""
            tk.Label(dlg, text=f"{ec} events  |  {m.get('inv_type', 'vault')}{give_str}",
                     bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                     ).place(x=15, y=155, width=260)

            tk.Label(dlg, text="Settle (ms):", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_SMALL).place(x=15, y=178, width=70)
            settle_edit = tk.Entry(dlg, font=FONT_SMALL)
            settle_edit.insert(0, str(m.get("mouse_settle", 1)))
            settle_edit.place(x=88, y=178, width=35, height=20)

            tk.Label(dlg, text="Mouse spd:", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_SMALL).place(x=135, y=178, width=65)
            mouse_edit = tk.Entry(dlg, font=FONT_SMALL)
            mouse_edit.insert(0, str(m.get("mouse_speed", 0)))
            mouse_edit.place(x=205, y=178, width=30, height=20)

            tk.Label(dlg, text="Inv load (ms):", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_SMALL).place(x=15, y=202, width=80)
            load_edit = tk.Entry(dlg, font=FONT_SMALL)
            load_edit.insert(0, str(m.get("inv_load_delay", 1500)))
            load_edit.place(x=100, y=202, width=50, height=20)

            turbo_var = tk.BooleanVar(value=bool(m.get("turbo", 0)))
            tk.Checkbutton(dlg, text="Turbo", variable=turbo_var,
                           **CB_OPTS).place(x=165, y=200, width=60)
            turbo_edit = tk.Entry(dlg, font=FONT_SMALL)
            turbo_edit.insert(0, str(m.get("turbo_delay", 1)))
            turbo_edit.place(x=230, y=202, width=30, height=20)

            btn_y = 232
        else:
            btn_y = 160

        def _save():
            n = name_edit.get().strip()
            if not n:
                return
            m["name"] = n
            m["hotkey"] = hk_edit.get().strip().lower()
            try:
                m["speed_mult"] = float(speed_edit.get())
            except ValueError:
                m["speed_mult"] = 1.0
            m["loop_enabled"] = loop_var.get()
            if is_guided:
                m["mouse_settle"] = int(settle_edit.get() or 1)
                m["mouse_speed"] = int(mouse_edit.get() or 0)
                m["inv_load_delay"] = int(load_edit.get() or 1500)
                m["turbo"] = int(turbo_var.get())
                m["turbo_delay"] = int(turbo_edit.get() or 1)
            macro_save_all()
            self._refresh_list()
            dlg.destroy()

        def _re_record():
            _save_fields_to_macro()
            dlg.destroy()
            self._guided_re_record(m)

        def _save_fields_to_macro():
            m["name"] = name_edit.get().strip() or m["name"]
            m["hotkey"] = hk_edit.get().strip().lower()
            try:
                m["speed_mult"] = float(speed_edit.get())
            except ValueError:
                pass
            m["loop_enabled"] = loop_var.get()
            if is_guided:
                m["mouse_settle"] = int(settle_edit.get() or 1)
                m["mouse_speed"] = int(mouse_edit.get() or 0)
                m["inv_load_delay"] = int(load_edit.get() or 1500)
                m["turbo"] = int(turbo_var.get())
                m["turbo_delay"] = int(turbo_edit.get() or 1)

        tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT, bg=BG_COLOR,
                  command=_save).place(x=15, y=btn_y, width=80, height=26)
        if is_guided:
            tk.Button(dlg, text="Re-record", font=FONT_BOLD, fg="#FFAA00",
                      bg=BG_COLOR, command=_re_record
                      ).place(x=100, y=btn_y, width=90, height=26)
            tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=dlg.destroy
                      ).place(x=195, y=btn_y, width=80, height=26)
        else:
            tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR,
                      bg=BG_COLOR, command=dlg.destroy
                      ).place(x=100, y=btn_y, width=100, height=26)

    def _edit_combo(self, m: dict):
        from modules.macro_system import macro_save_all
        dlg = self._make_dlg("Edit Combo Macro", 340, 250)

        tk.Label(dlg, text=f"Edit: {m['name']}", bg=BG_DARK, fg=FG_ACCENT,
                 font=FONT_BOLD).place(x=15, y=10, width=300)

        tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=40, width=55)
        name_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        name_edit.insert(0, m["name"])
        name_edit.place(x=75, y=40, width=240, height=24)

        tk.Label(dlg, text="Hotkey:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=70, width=55)
        hk_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        hk_edit.insert(0, m.get("hotkey", ""))
        hk_edit.place(x=75, y=70, width=100, height=24)
        tk.Button(dlg, text="Detect", font=FONT_SMALL, fg=FG_COLOR, bg=BG_COLOR,
                  command=lambda: self._detect_key_into(dlg, hk_edit)
                  ).place(x=180, y=70, width=75, height=24)

        tk.Label(dlg, text="Popcorn Filters:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=102, width=300)
        pc_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        pc_str = "|".join("<all>" if f == "" else f
                          for f in m.get("popcorn_filters", []))
        pc_edit.insert(0, pc_str)
        pc_edit.place(x=15, y=122, width=300, height=24)
        tk.Label(dlg, text="Separate with |  blank or <all> = no filter",
                 bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                 ).place(x=15, y=147, width=300)

        tk.Label(dlg, text="Magic F Give Filters:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=165, width=300)
        mf_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        mf_edit.insert(0, "|".join(m.get("magic_f_filters", [])))
        mf_edit.place(x=15, y=185, width=300, height=24)

        def _save():
            n = name_edit.get().strip()
            if not n:
                return
            m["name"] = n
            m["hotkey"] = hk_edit.get().strip().lower()
            raw_pc = pc_edit.get().strip()
            m["popcorn_filters"] = [
                "" if p.strip().lower() == "<all>" else p.strip()
                for p in raw_pc.split("|")
            ] if raw_pc else [""]
            raw_mf = mf_edit.get().strip()
            m["magic_f_filters"] = [
                p.strip() for p in raw_mf.split("|") if p.strip()
            ] if raw_mf else []
            macro_save_all()
            self._refresh_list()
            dlg.destroy()

        tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT, bg=BG_COLOR,
                  command=_save).place(x=15, y=215, width=100, height=26)
        tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR, bg=BG_COLOR,
                  command=dlg.destroy).place(x=120, y=215, width=100, height=26)

    def _guided_re_record(self, m: dict):
        from modules.macro_system import macro_save_all

        events = m.get("events", [])
        is_give = bool(m.get("player_search", 0))
        has_t_key = any(e.get("type") == "K" and e.get("key") == "t" for e in events)
        has_drop_key = any(e.get("type") == "K" and e.get("key") == state.pc_drop_key for e in events)

        if has_t_key or has_drop_key or is_give:
            self._guided_re_record_setup(m)
        else:
            self._guided_re_record_raw(m)

    def _guided_re_record_setup(self, m: dict):
        from modules.macro_system import macro_save_all

        is_give = bool(m.get("player_search", 0))
        events = m.get("events", [])
        has_drop = any(e.get("type") == "K" and e.get("key") == state.pc_drop_key for e in events)

        if is_give:
            mode_label = "Give"
        elif has_drop:
            mode_label = "Popcorn"
        else:
            mode_label = "Take"

        slot_count = sum(1 for e in events if e.get("type") == "M")

        dlg = self._make_dlg(f"Re-record {mode_label}", 320, 220)
        tk.Label(dlg, text=f"Re-record: {m['name']} ({mode_label})", bg=BG_DARK,
                 fg=FG_ACCENT, font=FONT_BOLD).place(x=15, y=10, width=280)

        tk.Label(dlg, text="Slot count:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=45, width=80)
        count_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        count_edit.insert(0, str(slot_count))
        count_edit.place(x=100, y=45, width=50, height=24)

        filter_y = 78
        if mode_label == "Popcorn":
            tk.Label(dlg, text="Drop key:", bg=BG_DARK, fg=FG_COLOR,
                     font=FONT_DEFAULT).place(x=15, y=78, width=80)
            drop_edit = tk.Entry(dlg, font=FONT_DEFAULT)
            drop_edit.insert(0, state.pc_drop_key)
            drop_edit.place(x=100, y=78, width=50, height=24)
            filter_y = 108
        else:
            drop_edit = None

        tk.Label(dlg, text="Search filter:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=filter_y, width=80)
        filter_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        filters = m.get("search_filters", [])
        if filters:
            filter_edit.insert(0, filters[0])
        filter_edit.place(x=100, y=filter_y, width=190, height=24)

        if is_give:
            tk.Label(dlg, text="First slot skipped without filter (implant)",
                     bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                     ).place(x=15, y=filter_y + 28, width=280)

        def _save():
            count = int(count_edit.get() or slot_count)
            filt = filter_edit.get().strip()
            skip_first = is_give and not filt

            if is_give:
                new_events = []
                cols = 6
                slot_idx = 0
                for i in range(count + (1 if skip_first else 0)):
                    if skip_first and i == 0:
                        continue
                    r, c = divmod(slot_idx, cols)
                    x = int(state.pl_start_slot_x + c * state.pl_slot_w)
                    y = int(state.pl_start_slot_y + r * state.pl_slot_h)
                    new_events.append({"type": "M", "x": x, "y": y, "delay": 0})
                    new_events.append({"type": "K", "dir": "p", "key": "t", "delay": 20})
                    slot_idx += 1
            else:
                dk = drop_edit.get().strip() if drop_edit else "t"
                if mode_label == "Take":
                    dk = "t"
                new_events = _build_guided_events(
                    "take" if mode_label == "Take" else "popcorn",
                    count, drop_key=dk)

            m["events"] = new_events
            m["search_filters"] = [filt] if filt else []
            macro_save_all()
            self._refresh_list()
            dlg.destroy()
            from gui.tooltip import show_tooltip
            show_tooltip(f" Re-recorded: {m['name']} ({len(new_events)} events)")

        tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT, bg=BG_COLOR,
                  command=_save).place(x=15, y=170, width=100, height=26)
        tk.Button(dlg, text="Cancel", font=FONT_BOLD, fg=FG_COLOR, bg=BG_COLOR,
                  command=dlg.destroy).place(x=120, y=170, width=100, height=26)

    def _guided_re_record_raw(self, m: dict):
        from modules.macro_system import (macro_start_guided_record,
                                          macro_save_all)
        macro_idx = None
        for i, mac in enumerate(state.macro_list):
            if mac is m:
                macro_idx = i
                break

        def _on_done(new_m):
            if new_m and macro_idx is not None:
                # Preserve existing settings, only replace events
                from modules.macro_system import _guided_clean_recorded_events
                m["events"] = _guided_clean_recorded_events(
                    new_m.get("events", []))
                macro_save_all()
                if state.root:
                    state.root.after(0, self._refresh_list)

        macro_start_guided_record(
            m["name"], m.get("inv_type", "vault"),
            m.get("search_filters", []),
            on_done=_on_done,
        )
        if state.main_gui:
            state.main_gui.hide()

    def _guided_show_save_dialog(self, wizard_data: dict, events: list):
        from modules.macro_system import (macro_save_all,
                                          _guided_clean_recorded_events)

        cleaned = _guided_clean_recorded_events(events)
        dlg = self._make_dlg("Save Guided Macro", 320, 300)
        state.guided_wiz_gui = dlg

        ec = len(cleaned)
        tk.Label(dlg, text=f"Save Guided Macro ({ec} events)", bg=BG_DARK,
                 fg=FG_ACCENT, font=FONT_BOLD).place(x=15, y=10, width=280)

        tk.Label(dlg, text="Name:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=45, width=55)
        name_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        name_edit.insert(0, wizard_data.get("name", ""))
        name_edit.place(x=75, y=45, width=215, height=24)

        loop_var = tk.BooleanVar()
        tk.Checkbutton(dlg, text="Loop", variable=loop_var,
                       **CB_OPTS).place(x=15, y=78, width=60)

        turbo_var = tk.BooleanVar(value=True)
        turbo_edit = tk.Entry(dlg, font=FONT_SMALL)
        turbo_edit.insert(0, "1")

        def _turbo_toggle():
            if turbo_var.get():
                turbo_edit.delete(0, tk.END)
                turbo_edit.insert(0, "1")
                settle_edit.delete(0, tk.END)
                settle_edit.insert(0, "1")
                mouse_edit.delete(0, tk.END)
                mouse_edit.insert(0, "0")
            else:
                turbo_edit.delete(0, tk.END)
                turbo_edit.insert(0, "30")
                settle_edit.delete(0, tk.END)
                settle_edit.insert(0, "30")
                mouse_edit.delete(0, tk.END)
                mouse_edit.insert(0, "0")

        tk.Checkbutton(dlg, text="Turbo", variable=turbo_var,
                       command=_turbo_toggle, **CB_OPTS
                       ).place(x=80, y=78, width=60)
        tk.Label(dlg, text="gap:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_SMALL).place(x=145, y=80, width=28)
        turbo_edit.place(x=175, y=80, width=35, height=20)
        tk.Label(dlg, text="ms", bg=BG_DARK, fg=FG_DIM,
                 font=FONT_SMALL).place(x=212, y=80, width=20)

        tk.Label(dlg, text="Settle (ms):", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=110, width=80)
        settle_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        settle_edit.insert(0, "1")
        settle_edit.place(x=100, y=110, width=50, height=24)

        tk.Label(dlg, text="Mouse speed:", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=165, y=110, width=90)
        mouse_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        mouse_edit.insert(0, "0")
        mouse_edit.place(x=260, y=110, width=35, height=24)

        tk.Label(dlg, text="Inv load delay (ms):", bg=BG_DARK, fg=FG_COLOR,
                 font=FONT_DEFAULT).place(x=15, y=143, width=130)
        load_edit = tk.Entry(dlg, font=FONT_DEFAULT)
        load_edit.insert(0, "1500")
        load_edit.place(x=150, y=143, width=60, height=24)

        inv_type = wizard_data.get("inv_type", "vault")
        filters = wizard_data.get("search_filters", [])
        tk.Label(dlg, text=f"Inv: {inv_type}  |  Filters: {len(filters)}",
                 bg=BG_DARK, fg=FG_DIM, font=FONT_SMALL_ITALIC
                 ).place(x=15, y=175, width=280)

        def _save():
            n = name_edit.get().strip()
            if not n:
                return
            new_m = {
                "name": n, "type": "guided", "hotkey": "f",
                "speed_mult": 1.0,
                "loop_enabled": int(loop_var.get()),
                "inv_type": inv_type,
                "mouse_speed": int(mouse_edit.get() or 0),
                "mouse_settle": int(settle_edit.get() or 1),
                "inv_load_delay": int(load_edit.get() or 1500),
                "turbo": int(turbo_var.get()),
                "turbo_delay": int(turbo_edit.get() or 1),
                "player_search": 0,
                "search_filters": filters,
                "events": cleaned,
            }
            state.macro_list.append(new_m)
            macro_save_all()
            self._refresh_list()
            state.guided_wiz_gui = None
            dlg.destroy()

        def _discard():
            state.guided_wiz_gui = None
            dlg.destroy()

        tk.Button(dlg, text="Save", font=FONT_BOLD, fg=FG_ACCENT, bg=BG_COLOR,
                  command=_save).place(x=15, y=210, width=100, height=26)
        tk.Button(dlg, text="Discard", font=FONT_BOLD, fg=FG_COLOR, bg=BG_COLOR,
                  command=_discard).place(x=120, y=210, width=100, height=26)

        dlg.protocol("WM_DELETE_WINDOW", _discard)

    def _delete_selected(self):
        idx = self.get_selected_index()
        if idx is None or idx >= len(state.macro_list):
            return
        m = state.macro_list[idx]
        if m.get("type") == "pyro":
            messagebox.showwarning("Protected", "Pyro macros cannot be deleted.")
            return
        from modules.macro_system import macro_save_all
        name = m.get("name", f"Macro {idx + 1}")
        if not messagebox.askyesno("Delete Macro", f"Delete '{name}'?"):
            return
        state.macro_list.pop(idx)
        macro_save_all()
        self._refresh_list()

    def _move_up(self):
        idx = self.get_selected_index()
        if idx is None or idx <= 0:
            return
        from modules.macro_system import macro_save_all
        state.macro_list[idx], state.macro_list[idx - 1] = (
            state.macro_list[idx - 1], state.macro_list[idx]
        )
        macro_save_all()
        self._refresh_list()
        children = self.tree.get_children()
        if idx - 1 < len(children):
            self.tree.selection_set(children[idx - 1])

    def _move_down(self):
        idx = self.get_selected_index()
        if idx is None or idx >= len(state.macro_list) - 1:
            return
        from modules.macro_system import macro_save_all
        state.macro_list[idx], state.macro_list[idx + 1] = (
            state.macro_list[idx + 1], state.macro_list[idx]
        )
        macro_save_all()
        self._refresh_list()
        children = self.tree.get_children()
        if idx + 1 < len(children):
            self.tree.selection_set(children[idx + 1])

    def _refresh_list(self):
        macros = []
        for m in state.macro_list:
            speed = ""
            if m["type"] in ("recorded", "pyro", "guided"):
                speed = f"{m.get('speed_mult', 1.0):.1f}x"
            elif m["type"] == "repeat":
                iv = m.get("repeat_interval", 1000)
                speed = "Hold" if m.get("repeat_spam", 0) or iv == 0 else f"{iv}ms"
            macros.append({
                "name": m.get("name", ""),
                "type": m.get("type", ""),
                "key": m.get("hotkey", ""),
                "speed": speed,
            })
        self.populate(macros)
