from PIL import ImageGrab

from . import window as _win


class WindowCapture:

    def __init__(self, image, x_offset: int, y_offset: int):
        self._image = image
        self._pixels = image.load() if image else None
        self._x_offset = x_offset
        self._y_offset = y_offset
        self.width = image.size[0] if image else 0
        self.height = image.size[1] if image else 0

    def get_pixel(self, x: int, y: int) -> int:
        if self._pixels is None:
            return 0
        if 0 <= x < self.width and 0 <= y < self.height:
            r, g, b = self._pixels[x, y][:3]
            return (r << 16) | (g << 8) | b
        return 0

    def get_pixel_rgb(self, x: int, y: int) -> tuple[int, int, int]:
        if self._pixels is None:
            return (0, 0, 0)
        if 0 <= x < self.width and 0 <= y < self.height:
            return self._pixels[x, y][:3]
        return (0, 0, 0)

    def release(self):
        self._image = None
        self._pixels = None


def capture_window(hwnd: int) -> WindowCapture | None:
    try:
        x, y, w, h = _win.win_get_pos(hwnd)
        if w <= 0 or h <= 0:
            return None
        image = ImageGrab.grab(bbox=(x, y, x + w, y + h))
        return WindowCapture(image, x, y)
    except Exception:
        return None


def get_pixel_argb(wc: WindowCapture, x: int, y: int) -> int:
    if wc is None:
        return 0
    rgb = wc.get_pixel(x, y)
    return 0xFF000000 | rgb


def release_capture(wc: WindowCapture):
    if wc is not None:
        wc.release()
