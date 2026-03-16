from pal import scaling as _s

BASE_WIDTH = 2560
BASE_HEIGHT = 1440

_s.set_dpi_aware()
screen_width, screen_height = _s.get_screen_size()

width_multiplier: float = screen_width / BASE_WIDTH
height_multiplier: float = screen_height / BASE_HEIGHT


def scale_x(base_x: float) -> int:
    return round(base_x * width_multiplier)


def scale_y(base_y: float) -> int:
    return round(base_y * height_multiplier)


def scale_w(base_w: float) -> int:
    return round(base_w * width_multiplier)


def scale_h(base_h: float) -> int:
    return round(base_h * height_multiplier)


def scale_game_x(fraction: float, game_width: int) -> int:
    return int(fraction * game_width)


def scale_game_y(fraction: float, game_height: int) -> int:
    return int(fraction * game_height)


def check_resolution():
    warnings = []
    standard = [(2560, 1440), (1920, 1080), (3840, 2160)]
    if (screen_width, screen_height) not in standard:
        warnings.append(
            f"Non-standard resolution ({screen_width}x{screen_height}) "
            "- running in scaled mode"
        )
    if round(screen_width / screen_height * 9) != 16:
        warnings.append(
            f"Non-16:9 aspect ratio ({screen_width}x{screen_height}) "
            "— pixel coordinates will be misaligned"
        )
    return warnings
