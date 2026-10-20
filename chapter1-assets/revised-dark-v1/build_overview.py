"""Build a compact review sheet without changing the full-resolution scenes."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
FILES = [
    ("01-control-walkway.png", "CONTROL WALKWAY"),
    ("02-inverted-room.png", "INVERTED ROOM"),
    ("03-maintenance-shaft.png", "MAINTENANCE SHAFT"),
    ("04-engine-room.png", "ENGINE ROOM"),
    ("05-observatory.png", "OBSERVATORY"),
]
FONT_FILE = Path("C:/Windows/Fonts/arialbd.ttf")
font = ImageFont.truetype(str(FONT_FILE), 26) if FONT_FILE.exists() else ImageFont.load_default()
small = ImageFont.truetype(str(FONT_FILE), 19) if FONT_FILE.exists() else ImageFont.load_default()
canvas = Image.new("RGB", (1690, 1640), (18, 27, 48))
draw = ImageDraw.Draw(canvas)
draw.text((42, 22), "CHAPTER I  /  DARK OBSERVATORY CASTLE", fill=(244, 226, 190), font=font)
draw.text((42, 60), "Five matching 2D scene concepts · no characters · 1672 × 941 originals", fill=(184, 201, 220), font=small)

for index, (filename, title) in enumerate(FILES):
    row, col = divmod(index, 2)
    x = 40 + col * 825
    y = 100 + row * 500
    image = Image.open(ROOT / filename).convert("RGB")
    image.thumbnail((800, 450), Image.Resampling.LANCZOS)
    canvas.paste(image, (x, y + 38))
    draw.text((x + 4, y + 2), title, fill=(255, 215, 154), font=small)

canvas.save(ROOT / "overview.png", optimize=True)
print("DARK_CHAPTER_OVERVIEW_OK")
