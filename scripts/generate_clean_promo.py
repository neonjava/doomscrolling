#!/usr/bin/env python3
"""
Generate a 30-second 9:16 vertical promo video for Instagram Reels / TikTok.
Features authentic YouTube Shorts and Instagram Reels UI themes drawn natively with vector graphics.
Zero personal device screenshots are used. Includes sound effects from the starter kit.
"""

import math
import os
from pathlib import Path
import subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFont

WIDTH = 1080
HEIGHT = 1920
FPS = 30
DURATION_SEC = 30
TOTAL_FRAMES = FPS * DURATION_SEC  # 900 frames

ROOT = Path(__file__).resolve().parents[1]
OUT_MP4 = ROOT / "web" / "promo.mp4"
PROMO_KIT = ROOT / "promo-kit"

# Fonts from starter kit
FONT_ARCHIVO = str(PROMO_KIT / "fonts" / "ArchivoBlack-400.woff2")
FONT_INTER_BOLD = str(PROMO_KIT / "fonts" / "Inter-700.woff2")
FONT_INTER_REG = str(PROMO_KIT / "fonts" / "Inter-400.woff2")

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()

# SFX paths
SFX_TICK = str(PROMO_KIT / "sfx" / "tick.wav")
SFX_SWITCH = str(PROMO_KIT / "sfx" / "switch.wav")
SFX_POP = str(PROMO_KIT / "sfx" / "pop.wav")
SFX_SUCCESS = str(PROMO_KIT / "sfx" / "success.wav")

# Palette
BG_DARK = (10, 13, 22)
MINT = (117, 236, 207)
WHITE = (248, 250, 252)
MUTED = (160, 172, 192)
RED_YT = (255, 0, 51)
IG_GRADIENT_START = (131, 58, 180)
IG_GRADIENT_MID = (253, 29, 29)
IG_GRADIENT_END = (252, 176, 69)

# Pre-generate audio soundtrack with mixed sound effects
AUDIO_PATH = "/tmp/clean_soundtrack.m4a"
def generate_soundtrack():
    print("Synthesizing audio soundtrack with SFX...")
    cmd = [
        "ffmpeg", "-y",
        "-f", "lavfi",
        "-i", "aevalsrc=0.08*sin(2*PI*110*t)*(1-abs(sin(2*PI*1.875*t))) + 0.04*sin(2*PI*220*t) + 0.02*sin(2*PI*440*t):s=44100:d=30",
        "-i", SFX_TICK,
        "-i", SFX_SWITCH,
        "-i", SFX_POP,
        "-i", SFX_SUCCESS,
        "-filter_complex", (
            "[1:a]adelay=1000|1000,volume=2.0[t1];"
            "[1:a]adelay=2000|2000,volume=2.0[t2];"
            "[1:a]adelay=3000|3000,volume=2.0[t3];"
            "[2:a]adelay=7500|7500,volume=2.2[sw];"
            "[3:a]adelay=14200|14200,volume=3.0[pop1];"
            "[3:a]adelay=21000|21000,volume=3.0[pop2];"
            "[4:a]adelay=25000|25000,volume=2.5[sfx_end];"
            "[0:a][t1][t2][t3][sw][pop1][pop2][sfx_end]amix=inputs=8:duration=first:dropout_transition=2[aout]"
        ),
        "-map", "[aout]",
        "-c:a", "aac",
        "-b:a", "192k",
        AUDIO_PATH
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

# Helper: Draw authentic YouTube Shorts UI on a target surface
def draw_youtube_shorts_mockup(t_scene, swipe_offset=0, show_toast=False):
    w, h = 640, 1160
    surf = Image.new("RGBA", (w, h), (15, 15, 15, 255))
    d = ImageDraw.Draw(surf)

    font_b = get_font(FONT_INTER_BOLD, 22)
    font_r = get_font(FONT_INTER_REG, 17)
    font_small = get_font(FONT_INTER_REG, 13)
    font_icon = get_font(FONT_INTER_BOLD, 28)

    # 1. Video background content (Stylized dynamic colorful gradient visual)
    # Shifts slightly with swipe_offset
    vy = -swipe_offset
    for row in range(0, h, 20):
        c1 = int(25 + 20 * math.sin((row + vy) * 0.01 + t_scene * 2))
        c2 = int(45 + 30 * math.sin((row + vy) * 0.015 + t_scene * 1.5))
        c3 = int(70 + 40 * math.sin((row + vy) * 0.008 + t_scene))
        d.line([(0, row), (w, row + 20)], fill=(c1, c2, c3, 255), width=20)

    # Center aesthetic video graphic: A pulsating sun & mountains
    sun_y = 480 - int(swipe_offset * 0.5)
    d.ellipse([w//2 - 90, sun_y - 90, w//2 + 90, sun_y + 90], fill=(255, 90, 70, 240))
    d.polygon([(0, 680 - int(swipe_offset*0.7)), (220, 520 - int(swipe_offset*0.7)), (440, 680 - int(swipe_offset*0.7))], fill=(35, 20, 45, 255))
    d.polygon([(200, 680 - int(swipe_offset*0.7)), (420, 500 - int(swipe_offset*0.7)), (w, 680 - int(swipe_offset*0.7))], fill=(25, 15, 35, 255))

    # Dark gradient overlays (top and bottom for legibility)
    d.rectangle([0, 0, w, 140], fill=(0, 0, 0, 130))
    d.rectangle([0, h - 340, w, h], fill=(0, 0, 0, 170))

    # 2. Authentic YouTube Shorts Top Bar
    d.text((36, 40), "Shorts", font=font_b, fill=WHITE)
    d.text((w - 110, 40), "🔍", font=font_r, fill=WHITE)
    d.text((w - 50, 40), "⋮", font=font_b, fill=WHITE)

    # 3. Authentic YouTube Shorts Right Interaction Sidebar
    stack_x = w - 65
    actions = [
        ("👍", "248K", 480),
        ("👎", "Dislike", 570),
        ("💬", "1,842", 660),
        ("↗", "Share", 750),
        ("⟳", "Remix", 840),
    ]
    for icon, label, y in actions:
        d.ellipse([stack_x - 22, y - 22, stack_x + 22, y + 22], fill=(40, 40, 40, 160))
        d.text((stack_x, y), icon, font=font_icon, fill=WHITE, anchor="mm")
        d.text((stack_x, y + 34), label, font=font_small, fill=WHITE, anchor="mm")

    # Rotating audio badge
    rot_angle = (t_scene * 180) % 360
    d.ellipse([stack_x - 22, 940 - 22, stack_x + 22, 940 + 22], fill=(20, 20, 20, 255), outline=WHITE, width=2)
    d.text((stack_x, 940), "🎵", font=font_r, fill=WHITE, anchor="mm")

    # 4. Authentic YouTube Shorts Channel Info & Title
    chan_y = h - 230
    d.ellipse([36, chan_y, 76, chan_y + 40], fill=(230, 60, 60))
    d.text((56, chan_y + 20), "▶", font=font_small, fill=WHITE, anchor="mm")
    d.text((88, chan_y + 20), "@CreatorDaily", font=font_b, fill=WHITE, anchor="lm")
    # Red Subscribe button
    d.rounded_rectangle([250, chan_y + 4, 370, chan_y + 36], radius=16, fill=RED_YT)
    d.text((310, chan_y + 20), "Subscribe", font=font_small, fill=WHITE, anchor="mm")

    d.text((36, chan_y + 65), "Why you shouldn't scroll before bed 🧠⚡", font=font_r, fill=WHITE)
    d.text((36, chan_y + 98), "♫ Original Audio · Tech Podcast", font=font_small, fill=(200, 200, 200))

    # Red scrubber line
    d.line([(0, h - 70), (w, h - 70)], fill=(70, 70, 70), width=4)
    prog_x = int((t_scene * 0.25 % 1.0) * w)
    d.line([(0, h - 70), (prog_x, h - 70)], fill=RED_YT, width=4)
    d.ellipse([prog_x - 5, h - 75, prog_x + 5, h - 65], fill=RED_YT)

    # 5. YouTube Bottom Navigation
    d.rectangle([0, h - 66, w, h], fill=(15, 15, 15, 255))
    navs = [("Home", 64), ("Shorts", 192), ("+", 320), ("Subs", 448), ("You", 576)]
    for name, nx in navs:
        col = WHITE if name == "Shorts" else (140, 140, 140)
        d.text((nx, h - 35), name, font=font_small, fill=col, anchor="mm")

    # 6. DOOMSCROLLING INTERCEPTION TOAST OVERLAY
    if show_toast:
        toast_w, toast_h = 440, 72
        tx = (w - toast_w) // 2
        ty = 130
        d.rounded_rectangle([tx, ty, tx + toast_w, ty + toast_h], radius=24, fill=(20, 30, 42, 248), outline=MINT, width=2)
        d.text((tx + 40, ty + 36), "🛡️", font=font_r, fill=MINT, anchor="mm")
        d.text((tx + 70, ty + 24), "You are doom scrolling", font=font_b, fill=WHITE, anchor="lm")
        d.text((tx + 70, ty + 48), "Swipe blocked · Current video continues", font=font_small, fill=MINT, anchor="lm")

    return surf

# Helper: Draw authentic Instagram Reels UI on a target surface
def draw_instagram_reels_mockup(t_scene, swipe_offset=0, show_toast=False):
    w, h = 640, 1160
    surf = Image.new("RGBA", (w, h), (10, 10, 10, 255))
    d = ImageDraw.Draw(surf)

    font_b = get_font(FONT_INTER_BOLD, 22)
    font_r = get_font(FONT_INTER_REG, 17)
    font_small = get_font(FONT_INTER_REG, 13)
    font_icon = get_font(FONT_INTER_BOLD, 28)

    # 1. Video background content (Stylized city neon twilight visual)
    vy = -swipe_offset
    for row in range(0, h, 20):
        c1 = int(35 + 25 * math.sin((row + vy) * 0.012 + t_scene * 1.8))
        c2 = int(20 + 15 * math.sin((row + vy) * 0.009 + t_scene))
        c3 = int(55 + 35 * math.cos((row + vy) * 0.01 + t_scene * 2))
        d.line([(0, row), (w, row + 20)], fill=(c1, c2, c3, 255), width=20)

    # Modern city geometric silhouetting
    for bx in range(30, w, 90):
        bh = 380 + int(70 * math.sin(bx * 0.05))
        d.rectangle([bx, h - bh - swipe_offset, bx + 70, h - swipe_offset], fill=(12, 10, 24, 255))
        # Windows
        for wy in range(h - bh + 30, h - 80, 50):
            d.rectangle([bx + 15, wy - swipe_offset, bx + 28, wy + 16 - swipe_offset], fill=(255, 230, 140, 200))
            d.rectangle([bx + 42, wy - swipe_offset, bx + 55, wy + 16 - swipe_offset], fill=(255, 230, 140, 200))

    d.rectangle([0, 0, w, 120], fill=(0, 0, 0, 110))
    d.rectangle([0, h - 300, w, h], fill=(0, 0, 0, 160))

    # 2. Authentic Instagram Reels Top Bar
    d.text((36, 40), "Reels", font=font_b, fill=WHITE)
    d.text((w - 50, 40), "📷", font=font_r, fill=WHITE)

    # 3. Authentic Instagram Reels Right Interaction Sidebar
    stack_x = w - 60
    actions = [
        ("🤍", "94.2K", 520),
        ("💬", "1,208", 610),
        ("✈", "42K", 700),
        ("⋮", "", 780),
    ]
    for icon, label, y in actions:
        d.text((stack_x, y), icon, font=font_icon, fill=WHITE, anchor="mm")
        if label:
            d.text((stack_x, y + 30), label, font=font_small, fill=WHITE, anchor="mm")

    # Vinyl disc audio badge
    d.ellipse([stack_x - 18, 860 - 18, stack_x + 18, 860 + 18], fill=(30, 30, 30, 255), outline=(100, 100, 100), width=3)
    d.ellipse([stack_x - 6, 860 - 6, stack_x + 6, 860 + 6], fill=WHITE)

    # 4. Authentic Instagram Creator Info
    chan_y = h - 210
    # Gradient Instagram story ring
    d.ellipse([34, chan_y - 2, 78, chan_y + 42], outline=(250, 50, 100), width=3)
    d.ellipse([38, chan_y + 2, 74, chan_y + 38], fill=(60, 80, 120))
    d.text((56, chan_y + 20), "👤", font=font_small, fill=WHITE, anchor="mm")

    d.text((90, chan_y + 20), "code.intention", font=font_b, fill=WHITE, anchor="lm")
    # Follow button pill
    d.rounded_rectangle([255, chan_y + 6, 335, chan_y + 34], radius=8, outline=WHITE, fill=(0, 0, 0, 0), width=2)
    d.text((295, chan_y + 20), "Follow", font=font_small, fill=WHITE, anchor="mm")

    d.text((36, chan_y + 60), "When you promised yourself 'just one reel' 💀", font=font_r, fill=WHITE)
    d.text((36, chan_y + 90), "🎵 trending audio · viral reel sound", font=font_small, fill=(210, 210, 210))

    # 5. Instagram Bottom Navigation Bar
    d.rectangle([0, h - 60, w, h], fill=(0, 0, 0, 255))
    d.text((64, h - 30), "⌂", font=font_icon, fill=(150, 150, 150), anchor="mm")
    d.text((192, h - 30), "🔍", font=font_r, fill=(150, 150, 150), anchor="mm")
    d.text((320, h - 30), "⊞", font=font_icon, fill=(150, 150, 150), anchor="mm")
    d.text((448, h - 30), "🎞️", font=font_r, fill=WHITE, anchor="mm")
    d.ellipse([576 - 12, h - 42, 576 + 12, h - 18], fill=(120, 120, 120))

    # 6. DOOMSCROLLING INTERCEPTION TOAST OVERLAY
    if show_toast:
        toast_w, toast_h = 440, 72
        tx = (w - toast_w) // 2
        ty = 130
        d.rounded_rectangle([tx, ty, tx + toast_w, ty + toast_h], radius=24, fill=(20, 30, 42, 248), outline=MINT, width=2)
        d.text((tx + 40, ty + 36), "🛡️", font=font_r, fill=MINT, anchor="mm")
        d.text((tx + 70, ty + 24), "You are doom scrolling", font=font_b, fill=WHITE, anchor="lm")
        d.text((tx + 70, ty + 48), "Swipe blocked · Next reel stopped", font=font_small, fill=MINT, anchor="lm")

    return surf

# Helper: Draw Doomscrolling App UI Mockup (Dark iOS Tahoe theme)
def draw_doomscrolling_app_mockup(switch_on=True):
    w, h = 640, 1160
    surf = Image.new("RGBA", (w, h), (14, 18, 26, 255))
    d = ImageDraw.Draw(surf)

    font_huge = get_font(FONT_INTER_BOLD, 36)
    font_b = get_font(FONT_INTER_BOLD, 22)
    font_r = get_font(FONT_INTER_REG, 17)
    font_small = get_font(FONT_INTER_REG, 13)

    # Top header
    d.text((40, 50), "Doomscrolling", font=font_b, fill=WHITE)
    # On Device Mint badge
    d.rounded_rectangle([w - 150, 42, w - 40, 78], radius=18, fill=(20, 50, 45), outline=MINT, width=2)
    d.text((w - 95, 60), "ON DEVICE", font=font_small, fill=MINT, anchor="mm")

    # Center Hero Card
    d.text((w//2, 170), "One video.", font=font_huge, fill=WHITE, anchor="mm")
    d.text((w//2, 215), "Your choice.", font=font_huge, fill=MINT, anchor="mm")
    d.text((w//2, 265), "Watch the Short or Reel you chose.", font=font_small, fill=MUTED, anchor="mm")
    d.text((w//2, 290), "Stop the swipe from deciding for you.", font=font_small, fill=MUTED, anchor="mm")

    # Main Master Switch Card
    d.rounded_rectangle([36, 330, w - 36, 440], radius=24, fill=(24, 33, 48), outline=(50, 65, 85), width=2)
    d.text((64, 370), "Protection", font=font_b, fill=WHITE)
    status_sub = "Active · Covering next swipe" if switch_on else "Paused"
    d.text((64, 400), status_sub, font=font_small, fill=MINT if switch_on else MUTED)
    # Switch toggle graphic
    sw_x = w - 110
    sw_col = MINT if switch_on else (60, 70, 85)
    d.rounded_rectangle([sw_x, 365, sw_x + 55, 395], radius=15, fill=sw_col)
    thumb_x = sw_x + 40 if switch_on else sw_x + 15
    d.ellipse([thumb_x - 12, 380 - 12, thumb_x + 12, 380 + 12], fill=WHITE)

    # Protected Apps Header
    d.text((40, 475), "PROTECTED APPS", font=font_small, fill=MUTED)

    # App switches card
    d.rounded_rectangle([36, 505, w - 36, 690], radius=24, fill=(24, 33, 48), outline=(50, 65, 85), width=2)
    # YouTube row
    d.rounded_rectangle([60, 530, 96, 566], radius=10, fill=RED_YT)
    d.text((78, 548), "▶", font=font_small, fill=WHITE, anchor="mm")
    d.text((115, 538), "YouTube Shorts", font=font_b, fill=WHITE)
    d.text((115, 562), "Shorts guarded · Feeds stay free", font=font_small, fill=MUTED)
    # Switch on
    d.rounded_rectangle([sw_x, 535, sw_x + 55, 565], radius=15, fill=MINT)
    d.ellipse([sw_x + 40 - 12, 550 - 12, sw_x + 40 + 12, 550 + 12], fill=WHITE)

    d.line([(60, 595), (w - 60, 595)], fill=(40, 50, 65), width=1)

    # Instagram row
    d.rounded_rectangle([60, 620, 96, 656], radius=10, fill=(160, 40, 110))
    d.text((78, 638), "▣", font=font_small, fill=WHITE, anchor="mm")
    d.text((115, 628), "Instagram Reels", font=font_b, fill=WHITE)
    d.text((115, 652), "Reels guarded · Feeds stay free", font=font_small, fill=MUTED)
    # Switch on
    d.rounded_rectangle([sw_x, 625, sw_x + 55, 655], radius=15, fill=MINT)
    d.ellipse([sw_x + 40 - 12, 640 - 12, sw_x + 40 + 12, 640 + 12], fill=WHITE)

    # Architecture Info Badge Card
    d.rounded_rectangle([36, 730, w - 36, 910], radius=24, fill=(20, 27, 40), outline=(40, 55, 75), width=2)
    d.text((w//2, 770), "⚡ RUST CORE ENGINE", font=font_b, fill=MINT, anchor="mm")
    d.text((w//2, 815), "Evaluates screen nodes locally in RAM", font=font_r, fill=WHITE, anchor="mm")
    d.text((w//2, 850), "Zero Internet Permission · Zero Telemetry", font=font_small, fill=MUTED, anchor="mm")

    # Bottom status indicator
    d.rounded_rectangle([36, 950, w - 36, 1040], radius=20, fill=(18, 45, 38), outline=MINT, width=2)
    d.text((w//2, 980), "STATUS: ACTIVE & READY", font=font_b, fill=MINT, anchor="mm")
    d.text((w//2, 1010), "Open any Short or Reel on your phone", font=font_small, fill=WHITE, anchor="mm")

    return surf

def main():
    generate_soundtrack()
    print(f"Rendering 30s clean promo video with genuine YouTube and Instagram themes ({WIDTH}x{HEIGHT} @ {FPS}fps)...")

    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",  # Video from stdin
        "-i", AUDIO_PATH,
        "-c:v", "libopenh264",
        "-b:v", "5M",
        "-pix_fmt", "yuv420p",
        "-c:a", "copy",
        "-shortest",
        str(OUT_MP4)
    ]

    proc = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)

    font_archivo_huge = get_font(FONT_ARCHIVO, 84)
    font_archivo_title = get_font(FONT_ARCHIVO, 64)
    font_inter_large = get_font(FONT_INTER_BOLD, 48)
    font_inter_med = get_font(FONT_INTER_REG, 36)
    font_inter_small = get_font(FONT_INTER_REG, 26)
    font_badge = get_font(FONT_INTER_BOLD, 24)

    for frame_idx in range(TOTAL_FRAMES):
        t = frame_idx / FPS  # Time in seconds

        canvas = Image.new("RGBA", (WIDTH, HEIGHT), (*BG_DARK, 255))
        d = ImageDraw.Draw(canvas)

        # Ambient background lighting glow
        pulse = 0.5 + 0.5 * math.sin(t * 2)
        glow_r = int(450 + pulse * 50)
        d.ellipse([WIDTH//2 - glow_r, 880 - glow_r, WIDTH//2 + glow_r, 880 + glow_r], fill=(16, 26, 42, 255))

        # ==============================================================
        # SCENE 1: THE LATE NIGHT SPIRAL (0.0s - 5.5s)
        # ==============================================================
        if t < 5.5:
            # Top Badge
            d.rounded_rectangle([WIDTH//2 - 200, 160, WIDTH//2 + 200, 215], radius=28, fill=(35, 20, 25), outline=(255, 90, 90), width=2)
            d.text((WIDTH//2, 187), "THE SCROLLING SPIRAL", font=font_badge, fill=(255, 110, 110), anchor="mm")

            d.text((WIDTH//2, 310), "YOU OPENED", font=font_archivo_title, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 390), "ONE SHORT VIDEO.", font=font_archivo_huge, fill=MINT, anchor="mm")

            # Rolling clock graphic
            clock_prog = min(1.0, t / 4.2)
            cur_mins = int(clock_prog * 165)
            ch = 11 + (cur_mins // 60)
            if ch > 12: ch -= 12
            cm = cur_mins % 60
            ampm = "PM" if (11 + (cur_mins // 60)) < 12 else "AM"
            time_str = f"{ch:02d}:{cm:02d} {ampm}"

            # Clock card
            d.rounded_rectangle([WIDTH//2 - 320, 520, WIDTH//2 + 320, 800], radius=36, fill=(18, 25, 38), outline=(60, 75, 105), width=3)
            d.text((WIDTH//2, 630), time_str, font=get_font(FONT_ARCHIVO, 96), fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 730), "⏰ 2 HOURS LOST IN BED", font=font_badge, fill=(255, 100, 100), anchor="mm")

            # Illustrative animated swipe trail
            d.rounded_rectangle([WIDTH//2 - 320, 860, WIDTH//2 + 320, 1480], radius=40, fill=(14, 20, 32), outline=(40, 50, 70), width=2)
            d.text((WIDTH//2, 940), "Auto-swipe loop took over...", font=font_inter_med, fill=MUTED, anchor="mm")

            # Upward moving swipe indicator
            loop_t = (t * 2.8) % 1.0
            swipe_y = 1360 - int(loop_t * 320)
            d.line([(WIDTH//2, swipe_y + 60), (WIDTH//2, swipe_y - 40)], fill=MINT, width=8)
            d.polygon([(WIDTH//2, swipe_y - 70), (WIDTH//2 - 30, swipe_y - 30), (WIDTH//2 + 30, swipe_y - 30)], fill=MINT)

            d.text((WIDTH//2, 1600), "PUT A STOP TO IT.", font=font_archivo_title, fill=(255, 90, 90), anchor="mm")
            d.text((WIDTH//2, 1680), "What if you could watch without the spiral?", font=font_inter_med, fill=WHITE, anchor="mm")

        # ==============================================================
        # SCENE 2: THE SOLUTION - DOOMSCROLLING (5.5s - 11.0s)
        # ==============================================================
        elif t < 11.0:
            local_t = t - 5.5
            d.rounded_rectangle([WIDTH//2 - 220, 130, WIDTH//2 + 220, 185], radius=28, fill=(18, 55, 45), outline=MINT, width=2)
            d.text((WIDTH//2, 157), "BUILT WITH RUST · ON-DEVICE", font=font_badge, fill=MINT, anchor="mm")

            d.text((WIDTH//2, 260), "MEET DOOMSCROLLING", font=font_archivo_title, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 330), "One video. Your choice.", font=font_inter_large, fill=MINT, anchor="mm")

            # Switch toggles on at local_t = 2.0s
            is_sw_on = local_t >= 2.0
            app_mockup = draw_doomscrolling_app_mockup(switch_on=is_sw_on)

            # Outer phone bezel frame
            pw, ph = 640, 1160
            px, py = (WIDTH - pw)//2, 400
            d.rounded_rectangle([px - 12, py - 12, px + pw + 12, py + ph + 12], radius=56, fill=(28, 36, 50), outline=(70, 85, 110), width=2)
            canvas.paste(app_mockup, (px, py))

            # Bottom feature callout
            d.rounded_rectangle([WIDTH//2 - 400, 1640, WIDTH//2 + 400, 1780], radius=28, fill=(18, 25, 38), outline=(50, 65, 85), width=2)
            d.text((WIDTH//2, 1690), "🛡️ Stops video-to-video gestures", font=font_inter_med, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 1740), "Feeds, comments, and taps remain 100% usable", font=font_inter_small, fill=MUTED, anchor="mm")

        # ==============================================================
        # SCENE 3: YOUTUBE SHORTS DEMO (11.0s - 18.0s)
        # ==============================================================
        elif t < 18.0:
            local_t = t - 11.0
            d.rounded_rectangle([WIDTH//2 - 200, 110, WIDTH//2 + 200, 165], radius=28, fill=(50, 18, 24), outline=RED_YT, width=2)
            d.text((WIDTH//2, 137), "YOUTUBE SHORTS DEMO", font=font_badge, fill=(255, 120, 130), anchor="mm")

            # Gesture simulation:
            # 0 to 2.5s: video plays peacefully
            # 2.5s to 3.2s: user swipes up
            # 3.2s onwards: swipe blocked & toast displays!
            swipe_offset = 0
            show_toast = False
            if local_t < 2.5:
                d.text((WIDTH//2, 215), "1. Watch the Short you opened...", font=font_inter_large, fill=WHITE, anchor="mm")
            elif local_t < 3.2:
                # Swiping up!
                swipe_p = (local_t - 2.5) / 0.7
                swipe_offset = int(math.sin(swipe_p * math.pi) * 90)
                d.text((WIDTH//2, 215), "2. You attempt to swipe...", font=font_inter_large, fill=WHITE, anchor="mm")
            else:
                # Blocked!
                show_toast = True
                d.text((WIDTH//2, 215), "SWIPE IS BLOCKED!", font=font_archivo_title, fill=MINT, anchor="mm")

            yt_mockup = draw_youtube_shorts_mockup(local_t, swipe_offset=swipe_offset, show_toast=show_toast)
            pw, ph = 640, 1160
            px, py = (WIDTH - pw)//2, 280
            d.rounded_rectangle([px - 12, py - 12, px + pw + 12, py + ph + 12], radius=56, fill=(28, 36, 50), outline=RED_YT if local_t < 3.2 else MINT, width=2)
            canvas.paste(yt_mockup, (px, py))

            # Bottom reminder
            d.rounded_rectangle([WIDTH//2 - 380, 1520, WIDTH//2 + 380, 1660], radius=28, fill=(20, 35, 42), outline=MINT, width=3)
            d.text((WIDTH//2, 1570), "“YOU ARE DOOM SCROLLING”", font=font_inter_large, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 1620), "Next video never loads · Spiral stopped", font=font_inter_small, fill=MINT, anchor="mm")

            d.text((WIDTH//2, 1730), "✓ Main feed & search still scroll completely free", font=font_inter_small, fill=MUTED, anchor="mm")

        # ==============================================================
        # SCENE 4: INSTAGRAM REELS DEMO (18.0s - 24.5s)
        # ==============================================================
        elif t < 24.5:
            local_t = t - 18.0
            d.rounded_rectangle([WIDTH//2 - 200, 110, WIDTH//2 + 200, 165], radius=28, fill=(50, 20, 50), outline=(220, 80, 240), width=2)
            d.text((WIDTH//2, 137), "INSTAGRAM REELS DEMO", font=font_badge, fill=(230, 120, 250), anchor="mm")

            swipe_offset = 0
            show_toast = False
            if local_t < 2.0:
                d.text((WIDTH//2, 215), "Same protection for Reels...", font=font_inter_large, fill=WHITE, anchor="mm")
            elif local_t < 2.8:
                swipe_p = (local_t - 2.0) / 0.8
                swipe_offset = int(math.sin(swipe_p * math.pi) * 85)
                d.text((WIDTH//2, 215), "Swiping to next Reel...", font=font_inter_large, fill=WHITE, anchor="mm")
            else:
                show_toast = True
                d.text((WIDTH//2, 215), "NEXT REEL CANNOT START!", font=font_archivo_title, fill=MINT, anchor="mm")

            ig_mockup = draw_instagram_reels_mockup(local_t, swipe_offset=swipe_offset, show_toast=show_toast)
            pw, ph = 640, 1160
            px, py = (WIDTH - pw)//2, 280
            d.rounded_rectangle([px - 12, py - 12, px + pw + 12, py + ph + 12], radius=56, fill=(28, 36, 50), outline=(220, 80, 240) if local_t < 2.8 else MINT, width=2)
            canvas.paste(ig_mockup, (px, py))

            d.rounded_rectangle([WIDTH//2 - 380, 1520, WIDTH//2 + 380, 1660], radius=28, fill=(20, 35, 42), outline=MINT, width=3)
            d.text((WIDTH//2, 1570), "NO MORE ENDLESS REELS", font=font_inter_large, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 1620), "Enjoy the reel you wanted. Stop there.", font=font_inter_small, fill=MINT, anchor="mm")

            d.text((WIDTH//2, 1730), "✓ Feed posts & Explore grid remain 100% untouched", font=font_inter_small, fill=MUTED, anchor="mm")

        # ==============================================================
        # SCENE 5: CALL TO ACTION (24.5s - 30.0s)
        # ==============================================================
        else:
            d.rounded_rectangle([WIDTH//2 - 190, 170, WIDTH//2 + 190, 225], radius=28, fill=(18, 55, 45), outline=MINT, width=2)
            d.text((WIDTH//2, 197), "FREE & OPEN SOURCE", font=font_badge, fill=MINT, anchor="mm")

            d.text((WIDTH//2, 310), "TAKE YOUR TIME BACK", font=font_archivo_huge, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 390), "Available now for Android 11+", font=font_inter_large, fill=MUTED, anchor="mm")

            # Outro card
            d.rounded_rectangle([WIDTH//2 - 380, 480, WIDTH//2 + 380, 1260], radius=44, fill=(18, 25, 38), outline=(60, 75, 100), width=3)

            # Shield icon
            sx, sy = WIDTH//2, 630
            d.polygon([(sx, sy - 60), (sx + 60, sy - 30), (sx + 50, sy + 40), (sx, sy + 70), (sx - 50, sy + 40), (sx - 60, sy - 30)], fill=(25, 65, 55), outline=MINT, width=4)

            d.text((WIDTH//2, 780), "DOOMSCROLLING", font=font_archivo_title, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 850), "AGPL-3.0 License · Zero Telemetry", font=font_inter_small, fill=MUTED, anchor="mm")

            # Domain pill
            d.rounded_rectangle([WIDTH//2 - 330, 910, WIDTH//2 + 330, 1020], radius=24, fill=(28, 48, 48), outline=MINT, width=3)
            d.text((WIDTH//2, 965), "doomscrolling-app.vercel.app", font=font_inter_med, fill=MINT, anchor="mm")

            # Download button
            d.rounded_rectangle([WIDTH//2 - 330, 1070, WIDTH//2 + 330, 1180], radius=28, fill=MINT)
            d.text((WIDTH//2, 1125), "DOWNLOAD APK ⬇", font=font_inter_large, fill=(10, 20, 25), anchor="mm")

            d.text((WIDTH//2, 1360), "github.com/neonjava/doomscrolling", font=font_inter_med, fill=WHITE, anchor="mm")
            d.text((WIDTH//2, 1420), "⭐ Star the project on GitHub", font=font_inter_small, fill=MUTED, anchor="mm")

            d.text((WIDTH//2, 1660), "LINK IN BIO", font=font_archivo_huge, fill=MINT, anchor="mm")
            d.text((WIDTH//2, 1740), "Stop doomscrolling today.", font=font_inter_large, fill=WHITE, anchor="mm")

        # Convert canvas to RGB raw bytes and write to ffmpeg
        raw = canvas.convert("RGB").tobytes("raw", "RGB")
        proc.stdin.write(raw)

        if frame_idx % 150 == 0:
            print(f"Rendered {frame_idx}/{TOTAL_FRAMES} frames ({t:.1f}s / {DURATION_SEC}s)...")

    proc.stdin.close()
    proc.wait()
    print(f"✓ Promo video generated successfully at: {OUT_MP4}")
    print(f"File size: {os.path.getsize(OUT_MP4) / (1024*1024):.2f} MB")

if __name__ == "__main__":
    main()
