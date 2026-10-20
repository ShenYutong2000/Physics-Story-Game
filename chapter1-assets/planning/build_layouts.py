"""Rebuild checkpoint-1 review diagrams from unchanged castle references.

Uses Pillow only. Run from any directory with a Python that has Pillow installed.
The overlays express provisional planning coordinates, not collision geometry.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
REF = ROOT / "reference"
OUT = ROOT / "layouts"
OUT.mkdir(exist_ok=True)

GREEN = (73, 235, 158, 255)
CYAN = (97, 221, 255, 255)
YELLOW = (255, 222, 111, 255)
CORAL = (255, 111, 113, 255)
WHITE = (249, 247, 237, 255)
NAVY = (18, 29, 56, 224)


def font(size: int, bold: bool = False):
    name = "arialbd.ttf" if bold else "arial.ttf"
    file = Path("C:/Windows/Fonts") / name
    return ImageFont.truetype(str(file), size) if file.exists() else ImageFont.load_default()


TITLE_FONT = font(36, True)
LABEL_FONT = font(23, True)
SMALL_FONT = font(18)


ROOMS = [
    {
        "id": "control-walkway",
        "title": "01  CONTROL WALKWAY  ·  FIXED TOWER",
        "paths": [[(85, 737), (625, 737)]],
        "labels": [
            ((125, 737), (20, 570), "Service Road return", YELLOW),
            ((395, 350), (260, 425), "Position needle", CYAN),
            ((565, 690), (445, 545), "Erin / control station", CYAN),
            ((1365, 275), (1210, 580), "Separate moving wing", CYAN),
            ((800, 507), (690, 600), "Raised bridge — no floor link", CORAL),
            ((1540, 125), (1120, 110), "Document wing pivot", CORAL),
        ],
    },
    {
        "id": "inverted-room",
        "title": "02  INVERTED ROOM  ·  ROTATING WING",
        "paths": [[(105, 815), (740, 815), (1500, 815)]],
        "labels": [
            ((130, 809), (18, 610), "Entry from misaligned wing", YELLOW),
            ((1530, 808), (1200, 680), "Lower service exit needs landing", CORAL),
            ((930, 90), (690, 115), "Broken pipe in old floor", CORAL),
            ((941, 645), (710, 540), "Drops fall screen-down", CYAN),
            ((872, 605), (750, 370), "Hanging chain / plumb", CYAN),
            ((1370, 120), (1200, 210), "Extinguish upper fireplace", CORAL),
        ],
    },
    {
        "id": "maintenance-shaft",
        "title": "03  MAINTENANCE SHAFT  ·  FIXED FRAME",
        "paths": [[(80, 790), (820, 790)], [(1210, 455), (1600, 455)]],
        "labels": [
            ((105, 780), (12, 565), "Lower route from room", YELLOW),
            ((486, 685), (265, 525), "Winch and brake", CYAN),
            ((1090, 82), (875, 115), "Upper fixed pulley", CYAN),
            ((1090, 304), (870, 355), "Basket moving pulley", CYAN),
            ((1100, 467), (820, 590), "Basket / docking states", CYAN),
            ((1450, 450), (1250, 560), "Erin ledge — not walkable from below", YELLOW),
            ((820, 385), (460, 260), "Rebuild both rope routings", CORAL),
        ],
    },
    {
        "id": "engine-room",
        "title": "04  ENGINE ROOM  ·  FIXED SERVICE CORE",
        "paths": [[(80, 647), (1570, 647)]],
        "labels": [
            ((90, 645), (15, 740), "Entry from rescue platform", YELLOW),
            ((1550, 645), (1300, 740), "Restored-wing exit", YELLOW),
            ((400, 240), (45, 420), "Station purpose diagram", CYAN),
            ((830, 389), (620, 135), "Normal stop linkage", CORAL),
            ((1120, 500), (950, 600), "Signal / brake / lock states", CYAN),
            ((1230, 555), (1250, 370), "Separate backup lock needed", CORAL),
        ],
    },
    {
        "id": "observatory",
        "title": "05  OBSERVATORY  ·  RESTORED WING",
        "paths": [[(100, 830), (1560, 830)]],
        "labels": [
            ((1530, 825), (1280, 670), "Entry after restoration", YELLOW),
            ((370, 640), (145, 730), "Signed records / drawer", CYAN),
            ((740, 480), (630, 600), "Telescope stays separate", CYAN),
            ((400, 510), (130, 390), "Floating Isles slip", CYAN),
            ((1120, 215), (1010, 330), "Exterior must match restored pose", CORAL),
        ],
    },
]


def draw_label(draw: ImageDraw.ImageDraw, point, box_xy, text, color):
    x, y = box_xy
    bounds = draw.textbbox((0, 0), text, font=LABEL_FONT)
    width = bounds[2] + 28
    height = bounds[3] - bounds[1] + 25
    x = min(x, 1660 - width)
    y = min(y, 868 - height)
    center = (x + width // 2, y + height // 2)
    draw.line([point, center], fill=(13, 23, 45, 240), width=8)
    draw.line([point, center], fill=color, width=4)
    draw.ellipse((point[0] - 8, point[1] - 8, point[0] + 8, point[1] + 8), fill=color)
    draw.rounded_rectangle((x, y, x + width, y + height), radius=12, fill=NAVY, outline=color, width=3)
    draw.text((x + 14, y + 9), text, fill=WHITE, font=LABEL_FONT)


def render_room(room):
    image = Image.open(REF / f"{room['id']}.png").convert("RGBA")
    assert image.size == (1672, 941), room["id"]
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rectangle((0, 0, 1672, 89), fill=(18, 29, 56, 239))
    draw.text((28, 18), room["title"], fill=WHITE, font=TITLE_FONT)
    draw.rectangle((0, 868, 1672, 941), fill=(18, 29, 56, 232))
    draw.text((30, 889), "GREEN  safe foot path     CYAN  future object     YELLOW  spawn/exit     CORAL  redraw or resolve", fill=WHITE, font=SMALL_FONT)
    for path in room["paths"]:
        draw.line(path, fill=(12, 40, 37, 245), width=13, joint="curve")
        draw.line(path, fill=GREEN, width=7, joint="curve")
        for point in (path[0], path[-1]):
            draw.ellipse((point[0] - 8, point[1] - 8, point[0] + 8, point[1] + 8), fill=GREEN)
    for point, box, text, color in room["labels"]:
        draw_label(draw, point, box, text, color)
    result = Image.alpha_composite(image, overlay).convert("RGB")
    result.save(OUT / f"{room['id']}-layout.png", optimize=True)


def render_topology():
    im = Image.new("RGB", (1800, 690), (24, 39, 73))
    d = ImageDraw.Draw(im)
    d.text((50, 28), "CHAPTER I  ·  SCENE TOPOLOGY", fill=WHITE, font=font(43, True))
    d.text((50, 91), "Solid arrows: story sequence after the relevant event.  Preview uses a separate route.", fill=(191, 213, 235), font=font(25))
    nodes = [
        (60, 270, "SERVICE ROAD", "Fixed approach", YELLOW),
        (360, 270, "CONTROL", "Fixed tower", CYAN),
        (660, 270, "INVERTED ROOM", "Rotating wing", CORAL),
        (960, 270, "SHAFT", "Fixed frame", CYAN),
        (1260, 270, "ENGINE", "Fixed core", CYAN),
        (1560, 270, "OBSERVATORY", "Restored wing", GREEN),
    ]
    for i in range(len(nodes) - 1):
        x1 = nodes[i][0] + 225
        x2 = nodes[i + 1][0] - 12
        d.line((x1, 337, x2, 337), fill=YELLOW, width=7)
        d.polygon(((x2, 337), (x2 - 15, 326), (x2 - 15, 348)), fill=YELLOW)
    for x, y, name, desc, edge in nodes:
        d.rounded_rectangle((x, y, x + 225, y + 135), radius=16, fill=(35, 56, 100), outline=edge, width=4)
        d.text((x + 15, y + 32), name, fill=WHITE, font=font(24, True))
        d.text((x + 15, y + 77), desc, fill=(213, 224, 240), font=font(20))
    d.text((395, 185), "STORY ENTRY", fill=YELLOW, font=font(20, True))
    d.text((685, 185), "AFTER ON-SITE INVERSION", fill=CORAL, font=font(20, True))
    d.text((1550, 185), "AFTER RESTORATION", fill=GREEN, font=font(20, True))
    d.rounded_rectangle((300, 505, 1530, 618), radius=18, fill=(42, 62, 105), outline=(133, 160, 200), width=2)
    d.text((330, 530), "STAGE-TWO PREVIEW: five-room walkthrough in a separate test entry.", fill=WHITE, font=font(27, True))
    d.text((330, 573), "The actual game stops at the Control Walkway until the incident is built.", fill=(214, 226, 241), font=font(23))
    im.save(OUT / "scene-topology.png", optimize=True)


if __name__ == "__main__":
    for room in ROOMS:
        render_room(room)
    render_topology()
    print("CHECKPOINT1_LAYOUTS_OK", OUT)
