
import tkinter as tk
from gui.theme import BG_DARK, FG_COLOR, FONT_DEFAULT
from pal import gui_helpers as _gui


class TooltipManager:
    """Manage floating tooltip windows."""

    def __init__(self, root: tk.Tk):
        self.root = root
        self._tooltips: dict[int, tk.Toplevel] = {}

    def show(self, text: str, x: int | None = None, y: int | None = None,
             tooltip_id: int = 1):
        """Show a tooltip at screen coordinates.

        If x/y are None, shows near the cursor.
        """
        self.hide(tooltip_id)

        if not text:
            return

        tip = tk.Toplevel(self.root)
        tip.overrideredirect(True)
        tip.attributes("-topmost", True)
        tip.configure(bg=BG_DARK)

        label = tk.Label(tip, text=text, bg=BG_DARK, fg=FG_COLOR,
                         font=FONT_DEFAULT, justify=tk.LEFT, padx=6, pady=6)
        label.pack()
        # Force geometry update so the window sizes to fit all text
        tip.update_idletasks()

        # Prevent tooltip from stealing focus from fullscreen apps
        try:
            _gui.set_no_activate(tip.wm_frame())
        except Exception:
            pass

        if x is None or y is None:
            px, py = self.root.winfo_pointerxy()
            x = x if x is not None else px + 16
            y = y if y is not None else py + 16

        tip.geometry(f"+{x}+{y}")
        self._tooltips[tooltip_id] = tip

    def hide(self, tooltip_id: int = 1):
        """Hide and destroy a tooltip by ID."""
        tip = self._tooltips.pop(tooltip_id, None)
        if tip:
            try:
                tip.destroy()
            except tk.TclError:
                pass

    def hide_all(self):
        """Hide all tooltips."""
        for tid in list(self._tooltips.keys()):
            self.hide(tid)

    def temp(self, text: str, duration_ms: int = 2000,
             x: int | None = None, y: int | None = None,
             tooltip_id: int = 1):
        """Show a tooltip that auto-hides after duration_ms."""
        self.show(text, x, y, tooltip_id)
        self.root.after(duration_ms, lambda: self.hide(tooltip_id))

    def update_text(self, text: str, tooltip_id: int = 1,
                    x: int = 0, y: int = 0):
        """Update the text of an existing tooltip without destroy/recreate.

        Falls back to show() at (x, y) if no tooltip exists yet.
        """
        tip = self._tooltips.get(tooltip_id)
        if tip:
            for child in tip.winfo_children():
                if isinstance(child, tk.Label):
                    child.configure(text=text)
                    break
        else:
            self.show(text, x, y, tooltip_id)


# ---------------------------------------------------------------------------
#  Module-level convenience functions
# ---------------------------------------------------------------------------
# Many modules do ``from gui.tooltip import show_tooltip, hide_tooltip``.
# These delegate to the singleton TooltipManager stored on state.

def show_tooltip(text: str, x: int = 0, y: int = 0,
                 tooltip_id: int = 1):
    """Show a tooltip via the global TooltipManager.

    Default position is (0, 0) — top-left of screen.
    """
    from core.state import state
    root = getattr(state, "root", None)
    if root is None:
        return
    tm = getattr(state, "_tooltip_mgr", None)
    if tm is None:
        return
    # Marshal to main thread
    root.after(0, lambda: tm.show(text, x, y, tooltip_id))


def update_tooltip(text: str, tooltip_id: int = 1,
                   x: int = 0, y: int = 0):
    """Update text of an existing tooltip (no destroy/recreate). Falls back to show at (x,y)."""
    from core.state import state
    root = getattr(state, "root", None)
    if root is None:
        return
    tm = getattr(state, "_tooltip_mgr", None)
    if tm is None:
        return
    root.after(0, lambda: tm.update_text(text, tooltip_id, x, y))


def hide_tooltip(tooltip_id: int = 1):
    """Hide a tooltip via the global TooltipManager."""
    from core.state import state
    root = getattr(state, "root", None)
    if root is None:
        return
    tm = getattr(state, "_tooltip_mgr", None)
    if tm is None:
        return
    root.after(0, lambda: tm.hide(tooltip_id))


def temp_tooltip(text: str, duration_ms: int = 2000,
                 x: int = 0, y: int = 0, tooltip_id: int = 1):
    """Show a tooltip that auto-hides after duration_ms."""
    from core.state import state
    root = getattr(state, "root", None)
    if root is None:
        return
    tm = getattr(state, "_tooltip_mgr", None)
    if tm is None:
        return
    root.after(0, lambda: tm.temp(text, duration_ms, x, y, tooltip_id))
