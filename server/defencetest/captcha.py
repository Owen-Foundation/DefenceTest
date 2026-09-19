"""Self-hosted image captcha for the signup form.

Replaces Google reCAPTCHA (which needs per-domain site keys and phones home
to Google) with a zero-service challenge that works on any domain:

* ``GET /captcha.png`` renders a fresh 6-character raster image and stores
  the answer in the visitor's signed session cookie.
* ``POST /signup`` checks the typed answer against it, single-use, with a
  10-minute expiry.

The image is a real raster (rotated glyphs, sine-wave warp, interference
lines, speckle) — the answer exists nowhere in the markup, so bots need
actual OCR. Spam accounts additionally require manual approval of their
first runs, so this strength/cost trade-off is appropriate.
"""

from __future__ import annotations

import hmac
import io
import math
import random
import secrets
import time

from PIL import Image, ImageDraw, ImageFont

CODE_LENGTH = 6
# Unambiguous: no 0/O, 1/I/L.
CHARSET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
SESSION_KEY = "captcha"
TTL_SECONDS = 600
WIDTH, HEIGHT = 200, 72

_FONT_PATHS = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/Library/Fonts/Arial Bold.ttf",
)


def _font(size: int):
    for path in _FONT_PATHS:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default(size=size)


def new_code() -> str:
    return "".join(secrets.choice(CHARSET) for _ in range(CODE_LENGTH))


def issue(session) -> str:
    """Generate a code, store it in the session, return it for rendering."""
    code = new_code()
    session.data[SESSION_KEY] = {"code": code, "exp": time.time() + TTL_SECONDS}
    return code


def verify(session, answer: object) -> bool:
    """Single-use check of the typed answer (case-insensitive)."""
    entry = session.data.pop(SESSION_KEY, None)
    if not isinstance(entry, dict):
        return False
    code = entry.get("code")
    exp = entry.get("exp", 0)
    if not isinstance(code, str) or time.time() > float(exp or 0):
        return False
    if not isinstance(answer, str):
        return False
    return hmac.compare_digest(code.lower(), answer.strip().lower())


def render_png(code: str) -> bytes:
    """Render the code as a distorted raster PNG (cosmetic randomness only)."""
    rng = random.Random()
    img = Image.new("RGB", (WIDTH, HEIGHT), (238, 240, 246))
    draw = ImageDraw.Draw(img)

    # Interference arcs behind the text.
    for _ in range(3):
        x0, y0 = rng.uniform(-20, WIDTH), rng.uniform(-20, HEIGHT)
        x1, y1 = x0 + rng.uniform(60, 200), y0 + rng.uniform(30, 90)
        draw.arc(
            [x0, y0, x1, y1],
            start=rng.uniform(0, 360),
            end=rng.uniform(0, 360) + rng.uniform(90, 270),
            fill=rng.choice([(150, 160, 190), (170, 150, 170), (150, 175, 160)]),
            width=2,
        )

    # Glyphs: each on its own layer, rotated, then pasted with jitter.
    # Tight spacing lets neighbours touch, which breaks segmentation.
    step = WIDTH / (len(code) + 0.7)
    for i, ch in enumerate(code):
        size = int(rng.uniform(32, 40))
        font = _font(size)
        glyph = Image.new("RGBA", (size + 24, size + 28), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glyph)
        gd.text(
            (12, 10),
            ch,
            font=font,
            fill=rng.choice(
                [(20, 25, 60), (55, 35, 85), (15, 60, 50), (90, 25, 25)]
            ),
        )
        glyph = glyph.rotate(
            rng.uniform(-32, 32), resample=Image.BICUBIC, expand=True
        )
        x = int(step * (i + 1) - glyph.width / 2 + rng.uniform(-8, 8))
        y = int(HEIGHT / 2 - glyph.height / 2 + rng.uniform(-8, 8))
        img.paste(glyph, (x, y), glyph)

    # Sine-wave warp: shift each column vertically.
    amp = rng.uniform(4, 6)
    period = rng.uniform(35, 60)
    phase = rng.uniform(0, 2 * math.pi)
    warped = Image.new("RGB", (WIDTH, HEIGHT), (238, 240, 246))
    for x in range(WIDTH):
        dy = int(amp * math.sin(2 * math.pi * x / period + phase))
        warped.paste(img.crop((x, 0, x + 1, HEIGHT)), (x, dy))

    draw = ImageDraw.Draw(warped)
    # Strikethrough lines across the text.
    for _ in range(2):
        x0, y0 = rng.uniform(-10, 30), rng.uniform(10, HEIGHT - 10)
        x1, y1 = rng.uniform(WIDTH - 30, WIDTH + 10), rng.uniform(10, HEIGHT - 10)
        draw.line(
            [x0, y0, x1, y1],
            fill=rng.choice([(110, 120, 145), (130, 115, 135)]),
            width=2,
        )
    # Speckle dots on top.
    for _ in range(120):
        r = rng.uniform(0.7, 1.7)
        x, y = rng.uniform(0, WIDTH), rng.uniform(0, HEIGHT)
        draw.ellipse(
            [x - r, y - r, x + r, y + r],
            fill=rng.choice([(120, 130, 155), (90, 95, 120), (150, 140, 160)]),
        )

    buf = io.BytesIO()
    warped.save(buf, format="PNG")
    return buf.getvalue()
