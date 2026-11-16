# 序章美术方向 v2：绘本水粉 · 严格蒸汽朋克

范围：只覆盖序章的六个画面（标题、万象馆大厅、机械维护室、顶层书库、Kath 的房间、维修路）。第一章不动。

本文件有两个用途：

1. 记录新的美术方向，以及它和 v1（平涂、靛蓝为主）的区别。
2. 提供可以直接交给图像生成工具的逐场景重绘提示词。提示词用英文写，因为 v1 的 `prologue-asset-pack-v1/docs/prompts.json` 也是英文，出图工具对英文更稳定。

## 1. v1 的问题

- 整屏是靛蓝和紫色，暖色只出现在灯和黄铜上。画面读起来像"奇幻夜景"，不像被煤气灯和锅炉烘暖的蒸汽朋克室内。
- 全部是尺规般的直线和纯平涂色块，没有手绘痕迹，显得像矢量模板。
- 细节密度低：书架是重复的色条，墙面大片空白，没有"这里有人生活和工作"的痕迹。
- 机械只是装饰：管道不通向任何地方，没有压力表、阀门、铆钉、煤灰和蒸汽。

## 2. 从参考图里取什么、不取什么

参考图只用于风格分析，不复制其中的角色、构图或文字，也不放进发行包（见 `docs/ASSET_SOURCES.md`）。

| 参考图 | 取用 | 不取用（会破坏蒸汽朋克设定） |
| --- | --- | --- |
| 黑猫茶屋 | 赭石和橙红的整体暖调；歪歪扭扭的手切形状；塞满小物件的货架；用藤蔓做画框 | 女巫、幽灵、木乃伊、魔法药水。画框改为铜管、阀门和线缆 |
| 兔子与电视 | 粗颗粒、套印错位的印刷感；圆头的信号牌和指示杆 | 显像管电视、霓虹、电子屏。改为信号臂、气动管道站、机械指示牌 |
| 彩色玻璃楼梯 | 厚重的红、琥珀、青绿彩窗；单一球形灯把整个空间染暖；贴满便签的墙 | 无 |
| 列车包厢 | 深色木镶板加黄铜包边；红色天鹅绒；橙色灯罩；窗外是冷青色的夜 | 无（这张最接近目标） |
| 紫色兔子房间 | 高密度的小物件；每盏灯有自己的光晕 | 霓虹紫粉色、电子游戏机 |
| 猫咪阁楼 | 蜡笔和水粉的粗笔触；阳光投下的硬边暖色影子 | 高饱和的糖果蓝墙面 |
| 怪兽片场海报 | 深青绿底色配朱红的两色对比；聚光灯光锥 | 现代摄影器材 |

## 3. 风格规则

**色彩。** 画面里暖色占大头，冷色只做阴影和窗外。

| 名称 | 色值 | 用途 |
| --- | --- | --- |
| 煤烟棕 | `#2A1E1A` | 最深的暗部，取代 v1 的午夜靛蓝 |
| 胡桃木 | `#6B3F2A` | 木镶板、家具、书架 |
| 旧黄铜 | `#B8893E` | 管道、栏杆、仪表外壳 |
| 紫铜 | `#B5622F` | 锅炉、弯头、铆钉带 |
| 煤气灯琥珀 | `#F2B255` | 灯光和被照亮的面 |
| 奶油纸 | `#F0DFB8` | 最亮的面、纸张、表盘 |
| 朱红 | `#C8432B` | 地毯、帘子、旗帜、警示件。取代 v1 的酒红 |
| 石油青 | `#1F4A4F` | 阴影、夜空、钢铁。取代 v1 的群青和紫 |
| 铜绿 | `#4F8F86` | 氧化的铜、彩窗、植物暗部 |
| 晨曦粉 | `#D98C7A` | 只在黎明场景的天空里出现 |

比例大约是：木头、赭石和黄铜 60%，石油青的阴影和夜色 25%，朱红 10%，奶油色高光 5%。不使用纯紫、群青和纯白。

**形状。** 手切纸片的感觉：直线略微弯曲，竖线不完全垂直，圆不完全圆。配件做大：铆钉、阀门手轮、管道法兰都比真实比例粗一号。

**质感。** 不透明水粉加彩铅：色块内部能看到干笔触和颜料不匀，边缘有轻微的毛边，整张图带纸纹和印刷颗粒。不要渐变喷枪，不要 3D 渲染，不要照片质感。

**光。** 每盏灯在墙上和地上留下一圈暖色光池，光池外迅速落入石油青的暗部。窗外永远比室内冷。有窗的地方画出带灰尘的光柱。

**密度。** 三层细节：大形状一眼能读（窗、书架、锅炉）；中等道具说明这个房间的用途；最小一层是"脚注"，例如标签、钉在墙上的便条、挂牌、粉笔记号、小压力表。行走带保持干净，不放任何东西。

**蒸汽朋克硬性规定。**

- 允许：黄铜和紫铜管道、铆钉钢板、压力表、阀门手轮、齿轮组、离心调速器、飞轮、皮带传动、锅炉、风箱、气动传送管、传声筒、电报线、打孔卡、发条装置、浑天仪、煤气灯、煤灰、蒸汽。
- 禁止：魔法、发光符文、幽灵和怪物、霓虹、任何电子屏幕、现代电器、塑料。
- 每根管道都要有来处和去处，每台机器都要看得出动力从哪里来。

## 4. 生成流程

每个场景需要四层，文件名和画布尺寸与 v1 完全一致（1672×941），这样 Godot 里的热点坐标不用改。

1. **干净底图**：用下面的场景提示词，把 v1 对应的 `backgrounds/*-clean.png` 作为第一张输入图（只取布局），可以再附上参考图作为风格输入。
2. **远景**：窗外或山谷的独立一层。
3. **中景**：把第 1 步的结果交给工具，只把窗玻璃区域抠成真透明，其余像素不变。沿用 v1 的中景提示词。
4. **前景**：只占画面底部的近景遮挡，其余全透明。

新文件放进 `prologue-asset-pack-v2/`，子目录和文件名照抄 v1（`backgrounds/`、`far/`、`mid/`、`foregrounds/`）。放好之后再把场景文件里的贴图路径指过去。

### 共用风格段（每条提示词开头都贴这一段）

```text
STYLE: Original 2D side-on storybook game background, hand-painted in opaque gouache and
coloured pencil on toned paper. Strictly steampunk: a working world of brass and copper
pipework, riveted iron, pressure gauges, valve handwheels, gear trains, flywheels, leather
belts, bellows, pneumatic message tubes, speaking tubes and gas lamps. Every pipe visibly
comes from somewhere and goes somewhere. Chunky, slightly wonky hand-cut shapes, no ruled
lines, verticals lean a little, fittings and rivets are oversized and toy-like. Visible dry
brush strokes, uneven pigment, soft fuzzy edges, paper grain and light print speckle.
PALETTE: soot umber #2A1E1A, walnut #6B3F2A, old brass #B8893E, copper #B5622F, gaslight
amber #F2B255, cream paper #F0DFB8, vermilion #C8432B, petrol teal #1F4A4F, verdigris
#4F8F86. Roughly 60% warm wood, ochre and brass, 25% petrol-teal shadow, 10% vermilion,
5% cream light. No purple, no ultramarine, no pure white.
LIGHT: each gas lamp throws a warm pool on wall and floor that falls off fast into
petrol-teal shadow. Outside is always colder than inside. Dusty light shafts.
DENSITY: big readable shapes first, then working props, then tiny footnote clutter: brass
labels, pinned notes with no readable words, hanging tags, chalk marks, small gauges.
NEVER: magic, glowing runes, ghosts or creatures, neon, electric screens, modern appliances,
plastic, 3D rendering, photorealism, airbrush gradients, watermark, readable text, people
or animals. One full-bleed 16:9 scene, not a board or collage.
```

### 01 万象馆大厅（`01-library-hall-clean`）

```text
Scene 01 LIBRARY HALL, evening before a storm. Input image 1 is the layout reference: keep
every large element where it is. Left edge: dark arched doorway aperture, left empty for a
separate door sprite. Left third: a tall arched window in three lights with a round compass
rose at the top, leaded in iron, a few panes of amber and verdigris stained glass. In front
of it a long walnut reading table with a green-shaded brass lamp, one chair, a floor globe
and a potted plant on stacked trunks. Centre: three-storey bookcases with a brass rolling-
ladder rail; a standing gas lamp post; leave an empty clock-width gap between table and
bookcase. Centre right: a bookbinder's bench with tool rack, glue pots and a small lantern,
its top left clear for a separate open-book sprite. Upper level: brass balustrade gallery
with an armillary sphere. Right: a wide stair climbing to the gallery; under the stair a
small arched boiler alcove with a glowing grate.
Repaint: walnut panelling and ochre plaster instead of blue walls. Book spines in faded
vermilion, ochre, verdigris and cream, shelved unevenly with gaps, leaning volumes, boxes
and rolled charts. A pneumatic message tube runs along the cornice into the bookcases with
brass capsule stations. A speaking tube by the stair. Small pressure gauge and valve on the
riser pipe. Vermilion carpet runners with a simple gear border.
Floor walking line at 80 percent of image height; the bottom 20 percent is bare worn boards.
No freestanding clock, no open books or papers on tables, no ladder, no near-camera objects.
```

### 02 机械维护室（`02-machine-room-clean`）

```text
Scene 02 MACHINE ROOM, the archive's engine. Input image 1 is the layout reference: keep
positions. Left: stone stair with brass handrail rising off-frame, two wall gas lamps.
Left of centre: a tall riveted copper boiler column banded in brass, with a large spoked
flywheel and crank at its foot behind a low brass guard rail. Centre: a wall of pipework,
elbows, flanges and two handwheels. Centre right: a control wall with two blank cream
mounting boards (small one left, wide one right with a notch in its lower edge) in iron
frames with corner bolts; both boards stay completely empty for separate gauge and lever
sprites. Beneath them a long workbench with cupboard doors and a stool. Far right: a tall
arched iron window. Floor: stone deck with a vermilion runner and a long iron floor grate
right of centre; below the deck, a lower arcade with one lamp.
Repaint: boiler in warm copper with soot streaks and heat-blued bands instead of blue paint.
Walls in sooty ochre brick and riveted iron plate. Add a centrifugal governor on the boiler,
a leather belt from flywheel to a line shaft overhead, a sight glass, a row of small
pressure gauges with blank faces, oil cans, rag hooks, chalked tally marks. Faint steam at
pipe joints painted as soft dry-brush wisps.
Walking line at 80 percent height, unbroken floor. No levers, no gauge needles, no cables,
no papers, no near-camera objects.
```

### 03 顶层书库（`03-upper-stacks-clean`）

```text
Scene 03 UPPER STACKS, the top room under the roof. Input image 1 is the layout reference:
keep positions. Left: a giant arched window with a compass rose in its head, a writing desk
with an armillary sphere, a chair and a small lantern in front of it. Lower left: a stair
down with brass newel posts. Centre and right: two storeys of tall bookcases with a brass
balustrade ledge at 26 percent height and a clear shelf bay for a separate wooden-case
sprite. Upper right: sloping roof timbers with a roof light and one visibly cracked seam
above the right bookcase (the leak source). Right edge: wall lanterns and a hanging banner.
Walkway carpet at 78 percent height; below it, arches opening onto the hall beneath.
Repaint: honey-coloured roof timbers with iron straps, shelves crammed and sagging, stacked
ledgers tied with string, specimen jars, rolled charts, a brass ladder rail along the
shelves. A copper rain gutter pipe crosses the rafters to a drain funnel. A handwheel-driven
book lift beside the stair. Vermilion banner with a plain gear-and-compass device.
No ladder, no wooden case, no bucket, no water, no near-camera objects.
```

### 04 Kath 的房间（`04-kath-room-clean`）

```text
Scene 04 KATH'S ROOM, a modest apprentice bedroom inside the archive. Input image 1 is the
layout reference: keep positions. Far left: open doorway onto bookstacks. Left of centre: a
wooden bed in an arched alcove with trunks at its foot and beneath it; a long shelf above
with books, a globe and a trailing plant; pinned star charts and mechanism drawings with no
readable words. Right of centre: a writing desk with drawers, a chair and a stool on a round
rug. Right: a tall arched window with a compass rose, heavy vermilion curtains tied back, a
potted plant. Two hanging gas lamps.
Repaint: walnut wainscot and warm cream plaster instead of blue walls. Patchwork quilt in
vermilion, ochre and verdigris. A copper radiator pipe with a small valve along the wall, a
speaking tube by the door, a brass alarm clock and a tin mug on the shelf, a row of coat
pegs (empty), a hand-built model engine on the shelf, tool roll and goggles hung on a nail.
Floor boards with long warm light shapes from the window.
Walk strip at 81 percent height, unbroken. No satchel, no coat, no open notebook, no desk
lamp, no near-camera objects.
```

### 05 维修路（`05-service-road-clean-v2`）

```text
Scene 05 SERVICE ROAD at dawn, the path from the archive to the Observatory Castle. Input
image 1 is the layout reference: keep positions. Far left: the archive's stone wall with an
arched stained-glass doorway, a wall lantern and a fat brass downpipe. A wet cobbled road
climbs gently to the right across the bottom 22 percent. Stone and iron railing along the
road's far edge. Three timber telegraph poles with hanging gas lanterns and sagging wires
recede to the right. Middle distance: a misty forested valley, a town on an arched viaduct,
mountains, a low sun. Upper right: a fixed stone observatory tower on a crag, and beside it
a huge EMPTY brass ring on bearing axles and support brackets (empty for a separate rotating
wing sprite), reached by a lamp-lit causeway on arches.
Repaint: sky in dusty rose #D98C7A, amber and pale verdigris instead of lavender; clouds as
flat gouache shapes with dry edges. Pines in petrol teal, mist in warm cream. Factory
chimneys with thin smoke in the town. The ring and tower visibly engineered: riveted
segments, gear teeth on the ring's inner rim, a steam winch house at its base. Vermilion
banners with a plain gear-and-compass device.
No road sign, no gate, no cable, no near-camera foliage, nothing inside the ring.
```

### 远景

```text
archive-night-city / archive-prestorm-city: only the view OUTSIDE the archive windows. A
steampunk city in three receding layers of flat petrol-teal silhouettes: gasworks domes,
chimney stacks with drifting smoke, a clock tower, an arched railway viaduct, an airship
mooring mast. Tiny amber windows. Sky in deep petrol teal with soot-brown cloud bands. The
prestorm version is dry with a heavy cloud bank; the night version is the same city in
rain. No window frame, no interior, no near objects. Skyline readable across the full width.

archive-dawn-city: the same skyline at dawn, sky dusty rose to amber, cream mist between
the layers, chimney smoke catching the light.

05-service-road-far: scene 05 with the road, archive wall, poles, wires and railing removed
and the valley painted continuously down to the bottom edge. Keep the tower, the empty ring
and its causeway.
```

### 前景

所有前景层：只画近景遮挡，深煤烟棕和石油青的剪影加少量暖色边缘光，限制在画面底部约 22% 之内，中间约 70% 宽度保持透明，其余全部是真透明。用管道、阀门、线缆和书堆代替参考图里的藤蔓画框。

```text
01 hall: stacked ledgers and a strapped trunk bottom left, a floor globe, a second trunk
and book pile bottom right.
02 machine room: a fat pipe elbow with flange bottom left, a brass guard rail along the
bottom edge, a large gear segment bottom right.
03 upper stacks: a brass balustrade fragment and book pile bottom left, a lantern, rolled
charts and a gear bottom right.
04 Kath's room: a potted plant and book stack bottom left, a trunk corner bottom right.
05 service road: dark grasses and thistle silhouettes in the two bottom corners only.
```

## 5. 引擎内的美术层（已撤回，暂不在项目里）

曾经做过一版不改场景文件的引擎内美术层（`scripts/art_pass.gd` 加 `shaders/storybook_pass.gdshader`），在序章画面上叠加纸纹、颜料不匀、暗角、煤气灯光晕、浮尘和蒸汽。按要求已经撤回，目前游戏里没有这一层。

新底图换上之后，如果还想加纸纹和灯光氛围，可以再把它放回来。届时底图本身已经是暖色调，要把着色器里的 `cool_to_teal` 和 `warm_rich` 调低到 0.1 到 0.2，只保留纸纹、抖动、暗角和灯光，否则颜色会被处理两遍。

## 6. 之后要做的

- 道具（钟、门、手柄、仪表、木匣等）和角色仍是 v1 的平涂风格，底图重绘后需要按同一套规则重画。
- 大厅特写图（`hall-closeups-v2`）也是 v1 风格，同样需要重画。
