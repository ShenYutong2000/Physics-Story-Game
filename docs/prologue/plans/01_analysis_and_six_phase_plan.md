# 序章 v1.3 迭代：工程分析与实施计划（修订版 · S01 混合式交互）

## Context

工程 `E:\Project-Physics-Game\Physics-Story-Game`（Godot 4.7.2，GL Compatibility，分支 `dev/kathleens/improveS01`，工作区仅 `docs/prologue/` 未跟踪）已经是一个能从序章玩到第一章结尾的原型。本次按 v1.3 脚本迭代序章 S01–S06，**在现有代码上改，不重建**。本轮只修订计划，不改代码。

**本次修订的重点**：S01 大厅从“靠近 → 按 E → 自动完成”改为 **World Interaction + Contextual Close-up**：镜头平滑推近到物件，局部细节叠层接管清晰度，玩家用手势（拖动 / 按住 / 拾取放置）亲手完成，完成后有物件动画、环境声变化和 Kath 的短句，再自然回到场景。第一、二、三、五部分的分析与 S02–S06 计划保持不变。

已定事项：红签页改 v1.3 一般原则；钥匙架完全按 v1.3；Kath 单句用不阻塞字幕；**鼠标支持升级为近景内点击 + 短距离拖动**（取代上一版的“不做拖拽”），每个拖动都有键盘等价操作。

---

## 一、现有工程分析（不变）

**1. 已实现**：五张序章地图可玩可往返（`scenes/library_hall.tscn`、`machine_room.tscn`、`upper_stacks.tscn`、`kath_room.tscn`、`service_road.tscn`），第一章五张地图已完成。共享框架：`scripts/story_room.gd`（`StoryRoom` 基类）、`hall_hotspot.gd`、`hall_ui.gd`（全部 HUD）、`story_guide.gd`（目标 + H 三级提示）、`prologue_state.gd`（Autoload，`flags` 字典 + 单槽存档）、`game_settings.gd`。大厅最完整：四个物件近景（`hall_prop_focus.gd` + `library_hall.gd` 的 `FOCUS_VIEWS`）、巡查册近景（`hall_round_book.gd`）、三个可选发现、天气三阶段。`tests/` 下 31 个无头测试，`tools/run_tests.ps1` 运行。

**2. 与 v1.3 一致**：三项任务任意顺序、门窗合一且可互换；无复杂谜题；未完成不能盖章；盖章后空白页 + 归档页 + 红签始终可读；盖章才开放机械室；状态分别持久化；Wick 无台词；残页 Enter 取得；应急两种顺序；12° 偏转一次性。

**3. 未实现**：S01 的笔记夹页开场、清单门槛、角落计数、O01–O03、两步盖章、D00_EXIT、鼠标；S02 手动铅笔痕；S03 可调水桶、三焦点观察、四格草图、D18；S04 对齐操作、休息确认、出门提醒；S05 仪表比较、应急牌、升降机警示、主动观测、事故记录；S06 观察拆分、`prologue_complete`。

**4. 需修改而非重建**：全部英文对白（硬编码、无 ID）；对白只有模态气泡；`hall_round_book.gd`、`library_hall.gd`、`hall_prop_focus.gd`、`hall_ui.gd` 笔记面板、`story_guide.gd` 大厅文案；约 10 个大厅测试。

**5. 可扩展性**：`StoryRoom` 钩子清晰，`FOCUS_VIEWS` 数据驱动，`flags` 自由扩展不必升存档版本。`hall_ui.gd` 已 1191 行，新界面应独立成脚本。硬约束：存档只接受 bool/int/float/string 的 flag；第一章与测试依赖现有 flag 名与笔记 id，**v1.3 键名一律映射到现有键，不改名**。

**6. 可复用**：见第四部分“复用与改动”。

**7. 优先级**：对白 ID 表 + 字幕 → 聚焦镜头与手势（S01 的交互骨架，S02–S05 也要用）→ 笔记夹页 → 其余 S01 → S02…S06。

**本次补充核对的两个事实**
- **工程里没有任何 Camera2D**（全工程检索为零），也没有任何鼠标输入代码。五张地图都是 1672×941 的固定画面。所以“复用现有 Camera2D”不成立，需要给大厅新增一台。
- 大厅中景图 `mid/01-library-hall-mid.png` 与画布 1:1（1672×941），镜头放大超过约 1.6 倍就会发糊。清晰度必须靠 **Detail Overlay**，而素材已经有：`hall-closeups-v2/` 里每个物件都有两态近景图 + 独立透明活动件（`layer-door-bolt`、`layer-window-catch`、`layer-clock-crank`、`layer-clock-pendulum`、`layer-east-key`、`layer-round-stamp`）。

---

## 二、需求映射表

| Script Requirement | Existing File / Node | Current Status | Required Change | Priority |
|---|---|---|---|---|
| S01-I00 进场不弹清单、立即可移动、D01 | `library_hall.gd:209-211` | 模态开场白，念出全部任务 | D01 不阻塞字幕；站位靠近巡查桌 | P0 |
| 聚焦镜头 | 无 Camera2D | 缺 | 新增 `LibraryHall/Camera2D` + `focus_camera.gd` | P0 |
| 近景过渡不突兀 | `hall_prop_focus.gd:92-128` | 0.23 秒弹出，背景 91% 遮黑，大标题 + 部件列表 | 镜头先推近，叠层后淡入；遮罩降到约 45%；去大标题 | P0 |
| 手势：Slide / Hold / Pick & Place | `library_hall.gd:259-281`（仅按键） | 一次 E 即完成（钟为按住） | 新增 `focus_gesture.gd`，键鼠等价 | P0 |
| S01-I00 清单发现前只能看、D00 | `library_hall.gd:299` | 无门槛 | 手势提交前检查 `hall_checklist_discovered` | P0 |
| S01-I01 开笔记 → 展开夹页、D02/D02b | `hall_round_book.gd`、`MaintenanceSheet`、`hall_round_book_world.gd` | 打开即清单 | cover / tucked 阶段；纸条用 Slide 抽出 | P0 |
| 角落 `Evening Rounds · n/3` 与打勾 | `hall_ui.gd`（无） | 缺 | 新增标签；完成一项时原地打勾动画 | P0 |
| 清单条目名 | `hall_round_book.gd:169-171`、`hall_ui.gd:826` | 旧措辞 | v1.3 三条 | P0 |
| S01-I02 门闩、D03 | `library_hall.gd:426`、`FOCUS_VIEWS[&"door"]`、`hall_latch_visual.gd` | E 一键 | Slide 手势；`Door latched`；风声变化 | P0 |
| S01-I03 窗扣、D04、O01 | `library_hall.gd:435`、`FOCUS_VIEWS[&"window"]` | E 一键；无 O01 | Slide（弧线）；触玻璃可选观察 | P0 / P1 |
| S01-I04 上弦、D05、O02 | `library_hall.gd:445-469`、`hall_clock_motion.gd` | 按住 E，进度保留 | 两段推近；连续的钟摆/滴答反馈；看钟摆可选 | P0 / P1 |
| S01-I05 钥匙、D06、O03 | `library_hall.gd:418`、`FOCUS_VIEWS[&"keys"]`、`hall_key_rack.gd` | E 一键；旧标签；城堡翻牌 | Pick & Place；`EAST DUTY`；摆动衰减；磨损可选 | P0 / P1 |
| S01-I06 铭牌 / 钟内盖 / 目录卡 | `library_hall.gd:394-415` | 已实现 | 保留文案；随新过渡样式 | P2 |
| S01-I07 红签应急页 | `hall_round_book.gd:179` | 写明 2→4 | 一般原则；合上阶段也可翻到 | P0 |
| S01-I08 亲手盖章、D07、留白 | `hall_round_book.gd:103`、`library_hall.gd:512,552` | E 直接盖；之后一句指路 | Pick & Place 盖章；D07；删指路台词；静默约 1 秒 | P0 |
| S01-I09 进机械室、D00_EXIT、短淡出 | `library_hall.gd:320,565` | 无提示、瞬切 | D00_EXIT；0.3 秒淡出 | P1 |
| S01.D 提示 / 笔记面板 | `story_guide.gd:53-57,173-182,256-274`、`hall_ui.gd:802` | 就近未完成 ✓ | 加“先找笔记”分支；v1.3 名称 | P0 |
| S01.G 状态与存档 | `prologue_state.gd` | 四物件 + 归档已持久化 | 新增 flag；旧档兼容 | P0 |
| Dialogue ID / 不阻塞字幕 | 各脚本硬编码；`hall_ui.gd:739` | 无 | `prologue_lines.gd`、字幕层、`_say(id)` | P0 |
| S02-I01 手动铅笔痕、D08/D09 | `machine_room.gd:146`、`hall_ui.gd:153-206` | Enter 直接记录 | 可移动标记 + 容差（复用 Slide） | P0 |
| S02-I02/I03/I04 | `machine_room.gd:63,134`、`library_hall.gd:214-224` | 部分实现，旧文案 | 只读手柄；D10；D11 | P0–P1 |
| S03 水桶 / 观察 / 四格草图 / D12–D22 | `upper_stacks.gd`、`hall_ui.gd:245-273` | 桶瞬移；无观察与草图 | 见 Phase 3 | P0 |
| S04 对齐 / 休息 / 装包 / D23–D25 | `kath_room.gd`、`hall_ui.gd:275-297` | 静态面板 | 见 Phase 4 | P0 |
| S05 警报全流程 / D26–D33 | `library_hall.gd:204-208`、`machine_room.gd:126-235`、`hall_ui.gd:433-457,1056` | 两顺序 ✓；其余缺 | 见 Phase 5 | P0 |
| S06 观察 / 闸门 / 章节卡 / D34–D36 | `service_road.gd:124-163` | 基本实现 | 见 Phase 6 | P0–P1 |

---

## 三、设计文件之间的实质冲突

| # | 冲突 | 处理 |
|---|---|---|
| 1 | v1.3 文内写“若有 `PROLOGUE_HALL_SCENE_LOCKED.md` 则以它为准”；该文件存在且与 v1.3 多处不同。你的指令是 S01 以 v1.3 为准。 | 执行 v1.3；锁定稿不删，顶部标注“S01 已由 v1.3 取代”。 |
| 2 | 现有代码的台词本身也已偏离锁定稿。 | 无需保留。 |
| 3 | 应急页 2→4 与 v1.3 不剧透。 | 已定：一般原则。 |
| 4 | 钥匙架城堡翻牌与 v1.3。 | 已定：按 v1.3。 |
| 5 | 清单发现前能否操作。 | 按 v1.3：只能看。 |
| 6 | 笔记键 N（建议）与现有 J。 | 默认保留 J。 |
| 7 | **老钟“打开钟盖”与现有素材**：近景图里上弦摇柄在钟壳**外侧**，钟摆在玻璃门后；素材没有“钟门打开”的状态图。另有一块小黄铜内盖（内有校准刻痕），属于可选发现 I06。 | 默认用“两段推近”表达开盖：整钟 → 上弦机构，配一声搭扣响。若你要真正的开门动画，需要补一张钟门打开的图（见素材清单 A4）。内盖仍是可选。 |
| 8 | 机械室入口是否独立热点。 | 默认保留档案门兼入口。 |
| 9 | `optional_notices: []` 与存档校验。 | 用三个 bool flag。 |
| 10 | v1.3 状态键名与现有 flag 名。 | 映射，不改名。 |
| 11 | 完整脚本文件名 v1_3、标题写 v1.2；S01 章节与独立 S01 文件一致。 | 无内部冲突。 |
| 12 | S05 观测方式、S04 开场白提到 Night of Unnaming、残页文字。 | 各自阶段处理。 |
| 13 | **本次新增**：你要求“优先复用现有 Camera2D”，但工程里没有。 | 只给大厅新增一台，脚本写成可挂到其他房间的小组件，其余房间本阶段不动。 |

---

## 四、Phase 1：S01 大厅（混合式交互 · 具体设计）

### 4.1 交互骨架：一次聚焦的完整节拍

所有物件共用同一条时间线，差别只在手势种类和参数。

| 阶段 | 时长 | 发生什么 |
|---|---|---|
| ① 靠近 | — | 进入 `discovery_radius` 出现小菱形标记，进入 `reach_radius` 出现 `E` 提示（现有逻辑）。 |
| ② 接手 | 0.25 s | 按 E：Kath 转向物件并播 `kath-interact`（已有帧、目前未接入）；Wick 飘向物件（现有 `react_to`）；提示隐藏；移动锁定。 |
| ③ 推近 | 0.40 s | Camera2D 以正弦缓动移向物件锚点并放大到 1.2–1.5 倍。大厅始终可见，环境声不断。物件自身的声音（风、滴答）略微提高。 |
| ④ 细节接管 | 0.25 s | 推近进行到约 60% 时，Detail Overlay 从物件在屏幕上的位置淡入并长到工作尺寸；四周只压暗到约 45% 并带暗角，不再是整屏遮黑。底部淡入一行小字操作提示和一个手势方向标。 |
| ⑤ 操作 | 玩家决定 | 手势驱动活动件连续移动，过程中有摩擦/齿轮声。无计时、无失败。 |
| ⑥ 落定 | 0.3–1.2 s | 到位吸附 → 锁止音 → 环境变化（风变闷、滴答变稳）→ 大厅里的同一物件同步变化（现有 `door_bolt_world` 等）→ 状态写入并存档 → 角落清单打勾（若该项完成）。 |
| ⑦ 一句话 | 落定后 0.4 s | 对应的 D03–D06 以字幕出现，不锁输入。 |
| ⑧ 停留 | 玩家决定 | 可选观察的入口此时才轻轻亮起。玩家可以看，也可以不看。 |
| ⑨ 退回 | 0.35 s | Esc / 鼠标右键 / 点击叠层外，或字幕结束后约 6 秒无任何输入时自动退回：叠层淡出，镜头缓回原位，结束后才把移动还给玩家。 |

**为什么不突兀**：镜头先动、叠层后到，叠层是从物件原位“长”出来的；大厅没有被盖掉；声音从头到尾连续；进出是同一条曲线的正反放；大厅里的物件在叠层后面同步变化，退回时看到的就是结果。

**再次查看已完成的物件**：直接进入落定后的样子，从第 ⑧ 步开始，不重播台词，不自动退回。

### 4.2 三类手势（`scripts/focus_gesture.gd`，约 150 行，一个文件）

| 手势 | 鼠标 | 键盘等价 | 规则 |
|---|---|---|---|
| **Slide** | 按住活动件，沿轨道方向拖约 80 屏幕像素 | 按住方向键（轨道方向）或按住 E，约 0.5 秒走完 | 进度 0–1 连续；松手停在原处，不回弹、不惩罚；≥ 0.9 自动吸附到位并提交。 |
| **Hold** | 按住机构 | 按住 E | 进度随时间累积，松手保留（现有上弦逻辑原样保留，含 `hall_clock_winding_progress` 存档）。 |
| **Pick & Place** | 按下拾起，拖到目标区松手 | E 拾起，←/→ 在停靠点间移动，E 或 Enter 放下 | 目标区判定半径约 90 像素；放在别处就滑回原位，不判错、不出台词。 |

输出只有三个信号：`progress_changed(value)`、`committed`、`cancelled`。`hall_prop_focus.gd` 和 `hall_round_book.gd` 都用它；S02 铅笔痕（Slide）、S03 推桶与草图墨点（Pick & Place）、S04 残页对齐（Slide）、S05 手柄（Slide）之后直接复用。输入由 `library_hall.gd` 的 `_room_input` 转发，命中判定用画布坐标的矩形手算，不改动现有控件的 `MOUSE_FILTER_IGNORE`。

### 4.3 逐项交互规格

**I01 笔记与夹页清单**（热点 `MaintenanceSheet`，x 1212 ± 145）
- 触发：E。无前置。镜头轻推到巡查桌（1.3 倍）。Kath 用 `kath-read-write`。
- 步骤 1 打开：点击封面或按 E → 封面翻开 0.3 秒 + 翻页声 → 左页是旧巡查的勾与褪色 `ROUND FILED` 印，右页夹着折叠纸条，露出 `EVENING ROUNDS` 边。置 `hall_notebook_opened_once`。**此时仍无任何清单 HUD。**
- 步骤 2 展开：Slide——按住纸条向外抽约 80 像素，或焦点在纸条时按 Enter/E → 纸条分两折展开 0.45 秒 + 纸声 → 三个空方框与三行任务名依次显墨。
- 完成判定：纸条展开动画结束 → `hall_checklist_discovered = true`，立即存档。
- 台词：展开后 0.3 秒 D02。若第一次只打开没展开、关掉后再来：翻开看到纸条时 D02b，展开时再 D02，两句不重叠。
- 红签：任何阶段（包括合上时）点击红签或按 ←/→ 都能翻到应急页。
- 退回大厅后角落淡入 `Evening Rounds · 0/3`。之后再开笔记直接是清单页，不重播展开。

**I02 门闩**（热点 `ArchiveDoor`，x 120 ± 120；镜头锚点 (127, 519)，1.5 倍）
- 前置：近景随时可进；提交需要 `hall_checklist_discovered`。
- 操作：Slide，向右。活动件用 `layer-door-bolt.png` 叠在 `door-latch-states.png` 的未扣态上（底图里烘焙的门闩正好垫在后面）。
- 过程反馈：金属摩擦声随进度；大厅里的小门闩（`hall_latch_visual.gd` 的 `progress`）同步移动。
- 完成判定：进度 ≥ 0.9 → 吸附 → `gate-latch.wav` → 门缝光条收窄、门边风声降低 → 短提示 `Door latched` → `hall_door_latched = true` → 0.4 秒后 D03。
- 若窗扣也已完成：角落 `Check Doors & Windows` 打勾 + 铅笔声，计数 +1。只触发一次。
- 停留：→ 或点击铭牌可看旧铭牌（现有可选发现，照旧）。

**I03 窗扣**（热点 `HighWindow`，x 476 ± 140；锚点 (602, 501)，1.4 倍）
- 操作：Slide，把窗扣的自由端向上推（轨道是一小段弧，画面上表现为旋转）。活动件 `layer-window-catch.png`，底图由未扣态随进度渐变到已扣态，窗扇随之合上。
- 完成判定：≥ 0.9 → 吸附 → `lever-click.wav` → 窗框拍打声停止（现有）→ 窗外风声变闷但不消失 → `hall_window_fixed = true` → D04。门窗共同打勾逻辑同上，先窗后门结果相同。
- 可选 O01：完成后玻璃上出现一个很淡的可交互亮点。点击玻璃或按 ↓ 再按 E → 指尖落点晕开一小片水雾，停 0.6 秒，慢慢散去 → O01 字幕 → `hall_notice_glass = true`。不解释温度与凝结，不计进度。

**I04 老钟**（热点 `OldClock`，x 967 ± 145；锚点 (967, 500)，1.35 倍）
- 第一拍 整钟：叠层用 `hall-clock-states.png`，钟摆是真的在摆（`layer-clock-pendulum.png`，未上弦时幅度小、滴答慢——现有 `hall_clock_motion.gd` 的节奏）。
- 第二拍 开盖推近：点击钟身或按 E → 搭扣声 → 叠层再推进到上弦机构（`clock-winding-detail-states.png`），0.35 秒。
- 操作：Hold，按住摇柄或按住 E，累计约 1.2 秒。摇柄连续转动（`layer-clock-crank.png`），每四分之一圈一声棘轮（现有 4 段逻辑）；**钟摆幅度和滴答间隔随进度连续变化**（现在是二值切换，改为插值）。松手保留进度，Esc 退出再来可继续。
- 完成判定：进度 1.0 → 摇柄停稳 → 齿轮咬合声 → 滴答稳定 → `Clock running` → `hall_clock_wound = true` → 叠层缓回整钟（第三拍）→ D05 → 角落打勾。
- 可选 O02：第三拍里点击钟摆或按 E → 叠层内视线从钟摆缓慢上移到钟面，1.2 秒，分针轻跳一格 → O02 → `hall_notice_pendulum = true`。不讲周期、不讲时间。
- 没有校准、没有计时、没有过度上弦。

**I05 东侧值班钥匙**（热点 `DutyKeys`，x 1370 ± 115；锚点 (1370, 500)，1.2 倍，轻聚焦）
- 画面：三个编号挂钩，第三钩下是磨损的 `EAST DUTY` 标签；钥匙挂在右侧临时钉上。前两把钥匙只是陈设，不可拾取。
- 操作：Pick & Place。按下钥匙（或 E）→ 钥匙抬起、轻响、跟随指针（键盘：← 移到第三钩上方）→ 在第三钩范围内松手（或 E/Enter）。
- 合成方式（不需要新图）：底图用未归位态；拾起时用已归位态里“空钉”那一小块盖住烘焙的钥匙；活动件用 `layer-east-key.png`。
- 完成判定：在第三钩范围内放下 → 清脆碰撞声 → 钥匙以挂点为轴摆动三次、幅度递减，约 1.2 秒，伴两声渐弱的轻碰 → 摆停后切到已归位底图 → `hall_east_key_sorted = true` → **等余音消散** D06 → 角落打勾。
- 放错：其他位置或已占用的钩 → 钥匙滑回临时钉，无台词、无惩罚、不计完成。
- 可选 O03：完成后点击钥匙柄或旧标签（或 E）→ 叠层向钥匙缓慢推近到 1.25 倍，停 1 秒 → O03 → `hall_notice_key_wear = true`。没有闪回，没有隐藏门暗示。

**I08 盖章 `ROUND FILED`**（回到 `MaintenanceSheet`）
- 前置：已发现清单且四个物件全部完成。
- 操作：Pick & Place。清单页右下是印章（`layer-round-stamp.png`）。按下拾起 → 拖到纸面盖章区松手（键盘：E 拾起后印章自动悬在盖章区上方，Enter/E 落下）。
- 未完成时：印章可以拿起来看；落下时状态行只列出未完成的项目名，印章回到原位，不代办、不跳过。
- 完成判定：印章落下 0.6 秒（带轻微压扁）→ 闷响 → `ROUND FILED` 印迹显墨 → 停 0.5 秒 → 旧页向左滑入归档 + 纸声 → 露出空白页 → `hall_round_filed = true`，存档 → D07 → **之后约 1 秒内不出任何提示**，只有滴答和风 → 角落计数淡出。
- 机械室入口此时可用。

**I09 进入机械室 / D00_EXIT**
- 已归档：档案门提示变为 `ENTER · MACHINE ROOM`，E → 0.3 秒淡出 → S02。
- 未归档且门闩已扣：在门的近景里按 E → D00_EXIT 字幕，门不开，已完成事项不变。

**清单发现前碰四个物件**：近景照常打开，可以看。尝试手势时活动件只轻晃一下回到原位，首次出 D00，Wick 飘向巡查桌；之后再试，只在状态行显示 `Tonight's page first.`，不再念台词。可选发现与可选观察不受此限。

### 4.4 如何保证不卡关
- 每个近景任何时刻都能 Esc 退出，包括过渡动画中途；退出不丢已保存的状态。
- 每个拖动都有键盘等价；判定宽松（吸附阈值 0.9、放置半径 90 像素）；全程无计时、无失败态、无次数限制。
- 近景内 6 秒没有进展时，手势方向标轻轻脉动一次——只示意“往哪动”，不替玩家做。
- 大厅里 H 三级提示：未发现清单时始终先指向笔记；之后指向离 Kath 最近的未完成物件；全部完成后指向笔记桌的印章。可选观察永不进入提示。
- 旧存档：只要已有任何大厅进度、已归档或已记基线，就视为清单已发现，不会被拦在开场。
- 过渡期间输入被忽略而不是排队，避免连按 E 误触下一步。

### 4.5 复用与改动

**直接复用**
- `hall_prop_focus.gd` 的整体结构、`FOCUS_VIEWS` 数据驱动配置、两态图集裁切、`select_part`。
- `hall_round_book.gd` 的页面切换、盖章补间、归档/空白/红签页。
- `hall_latch_visual.gd`、`hall_clock_motion.gd`、`hall_key_rack.gd`、`hall_round_book_world.gd`：大厅里的物件同步变化。
- `library_hall.gd` 的状态判定（`_door_is_latched` 等）、门窗合并记录、上弦进度持久化、窗框拍打与滴答节奏。
- `hall_hotspot.gd`、`StoryRoom` 的模式/音频/笔记、Wick `react_to`、`story_guide.gd` 的就近未完成逻辑、存档。
- 全部 `hall-closeups-v2/` 素材与六个活动分层；`characters/kath-interact`、`kath-read-write` 帧；`amb-road.wav` 作窗外风层。

**需要修改**
- `hall_prop_focus.gd`：过渡改为“镜头先、叠层后”，遮罩变浅加暗角，去掉大标题与部件列表；增加活动件层、局部补片、手势方向标；已完成后仍允许可选部位。
- `hall_round_book.gd`：cover / tucked 阶段、纸条 Slide、盖章 Pick & Place、v1.3 条目名与红签文字。
- `library_hall.gd`：开场、门槛、手势信号接线、D01–D07 / O01–O03 / D00 / D00_EXIT 的触发、钥匙架配置、删除完成后的指路台词、风层。
- `hall_clock_motion.gd`：钟摆幅度与滴答由二值改插值。
- `hall_ui.gd`：字幕层、角落清单标签与打勾、淡出遮罩、笔记面板大厅段。
- `story_room.gd`：`_say(id)`。`story_guide.gd`：大厅目标与提示文案。`prologue_state.gd`：`hall_checklist_discovered()`。

### 4.6 需要新增的节点、脚本、资源

**节点**
- `LibraryHall/Camera2D`（静止时位于画面中心、缩放 1，四边限位 0–1672 / 0–941；静止画面与现在逐像素一致）。
- `HallPropFocus` 内：`MovingLayer`、`Patch`、`GestureHint`、`Vignette`（都在脚本里创建，沿用现有做法）。
- `HallUI` 内：`CaptionLayer`（层级高于近景）、`RoundsTag`、`Fade`。
- `LibraryHall` 内：窗外风声播放器（脚本创建）。

**脚本**
- `scripts/prologue_lines.gd`：CSV 全部 42 条，ID → 英文。
- `scripts/focus_camera.gd`：`focus_on(world_point, zoom, seconds)`、`release(seconds)`，中途可打断。
- `scripts/focus_gesture.gd`：三类手势。

**媒体资源**（左列先用占位即可开工，不阻塞）

| # | 资源 | 占位方案 | 必要性 |
|---|---|---|---|
| A1 | 老钟近景的干净底图（去掉钟摆与摇柄） | 用深色补片盖住烘焙的钟摆 | 最值得补的一张 |
| A2 | 合上的笔记本封面近景、折叠纸条 | `props/notebook-world.png` + Godot 绘制的纸条 | 建议补 |
| A3 | 窗框干净底图（去掉窗扣） | 两态渐变 + 活动件 | 可选 |
| A4 | 钟门打开状态 | 两段推近 + 搭扣声 | 仅当要真开门 |
| S1 | 门闩摩擦、盖章闷响、钥匙碰撞、上弦棘轮、纸条展开 | 复用 `gate-latch` / `stop-switch` / `lever-click` / `page-turn` 并调音高 | 建议补 |
| S2 | 室外风声循环 | `amb-road.wav` | 可用现有 |
| — | 水雾、暗角、手势方向标 | Godot 渐变贴图与绘制 | 无需外部素材 |

活动分层与底图的对位在实现时逐个截图确认；对不齐就退回“按进度裁切已完成态”的做法，同样不需要新图。

### 4.7 状态（全部在 `PrologueState.flags`）
- 新增：`hall_notebook_opened_once`、`hall_checklist_discovered`、`hall_notice_glass`、`hall_notice_pendulum`、`hall_notice_key_wear`、`line_<ID>`。
- 沿用：`hall_door_latched`、`hall_window_fixed`、`hall_clock_wound`、`hall_clock_winding_progress`、`hall_east_key_sorted`、`hall_round_filed`。三格勾选为派生值。`SAVE_VERSION` 不变。

### 4.8 红签页文字草稿（待你审）
```
EMERGENCY
If the upper needle crosses the red line:
  Compare it with the last pencil mark.
  Follow the procedure plate on the machine-room wall.
  If it keeps rising, isolate the local drive.
  Keep the upper lift out of use.
```

### 4.9 Godot 实施顺序

| 步 | 内容 | 完成后可验证 |
|---|---|---|
| 0 | 跑全量测试，记录基线 | 改动前的通过情况 |
| 1 | `prologue_lines.gd`、字幕层、`_say`；开场换 D01 | 进场立即可走，字幕不锁输入 |
| 2 | `Camera2D` + `focus_camera.gd`；`hall_prop_focus` 过渡重做（玩法不变） | 四个近景进出平滑；静止画面与旧截图一致 |
| 3 | `focus_gesture.gd` + **门闩纵切片**：推近 → 叠层 → 拖动 → 吸附 → 声音 → D03 → 退回 | **此处停下给你看截图与手感，确认后再铺开** |
| 4 | 笔记封面与夹页、门槛与 D00、角落计数、旧档兼容 | 开场闭环：开笔记 → 展开 → 才能操作 |
| 5 | 窗扣 + O01、老钟两段推近 + O02、钥匙 Pick & Place + O03 | 三项任务任意顺序 |
| 6 | 盖章、D07 与静默、红签页、D00_EXIT、进机械室淡出、笔记面板与 H 文案 | S01 全流程 |
| 7 | 更新/新增测试、双分辨率截图、README 与锁定稿标注 | 全量测试通过 |

### 4.10 测试标准

**自动（`tools/run_tests.ps1`）**
- 新增 `tests/focus_gesture_test.gd`：合成鼠标拖动得到正确进度；半途松手不提交也不回退；键盘等价路径结果相同；放错位置回到原位；清单未发现时手势不改变任何 flag。
- 新增 `tests/hall_focus_camera_test.gd`：聚焦后退回，镜头位置与缩放回到初值；过渡中途 Esc 在 0.6 秒内回到 `roam` 且移动恢复；退回后 E 提示的位置与聚焦前相同。
- 新增 `tests/hall_notebook_discovery_test.gd`：开场无清单 HUD；开/关/重开触发 D02b；展开触发 D02 且只一次；两步盖章；未完成时印章无效并列出缺项；存读档后状态一致。
- 新增 `tests/prologue_lines_test.gd`：对白表与 `docs/prologue/Kath_Prologue_Dialogue_Lines_v1_3.csv` 逐条一致。
- 更新 `hall_patrol_order_test`：3! × 门窗两种先后 = 12 条路径，全部用手势完成；每条主线台词只出现一次；可选观察不改变计数。
- 更新 `hall_door_window`、`hall_clock`、`hall_key_rack`、`hall_round_book`、`hall_interaction`、`hall_optional_discoveries`、`hall_weather_checkpoint`、`story_guide`、`journal_progress`；`tests/support/story_test.gd` 增加 `_hold(key, seconds)`、`_drag(from, to)`，`_new_hall()` 默认预置清单已发现。
- 回归：S02–S06 与第一章的全部测试不改动且仍通过。

**量化标准**
- 进入过渡 ≤ 0.9 秒，退出 ≤ 0.5 秒；任何时刻 Esc 到恢复移动 ≤ 0.6 秒。
- 镜头静止时画面与改动前的审阅截图一致（1672×941 与 1280×720）。
- 每个主线交互从按 E 到完成，熟练操作 ≤ 6 秒；没有任何必须等待的不可跳过演出超过 1.5 秒。

**人工（F5 实机）**
- T01–T03 三条用例各走一遍，一遍纯键盘、一遍键鼠。
- 检查项：推近时有没有“切屏”感；拖动时活动件是否跟手；叠层与大厅物件是否同步；台词是否压在音效之后而不是同时；D07 之后是否真的安静。

---

## 五、Phase 2–6 概要（不变）

**Phase 2 · S02 机械室** — 改 `machine_room.gd`、`hall_ui.gd`（仪表近景）、`scenes/machine_room.tscn`、`library_hall.gd`（D11）。手动铅笔痕 + 容差（存 `machine_baseline_pos`）、`Let me look again.`、Esc 不记录；手柄/停机只读；D10；回大厅滴水 D11。复用仪表面板与回程逻辑，以及 Phase 1 的 Slide 手势与聚焦镜头组件。测试 T04、T05。

**Phase 3 · S03 顶层书库**（最大，拆 3a 水桶与水滴循环 / 3b 观察视图 / 3c 四格草图与木盒）— 改 `upper_stacks.gd`、`scenes/upper_stacks.tscn`、`hall_ui.gd`（残页文字）；新增观察视图与草图页两个场景。推桶 + 命中判定；曲线驱动的水滴循环；三焦点 + 等时三帧；D13–D16 观察后才出现；D18 绑定玩家自己重看；四格草图（墨点/短线，淡墨痕保留）；D19；Wick 引向木盒；D20–D22。需补水珠/飞溅帧、接缝近景、四格底图。测试 T06–T12。

**Phase 4 · S04 Kath 的房间** — 改 `kath_room.gd`、`scenes/kath_room.tscn`、`hall_ui.gd`。残页对齐（Slide）+ Enter、D23、D24、新旧并排、休息确认 + D25、装包与出门提醒、可选外套/工具包、开场白去掉 Night of Unnaming。测试 T13、T14。

**Phase 5 · S05 警报** — 改 `library_hall.gd`、`machine_room.gd`、`hall_ui.gd`、`scenes/machine_room.tscn`。先静后响 + D26/D27；仪表与基线比较 D28；应急牌；两种顺序 + D29/D30；升降机警示 D31；主动观测 12° D32；事故记录 D33。保持 `incident_complete`、`castle_pose = tilted`、`castle-alarm` 的产出。测试 T15–T18。

**Phase 6 · S06 维修路** — 改 `service_road.gd`、`scenes/service_road.tscn`。路牌/缆线/建筑翼分开观察 D34、并列记录 D35、闸门停顿 + Wick 先飞 + D36、`prologue_complete`。测试 T19、T20。

---

## 六、第一轮修改的文件与起步方式

第一轮（步骤 0–3）只做交互骨架和一个纵切片，动这些文件：
1. `scripts/prologue_lines.gd`（新增）
2. `scripts/focus_camera.gd`（新增）
3. `scripts/focus_gesture.gd`（新增）
4. `scripts/hall_ui.gd`（字幕层）
5. `scripts/story_room.gd`（`_say`）
6. `scripts/hall_prop_focus.gd`（过渡与活动件层）
7. `scripts/library_hall.gd`（开场 D01、镜头接线、门闩手势）
8. `scenes/library_hall.tscn`（加 `Camera2D`）
9. `tests/support/story_test.gd` 与两个新测试

门闩切片做完后停下，把推近、拖动、落定、退回四个时刻的截图和一份手感说明交给你；你认可这套节拍后，再照同一模式铺到笔记、窗扣、老钟、钥匙和印章。不提交 git，除非你要求。

## 验证方式

`.\tools\run_tests.ps1 -Filter hall` → 全量 `.\tools\run_tests.ps1`（Godot 位于 `D:\Game\Godot-4.7.2\`）→ `-CaptureDir` 出两种分辨率截图 → Godot 里 F5 从 New Game 实机走 T01–T03。
