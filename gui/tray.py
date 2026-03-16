
import threading
try:
    from pystray import Icon, Menu, MenuItem
    from PIL import Image, ImageDraw
    PYSTRAY_AVAILABLE = True
except ImportError:
    PYSTRAY_AVAILABLE = False


class TrayManager:
    """Manage system tray icon and notifications."""

    def __init__(self, on_quit=None, on_show=None):
        self._icon = None
        self._on_quit = on_quit
        self._on_show = on_show
        self._thread = None

    def start(self):
        """Start the tray icon in a background thread."""
        if not PYSTRAY_AVAILABLE:
            return

        # Create a simple red/black icon
        img = Image.new("RGB", (64, 64), "#000000")
        draw = ImageDraw.Draw(img)
        draw.rectangle([8, 8, 56, 56], fill="#FF4444")
        draw.text((18, 18), "GG", fill="#FFFFFF")

        menu = Menu(
            MenuItem("Show", self._show_action, default=True),
            MenuItem("Quit", self._quit_action),
        )

        self._icon = Icon("GG AIO", img, "GG AIO", menu)
        self._thread = threading.Thread(target=self._icon.run, daemon=True)
        self._thread.start()

    def stop(self):
        """Stop the tray icon."""
        if self._icon:
            self._icon.stop()

    def notify(self, title: str, message: str):
        """Show a balloon notification."""
        if self._icon:
            self._icon.notify(message, title)

    def _show_action(self, icon=None, item=None):
        if self._on_show:
            self._on_show()

    def _quit_action(self, icon=None, item=None):
        if self._on_quit:
            self._on_quit()
