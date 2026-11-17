# 序章 v1.3 开发交接（截至 2026-11-16）

接手前请先读仓库根目录的 `AGENTS.md`。本文件说明：做到哪了、哪些事已经定案、接下来按什么顺序做、每一步怎么算完成。

- 分支：`dev/kathleens/improveS01`。本文件所述改动**尚未提交**，都在工作区里。
- 测试基线：`.\tools\run_tests.ps1` → **34 passed, 0 failed**。

## 1. 相关文档怎么读

| 文件 | 用途 | 注意 |
|---|---|---|
| `docs/prologue/S01_Hall_Revised_v1_3.md` | S01 的交互与对白权威 | — |
| `docs/prologue/Kath_Prologue_Implementation_Script_v1_3.md` | S02–S06 与全局约定 | 标题写 v1.2，内容即 v1.3 |
| `docs/prologue/Kath_Prologue_Dialogue_Lines_v1_3.csv` | 42 条英文对白 | 已录入 `scripts/prologue_lines.gd` |
| `docs/prologue/plans/01_analysis_and_six_phase_plan.md` | 工程分析、需求映射表、冲突清单、六阶段计划 | **其中第四部分“带边框的 Detail Overlay”呈现方式已被 02 取代**；流程、状态、判定、测试标准仍有效 |
| `docs/prologue/plans/02_door_close_shot_plan.md` | 当前生效的镜头形式：推近 → 全屏过肩特写 | 以门闩为样板 |

## 2. 已定案的决定（不要重新讨论，除非用户提出）

**内容**
1. S01 以 v1.3 为准，旧锁定稿 `docs/PROLOGUE_HALL_SCENE_LOCKED.md` 作废但不删除（待在其顶部加一行“S01 已由 v1.3 取代”）。
2. 红签应急页改为一般安全原则，不写“先 2 后 4”。草稿（待用户审）：
   ```
   EMERGENCY
   If the upper needle crosses the red line:
     Compare it with the last pencil mark.
     Follow the procedure plate on the machine-room wall.
     If it keeps rising, isolate the local drive.
     Keep the upper lift out of use.
   ```
3. 钥匙架完全按 v1.3：第三钩标 `EAST DUTY`，**取消**挂回后翻牌露出 `OBSERVATORY CASTLE` 的揭示及相关笔记文字。
4. 清单发现前，四个维护物件只能看不能改，首次尝试触发 D00。
5. 笔记键保留 **J**（v1.3 写的 N 只是建议）。
6. 老钟保留“按住上弦、进度保留”，不做校准；“打开钟盖”用两段推近表达（现有素材没有钟门打开的图）；小黄铜内盖仍是可选发现。
7. 档案门继续兼作机械室入口，不新增独立入口热点。
8. 可选观察用三个 bool flag：`hall_notice_glass`、`hall_notice_pendulum`、`hall_notice_key_wear`。

**呈现与操作**
9. Kath 的单句用**不阻塞字幕**（`_say(id)`）；多句剧情对白仍用原有的 Enter 气泡（`_start_dialogue`）。
10. 动手操作的镜头形式：**场景内推近 → 溶入铺满屏幕的特写 → 画面里有 Kath 的背影和手**。不要带边框的弹窗、不要压暗背景、不要标题和整行说明文字。
11. 手势三类：Slide（拖动/按住）、Hold（按住累积）、Pick & Place（拾取放置）。鼠标拖动与键盘等价；松手不回弹、不惩罚。
12. 先做一个纵切片给用户确认，再铺开。

## 3. 已完成

| 内容 | 位置 |
|---|---|
| 对白 ID 表（42 条）与逐条比对测试 | `scripts/prologue_lines.gd`、`tests/prologue_lines_test.gd` |
| 不阻塞字幕层；`StoryRoom._say(id, once)`；一次性标记 `line_<ID>` | `scripts/hall_ui.gd`（`show_caption`）、`scripts/story_room.gd` |
| 大厅开场改为 D01 字幕，进场即可移动 | `scripts/library_hall.gd`（`_queue_line`） |
| 大厅聚焦镜头（静止时与无镜头时画面一致） | `scripts/focus_camera.gd`、`scenes/library_hall.tscn` 的 `Camera2D` |
| 手势模块，已实现 Slide（含起步卡涩） | `scripts/focus_gesture.gd` |
| 近景呈现支持两种模式：全屏特写（`"shot"`）与旧的带框近景 | `scripts/hall_prop_focus.gd` |
| **门闩纵切片**：推近、溶入、过肩背影、拖动/按住、风晃、门缝光、落定轻震、`Door latched.`、D03、退回 | `library_hall.gd` 的 `FOCUS_VIEWS[&"door"]` |
| Kath 伸手姿势与让位一步 | `scripts/kath.gd`（`reach_toward`、`stop_reaching`） |
| 窗外风声层，随门窗固定而降低 | `library_hall.gd`（`_update_wind`） |
| 测试辅助：`_hold_on`、`_drag_on`、`_mouse_button`、`FOCUS_IN` / `FOCUS_OUT` / `SLIDE_HOLD` | `tests/support/story_test.gd` |
| 新测试 | `tests/focus_gesture_test.gd`、`tests/hall_focus_camera_test.gd` |

## 4. 当前卡点

**门闩切片在等用户试玩确认。** 用户还没有在 Godot 里亲手试过拖动手感。确认前不要把这套形式铺到其他物件。已知可能被要求调整的地方：

- 门缝光是一条细竖线，上端截得突兀，可改成渐变或去掉。
- 铭牌近景（门特写里按 → 或点击铭牌）仍是旧的带框样式。
- 特写用的门与大厅里那扇门不是同一张画，靠推镜途中的溶入掩盖。
- 1672×941 下门板特写略软（素材每态 887×887）。

## 5. 一个“全屏特写”是怎么配置的（照这个样板做其余物件）

`library_hall.gd` 的 `FOCUS_VIEWS[<key>]`：

- 条目级：`"zoom"`（场景内推近倍数，背景图 1:1，别超过约 2.2）、`"stand_x"`（Kath 让位站到哪）。
- `"view"` 内：
  - `"texture"`、`"before_region"`、`"after_region"`：两态图集。
  - `"gesture"`：`handle`（屏幕坐标的可抓区域）、`track`（走完全程的拖动向量）、`hint`（方向标位置）、`stick_pixels` / `stick_seconds`（起步卡涩）。
  - `"shot"`：`crop`（图集内以物件为中心的 16:9 横带）、`figure`（Kath 背影：贴图、帧区域、`grip` 手的位置、`scale`、`rotation`、`at` 屏幕落点、`travel` 随进度的位移）、`light_gap`、`rattle`、`status_at`、`links`（特写里可点击跳到的其他视图）。
  - `"stretch_slide"`：门闩专用的“局部拉伸”活动件做法。
- 换算：屏幕坐标 = (图集坐标 − `crop` 原点) × (1672 / `crop` 宽)。门闩是 ×1.885。
- 完成动作在 `_run_focus_action()` 里按 `parts[0].action` 分发；完成后的顺序是：`focus.set_completed()` → 音效 → 环境变化 → `_queue_line("Dxx", 0.4)` → `focus_autoreturn`。

可用的高清素材：`prologue-asset-pack-v1/hall-closeups-v2/` 下每个物件的两态图与活动分层（`layer-window-catch`、`layer-clock-crank`、`layer-clock-pendulum`、`layer-east-key`、`layer-round-stamp`），尺寸见同目录 `manifest.json`。Kath 背影用 `characters/kath-climb.png`。

## 6. 接下来的顺序

每一步结束都要：相关测试子集通过 → 全量通过 → 出两种分辨率截图 → 向用户汇报后再进下一步。

**Phase 1（S01）剩余**

| 步 | 内容 | 完成标准 |
|---|---|---|
| 1a | 按用户试玩反馈调整门闩切片 | 用户明确认可 |
| 1b | 笔记夹页开场：合上的笔记 → 打开 → 抽出并展开 `EVENING ROUNDS`；D02 / D02b；`hall_notebook_opened_once`、`hall_checklist_discovered`；清单门槛与 D00；角落 `Evening Rounds · n/3` 与原地打勾；旧存档兼容（已有任何大厅进度即视为已发现） | 进场无清单 HUD；不展开就不能改任何物件；存读档后不重播展开；现有测试通过 `_new_hall()` 预置已发现 |
| 1c | 窗扣：Slide（弧线）全屏特写 + D04 + 可选 O01 触玻璃 | 先窗后门、先门后窗都只打一次勾 |
| 1d | 老钟：两段推近 + Hold 上弦 + 钟摆/滴答随进度连续变化 + D05 + 可选 O02 | 半途松手保留进度；无校准无计时 |
| 1e | 钥匙：给 `focus_gesture.gd` 加 Pick & Place；`EAST DUTY`；摆动衰减；D06（等余音）；可选 O03；去掉城堡翻牌 | 放错位置钥匙滑回、不判错 |
| 1f | 盖章：Pick & Place；未完成时列出缺项；D07 与约 1 秒静默；红签页新文字；D00_EXIT；进机械室 0.3 秒淡出；笔记面板与 H 提示改 v1.3 名称；铭牌等可选发现改成新镜头形式 | S01 验收清单 11 条全过（见 `S01_Hall_Revised_v1_3.md` 的 S01.H） |
| 1g | 更新 `README.md` 大厅流程；旧锁定稿加取代标注 | — |

**Phase 2–6**：S02 机械室 → S03 顶层书库（最大，拆成水桶与水滴循环 / 观察视图 / 四格草图与木盒三段）→ S04 Kath 的房间 → S05 警报 → S06 维修路。每阶段的文件、功能、可复用素材、需补资源、测试用例与验收，见 `plans/01_analysis_and_six_phase_plan.md` 第五部分和需求映射表；镜头与手势沿用 S01 建好的组件。

## 7. 已踩过的坑

- 近景的“打开过渡”主补间结束才允许操作。曾把一个 0.8 秒的装饰补间并进去，导致近景迟迟不可操作、测试失败。
- 截图时测试窗口若被最小化，读回的是空白图；`_capture()` 现在会先恢复窗口。看到 3–6 KB 的 PNG 就是这个问题。
- 开窗口跑测试时帧时间不稳，“按一下再松开”可能被当成按住；需要精确的轻点请在同一帧内直接调用 `_unhandled_input` 发按下和松开。
- 改了近景的开合时长要同步 `tests/support/story_test.gd` 里的 `FOCUS_IN` / `FOCUS_OUT`。
- Kath 让位后，若不在关闭时把她移回原位，“最近热点”会从门变成铭牌，后续按 E 开错东西。
- Godot 把 `docs/prologue/*.csv` 当翻译表导入，生成了 `.import` 和 `.translation` 文件。它们无害但不该进版本库；可把该 CSV 的导入类型改为 Keep，或把这些产物加进 `.gitignore`（待用户决定）。

## 8. 需要用户补充或决定的事项

- 门闩切片的试玩结论。
- 红签页英文草稿是否通过。
- 可选补充美术：老钟近景的干净底图（去掉钟摆与摇柄）、合上的笔记本封面与折叠纸条、窗框干净底图、钟门打开状态、按大厅那扇门重画的门特写、Kath 过肩背影专用图。都有占位做法，不阻塞开发。
- 可选补充音效：门闩摩擦、盖章闷响、钥匙碰撞、上弦棘轮、纸条展开、室外风声循环。目前复用现有音效并调音高。
