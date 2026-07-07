#!/usr/bin/env python3
"""
compose-screenshots.py

Programmatically composite App Store screenshots for the 4.3(a) reposition
submission. Takes raw 1320x2868 screenshots from docs/beta/screenshots/drafts/
and produces final 1320x2868 PNGs in docs/beta/screenshots/ with overlay
caption text at the top.

Design: caption band (top 540px, white) + scaled screenshot below, centered.
Auto-shrinks font to fit max width; supports redaction boxes (e.g., covering
last names in Shot 1). Edit the SHOTS list to update captions without touching
layout code.

Usage:
    python3 Tools/compose-screenshots.py

Dependencies:
    Pillow (pip3 install --user Pillow)
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ---------------- Config ----------------

FRAME_W, FRAME_H = 1320, 2868
CAPTION_H = 540
SCREENSHOT_H = FRAME_H - CAPTION_H  # 2328

# Caption layout
TITLE_PT_START = 78
SUB_PT_START = 48
MIN_PT = 32
MAX_TEXT_WIDTH = 1200  # 60px margin each side
TITLE_Y = 150
TITLE_SUB_GAP = 36

# Colors — Provisions Press band (reskin-provisions-press): butcher-paper
# frame blends with the app canvas so the composite reads as one sheet;
# ink title, tomato subtitle
TITLE_COLOR = (32, 29, 26)     # ink #201D1A
SUB_COLOR = (200, 64, 46)      # tomato #C8402E
FRAME_BG = (232, 230, 223)     # butcher paper #E8E6DF
REDACT_FILL = (242, 240, 235)  # card surface (sampled) — invisible patch

# Crate-label faces from the Helvetica Neue collection
TITLE_FONT = ("/System/Library/Fonts/HelveticaNeue.ttc", 9)  # Condensed Black
SUB_FONT = ("/System/Library/Fonts/HelveticaNeue.ttc", 4)    # Condensed Bold

# Mounted-print treatment
MOUNT_MARGIN = 56      # paper margin around the app screen
MOUNT_RADIUS = 64
MOUNT_KEYLINE = 8      # bold ink border

# IO paths (relative to repo root)
DRAFT_DIR = "docs/beta/screenshots/drafts"
OUT_DIR = "docs/beta/screenshots"

# Shots + captions + redactions
# redact: list of (x1, y1, x2, y2) boxes applied to the ORIGINAL 1320x2868 source
# before scaling. Coordinates are in source pixel space.
SHOTS = [
    {
        "filename": "01-household-invite.png",
        "title": "Invite your household with a link.",
        "subtitle": "No account. No signup. No email.",
        # Rectangle over "Hayn" in the "Mary Hayn" row. Coords are in the
        # 1320x2868 source space (build 153 masthead layout, IMG_1958 set).
        "redact": [(394, 1385, 545, 1472)],
    },
    {
        "filename": "02-group-by-store.png",
        "title": "One list. Every store.",
        "subtitle": "Multi-stop shopping without the juggle.",
        "redact": [],
    },
    {
        "filename": "03-recipe-import.png",
        "title": "Import any recipe, parsed on your phone.",
        "subtitle": "Optional AI with your own Anthropic key.",
        "redact": [],
    },
    {
        "filename": "04-dashboard.png",
        "title": "Your week, at a glance.",
        "subtitle": "Meals planned. Groceries ready.",
        "redact": [],
    },
    {
        "filename": "05-recipe-scaling.png",
        "title": "Scale any recipe. Fractions made friendly.",
        "subtitle": "0.25× to 4×, always readable.",
        "redact": [],
    },
]

# ---------------- Implementation ----------------


def load_font(fontspec, pt):
    path, index = fontspec
    return ImageFont.truetype(path, pt, index=index)


def fit_font(text, max_width, start_pt, fontspec):
    """Return (font, pt) that fits text within max_width; shrinks in 4pt steps."""
    pt = start_pt
    probe_img = Image.new("RGB", (1, 1))
    probe_draw = ImageDraw.Draw(probe_img)
    while pt >= MIN_PT:
        font = load_font(fontspec, pt)
        bbox = probe_draw.textbbox((0, 0), text, font=font)
        if bbox[2] - bbox[0] <= max_width:
            return font, pt
        pt -= 4
    return load_font(fontspec, MIN_PT), MIN_PT


def composite(shot):
    input_path = os.path.join(DRAFT_DIR, shot["filename"])
    output_path = os.path.join(OUT_DIR, shot["filename"])

    # Butcher-paper frame
    frame = Image.new("RGB", (FRAME_W, FRAME_H), FRAME_BG)

    # Load source
    src = Image.open(input_path).convert("RGB")

    # Apply redactions on source (pre-scale, coords in source space)
    if shot.get("redact"):
        rdraw = ImageDraw.Draw(src)
        for box in shot["redact"]:
            rdraw.rectangle(box, fill=REDACT_FILL)

    # Mounted-print treatment: inset with margins, rounded corners, bold
    # ink keyline, soft shadow — the app screen reads as a clearly bounded
    # object on the paper instead of blending into the frame
    avail_w = FRAME_W - 2 * MOUNT_MARGIN
    avail_h = SCREENSHOT_H - MOUNT_MARGIN
    src_ratio = src.width / src.height
    new_h = avail_h
    new_w = int(new_h * src_ratio)
    if new_w > avail_w:
        new_w = avail_w
        new_h = int(new_w / src_ratio)
    scaled = src.resize((new_w, new_h), Image.LANCZOS)

    paste_x = (FRAME_W - new_w) // 2
    paste_y = CAPTION_H

    # Shadow
    shadow = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [paste_x + 8, paste_y + 14, paste_x + new_w + 8, paste_y + new_h + 14],
        MOUNT_RADIUS, fill=TITLE_COLOR + (90,))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    frame = Image.alpha_composite(frame.convert("RGBA"), shadow).convert("RGB")

    # Rounded screenshot
    mask = Image.new("L", (new_w, new_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, new_w - 1, new_h - 1], MOUNT_RADIUS, fill=255)
    frame.paste(scaled, (paste_x, paste_y), mask)

    # Bold ink keyline
    ImageDraw.Draw(frame).rounded_rectangle(
        [paste_x, paste_y, paste_x + new_w - 1, paste_y + new_h - 1],
        MOUNT_RADIUS, outline=TITLE_COLOR, width=MOUNT_KEYLINE)

    # Caption text
    draw = ImageDraw.Draw(frame)
    title_font, title_pt = fit_font(shot["title"], MAX_TEXT_WIDTH, TITLE_PT_START, TITLE_FONT)
    sub_font, _ = fit_font(shot["subtitle"], MAX_TEXT_WIDTH, SUB_PT_START, SUB_FONT)

    t_bbox = draw.textbbox((0, 0), shot["title"], font=title_font)
    t_w = t_bbox[2] - t_bbox[0]
    t_h = t_bbox[3] - t_bbox[1]
    t_x = (FRAME_W - t_w) // 2
    draw.text((t_x, TITLE_Y), shot["title"], fill=TITLE_COLOR, font=title_font)

    s_bbox = draw.textbbox((0, 0), shot["subtitle"], font=sub_font)
    s_w = s_bbox[2] - s_bbox[0]
    s_x = (FRAME_W - s_w) // 2
    s_y = TITLE_Y + t_h + TITLE_SUB_GAP
    draw.text((s_x, s_y), shot["subtitle"], fill=SUB_COLOR, font=sub_font)

    frame.save(output_path, optimize=True)
    print(f"✅ {output_path} (title fit at {title_pt}pt)")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for shot in SHOTS:
        composite(shot)
    print(f"\n{len(SHOTS)} screenshots composited into {OUT_DIR}")


if __name__ == "__main__":
    main()
