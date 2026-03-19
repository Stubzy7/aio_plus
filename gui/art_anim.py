
import math
import random
from PIL import Image, ImageDraw, ImageFont

from gui.art import _spiral_color, _GG_LINES, _GG_PIPES

# ── SETTINGS ────────────────────────────────────────────────
W, H = 175, 175
STEPS = 32
RADIUS = 85
SLIDE = 0.068
CX, CY = 75, 65
FPS = 30
SCALE = 2
BG = (0, 0, 0)
# ────────────────────────────────────────────────────────────


def _build_segments():
    a0 = math.pi / 2
    sx, sy, sr = CX * SCALE, CY * SCALE, RADIUS * SCALE
    p1x = sx + sr * math.cos(a0)
    p1y = sy + sr * math.sin(a0)
    p2x = sx + sr * math.cos(a0 + 2.0943951024)
    p2y = sy + sr * math.sin(a0 + 2.0943951024)
    p3x = sx + sr * math.cos(a0 + 4.1887902048)
    p3y = sy + sr * math.sin(a0 + 4.1887902048)

    segs = []
    for i in range(STEPS):
        frac = i / (STEPS - 1)
        alpha = max(3, min(255, int((1.0 - frac * 0.2) * 255)))
        pw = max(1, int(round(max(0.5, 2.0 - frac * 1.2) * SCALE)))
        color = _spiral_color(frac)
        r = color[0] * alpha // 255
        g = color[1] * alpha // 255
        b = color[2] * alpha // 255

        segs.append((p1x, p1y, p2x, p2y, (r, g, b), pw))
        segs.append((p2x, p2y, p3x, p3y, (r, g, b), pw))
        segs.append((p3x, p3y, p1x, p1y, (r, g, b), pw))

        n1x = p1x + SLIDE * (p2x - p1x)
        n1y = p1y + SLIDE * (p2y - p1y)
        n2x = p2x + SLIDE * (p3x - p2x)
        n2y = p2y + SLIDE * (p3y - p2y)
        n3x = p3x + SLIDE * (p1x - p3x)
        n3y = p3y + SLIDE * (p1y - p3y)
        p1x, p1y = n1x, n1y
        p2x, p2y = n2x, n2y
        p3x, p3y = n3x, n3y

    return segs


ALL_SEGS = _build_segments()
TOTAL = len(ALL_SEGS)


def _full_spiral():
    img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
    draw = ImageDraw.Draw(img)
    for idx in range(TOTAL):
        x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
        draw.line([(x1, y1), (x2, y2)], fill=color, width=pw)
    return img.resize((W, H), Image.LANCZOS)


def _lerp_color(base, mult):
    return (min(255, int(base[0] * mult)),
            min(255, int(base[1] * mult)),
            min(255, int(base[2] * mult)))


def _boost_color(base, mult):
    r = min(255, int(base[0] + (255 - base[0]) * max(0, mult - 1.0)))
    g = min(255, int(base[1] + (255 - base[1]) * max(0, mult - 1.0)))
    b = min(255, int(base[2] + (255 - base[2]) * max(0, mult - 1.0)))
    if mult <= 1.0:
        return _lerp_color(base, mult)
    return (r, g, b)


# ════════════════════════════════════════════════════════════
# Style 1
# ════════════════════════════════════════════════════════════
class Style1:
    WAVE_WIDTH = 8
    DIM = 0.15

    def __init__(self):
        self.wave_center = 0.0
        self.static = False

    def reset(self):
        self.wave_center = 0.0
        self.static = False

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self.wave_center += 0.5
            if self.wave_center > STEPS + self.WAVE_WIDTH:
                self.wave_center = -self.WAVE_WIDTH

    def render(self):
        if self.static:
            return _full_spiral()
        img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
        draw = ImageDraw.Draw(img)

        for idx in range(TOTAL):
            x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
            ring = idx // 3
            inner_ring = (STEPS - 1) - ring
            dist = abs(inner_ring - self.wave_center)

            if dist < self.WAVE_WIDTH:
                t = dist / self.WAVE_WIDTH
                b = 0.3 + 0.7 * (1.0 - t)
            else:
                b = self.DIM

            c = _lerp_color(color, b)
            draw.line([(x1, y1), (x2, y2)], fill=c, width=pw)

        return img.resize((W, H), Image.LANCZOS)


# ════════════════════════════════════════════════════════════
# Style 2
# ════════════════════════════════════════════════════════════
class Style2:
    DIM = 0.12
    SPARK_LEN = 4
    TRAIL_LEN = 14

    def __init__(self):
        self.pos = 0.0
        self.static = False

    def reset(self):
        self.pos = 0.0
        self.static = False

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self.pos = (self.pos + 1.5) % TOTAL

    def render(self):
        if self.static:
            return _full_spiral()
        img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
        draw = ImageDraw.Draw(img)
        head = int(self.pos)

        for idx in range(TOTAL):
            x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
            dist = (head - idx) % TOTAL

            if dist < self.SPARK_LEN:
                t = dist / self.SPARK_LEN
                c = _boost_color(color, 2.0 - t * 0.8)
            elif dist < self.SPARK_LEN + self.TRAIL_LEN:
                t = (dist - self.SPARK_LEN) / self.TRAIL_LEN
                brightness = 0.9 - t * (0.9 - self.DIM)
                c = _lerp_color(color, brightness)
            else:
                c = _lerp_color(color, self.DIM)

            draw.line([(x1, y1), (x2, y2)], fill=c, width=pw)

        return img.resize((W, H), Image.LANCZOS)


# ════════════════════════════════════════════════════════════
# Style 3
# ════════════════════════════════════════════════════════════
class Style3:
    BASE_DIM = 0.08

    def __init__(self):
        self.static = False
        self._phases = [random.uniform(0, math.tau) for _ in range(TOTAL)]
        self._speeds = [random.uniform(0.02, 0.08) for _ in range(TOTAL)]
        self._hot = set(random.sample(range(TOTAL), TOTAL // 4))
        self._hot_timer = 0

    def reset(self):
        self.static = False
        self._phases = [random.uniform(0, math.tau) for _ in range(TOTAL)]
        self._hot_timer = 0

    def trigger(self):
        self.static = True

    def tick(self):
        if self.static:
            return
        for i in range(TOTAL):
            self._phases[i] += self._speeds[i]

        self._hot_timer += 1
        if self._hot_timer > 15:
            self._hot_timer = 0
            if self._hot:
                for _ in range(3):
                    self._hot.discard(random.choice(list(self._hot)))
                    self._hot.add(random.randint(0, TOTAL - 1))

    def render(self):
        if self.static:
            return _full_spiral()
        img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
        draw = ImageDraw.Draw(img)

        for idx in range(TOTAL):
            x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
            wave = 0.5 + 0.5 * math.sin(self._phases[idx])
            if idx in self._hot:
                b = self.BASE_DIM + wave * 0.85
            else:
                b = self.BASE_DIM + wave * 0.25

            c = _lerp_color(color, b)
            draw.line([(x1, y1), (x2, y2)], fill=c, width=pw)

        return img.resize((W, H), Image.LANCZOS)


# ════════════════════════════════════════════════════════════
# Style 4
# ════════════════════════════════════════════════════════════
class Style4:
    SPARK_LEN = 3
    TRAIL_LEN = 10

    def __init__(self):
        self.static = False
        self.pos = 0.0
        self.charge = 0.0
        self.pass_count = 0
        self.total_passes = 5
        self._dimming = False

    def reset(self):
        self.static = False
        self.pos = 0.0
        self.charge = 0.0
        self.pass_count = 0
        self._dimming = False

    def trigger(self):
        self.static = True

    def tick(self):
        if self.static:
            return
        if self._dimming:
            self.charge -= 0.008
            if self.charge <= 0:
                self.charge = 0.0
                self._dimming = False
                self.pass_count = 0
            return

        self.pos += 2.0
        if self.pos >= TOTAL:
            self.pos -= TOTAL
            self.pass_count += 1
            self.charge = min(1.0, self.pass_count / self.total_passes)
            if self.pass_count >= self.total_passes:
                self._dimming = True

    def render(self):
        if self.static:
            return _full_spiral()
        img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
        draw = ImageDraw.Draw(img)
        head = int(self.pos)
        base_b = 0.05 + self.charge * 0.85

        for idx in range(TOTAL):
            x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
            dist = (head - idx) % TOTAL

            if not self._dimming and dist < self.SPARK_LEN:
                b = 2.0 - dist * 0.3
            elif not self._dimming and dist < self.SPARK_LEN + self.TRAIL_LEN:
                t = (dist - self.SPARK_LEN) / self.TRAIL_LEN
                b = max(base_b, 1.2 - t * 0.8)
            else:
                b = base_b

            c = _boost_color(color, b)
            draw.line([(x1, y1), (x2, y2)], fill=c, width=pw)

        return img.resize((W, H), Image.LANCZOS)


# ════════════════════════════════════════════════════════════
# Style 5
# ════════════════════════════════════════════════════════════
class Style5:
    DIM = 0.04
    HEAD_B = 1.6
    TRAIL_LEN = 60

    def __init__(self):
        self.pos = 0.0
        self.static = False

    def reset(self):
        self.pos = 0.0
        self.static = False

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self.pos = (self.pos + 0.8) % TOTAL

    def render(self):
        if self.static:
            return _full_spiral()
        img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
        draw = ImageDraw.Draw(img)
        head = int(self.pos)

        for idx in range(TOTAL):
            x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
            dist = (head - idx) % TOTAL

            if dist == 0:
                b = self.HEAD_B
            elif dist < 4:
                b = 1.2 - dist * 0.1
            elif dist < self.TRAIL_LEN:
                t = (dist - 4) / (self.TRAIL_LEN - 4)
                b = 0.7 * (1.0 - t * t)
                b = max(self.DIM, b)
            else:
                b = self.DIM

            c = _boost_color(color, b)
            draw.line([(x1, y1), (x2, y2)], fill=c, width=pw)

        return img.resize((W, H), Image.LANCZOS)


# ════════════════════════════════════════════════════════════
# Style 6
# ════════════════════════════════════════════════════════════
class Style6:
    DIM = 0.06
    FREQS = [0.25, 0.4, 0.63]
    SPEEDS = [0.04, 0.055, 0.033]

    def __init__(self):
        self.static = False
        self.frame = 0

    def reset(self):
        self.static = False
        self.frame = 0

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self.frame += 1

    def render(self):
        if self.static:
            return _full_spiral()
        img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
        draw = ImageDraw.Draw(img)

        for idx in range(TOTAL):
            x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
            ring = idx // 3

            total_wave = 0
            for freq, speed in zip(self.FREQS, self.SPEEDS):
                total_wave += math.sin(ring * freq + self.frame * speed)
            normalized = (total_wave + 3) / 6
            b = self.DIM + normalized * 0.75

            c = _lerp_color(color, b)
            draw.line([(x1, y1), (x2, y2)], fill=c, width=pw)

        return img.resize((W, H), Image.LANCZOS)


# ════════════════════════════════════════════════════════════
# Style 7
# ════════════════════════════════════════════════════════════
class Style7:
    DIM = 0.04
    READY_B = 0.6
    FLASH_B = 1.5
    FRAMES_PER_JOIN = 8
    HOLD_FRAMES = 40
    FLASH_FRAMES = 12

    def __init__(self):
        self.static = False
        self._joined = 0
        self._frame_in_step = 0
        self._phase = "joining"
        self._flash_frame = 0
        self._reset_wait = 0

    def reset(self):
        self.static = False
        self._joined = 0
        self._frame_in_step = 0
        self._phase = "joining"
        self._flash_frame = 0
        self._reset_wait = 0

    def trigger(self):
        self.static = True

    def tick(self):
        if self.static:
            return

        if self._phase == "joining":
            self._frame_in_step += 1
            if self._frame_in_step >= self.FRAMES_PER_JOIN:
                self._frame_in_step = 0
                self._joined += 1
                if self._joined >= STEPS:
                    self._phase = "flash"
                    self._flash_frame = 0
        elif self._phase == "flash":
            self._flash_frame += 1
            if self._flash_frame >= self.FLASH_FRAMES:
                self._phase = "hold"
                self._reset_wait = self.HOLD_FRAMES
        elif self._phase == "hold":
            self._reset_wait -= 1
            if self._reset_wait <= 0:
                self._phase = "reset"
                self._reset_wait = 15
        elif self._phase == "reset":
            self._reset_wait -= 1
            if self._reset_wait <= 0:
                self._joined = 0
                self._frame_in_step = 0
                self._phase = "joining"

    def render(self):
        if self.static:
            return _full_spiral()
        img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
        draw = ImageDraw.Draw(img)

        for idx in range(TOTAL):
            x1, y1, x2, y2, color, pw = ALL_SEGS[idx]
            ring = idx // 3

            if self._phase == "flash":
                t = self._flash_frame / self.FLASH_FRAMES
                b = self.FLASH_B * (1.0 - t) + self.READY_B * t
            elif self._phase == "hold":
                b = self.READY_B
            elif self._phase == "reset":
                t = 1.0 - self._reset_wait / 15
                b = self.READY_B * (1.0 - t) + self.DIM * t
            elif ring < self._joined:
                b = self.READY_B
            elif ring == self._joined:
                flash_t = self._frame_in_step / self.FRAMES_PER_JOIN
                if flash_t < 0.3:
                    b = self.FLASH_B * (flash_t / 0.3)
                else:
                    b = self.FLASH_B * (1.0 - (flash_t - 0.3) / 0.7) + self.READY_B * ((flash_t - 0.3) / 0.7)
            else:
                b = self.DIM

            c = _boost_color(color, b)
            draw.line([(x1, y1), (x2, y2)], fill=c, width=pw)

        return img.resize((W, H), Image.LANCZOS)


# ════════════════════════════════════════════════════════════
STYLES = [
    Style1, Style2, Style3, Style4,
    Style5, Style6, Style7,
]


# ════════════════════════════════════════════════════════════
# Animation Cycler — crossfades between styles in mood order
# ════════════════════════════════════════════════════════════
class AnimationCycler:
    MOOD_SEQ = [Style5, Style3, Style6, Style2, Style4, Style7]
    STYLE_TICKS = 750   # 25s at 30 FPS
    FADE_TICKS = 45     # 1.5s crossfade

    def __init__(self):
        self._idx = 0
        self._current = self.MOOD_SEQ[0]()
        self._next = None
        self._tick_count = 0
        self._fade_tick = 0
        self._fading = False
        self._static = False

    def reset(self):
        self._idx = 0
        self._current = self.MOOD_SEQ[0]()
        self._next = None
        self._tick_count = 0
        self._fade_tick = 0
        self._fading = False
        self._static = False

    def trigger(self):
        self._static = True

    def untrigger(self):
        self._static = False

    def tick(self):
        if self._static:
            return
        self._current.tick()
        self._tick_count += 1

        if self._fading:
            self._next.tick()
            self._fade_tick += 1
            if self._fade_tick >= self.FADE_TICKS:
                self._current = self._next
                self._next = None
                self._fading = False
                self._tick_count = 0
                self._fade_tick = 0
        elif self._tick_count >= self.STYLE_TICKS:
            self._idx = (self._idx + 1) % len(self.MOOD_SEQ)
            self._next = self.MOOD_SEQ[self._idx]()
            self._fading = True
            self._fade_tick = 0

    def render(self):
        if self._static:
            return _full_spiral()
        img_out = self._current.render()
        if self._fading and self._next is not None:
            img_in = self._next.render()
            alpha = self._fade_tick / self.FADE_TICKS
            return Image.blend(img_out, img_in, alpha)
        return img_out


# ════════════════════════════════════════════════════════════════════════════
# GG Art Animation
# ════════════════════════════════════════════════════════════════════════════

GG_W, GG_H = 210, 140
_GG_BMP_X, _GG_BMP_Y = 240, 268


def _gg_load_font():
    sz = 8 * SCALE
    try:
        return ImageFont.truetype("consolab.ttf", sz)
    except OSError:
        try:
            return ImageFont.truetype("consola.ttf", sz)
        except OSError:
            return ImageFont.load_default()


_GG_FONT = _gg_load_font()
_GG_CHAR_W = _GG_FONT.getlength("M")

_GG_CHARS = []
for _li, (_text, _gx, _gy, _color) in enumerate(_GG_LINES):
    _bx = (_gx - _GG_BMP_X) * SCALE
    _by = (_gy - _GG_BMP_Y) * SCALE
    for _ci, _ch in enumerate(_text):
        _GG_CHARS.append((_bx + _ci * _GG_CHAR_W, _by, _ch, _color, _li, _ci))

_pipe_ys = sorted(set(py for _, py, _ in _GG_PIPES))
_py_to_row = {y: i for i, y in enumerate(_pipe_ys)}
_GG_PIPE_LIST = []
for _px, _py, _color in _GG_PIPES:
    _GG_PIPE_LIST.append(((_px - _GG_BMP_X) * SCALE, (_py - _GG_BMP_Y) * SCALE,
                           _color, _py_to_row[_py]))

_GG_TOTAL_CHARS = len(_GG_CHARS)
_GG_TOTAL_PIPES = len(_GG_PIPE_LIST)
_GG_TOTAL = _GG_TOTAL_CHARS + _GG_TOTAL_PIPES

_tw_items = []
for _i, (_x, _y, _ch, _color, _li, _ci) in enumerate(_GG_CHARS):
    _tw_items.append((_y, _x, _i))
for _pi, (_x, _y, _color, _) in enumerate(_GG_PIPE_LIST):
    _tw_items.append((_y, _x, _GG_TOTAL_CHARS + _pi))
_tw_items.sort()
_GG_TW_ORDER = [idx for _, _, idx in _tw_items]
_GG_TW_REVEAL = [0] * _GG_TOTAL
for _rp, _gi in enumerate(_GG_TW_ORDER):
    _GG_TW_REVEAL[_gi] = _rp

_GG_POSITIONS = [(c[0], c[1]) for c in _GG_CHARS] + [(p[0], p[1]) for p in _GG_PIPE_LIST]
_GG_NEIGHBORS = []
for _i in range(_GG_TOTAL):
    _px, _py = _GG_POSITIONS[_i]
    _nbrs = []
    for _j in range(_GG_TOTAL):
        if _j != _i and abs(_px - _GG_POSITIONS[_j][0]) + abs(_py - _GG_POSITIONS[_j][1]) < _GG_CHAR_W * 4:
            _nbrs.append(_j)
    _GG_NEIGHBORS.append(_nbrs)


def _gg_brightness(color, mult):
    return tuple(min(255, max(0, int(c * mult))) for c in color)


def _gg_lerp_white(color, t):
    return tuple(min(255, int(c + (255 - c) * t)) for c in color)


def _gg_new_img():
    return Image.new("RGB", (GG_W * SCALE, GG_H * SCALE), BG)


def _gg_finalize(img):
    return img.resize((GG_W, GG_H), Image.LANCZOS)


def _gg_draw_all_lines(draw, line_mults=None):
    for li, (text, gx, gy, color) in enumerate(_GG_LINES):
        x = (gx - _GG_BMP_X) * SCALE
        y = (gy - _GG_BMP_Y) * SCALE
        m = line_mults[li] if line_mults else 1.0
        draw.text((x, y), text, fill=_gg_brightness(color, m), font=_GG_FONT)


def _gg_draw_all_pipes(draw, pipe_mults=None):
    for pi, (x, y, color, _) in enumerate(_GG_PIPE_LIST):
        m = pipe_mults[pi] if pipe_mults else 1.0
        draw.text((x, y), "|", fill=_gg_brightness(color, m), font=_GG_FONT)


def _gg_full():
    img = _gg_new_img()
    draw = ImageDraw.Draw(img)
    _gg_draw_all_lines(draw)
    _gg_draw_all_pipes(draw)
    return _gg_finalize(img)


class GGStyle1:

    def __init__(self):
        self._frame = 0
        self.static = False
        all_d = [c[0] + c[1] * 0.5 for c in _GG_CHARS] + \
                [p[0] + p[1] * 0.5 for p in _GG_PIPE_LIST]
        self._min_d = min(all_d)
        self._max_d = max(all_d)
        self._range = self._max_d - self._min_d

    def reset(self):
        self._frame = 0
        self.static = False

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self._frame += 1

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)

        SWEEP = 240
        HOLD = 45
        CYCLE = SWEEP + HOLD
        BAND_W = self._range * 0.18

        full_cycle = self._frame % (CYCLE * 2)
        reverse = full_cycle >= CYCLE
        phase = full_cycle % CYCLE
        if phase < SWEEP:
            t_sweep = phase / SWEEP
            if reverse:
                t_sweep = 1.0 - t_sweep
            band_pos = (self._min_d - BAND_W +
                        (self._range + 2 * BAND_W) * t_sweep)
        else:
            band_pos = -99999

        for x, y, ch, color, li, ci in _GG_CHARS:
            d = x + y * 0.5
            dist = abs(d - band_pos)
            if dist < BAND_W:
                t = 1.0 - dist / BAND_W
                c = _gg_lerp_white(color, t * 0.7)
            else:
                c = color
            draw.text((x, y), ch, fill=c, font=_GG_FONT)

        for x, y, color, _ in _GG_PIPE_LIST:
            d = x + y * 0.5
            dist = abs(d - band_pos)
            if dist < BAND_W:
                t = 1.0 - dist / BAND_W
                c = _gg_lerp_white(color, t * 0.7)
            else:
                c = color
            draw.text((x, y), "|", fill=c, font=_GG_FONT)

        return _gg_finalize(img)


class GGStyle2:

    def __init__(self):
        self._frame = 0
        self.static = False
        self._chars_per_frame = 3

    def reset(self):
        self._frame = 0
        self.static = False

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self._frame += 1

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)

        total_reveal_frames = _GG_TOTAL // self._chars_per_frame + 1
        HOLD = 75
        DARK_HOLD = 15
        cycle_frames = total_reveal_frames + HOLD + total_reveal_frames + DARK_HOLD
        phase = self._frame % cycle_frames

        if phase < total_reveal_frames:
            revealed = phase * self._chars_per_frame
            self._draw_typed(draw, revealed, False)
        elif phase < total_reveal_frames + HOLD:
            _gg_draw_all_lines(draw)
            _gg_draw_all_pipes(draw)
        elif phase < total_reveal_frames + HOLD + total_reveal_frames:
            dismiss_phase = phase - total_reveal_frames - HOLD
            dismissed = dismiss_phase * self._chars_per_frame
            self._draw_typed(draw, dismissed, True)

        return _gg_finalize(img)

    def _draw_typed(self, draw, count, reverse):
        for i, (x, y, ch, color, li, ci) in enumerate(_GG_CHARS):
            rpos = _GG_TW_REVEAL[i]
            if reverse:
                dpos = (_GG_TOTAL - 1) - rpos
                if dpos < count:
                    continue
                dist = dpos - count
                if dist < 6:
                    c = _gg_brightness(color, 1.0 + dist * 0.25)
                else:
                    c = color
            else:
                if rpos >= count:
                    continue
                age = count - rpos
                if age < 6:
                    c = _gg_brightness(color, 1.0 + (6 - age) * 0.25)
                else:
                    c = color
            draw.text((x, y), ch, fill=c, font=_GG_FONT)

        for pi, (x, y, color, _) in enumerate(_GG_PIPE_LIST):
            rpos = _GG_TW_REVEAL[_GG_TOTAL_CHARS + pi]
            if reverse:
                dpos = (_GG_TOTAL - 1) - rpos
                if dpos < count:
                    continue
                dist = dpos - count
                if dist < 6:
                    c = _gg_brightness(color, 1.0 + dist * 0.25)
                else:
                    c = color
            else:
                if rpos >= count:
                    continue
                age = count - rpos
                if age < 6:
                    c = _gg_brightness(color, 1.0 + (6 - age) * 0.25)
                else:
                    c = color
            draw.text((x, y), "|", fill=c, font=_GG_FONT)


class GGStyle3:

    def __init__(self):
        self._frame = 0
        self.static = False
        self._order = list(range(_GG_TOTAL))
        random.shuffle(self._order)
        self._reveal_at = [0] * _GG_TOTAL
        for rp, ei in enumerate(self._order):
            self._reveal_at[ei] = rp
        self._flicker_seed = [random.random() for _ in range(_GG_TOTAL)]

    def reset(self):
        self._frame = 0
        self.static = False
        random.shuffle(self._order)
        for rp, ei in enumerate(self._order):
            self._reveal_at[ei] = rp
        self._flicker_seed = [random.random() for _ in range(_GG_TOTAL)]

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self._frame += 1

    def _render_char(self, draw, idx, x, y, ch, color):
        REVEAL_FRAMES = 180
        HOLD = 75
        DISMISS_FRAMES = 180
        DARK_HOLD = 15
        CYCLE = REVEAL_FRAMES + HOLD + DISMISS_FRAMES + DARK_HOLD
        phase = self._frame % CYCLE
        elems_per_frame = _GG_TOTAL / REVEAL_FRAMES

        if phase < REVEAL_FRAMES:
            revealed = phase * elems_per_frame
            rpos = self._reveal_at[idx]
            if rpos >= revealed:
                return
            age = revealed - rpos
            if age < 12:
                seed = self._flicker_seed[idx]
                flicker = math.sin(age * 2.5 + seed * 20.0)
                if flicker < -0.3 and age < 8:
                    c = _gg_brightness(color, 0.15)
                else:
                    c = _gg_brightness(color, 1.0 + max(0, (8 - age) * 0.2))
            else:
                c = color
        elif phase < REVEAL_FRAMES + HOLD:
            c = color
        elif phase < REVEAL_FRAMES + HOLD + DISMISS_FRAMES:
            dismiss_phase = phase - REVEAL_FRAMES - HOLD
            dismissed = dismiss_phase * elems_per_frame
            rpos = self._reveal_at[idx]
            dismiss_pos = (_GG_TOTAL - 1) - rpos
            if dismiss_pos >= dismissed:
                c = color
            else:
                age = dismissed - dismiss_pos
                if age < 12:
                    seed = self._flicker_seed[idx]
                    flicker = math.sin(age * 2.5 + seed * 20.0)
                    if flicker < -0.3 and age < 8:
                        c = color
                    else:
                        c = _gg_brightness(color, max(0.0, 1.0 - age * 0.12))
                else:
                    return
        else:
            return

        draw.text((x, y), ch, fill=c, font=_GG_FONT)

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)
        for i, (x, y, ch, color, li, ci) in enumerate(_GG_CHARS):
            self._render_char(draw, i, x, y, ch, color)
        for pi, (x, y, color, _) in enumerate(_GG_PIPE_LIST):
            self._render_char(draw, _GG_TOTAL_CHARS + pi, x, y, "|", color)
        return _gg_finalize(img)


class GGStyle4:

    def __init__(self):
        self._frame = 0
        self.static = False
        all_d = [c[0] + c[1] for c in _GG_CHARS] + [p[0] + p[1] for p in _GG_PIPE_LIST]
        self._min_d = min(all_d)
        self._max_d = max(all_d)
        self._range = self._max_d - self._min_d
        self._surges = [
            {"speed": 3.5, "width": 0.12, "dir": 1.0, "phase": 0.0},
            {"speed": 2.8, "width": 0.15, "dir": -1.0, "phase": 80.0},
            {"speed": 4.2, "width": 0.10, "dir": 1.0, "phase": 200.0},
        ]

    def reset(self):
        self._frame = 0
        self.static = False

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self._frame += 1

    def _surge_mult(self, d):
        norm = (d - self._min_d) / self._range
        total_boost = 0.0
        for s in self._surges:
            wave_pos = ((self._frame * s["speed"] * s["dir"] + s["phase"])
                        % (self._range * 3)) / (self._range * 3)
            dist = abs(norm - wave_pos)
            dist = min(dist, 1.0 - dist)
            if dist < s["width"]:
                t = 1.0 - dist / s["width"]
                total_boost += t * 0.9
        return min(0.25 + total_boost, 2.2)

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)
        for x, y, ch, color, li, ci in _GG_CHARS:
            m = self._surge_mult(x + y)
            if m > 1.3:
                c = _gg_lerp_white(color, min(1.0, (m - 1.0) * 0.6))
            else:
                c = _gg_brightness(color, m)
            draw.text((x, y), ch, fill=c, font=_GG_FONT)
        for x, y, color, _ in _GG_PIPE_LIST:
            m = self._surge_mult(x + y)
            if m > 1.3:
                c = _gg_lerp_white(color, min(1.0, (m - 1.0) * 0.6))
            else:
                c = _gg_brightness(color, m)
            draw.text((x, y), "|", fill=c, font=_GG_FONT)
        return _gg_finalize(img)


class GGStyle5:
    NUM_SPARKS = 3
    SPARK_LIFE = 4

    def __init__(self):
        self._frame = 0
        self.static = False
        self._sparks = []

    def reset(self):
        self._frame = 0
        self.static = False
        self._sparks = []

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self._frame += 1
            self._sparks = [(idx, birth) for idx, birth in self._sparks
                            if self._frame - birth < self.SPARK_LIFE]
            while len(self._sparks) < self.NUM_SPARKS:
                self._sparks.append(
                    (random.randint(0, _GG_TOTAL - 1), self._frame))

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)
        spark_map = {}
        for idx, birth in self._sparks:
            age = self._frame - birth
            if idx not in spark_map or age < spark_map[idx]:
                spark_map[idx] = age
        for i, (x, y, ch, color, li, ci) in enumerate(_GG_CHARS):
            if i in spark_map:
                t = 1.0 - spark_map[i] / self.SPARK_LIFE
                c = _gg_lerp_white(color, t * 0.9)
            else:
                c = _gg_brightness(color, 0.6)
            draw.text((x, y), ch, fill=c, font=_GG_FONT)
        for pi, (x, y, color, _) in enumerate(_GG_PIPE_LIST):
            idx = _GG_TOTAL_CHARS + pi
            if idx in spark_map:
                t = 1.0 - spark_map[idx] / self.SPARK_LIFE
                c = _gg_lerp_white(color, t * 0.9)
            else:
                c = _gg_brightness(color, 0.6)
            draw.text((x, y), "|", fill=c, font=_GG_FONT)
        return _gg_finalize(img)


class GGStyle6:
    _SPREAD_RATE = 4.0
    _HOLD = 60
    _DARK_HOLD = 15

    def __init__(self):
        self._frame = 0
        self.static = False
        self._ignite_order = None
        self._last_cycle = -1
        self._build_ignition()

    def _build_ignition(self, start=None):
        if start is None:
            start = random.randint(0, _GG_TOTAL - 1)
        visited = [False] * _GG_TOTAL
        order = []
        queue = [start]
        visited[start] = True
        while queue:
            next_queue = []
            random.shuffle(queue)
            for idx in queue:
                order.append(idx)
                px, py = _GG_POSITIONS[idx]
                neighbors = []
                for j in range(_GG_TOTAL):
                    if not visited[j]:
                        nx, ny = _GG_POSITIONS[j]
                        if abs(px - nx) + abs(py - ny) < _GG_CHAR_W * 3:
                            neighbors.append(j)
                random.shuffle(neighbors)
                for n in neighbors[:4]:
                    if not visited[n]:
                        visited[n] = True
                        next_queue.append(n)
            queue = next_queue
        for i in range(_GG_TOTAL):
            if not visited[i]:
                order.append(i)
        self._ignite_order = [0] * _GG_TOTAL
        for pos, idx in enumerate(order):
            self._ignite_order[idx] = pos

    def reset(self):
        self._frame = 0
        self.static = False
        self._build_ignition()

    def trigger(self):
        self.static = True

    def _cycle_len(self):
        spread_frames = int(_GG_TOTAL / self._SPREAD_RATE) + 1
        return spread_frames + self._HOLD + spread_frames + self._DARK_HOLD

    def tick(self):
        if not self.static:
            self._frame += 1
            cur_cycle = self._frame // self._cycle_len()
            if cur_cycle != self._last_cycle:
                last_idx = max(range(_GG_TOTAL),
                               key=lambda i: self._ignite_order[i])
                self._build_ignition(start=last_idx)
                self._last_cycle = cur_cycle

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)

        spread_frames = int(_GG_TOTAL / self._SPREAD_RATE) + 1
        cycle = self._cycle_len()
        phase = self._frame % cycle

        if phase < spread_frames:
            ignited_count = phase * self._SPREAD_RATE
            self._draw_spread(draw, ignited_count, False)
        elif phase < spread_frames + self._HOLD:
            _gg_draw_all_lines(draw)
            _gg_draw_all_pipes(draw)
        elif phase < spread_frames + self._HOLD + spread_frames:
            dismiss_phase = phase - spread_frames - self._HOLD
            dismissed_count = dismiss_phase * self._SPREAD_RATE
            self._draw_spread(draw, dismissed_count, True)

        return _gg_finalize(img)

    def _draw_spread(self, draw, count, reverse):
        for i, (x, y, ch, color, li, ci) in enumerate(_GG_CHARS):
            ipos = self._ignite_order[i]
            if reverse:
                dismiss_pos = (_GG_TOTAL - 1) - ipos
                if dismiss_pos < count:
                    c = _gg_brightness(color, 0.04)
                else:
                    dist = dismiss_pos - count
                    if dist < 6:
                        c = _gg_lerp_white(color, (dist / 6) * 0.5)
                    else:
                        c = color
            else:
                if ipos >= count:
                    c = _gg_brightness(color, 0.04)
                else:
                    age = count - ipos
                    if age < 6:
                        c = _gg_lerp_white(color, ((6 - age) / 6) * 0.8)
                    else:
                        c = color
            draw.text((x, y), ch, fill=c, font=_GG_FONT)

        for pi, (x, y, color, _) in enumerate(_GG_PIPE_LIST):
            ipos = self._ignite_order[_GG_TOTAL_CHARS + pi]
            if reverse:
                dismiss_pos = (_GG_TOTAL - 1) - ipos
                if dismiss_pos < count:
                    c = _gg_brightness(color, 0.04)
                else:
                    dist = dismiss_pos - count
                    if dist < 6:
                        c = _gg_lerp_white(color, (dist / 6) * 0.5)
                    else:
                        c = color
            else:
                if ipos >= count:
                    c = _gg_brightness(color, 0.04)
                else:
                    age = count - ipos
                    if age < 6:
                        c = _gg_lerp_white(color, ((6 - age) / 6) * 0.8)
                    else:
                        c = color
            draw.text((x, y), "|", fill=c, font=_GG_FONT)


class GGStyle7:
    CHAIN_LEN = 12
    SPARK_LIFE = 3
    CHAINS = 2

    def __init__(self):
        self._frame = 0
        self.static = False
        self._chains = [[] for _ in range(self.CHAINS)]
        self._chain_step = [0] * self.CHAINS

    def reset(self):
        self._frame = 0
        self.static = False
        self._chains = [[] for _ in range(self.CHAINS)]
        self._chain_step = [0] * self.CHAINS

    def trigger(self):
        self.static = True

    def tick(self):
        if not self.static:
            self._frame += 1
            for ci in range(self.CHAINS):
                chain = self._chains[ci]
                self._chain_step[ci] += 1
                if self._chain_step[ci] >= self.SPARK_LIFE:
                    self._chain_step[ci] = 0
                    if not chain or len(chain) >= self.CHAIN_LEN:
                        self._chains[ci] = [(random.randint(0, _GG_TOTAL - 1), self._frame)]
                    else:
                        tip = chain[-1][0]
                        visited = {idx for idx, _ in chain}
                        candidates = [n for n in _GG_NEIGHBORS[tip] if n not in visited]
                        if candidates:
                            chain.append((random.choice(candidates), self._frame))
                        else:
                            self._chains[ci] = [(random.randint(0, _GG_TOTAL - 1), self._frame)]

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)
        spark_map = {}
        for chain in self._chains:
            clen = len(chain)
            for pos, (idx, _) in enumerate(chain):
                dist_from_tip = clen - 1 - pos
                if idx not in spark_map or dist_from_tip < spark_map[idx][0]:
                    spark_map[idx] = (dist_from_tip, clen)
        for i, (x, y, ch, color, li, ci) in enumerate(_GG_CHARS):
            if i in spark_map:
                dist, clen = spark_map[i]
                if dist == 0:
                    c = _gg_lerp_white(color, 0.9)
                else:
                    t = 1.0 - dist / max(clen, 1)
                    c = _gg_lerp_white(color, t * 0.5)
            else:
                c = _gg_brightness(color, 0.5)
            draw.text((x, y), ch, fill=c, font=_GG_FONT)
        for pi, (x, y, color, _) in enumerate(_GG_PIPE_LIST):
            idx = _GG_TOTAL_CHARS + pi
            if idx in spark_map:
                dist, clen = spark_map[idx]
                if dist == 0:
                    c = _gg_lerp_white(color, 0.9)
                else:
                    t = 1.0 - dist / max(clen, 1)
                    c = _gg_lerp_white(color, t * 0.5)
            else:
                c = _gg_brightness(color, 0.5)
            draw.text((x, y), "|", fill=c, font=_GG_FONT)
        return _gg_finalize(img)


class GGStyle8:
    CHAIN_LEN = 120
    SPARK_LIFE = 2
    CHAINS = 5
    HEAT_BOOST = 0.5
    HEAT_DECAY = 0.0015
    BURST_RADIUS = _GG_CHAR_W * 6
    BURST_LIFE = 12

    def __init__(self):
        self._frame = 0
        self.static = False
        self._chains = [[] for _ in range(self.CHAINS)]
        self._chain_step = [0] * self.CHAINS
        self._heat = [0.0] * _GG_TOTAL
        self._bursts = []

    def reset(self):
        self._frame = 0
        self.static = False
        self._chains = [[] for _ in range(self.CHAINS)]
        self._chain_step = [0] * self.CHAINS
        self._heat = [0.0] * _GG_TOTAL
        self._bursts = []

    def trigger(self):
        self.static = True

    def _check_collision(self):
        tips = []
        for ci, chain in enumerate(self._chains):
            if len(chain) > 3:
                tips.append((ci, chain[-1][0]))
        for a in range(len(tips)):
            for b in range(a + 1, len(tips)):
                ai, aidx = tips[a]
                bi, bidx = tips[b]
                ax, ay = _GG_POSITIONS[aidx]
                bx, by = _GG_POSITIONS[bidx]
                if abs(ax - bx) + abs(ay - by) < _GG_CHAR_W * 5:
                    mx, my = (ax + bx) / 2, (ay + by) / 2
                    self._bursts.append((mx, my, self._frame))
                    for i in range(_GG_TOTAL):
                        px, py = _GG_POSITIONS[i]
                        d = math.sqrt((px - mx) ** 2 + (py - my) ** 2)
                        if d < self.BURST_RADIUS:
                            boost = (1.0 - d / self.BURST_RADIUS) * 0.7
                            self._heat[i] = min(1.0, self._heat[i] + boost)
                    self._chains[ai] = [(random.randint(0, _GG_TOTAL - 1), self._frame)]
                    self._chains[bi] = [(random.randint(0, _GG_TOTAL - 1), self._frame)]
                    return

    def tick(self):
        if not self.static:
            self._frame += 1
            for i in range(_GG_TOTAL):
                if self._heat[i] > 0:
                    self._heat[i] = max(0.0, self._heat[i] - self.HEAT_DECAY)
            self._bursts = [(x, y, b) for x, y, b in self._bursts
                            if self._frame - b < self.BURST_LIFE]
            for ci in range(self.CHAINS):
                chain = self._chains[ci]
                self._chain_step[ci] += 1
                if self._chain_step[ci] >= self.SPARK_LIFE:
                    self._chain_step[ci] = 0
                    if not chain or len(chain) >= self.CHAIN_LEN:
                        start = random.randint(0, _GG_TOTAL - 1)
                        self._chains[ci] = [(start, self._frame)]
                        self._heat[start] = min(1.0, self._heat[start] + self.HEAT_BOOST)
                    else:
                        tip = chain[-1][0]
                        visited = {idx for idx, _ in chain}
                        candidates = [n for n in _GG_NEIGHBORS[tip] if n not in visited]
                        if candidates:
                            nxt = random.choice(candidates)
                            chain.append((nxt, self._frame))
                            self._heat[nxt] = min(1.0, self._heat[nxt] + self.HEAT_BOOST)
                        else:
                            start = random.randint(0, _GG_TOTAL - 1)
                            self._chains[ci] = [(start, self._frame)]
                            self._heat[start] = min(1.0, self._heat[start] + self.HEAT_BOOST)
            self._check_collision()

    def _burst_boost(self, x, y):
        total = 0.0
        for bx, by, birth in self._bursts:
            age = self._frame - birth
            d = math.sqrt((x - bx) ** 2 + (y - by) ** 2)
            ring_r = (age / self.BURST_LIFE) * self.BURST_RADIUS * 1.5
            ring_dist = abs(d - ring_r)
            ring_width = self.BURST_RADIUS * 0.3
            if ring_dist < ring_width:
                intensity = 1.0 - age / self.BURST_LIFE
                t = 1.0 - ring_dist / ring_width
                total += t * intensity * 0.9
            if age < 4 and d < self.BURST_RADIUS * 0.4:
                total += (1.0 - d / (self.BURST_RADIUS * 0.4)) * 0.7
        return min(total, 1.0)

    def render(self):
        if self.static:
            return _gg_full()
        img = _gg_new_img()
        draw = ImageDraw.Draw(img)
        spark_map = {}
        for chain in self._chains:
            clen = len(chain)
            for pos, (idx, _) in enumerate(chain):
                dist_from_tip = clen - 1 - pos
                if idx not in spark_map or dist_from_tip < spark_map[idx][0]:
                    spark_map[idx] = (dist_from_tip, clen)
        for i, (x, y, ch, color, li, ci) in enumerate(_GG_CHARS):
            heat = self._heat[i]
            burst = self._burst_boost(x, y)
            if burst > 0.05:
                c = _gg_lerp_white(color, burst)
            elif i in spark_map:
                dist, clen = spark_map[i]
                if dist == 0:
                    c = _gg_lerp_white(color, 0.9)
                else:
                    t = 1.0 - dist / max(clen, 1)
                    c = _gg_lerp_white(color, t * 0.55)
            else:
                c = _gg_brightness(color, 0.15 + heat * 0.7)
            draw.text((x, y), ch, fill=c, font=_GG_FONT)
        for pi, (x, y, color, _) in enumerate(_GG_PIPE_LIST):
            idx = _GG_TOTAL_CHARS + pi
            heat = self._heat[idx]
            burst = self._burst_boost(x, y)
            if burst > 0.05:
                c = _gg_lerp_white(color, burst)
            elif idx in spark_map:
                dist, clen = spark_map[idx]
                if dist == 0:
                    c = _gg_lerp_white(color, 0.9)
                else:
                    t = 1.0 - dist / max(clen, 1)
                    c = _gg_lerp_white(color, t * 0.55)
            else:
                c = _gg_brightness(color, 0.15 + heat * 0.7)
            draw.text((x, y), "|", fill=c, font=_GG_FONT)
        return _gg_finalize(img)


GG_STYLES = [
    GGStyle1, GGStyle2, GGStyle3, GGStyle4,
    GGStyle5, GGStyle6, GGStyle7, GGStyle8,
]

GG_MOOD_SEQ = [
    GGStyle1, GGStyle2, GGStyle3, GGStyle4,
    GGStyle5, GGStyle6, GGStyle7, GGStyle8,
]


class GGAnimationCycler:
    STYLE_TICKS = 750
    FADE_TICKS = 45

    def __init__(self):
        self._idx = 0
        self._current = GG_MOOD_SEQ[0]()
        self._next = None
        self._tick_count = 0
        self._fade_tick = 0
        self._fading = False
        self._static = False

    def reset(self):
        self._idx = 0
        self._current = GG_MOOD_SEQ[0]()
        self._next = None
        self._tick_count = 0
        self._fade_tick = 0
        self._fading = False
        self._static = False

    def trigger(self):
        self._static = True

    def untrigger(self):
        self._static = False

    def tick(self):
        if self._static:
            return
        self._current.tick()
        self._tick_count += 1

        if self._fading:
            self._next.tick()
            self._fade_tick += 1
            if self._fade_tick >= self.FADE_TICKS:
                self._current = self._next
                self._next = None
                self._fading = False
                self._tick_count = 0
                self._fade_tick = 0
        elif self._tick_count >= self.STYLE_TICKS:
            self._idx = (self._idx + 1) % len(GG_MOOD_SEQ)
            self._next = GG_MOOD_SEQ[self._idx]()
            self._fading = True
            self._fade_tick = 0

    @staticmethod
    def _ease(t):
        return t * t * (3.0 - 2.0 * t)

    def render(self):
        if self._static:
            return _gg_full()
        img_out = self._current.render()
        if self._fading and self._next is not None:
            img_in = self._next.render()
            alpha = self._ease(self._fade_tick / self.FADE_TICKS)
            return Image.blend(img_out, img_in, alpha)
        return img_out
