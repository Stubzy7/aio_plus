
import tkinter as tk


def show_rect_overlay(x: int, y: int, w: int, h: int,
                      color: str = "red", border: int = 1) -> list[tk.Toplevel]:
    from core.state import state
    root = getattr(state, "root", None)
    if root is None:
        return []

    edges = []
    specs = [
        (x, y, w, border),           # top
        (x, y + h - border, w, border),  # bottom
        (x, y, border, h),           # left
        (x + w - border, y, border, h),  # right
    ]
    for ex, ey, ew, eh in specs:
        edge = tk.Toplevel(root)
        edge.overrideredirect(True)
        edge.attributes("-topmost", True)
        edge.attributes("-alpha", 0.8)
        edge.configure(bg=color)
        edge.geometry(f"{ew}x{eh}+{ex}+{ey}")
        edges.append(edge)

    return edges


def hide_rect_overlay(edges: list) -> None:
    if not edges:
        return
    for edge in edges:
        try:
            edge.destroy()
        except Exception:
            pass


destroy_overlay = hide_rect_overlay
