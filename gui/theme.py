
import tkinter as tk
from tkinter import ttk

BG_COLOR = "#000000"
BG_DARK = "#1A1A1A"
FG_COLOR = "#DDDDDD"
FG_DIM = "#888888"
FG_ACCENT = "#FF4444"
FG_GREEN = "#00FF00"
FG_WHITE = "#FFFFFF"
FG_ITALIC_DIM = "#888888"

FONT_FAMILY = "Segoe UI"
FONT_DEFAULT = (FONT_FAMILY, 9)
FONT_BOLD = (FONT_FAMILY, 9, "bold")
FONT_SMALL = (FONT_FAMILY, 8)
FONT_SMALL_ITALIC = (FONT_FAMILY, 8, "italic")
FONT_SMALL_BOLD = (FONT_FAMILY, 8, "bold")
FONT_TITLE = (FONT_FAMILY, 10, "bold")
FONT_TINY = (FONT_FAMILY, 7)
FONT_ART = ("Consolas", 5, "bold")

CB_OPTS = dict(
    bg=BG_COLOR, fg=FG_COLOR, selectcolor="#000000",
    activebackground=BG_COLOR, activeforeground=FG_COLOR,
    highlightthickness=0, bd=0, font=FONT_DEFAULT, anchor="w",
)
CB_OPTS_NOLABEL = dict(
    bg=BG_COLOR, fg=FG_COLOR, selectcolor="#000000",
    activebackground=BG_COLOR, highlightthickness=0, bd=0, anchor="w",
)


class AHKCheckbox(tk.Frame):

    def __init__(self, parent, text="", variable=None, command=None,
                 font=(FONT_FAMILY, 10), fg=FG_COLOR, box_size=15,
                 bg=BG_COLOR, check_color=FG_COLOR, box_bg=BG_DARK,
                 box_border="#666666", **kwargs):
        super().__init__(parent, bg=bg, **kwargs)

        self.variable = variable if variable else tk.BooleanVar(value=False)
        self.command = command
        self.box_size = box_size
        self.check_color = check_color
        self.box_bg = box_bg
        self.box_border = box_border

        self.canvas = tk.Canvas(self, width=box_size + 2, height=box_size + 2,
                                bg=bg, highlightthickness=0, borderwidth=0)
        self.canvas.pack(side="left", padx=(0, 4))

        if text:
            self.label = tk.Label(self, text=text, bg=bg, fg=fg, font=font,
                                  anchor="w")
            self.label.pack(side="left", fill="x")
            self.label.bind("<Button-1>", self._on_click)

        self.canvas.bind("<Button-1>", self._on_click)
        self.bind("<Button-1>", self._on_click)

        self.variable.trace_add("write", lambda *a: self._draw())
        self._draw()

    def _draw(self):
        self.canvas.delete("all")
        s = self.box_size
        x, y = 1, 1
        self.canvas.create_rectangle(x, y, x + s, y + s,
                                     outline=self.box_border, fill=self.box_bg, width=1)
        if self.variable.get():
            mx = x + s * 0.25
            my = y + s * 0.55
            bx = x + s * 0.42
            by = y + s * 0.75
            ex = x + s * 0.78
            ey = y + s * 0.22
            self.canvas.create_line(mx, my, bx, by,
                                    fill=self.check_color, width=2, capstyle="round")
            self.canvas.create_line(bx, by, ex, ey,
                                    fill=self.check_color, width=2, capstyle="round")

    def _on_click(self, event=None):
        self.variable.set(not self.variable.get())
        if self.command:
            self.command()

    def select(self):
        self.variable.set(True)

    def deselect(self):
        self.variable.set(False)


def apply_theme(root: tk.Tk):
    root.configure(bg=BG_COLOR)

    style = ttk.Style(root)
    style.theme_use("default")

    style.configure("TNotebook", background=BG_COLOR, borderwidth=1,
                    padding=[0, 0])
    style.configure("TNotebook.Tab",
                    background=BG_COLOR, foreground=FG_ACCENT,
                    font=FONT_BOLD, padding=[6, 2],
                    borderwidth=1)
    style.map("TNotebook.Tab",
              background=[("selected", "#222222"), ("!selected", BG_COLOR)],
              foreground=[("selected", FG_ACCENT), ("!selected", "#7A2020")],
              lightcolor=[("selected", FG_ACCENT), ("!selected", "#7A2020")],
              darkcolor=[("selected", FG_ACCENT), ("!selected", "#7A2020")],
              bordercolor=[("selected", FG_ACCENT), ("!selected", "#7A2020")])
    style.layout("TNotebook", [("Notebook.client", {"sticky": "nswe"})])

    style.configure("TFrame", background=BG_COLOR)
    style.configure("Dark.TFrame", background=BG_DARK)

    style.configure("TLabel", background=BG_COLOR, foreground=FG_COLOR,
                    font=FONT_DEFAULT)
    style.configure("Dim.TLabel", foreground=FG_DIM, font=FONT_SMALL_ITALIC)
    style.configure("Accent.TLabel", foreground=FG_ACCENT, font=FONT_BOLD)
    style.configure("Green.TLabel", foreground=FG_GREEN, font=FONT_SMALL)
    style.configure("Title.TLabel", foreground=FG_ACCENT, font=FONT_TITLE)

    style.configure("TButton", font=FONT_DEFAULT, padding=[6, 2])
    style.configure("Accent.TButton", foreground=FG_ACCENT, font=FONT_BOLD)
    style.configure("Small.TButton", font=FONT_SMALL)

    # Checkbutton not styled via ttk — use tk.Checkbutton with CB_OPTS instead

    style.configure("TEntry", font=FONT_DEFAULT)

    style.configure("TCombobox", font=FONT_DEFAULT)

    style.configure("TSpinbox", font=FONT_DEFAULT)

    style.configure("TLabelframe", background=BG_COLOR, foreground=FG_COLOR)
    style.configure("TLabelframe.Label", background=BG_COLOR,
                    foreground=FG_ACCENT, font=FONT_BOLD)
