"""
GG Art animation showcase — all 8 saved styles + cycler.
Run from aio_plus/:  python test_gg_anim.py

Press 1-9 to switch styles (9=cycler). S = trigger fill. R = reset. Space = pause. Esc = quit.
"""

import tkinter as tk
from PIL import ImageTk

from gui.art_anim import (
    GG_W, GG_H, FPS, GG_STYLES, GGAnimationCycler,
)


def main():
    root = tk.Tk()
    root.title("GG Art — All 8 Saved Styles")
    root.configure(bg="black")
    root.resizable(False, False)

    frame = tk.Frame(root, bg="black")
    frame.pack(padx=10, pady=10)

    title_lbl = tk.Label(frame, text="", fg="#FF4040", bg="black",
                         font=("Consolas", 11, "bold"))
    title_lbl.pack(pady=(0, 2))

    desc_lbl = tk.Label(frame, text="", fg="#AA4444", bg="black",
                        font=("Consolas", 9))
    desc_lbl.pack(pady=(0, 6))

    canvas = tk.Canvas(frame, width=GG_W, height=GG_H, bg="black",
                       highlightthickness=0)
    canvas.pack()

    status_lbl = tk.Label(frame, text="", fg="#888888", bg="black",
                          font=("Consolas", 8))
    status_lbl.pack(pady=(4, 0))

    info = tk.Label(root,
                    text="1-9=style (9=cycler)  S=fill  R=reset  Space=pause  Esc=quit",
                    fg="#666666", bg="black", font=("Consolas", 8))
    info.pack(pady=(0, 6))

    all_styles = GG_STYLES + [GGAnimationCycler]
    animators = [cls() for cls in all_styles]
    current = [0]
    paused = [False]
    photo_ref = [None]
    img_id = canvas.create_image(0, 0, anchor="nw")

    def switch_style(idx):
        current[0] = idx
        a = animators[idx]
        title_lbl.config(text=a.name)

    def tick():
        a = animators[current[0]]
        if not paused[0]:
            a.tick()
        img_pil = a.render()
        photo_ref[0] = ImageTk.PhotoImage(img_pil)
        canvas.itemconfig(img_id, image=photo_ref[0])

        st = "STATIC" if getattr(a, 'static', getattr(a, '_static', False)) else "animating"
        status_lbl.config(text=st)
        root.after(1000 // FPS, tick)

    def on_key(e):
        if e.char in "123456789":
            switch_style(int(e.char) - 1)
        elif e.char == "s":
            animators[current[0]].trigger()
        elif e.char == "r":
            animators[current[0]].reset()
        elif e.char == " ":
            paused[0] = not paused[0]

    root.bind("<Key>", on_key)
    root.bind("<Escape>", lambda e: root.destroy())

    switch_style(0)
    tick()
    root.mainloop()


if __name__ == "__main__":
    main()
