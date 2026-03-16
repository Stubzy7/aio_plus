
import ctypes
import ctypes.wintypes as wt

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32

SRCCOPY = 0x00CC0020
PW_RENDERFULLCONTENT = 0x00000002
DIB_RGB_COLORS = 0


class WindowCapture:
    """Capture a window's contents to a memory DC for pixel reading."""

    def __init__(self, hwnd: int):
        self.hwnd = hwnd
        self.hdc_window = None
        self.hdc_mem = None
        self.hbmp = None
        self.old_bmp = None
        self.width = 0
        self.height = 0

    def capture(self) -> bool:
        """Capture the window contents. Returns True on success.

        Uses GetWindowDC + WinGetPos for dimensions,
        then PrintWindow with PW_RENDERFULLCONTENT (flag 2).
        """
        self.release()

        # Use WinGetPos (full window rect) for capture dimensions
        rect = wt.RECT()
        user32.GetWindowRect(self.hwnd, ctypes.byref(rect))
        self.width = rect.right - rect.left
        self.height = rect.bottom - rect.top

        if self.width <= 0 or self.height <= 0:
            return False

        # GetWindowDC for the full window including non-client area
        self.hdc_window = user32.GetWindowDC(self.hwnd)
        self.hdc_mem = gdi32.CreateCompatibleDC(self.hdc_window)
        self.hbmp = gdi32.CreateCompatibleBitmap(
            self.hdc_window, self.width, self.height
        )
        self.old_bmp = gdi32.SelectObject(self.hdc_mem, self.hbmp)

        # PrintWindow with flag 2 (PW_RENDERFULLCONTENT)
        result = user32.PrintWindow(self.hwnd, self.hdc_mem, PW_RENDERFULLCONTENT)
        if not result:
            # Fallback to BitBlt
            gdi32.BitBlt(
                self.hdc_mem, 0, 0, self.width, self.height,
                self.hdc_window, 0, 0, SRCCOPY,
            )

        return True

    def get_pixel(self, x: int, y: int) -> int:
        """Get pixel color from the captured image in 0xFFRRGGBB format.

        Returns color in 0xFFRRGGBB format from the captured DC.
        """
        if not self.hdc_mem:
            return 0
        bgr = gdi32.GetPixel(self.hdc_mem, x, y)
        if bgr == -1:
            return 0
        r = bgr & 0xFF
        g = (bgr >> 8) & 0xFF
        b = (bgr >> 16) & 0xFF
        return (0xFF << 24) | (r << 16) | (g << 8) | b

    def get_pixel_rgb(self, x: int, y: int) -> tuple[int, int, int]:
        """Get pixel as (R, G, B) tuple."""
        c = self.get_pixel(x, y)
        return ((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF)

    def release(self):
        """Free all GDI resources."""
        if self.old_bmp and self.hdc_mem:
            gdi32.SelectObject(self.hdc_mem, self.old_bmp)
            self.old_bmp = None
        if self.hbmp:
            gdi32.DeleteObject(self.hbmp)
            self.hbmp = None
        if self.hdc_mem:
            gdi32.DeleteDC(self.hdc_mem)
            self.hdc_mem = None
        if self.hdc_window:
            user32.ReleaseDC(self.hwnd, self.hdc_window)
            self.hdc_window = None

    def __del__(self):
        self.release()


# ---------------------------------------------------------------------------
#  Convenience functions (used by JoinSim)
# ---------------------------------------------------------------------------

def capture_window(hwnd: int) -> WindowCapture | None:
    """Capture a window and return the WindowCapture object, or None on failure."""
    wc = WindowCapture(hwnd)
    if wc.capture():
        return wc
    wc.release()
    return None


def get_pixel_argb(wc: WindowCapture, x: int, y: int) -> int:
    """Read a pixel from a captured window in 0xFFRRGGBB format."""
    return wc.get_pixel(x, y)


def release_capture(wc: WindowCapture):
    """Release all GDI resources for a captured window."""
    wc.release()
