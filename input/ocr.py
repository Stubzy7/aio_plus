
import asyncio
import io
from PIL import Image, ImageGrab, ImageFilter, ImageOps


def _capture_rect(x: int, y: int, w: int, h: int) -> Image.Image:
    """Capture a rectangle from the screen."""
    return ImageGrab.grab(bbox=(x, y, x + w, y + h))


def _apply_transforms(img: Image.Image, scale: int = 1,
                      grayscale: bool = False, invert: bool = False,
                      monochrome: int = 0) -> Image.Image:
    """Apply image transforms before OCR."""
    if scale > 1:
        # NEAREST (StretchBlt COLORONCOLOR equivalent) —
        # preserves sharp pixel edges which WinRT OCR reads more reliably
        # than LANCZOS anti-aliased smoothing on small game UI text.
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    if grayscale:
        img = img.convert("L").convert("RGB")
    if invert:
        img = ImageOps.invert(img.convert("RGB"))
    if monochrome > 0:
        gray = img.convert("L")
        img = gray.point(lambda p: 255 if p > monochrome else 0).convert("RGB")
    return img


_ocr_loop = None          # persistent event loop for winocr calls


def _get_ocr_loop():
    """Return a reusable asyncio event loop (avoids asyncio.run() overhead)."""
    global _ocr_loop
    if _ocr_loop is None or _ocr_loop.is_closed():
        _ocr_loop = asyncio.new_event_loop()
    return _ocr_loop


def _run_ocr(img: Image.Image, lang: str = "en") -> str:
    """Run winocr on a PIL image, resolving the WinRT async result."""
    try:
        import winocr

        async def _await_result():
            return await winocr.recognize_pil(img, lang)

        result = _get_ocr_loop().run_until_complete(_await_result())

        if result and hasattr(result, "text"):
            return result.text
        if isinstance(result, str):
            return result
        return str(result) if result else ""
    except ImportError:
        try:
            import pytesseract
            return pytesseract.image_to_string(img).strip()
        except ImportError:
            raise RuntimeError(
                "No OCR engine available. Install pytesseract: pip install pytesseract"
            )


def from_rect(x: int, y: int, w: int, h: int, scale: int = 1,
              grayscale: bool = False, invert: bool = False,
              monochrome: int = 0, lang: str = "en") -> str:
    """Capture a screen region and run OCR on it.

    Captures a screen rectangle and runs WinRT OCR on it.

    Args:
        x, y, w, h: Screen rectangle to capture.
        scale: Upscale factor for small text (2-3 recommended).
        grayscale: Convert to grayscale before OCR.
        invert: Invert colors before OCR.
        monochrome: Threshold for black/white conversion (0 = disabled).
        lang: OCR language code.

    Returns:
        Recognized text string.
    """
    img = _capture_rect(x, y, w, h)
    img = _apply_transforms(img, scale, grayscale, invert, monochrome)
    return _run_ocr(img, lang)


def from_image(img: Image.Image, scale: int = 1, grayscale: bool = False,
               invert: bool = False, monochrome: int = 0,
               lang: str = "en") -> str:
    """Run OCR on a PIL Image."""
    img = _apply_transforms(img, scale, grayscale, invert, monochrome)
    return _run_ocr(img, lang)
