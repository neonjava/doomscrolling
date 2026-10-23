#!/usr/bin/env python3
"""
Generate a high-retention 30-second 9:16 vertical promo video for Instagram Reels / TikTok / YouTube Shorts.
Uses real physical device captures, kinetic typography, phone frame mockups, and synthesized sound design.
"""

import math
import os
from pathlib import Path
import subprocess
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

WIDTH = 1080
HEIGHT = 1920
FPS = 30
DURATION_SEC = 30
TOTAL_FRAMES = FPS * DURATION_SEC  # 900 frames

ROOT = Path(__file__).resolve().parents[1]
CAPTURES_DIR = Path("/tmp/doomscrolling-device")
OUT_MP4 = ROOT / "web" / "promo.mp4"

FONT_PATH = "/usr/share/fonts/google-noto-vf/NotoSans[wght].ttf"
BOLD_FONT_PATH = "/usr/share/fonts/google-droid-sans-fonts/DroidSans-Bold.ttf"

def get_font(size, bold=False):
    path = BOLD_FONT_PATH if bold and os.path.exists(BOLD_FONT_PATH) else FONT_PATH
    return ImageFont.truetype(path, size)

# Colors
BG_DARK = (10, 13, 22)
MINT = (117, 236, 207)
WHITE = (245, 248, 252)
MUTED = (160, 172, 192)
RED = (239, 68, 68)
CARD_BG = (24, 32, 46)
BORDER_COL = (45, 55, 72)

# Load device captures
def load_img(name):
    p = CAPTURES_DIR / name
    if p.exists():
        return Image.open(p).convert("RGBA")
    return None

img_app = load_img("app-dark.png")
img_yt_before = load_img("before.png")
img_yt_after = load_img("after.png")
img_comments = load_img("comments.png")
img_ig = load_img("ig.png")
img_ig_after = load_img("ig-swipe.png")

def draw_phone_frame(draw, x, y, w, h, screen_img, corner=48):
    # Outer device bezel
    bezel = 12
    draw.rounded_rectangle([x - bezel, y - bezel, x + w + bezel, y + h + bezel], radius=corner + bezel, fill=(28, 36, 50), outline=(75, 90, 115), width=2)
    # Screen inner shadow / cutout
    if screen_img:
        # Resize screen_img to fit
        resized = screen_img.resize((w, h), Image.Resampling.LANCZOS)
        # Create mask with rounded corners
        mask = Image.new("L", (w, h), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, w, h], radius=corner, fill=255)
        return resized, mask, (x, y)
    return None

def main():
    print(f"Generating 30s 9:16 vertical promo video ({WIDTH}x{HEIGHT} @ {FPS}fps = {TOTAL_FRAMES} frames)...")

    # Start ffmpeg pipe
    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",  # Video from stdin
        # Synthesize atmospheric tech electronic audio with beat and chime
        "-f", "lavfi",
        "-i", "aevalsrc=0.12*sin(2*PI*110*t)*(1-abs(sin(2*PI*1.875*t))) + 0.06*sin(2*PI*220*t) + 0.03*sin(2*PI*440*t):s=44100:d=30",
        "-c:v", "libopenh264",
        "-b:v", "5M",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        str(OUT_MP4)
    ]

    proc = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)

    font_huge = get_font(76, bold=True)
    font_large = get_font(52, bold=True)
    font_med = get_font(38, bold=False)
    font_small = get_font(28, bold=False)
    font_badge = get_font(24, bold=True)
    font_clock = get_font(90, bold=True)

    for frame_idx in range(TOTAL_FRAMES):
        t = frame_idx / FPS  # Current time in seconds

        # Create base canvas with smooth subtle gradient
        img = Image.new("RGB", (WIDTH, HEIGHT), BG_DARK)
        draw = ImageDraw.Draw(img)

        # Subtle glowing background circle
        glow_pulse = 0.5 + 0.5 * math.sin(t * 2)
        glow_center = (WIDTH // 2, 850)
        glow_radius = int(380 + glow_pulse * 40)
        draw.ellipse([glow_center[0] - glow_radius, glow_center[1] - glow_radius,
                      glow_center[0] + glow_radius, glow_center[1] + glow_radius],
                     fill=(14, 25, 38))

        screen_composite = None

        # ==============================================================
        # SCENE 1: THE HOOK (0.0s - 5.5s)
        # ==============================================================
        if t < 5.5:
            # Top Badge
            draw.rounded_rectangle([WIDTH//2 - 190, 180, WIDTH//2 + 190, 235], radius=28, fill=(28, 45, 45), outline=MINT, width=2)
            draw.text((WIDTH//2, 207), "THE INFINITE TRAP", font=font_badge, fill=MINT, anchor="mm")

            # Main text
            draw.text((WIDTH//2, 340), "You opened YouTube", font=font_large, fill=WHITE, anchor="mm")
            draw.text((WIDTH//2, 420), "for ONE short video...", font=font_huge, fill=MINT, anchor="mm")

            # Clock animation
            clock_t = min(1.0, t / 4.0)
            mins = int(clock_t * 165)  # 0 to 165 mins (11:00 PM -> 1:45 AM)
            h = 11 + (mins // 60)
            if h > 12: h -= 12
            m = mins % 60
            ampm = "PM" if (11 + (mins // 60)) < 12 else "AM"
            time_str = f"{h:02d}:{m:02d} {ampm}"

            # Clock box
            draw.rounded_rectangle([WIDTH//2 - 300, 560, WIDTH//2 + 300, 800], radius=40, fill=(18, 24, 36), outline=(60, 75, 100), width=3)
            draw.text((WIDTH//2, 650), time_str, font=font_clock, fill=WHITE, anchor="mm")
            draw.text((WIDTH//2, 740), "LATE NIGHT ROT", font=font_badge, fill=RED, anchor="mm")

            # Swipe simulation graphic
            draw.rounded_rectangle([WIDTH//2 - 340, 880, WIDTH//2 + 340, 1500], radius=44, fill=(16, 22, 34), outline=(40, 50, 70), width=2)
            draw.text((WIDTH//2, 960), "Endless automatic swipes...", font=font_med, fill=MUTED, anchor="mm")

            # Animated swipe arrow moving upward
            arrow_y = 1380 - int((t * 4 % 1.0) * 280)
            draw.line([WIDTH//2, arrow_y + 40, WIDTH//2, arrow_y - 40], fill=MINT, width=6)
            draw.polygon([(WIDTH//2, arrow_y - 60), (WIDTH//2 - 25, arrow_y - 20), (WIDTH//2 + 25, arrow_y - 20)], fill=MINT)

            # Bottom hook punchline
            draw.text((WIDTH//2, 1620), "2 HOURS GONE.", font=font_huge, fill=RED, anchor="mm")
            draw.text((WIDTH//2, 1720), "Your attention, taken by an algorithm.", font=font_med, fill=MUTED, anchor="mm")

        # ==============================================================
        # SCENE 2: THE REVEAL & THE RUST APP (5.5s - 12.0s)
        # ==============================================================
        elif t < 12.0:
            local_t = t - 5.5
            # Top Badge
            draw.rounded_rectangle([WIDTH//2 - 220, 140, WIDTH//2 + 220, 195], radius=28, fill=(18, 55, 45), outline=MINT, width=2)
            draw.text((WIDTH//2, 167), "OPEN SOURCE · RUST POWERED", font=font_badge, fill=MINT, anchor="mm")

            draw.text((WIDTH//2, 280), "MEET DOOMSCROLLING", font=font_huge, fill=WHITE, anchor="mm")
            draw.text((WIDTH//2, 360), "One video. Your choice.", font=font_med, fill=MINT, anchor="mm")

            # Phone mockup with app-dark.png
            pw, ph = 640, 1160
            px = (WIDTH - pw) // 2
            py = 430
            screen_composite = draw_phone_frame(draw, px, py, pw, ph, img_app)

            # Features below
            draw.rounded_rectangle([WIDTH//2 - 380, 1640, WIDTH//2 + 380, 1780], radius=28, fill=(18, 25, 38), outline=BORDER_COL, width=2)
            draw.text((WIDTH//2, 1690), "🛡️ Intercepts swipes before navigation", font=font_med, fill=WHITE, anchor="mm")
            draw.text((WIDTH//2, 1740), "⚡ 100% On-Device · Zero Internet Permissions", font=font_small, fill=MUTED, anchor="mm")

        # ==============================================================
        # SCENE 3: LIVE DEMO - YOUTUBE SHORTS (12.0s - 19.0s)
        # ==============================================================
        elif t < 19.0:
            local_t = t - 12.0
            # Header
            draw.rounded_rectangle([WIDTH//2 - 200, 130, WIDTH//2 + 200, 185], radius=28, fill=(50, 18, 22), outline=(255, 100, 120), width=2)
            draw.text((WIDTH//2, 157), "YOUTUBE SHORTS DEMO", font=font_badge, fill=(255, 120, 140), anchor="mm")

            pw, ph = 640, 1160
            px = (WIDTH - pw) // 2
            py = 280

            # First 2 seconds show normal video, then swipe occurs
            if local_t < 2.5:
                screen_composite = draw_phone_frame(draw, px, py, pw, ph, img_yt_before)
                draw.text((WIDTH//2, 230), "1. Watch the Short you chose...", font=font_large, fill=WHITE, anchor="mm")
                # Finger gesture preparing
                finger_y = 1100 - int(local_t * 40)
                draw.ellipse([px + pw//2 - 30, finger_y - 30, px + pw//2 + 30, finger_y + 30], fill=(255, 255, 255, 180), outline=MINT, width=4)
            else:
                # Swipe blocked!
                screen_composite = draw_phone_frame(draw, px, py, pw, ph, img_yt_after)
                draw.text((WIDTH//2, 230), "2. You swipe... and it BLOCKS IT!", font=font_large, fill=MINT, anchor="mm")

                # Callout box
                draw.rounded_rectangle([WIDTH//2 - 380, 1480, WIDTH//2 + 380, 1640], radius=28, fill=(22, 42, 36), outline=MINT, width=3)
                draw.text((WIDTH//2, 1535), "“YOU ARE DOOM SCROLLING”", font=font_large, fill=WHITE, anchor="mm")
                draw.text((WIDTH//2, 1600), "Video stays put. The endless spiral stops.", font=font_small, fill=MINT, anchor="mm")

            # Feeds & comments note
            draw.text((WIDTH//2, 1720), "✓ Normal feeds & search still scroll freely", font=font_small, fill=MUTED, anchor="mm")
            draw.text((WIDTH//2, 1765), "✓ Tap playback controls still work", font=font_small, fill=MUTED, anchor="mm")

        # ==============================================================
        # SCENE 4: LIVE DEMO - INSTAGRAM REELS (19.0s - 24.5s)
        # ==============================================================
        elif t < 24.5:
            local_t = t - 19.0
            # Header
            draw.rounded_rectangle([WIDTH//2 - 200, 130, WIDTH//2 + 200, 185], radius=28, fill=(45, 22, 50), outline=(220, 120, 240), width=2)
            draw.text((WIDTH//2, 157), "INSTAGRAM REELS DEMO", font=font_badge, fill=(230, 140, 250), anchor="mm")

            pw, ph = 640, 1160
            px = (WIDTH - pw) // 2
            py = 280

            if local_t < 2.0:
                screen_composite = draw_phone_frame(draw, px, py, pw, ph, img_ig)
                draw.text((WIDTH//2, 230), "Same thing on Instagram Reels...", font=font_large, fill=WHITE, anchor="mm")
            else:
                screen_composite = draw_phone_frame(draw, px, py, pw, ph, img_ig_after)
                draw.text((WIDTH//2, 230), "Next Reel CANNOT take over!", font=font_large, fill=MINT, anchor="mm")

                draw.rounded_rectangle([WIDTH//2 - 380, 1480, WIDTH//2 + 380, 1640], radius=28, fill=(22, 42, 36), outline=MINT, width=3)
                draw.text((WIDTH//2, 1535), "NO ACCIDENTAL REEL SWIPES", font=font_large, fill=WHITE, anchor="mm")
                draw.text((WIDTH//2, 1600), "Enjoy the Reel you clicked. That's it.", font=font_small, fill=MINT, anchor="mm")

            draw.text((WIDTH//2, 1720), "✓ Main feed & explore grid remain 100% normal", font=font_small, fill=MUTED, anchor="mm")

        # ==============================================================
        # SCENE 5: CALL TO ACTION & DOMAIN (24.5s - 30.0s)
        # ==============================================================
        else:
            # Top Badge
            draw.rounded_rectangle([WIDTH//2 - 190, 180, WIDTH//2 + 190, 235], radius=28, fill=(18, 55, 45), outline=MINT, width=2)
            draw.text((WIDTH//2, 207), "FREE & OPEN SOURCE", font=font_badge, fill=MINT, anchor="mm")

            draw.text((WIDTH//2, 330), "TAKE YOUR TIME BACK", font=font_huge, fill=WHITE, anchor="mm")
            draw.text((WIDTH//2, 410), "Available now for Android 11+", font=font_med, fill=MUTED, anchor="mm")

            # Center Card with Logo & Domain
            draw.rounded_rectangle([WIDTH//2 - 380, 520, WIDTH//2 + 380, 1260], radius=44, fill=(18, 25, 38), outline=BORDER_COL, width=3)

            # Shield icon
            shield_x, shield_y = WIDTH//2, 660
            draw.polygon([(shield_x, shield_y - 60), (shield_x + 60, shield_y - 30),
                          (shield_x + 50, shield_y + 40), (shield_x, shield_y + 70),
                          (shield_x - 50, shield_y + 40), (shield_x - 60, shield_y - 30)], fill=(28, 65, 55), outline=MINT, width=4)

            draw.text((WIDTH//2, 800), "DOOMSCROLLING", font=font_huge, fill=WHITE, anchor="mm")
            draw.text((WIDTH//2, 870), "AGPL-3.0 License · Zero Telemetry", font=font_small, fill=MUTED, anchor="mm")

            # Website domain box
            draw.rounded_rectangle([WIDTH//2 - 330, 930, WIDTH//2 + 330, 1040], radius=24, fill=(28, 48, 48), outline=MINT, width=3)
            draw.text((WIDTH//2, 985), "doomscrolling-app.vercel.app", font=font_med, fill=MINT, anchor="mm")

            # Download Button
            draw.rounded_rectangle([WIDTH//2 - 330, 1090, WIDTH//2 + 330, 1200], radius=28, fill=MINT)
            draw.text((WIDTH//2, 1145), "DOWNLOAD APK ⬇", font=font_large, fill=(10, 20, 25), anchor="mm")

            # GitHub link
            draw.text((WIDTH//2, 1370), "github.com/neonjava/doomscrolling", font=font_med, fill=WHITE, anchor="mm")
            draw.text((WIDTH//2, 1430), "⭐ Star the project on GitHub", font=font_small, fill=MUTED, anchor="mm")

            draw.text((WIDTH//2, 1680), "LINK IN BIO", font=font_huge, fill=MINT, anchor="mm")
            draw.text((WIDTH//2, 1750), "Try it today. Stop the scroll.", font=font_med, fill=WHITE, anchor="mm")

        # Paste phone screen if any
        if screen_composite:
            resized_screen, mask, (px, py) = screen_composite
            img.paste(resized_screen, (px, py), mask)

        # Convert to raw RGB bytes and write to ffmpeg stdin
        raw_bytes = img.tobytes("raw", "RGB")
        proc.stdin.write(raw_bytes)

        if frame_idx % 150 == 0:
            print(f"Rendered {frame_idx}/{TOTAL_FRAMES} frames ({t:.1f}s / {DURATION_SEC}s)...")

    proc.stdin.close()
    proc.wait()
    print(f"✓ Video successfully generated at: {OUT_MP4}")
    print(f"File size: {os.path.getsize(OUT_MP4) / (1024*1024):.2f} MB")

if __name__ == "__main__":
    main()
