
import tkinter as tk
from gui.theme import BG_DARK, FG_COLOR, FG_ACCENT, FG_WHITE, FONT_DEFAULT, FONT_BOLD


_open_help_dialogs: dict[str, tk.Toplevel] = {}


def show_help_dialog(title: str, text: str, parent: tk.Tk | None = None):
    # Toggle: destroy existing dialog with same title
    existing = _open_help_dialogs.pop(title, None)
    if existing is not None:
        try:
            existing.destroy()
        except tk.TclError:
            pass
        return

    dlg = tk.Toplevel(parent)
    dlg.title(title)
    dlg.configure(bg=BG_DARK)
    dlg.attributes("-topmost", True)
    dlg.resizable(False, False)

    tk.Label(
        dlg, text=title, bg=BG_DARK, fg=FG_ACCENT,
        font=FONT_BOLD, anchor=tk.W,
    ).pack(padx=20, pady=(15, 5))

    tk.Label(
        dlg, text=text, bg=BG_DARK, fg=FG_COLOR,
        font=FONT_DEFAULT, justify=tk.LEFT, wraplength=400,
    ).pack(padx=20, pady=5)

    def _close():
        _open_help_dialogs.pop(title, None)
        dlg.destroy()

    btn = tk.Button(
        dlg, text="Got it", command=_close,
        bg="#333333", fg=FG_WHITE, font=FONT_BOLD,
        relief=tk.FLAT, padx=20, pady=4,
    )
    btn.pack(pady=(5, 15))

    dlg.protocol("WM_DELETE_WINDOW", _close)

    _open_help_dialogs[title] = dlg

    dlg.update_idletasks()
    w, h = dlg.winfo_width(), dlg.winfo_height()
    sw, sh = dlg.winfo_screenwidth(), dlg.winfo_screenheight()
    dlg.geometry(f"+{(sw - w) // 2}+{(sh - h) // 2}")


def show_message(title: str, text: str, parent: tk.Tk | None = None):
    show_help_dialog(title, text, parent)


def ask_yes_no(title: str, text: str, parent: tk.Tk | None = None) -> bool:
    result = [False]
    dlg = tk.Toplevel(parent)
    dlg.title(title)
    dlg.configure(bg=BG_DARK)
    dlg.attributes("-topmost", True)
    dlg.resizable(False, False)

    tk.Label(
        dlg, text=text, bg=BG_DARK, fg=FG_COLOR,
        font=FONT_DEFAULT, justify=tk.LEFT, wraplength=350,
    ).pack(padx=20, pady=(15, 10))

    btn_frame = tk.Frame(dlg, bg=BG_DARK)
    btn_frame.pack(pady=(0, 15))

    def _yes():
        result[0] = True
        dlg.destroy()

    tk.Button(
        btn_frame, text="Yes", command=_yes,
        bg="#334433", fg=FG_WHITE, font=FONT_BOLD,
        relief=tk.FLAT, padx=20, pady=4,
    ).pack(side=tk.LEFT, padx=5)

    tk.Button(
        btn_frame, text="No", command=dlg.destroy,
        bg="#443333", fg=FG_WHITE, font=FONT_BOLD,
        relief=tk.FLAT, padx=20, pady=4,
    ).pack(side=tk.LEFT, padx=5)

    dlg.protocol("WM_DELETE_WINDOW", dlg.destroy)
    dlg.grab_set()
    dlg.wait_window()
    return result[0]


def show_input_dialog(title: str, prompt: str, default: str = "",
                      parent: tk.Tk | None = None) -> str | None:
    result = [None]
    dlg = tk.Toplevel(parent)
    dlg.title(title)
    dlg.configure(bg=BG_DARK)
    dlg.attributes("-topmost", True)
    dlg.resizable(False, False)

    tk.Label(
        dlg, text=prompt, bg=BG_DARK, fg=FG_COLOR,
        font=FONT_DEFAULT, justify=tk.LEFT,
    ).pack(padx=20, pady=(15, 5))

    entry = tk.Entry(dlg, font=FONT_DEFAULT, width=30)
    entry.insert(0, default)
    entry.pack(padx=20, pady=5)
    entry.focus_set()

    btn_frame = tk.Frame(dlg, bg=BG_DARK)
    btn_frame.pack(pady=(5, 15))

    def _ok():
        result[0] = entry.get()
        dlg.destroy()

    entry.bind("<Return>", lambda e: _ok())

    tk.Button(
        btn_frame, text="OK", command=_ok,
        bg="#334433", fg=FG_WHITE, font=FONT_BOLD,
        relief=tk.FLAT, padx=20, pady=4,
    ).pack(side=tk.LEFT, padx=5)

    tk.Button(
        btn_frame, text="Cancel", command=dlg.destroy,
        bg="#443333", fg=FG_WHITE, font=FONT_BOLD,
        relief=tk.FLAT, padx=20, pady=4,
    ).pack(side=tk.LEFT, padx=5)

    dlg.protocol("WM_DELETE_WINDOW", dlg.destroy)
    dlg.grab_set()
    dlg.wait_window()
    return result[0]


class SaveDialog:

    def __init__(self, title: str, fields: list[dict], parent=None,
                 on_save=None):
        self.on_save = on_save
        self.dlg = tk.Toplevel(parent)
        self.dlg.title(title)
        self.dlg.configure(bg=BG_DARK)
        self.dlg.attributes("-topmost", True)
        self.dlg.resizable(False, False)

        self.widgets = {}
        y = 15
        for field in fields:
            key = field["key"]
            if field["type"] == "entry":
                tk.Label(
                    self.dlg, text=field["label"], bg=BG_DARK, fg=FG_COLOR,
                    font=FONT_DEFAULT,
                ).place(x=20, y=y)
                entry = tk.Entry(self.dlg, font=FONT_DEFAULT, width=25)
                entry.place(x=120, y=y, height=24)
                entry.insert(0, field.get("default", ""))
                self.widgets[key] = entry
            elif field["type"] == "check":
                var = tk.BooleanVar(value=field.get("default", False))
                cb = tk.Checkbutton(
                    self.dlg, text=field["label"], variable=var,
                    bg=BG_DARK, fg=FG_COLOR, font=FONT_DEFAULT,
                    selectcolor="#FFFFFF", activebackground=BG_DARK,
                )
                cb.place(x=20, y=y)
                self.widgets[key] = var
            y += 30

        btn_frame = tk.Frame(self.dlg, bg=BG_DARK)
        btn_frame.place(x=60, y=y + 5)

        tk.Button(
            btn_frame, text="Save", command=self._save,
            bg="#334433", fg=FG_WHITE, font=FONT_BOLD,
            relief=tk.FLAT, padx=20,
        ).pack(side=tk.LEFT, padx=5)

        tk.Button(
            btn_frame, text="Cancel", command=self.dlg.destroy,
            bg="#443333", fg=FG_WHITE, font=FONT_BOLD,
            relief=tk.FLAT, padx=20,
        ).pack(side=tk.LEFT, padx=5)

        self.dlg.geometry(f"320x{y + 50}")

    def _save(self):
        values = {}
        for key, widget in self.widgets.items():
            if isinstance(widget, tk.Entry):
                values[key] = widget.get()
            elif isinstance(widget, tk.BooleanVar):
                values[key] = widget.get()
        if self.on_save:
            self.on_save(values)
        self.dlg.destroy()
