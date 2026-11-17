# 给 Codex 的提示词

在仓库根目录 `Physics-Story-Game/` 里启动 Codex（它会自动读取 `AGENTS.md`）。下面三段按场合复制使用。

## A. 首次接手（只读，不改代码）

```text
你将接手一个已经在开发中的 Godot 4.7.2 游戏项目《Footnotes to the World》，继续开发它的序章（S01–S06）。这不是新项目，不要重建。

请先完整阅读，不要改任何文件：
1. AGENTS.md
2. docs/prologue/HANDOFF.md
3. docs/prologue/plans/02_door_close_shot_plan.md
4. docs/prologue/plans/01_analysis_and_six_phase_plan.md
5. docs/prologue/S01_Hall_Revised_v1_3.md
6. scripts/library_hall.gd、scripts/hall_prop_focus.gd、scripts/focus_gesture.gd、scripts/focus_camera.gd、scripts/story_room.gd、scripts/prologue_lines.gd
7. tests/support/story_test.gd、tests/focus_gesture_test.gd、tests/hall_focus_camera_test.gd

然后做两件事：
- 运行 .\tools\run_tests.ps1，确认结果是 34 passed, 0 failed；如果不是，把失败信息原样告诉我，不要动手修。
- 用中文向我复述：(1) 目前做到哪一步、卡在哪；(2) 已经定案、不能擅自改的决定有哪些；(3) 门闩的“全屏过肩特写”是怎么配置出来的；(4) 你理解的下一步是什么、打算改哪些文件。

复述完就停下，等我确认。在我确认之前不要修改代码，也不要提交 git。
```

## B. 开始一个具体步骤（把步骤号和反馈换成实际内容）

```text
请按 docs/prologue/HANDOFF.md 第 6 节执行步骤 <1b / 1c / …>，只做这一步。

我对上一步的反馈：<在这里写试玩感受或“无”>

要求：
- 遵守 AGENTS.md 的全部硬性规则；沿用门闩切片的做法（FOCUS_VIEWS 配置 + hall_prop_focus 的 shot 模式 + focus_gesture），不要另起一套系统。
- 动手前先用几句话告诉我：要改哪些文件、新增什么、哪些现有测试需要更新。涉及 HANDOFF.md 没定案的设计选择时先问我。
- 对白只能用 scripts/prologue_lines.gd 里已有的 ID。
- 完成后依次运行：相关子集（.\tools\run_tests.ps1 -Filter <关键词>）和全量（.\tools\run_tests.ps1），必须全部通过。
- 用 -CaptureDir 输出 1672x941 与 1280x720 截图到项目外的目录，并告诉我路径和每张图是什么时刻。
- 最后更新 docs/prologue/HANDOFF.md 的“已完成”“当前卡点”“已踩过的坑”三节，使它反映最新状态。
- 用中文汇报：改了什么、玩家能看到什么变化、测试结果、哪些没做或没验证。不要提交 git。

做完这一步就停下，等我试玩确认。
```

## C. 只想调整手感或画面时

```text
我在 Godot 里试玩了 <物件>，感受如下：<具体描述，例如“拖动距离太长”“Kath 的背影挡住了门闩”“溶入太快”>。

请只调整相关参数和必要的少量代码，不要扩大范围。先告诉我你准备改哪几个数值或哪一段逻辑，再动手。改完跑相关测试子集和全量测试，重新出截图，并用中文说明改前改后的差别。不要提交 git。
```

## 使用建议

- 每次只给一个步骤，等试玩确认后再给下一个；一次塞多个步骤最容易跑偏。
- Codex 改完后，自己在 Godot 里 F5 → New Game 实际玩一遍。自动测试只能证明逻辑没坏，证明不了手感。
- 如果它提出要改名 flag、重写某个系统、或合并两份设计文件里冲突的说法，先让它停下说明原因。
- 设计有变化时，先改 `HANDOFF.md` 第 2 节“已定案的决定”，再让它动手，这样后续每一轮都以同一份记录为准。
