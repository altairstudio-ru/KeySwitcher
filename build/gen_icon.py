# -*- coding: utf-8 -*-
"""
Генератор иконки «AltaiR Key Switcher» (RU <-> EN).

Создаёт:
  icon.ico  — многоразмерная иконка (16/24/32/48/64/128/256 px),
              каждый кадр — PNG c альфа-каналом, упакованный вручную
              в формат ICO (ICONDIR + ICONDIRENTRY[] + PNG-данные).
  icon.png  — логотип 256px для окна «О программе».

Дизайн: на сине-градиентной плитке со скруглёнными углами буквы
«p» (латиница) и «п» (кириллица) — одинаковые знаки-глифы, набранные
не в той раскладке, — а между ними под буквами двунаправленная
стрелка-переключатель «RU <-> EN».
"""
import io
import math
import os
import struct

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_ICO = os.path.join(ROOT, "icon.ico")
OUT_PNG = os.path.join(ROOT, "icon.png")

SIZES = [16, 24, 32, 48, 64, 128, 256]

FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_FALLBACK = "C:/Windows/Fonts/arialbd.ttf"

# ---- Палитра -------------------------------------------------------
BG_TOP = (36, 64, 128)        # #244080
BG_BOTTOM = (64, 108, 233)    # #406CE9
LETTER_COLOR = (255, 255, 255, 255)
ARROW_MAIN = (255, 201, 60)   # #FFC93C
ARROW_OUTLINE = (20, 30, 66)  # #141E42
FRAME = (157, 182, 255)       # #9DB6FF


def lerp(a, b, t):
    return a + (b - a) * t


def load_font(px):
    path = FONT_BOLD if os.path.exists(FONT_BOLD) else FONT_FALLBACK
    return ImageFont.truetype(path, px)


def draw_arrow(d, p1, p2, width, fill, outline=None, ow=0.0):
    """Стрелка с круглой «головой»-треугольником; outline — обводка."""
    p1x, p1y = p1
    p2x, p2y = p2
    vx, vy = p2x - p1x, p2y - p1y
    L = math.hypot(vx, vy) or 1.0
    vx, vy = vx / L, vy / L
    px_, py_ = -vy, vx  # перпендикуляр

    hs = max(width * 2.4, width + 6.0) + 2 * ow   # длина головы
    hh = width * 0.95 + 2 * ow                     # полувысота головы

    def head(tip, hs_, hh_):
        bx, by = tip[0] - vx * hs_, tip[1] - vy * hs_
        return [
            (tip[0], tip[1]),
            (bx + px_ * hh_, by + py_ * hh_),
            (bx - px_ * hh_, by - py_ * hh_),
        ]

    shaft_color = outline if outline else fill
    shaft_w = int(width + 2 * ow) if outline else int(width)
    # хвост стрелки: рисуем чуть с запасом, голова перекроет конец
    d.line([p1, p2], fill=shaft_color, width=shaft_w)

    if outline:
        d.polygon(head(p2, hs + ow * 2, hh + ow * 2), fill=outline)
    d.polygon(head(p2, hs * 0.82, hh * 0.82), fill=fill)


def draw_icon(size):
    k = size / 256.0
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pad = 10 * k
    x0, y0, x1, y1 = pad, pad, size - pad, size - pad
    w, h = x1 - x0, y1 - y0
    radius = 54 * k

    # --- градиентный фон (слегка диагональный) ---
    grad = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for y in range(size):
        t = y / (size - 1)
        # лёгкий диагональный уклон: верх слева темнее, низ справа светлее
        r = int(lerp(BG_TOP[0], BG_BOTTOM[0], t))
        g = int(lerp(BG_TOP[1], BG_BOTTOM[1], t))
        b = int(lerp(BG_TOP[2], BG_BOTTOM[2], t))
        gd.line([(0, y), (size, y)], fill=(r, g, b, 255))

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=255)
    img.paste(grad, (0, 0), mask)

    # --- мягкий блик сверху ---
    gloss = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(gloss)
    gdraw.ellipse(
        [x0 - 30 * k, y0 - 70 * k, x1 + 30 * k, y0 + h * 0.62],
        fill=(255, 255, 255, 30),
    )
    gloss.putalpha(ImageChops.multiply(gloss.getchannel("A"), mask))
    img = Image.alpha_composite(img, gloss)

    # --- светлая рамка ---
    ImageDraw.Draw(img).rounded_rectangle(
        [x0, y0, x1, y1], radius=radius,
        outline=FRAME + (170,), width=max(1, int(3 * k)),
    )

    d = ImageDraw.Draw(img)

    # --- буквы «p» и «п» (одинаковые глифы: RU <-> EN) ---
    fs = int(106 * k)
    font = load_font(fs)
    cy = y0 + h * 0.42
    cx_l = x0 + w * 0.31
    cx_r = x0 + w * 0.69

    for ch, cx in (("p", cx_l), ("п", cx_r)):
        bbox = font.getbbox(ch)
        gw = bbox[2] - bbox[0]
        gh = bbox[3] - bbox[1]
        ox = cx - (bbox[0] + gw / 2)
        oy = cy - (bbox[1] + gh / 2)
        d.text((ox, oy), ch, font=font, fill=LETTER_COLOR)

    # --- двунаправленная стрелка-переключатель ---
    ax1 = x0 + w * 0.40
    ax2 = x0 + w * 0.60
    ay = y0 + h * 0.80
    aw = max(3.0, 8.5 * k)
    aow = max(1.5, 2.6 * k)
    gap = 5.5 * k

    # верхняя стрелка — вправо (EN -> RU)
    draw_arrow(d, (ax1, ay - gap), (ax2, ay - gap), aw, ARROW_MAIN, ARROW_OUTLINE, aow)
    # нижняя стрелка — влево (RU -> EN)
    draw_arrow(d, (ax2, ay + gap), (ax1, ay + gap), aw, ARROW_MAIN, ARROW_OUTLINE, aow)

    return img


def pack_ico(frames):
    """frames: list[(size, png_bytes)] -> байты .ico (кадры PNG с альфой)."""
    header = struct.pack("<HHH", 0, 1, len(frames))
    entries = b""
    offset = 6 + 16 * len(frames)
    for size, png in frames:
        dim = 0 if size >= 256 else size  # 256 кодируется как 0
        entries += struct.pack(
            "<BBBBHHII", dim, dim, 0, 0, 1, 32, len(png), offset
        )
        offset += len(png)
    return header + entries + b"".join(png for _, png in frames)


def main():
    frames = []
    logo = None
    for size in SIZES:
        img = draw_icon(size)
        if size == 256:
            logo = img
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        frames.append((size, buf.getvalue()))
        print(f"  кадр {size:3d}px готов ({len(buf.getvalue())} байт)")

    ico = pack_ico(frames)
    with open(OUT_ICO, "wb") as f:
        f.write(ico)
    print(f"icon.ico записан: {len(ico)} байт, кадров: {len(frames)}")

    logo.save(OUT_PNG, format="PNG")
    print(f"icon.png записан: {os.path.getsize(OUT_PNG)} байт")


if __name__ == "__main__":
    main()