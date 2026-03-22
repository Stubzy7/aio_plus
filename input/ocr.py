
import asyncio
import io
from PIL import Image, ImageGrab, ImageFilter, ImageOps


def _capture_rect(x: int, y: int, w: int, h: int) -> Image.Image:
    return ImageGrab.grab(bbox=(x, y, x + w, y + h))


def _apply_transforms(img: Image.Image, scale: int = 1,
                      grayscale: bool = False, invert: bool = False,
                      monochrome: int = 0) -> Image.Image:
    if scale > 1:
        # NEAREST preserves sharp pixel edges which WinRT OCR reads more
        # reliably than LANCZOS smoothing on small game UI text.
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    if grayscale:
        img = img.convert("L").convert("RGB")
    if invert:
        img = ImageOps.invert(img.convert("RGB"))
    if monochrome > 0:
        gray = img.convert("L")
        img = gray.point(lambda p: 255 if p > monochrome else 0).convert("RGB")
    return img


_ocr_loop = None


def _get_ocr_loop():
    global _ocr_loop
    if _ocr_loop is None or _ocr_loop.is_closed():
        _ocr_loop = asyncio.new_event_loop()
    return _ocr_loop


def _run_ocr(img: Image.Image, lang: str = "en") -> str:
    try:
        import winocr

        async def _await_result():
            return await winocr.recognize_pil(img, lang)

        coro = _await_result()
        try:
            result = _get_ocr_loop().run_until_complete(coro)
        except Exception:
            coro.close()
            raise

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
    img = _capture_rect(x, y, w, h)
    img = _apply_transforms(img, scale, grayscale, invert, monochrome)
    return _run_ocr(img, lang)


def from_image(img: Image.Image, scale: int = 1, grayscale: bool = False,
               invert: bool = False, monochrome: int = 0,
               lang: str = "en") -> str:
    img = _apply_transforms(img, scale, grayscale, invert, monochrome)
    return _run_ocr(img, lang)
