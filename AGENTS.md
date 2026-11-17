# AGENTS.md — Footnotes to the World

给接手开发的 AI 代理的常驻规则。开始任何任务前先读完本文件，再读 `docs/prologue/HANDOFF.md`。

## 项目

- Godot **4.7.2**，GL Compatibility，2D 横版剧情探索游戏。设计画布 1672×941，默认窗口 1280×720。
- 主角 Kath，同伴 Wick（**永远不说话**）。当前工作范围：**仅序章 S01–S06**。第一章已完成，不要改。
- 平台 Windows。Godot 位于 `D:\Game\Godot-4.7.2\`（`Godot_v4.7.2-stable_win64_console.exe` 用于命令行）。

## 权威资料（冲突时按此顺序）

1. 用户在对话里的最新指示。
2. `docs/prologue/HANDOFF.md` 里“已定案的决定”。
3. `docs/prologue/S01_Hall_Revised_v1_3.md`（仅 S01）。
4. `docs/prologue/Kath_Prologue_Implementation_Script_v1_3.md`（S02–S06 与全局约定）。
5. `docs/prologue/Kath_Prologue_Dialogue_Lines_v1_3.csv`（英文对白，按 Dialogue ID）。

`docs/PROLOGUE_HALL_SCENE_LOCKED.md` 与 `docs/PROLOGUE_GAME_SCRIPT_REVISED.md` 是旧稿，S01 已被 v1.3 取代，只作历史参考。设计文件之间发现新的实质冲突时，**列出来问用户，不要自行合并**。

## 硬性规则

- **增量修改，不重建。** 已有功能优先改，不另起一套；不删除或替换现有场景、脚本、图片、动画，除非先说明并得到同意。
- **一次只做一小步**，每步都能单独运行和测试。做完一个纵切片先停下给用户看，再铺开。
- **不改名现有 flag 和笔记 id。** 第一章、`story_guide.gd` 和测试依赖它们（如 `hall_door_latched`、`hall_window_fixed`、`hall_east_key_sorted`、`machine_baseline_recorded`、`incident_complete`、`newton-note`、`castle-alarm`）。v1.3 文档里的示例键名一律映射到现有键。
- **`PrologueState.flags` 只能存 bool / int / float / String。** 存数组或字典会让整份存档校验失败（`scripts/prologue_state.gd` 的 `_read_checkpoint_path`）。
- **对白只从 `scripts/prologue_lines.gd` 取**，用 `_say("D03")` 这类 ID 调用；不要在房间脚本里新写英文台词。改台词要同时改 CSV，`tests/prologue_lines_test.gd` 会逐条比对。
- **叙事边界**：Wick 不说话；不解释失名之夜；序章不讲解 `F = ma`；城堡只倾斜 12°，不出现 180°；不加直白的哲学独白；可选观察永远不阻塞主线；真正的觉醒留在 S03 水滴场景。
- **交互原则**：无计时、无失败态；每个鼠标拖动都要有键盘等价操作；任何近景任何时刻都能 Esc 退出且不丢已保存的状态。
- **不提交 git、不推送**，除非用户明确要求。

## 运行与测试

```powershell
# 全量（约 5 分钟；hall_patrol_order_test 单项约 160 秒）
.\tools\run_tests.ps1
# 子集
.\tools\run_tests.ps1 -Filter hall
# 出审阅截图（会开窗口，输出 1672x941 与 1280x720 两种）
.\tools\run_tests.ps1 -Filter focus -CaptureDir <项目外的绝对路径>
```

- 每个 `tests/*_test.gd` 继承 `tests/support/story_test.gd`，实现 `_run()`，用 `_fail()` / `_pass()` 结束。
- 每次改动后至少跑相关子集；一步做完跑全量。**当前基线：34 项全部通过。** 任何时候都不能让原有测试变红后不管。
- 测试不得往项目目录里写文件；截图目录必须在项目外。
- 新增 `.gd` 后 Godot 会生成同名 `.uid`，属于正常产物，随脚本一起保留。

## 代码结构

- `scripts/story_room.gd`（`class_name StoryRoom`）：所有房间的基类——模式、对白、笔记、热点、暂停、音频、天气。房间脚本只填 `hotspots`、实现 `_inspect()`，按需覆写 `_room_input()`、`_cancel()` 等钩子。
- `scripts/prologue_state.gd`（Autoload `PrologueState`）：`flags`、`notes`、单槽存档。`scripts/game_settings.gd`（Autoload `GameSettings`）：偏好与改键（E / J / H）。
- `scripts/hall_ui.gd`：共用 HUD（已 1100+ 行）。**新界面请独立成脚本/场景，不要继续往里堆。**
- `scripts/story_guide.gd`：当前目标与 H 三级提示，由存档状态推导，不另存任务状态。
- 大厅专用：`library_hall.gd`（`FOCUS_VIEWS` 数据驱动的近景配置）、`hall_prop_focus.gd`（近景/全屏特写呈现）、`focus_gesture.gd`（手势）、`focus_camera.gd`（聚焦镜头）、`hall_round_book.gd`（巡查册）。

## 写代码的约定

- GDScript 用 Tab 缩进、静态类型标注，注释用英文、写“为什么”，风格与周围代码一致。
- UI 节点沿用现有做法：在脚本里创建，`mouse_filter = MOUSE_FILTER_IGNORE`；鼠标命中用画布坐标的 `Rect2` 手算，输入从房间的 `_room_input()` 转发。
- 手改 `.tscn` 时记得同步 `load_steps` 和 `ext_resource` 的 id。
- 装饰性的补间不要并进“打开过渡”的主补间，否则会拖长 `transitioning`，导致近景迟迟不可操作。
- 面向玩家的文字全部英文；与用户沟通用中文。

## 汇报要求

每完成一步，用中文说明：改了哪些文件、玩家能看到什么变化、跑了哪些测试及结果、哪些没做或没验证。测试失败要贴出失败信息，不要含糊带过。
