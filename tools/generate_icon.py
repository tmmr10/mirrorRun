#!/usr/bin/env python3
"""Generate Mirror Runners app icon — matching in-game style."""

from PIL import Image, ImageDraw, ImageFilter
import math
import os
import random

SIZE = 1024
CX = SIZE // 2
CY = SIZE // 2


def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def draw_icon():
    img = Image.new('RGBA', (SIZE, SIZE), (8, 8, 16, 255))

    # === Background: menu-style dark gradient ===
    # Menu uses: 0F0a0a0f → 0F080812 → 0F0f0a14
    bg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    for y in range(SIZE):
        for x in range(SIZE):
            xt = x / SIZE
            yt = y / SIZE
            # Diagonal gradient matching menu
            t = (xt + yt) / 2
            c1 = (10, 10, 15)  # top-left
            c2 = (8, 8, 18)    # middle
            c3 = (15, 10, 20)  # bottom-right
            if t < 0.5:
                c = lerp_color(c1, c2, t * 2)
            else:
                c = lerp_color(c2, c3, (t - 0.5) * 2)
            bg.putpixel((x, y), (*c, 255))
    img = Image.alpha_composite(img, bg)

    # === Mirror line — matching in-game MirrorLine style ===
    # In-game: 6px wide gradient: transparent #A082FF → bright #D2BEFF → transparent #A082FF
    # Plus pulsing white center. Wide soft glow.
    line_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line_layer)

    # Extra wide soft glow
    glow_color = (160, 130, 255)  # #A082FF
    for offset in range(-120, 121):
        dist = abs(offset) / 120
        alpha = int(40 * math.exp(-2 * dist * dist))
        ld.line([(CX + offset, 0), (CX + offset, SIZE)],
                fill=(*glow_color, alpha), width=1)

    # Medium glow
    bright_color = (210, 190, 255)  # #D2BEFF
    for offset in range(-30, 31):
        dist = abs(offset) / 30
        alpha = int(120 * math.exp(-2 * dist * dist))
        ld.line([(CX + offset, 0), (CX + offset, SIZE)],
                fill=(*bright_color, alpha), width=1)

    # Hot core
    for offset in range(-6, 7):
        dist = abs(offset) / 6
        alpha = int(220 * (1 - dist))
        ld.line([(CX + offset, 0), (CX + offset, SIZE)],
                fill=(230, 220, 255, alpha), width=1)

    # Bright center line
    ld.line([(CX, 0), (CX, SIZE)], fill=(255, 255, 255, 60), width=2)

    # Shimmer hotspot (larger, brighter)
    shimmer_cy = int(SIZE * 0.4)
    for dy in range(-180, 181):
        dist = abs(dy) / 180
        alpha = int(100 * math.exp(-2 * dist * dist))
        for dx in range(-50, 51):
            dx_dist = abs(dx) / 50
            a = int(alpha * math.exp(-2.5 * dx_dist * dx_dist))
            if a > 0:
                ld.point((CX + dx, shimmer_cy + dy), fill=(230, 215, 255, a))

    # Second shimmer lower
    shimmer_cy2 = int(SIZE * 0.72)
    for dy in range(-130, 131):
        dist = abs(dy) / 130
        alpha = int(65 * math.exp(-2 * dist * dist))
        for dx in range(-35, 36):
            dx_dist = abs(dx) / 35
            a = int(alpha * math.exp(-2.5 * dx_dist * dx_dist))
            if a > 0:
                ld.point((CX + dx, shimmer_cy2 + dy), fill=(*bright_color, a))

    img = Image.alpha_composite(img, line_layer)

    # === Ambient glow behind each player ===
    for (gcx, gc) in [(CX - 175, (255, 107, 53)), (CX + 175, (153, 102, 255))]:
        amb = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        ad = ImageDraw.Draw(amb)
        for r in range(280, 0, -3):
            a = int(14 * (1 - r / 280) ** 0.5)
            ad.ellipse([gcx - r, CY - 10 - r, gcx + r, CY - 10 + r], fill=(*gc, a))
        img = Image.alpha_composite(img, amb)

    # === Ground line (matching in-game: colored per side) ===
    ground_y = CY + 180
    ground = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ground)
    # Ground glow
    for offset in range(-4, 5):
        a = int(20 * (1 - abs(offset) / 5))
        gd.line([(80, ground_y + offset), (SIZE - 80, ground_y + offset)],
                fill=(160, 130, 255, a), width=1)
    # Left: orange line (like biome.lineL)
    gd.line([(80, ground_y), (CX, ground_y)], fill=(42, 106, 42, 120), width=2)
    # Right: blue-purple line (like biome.lineR)
    gd.line([(CX, ground_y), (SIZE - 80, ground_y)], fill=(42, 42, 106, 120), width=2)
    img = Image.alpha_composite(img, ground)

    # === Small obstacles falling from top ===
    obs_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(obs_layer)

    def draw_obstacle(ox, oy, ow, oh, color, glow_col):
        # Soft glow
        for r in range(14, 0, -1):
            a = int(18 * (1 - r / 14))
            od.rounded_rectangle([ox - r, oy - r, ox + ow + r, oy + oh + r],
                                 radius=6, fill=(*glow_col, a))
        od.rounded_rectangle([ox, oy, ox + ow, oy + oh], radius=5, fill=color)

    # Left obstacles (green-ish like forest biome obsL: #2d8c3a)
    draw_obstacle(CX - 290, 130, 48, 56, (45, 140, 58, 200), (45, 140, 58))
    draw_obstacle(CX - 130, 340, 48, 56, (45, 140, 58, 200), (45, 140, 58))
    # Right obstacles (blue-ish like forest biome obsR: #2d3a8c)
    draw_obstacle(CX + 95, 210, 48, 56, (45, 58, 140, 200), (45, 58, 140))
    draw_obstacle(CX + 240, 430, 48, 56, (45, 58, 140, 200), (45, 58, 140))
    img = Image.alpha_composite(img, obs_layer)

    # === Players (in-game: rounded rect + glow + eyes) ===
    def draw_player(cx, cy, pw, ph, color, glow_color, corner_r):
        nonlocal img

        # Wide glow (matching in-game maskFilter blur, extra strong)
        glow_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        gd_p = ImageDraw.Draw(glow_layer)
        # Outer soft glow
        gd_p.rounded_rectangle(
            [cx - pw // 2 - 40, cy - ph // 2 - 40, cx + pw // 2 + 40, cy + ph // 2 + 40],
            radius=corner_r + 30,
            fill=(*glow_color[:3], 50)
        )
        # Inner bright glow
        gd_p.rounded_rectangle(
            [cx - pw // 2 - 14, cy - ph // 2 - 14, cx + pw // 2 + 14, cy + ph // 2 + 14],
            radius=corner_r + 8,
            fill=glow_color
        )
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=35))
        img = Image.alpha_composite(img, glow_layer)

        # Trail (fading copies below, like in-game _trail)
        trail_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        td = ImageDraw.Draw(trail_layer)
        for i in range(6):
            a = int(30 * (1 - i / 6) ** 1.5)
            offset_y = (i + 1) * 16
            td.rounded_rectangle(
                [cx - pw // 2 + 4, cy - ph // 2 + offset_y + 4,
                 cx + pw // 2 - 4, cy + ph // 2 + offset_y - 4],
                radius=corner_r - 2,
                fill=(*color[:3], a)
            )
        img = Image.alpha_composite(img, trail_layer)

        # Solid body
        body_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        bd = ImageDraw.Draw(body_layer)
        bd.rounded_rectangle(
            [cx - pw // 2, cy - ph // 2, cx + pw // 2, cy + ph // 2],
            radius=corner_r,
            fill=color
        )

        # Eyes (matching in-game: dark circles at 30% from top)
        eye_y = cy - ph // 2 + int(ph * 0.3)
        eye_spacing = int(pw * 0.17)
        eye_r = int(pw * 0.07)
        bd.ellipse([cx - eye_spacing - eye_r, eye_y - eye_r,
                     cx - eye_spacing + eye_r, eye_y + eye_r],
                    fill=(0, 0, 0, 128))
        bd.ellipse([cx + eye_spacing - eye_r, eye_y - eye_r,
                     cx + eye_spacing + eye_r, eye_y + eye_r],
                    fill=(0, 0, 0, 128))

        img = Image.alpha_composite(img, body_layer)

    pw = 120
    ph = 170
    corner = 35

    # Left player (orange — #ff6b35)
    draw_player(CX - 175, CY - 10, pw, ph,
                (255, 107, 53, 255), (255, 107, 53, 100), corner)
    # Right player (purple — #9966ff)
    draw_player(CX + 175, CY - 10, pw, ph,
                (153, 102, 255, 255), (153, 102, 255, 100), corner)

    # === Lane guides (very subtle, like in-game 0x0AFFFFFF) ===
    lanes_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    lnd = ImageDraw.Draw(lanes_layer)
    # 3 left lanes, 3 right lanes (approximate positions scaled to icon)
    for lx in [CX - 280, CX - 175, CX - 70, CX + 70, CX + 175, CX + 280]:
        lnd.line([(lx, 60), (lx, SIZE - 60)], fill=(255, 255, 255, 8), width=1)
    img = Image.alpha_composite(img, lanes_layer)

    return img


def save_ios_icons(img):
    base = "/Users/tmaier/mirror_run/ios/Runner/Assets.xcassets/AppIcon.appiconset"
    sizes = {
        "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60, "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120, "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180, "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152, "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, px in sizes.items():
        resized = img.resize((px, px), Image.LANCZOS)
        rgb = Image.new('RGB', (px, px), (10, 10, 15))
        rgb.paste(resized, mask=resized.split()[3])
        rgb.save(os.path.join(base, filename), 'PNG')
    print(f"  iOS: {len(sizes)} icons saved")


def save_android_icons(img):
    base = "/Users/tmaier/mirror_run/android/app/src/main/res"
    sizes = {"mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
             "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192}
    for folder, px in sizes.items():
        resized = img.resize((px, px), Image.LANCZOS)
        rgb = Image.new('RGB', (px, px), (10, 10, 15))
        rgb.paste(resized, mask=resized.split()[3])
        rgb.save(os.path.join(base, folder, "ic_launcher.png"), 'PNG')
    print(f"  Android: {len(sizes)} icons saved")


def save_macos_icons(img):
    base = "/Users/tmaier/mirror_run/macos/Runner/Assets.xcassets/AppIcon.appiconset"
    if not os.path.exists(base):
        return
    sizes = {"app_icon_16.png": 16, "app_icon_32.png": 32, "app_icon_64.png": 64,
             "app_icon_128.png": 128, "app_icon_256.png": 256, "app_icon_512.png": 512,
             "app_icon_1024.png": 1024}
    for filename, px in sizes.items():
        resized = img.resize((px, px), Image.LANCZOS)
        resized.save(os.path.join(base, filename), 'PNG')
    print(f"  macOS: {len(sizes)} icons saved")


if __name__ == '__main__':
    print("Generating Mirror Run icon...")
    img = draw_icon()
    img.save("/Users/tmaier/mirror_run/assets/icon.png", 'PNG')
    print("  Master saved")
    save_ios_icons(img)
    save_android_icons(img)
    save_macos_icons(img)
    print("Done!")
