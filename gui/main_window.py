
import tkinter as tk
from tkinter import ttk
from gui.theme import (
    apply_theme, BG_COLOR, FG_DIM, FG_ACCENT, FG_COLOR,
    FONT_SMALL, FONT_SMALL_ITALIC, FONT_DEFAULT,
)
from core.scaling import screen_width, screen_height
from pal import gui_helpers as _gui
from input.mouse import set_cursor_pos


class MainWindow:

    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("GG AIO")
        self.root.configure(bg=BG_COLOR)
        self.root.attributes("-topmost", True)
        self.root.resizable(False, False)
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self.root.geometry("450x452+177+330")
        self.root.configure(padx=0, pady=0)

        apply_theme(self.root)

        self.notebook = ttk.Notebook(self.root, width=450, height=408)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=0, pady=0)

        self.tab_frames: dict[str, ttk.Frame] = {}
        self.tab_names = [
            "JoinSim", "Magic F", "AutoLvL", "Popcorn",
            "Sheep", "Craft", "Macro", "Misc",
        ]
        for name in self.tab_names:
            frame = ttk.Frame(self.notebook, style="TFrame")
            self.notebook.add(frame, text=name)
            self.tab_frames[name] = frame

        self.notebook.bind("<<NotebookTabChanged>>", self._on_tab_change)

        self.root.bind("<Control-Tab>", self._next_tab)
        self.root.bind("<Control-Shift-Tab>", self._prev_tab)
        # Bind on notebook too to prevent default traversal focusing sub-widgets
        self.notebook.bind("<Control-Tab>", self._next_tab)
        self.notebook.bind("<Control-Shift-Tab>", self._prev_tab)

        status_frame = tk.Frame(self.root, bg=BG_COLOR, height=24)
        status_frame.pack(fill=tk.X, side=tk.BOTTOM)

        tk.Label(
            status_frame, text=f"Resolution: {screen_width}x{screen_height}",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL,
        ).place(x=10, y=2)

        tk.Label(
            status_frame, text="Ctrl+Tab = tabs",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC,
        ).place(x=140, y=2)

        tk.Label(
            status_frame, text="F4 = Exit",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL_ITALIC,
        ).place(x=240, y=2)

        self.app_select_label = tk.Label(
            status_frame, text="ArkAscended",
            bg=BG_COLOR, fg=FG_DIM, font=FONT_SMALL, anchor=tk.E,
        )
        self.app_select_label.place(x=320, y=2, width=120)

        self._tab_builders: dict[str, object] = {}
        self._on_tab_change_callback = None

    def set_tab_change_callback(self, callback):
        self._on_tab_change_callback = callback

    def get_current_tab(self) -> str:
        idx = self.notebook.index(self.notebook.select())
        return self.tab_names[idx]

    def select_tab(self, name: str):
        if name in self.tab_frames:
            idx = self.tab_names.index(name)
            self.notebook.select(idx)

    def _next_tab(self, event=None):
        idx = self.notebook.index(self.notebook.select())
        idx = (idx + 1) % len(self.tab_names)
        self.notebook.select(idx)
        return "break"

    def _prev_tab(self, event=None):
        idx = self.notebook.index(self.notebook.select())
        idx = (idx - 1) % len(self.tab_names)
        self.notebook.select(idx)
        return "break"

    def _on_tab_change(self, event=None):
        tab_name = self.get_current_tab()
        if self._on_tab_change_callback:
            self._on_tab_change_callback(tab_name)

    def _on_close(self):
        self.root.quit()
        self.root.destroy()

    def show(self):
        self.root.deiconify()
        self.root.geometry("450x452+177+330")
        self.root.attributes("-topmost", True)

        try:
            hwnd = int(self.root.wm_frame(), 16)
        except Exception:
            hwnd = 0

        if hwnd:
            _gui.flash_activate(hwnd)

        self.root.after(50, lambda: set_cursor_pos(177 + 225, 330 + 204))

    def show_passive(self):
        # Show without stealing focus so ARK keeps input focus
        self.root.deiconify()
        self.root.geometry("450x452+177+330")
        self.root.attributes("-topmost", True)

    def hide(self):
        self.root.withdraw()

    def toggle_visibility(self):
        if self.root.state() == "withdrawn":
            self.show()
        else:
            self.hide()
