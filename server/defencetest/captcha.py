"""Self-hosted SVG captcha for the signup form.

Replaces Google reCAPTCHA (which needs per-domain site keys and phones home
to Google) with a zero-dependency challenge that works on any domain:

* ``GET /captcha.svg`` renders a fresh 5-character image and stores the
  answer in the visitor's signed session cookie.
* ``POST /signup`` checks the typed answer against it, single-use, with a
  10-minute expiry.

Spam accounts additionally require manual approval, so a simple
human-check here is the right strength/cost trade-off.
"""

from __future__ import annotations

import hmac
import random
import secrets
import time

CODE_LENGTH = 5
# Unambiguous: no 0/O, 1/I/L.
CHARSET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
SESSION_KEY = "captcha"
TTL_SECONDS = 600
WIDTH, HEIGHT = 170, 64


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


def render_svg(code: str) -> str:
    """Render the code as a distorted SVG (cosmetic randomness only)."""
    rng = random.Random()
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">',
        f'<rect width="{WIDTH}" height="{HEIGHT}" fill="#eef0f6"/>',
    ]
    # Noise lines behind the text.
    for _ in range(4):
        x1, y1 = rng.uniform(0, WIDTH), rng.uniform(0, HEIGHT)
        x2, y2 = rng.uniform(0, WIDTH), rng.uniform(0, HEIGHT)
        c = rng.choice(["#b9c2d9", "#9aa7c7", "#c9a0b8", "#93b8a4"])
        parts.append(
            f'<path d="M{x1:.0f},{y1:.0f} Q{rng.uniform(0, WIDTH):.0f},{rng.uniform(0, HEIGHT):.0f} '
            f'{x2:.0f},{y2:.0f}" stroke="{c}" stroke-width="1.6" fill="none"/>'
        )
    # Characters with jitter + rotation.
    step = WIDTH / (len(code) + 1)
    for i, ch in enumerate(code):
        x = step * (i + 1) + rng.uniform(-7, 7)
        y = HEIGHT / 2 + rng.uniform(8, 16)
        rot = rng.uniform(-24, 24)
        size = rng.uniform(30, 38)
        fill = rng.choice(["#1c2340", "#3b2a5e", "#0f3d33", "#5e1f1f"])
        parts.append(
            f'<text x="{x:.1f}" y="{y:.1f}" font-family="monospace, monospace" '
            f'font-size="{size:.0f}" font-weight="bold" fill="{fill}" '
            f'transform="rotate({rot:.1f} {x:.1f} {y:.1f})">{ch}</text>'
        )
    # Speckle dots on top.
    for _ in range(28):
        parts.append(
            f'<circle cx="{rng.uniform(0, WIDTH):.0f}" cy="{rng.uniform(0, HEIGHT):.0f}" '
            f'r="{rng.uniform(0.8, 1.8):.1f}" fill="#8a93ad"/>'
        )
    parts.append("</svg>")
    return "".join(parts)
