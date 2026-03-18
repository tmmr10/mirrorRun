#!/usr/bin/env python3
"""Generate Google Play Store feature graphic (1024x500) for Mirror Runners."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

WIDTH, HEIGHT = 1024, 500
BG_COLOR = (15, 15, 30)  # Dark navy matching the game

img = Image.new("RGBA", (WIDTH, HEIGHT), BG_COLOR)
draw = ImageDraw.Draw(img)

# --- Background: subtle vertical lane lines ---
for x_offset in [-180, -100, -20, 20, 100, 180]:
    x = WIDTH // 2 + x_offset
    draw.line([(x, 0), (x, HEIGHT)], fill=(30, 30, 55), width=1)

# --- Horizontal ground line (subtle) ---
ground_y = HEIGHT * 0.72
draw.line([(0, int(ground_y)), (WIDTH, int(ground_y))], fill=(80, 220, 180, 60), width=2)

# --- Mirror line (center vertical, glowing) ---
mirror_x = WIDTH // 2
# Create glow effect for mirror line
glow_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow_layer)
for w in range(12, 0, -1):
    alpha = int(15 * (12 - w))
    glow_draw.line([(mirror_x, 0), (mirror_x, HEIGHT)], fill=(150, 180, 220, alpha), width=w)
glow_draw.line([(mirror_x, 0), (mirror_x, HEIGHT)], fill=(200, 220, 255, 180), width=2)
img = Image.alpha_composite(img, glow_layer)
draw = ImageDraw.Draw(img)

# --- Helper: draw rounded rectangle with glow ---
def draw_character(img, cx, cy, size, color, glow_color):
    """Draw a character (rounded square with eyes) at center position."""
    layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    half = size // 2
    r = size // 4  # corner radius

    # Glow
    glow_size = size + 40
    glow_half = glow_size // 2
    glow_img = Image.new("RGBA", (glow_size * 2, glow_size * 2), (0, 0, 0, 0))
    glow_d = ImageDraw.Draw(glow_img)
    glow_d.rounded_rectangle(
        [glow_half, glow_half, glow_half + glow_size, glow_half + glow_size],
        radius=r + 10,
        fill=(*glow_color, 50),
    )
    glow_img = glow_img.filter(ImageFilter.GaussianBlur(25))
    # Paste glow centered on character
    gx = cx - glow_size
    gy = cy - glow_size
    img.paste(Image.alpha_composite(
        img.crop((max(0, gx), max(0, gy), min(WIDTH, gx + glow_size * 2), min(HEIGHT, gy + glow_size * 2))),
        glow_img.crop((max(0, -gx), max(0, -gy), min(glow_size * 2, WIDTH - gx), min(glow_size * 2, HEIGHT - gy)))
    ), (max(0, gx), max(0, gy)))

    # Body
    d.rounded_rectangle(
        [cx - half, cy - half, cx + half, cy + half],
        radius=r,
        fill=color,
    )

    # Eyes (two dots)
    eye_y = cy - size // 10
    eye_spacing = size // 4
    eye_r = size // 12
    d.ellipse([cx - eye_spacing - eye_r, eye_y - eye_r, cx - eye_spacing + eye_r, eye_y + eye_r], fill=(20, 20, 30))
    d.ellipse([cx + eye_spacing - eye_r, eye_y - eye_r, cx + eye_spacing + eye_r, eye_y + eye_r], fill=(20, 20, 30))

    return Image.alpha_composite(img, layer)


# --- Draw characters ---
char_y = int(HEIGHT * 0.48)
char_size = 100

# Left character (orange)
img = draw_character(img, WIDTH // 2 - 150, char_y, char_size, (255, 140, 50), (255, 140, 50))
# Right character (purple)
img = draw_character(img, WIDTH // 2 + 150, char_y, char_size, (170, 130, 255), (170, 130, 255))

draw = ImageDraw.Draw(img)

# --- Small obstacles (decorative) ---
obstacles = [
    (WIDTH // 2 - 280, 80, 22, (50, 160, 80)),      # green top-left
    (WIDTH // 2 - 100, 130, 18, (50, 160, 80)),      # green mid-left
    (WIDTH // 2 + 100, 90, 18, (50, 80, 160)),       # blue top-right
    (WIDTH // 2 + 260, 160, 22, (50, 80, 160)),      # blue mid-right
    (WIDTH // 2 - 220, 320, 16, (50, 160, 80)),      # green bottom-left
    (WIDTH // 2 + 220, 300, 16, (50, 80, 160)),      # blue bottom-right
]
for ox, oy, osize, ocolor in obstacles:
    half = osize // 2
    draw.rounded_rectangle([ox - half, oy - half, ox + half, oy + half], radius=3, fill=ocolor)

# --- Title text: "MIRROR RUNNERS" ---
# Try to use a bold system font
font_large = None
font_paths = [
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/SFNSDisplay.ttf",
    "/Library/Fonts/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
]
for fp in font_paths:
    if os.path.exists(fp):
        try:
            font_large = ImageFont.truetype(fp, 72)
            font_small = ImageFont.truetype(fp, 28)
            break
        except Exception:
            continue

if font_large is None:
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Draw title with slight shadow
title = "MIRROR RUNNERS"
bbox = draw.textbbox((0, 0), title, font=font_large)
tw = bbox[2] - bbox[0]
tx = (WIDTH - tw) // 2
ty = HEIGHT - 130

# Shadow
draw.text((tx + 2, ty + 2), title, font=font_large, fill=(0, 0, 0, 150))
# Main text
draw.text((tx, ty), title, font=font_large, fill=(255, 255, 255))

# Subtitle
subtitle = "One tap. Two runners. Mirror mayhem."
bbox2 = draw.textbbox((0, 0), subtitle, font=font_small)
sw = bbox2[2] - bbox2[0]
sx = (WIDTH - sw) // 2
sy = ty + 75
draw.text((sx, sy), subtitle, font=font_small, fill=(180, 190, 210))

# --- Save ---
output_path = "/Users/tmaier/mirror_run/feature_graphic.png"
img_rgb = img.convert("RGB")
img_rgb.save(output_path, "PNG", optimize=True)
print(f"Saved: {output_path}")
print(f"Size: {img_rgb.size}")
print(f"File size: {os.path.getsize(output_path) / 1024:.1f} KB")
