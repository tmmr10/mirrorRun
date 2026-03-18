#!/usr/bin/env python3
"""Process raw screenshots: add overlays for App Store.

v6 — Premium full-width glass box with gradient border and glow.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

RAW = os.path.join(os.path.dirname(__file__), "raw_screenshots")
EN_OUT = "/Users/tmaier/mirror_run/ios/fastlane/screenshots/en-US"
DE_OUT = "/Users/tmaier/mirror_run/ios/fastlane/screenshots/de-DE"

IPHONE_W, IPHONE_H = 1284, 2778
IPAD_W, IPAD_H = 2048, 2732

FONT_HN = "/System/Library/Fonts/HelveticaNeue.ttc"
HN_ULTRALIGHT = 5
HN_BOLD = 1

BG_COLOR = (8, 8, 15)


def draw_gradient_line(img, cx, y, width, height, color_left, color_right):
    line = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line)
    for x in range(width):
        t = x / max(width - 1, 1)
        if t < 0.1:
            a = int(255 * (t / 0.1))
        elif t > 0.9:
            a = int(255 * ((1 - t) / 0.1))
        else:
            a = 255
        r = int(color_left[0] * (1 - t) + color_right[0] * t)
        g = int(color_left[1] * (1 - t) + color_right[1] * t)
        b = int(color_left[2] * (1 - t) + color_right[2] * t)
        for row in range(height):
            ld.point((x, row), fill=(r, g, b, a))
    img.paste(line, (cx - width // 2, y), line)


def draw_text_with_spacing(draw, x, y, text, font, fill, spacing):
    cursor = x
    for ch in text:
        bbox = font.getbbox(ch)
        cw = bbox[2] - bbox[0]
        draw.text((cursor, y), ch, font=font, fill=fill)
        cursor += cw + spacing
    return cursor - x - spacing if text else 0


def measure_text_with_spacing(font, text, spacing):
    total = 0
    for i, ch in enumerate(text):
        bbox = font.getbbox(ch)
        total += bbox[2] - bbox[0]
        if i < len(text) - 1:
            total += spacing
    return total


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] * (1 - t) + c2[i] * t) for i in range(len(c1)))


def add_overlay(img, headline, subtext, accent_left, accent_right, target_w, target_h):
    if img.mode == 'RGBA':
        bg = Image.new('RGBA', img.size, (0, 0, 0, 255))
        img = Image.alpha_composite(bg, img)

    scale = target_w / IPHONE_W
    status_bar_h = 150

    # --- Font setup ---
    head_font_size = int(84 * scale)
    head_font = ImageFont.truetype(FONT_HN, head_font_size, index=HN_BOLD)
    head_spacing = int(9 * scale)
    head_tw = measure_text_with_spacing(head_font, headline, head_spacing)
    head_bbox = head_font.getbbox("A")
    head_text_h = head_bbox[3] - head_bbox[1]

    sub_font_size = int(36 * scale)
    sub_font = ImageFont.truetype(FONT_HN, sub_font_size, index=HN_ULTRALIGHT)
    sub_spacing = int(13 * scale)
    sub_tw = measure_text_with_spacing(sub_font, subtext, sub_spacing)
    sub_bbox = sub_font.getbbox("A")
    sub_text_h = sub_bbox[3] - sub_bbox[1]

    # --- Box layout ---
    box_margin_x = int(32 * scale)
    pad_top = int(48 * scale)
    pad_bottom = int(48 * scale)
    text_gap = int(38 * scale)

    box_w = target_w - box_margin_x * 2
    box_h = pad_top + head_text_h + text_gap + sub_text_h + pad_bottom
    box_margin_top = int(44 * (target_h / IPHONE_H))
    box_margin_bottom = int(50 * scale)

    reserved_top = box_margin_top + box_h + box_margin_bottom

    # --- Place game screenshot ---
    out = Image.new('RGBA', (target_w, target_h), (*BG_COLOR, 255))

    game_cropped = img.crop((0, status_bar_h, img.width, img.height))
    game_area_h = target_h - reserved_top
    src_ratio = game_cropped.width / game_cropped.height
    dst_ratio = target_w / game_area_h
    if src_ratio < dst_ratio:
        scaled_w = target_w
        scaled_h = int(target_w / src_ratio)
        game_scaled = game_cropped.resize((scaled_w, scaled_h), Image.LANCZOS)
        crop_top = (scaled_h - game_area_h) // 2
        game_img = game_scaled.crop((0, crop_top, scaled_w, crop_top + game_area_h))
    else:
        scaled_h = game_area_h
        scaled_w = int(game_area_h * src_ratio)
        game_scaled = game_cropped.resize((scaled_w, scaled_h), Image.LANCZOS)
        pad_lr = (target_w - scaled_w) // 2
        game_img = Image.new('RGBA', (target_w, game_area_h), (*BG_COLOR, 255))
        game_img.paste(game_scaled, (pad_lr, 0))

    out.paste(game_img, (0, reserved_top))

    # Smooth gradient blend into game
    blend_h = int(120 * scale)
    blend = Image.new('RGBA', (target_w, blend_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blend)
    for y in range(blend_h):
        alpha = int(255 * (1 - y / blend_h) ** 2)
        bd.line([(0, y), (target_w, y)], fill=(*BG_COLOR, alpha))
    out.paste(blend, (0, reserved_top), blend)

    # Bottom vignette
    vig_h = int(300 * scale)
    vignette = Image.new('RGBA', (target_w, vig_h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    for y in range(vig_h):
        alpha = int(180 * (y / vig_h) ** 2.5)
        vd.line([(0, y), (target_w, y)], fill=(0, 0, 0, alpha))
    out.paste(vignette, (0, target_h - vig_h), vignette)

    cx = target_w // 2
    box_x = box_margin_x
    box_y = box_margin_top
    box_radius = int(24 * scale)

    # --- Outer glow behind box ---
    glow_layer = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    accent_mid = tuple((a + b) // 2 for a, b in zip(accent_left, accent_right))
    glow_draw.rounded_rectangle(
        (box_x - 12, box_y - 12, box_x + box_w + 12, box_y + box_h + 12),
        radius=box_radius + 12,
        fill=(*accent_mid, 80),
    )
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=int(45 * scale)))
    out = Image.alpha_composite(out, glow_layer)

    # --- Box background: subtle gradient from accent_left to accent_right, very dark ---
    box_bg = Image.new('RGBA', (box_w, box_h), (0, 0, 0, 0))
    box_bg_draw = ImageDraw.Draw(box_bg)
    # Rounded mask
    mask = Image.new('L', (box_w, box_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, box_w, box_h), radius=box_radius, fill=255)

    # Base dark fill
    base = Image.new('RGBA', (box_w, box_h), (10, 10, 20, 220))

    # Gradient tint overlay (horizontal, accent_left → accent_right, very subtle)
    grad_tint = Image.new('RGBA', (box_w, box_h), (0, 0, 0, 0))
    gt_draw = ImageDraw.Draw(grad_tint)
    for x in range(box_w):
        t = x / max(box_w - 1, 1)
        c = lerp_color((*accent_left, 20), (*accent_right, 20), t)
        gt_draw.line([(x, 0), (x, box_h)], fill=c)

    combined_box = Image.alpha_composite(base, grad_tint)

    # Top edge highlight: subtle light line at top of box
    highlight = Image.new('RGBA', (box_w, box_h), (0, 0, 0, 0))
    hl_draw = ImageDraw.Draw(highlight)
    for x in range(box_w):
        t = x / max(box_w - 1, 1)
        c = lerp_color(accent_left, accent_right, t)
        # Fade edges
        edge_fade = 1.0
        if t < 0.05:
            edge_fade = t / 0.05
        elif t > 0.95:
            edge_fade = (1 - t) / 0.05
        a = int(80 * edge_fade)
        for row in range(3):
            row_fade = 1.0 - row / 3
            hl_draw.point((x, row), fill=(*c, int(a * row_fade)))

    combined_box = Image.alpha_composite(combined_box, highlight)
    out.paste(combined_box, (box_x, box_y), mask)

    # --- Gradient border ---
    border_w = 2
    # Draw border by creating outer and inner rounded rects
    border_layer = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    bd_draw = ImageDraw.Draw(border_layer)

    # We'll draw gradient border pixel by pixel around the perimeter
    # Simpler: draw 4 gradient lines (top, bottom, left, right) with rounded corners via outline
    # Use rounded_rectangle outline with gradient by drawing multiple single-color outlines blended
    # Simplest approach: draw the outline and tint it
    for i in range(border_w):
        # Slightly different alpha for depth
        a = 70 - i * 15
        bd_draw.rounded_rectangle(
            (box_x + i, box_y + i, box_x + box_w - i, box_y + box_h - i),
            radius=box_radius - i,
            outline=(*accent_mid, a),
            width=1,
        )
    out = Image.alpha_composite(out, border_layer)

    # --- Text inside box ---
    head_x = cx - head_tw // 2
    head_y_pos = box_y + pad_top

    # Headline glow
    h_glow = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    h_glow_draw = ImageDraw.Draw(h_glow)
    draw_text_with_spacing(h_glow_draw, head_x, head_y_pos, headline,
                           head_font, (*accent_left, 80), head_spacing)
    h_glow = h_glow.filter(ImageFilter.GaussianBlur(radius=int(25 * scale)))
    out = Image.alpha_composite(out, h_glow)

    draw = ImageDraw.Draw(out)
    draw_text_with_spacing(draw, head_x, head_y_pos, headline,
                           head_font, (255, 255, 255, 255), head_spacing)

    # Subtext
    sub_x = cx - sub_tw // 2
    sub_y_pos = head_y_pos + head_text_h + text_gap

    s_glow = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    s_glow_draw = ImageDraw.Draw(s_glow)
    draw_text_with_spacing(s_glow_draw, sub_x, sub_y_pos, subtext,
                           sub_font, (*accent_right, 35), sub_spacing)
    s_glow = s_glow.filter(ImageFilter.GaussianBlur(radius=int(15 * scale)))
    out = Image.alpha_composite(out, s_glow)

    draw = ImageDraw.Draw(out)
    draw_text_with_spacing(draw, sub_x, sub_y_pos, subtext,
                           sub_font, (255, 255, 255, 220), sub_spacing)

    return out


def process(raw_name, en_name, de_name, en_head, en_sub, de_head, de_sub,
            accent_left=(180, 140, 255), accent_right=(80, 200, 255)):
    raw_path = os.path.join(RAW, raw_name)
    ipad_raw_path = os.path.join(RAW, "ipad_" + raw_name)

    if not os.path.exists(raw_path):
        print(f"  SKIP: {raw_name} not found")
        return

    img = Image.open(raw_path).convert("RGBA")
    ipad_img = Image.open(ipad_raw_path).convert("RGBA") if os.path.exists(ipad_raw_path) else None

    ipad_name = "ipad_" + en_name
    ipad_de_name = "ipad_" + de_name
    for label, tw, th, out_dirs in [
        ("iPhone", IPHONE_W, IPHONE_H, [(EN_OUT, en_name), (DE_OUT, de_name)]),
        ("iPad", IPAD_W, IPAD_H, [(EN_OUT, ipad_name), (DE_OUT, ipad_de_name)]),
    ]:
        if label == "iPad" and ipad_img is not None:
            source = ipad_img.resize((IPAD_W, IPAD_H), Image.LANCZOS)
        else:
            source = img.resize((IPHONE_W, IPHONE_H), Image.LANCZOS)

        for out_dir, name in out_dirs:
            os.makedirs(out_dir, exist_ok=True)
            is_en = "en-US" in out_dir
            head = en_head if is_en else de_head
            sub = en_sub if is_en else de_sub
            result = add_overlay(source.copy(), head, sub,
                                 accent_left, accent_right, tw, th)
            result.convert("RGB").save(os.path.join(out_dir, name))
            lang = "EN" if is_en else "DE"
            print(f"  {lang} {label}: {name}")


for d in [EN_OUT, DE_OUT]:
    os.makedirs(d, exist_ok=True)

print("Processing screenshots...\n")

PURPLE = (180, 140, 255)
CYAN = (80, 200, 255)

process("01_menu.png", "01_menu.png", "01_menu.png",
        "ONE MOVE", "TWO RUNNERS",
        "EINE BEWEGUNG", "ZWEI RUNNER",
        accent_left=PURPLE, accent_right=CYAN)

process("02_gameplay.png", "02_gameplay.png", "02_gameplay.png",
        "RUN FURTHER", "EXPLORE 11 WORLDS",
        "LAUF WEITER", "ENTDECKE 11 WELTEN",
        accent_left=(0, 220, 200), accent_right=(80, 140, 255))

process("03_phantom.png", "03_phantom.png", "03_phantom.png",
        "STAY ALERT", "OBSTACLES GO INVISIBLE",
        "BLEIB WACHSAM", "HINDERNISSE VERSCHWINDEN",
        accent_left=(180, 80, 255), accent_right=(255, 80, 180))

process("04_swap.png", "04_swap.png", "04_swap.png",
        "EXPECT CHAOS", "CONTROLS GET REVERSED",
        "ERWARTE CHAOS", "STEUERUNG WIRD VERTAUSCHT",
        accent_left=(255, 100, 68), accent_right=(255, 180, 40))

process("05_skins.png", "05_skins.png", "05_skins.png",
        "EARN SKINS", "UNLOCK BY PLAYING",
        "SKINS FREISPIELEN", "BELOHNUNG DURCH SPIELEN",
        accent_left=(255, 140, 80), accent_right=(255, 80, 140))

process("06_creator.png", "06_creator.png", "06_creator.png",
        "BE UNIQUE", "CREATE YOUR OWN SKIN",
        "SEI EINZIGARTIG", "ERSTELLE DEINEN SKIN",
        accent_left=(0, 220, 180), accent_right=(140, 80, 255))

print("\nDone!")
