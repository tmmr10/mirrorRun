#!/usr/bin/env python3
"""Process raw screenshots: resize and add modern text overlays for App Store."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

RAW = os.path.join(os.path.dirname(__file__), "raw_screenshots")
EN_OUT = "/Users/tmaier/mirror_run/ios/fastlane/screenshots/en-US"
DE_OUT = "/Users/tmaier/mirror_run/ios/fastlane/screenshots/de-DE"

IPHONE_W, IPHONE_H = 1284, 2778
IPAD_W, IPAD_H = 2048, 2732

FONT_FUTURA_BOLD = "/System/Library/Fonts/Supplemental/Futura.ttc"
FONT_FUTURA_MEDIUM = "/System/Library/Fonts/Supplemental/Futura.ttc"
FUTURA_BOLD_INDEX = 4   # Condensed ExtraBold
FUTURA_MEDIUM_INDEX = 0  # Medium


def draw_accent_line(draw, cx, y, width, color_left, color_right, img):
    """Draw a thin horizontal gradient accent line."""
    line_img = Image.new('RGBA', (width, 3), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line_img)
    for x in range(width):
        t = x / width
        if t < 0.15:
            a = int(255 * (t / 0.15))
        elif t > 0.85:
            a = int(255 * ((1 - t) / 0.15))
        else:
            a = 255
        r = int(color_left[0] * (1 - t) + color_right[0] * t)
        g = int(color_left[1] * (1 - t) + color_right[1] * t)
        b = int(color_left[2] * (1 - t) + color_right[2] * t)
        ld.line([(x, 0), (x, 2)], fill=(r, g, b, a))
    img.paste(line_img, (cx - width // 2, y), line_img)


def add_overlay(img, headline, subtext, accent_left, accent_right, target_w, target_h):
    """Add modern minimal text banner at top with gradient accent."""
    if img.mode == 'RGBA':
        bg = Image.new('RGBA', img.size, (0, 0, 0, 255))
        img = Image.alpha_composite(bg, img)

    scale = target_w / IPHONE_W
    banner_h = int(380 * (target_h / IPHONE_H))
    status_bar_h = 150

    out = Image.new('RGBA', (target_w, target_h), (6, 6, 12, 255))

    # Crop status bar, scale game to fill below banner
    game_cropped = img.crop((0, status_bar_h, img.width, img.height))
    game_h = target_h - banner_h
    src_ratio = game_cropped.width / game_cropped.height
    dst_ratio = target_w / game_h
    if src_ratio < dst_ratio:
        scaled_w = target_w
        scaled_h = int(target_w / src_ratio)
        game_scaled = game_cropped.resize((scaled_w, scaled_h), Image.LANCZOS)
        crop_top = (scaled_h - game_h) // 2
        game_img = game_scaled.crop((0, crop_top, scaled_w, crop_top + game_h))
    else:
        scaled_h = game_h
        scaled_w = int(game_h * src_ratio)
        game_scaled = game_cropped.resize((scaled_w, scaled_h), Image.LANCZOS)
        pad_x = (target_w - scaled_w) // 2
        game_img = Image.new('RGBA', (target_w, game_h), (6, 6, 12, 255))
        game_img.paste(game_scaled, (pad_x, 0))

    out.paste(game_img, (0, banner_h))

    # Soft gradient transition from banner to game
    grad_h = int(100 * scale)
    gradient = Image.new('RGBA', (target_w, grad_h), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(gradient)
    for y in range(grad_h):
        alpha = int(255 * (1 - y / grad_h) ** 1.5)
        grad_draw.line([(0, y), (target_w, y)], fill=(6, 6, 12, alpha))
    out.paste(gradient, (0, banner_h), gradient)

    # Subtle vignette at bottom
    vig_h = int(200 * scale)
    vignette = Image.new('RGBA', (target_w, vig_h), (0, 0, 0, 0))
    vig_draw = ImageDraw.Draw(vignette)
    for y in range(vig_h):
        alpha = int(180 * (y / vig_h) ** 2)
        vig_draw.line([(0, y), (target_w, y)], fill=(0, 0, 0, alpha))
    out.paste(vignette, (0, target_h - vig_h), vignette)

    cx = target_w // 2

    # Headline — Futura Condensed ExtraBold, large, white
    font_head_size = int(88 * scale)
    font_headline = ImageFont.truetype(FONT_FUTURA_BOLD, font_head_size, index=FUTURA_BOLD_INDEX)
    bbox = font_headline.getbbox(headline)
    tw = bbox[2] - bbox[0]
    head_x = cx - tw // 2
    head_y = int(115 * (target_h / IPHONE_H))

    # Subtle text shadow
    shadow = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.text((head_x, head_y + 2), headline, font=font_headline, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=int(6 * scale)))
    out = Image.alpha_composite(out, shadow)

    # Main headline text — clean white
    draw = ImageDraw.Draw(out)
    draw.text((head_x, head_y), headline, font=font_headline, fill=(255, 255, 255, 255))

    # Accent gradient line under headline
    line_y = head_y + (bbox[3] - bbox[1]) + int(18 * scale)
    line_w = int(min(tw * 0.6, 300 * scale))
    draw_accent_line(draw, cx, line_y, line_w, accent_left, accent_right, out)

    # Subtext — Futura Medium, lighter, spaced
    font_sub_size = int(38 * scale)
    font_sub = ImageFont.truetype(FONT_FUTURA_MEDIUM, font_sub_size, index=FUTURA_MEDIUM_INDEX)
    bbox_sub = font_sub.getbbox(subtext)
    tw_sub = bbox_sub[2] - bbox_sub[0]
    sub_x = cx - tw_sub // 2
    sub_y = line_y + int(24 * scale)

    draw.text((sub_x, sub_y), subtext, font=font_sub, fill=(200, 200, 220, 200))

    return out


def process(raw_name, en_name, de_name, en_head, en_sub, de_head, de_sub,
            accent_left=(180, 140, 255), accent_right=(80, 200, 255)):
    """Process one screenshot for all locales and device sizes."""
    raw_path = os.path.join(RAW, raw_name)
    if not os.path.exists(raw_path):
        print(f"  SKIP: {raw_name} not found")
        return

    img = Image.open(raw_path).convert("RGBA")

    ipad_name = "ipad_" + en_name
    ipad_de_name = "ipad_" + de_name
    for label, tw, th, out_dirs in [
        ("iPhone", IPHONE_W, IPHONE_H, [(EN_OUT, en_name), (DE_OUT, de_name)]),
        ("iPad", IPAD_W, IPAD_H, [(EN_OUT, ipad_name), (DE_OUT, ipad_de_name)]),
    ]:
        resized = img.resize((IPHONE_W, IPHONE_H), Image.LANCZOS)

        for out_dir, name in out_dirs:
            os.makedirs(out_dir, exist_ok=True)
            is_en = "en-US" in out_dir
            head = en_head if is_en else de_head
            sub = en_sub if is_en else de_sub
            result = add_overlay(resized.copy(), head, sub,
                                 accent_left, accent_right, tw, th)
            result.convert("RGB").save(os.path.join(out_dir, name))
            lang = "EN" if is_en else "DE"
            print(f"  {lang} {label}: {name}")


for d in [EN_OUT, DE_OUT]:
    os.makedirs(d, exist_ok=True)

print("Processing screenshots...\n")

# 1. Menu
process("01_menu.png", "01_menu.png", "01_menu.png",
        "TWO RUNNERS. ONE MOVE.", "Dodge both sides to survive",
        "ZWEI RUNNER. EINE BEWEGUNG.", "Weiche auf beiden Seiten aus",
        accent_left=(180, 140, 255), accent_right=(80, 200, 255))

# 2. Gameplay
process("02_gameplay.png", "02_gameplay.png", "02_gameplay.png",
        "11 BIOMES TO EXPLORE", "How far can you go?",
        "11 BIOME ENTDECKEN", "Wie weit kommst du?",
        accent_left=(0, 230, 200), accent_right=(80, 140, 255))

# 3. Phantom
process("03_phantom.png", "03_phantom.png", "03_phantom.png",
        "PHANTOM MODE", "Obstacles turn invisible",
        "PHANTOM-MODUS", "Hindernisse werden unsichtbar",
        accent_left=(180, 80, 255), accent_right=(255, 80, 180))

# 4. Swap
process("04_swap.png", "04_swap.png", "04_swap.png",
        "MIRROR SWAP", "Left becomes right",
        "MIRROR SWAP", "Links wird rechts",
        accent_left=(255, 100, 68), accent_right=(255, 180, 40))

# 5. Skins
process("05_skins.png", "05_skins.png", "05_skins.png",
        "UNLOCKABLE SKINS", "Earn new looks as you explore",
        "FREISCHALTBARE SKINS", "Verdiene neue Looks",
        accent_left=(255, 140, 80), accent_right=(255, 80, 140))

print("\nDone!")
