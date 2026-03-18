#!/usr/bin/env python3
"""Create App Store Preview videos from screenshots using PIL + ffmpeg."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import subprocess
import os
import shutil
import math

SCREENSHOTS = "/Users/tmaier/mirror_run/ios/fastlane/screenshots"
TOOLS = os.path.dirname(__file__)
FRAME_DIR = os.path.join(TOOLS, "preview_frames")

W, H = 1284, 2778
FPS = 30
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"


def ease_in_out(t):
    """Smooth easing function."""
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def crop_zoom(img, zoom, cx=0.5, cy=0.5):
    """Crop image to simulate zoom effect centered at (cx, cy)."""
    w, h = img.size
    new_w = int(w / zoom)
    new_h = int(h / zoom)
    x = int((w - new_w) * cx)
    y = int((h - new_h) * cy)
    return img.crop((x, y, x + new_w, y + new_h)).resize((w, h), Image.LANCZOS)


def neon_glow_text(canvas, text, font, cx, cy, color, glow_r=20):
    """Draw neon text centered at (cx, cy) with glow."""
    w, h = canvas.size
    bbox = font.getbbox(text)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = cx - tw // 2
    y = cy - th // 2

    glow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for _ in range(3):
        gd.text((x, y), text, font=font, fill=(*color, 140))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=glow_r))
    canvas = Image.alpha_composite(canvas, glow)

    draw = ImageDraw.Draw(canvas)
    draw.text((x, y), text, font=font, fill=(*color, 255))
    return canvas


def fade_text(canvas, text, font, cx, cy, color, alpha):
    """Draw text with specific alpha."""
    w, h = canvas.size
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    x = cx - tw // 2
    y = cy - bbox[3] // 2

    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.text((x, y), text, font=font, fill=(*color, int(alpha * 255)))
    return Image.alpha_composite(canvas, layer)


def crossfade(img_a, img_b, t):
    """Crossfade between two images."""
    return Image.blend(img_a.convert('RGB'), img_b.convert('RGB'), t)


def black_frame():
    return Image.new('RGB', (W, H), (0, 0, 0))


def save_frame(img, idx, subdir):
    path = os.path.join(FRAME_DIR, subdir)
    os.makedirs(path, exist_ok=True)
    img.convert('RGB').save(os.path.join(path, f"frame_{idx:04d}.png"))


def encode_video(subdir, output_name, locale):
    frame_dir = os.path.join(FRAME_DIR, subdir)
    out_dir = os.path.join(SCREENSHOTS, locale)
    out_path = os.path.join(out_dir, output_name)

    subprocess.run([
        'ffmpeg', '-y', '-framerate', str(FPS),
        '-i', os.path.join(frame_dir, 'frame_%04d.png'),
        '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
        '-profile:v', 'high', '-level', '4.2',
        '-b:v', '12M', '-movflags', '+faststart',
        out_path
    ], capture_output=True)
    print(f"  {locale}: {output_name}")


# Load screenshots
def load_ss(name, locale="en-US"):
    return Image.open(os.path.join(SCREENSHOTS, locale, name)).convert('RGBA')


def create_preview_1(locale, texts):
    """Preview 1: Gameplay Overview (~18s)
    Menu with slow zoom -> crossfade to gameplay -> zoom into action
    """
    menu = load_ss("01_menu.png", locale)
    gameplay = load_ss("02_gameplay.png", locale)
    subdir = f"p1_{locale}"
    idx = 0

    font_big = ImageFont.truetype(FONT_BOLD, 88)
    font_sub = ImageFont.truetype(FONT_REG, 44)

    # Phase 1: Black -> fade in menu (1s)
    for f in range(FPS * 1):
        t = f / (FPS * 1)
        frame = crossfade(black_frame(), menu.convert('RGB'), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    # Phase 2: Menu with slow zoom in (4s)
    for f in range(FPS * 4):
        t = f / (FPS * 4)
        zoom = lerp(1.0, 1.08, ease_in_out(t))
        frame = crop_zoom(menu, zoom, 0.5, 0.45)
        save_frame(frame, idx, subdir); idx += 1

    # Phase 3: Crossfade to gameplay (1.5s)
    for f in range(int(FPS * 1.5)):
        t = f / (FPS * 1.5)
        frame = crossfade(menu.convert('RGB'), gameplay.convert('RGB'), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    # Phase 4: Gameplay with slow zoom + pan down (5s)
    for f in range(FPS * 5):
        t = f / (FPS * 5)
        zoom = lerp(1.0, 1.12, ease_in_out(t))
        cy = lerp(0.4, 0.55, ease_in_out(t))
        frame = crop_zoom(gameplay, zoom, 0.5, cy)
        save_frame(frame, idx, subdir); idx += 1

    # Phase 5: Flash white + text overlay (4s)
    for f in range(FPS * 4):
        t = f / (FPS * 4)
        frame = crop_zoom(gameplay, 1.12, 0.5, 0.55).convert('RGBA')

        # Darken
        dark = Image.new('RGBA', (W, H), (0, 0, 0, int(150 * min(1, t * 3))))
        frame = Image.alpha_composite(frame, dark)

        # Text fade in
        text_alpha = min(1.0, t * 2.5)
        frame = fade_text(frame, texts[0], font_big, W // 2, H // 2 - 60,
                          (180, 140, 255), text_alpha)
        frame = fade_text(frame, texts[1], font_sub, W // 2, H // 2 + 60,
                          (220, 220, 240), text_alpha * 0.8)

        save_frame(frame, idx, subdir); idx += 1

    # Phase 6: Fade out (1.5s)
    last = crop_zoom(gameplay, 1.12, 0.5, 0.55).convert('RGBA')
    dark = Image.new('RGBA', (W, H), (0, 0, 0, 150))
    last = Image.alpha_composite(last, dark)
    last = fade_text(last, texts[0], font_big, W // 2, H // 2 - 60,
                     (180, 140, 255), 1.0)
    last = fade_text(last, texts[1], font_sub, W // 2, H // 2 + 60,
                     (220, 220, 240), 0.8)

    for f in range(int(FPS * 1.5)):
        t = f / (FPS * 1.5)
        frame = crossfade(last.convert('RGB'), black_frame(), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    print(f"  Preview 1: {idx} frames ({idx/FPS:.1f}s)")
    encode_video(subdir, "preview_01_gameplay.mp4", locale)


def create_preview_2(locale, texts):
    """Preview 2: Special Events (~18s)
    Phantom mode -> Mirror Swap -> text
    """
    phantom = load_ss("03_phantom.png", locale)
    swap = load_ss("04_swap.png", locale)
    subdir = f"p2_{locale}"
    idx = 0

    font_big = ImageFont.truetype(FONT_BOLD, 82)
    font_sub = ImageFont.truetype(FONT_REG, 42)
    font_label = ImageFont.truetype(FONT_BOLD, 56)

    # Phase 1: Fade in phantom (1s)
    for f in range(FPS * 1):
        t = f / (FPS * 1)
        frame = crossfade(black_frame(), phantom.convert('RGB'), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    # Phase 2: Phantom with zoom + label (4.5s)
    for f in range(int(FPS * 4.5)):
        t = f / (FPS * 4.5)
        zoom = lerp(1.0, 1.06, ease_in_out(t))
        frame = crop_zoom(phantom, zoom, 0.5, 0.5).convert('RGBA')

        # Pulsing cyan border
        pulse = 0.3 + 0.3 * math.sin(t * math.pi * 4)
        border = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        bd = ImageDraw.Draw(border)
        bd.rectangle([(0, 0), (W-1, H-1)], outline=(68, 221, 255, int(pulse * 255)), width=4)
        frame = Image.alpha_composite(frame, border)

        save_frame(frame, idx, subdir); idx += 1

    # Phase 3: Flash transition to swap (1s)
    for f in range(FPS * 1):
        t = f / (FPS * 1)
        if t < 0.3:
            # White flash
            flash_t = t / 0.3
            frame = phantom.convert('RGB')
            white = Image.new('RGB', (W, H), (255, 255, 255))
            frame = crossfade(frame, white, ease_in_out(flash_t) * 0.7)
        else:
            # Fade to swap
            fade_t = (t - 0.3) / 0.7
            white = Image.new('RGB', (W, H), (255, 80, 40))
            frame = crossfade(white, swap.convert('RGB'), ease_in_out(fade_t))
        save_frame(frame, idx, subdir); idx += 1

    # Phase 4: Swap with zoom (4.5s)
    for f in range(int(FPS * 4.5)):
        t = f / (FPS * 4.5)
        zoom = lerp(1.0, 1.08, ease_in_out(t))
        cy = lerp(0.45, 0.55, ease_in_out(t))
        frame = crop_zoom(swap, zoom, 0.5, cy).convert('RGBA')

        # Pulsing red border
        pulse = 0.3 + 0.3 * math.sin(t * math.pi * 3)
        border = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        bd = ImageDraw.Draw(border)
        bd.rectangle([(0, 0), (W-1, H-1)], outline=(255, 80, 40, int(pulse * 255)), width=4)
        frame = Image.alpha_composite(frame, border)

        save_frame(frame, idx, subdir); idx += 1

    # Phase 5: Darken + end text (4.5s)
    for f in range(int(FPS * 4.5)):
        t = f / (FPS * 4.5)
        frame = crop_zoom(swap, 1.08, 0.5, 0.55).convert('RGBA')
        dark = Image.new('RGBA', (W, H), (0, 0, 0, int(160 * min(1, t * 3))))
        frame = Image.alpha_composite(frame, dark)

        text_alpha = min(1.0, t * 2.5)
        frame = fade_text(frame, texts[0], font_big, W // 2, H // 2 - 60,
                          (255, 100, 68), text_alpha)
        frame = fade_text(frame, texts[1], font_sub, W // 2, H // 2 + 60,
                          (220, 220, 240), text_alpha * 0.8)
        save_frame(frame, idx, subdir); idx += 1

    # Phase 6: Fade out (1.5s)
    last = crop_zoom(swap, 1.08, 0.5, 0.55).convert('RGBA')
    dark = Image.new('RGBA', (W, H), (0, 0, 0, 160))
    last = Image.alpha_composite(last, dark)
    last = fade_text(last, texts[0], font_big, W // 2, H // 2 - 60, (255, 100, 68), 1.0)
    last = fade_text(last, texts[1], font_sub, W // 2, H // 2 + 60, (220, 220, 240), 0.8)
    for f in range(int(FPS * 1.5)):
        t = f / (FPS * 1.5)
        frame = crossfade(last.convert('RGB'), black_frame(), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    print(f"  Preview 2: {idx} frames ({idx/FPS:.1f}s)")
    encode_video(subdir, "preview_02_events.mp4", locale)


def create_preview_3(locale, texts):
    """Preview 3: Skins & Biomes (~18s)
    Gameplay zoom -> skins showcase -> end text
    """
    gameplay = load_ss("02_gameplay.png", locale)
    swap = load_ss("04_swap.png", locale)
    skins = load_ss("05_skins.png", locale)
    subdir = f"p3_{locale}"
    idx = 0

    font_big = ImageFont.truetype(FONT_BOLD, 82)
    font_sub = ImageFont.truetype(FONT_REG, 42)

    # Phase 1: Fade in gameplay/crystal biome (1s)
    for f in range(FPS * 1):
        t = f / (FPS * 1)
        frame = crossfade(black_frame(), gameplay.convert('RGB'), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    # Phase 2: Crystal biome zoom (3s)
    for f in range(FPS * 3):
        t = f / (FPS * 3)
        zoom = lerp(1.0, 1.06, ease_in_out(t))
        frame = crop_zoom(gameplay, zoom, 0.5, 0.5)
        save_frame(frame, idx, subdir); idx += 1

    # Phase 3: Crossfade to volcano/swap (1s)
    for f in range(FPS * 1):
        t = f / (FPS * 1)
        frame = crossfade(gameplay.convert('RGB'), swap.convert('RGB'), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    # Phase 4: Volcano zoom (3s)
    for f in range(FPS * 3):
        t = f / (FPS * 3)
        zoom = lerp(1.0, 1.06, ease_in_out(t))
        frame = crop_zoom(swap, zoom, 0.5, 0.5)
        save_frame(frame, idx, subdir); idx += 1

    # Phase 5: Crossfade to skins (1s)
    for f in range(FPS * 1):
        t = f / (FPS * 1)
        frame = crossfade(swap.convert('RGB'), skins.convert('RGB'), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    # Phase 6: Skins with gentle zoom (4s)
    for f in range(FPS * 4):
        t = f / (FPS * 4)
        zoom = lerp(1.0, 1.05, ease_in_out(t))
        frame = crop_zoom(skins, zoom, 0.5, 0.45)
        save_frame(frame, idx, subdir); idx += 1

    # Phase 7: Darken + end text (3.5s)
    for f in range(int(FPS * 3.5)):
        t = f / (FPS * 3.5)
        frame = crop_zoom(skins, 1.05, 0.5, 0.45).convert('RGBA')
        dark = Image.new('RGBA', (W, H), (0, 0, 0, int(160 * min(1, t * 3))))
        frame = Image.alpha_composite(frame, dark)

        text_alpha = min(1.0, t * 2.5)
        frame = fade_text(frame, texts[0], font_big, W // 2, H // 2 - 60,
                          (180, 140, 255), text_alpha)
        frame = fade_text(frame, texts[1], font_sub, W // 2, H // 2 + 60,
                          (220, 220, 240), text_alpha * 0.8)
        save_frame(frame, idx, subdir); idx += 1

    # Phase 8: Fade out (1.5s)
    last = crop_zoom(skins, 1.05, 0.5, 0.45).convert('RGBA')
    dark = Image.new('RGBA', (W, H), (0, 0, 0, 160))
    last = Image.alpha_composite(last, dark)
    last = fade_text(last, texts[0], font_big, W // 2, H // 2 - 60, (180, 140, 255), 1.0)
    last = fade_text(last, texts[1], font_sub, W // 2, H // 2 + 60, (220, 220, 240), 0.8)
    for f in range(int(FPS * 1.5)):
        t = f / (FPS * 1.5)
        frame = crossfade(last.convert('RGB'), black_frame(), ease_in_out(t))
        save_frame(frame, idx, subdir); idx += 1

    print(f"  Preview 3: {idx} frames ({idx/FPS:.1f}s)")
    encode_video(subdir, "preview_03_biomes.mp4", locale)


# ---- Main ----
if os.path.exists(FRAME_DIR):
    shutil.rmtree(FRAME_DIR)

print("Creating App Store Previews...\n")

# EN
print("EN:")
create_preview_1("en-US", ["Two Runners. One Move.", "How far can you go?"])
create_preview_2("en-US", ["Expect the Unexpected", "Phantom Mode & Mirror Swap"])
create_preview_3("en-US", ["11 Biomes. 7 Skins.", "Unlock them all."])

# DE
print("\nDE:")
create_preview_1("de-DE", ["Zwei Runner. Eine Bewegung.", "Wie weit kommst du?"])
create_preview_2("de-DE", ["Erwarte das Unerwartete", "Phantom-Modus & Mirror Swap"])
create_preview_3("de-DE", ["11 Biome. 7 Skins.", "Schalte alle frei."])

# Cleanup frames
shutil.rmtree(FRAME_DIR)
print("\nDone! Previews saved to fastlane/screenshots/")
