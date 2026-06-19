#!/usr/bin/env python3
"""把 2026 世界杯官方会徽合成成 macOS App 图标（白色圆角底，各尺寸）。"""
from PIL import Image, ImageDraw
import os

SRC = "/tmp/wc26_emblem.png"
OUT = "/Users/charles/WorldCupWidget/App/Assets.xcassets/AppIcon.appiconset"
os.makedirs(OUT, exist_ok=True)

emblem = Image.open(SRC).convert("RGBA")
bbox = emblem.getbbox()
if bbox:
    emblem = emblem.crop(bbox)   # 去掉透明边

def make(base: int) -> Image.Image:
    icon = Image.new("RGBA", (base, base), (0, 0, 0, 0))
    margin = round(base * 0.06)
    radius = round(base * 0.2237)            # 接近 macOS 圆角
    mask = Image.new("L", (base, base), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [margin, margin, base - margin - 1, base - margin - 1], radius=radius, fill=255)
    white = Image.new("RGBA", (base, base), (255, 255, 255, 255))
    icon = Image.composite(white, icon, mask)

    target = round(base * 0.60)              # 会徽占画布约 60%
    ew, eh = emblem.size
    scale = min(target / ew, target / eh)
    nw, nh = max(1, round(ew * scale)), max(1, round(eh * scale))
    em = emblem.resize((nw, nh), Image.LANCZOS)
    icon.alpha_composite(em, ((base - nw) // 2, (base - nh) // 2))
    return icon

for s in [16, 32, 64, 128, 256, 512, 1024]:
    make(s).save(os.path.join(OUT, f"icon_{s}.png"))
    print("wrote icon_%d.png" % s)
