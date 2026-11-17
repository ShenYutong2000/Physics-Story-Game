# 《序章：尚未完成的问题》游戏详细脚本与 Godot 实施规格

**英文暂定名：** Prologue — A Question Yet to Be Answered  
**版本：** v1.2（大厅清单发现 + 三任务自由顺序）｜供剧情检查、交互原型与 AI 辅助开发  
**范围：** 仅序章；傍晚暴雨将至 → 雨夜 → 次日清晨；不包含第一章具体关卡  
**玩家角色：** Kath  
**陪伴角色：** Wick（通过飞行、停留和微光提示，不说话）  
**主旨：** 人如何重新获得思考能力，并在理解世界的过程中重新理解自己。

> **阅读约定：**【既有约束】来自上传的《序章-改进版》；【本版细化】为结合此前对话提出的可执行方案，并不代表已存在于 Godot 工程。尤其大厅原稿指向未一同上传的 `PROLOGUE_HALL_SCENE_LOCKED.md` 作为最终权威版本；本 v1.3 采用“笔记夹页先发现 + 三任务任意顺序”的可实施草案，实际并入工程前必须与该锁定文件核对，不应直接覆盖其既定英文文案和物件状态。

---

# 0. 全局设计约定

## 0.1 核心叙事与演出原则

- **日常不是错误的。** 初始 Kath 认真、可靠，依靠清单维持万象馆秩序，不被描写成“没有思想的人”。她在熟悉任务中偶尔注意到微小异常，但没有立即形成宏大的生命反思。
- **觉醒不是一次台词。** 大厅的停顿 → 机械室依据观察留下基线 → 书库在任务完成后主动停留 → 允许草图保留错误 → 警报时依结果判断 → 选择赴城堡，是同一条变化线。
- **玩家先于对白看到证据。** 尤其水滴四现象：不主动弹出理论解释，Kath 的一句短问只在玩家观察对应区域后出现。
- **任务完成 ≠ 理解完成。** `ROUND FILED` 为工作完成标记；新笔记容纳未完成的问题，不提供“科学问题已全部解决”的印章。
- **不把科学问题做成考试。** 序章不讲解牛顿第二定律，不要求选重力或表面张力作为答案；草图的检查是“确实做了观察记录”，不是物理术语准确率测验。
- **无超自然恢复记忆。** 旧残页证明过去的工作经历和笔迹，不触发完整闪回、幻觉或突然解锁科学知识；Wick 的光只是常规角色演出与注意力提示。
- **安全程序不可随意违背。** 第二天必须落实万象馆本地隔离、警示与记录；操作机械并非鼓励无依据地乱拉手柄。

## 0.2 场景地图与剧情章节的区别

**五张地图，六个叙事 Section：**

1. `Hall.tscn`（S01 傍晚首次巡查；S05 清晨警报过场）
2. `MachineRoom.tscn`（S02 夜前基线；S05 清晨应急）
3. `TopLibrary.tscn`（S03 雨夜水滴观察与残页）
4. `KathRoom.tscn`（S04 夜间笔记比对及晨起）
5. `MaintenanceRoad.tscn`（S06 清晨确认倾斜并前往城堡）

> 地图名均为**建议标识符**；与实际 Godot 场景文件路径不同时，开发时映射现有文件，不擅自重建重复场景。

## 0.3 单场景交互编号与严重性

每项交互写作 `S01-I04`。属性：

- **[M] 主线必需**：主线解锁依赖该状态；允许回退、重试。
- **[O] 可选观察**：不强制，不计入清单，不阻塞主线。
- **[R] 可重复**：可以再次进入，关键剧情对白和奖励只触发一次。
- **[C] 条件分支**：取决于此前的玩家操作；不能让玩家因不同顺序而被卡住。

**约定控制（桌面键盘 + 鼠标，可配置）：**

| 操作 | 默认输入 | 游戏表现 |
|---|---|---|
| 移动 | A/D 或左右键 | 角色在横向场景中行走；近景界面另行复用方向键 |
| 交互 | E | 进入物件近景、拾取、确认可执行的世界操作 |
| 确认/记录 | Enter | 接受当前标记、确认纸页、进入下一章节 |
| 取消/退出 | Esc | 退出近景或撤销草图当前步骤；不清除已保存进度 |
| 提示 | H | 逐级显示“下一处值得关注的位置”，不自动给出答案 |
| 笔记 | N（建议） | 任务清单/观察笔记切换；必须支持鼠标 UI 入口 |
| 推桶/推梯 | 靠近后 E 抓取，左右移动，E 放下 | 可拖动对象需有范围限制与就位反馈 |
| 草图 | 鼠标拖拽；或方向键移笔尖 + E 落笔 | 低门槛符号化涂画，非自由像素绘图 |

**交互提示**：邻近物件出现细小 `E Inspect`、`E Interact`，不在全屏铺满问号；可交互对象获得轻微轮廓或灯光。已完成可再看对象仍可调查，但不重复弹剧情。

## 0.4 全局进度状态（示例键名）

建议使用 Godot Autoload `PrologueState.gd` 或复用既有存档管理器。状态命名可映射工程现状。

```yaml
world:
  time_phase: evening               # evening / rainy_night / next_morning
  rain_stage: approaching           # approaching / starting / heavy / stopped
  chapter: prologue
hall:
  notebook_opened_once: false
  checklist_discovered: false
  door_latched: false
  window_fastened: false
  clock_wound: false
  east_key_returned: false
  task_doors_windows_complete: false
  task_clock_complete: false
  task_key_complete: false
  hall_round_filed: false
  hall_optional_notices: []         # condensation / pendulum / key_wear 等
machine:
  baseline_saved: false
  baseline_normalized_pos: null     # 0..1，与指针画面坐标或角度关联
  alarm_seen: false
  alarm_gauge_compared: false
  emergency_card_seen: false
  lever_2_done: false
  lever_4_done: false
  local_drive_stopped: false
  upper_lift_warning_sent: false
  alarm_record_saved: false
  castle_tilt_cutscene_seen: false
library:
  bucket_position: 0.0
  bucket_catches_drip: false
  books_protected: false
  observation_seen: {seam: false, speed: false, direction: false, splash: false}
  touched_small_drop: false
  notebook_cells_done: [false, false, false, false]
  notebook_strokes: [[], [], [], []]
  favorite_question: null          # 0..3，选填
  ladder_position: 0.0
  ladder_wheels_locked: false
  wooden_box_found: false
  old_page_collected: false
room:
  lamp_on: false
  page_match_confirmed: false
  castle_index_seen: false
  notes_compared: false
  slept: false
  bag_packed: false
road:
  cable_noted: false
  wing_noted: false
  gate_open: false
  prologue_complete: false
ui:
  once_dialogue_ids: []
  hint_stage_by_section: {}
```

**存档触发**：关键任务完成、手动调整桶/梯位置、每格笔记完成、圈选疑问、残页拾取、比对完成、休息、装包、应急操作、事故记录、闸门打开。循环水滴动画的当前帧无须存档。再次加载应回到可操作状态而不是重新执行过场。

## 0.5 剧情门槛与防卡死规则

```text
START S01
  └─ 打开笔记 → 展开夹页清单
      └─ {门闩 + 窗扣（门窗合成一项）、上弦、东侧钥匙归位：任意顺序}
          └─ 玩家主动盖 ROUND FILED
          └─ S02 机械室开放
              └─ 玩家亲手保存正常基线
                  └─ 回大厅听到明显漏水 → S03 顶层书库
                      └─ 桶接住水 → 保护书籍
                          └─ 4 格观察草图均有记录（可随时返看水滴）
                              └─ Wick 指向书架 → 锁梯轮 → 木盒 → 取得残页
                                  └─ S04 房间开放 → 开灯 → 笔记对齐确认
                                      └─ 床铺休息 → 清晨装包
                                          └─ S05 警报 → 应急隔离 + 警示 + 事故记录
                                              └─ 观测城堡倾斜 → S06 维修路
                                                  └─ 打开检修闸门 → PROLOGUE COMPLETE
```

- S01 必须先在笔记中发现夹着的任务清单；清单展开后三项巡查**任意顺序**，门窗内部两个子动作也可任意顺序。
- S02 可返回大厅重新进入；未保存基线时不会错误触发雨夜书库的主线。
- S03 可先观察水滴再推桶；但是绘制最终观察页的主线确认要求书籍已保护。四格内部顺序自由。
- S03 木盒剧情须在四格草图都留下记录后触发 Wick 的书架提示；梯上轻碰水滴绝不参与木盒解锁。
- S04 在确认残页归属之前不能睡觉推进清晨；早上若未装包，出门给简短提醒。
- S05 应急操作支持“先拉两柄后停机”和“先停机后处理剩余负载”两条安全完成路径。
- S06 未强制观察全部可选物件也可开门；第一章仅由结尾 Enter 进入，Esc 返回道路。

---

# S01. 万象馆大厅｜从笔记里发现今天的清单（v1.3 · 对白润色）

> **适用范围：**仅序章 S01，以 v1.2 为交互基准，仅润色对白与微表演；后续 S02–S06 不做剧情调整。  
> **本次改动：**仅润色对白，不改逻辑。保留 v1.0 的三项简洁任务玩法（门闩与窗扣、老钟上弦、东侧值班钥匙归位），增加“先打开笔记→发现夹页清单”开场。**清单一经发现，三个任务完全可以任意顺序完成**；门与窗两项子操作也可自由排序。  
> **重要排除项：**不采用 v1.1 的门扇压合/门把复查链、窗扣多角度对齐、调节钟摆中心线、固定观看三周期、双钥匙辨认或逐项激活。  
> **未提供的锁定规格：**原工程可能另有 `PROLOGUE_HALL_SCENE_LOCKED.md`。若开发 AI 在项目中发现此文件，应先核对现有物件与对白，不擅自覆盖已锁定内容。

## S01.A 场景目标与气氛

- **地点与时间：**万象馆大厅，暴雨将至的傍晚；室内灯光偏暖，窗外乌云加深、树叶受风轻晃；钟摆持续发出滴答声。
- **故事功能：**先让玩家进入 Kath 熟悉的工作节奏，经过少量不强制的感官观察，感到“完成任务”与“理解世界”之间存在微小距离。觉醒的正式转折仍留在 S03 水滴场景。
- **主线目标：**翻开笔记、发现夹页清单、自由完成 `Check Doors & Windows`、`Wind & Check the Clock`、`Return East Duty Key`，最后回到桌前手动盖 `ROUND FILED`，解锁 S02 机械室。
- **场景热点：**巡查桌与合上的笔记、主门门闩、高窗窗扣、机械钟、第三挂钩及东侧值班钥匙、手动印章、机械室入口；红签应急页、旧铭牌、钟内盖铭文与目录卡为可选调查。
- **自由顺序规则：**只有“发现清单”早于正式维护、以及“完成全部任务”早于盖章，是强制顺序；三项任务之间**没有前置依赖**。玩家看过清单后可先处理钥匙、再钟、最后门窗，或采用任何其他排列。

## S01.B 开场：先有笔记，后有清单

### S01-I00 [M] 进入大厅与引导至巡查桌

**镜头与环境：**Kath 站在巡查桌附近。两秒内可立即移动，不自动弹出清单 UI。桌上合着一本旧笔记，封面露出折叠纸的一角。Wick 在桌旁停留或短距离飞行，不说话。远处钟鸣后继续滴答，雨声尚未大到盖过环境音。

**玩家操作：**自由移动；靠近笔记出现 `E — Open Notebook` 的轻量交互提示。若先查看门、窗、钟或钥匙，可以近距离观察物件，但在读清单前不能改变巡查完成状态；Kath 可以轻声说 `I'd better find tonight's page before I begin.`（D00），只触发一次。

**对白 D01（新增建议）：**Kath: `Evening again. The light leaves the hall so quietly.`

**系统状态：**开场不自动产生已激活任务；`hall.checklist_discovered=false`。

### S01-I01 [M/R] 打开笔记，抽出夹着的清单

**近景画面：**展开的笔记左侧可看到多张过去巡查页的勾与 `ROUND FILED` 印章；右页夹着折叠的纸条，边缘写着 `EVENING ROUNDS`。红签 `EMERGENCY` 位于侧边，随时可再次查看。

**玩家必须完成的两个动作：**
1. **打开笔记：**靠近巡查桌按 E，或用鼠标点击笔记封面；播放翻页的短动画，展示右页夹着的纸条。此时**仍不出现 HUD 任务清单**。
2. **展开夹页：**玩家点纸条或将焦点移到折叠纸按 Enter，纸条展开，显示三个空方框和任务名称：
   - `Check Doors & Windows`
   - `Wind & Check the Clock`
   - `Return East Duty Key`

**对白 D02：**Kath: `Three small things to set right before the rain.`

**可选对白 D02b：**若玩家首次打开笔记却没有展开纸条，关闭后重新打开并发现夹页，Kath 可轻声说：`There you are, tucked between yesterday's pages.`；仅播放一次，不叠加 D02 同一时刻的字幕。

**UI 与引导：**显示清单之后，才在界面角落出现简洁任务入口，例如 `Evening Rounds · 0/3`；不需要单独的 `Begin Rounds` 按钮，不高亮“第 1 项”为唯一当前任务。玩家可按 N 或从 UI 图标再次翻看。退出时三项并列显示，没有强制序号、锁定标记或“Next task”跳转。

**中断与重入：**第一次打开笔记后就关闭，记录 `notebook_opened_once=true`，但仍未解锁维护；再次打开可继续展开夹页。展开完成后记录 `checklist_discovered=true` 并自动存档。之后重开无需再播放强制展开动画。

**叙事暗示：**重复的旧清单与整齐的印章建立“平凡而重复的生活”，不要让角色在此宣告人生困惑。

## S01.C 三项巡查（任意顺序）

**统一前置：**`hall.checklist_discovered == true`。三个任务对应独立完成标记，不检查 `active_task`；完成某项后立即在笔记对应框中手动打勾的简短动画，可以用一笔自动表现 Kath 记录，不要求返回桌面。仍能再次查看已完成物件。

### S01-I02 [M/R] 检查主门门闩（门窗子项 A）

- **初始状态：**主门合上但门闩尚未完全扣紧，风从门边传来很轻的声音。
- **玩家做什么：**走近主门按 E 查看门闩的局部近景；识别未锁紧状态，点击或按 E 将门闩沿导轨推至终点。无需压合门扇、拉门把测试等额外强制步骤。
- **反馈：**门闩移动并发出 `click`；门缝光略微缩窄，风声变化，画面短提示 `Door latched`。动作完成后 `hall.door_latched=true`。
- **对白 D03：**Kath: `That should hold. The wind loves finding little gaps.`
- **错误与重复：**不在交互范围点击不会改变状态；关闭近景后随时可回来，已扣好则显示锁紧状态，不能刷完成事件。无需惩罚、无需限时。
- **动画/声音：**2–4 帧门闩滑动、锁止状态；`SFX_latch_slide`、`SFX_latch_click`；背景风声持续。

### S01-I03 [M/R] 检查高窗窗扣（门窗子项 B）

- **初始状态：**高窗稍微松开，金属窗扣处于未固定角度，窗外风吹动树枝，天空转灰。
- **玩家做什么：**走近高窗按 E 进入窗扣近景；点击、拖动或按 E 将窗扣推到固定位置，窗扇轻合。无需多角度旋转、精细校准、再轻拉窗户等强制环节。
- **反馈：**窗扣转到锁定方向并发出 `click`，外部风声变闷，但窗外风、云等环境现象继续播放；`hall.window_fastened=true`。
- **对白 D04：**Kath: `The sky is restless tonight. This window can rest.`
- **可选观察 O01：**玩家可查看玻璃冷意、薄雾和窗外天气。Kath 轻声说 `Warm inside... yet the glass carries the evening chill.`；动作表现为触摸玻璃后短暂停顿。只写入 `hall.optional_notices`，不解释温度、凝结或天气原因。
- **门窗共同完成逻辑：**仅当 `door_latched && window_fastened` 时，在清单的 **同一个** `Check Doors & Windows` 方框打勾。无论先做门或先做窗，均只触发一次。门与窗的已完成状态分别持久化。
- **动画/声音：**窗扣 2–4 帧、窗扇轻合、触玻璃可选演出；`SFX_window_latch`、`SFX_wind_outside`。

### S01-I04 [M/R] 老钟：查看、上弦、确认运行

- **初始状态：**钟仍有节奏地运行，但需要例行上弦；金属内盖可打开，钟摆和齿轮已处于循环动画中。
- **玩家做什么：**靠近老钟按 E 打开内盖；观察上弦接口；按住 E 短时转动或用鼠标进行简短旋转（原型可简化为两次点击），然后看钟摆保持运行，按 Enter 或退出近景确认。**不是**调钟摆中心线的精密操作。
- **反馈：**上弦柄微转、齿轮啮合短动画、滴答声持续；状态显示 `Clock running`；`hall.clock_wound=true`，笔记勾选时钟任务。
- **对白 D05：**Kath: `One more turn, and the old clock keeps its steady song.`
- **可选观察 O02：**玩家停留查看钟摆与表针，镜头先摆动后钟面；Kath: `The pendulum comes back. The hands keep moving on.`；仅记 `hall.optional_notices += pendulum`，不讲周期公式或时间的本质。
- **重试/防卡：**提前退出不完成上弦时，再进仍可继续；完成后保留运行状态；不设计过度上弦损坏机制或计时操作失败。
- **动画/声音：**钟盖打开/关闭、上弦柄、齿轮轻动、钟摆循环、表针微动；`SFX_clock_wind`、`SFX_clock_gear`、`SFX_clock_tick_loop`。

### S01-I05 [M/R] 东侧值班钥匙归位

- **初始状态：**钥匙架有编号挂钩，第三处标有磨损的 `EAST DUTY` 标签；东侧值班钥匙位于架旁的简易暂放位置，**只有需要归还的这一把钥匙参与任务**。
- **玩家做什么：**靠近钥匙架按 E，查看标签；选择 `East Duty Key`，点击第三挂钩或拖动过去，也可用方向键移动焦点并按 E/Enter 放上去。无需双钥匙匹配、旋转模型识别或额外复查小游戏。
- **反馈：**钥匙挂上后摆动两三次、逐渐停住；发出清脆金属碰撞声；`hall.east_key_returned=true`，笔记勾选钥匙任务。
- **对白 D06：**Kath: `Third hook, as always. Even the little clink sounds familiar.`
- **可选观察 O03：**查看磨损的金属边缘和褪色标签；Kath: `The brass is worn smooth. Whose hands held it before mine?`；没有隐藏门的确定暗示，不计进度。
- **错误与重复：**如果玩家没有选中第三挂钩，不自动将钥匙放错，也不直接判定完成；允许调整目标。任务完成后可重新观察，但不重复新增勾或重播关键对白。
- **动画/声音：**钥匙移动、悬挂后摆动衰减；`SFX_key_clink`。

## S01.D 不要求按顺序的任务引导与清单更新

**清单 UI：**三个并列复选框，任何未完成项都可通过点选查看任务描述，但不能远程自动操作物件。全部都是可执行状态，未完成项不显示锁形图标，不出现 `01/03 → 02/03` 的强制当前项。

**轻量环境提示：**如果玩家在大厅游走且未进展，H 提示先强调“查看笔记”或已经打开的清单，再给出离玩家最近的一个未完成物件位置。可选观察永远不作为必做条件。

**任务完成事件：**

```gdscript
# 表达意图的伪代码：请映射到工程现有脚本与信号
func on_hall_object_updated() -> void:
    if not hall.checklist_discovered:
        return
    var windows_done := hall.door_latched and hall.window_fastened
    hall.task_doors_windows_complete = windows_done
    hall.task_clock_complete = hall.clock_wound
    hall.task_key_complete = hall.east_key_returned
    update_notebook_checks_once()
    save_game()

func can_file_round() -> bool:
    return hall.checklist_discovered and hall.door_latched \
        and hall.window_fastened and hall.clock_wound \
        and hall.east_key_returned
```

**允许的完成路径示例：**

```text
进入大厅 → 打开笔记 → 展开夹着的清单
    ├─ A: 门闩 → 窗扣 → 时钟 → 钥匙 ─┐
    ├─ B: 钥匙 → 时钟 → 窗扣 → 门闩 ─┤
    ├─ C: 时钟 → 门闩 → 钥匙 → 窗扣 ─┤
    └─ D: 其他任意排列（门/窗均是独立子交互） ─┘
                  ↓
            三项方框全部打勾
                  ↓
          回到桌前亲手盖章归档
                  ↓
             开放机械室 S02
```

## S01.E 自由调查、盖章及场景转移

### S01-I06 [O/R] 旧铭牌、钟内盖铭文、目录卡

玩家可在大厅中任意时刻调查旧铭牌、钟盖铭文和目录卡；只显示少量名称与残留用途，不解释失名之夜原因，不触发记忆恢复，也不计入巡查。可放在已经执行的钟盖近景中，不强制额外切图。

### S01-I07 [O/R] 红签应急页

红签位于巡查桌笔记一侧；**从首次进入起可查看，即使清单未展开、盖章后仍存在**。点击后显示基本安全原则：比对红线、遵循墙上应急程序、必要时隔离本地驱动和警示上层升降机风险。不提前剧透次日事故的确切处理顺序。

### S01-I08 [M] 玩家亲手盖 `ROUND FILED`

- **前置条件：**`checklist_discovered && door_latched && window_fastened && clock_wound && east_key_returned`。
- **玩家动作：**回巡查桌，打开已打勾的清单，选中印章，再点击纸张盖章区或按 Enter。**不能由任务勾选自动播放盖章**。
- **成功动画：**印章落下约 0.5–0.8 秒，纸张归档移走，出现下一张空白清单；应急红签仍保留在桌边；机械室入口开始可用。声音：`SFX_stamp_impact`、`SFX_archive_slide`。
- **对白 D07（建议）：**Kath: `Three small marks, and another evening folded away.`；之后可以只有钟摆和风声，不加入说教式人生旁白。
- **未完成时：**允许查看印章，但点击时只显示尚未完成的项目名；不会帮玩家补齐或直接跳过。
- **状态：**`hall.hall_round_filed=true`，立即存档。重进大厅不重复播放归档动画。

### S01-I09 [M] 转入机械室

**前置条件：**`hall.hall_round_filed`。玩家靠近机械室入口按 E，短淡出转场 S02。若提前尝试，Kath（D00_EXIT）: `The rounds aren't filed yet. One thing at a time.` 已完成事项保持不变。

## S01.F 媒体与实现清单

| 资源编号 | 资源 | 实现要求 | 优先级 |
|---|---|---|---|
| UI-H01 | 合上的笔记、露出纸角、翻页与展开夹页 | 初次进入不出现清单；必须二次交互读出三项 | 必须 |
| UI-H02 | 任务清单 3 个并列方框与 0/3 计数 | 任何顺序勾选，不高亮锁定任务 | 必须 |
| UI-H03 | 门闩局部近景 | 看见未扣状态、点击/按 E 扣紧、保持结果 | 必须 |
| UI-H04 | 高窗窗扣近景 | 看见未锁状态、点击/按 E 固定；玻璃可选观察 | 必须 |
| UI-H05 | 老钟内盖近景 | 两步简易上弦与钟摆持续运行，不增加调节谜题 | 必须 |
| UI-H06 | 东侧钥匙及第三挂钩 | 单钥匙归位与金属摆动反馈 | 必须 |
| A-H01 | 风、树叶、傍晚乌云 | 持续且不随任务完成而消失 | 必须 |
| A-H02 | 机械钟循环、齿轮、上弦 | 低成本局部动画即可 | 必须 |
| A-H03 | 盖章与旧页归档 | 玩家确认后才触发 | 必须 |
| A-H04 | Kath 的微表演 | 触玻璃、观察钟摆、看钥匙磨损，均可选 | 推荐 |
| AUD-H01 | 钟摆、风、纸张、门窗、钥匙、印章 | 避免音效过密或覆盖对白 | 必须 |

**镜头约束：**玩家自主进入对象近景；不以剧情强制拉近每一处科学现象。视觉停顿 0.3–1 秒，尽量允许跳过。Wick 不替玩家指出哪一项任务“接下来必须做”。

## S01.G 状态机与存档规范

```yaml
hall:
  notebook_opened_once: false       # 读到夹页前可能仅打开笔记
  checklist_discovered: false       # 此状态是三项维护的唯一共同前置
  door_latched: false
  window_fastened: false
  clock_wound: false
  east_key_returned: false
  task_doors_windows_complete: false # 派生或缓存，不是主状态的替代
  task_clock_complete: false
  task_key_complete: false
  hall_round_filed: false
  optional_notices: []             # glass / pendulum / key_wear / old_plaque ...
```

**绝对不要保留 `active_task`、`clock_adjusted`、`key_identified` 等 v1.1 的必做门槛。**旧存档升级时若有这些字段，可忽略，不得把它们用于 v1.2 任务解锁。不可因先处理钥匙或时钟而丢失该任务完成状态。

**持久化要求：**保存展开清单、四处维护对象的状态、三格勾选、可选观察、盖章进度。返回大厅不能重新出现“再展开清单”的主线动画；S05 清晨进入大厅时保持傍晚巡查已归档，不重复触发 S01。

## S01.H 验收清单

- [ ] 初次进入大厅只看到笔记和场景，不自动显示 3 条任务 HUD。
- [ ] 玩家必须先打开笔记，再展开夹着的 `EVENING ROUNDS`，才看到 3 个任务。
- [ ] 任务清单出现后，**门窗、时钟、钥匙可任意顺序完成**；门闩与窗扣也可以互换。
- [ ] 没有 `active_task` 或下一项强制激活；已完成项自动勾选且只记录一次。
- [ ] 主门只要扣门闩；高窗只要固定窗扣；老钟只需简易上弦并观察；钥匙只要挂到第三钩。
- [ ] 不出现精密钟摆调节、门窗连环校准、两把钥匙辨认或强制复查步骤。
- [ ] 3 项未全部完成时印章无效；全部完成后玩家必须自己盖章。
- [ ] 盖章后今日清单归档、露出下一张空白页；应急红签仍可查看。
- [ ] 玻璃、钟摆、钥匙磨损等探索可选，不强制科学理论问答。
- [ ] 存档/读档后，清单状态、任务完成状态和返回大厅的状态均正确。
- [ ] 进入 S02 不会触发任何仅存在于 v1.1 顺序版本的事件或条件。

## S01.I 交付给开发 AI 的指令

> 仅替换现有序章 S01 大厅的交互逻辑。优先复用当前 Godot 已有的门闩、窗扣、钟上弦、钥匙架、笔记、印章和场景切换代码。保留原 v1.0 任务的动作复杂度；增加首次打开笔记、展开夹页清单的双步开场交互。维护操作只要求 `hall.checklist_discovered`，不要求某一项先于另一项。四个对象的完成状态分别持久化，门窗合并为一个任务勾；三格都完成后玩家亲自盖 `ROUND FILED`，再解锁机械室。移除 v1.1 的 `active_task`、钟摆微调与钥匙匹配谜题前置条件。不要修改 S02–S06 的剧情、科学设定或关键状态。



## S01.J v1.3 对白风格与演出规范（只改文字，不改变交互）

- **核心口吻：**Kath 安静、认真、略带生活气息；诗意来自对风、光、玻璃、滴答声与磨损痕迹的细微感受，不由角色直接解释“生命意义”或“科学觉醒”。
- **字幕长度：**原则上每条英文对白 8–15 词；在同一个字幕框中最多显示两行，必要时按照句号分成两个短停顿，不同时堆叠。
- **主线对白：**D01–D07 只在首次触发对应事件时播放。若玩家任意顺序完成任务，脚本不应假定已经完成其他项目。
- **可选观察：**O01 只在主动触摸/观察玻璃时播放，O02 只在主动注视钟摆与指针时播放，O03 只在主动查看钥匙磨损痕迹时播放。每条至多一次，不触发任务进度。
- **空白与声音：**D07 后静置约一秒，只保留钟摆滴答与室外风声，不加解释式旁白，也不要强制摄像机凝视主角。
- **防重复：**已经完成的门闩、窗扣、时钟和钥匙可继续查看，但不重复朗读主线对白。角色发现问题的明确愿望仍留到 S03 水滴场景。
- **可读性：**文字轻微拟人化可以存在（钟的歌、风寻找缝隙），不要使用难懂的抽象哲学词汇；画面与物件行为必须与句子一致。

### 对白与具体表演匹配表

| 触发 | 一次性对白（英文） | 表演与节奏 |
|---|---|---|
| D01 进入大厅 | Evening again. The light leaves the hall so quietly. | 望向窗外片刻，再恢复移动 |
| D00 提前碰其他物件 | I'd better find tonight's page before I begin. | 视线轻转向桌上的笔记 |
| D02 展开清单 | Three small things to set right before the rain. | 手指压住清单边缘，随后释放自由操作 |
| D02b 再找夹页（可选） | There you are, tucked between yesterday's pages. | 抽出纸条时轻轻舒一口气 |
| D03 扣好门闩 | That should hold. The wind loves finding little gaps. | 门闩咔哒声后轻轻松开手 |
| D04 扣好窗扣 | The sky is restless tonight. This window can rest. | 看窗外风动树枝，随即转身 |
| O01 触摸玻璃（可选） | Warm inside... yet the glass carries the evening chill. | 指尖短暂停在玻璃上，不弹知识说明 |
| D05 上弦成功 | One more turn, and the old clock keeps its steady song. | 上弦声止，钟摆滴答声仍继续 |
| O02 看钟摆（可选） | The pendulum comes back. The hands keep moving on. | 视线从钟摆缓慢移至钟面 |
| D06 挂回钥匙 | Third hook, as always. Even the little clink sounds familiar. | 钥匙轻晃，等余音消散后恢复操作 |
| O03 观察钥匙磨损（可选） | The brass is worn smooth. Whose hands held it before mine? | 视线停留，没有回忆闪回或结论 |
| D07 盖章归档 | Three small marks, and another evening folded away. | 纸页被归档；留下钟声与短暂静默 |
| D00_EXIT 提前想进机械室 | The rounds aren't filed yet. One thing at a time. | 保持门不可进入，显示未完成清单 |

> **剧情边界：**从 D01 到 D07，Kath 只是在熟悉的巡查中有了细微的感官停顿。不要提前说出“我不理解世界”“我寻找什么”或“我要继续探索”；真正的主动意愿台词 `I want to see that again.` 保留在 S03。


# S02. 机械室｜记录真实，而不是预期

**时间：** 傍晚，雨刚开始。 **核心心理转折：** 从只确认“安全/完成”，转向准确比较“昨天/今天”。  
**必需交互：** 仪表位置由玩家亲自标记；不是点击自动盖章。


## S02.A 入场、环境与开放物件

- 机器低频持续振动，雨声刚出现；灯光稳定。
- 玩家能看见 4 个编号手柄、仪表红线、停机按钮、应急牌、通往城堡的线路图。
- 此时手柄和停机按钮不作为需要操作的谜题；靠近时可只读查看，不能误触造成事故。
- Wick 飞到仪表附近，翅膀照出一小圈光；它不指出答案。

## S02.B 交互详情

### S02-I01 [M/R] 仪表读数近景

- **进入**：靠近主仪表 E。打开固定尺度的放大画面：红线、当前指针、上一次铅笔痕清楚可辨。
- **初始视觉事实**：今天指针略高于昨天标记，**仍低于红线**。
- **玩家操作**：左右键移动笔记页上的铅笔位置标记（鼠标拖拽可替代），Enter 确认；Esc 返回世界但本次不记录。
- **判定建议**：将显示刻度归一化到 0..1，接受相对于当前指针位置的宽松容差；具体容差按美术画面调整，例如 ±0.06，而非一像素精度。
- **若错误明显**：不锁死、不帮玩家画正确值；Kath：`Let me look again.`；仍可比较后重试。
- **若确认成功**：新铅笔痕出现，昨天痕迹保留；今日读数进入永久笔记，并写 `baseline_saved=true`；关闭近景后不重复录入。
- **对白 D08**：`A little higher than yesterday. Still below red.`；确认后 D09：`I'll draw where it is, not where I expected it to be.`
- **失败态**：无时间损失、无扣分、无误导性“危机失败”提示。

### S02-I02 [O/R] 四个手柄与本地停机按钮

- **玩家动作**：靠近 E 查看编号和说明。
- **反馈**：若玩家试图在正常时段操作，Kath：`No reason to change these now.`；按下不会改变设备状态。
- **镜头**：可提前留下手柄与红线的位置记忆，供 S05 回访。

### S02-I03 [O/R] 城堡线路图

- **玩家动作**：E 查看线路图；可移动视野看通往 `Observatory Castle` 的检修路线。
- **视觉**：部分线路名称褪色/涂改；万象馆线路与城堡本地控制线表现为独立系统。
- **对白 D10**：`A route to the Observatory Castle.`；可选 `Some of these labels have been changed.`
- **限制**：不推断城堡异常的原因，不提前开放维修路。

### S02-I04 [M] 回大厅 / 听见屋顶滴水

- **前置**：`machine.baseline_saved=true` 才触发清晰漏水声；未完成仍允许往返，但由清单/现场提示回仪表。
- **玩家动作**：走回大厅。
- **演出**：空气更暗，雨点敲打屋顶；在钟声/雨声中加入明确但不急促的 `drip`；镜头轻微上抬指向右侧通往书库的楼梯，Wick 望向上方。
- **对白 D11**：`That sound... is it coming from upstairs?`
- **状态**：`rain_stage=heavy` 并开放 S03 上楼路线。

## S02.C 媒体与验收

- **素材**：A07 仪表近景与双铅笔痕；A08 笔尖左右移的 UI；A09 机械低频循环；A10 屋顶渐强滴水/雨声；A11 线路图遮罩。
- **验收**：不记录不能跳过基线；退出近景仍可重试；重返机房保留铅笔痕；不可在 S02 误触应急事件；正确存档后才明确引导去书库。

---
# S03. 顶层书库｜一滴水与第一个主动问题

**时间：** 暴雨夜。 **场景功能：** 解决现实漏水任务后，玩家与 Kath 第一次在“没有任务要求”的情况下，选择停下来继续观察。  
**保留物件：** 铜接缝漏点、积水、湿书、桶、梯子、干燥书桌、书架夹缝、木盒、Wick。  
**关键约束：** 不增加计时器、木箱接水、高度计算题、独立推车实验；同一循环水滴承担四个观察现象。

## S03.A 进入时的画面与角色动机

1. 雨敲金属屋顶 `SFX_rain_metal_loop`。机位先给书架底层湿书和蔓延的浅积水，再给铜接缝与滴下的水。
2. 一颗水珠附在铜边，变大，脱离，近似竖直落下，撞进地板积水，几点水向外、向上飞溅，再落回。循环播放，不能每次都以完全同频率触发角色对白。
3. Wick 悬停在漏点与湿书之间，先关注受潮问题，不像“知道定律的老师”一样逐一指示物理问题。
4. Kath 初见 D12：`Oh, no. The books.`；默认初始目标栏为 `Keep the water away from the books.`。
5. **没有倒计时、书本永久损毁失败态或强制播放完整观察教学。** 玩家可以先接水，也可以先探索水滴。

## S03.B 漏水处互动与可观察试探

### S03-I01 [O/R] 湿书与地面积水

- **对象**：低层书脊、湿痕、地面水圈。
- **玩家动作**：E 查看；不需要逐本捡书。
- **反馈**：镜头靠近水线，突出积水正接近书架，水滴声音仍继续；Kath：`The water is reaching the lower shelves.`
- **用途**：合理地解释为什么首先需要把桶摆好。若玩家没调查此处也不影响主线。

### S03-I02 [M/R] 可调整位置的水桶

- **玩家动作**：靠近桶 E 抓取 → 左右移动 → E 放下 → 等待下一滴验证；也可鼠标拖动桶到地面的允许区间。
- **判定**：滴落路径与桶口水平范围重叠时下一滴被接住，水滴撞在桶内积水上依旧有小水花；否则桶里没有新水声，水落地形成新水圈。
- **初始位置**：建议稍偏离落点，让玩家必须做一次简单预测；不能偏得离谱，以免变成找像素任务。
- **错误反馈**：滴落的物理动画本身是主要反馈；Kath 短句 `Not quite.`（首次放偏可触发，后续不刷屏）；水桶随时可移动，错误可恢复。
- **正确反馈**：`SFX_drop_into_bucket` 与桶水面波纹；视觉提示“水不再继续接近湿书”，状态 `bucket_catches_drip=true`、`books_protected=true`；Kath：`There. That should keep the books dry.`
- **后续**：桶的位置永久保留，地板旧水圈保留；水滴继续落下，允许反复观看。
- **重要**：不要用一个固定按钮使桶瞬移到正确位置，必须有可观察的位置选择与检验。

### S03-I03 [O/R] 纵向水滴观察模式

- **进入**：在漏点附近 E，打开连续纵向观察视图；初始机位位于铜接缝，可用上下键在 `seam / falling / puddle` 三个焦点平滑移动，Esc 退出。
- **镜头规则**：在同一循环动画上移动视野，不切换到四个互不相关的科普视频；玩家可以随时停留、返回、再次进入。
- **三个焦点内容**：
  - `seam` 顶部：小水珠附在铜边微颤，逐渐变大后脱离。
  - `falling` 中部：离开铜边后落速逐渐增大，轨迹大致竖直（在书库无明显侧风的条件下）。
  - `puddle` 底部：撞击的细小飞溅向外/向上，随后重新向下落回。
- **发现判定**：玩家焦点在对应区域并经历了至少一次可辨识的关键动作时置 `observation_seen.*=true`；不必观看固定秒数的教学片段。若动画正在中途，可在当前焦点等待循环。
- **问题出现方式**：只有在看见相应现象后，笔记边缘才渐显对应问号；首次可触发 Kath 短疑问，之后不再自动重复。
- **离开**：Esc 关闭不清除观察发现记录。

### S03-I04 [O/R] 铜边：为什么先悬着？

- **操作**：观察视图保持在 `seam`；观看一滴由小到大且暂时附着在铜边的水珠。
- **触发**：见到“仍附着”与“随后脱离”两个关键动作后标记 `seam=true`；笔记边缘浮现 `Why does it wait?`。
- **对白 D13**：`Why is it still hanging there?`
- **动画**：小水珠拉长/轻颤而非突然没有重力；分离时原接缝处留少量水迹。

### S03-I05 [O/R] 下落：为什么越落越快？

- **操作**：切到 `falling`，观看水滴开始与接近桶面的移动；中部按 Enter 可**短暂叠加同一水滴等时间间隔的三个位置**。
- **触发**：看见三位置或完整可辨的下落后标记 `speed=true`；笔记边缘浮现 `Why does it speed up?`。
- **对白 D14**：`It seems faster near the floor. Why?`
- **叠图**：淡色轮廓/冻结三帧，位置间距从上到下逐渐变大；显示 2–3 秒后可手动重开，不出现秒表、公式与坐标轴。
- **技术要点**：等时间间隔，不是等距离间隔；不能错误地画成匀速。

### S03-I06 [O/R] 轨迹：为什么近似朝下？

- **操作**：在中部查看铜边倾角和下落轨迹，或者先用水桶预测落点再回看；视觉叠加可选纤细轨迹描线，不画“重力箭头答案”。
- **触发**：看到倾斜屋檐与近似竖直下落形成对比时 `direction=true`，笔记边缘浮现 `Why down?`。
- **对白 D15**：`The roof is slanted, but the drop falls almost straight down.`
- **技术要点**：在无明显侧风情境用“近似竖直”，不是完美几何直线；不是证明所有物体在任何条件下都绝对垂直落下。

### S03-I07 [O/R] 撞水：为什么飞溅向上？

- **操作**：切到 `puddle`，查看落点、水面小波纹、向上与向外飞起的微水珠及随后落回的过程；接水后桶内积水提供同样观察机会。
- **触发**：撞击与飞溅可见时 `splash=true`，笔记边缘出现 `Why does it splash up?`。
- **对白 D16**：`It fell down. What sent those little drops up?`
- **技术要点**：细水珠上飞是碰撞导致的水流运动，重力没有改方向；游戏只呈现现象，不在本章解释机制。

### S03-I08 [O/R] 梯上轻碰一颗小水珠（可选试探）

- **前置**：梯子可以移动到屋顶接缝检修点，且梯轮已锁；**不要求**先完成草图。
- **玩家动作**：推动梯子到接缝附近 → E 锁轮 → 爬上 → 选修补工具 → 在水珠尚小时按 E 轻碰一次。
- **反馈**：该滴水比自然形成的水珠更早脱离；玩家仍可看它向下落、撞水；等待一滴正常水珠作比较。
- **对白 D17（一次）**：`That one fell sooner.`
- **状态**：`touched_small_drop=true`，可选，**不能**成为发现木盒的必需条件；此操作不永久修复漏水、不破坏循环。
- **安全**：梯子只有在锁轮状态下允许攀爬；错误交互只提示 `Lock the wheels first.`，不做坠落惩罚。

## S03.C 第一次真正的主动停留（剧情节拍）

**触发建议**：第一次桶接住水并确认书籍安全后，若玩家试图离开，水滴仍持续；可以用一声更清晰的 `plink` 和 Kath 0.5 秒回头动画提示继续观察，但**不要强制锁定出口或播放“必须探索”的哲学台词**。

**D18 主动性台词的触发**：玩家在 `books_protected=true` 后，**自己重新进入**水滴观察视图/再次检查已被接住的水滴。只播放一次：

> Kath: `Wait... I want to see that again.`

这句应发生在玩家做出探索行为之后，而不是在任务完成的瞬间自动宣告。其叙事功能是将玩家的自发探索与 Kath 的内心变化同步。

## S03.D 书桌与四格观察笔记

### S03-I09 [M/R] 打开干燥书桌的观察页

- **前置**：`books_protected=true`。
- **玩家动作**：靠近干燥书桌 E；打开一页可操作的四格笔记。若暂未观察四种现象，仍可进入并在旁边看到未形成问题的空格，可随时返回漏点；该格在未观察相应现象前不可登记为完成，但这不锁住玩家离开、返看或修改已完成的格。
- **UI**：标题 `Observations — Rainy Evening`，四格标签固定为：
  1. `At the seam`
  2. `In the air`
  3. `Toward the floor`
  4. `At the water`
- **玩法简化**：玩家拖动有限数量墨点、短线及小曲线；键盘支持方向键移动笔尖 + E 放置/确认，Esc 撤销当前对象。每格保存当前图元与已改动痕迹；不要求自由画布与笔迹识别。
- **反馈**：选格时可出现 `Back to observation` 以重开水滴视图；已看到相应现象时显示对应问句，未看过时显示淡淡 `Look more closely`（不是答案）。

### S03-I10 [M] 四格草图逐格操作（次序自由）

| 格 | 玩家动手做的事 | 可接受的完成判定 | Kath 手写问题（完成对应格后出现） |
|---|---|---|---|
| `At the seam` | 放一小一大两颗仍与铜边接触的水珠，最后一颗脱离 | 至少完成附着 → 变大 → 脱离的结构化三步记录 | `Why did it wait before falling?` |
| `In the air` | 排列同一水滴等间隔观察到的三个位置，间隔由小到大 | 三个位置有明确先后，允许宽松位置误差；不要求毫米级准确 | `Why did it move farther each time?` |
| `Toward the floor` | 画一条脱离接缝后大致朝向地面的轨迹 | 连接起点与落点，方向大致向下即可 | `Why does it fall downward here?` |
| `At the water` | 放撞击位置、向外向上的短线/水点，另有回落点 | 明确画出至少一次向上飞溅与落回 | `What made the splash rise?` |

- **主线观察条件**：每格在 `observation_seen` 对应条目为 true 后，玩家才可将该格标记为完成；如果尚未观察，显示“回去看一眼”的柔和提示，而非替玩家填写。四格完成顺序仍自由。
- **重要**：此表的“判定”仅是交互完成验证。不能展示自动填好的图，也不能把玩家草图与物理理论标准答案进行分数比较。
- **修改**：任意格允许重新编辑，第一次错误笔划保留为低透明度淡墨痕（可选开关）；误按 Esc 不清除整页。
- **完成**：四格均保存非空有效记录后 `notebook_cells_done=[true,true,true,true]`，在笔记页旁浮现四个问号；Kath D19：`I can draw what happened. I still need to find out why.`
- **情绪**：Kath 在这一刻不应该突然宣布自己是科学家；镜头可停在纸面和她握笔的手上 1 秒，音乐首次出现很轻的明亮音色。

### S03-I11 [O/R] 圈选最想继续探索的问题

- **前置**：可在四格完成后出现；后续可以重新选择。
- **玩家动作**：点击或用方向键选择四个问题之一，圈上铅笔圆圈。
- **状态**：`favorite_question=0..3`；不选择保持 null。这个值可在第一章用作一句优先回忆对白，但**不影响本序章谜题和后续的主线解法**。
- **反馈**：所选圆圈有笔迹演出，其他问题仍在；禁止把它包装成“唯一正确的问题”。

## S03.E 从笔记到旧木盒的叙事过渡

### S03-I12 [M/C] Wick 发现高处夹缝

- **前置**：四格草图完成；桶已接住水。
- **演出**：Kath 暂时合上新笔记。Wick 从她身边飞离，在高书架的窄缝前停住，翅膀柔光扫过书脊；可重复触发轻提示，但“第一次发现”镜头不重播。
- **对白**：Kath `What is it, Wick?`（新增可选，语气短；Wick 无语言回复。）
- **状态**：书架夹缝热点可交互；若玩家之前就看见木盒的书架位置，最多描述 `There's something behind the books.`，不在主要观察完成前提前拿到残页。

### S03-I13 [M/R] 移梯、锁轮、攀爬

- **玩家动作**：E 抓梯子 → 移动至书架标记区 → E 放置 → E/点击锁定两个轮子 → E 攀爬。
- **反馈**：轮子锁定时 `click`，小图标从未锁转为锁；角色安全攀至书架上方，不能未锁强攀。
- **防卡**：如果此前用梯子做 S03-I08，可再次推回书架；重返场景梯位和轮锁状态保持。
- **对白**：未锁时 `Better lock the wheels first.`

### S03-I14 [M] 发现没有登记编号的木盒

- **玩家动作**：在高架夹缝按 E 推开两本书，看到薄木盒，E 取出并打开。
- **视觉**：木盒朴素、薄、旧；盒盖内衬能解释纸张避开漏水与后期目录整理。不能把盒子画成明显魔法物品。
- **状态**：`wooden_box_found=true`。
- **SFX**：木盒拉出/盒盖轻启/纸张摩擦。

### S03-I15 [M/R] 查看并收起旧残页

- **近景重点**：中央 `F = ma`，旁边是**不完整**的城堡检修吊篮草图，辨认得到篮框、一小段绳、模糊轮缘；不可给出完整绕绳和救援答案。页上有装订孔、擦改痕及 Kath 签名。
- **纸面英文（按上传稿保留）**：
  - `The first mark was wrong.`
  - `Don't erase it. Write down the second result too.`
  - `Next time at the castle, try again.`
  - `Kath`
- **首次对白 D20**：`I wrote this. I know I did.`
- **短停顿 D21**：`Why would I keep a wrong mark?`
- **可选看新笔记 D22**：`I drew what I saw tonight. The questions can stay beside it.`
- **玩家动作**：Enter 收起并正式取得残页；Esc 退出时**纸仍留在盒中**，可重新打开，不应误设为“已拾取”。
- **状态**：Enter 后 `old_page_collected=true`，存档；开启通往 Kath 房间的左侧门。
- **Wick**：光扫过 `Kath` 签名停住 0.5 秒，不提示公式含义。

### S03-I16 [M] 前往 Kath 房间

- **前置**：`old_page_collected=true`。
- **玩家动作**：下梯后向书库左侧门移动，E 开门；允许之后返回书库或大厅。
- **对白**：如未收起残页却想走，提示 `I should take another look at that page.`（只提示主线，不自动把纸装包）。
- **转场**：书库雨声变远，房间暖光，进入 S04。

## S03.F 水滴物理动画：精确表现要求（制作约束）

1. **附着阶段**：重力始终作用；水滴在铜边附着时同时受接触处的表面张力/附着作用等影响，不能画成“水滴完全不受向下作用”。
2. **脱离与下落**：生成同一颗水滴的连续运动；近距离可作近似下落加速；视角静风条件轨迹近似竖直。
3. **等间隔三帧**：上下间距逐渐增大，不要用不同大小的水滴替代同一滴的不同位置。
4. **碰撞**：落水使局部液体向外、向上运动，形成细小飞溅；飞出的水珠随即下落。不要把“向上溅”解释为重力翻转。
5. **循环**：一滴完整周期约 2–4 秒作为**原型调参起点**，实际按可观察性调整；底部飞溅约 0.3–0.6 秒；三帧叠图 2–3 秒。以上时长均为本版开发建议，不是源文件规定。
6. **低成本方案**：帧动画/预设曲线驱动即可，不需要真实 Navier–Stokes 流体模拟或新增加速度计。

## S03.G 提示层级、音画素材与验收

**H 提示层级：**

1. 未处理书籍：`The water is getting close to the books.` 指向桶/漏点。
2. 桶放偏：`Watch where the next drop actually lands.` 指向落点而非给出“正确坐标”。
3. 观察不完整：`There may be more to notice near the seam / in the air / at the water.` 指向未查看区域。
4. 草图不完整：`The desk might help Kath keep a record.` 指向书桌，**不自动填写线条**。
5. 草图完成后：Wick 光照高处夹缝；随后才提示移动梯子、锁轮。

**媒体资产**：

| ID | 素材 | 要求 |
|---|---|---|
| A12 | 重复水滴主循环 | 附着、变大、脱离、加速、落水、飞溅、回落 |
| A13 | 三焦点视图/镜头平移 | 允许玩家手动上下查看，无强制播片 |
| A14 | 等间隔三位置叠图 | 由同一轨迹采样，显示后消失可重看 |
| A15 | 桶推移与水滴命中判定 | 放偏/接住不同水声与波纹；记录位置 |
| A16 | 梯子移动/锁轮/攀爬 | 可复用原有动作，锁轮是安全门槛 |
| A17 | 书桌四格笔记 UI | 拖点、放线、撤销、返回观察、保存痕迹 |
| A18 | Wick 书架提示 | 不说话、光点不标答案 |
| A19 | 薄木盒/旧纸特写 | 公式、残缺吊篮草图、签名、折痕 |
| A20 | 雨夜氛围 | 金属雨声、滴水、桶内回音、潮湿书库环境 |

**验收**：

- [ ] 先观察再接桶、先接桶再观察都可推进。
- [ ] 放偏的桶能再次调整；错误结果可被玩家真正看到。
- [ ] 三焦点均可反复进入，四现象容易辨认，字幕不抢先给答案。
- [ ] 三帧水滴时间间隔相等，移动间距逐渐变大。
- [ ] 四格草图均为玩家参与记录，允许修订并保存原始淡墨痕。
- [ ] 圈一个问题可选，不影响进度。
- [ ] 轻碰水滴可选，不触发“已修复漏水”，不影响木盒解锁。
- [ ] 木盒图纸刻意不完整；Esc 退出不算已取得，Enter 才正式拾取。
- [ ] Wick 始终无对白，关键互动不能因没有看 Wick 的某个动画而错过。

---

# S04. Kath 的房间｜过去的我与现在的我

**时间：** 雨夜 → 次日清晨。 **核心心理转折：** 确认遗失的过去，但不依赖恢复记忆来获得新的行动意愿。  
**主线：** 开灯 → 残页与本子对齐 → 比对新旧记录 → 休息 → 装包。

## S04.A 场景环境

- 温暖但略显凌乱的小房间：旧书桌、台灯、缝线、磨钝铅笔、半整理笔记、床、窗、挂着的外套、工具包。
- 窗外仍是夜雨；室内比书库安静，音乐减到极简，留下呼吸、翻纸与雨声。
- 不出现梦境、神秘人声或“科学知识复苏”的闪回。

## S04.B 逐交互详情

### S04-I01 [M] 打开台灯

- **玩家动作**：靠近书桌 E 开灯。
- **反馈**：桌面亮起，露出装订本、笔迹与小修补工具，暗处仍有背景余光。
- **SFX**：机械灯开关、轻灯丝噪音（可选）。
- **状态**：`lamp_on=true`。
- **叙事目的**：空间从“急于处理漏水”过渡到“仔细审视记录”。

### S04-I02 [M/R] 残页与原装订本对齐

- **前置**：灯已亮且持有残页。
- **玩家动作**：E 打开桌面近景；鼠标拖动残页或左右方向键微移，使撕裂边、孔距与纸页纹理大致吻合；Enter 确认，Esc 可退出重新做。
- **反馈**：对齐后两张纸边缘契合，装订孔成一线；判定宽松，避免高精度拼图；系统提示 `The torn edges fit.`，但不直接说出科学解释。
- **状态**：`page_match_confirmed=true`；保存；之后再次打开只展示已经对齐的状态，不重玩首次确认动画。
- **对白 D23**：`The torn edge fits. I took this page out of my own notebook.`
- **限制**：这只能证明笔记原属 Kath，不代表恢复与城堡相关的完整记忆。

### S04-I03 [M/C] 查看旧行程索引

- **前置**：开灯；可在对齐前先看，主线确认最好待对齐后。
- **玩家动作**：翻到 `Observatory Castle` 旧索引页；查看数次旧行程，其中某条日期与残页 `Next time at the castle...` 相邻。
- **反馈**：原有文字可读，但若干项目残缺；玩家知道 Kath 曾与城堡工作相关，不知道当时实验具体是什么。
- **对白 D24**：`I was due back at the castle. I don't remember what I meant to check.`
- **状态**：可记录 `room.castle_index_seen`，但若不希望额外门槛，也可合并入 I02 成功后的自动可查看补充。

### S04-I04 [M/R] 新旧笔记并排比较

- **前置**：`page_match_confirmed=true`，四格水滴草图已存在。
- **玩家动作**：点击左侧旧残页的 `The first mark was wrong.`，再点右侧新水滴草图的淡墨修改痕；或以鼠标滑动让两页并排展开。此互动可以非常轻，不是另一道复杂解谜。
- **视觉**：旧错误记号未擦掉，新页草图首次移动/修改痕迹也仍在；两页用相同的纸纹与孔距暗示同一本本子。
- **短对白（新增情绪细节）**：`I made a mistake here, too.` → `You didn't erase yours.` → `Neither will I.`
- **状态**：`room.notes_compared=true`；若为降低任务门槛，可随 I02 自动执行，不独立阻挡睡觉。
- **叙事目的**：现在的行动与过去形成呼应；重点不是“我是过去那个人”，而是“我今天也愿意重新观察和修正”。

### S04-I05 [O/R] 外套上的修补袖口

- **玩家动作**：E 查看；特写磨损/修补针线。
- **对白**：`I've repaired this before.`
- **目的**：角色过去的实践痕迹，不推导事故成因。

### S04-I06 [O/R] 工具包里的铅垂与量尺

- **玩家动作**：E 打开工具包，看见不常使用的铅垂与量尺；可对其名称模糊而不描述精确原理。
- **对白**：`I kept these, though I hardly use them.`
- **限制**：不得提前通过工具解释重力、加速度或第一章的救援方法。

### S04-I07 [M] 留下笔记，选择休息

- **前置**：`page_match_confirmed=true`，已看见旧记录与新观察页（I04 可为伴随镜头，不要强制二次复杂操作）。
- **玩家动作**：E 整理桌上纸页后走到床边 E 休息；弹出简短 `Rest until morning?` / Yes-No。
- **对白 D25**：`I'll leave these notes here. Tomorrow I may notice something I missed.`
- **演出**：关灯、轻淡出、雨声渐弱，灰蓝晨光渐强；**不出现梦境或超自然闪回**。
- **状态**：`slept=true`，`time_phase=next_morning`，`rain_stage=stopped`。

### S04-I08 [M] 清晨装包

- **前置**：休息后。
- **玩家动作**：E 触碰书桌，将旧残页与四格笔记放进背包（推荐只用一次打包动画）；如尝试离开而未装包，Kath：`My notes. I should take them.`
- **反馈**：桌上纸页叠起，进入背包图标，实际数据仍留在存档可查看；`bag_packed=true`。
- **转场**：玩家出门后进入晨间大厅 S05；不要自动直接切事故，以保留 1–2 秒“熟悉大厅的正常钟声”。

## S04.C 台词与媒体

- **核心旧台词必须保留**：`The torn edge fits. I took this page out of my own notebook.` / `I was due back at the castle. I don't remember what I meant to check.` / `I'll leave these notes here. Tomorrow I may notice something I missed.`
- **情绪节奏**：比对时不配巨大揭秘音乐；可只加入一两声细弱的钢琴/木琴单音，强调认识而不是震惊。
- **素材**：A21 台灯/晨光二态；A22 可拖动残页与撕边对齐界面；A23 新旧笔记双页；A24 外套/铅垂/量尺特写；A25 夜至晨渐变；A26 装包动作。

## S04.D 验收

- [ ] 正常纸页对齐确认依赖玩家 Enter，不是拾取后自动确认。
- [ ] Esc 可退出并重试；失败无惩罚。
- [ ] 玩家看到旧行程与 Castle 关系，但不会自动解码 `F = ma`。
- [ ] 不出现记忆恢复特效、神秘幻觉或章节一的救援答案。
- [ ] 清晨未装包不能静默丢笔记；装包后不会重复拿到同一残页。

---
# S05. 清晨大厅与机械室｜理解必须承担后果

**时间：** 次日清晨。 **核心心理转折：** 昨晚留下的观察记录在真实事故中产生价值；Kath 不再把“完成步骤”误认为“问题已经消失”。  
**地图复用：** `Hall.tscn` + `MachineRoom.tscn`，原物件与保存状态沿用，不重复播放 S01/S02 的首次互动。

## S05.A 清晨大厅的复访

### S05-I01 [M] 从房间回大厅 / 警报首次响起

- **前置**：`room.slept && room.bag_packed`。
- **镜头**：灰蓝晨光，大厅钟**仍正常走动**；昨夜门窗闭合与钥匙归位状态可见，说明整栋建筑没有瞬间失去动力。
- **声音**：晨间滴答与室外雨后水滴；0.5–1 秒平静后机械室方向响起尖锐警报。**先播放声音，再出现角色对白**。
- **视觉**：高窗远处城堡方向的信号灯断续闪烁；玩家不必立刻看见城堡倾斜。
- **对白 D26**：`That alarm is from the machine room. The needle was below red last night.`
- **对白 D27**：`I have a mark to compare it with.`
- **状态**：`machine.alarm_seen=true`，重新开启机械室通路。
- **限制**：不能由 Kath 一眼断言“昨晚的雨导致机械故障”。雨、漏水和城堡倾斜是否同源，仍没有证据。

### S05-I02 [O/R] 再次查看大厅的钟与空白清单

- **玩家动作**：查看正常走动的钟；可查看昨晚归档页和今天仍未开始的空白页。
- **反馈**：`The clock is still running.`，不重置三项巡查、不要求再做一轮；警报是当前优先事件。
- **叙事**：与开场“按清单维护日常”的节奏形成对照，这次Kath主动去核查真实问题。

### S05-I03 [M] 进入机械室

- **玩家动作**：向警报方向走并 E 开门；提示 `The alarm is downstairs.` 只在迷路时出现。
- **转场**：在进门时将低频机器声、尖锐警报与警示红光逐渐放大。

## S05.B 机械室异常与应急响应

### S05-I04 [M] 查看越过红线的主仪表

- **玩家动作**：靠近仪表 E 近景；将昨夜亲手画下的基线与当前指针比较。
- **视觉**：昨夜铅笔痕仍在，当前指针**明显越过红线**，可直接辨认。不能在这一步把旧记录清除。
- **对白 D28**：`It was below the red line yesterday.` / `Now it's over.`（可保留一条，避免同义台词堆叠。）
- **状态**：`machine.alarm_gauge_compared=true`，但不得因未确认对白而卡住安全操作。

### S05-I05 [M/R] 阅读红签应急牌

- **玩家动作**：E 查看应急牌。UI 高亮编号 `2`、`4` 和 `LOCAL STOP`，并标明上层升降机警示程序。
- **规则**：这张应急牌从 S01 起已有视觉铺垫，S05 只是在真实情境下用于指导操作；避免“临时生成的神秘答案”。
- **信息量**：显示可以执行的**安全步骤**，不展示机器完整科学原理，也不显示城堡内部控制方法。
- **状态**：`emergency_card_seen=true`（可选进度记录）；若玩家直接按正确装置，仍然接受操作，不强制先看卡。

### S05-I06 [M/C] 处理二号与四号手柄

- **玩家动作**：分别走到 2、4 号手柄，E 拉下/移至安全位置；允许顺序 `2 → 4` 或 `4 → 2`。
- **前置**：进入警报状态；其他手柄 1、3 保持仅查看/明确无主线操作，不会因误触造成永久失效。
- **反馈**：每拉一个手柄有 `clunk`、小范围机械震动；两柄都处理后，仪表短暂回落，继而出现再次偏转的趋势。视觉应让玩家确实看到“短暂有效，但没有完全解决问题”。
- **状态**：`lever_2_done=true`、`lever_4_done=true`；各自不可重复拉造成无限刷动画。
- **对白 D29**：`Two and four. The needle fell... and now it's climbing again.` 仅当玩家确实目睹回落与再次偏转后播放。
- **分支 B（先停机）**：若 `local_drive_stopped=true`，玩家仍可将 2、4 号手柄置于安全位置以卸除剩余负载。仪表呈现剩余趋势/短暂惯性回落，不可表现成停机后电机自行重新启动；结束后维持本地停机的安全状态。

### S05-I07 [M/C] 本地停机按钮

- **玩家动作**：E 近景显示 `LOCAL STOP`，按下/长按确认（避免误触）；允许在拉手柄之前或之后操作。
- **反馈**：本地机械驱动声音逐渐减弱、指示灯变更、部分装置停止；城堡方向的远程警示依旧存在。
- **状态**：`local_drive_stopped=true`；为不可逆的本地安全状态，不在后续自动开启。
- **对白 D30**：`The Archive drive is stopped.`
- **边界**：这只是万象馆本地辅助线路，不等于把远处城堡的环形驱动和制动系统关闭。

### S05-I08 [M] 发出上层升降机警示

- **前置**：进入警报状态，建议本地驱动已停或至少两手柄已安全（按工程安全流程确定；不应拖延直接停机）。
- **玩家动作**：E 操作墙上的警示开关或公告终端，选择/确认 `Do not use upper lift`。
- **反馈**：小型警示灯、终端记录回执或挂上红色禁用牌；不制造新的复杂通信谜题。
- **状态**：`upper_lift_warning_sent=true`；可检查已发布的警示内容。
- **对白 D31**：`The upper lift must stay out of use.`

### S05-I09 [M/C] 完成应急安全状态判定

- **完成条件**：`lever_2_done && lever_4_done && local_drive_stopped && upper_lift_warning_sent`，顺序不限。
- **视觉状态**：当地驱动已关闭、指针最后处于对应安全/余量状态、警报等级从紧急持续尖鸣转为可辨识的余警提示；**不要把红线越界效果直接归零来假装事故完全解决**。
- **Kath 认识**：执行了应急步骤，但不知道导致异常的根本原因。

## S05.C 观测远方城堡（只出现一次的悬念演出）

### S05-I10 [M] 高窗/远程观测装置查看城堡

- **前置**：应急安全状态已完成；城堡信号依旧异常。
- **玩家动作**：E 使用远程观测装置，镜头对焦城堡的固定塔楼与支承环中的建筑翼。
- **演出**：固定塔楼保持竖直，建筑翼在**约 3 秒内顺时针偏转至约 12°**，然后停住；缆线顺应位置变化，远方灯光断断续续。
- **关键限制**：序章绝不出现城堡 180° 倒悬；这一视觉变化只触发一次。再看仍然显示 12° 倾斜的最终状态，不重播整段偏转。
- **状态**：`castle_tilt_cutscene_seen=true`；如玩家之前通过高窗看见信号灯，不能误触完整倾斜演出。
- **对白 D32**：`The fixed tower is still upright... but the wing isn't.` 或保持沉默，留给 S06 实地复述。
- **镜头切换**：至少让玩家明确辨别“固定塔楼”和“会偏转的建筑翼”，不使用整座城堡倾覆的错误剪影。

### S05-I11 [M] 事故记录

- **玩家动作**：E 打开事故笔记页，将昨晚基线、今日红线越界、2/4 手柄回落后的变化、本地停机、上层升降机警示，以及远处城堡倾斜写成几条可核查的记录。低成本实现可用已观察到的事实卡片由玩家按发生顺序放入笔记，不需要写长篇文字。
- **基本必需事实**：①昨夜正常基线，②今日异常，③采取过哪些安全措施，④远处倾斜但原因未知。
- **反馈**：`Incident Notes Saved`，笔记可重看，不允许通过笔记猜测雨水与城堡异常的因果关系。
- **对白 D33（沿用原稿）**：`I'll record what I saw. Someone at the castle may know what to check there.`
- **状态**：`alarm_record_saved=true`，右侧维修路出口开启。
- **建议**：不要把这里做成正式评估题；玩家刚刚亲自执行过动作，记录只需确保现象与时间顺序清楚。

### S05-I12 [M] 离开机房前往维修路

- **前置**：`alarm_record_saved=true`。
- **玩家动作**：右侧出口 E 进入 S06；返回或重进机房时保持手柄、本地停机、仪表、事故笔记与城堡最终倾斜状态。
- **提示**：未完成安全措施时只显示对应物件的方向信息，不自动按下任何按钮。

## S05.D 两种安全顺序与状态一致性

**路径 A：先卸载后停机**

`查看仪表 → 操作 2/4 → 看指针回落后又偏转 → 本地停机 → 警示 → 远望 → 记录 → 出口`

**路径 B：先停机再处理剩余负载**

`查看仪表 → 本地停机 → 安全处理 2/4 → 看剩余读数/余量变化（无重新启动）→ 警示 → 远望 → 记录 → 出口`

- 两条路径均必须显示措施与结果之间的联系，不能把路径 B 错误归到失败。
- 如果已有 Godot 物理/动画系统不支持停机后的指针余量变化，可将“回落后反弹”的可辨认趋势限定在停机前操作；停机优先路径则通过残余指针偏差/远程警报展示问题未解决，**不要**制造违反逻辑的强制回弹。此处应由现有工程的仪表表现确定最终实现，属于待测试的开发细化。

## S05.E 媒体与验收

| ID | 素材 | 要求 |
|---|---|---|
| A27 | 清晨大厅复用状态 | 钟正常、门窗已关、空白清单仍在 |
| A28 | 警报灯/警报音 | 声音先于对白，分紧急和余警两个层级 |
| A29 | 红线越界仪表 | 昨日基线和今日指针同屏，清楚可读 |
| A30 | 手柄 2/4 / LOCAL STOP | 独立状态、响应音、不可反复刷成功 |
| A31 | 上层升降机警示 | 简明、可复查、不另造通信系统 |
| A32 | 观测城堡偏转 0°→12° | 三秒左右，一次性，固定塔楼始终直立 |
| A33 | 事故笔记 | 由观察事实形成，保存后可再次查看 |

- [ ] 警报声音先播放，Kath 再判断发生位置。
- [ ] S02 留下的玩家基线仍显示在 S05 仪表上。
- [ ] 两种操作顺序都可到达安全完成状态，且不产生设备“自动重启”的逻辑错误。
- [ ] 已停机不误表示城堡驱动也已停；远程故障仍然存在。
- [ ] 整座城堡不在序章翻到 180°，只有建筑翼偏 12°。
- [ ] 重返机房不重复偏转镜头，不清除事故状态。

---

# S06. 维修路｜我可以从眼前所见开始

**时间：** 雨后清晨。 **核心心理转折：** Kath 带着不确定性前往现场，因为她选择继续观察、确认，并尽力帮助他人。  
**目标：** 实地确认倾斜、记录有限证据、打开维修闸门，完成序章交接。

## S06.A 场景全景

- 湿润石路、局部小积水、薄雾；雨已停但屋檐仍可能滴水（不再触发新一轮必做水滴教学）。
- 远景固定塔楼竖直，支承环建筑翼约 12° 倾斜；数条缆线朝路面方向下垂，远方信号灯仍不稳定。
- 音效：风、湿路脚步、细水滴、偶尔远方金属轻响；此前急促警报降低，情绪转为谨慎且坚定。
- Wick 在可观察的缆线旁环绕一圈，望向城堡；不把它当成一位会解释科学的导师。

## S06.B 逐交互详情

### S06-I01 [O/R] 查看维修路牌

- **玩家动作**：靠近旧路牌 E。
- **显示**：指向 `Observatory Castle — Maintenance Entrance` 的路线方向；材质旧但可读。
- **对白**：`The maintenance entrance is this way.`
- **状态**：不影响闸门主线，只提供空间定位，避免玩家迷路。

### S06-I02 [O/R] 观察缆线下垂

- **玩家动作**：靠近能观察缆线的位置 E，拉近 0.5–1 秒。
- **视觉**：缆线自然受力而下垂，不能像受无形魔法抬起；不直接出现受力箭头与解释。
- **反馈**：可向笔记追加 `The cable hangs toward the road.`；`road.cable_noted=true`。
- **对白候选**：`It hangs toward the road.`

### S06-I03 [O/R] 观察固定塔楼与倾斜建筑翼

- **玩家动作**：站在可辨认两者的观察点，E 调查。
- **视觉**：镜头同时显示直立塔楼和倾斜建筑翼，避免切出错误的整体倾斜印象。
- **对白 D34（按原稿）**：`The fixed tower is upright. The wing isn't.`
- **状态**：`road.wing_noted=true`；可向笔记追加对照记录。

### S06-I04 [O/R] 将两项观察并列记入笔记

- **前置**：至少查看过其中一项；全看后可以并列显示。
- **玩家动作**：N 打开笔记；选择 `Cable` / `Wing` 两条事实作为相邻记录；与水滴旧草图可在同一本里翻看。
- **反馈**：Kath 不把两条事实等同于“事故原因”，只留下观察。
- **对白 D35（原稿）**：`One hanging cable tells me where it falls here. I still need to see what happened inside.`
- **状态**：记录可选，不成为进入城堡强制条件。

### S06-I05 [M] 打开维修闸门

- **前置**：S05 事故记录已完成、进入维修路；此处可让玩家直接开门，不必强制查完路牌、缆线和建筑。
- **玩家动作**：靠近闸门 E → 门锁/把手互动 → 闸门开启；如果道具设计需要钥匙，必须使用**已明确存在且合理随身携带的维修许可/通行机制**，不能临时规定大厅那把已归位的东侧值班钥匙被 Kath 偷带出来。
- **动画**：Kath 手握门把短暂停顿，门沿轨道/铰链缓缓打开，Wick 先飞过，晨光与空气声进入。
- **对白 D36（沿用原稿结尾）**：`I came for an answer. I'll start with what I can check.`
- **状态**：`gate_open=true`，存档。
- **叙事解释**：这不是“她已经找到人生使命”，而是“她愿意在不知道答案时，开始自行判断与行动”。

### S06-I06 [M] 章节交接

- **玩家动作**：沿维修路走到尽头；显示 `Prologue Complete` / `Chapter I — Upside-Down Castle`。Enter 前往下一章城堡控制廊；Esc 返回维修路。
- **边界**：序章只做章节交接，不写第一章 Erin 的救援、低速归位和最终 180° 翻转。开发框架若第一章尚未实现，Enter 可跳转至独立占位页，不能假装已经制作了第一章。
- **状态**：`prologue_complete=true`，玩家可回到序章末端（视现有章节管理规则）。

## S06.C 素材与验收

| ID | 素材 | 要求 |
|---|---|---|
| A34 | 雨后维修路全景 | 湿路、雾、道路方向清楚 |
| A35 | 倾斜城堡远景 | 固定塔楼竖直、建筑翼约 12° |
| A36 | 缆线下垂与灯光不稳 | 物理可信、可重复查看 |
| A37 | 闸门开启/Kath 停顿/Wick 飞入 | 简短、不冗长、可跳过 |
| A38 | 章节标题叠层 | Enter 进入下一章，Esc 返回 |

- [ ] 玩家不看所有可选环境物件也能完成序章。
- [ ] 缆线与建筑翼仅作为线索，不自动推导完整事故原因。
- [ ] 没有把大厅东侧钥匙错误挪用作城堡门钥匙。
- [ ] 章节结束屏标题与行为准确，绝不提前播放第一章事故。

---

# 7. 统一对白清单（可做本地化数据表）

**角色约定：** 唯一主要语言角色为 Kath；Wick 没有台词。**来源标签** `SOURCE` 为上传稿已有台词；`PROPOSED` 为本版新增/细化，需与大厅锁定稿二次核对。播出条件写在场景项中，同一条 `once` 默认只播一次。

| ID | Section | Speaker | English line | 类型 |
|---|---|---|---|---|
| D01 | 01 | Kath | Evening again. The light leaves the hall so quietly. | PROPOSED |
| D02 | 01 | Kath | Three small things to set right before the rain. | PROPOSED |
| D03 | 01 | Kath | That should hold. The wind loves finding little gaps. | PROPOSED |
| D04 | 01 | Kath | The sky is restless tonight. This window can rest. | PROPOSED |
| D05 | 01 | Kath | One more turn, and the old clock keeps its steady song. | PROPOSED |
| D06 | 01 | Kath | Third hook, as always. Even the little clink sounds familiar. | PROPOSED |
| D07 | 01 | Kath | Three small marks, and another evening folded away. | PROPOSED |
| D08 | 02 | Kath | A little higher than yesterday. Still below red. | SOURCE |
| D09 | 02 | Kath | I'll draw where it is, not where I expected it to be. | SOURCE |
| D10 | 02 | Kath | A route to the Observatory Castle. | PROPOSED |
| D11 | 02 | Kath | That sound... is it coming from upstairs? | PROPOSED |
| D12 | 03 | Kath | Oh, no. The books. | PROPOSED |
| D13 | 03 | Kath | Why is it still hanging there? | SOURCE |
| D14 | 03 | Kath | It seems faster near the floor. Why? | SOURCE |
| D15 | 03 | Kath | The roof is slanted, but the drop falls almost straight down. | SOURCE |
| D16 | 03 | Kath | It fell down. What sent those little drops up? | SOURCE |
| D17 | 03 | Kath | That one fell sooner. | PROPOSED |
| D18 | 03 | Kath | Wait... I want to see that again. | PROPOSED |
| D19 | 03 | Kath | I can draw what happened. I still need to find out why. | SOURCE |
| D20 | 03 | Kath | I wrote this. I know I did. | SOURCE |
| D21 | 03 | Kath | Why would I keep a wrong mark? | SOURCE |
| D22 | 03 | Kath | I drew what I saw tonight. The questions can stay beside it. | SOURCE |
| D23 | 04 | Kath | The torn edge fits. I took this page out of my own notebook. | SOURCE |
| D24 | 04 | Kath | I was due back at the castle. I don't remember what I meant to check. | SOURCE |
| D25 | 04 | Kath | I'll leave these notes here. Tomorrow I may notice something I missed. | SOURCE |
| D26 | 05 | Kath | That alarm is from the machine room. The needle was below red last night. | SOURCE |
| D27 | 05 | Kath | I have a mark to compare it with. | SOURCE |
| D28 | 05 | Kath | It was below the red line yesterday. Now it's over. | PROPOSED |
| D29 | 05 | Kath | Two and four. The needle fell... and now it's climbing again. | SOURCE |
| D30 | 05 | Kath | The Archive drive is stopped. | SOURCE (节选) |
| D31 | 05 | Kath | The upper lift must stay out of use. | PROPOSED |
| D32 | 05 | Kath | The fixed tower is still upright... but the wing isn't. | PROPOSED |
| D33 | 05 | Kath | I'll record what I saw. Someone at the castle may know what to check there. | SOURCE |
| D34 | 06 | Kath | The fixed tower is upright. The wing isn't. | SOURCE |
| D35 | 06 | Kath | One hanging cable tells me where it falls here. I still need to see what happened inside. | SOURCE |
| D36 | 06 | Kath | I came for an answer. I'll start with what I can check. | SOURCE |

**推荐的对白播放优先级**：危险/应急 > 主线首次信息 > 角色短情绪 > 可选观察。出现新危险时可以中断低优先级对白。字幕与对白异步完成，不等待声音文件加载才能进行交互。角色不对每个物件重复询问抽象的 `Why?`。

**推荐中英文本管理**：以英文为游戏内默认对白；中文仅作为开发说明和未来本地化译文。将 ID 与音频资源/字幕映射分离，避免写死在场景脚本里。

---

# 8. 导航、提示和容错（开发 AI 必须落实）

## 8.1 全局可进入/可退出原则

- 各场景边界仅使用明确的主线前置状态；已访问场景允许合理回访。
- 所有可交互近景支持 Esc 退出，退出不重置已经成功保存的步骤。
- 当玩家正在推桶、移动梯子、编辑草图时，不允许突然跳场导致状态丢失；先释放抓取状态或自动安全落位。
- **不存在限时漏水任务**：湿书只产生视觉动机，防止仓促处理破坏科学观察。
- 可重复观察水滴或仪表，但首次对白不能每次重放。

## 8.2 提示最小梯度

| 卡住的位置 | H 第一次 | 再次 H | 禁止的提示方式 |
|---|---|---|---|
| 大厅 | 先发现笔记夹页；之后查看任一未勾选项 | 就近未完成物件轻闪 | 强制 01→02→03、自动替玩家关窗/盖章 |
| 机械室基线 | 比较今天与昨天的指针 | 提示用左右键移动铅笔痕 | 自动把标记移到正确点 |
| 书库接水 | 水滴在哪里落下？ | 高亮桶可推动范围 | 一键瞬移正确桶位 |
| 水滴观察 | 尚有某个区域未看 | Wick 光指向观察位置 | 弹“重力/加速度”术语答案 |
| 四格草图 | 选择未完成的一格 | 示范操作方法而非正确图 | 自动填写四格记录 |
| 找木盒 | Wick 望向书架高处 | 提醒移动梯子并锁轮 | 直接传送木盒到手中 |
| 房间比对 | 看笔记撕边与孔 | 提示微移纸页然后 Enter | 自动对齐并确认 |
| 警报 | 查看红签应急牌 | 高亮尚未处理的安全物件 | 无依据建议乱拉所有手柄 |
| 维修路 | 看路牌/朝门走 | 闸门轻高亮 | 强制看完全部可选物件 |

## 8.3 输入与无障碍要求

- 所有拖拽必须提供键盘替代方式；支持自定义按键。
- 字幕与重要仪表不能只靠颜色区分。红线越界需同时有刻度/位置/警报文字。
- 物件可交互范围要宽松；水桶接水判定和草图判定可以在调试工具中调节。
- 闪烁警示灯强度可降低；快速镜头移动和雨声/警报音量可调。
- 重看对话日志、笔记与事实记录，不把关键科学现象只播一次。
- 自动存档后提示小图标即可，避免截断情绪节奏。

---

# 9. Godot 推荐事件结构与数据接口

> 以下为引擎无关的实现说明和示意伪代码，**不是声称当前工程已经有这些类**。开发前必须先读取现有 Godot 节点、脚本、信号和存档格式，以增量修改为原则。

## 9.1 推荐模块职责

| 模块（示例名） | 责任 |
|---|---|
| `PrologueState` | 全局进度与载入保存；不持有动画运行时帧 |
| `Interactable` 基类/组件 | 热点范围、E 提示、执行与交互已完成态 |
| `SceneTransition` | 读取前置条件、场景切换、角色出生位置 |
| `DialogueDirector` | 根据 ID 只播一次、字幕队列与可中断优先级 |
| `JournalUI` | 清单、基线、四格草图、事故记录、旧残页 |
| `RainDropLoop` | 可重复水滴动画与落点/飞溅事件信号 |
| `DripObservationView` | 三个观察焦点、三帧位置叠图、发现状态 |
| `MovableBucket` | 桶拖移、范围限制、与水滴落点判定 |
| `LadderInteractable` | 推动、锁轮、攀爬、安全状态 |
| `MachineEmergencyController` | 2/4 手柄、停机、警示、安全完成条件 |
| `AudioDirector` | 雨、滴水、机械声、警报音的状态切换 |

## 9.2 建议事件总线（示意）

```gdscript
# events/signals, names are illustrative
signal task_completed(task_id)
signal observation_made(observation_id)
signal notebook_cell_saved(index)
signal interactable_state_changed(id, value)
signal scene_gate_unlocked(gate_id)
signal dialogue_requested(dialogue_id, priority)
signal prologue_finished()

func on_all_hall_tasks_complete():
    # 不自动归档；只让印章可用
    stamp_interactable.enabled = true

func on_round_filed():
    PrologueState.hall_round_filed = true
    archive_today_sheet()
    clear_current_round_sheet()
    machine_room_entrance.enabled = true
    save_game()

func on_water_drop_landed(hit_bucket: bool):
    if hit_bucket:
        PrologueState.bucket_catches_drip = true
        PrologueState.books_protected = true
        play_bucket_splash()
    else:
        add_floor_ripple()
    # 无论如何继续循环，不自动给出物理解释

func on_four_cells_saved():
    if PrologueState.notebook_cells_done.all(func(x): return x):
        enable_high_shelf_discovery()
        request_wick_fly_to_shelf()
        save_game()

func emergency_safe() -> bool:
    return (PrologueState.lever_2_done
        and PrologueState.lever_4_done
        and PrologueState.local_drive_stopped
        and PrologueState.upper_lift_warning_sent)
```

上述示意中的 `on_four_cells_saved` 应采用事件触发而不是每帧反复通知；避免 Wick 动画重复抢控制权。

## 9.3 每个互动对象的可序列化字段

```yaml
id: S03-I02
scene: TopLibrary
interaction_type: movable_object
required: true
preconditions: []
input: [E, move_left, move_right, E_release]
feedback:
  success: bucket_hit_animation
  retryable: true
persist:
  - library.bucket_position
  - library.bucket_catches_drip
postconditions:
  - library.books_protected
hints:
  - Watch where the next drop lands.
```

可以按这个模板把各交互写成 `.tres` Resource、JSON 或 YAML 再导入 Godot；但本稿的正式权威内容仍是各 Section 对应的 `Sxx-Iyy` 文字规则。不要用数据格式限制叙事细节。

## 9.4 最容易出现的状态依赖错误

1. **把“任务条件满足”当作“角色主动确认”**：大厅必须先展开笔记夹页、任意顺序完成巡查，并由玩家手动盖章；旧纸必须 Enter 取得；房间对齐必须 Enter 确认。
2. **把 optional 变 mandatory**：门窗可选观察、轻碰水滴、问题圈选、维修路缆线调查都不能卡主线。
3. **离开再回来丢失改动**：桶、梯子、草图、旧纸、事故状态都要保持。
4. **把视觉反馈写成文本答案**：先让玩家看到水滴变化，再出现短疑问；不直接告诉加速度公式。
5. **机器分支状态冲突**：先停机与后停机应抵达相同安全状态，但动作反馈要分别设计。
6. **过场重播**：书架发现、晨间警报与城堡 12° 偏转只首次播放。

---

# 10. 美术、动画、音效与文字资产清单（跨场景）

## 10.1 优先制作优先级

**P0（主线不可缺）**

- 大厅笔记夹页清单、三项任意顺序巡查（门闩/窗扣/时钟上弦/钥匙归位/印章归档）；
- 机械表盘近景、昨日/今日铅笔痕、红线越界版；
- 水滴完整循环、推桶命中判定、三焦点观察、等间隔三帧、四格手绘 UI；
- 梯子锁轮、书架木盒、`F = ma` 残页特写；
- 房间纸页比对、休息晨起、装包；
- 清晨警报/2、4 号手柄/本地停机/警示/城堡 12° 远望；
- 维修路、闸门、章节标题与存档。

**P1（强烈建议，提升情绪）**

- Kath 在玻璃、钟摆、钥匙、笔记前的短停顿；
- 不同时间的窗外色温与雨声层；
- 完成清单后 1 秒不插任务提示的静默；
- 第一滴水接到桶之后的一声清晰 `plink`；
- 新旧纸并排时的温暖灯光与轻音乐；
- Wick 的轻指引与回望动作。

**P2（可选精修）**

- 玻璃薄雾与水珠、钟内齿轮特写、钥匙磨损细节；
- 工具包铅垂/量尺、外套袖口；
- 雨后路面反光与雾层；
- 轻量角色手部动画；
- 完整本地化字幕和音效选项。

## 10.2 关键声音节奏

| 时段 | 主要声音 | 叙事用法 |
|---|---|---|
| 傍晚大厅 | 滴答、翻纸、风声 | 重复、有秩序；不故意渲染悲伤 |
| 机械室 | 低频机械声 + 初雨 | 正常运行，但能听出环境变化 |
| 书库入场 | 大雨、木板水滴 | 先形成保护书籍的实际需求 |
| 接桶成功 | 清晰 `plink` | 完成任务之后仍存在可观察现象 |
| 水滴笔记 | 雨声略退后、铅笔摩擦 | 给玩家主动观察和思考的空间 |
| Kath 房间 | 雨夜低声、台灯、纸张 | 安静、不用大型惊悚揭秘音乐 |
| 清晨警报 | 正常滴答被警报打断 | 由已建立的日常转入现实责任 |
| 维修路 | 风、湿路脚步、远方金属 | 仍未知，但角色开始主动向前 |

## 10.3 画面/镜头约束

- 所有关键现象至少有**可重复调查视图**，不要只在一次不可重播的过场中展示。
- 书库观察最好使用同一长镜头上下平移，而不是切四张不同风格的科学插图。
- 新旧笔记对照时镜头可以慢，但应允许玩家跳过已看过的长动画。
- 城堡倾斜不使用“整座城堡倒下”的视觉语言；固定塔楼与活动翼必须清楚区分。
- Wick 的提示光不成为能替玩家操作物件的能力，也不被解释为失名之夜原因。

---

# 11. 测试清单与试玩观察

## 11.1 功能路径测试

| 用例 | 操作 | 预期 |
|---|---|---|
| T01 | 首先打开笔记并展开清单→钥匙→钟→窗→门→盖章 | 任意顺序成功，盖章后开放机械室 |
| T02 | 展开清单→门→窗→钟→钥匙→盖章 | 与 T01 同样顺利，顺序不敏感 |
| T03 | 未读清单就检查物品；清单读后仅两项完成时按印章 | 前者只允许观察不计完成，后者提示剩余项、不强行完成 |
| T04 | 机械室基线画错再重试 | 不给答案，可调整直到记录成功 |
| T05 | 机械室打开近景后 Esc | 没有误记基线，之后可再做 |
| T06 | 书库先看水滴后推桶 | 能接水、做四格草图、拿残页 |
| T07 | 书库先接桶后观察 | 与 T06 一样推进 |
| T08 | 桶连续摆偏 3 次 | 可见水圈，永远可恢复，不触发死局 |
| T09 | 不做梯上轻碰试验 | 仍能完成全部序章 |
| T10 | 四格草图乱序/撤销/重画 | 状态稳定，完成后可打开木盒 |
| T11 | 圈选不同疑问/完全不选 | 序章可完成，存档值分别保留 |
| T12 | 打开残页按 Esc 离开 | 纸仍在木盒，返回后 Enter 才收起 |
| T13 | 房间对齐按 Esc 再确认 | 可重试，确认后不重复首播 |
| T14 | 起床没装包就出门 | 有提示，不能静默丢主线资料 |
| T15 | 警报先拉 2/4 再停机 | 安全完成，正确显示回落/偏转与关机 |
| T16 | 警报先停机再拉 2/4 | 同样完成，不显示误导性电机重新启动 |
| T17 | 警报处理中进出机房 | 读数/已操作手柄保持，不回滚 |
| T18 | 完成后重进机房 | 城堡偏转演出不二次播放 |
| T19 | 不调查维修路可选路牌和缆线 | 仍然能够开闸门完成序章 |
| T20 | 章节屏按 Esc | 返回维修路，按 Enter 才前往下一章 |

## 11.2 叙事体验测试（对首次游玩的玩家）

请受试者尽量不读脚本独立试玩，开发者只记录行为，试玩后简短访谈：

1. 在大厅，玩家是否注意到可选的玻璃/钟摆/钥匙细节？没注意到不等于失败；主线仍应自然。
2. 在书库，玩家是否**自己抬头**看铜边，而不是仅记得字幕？
3. 玩家是否通过桶的落点和三帧叠图理解“可以自己比较和检验”？
4. 玩家能否复述至少部分水滴的四种观察现象，而非只复述角色说了什么？
5. 玩家是否理解旧页证明 Kath 曾经做过记录，却没有直接恢复记忆？
6. 玩家是否注意到 S05 事故中“照做了，但指针仍异常”，因而理解为什么要继续记录和前往城堡？
7. 玩家是否认为 Kath 是因为**自己愿意理解问题并帮助他人**而向前，而不是被神秘力量驱使？

若玩家只记得教学字幕，优先改善水滴可读性、镜头停留和互动反馈；不优先增加讲解对白。

## 11.3 物理与叙事一致性检查

- [ ] 玻璃“感觉冷”不被简单等同于准确测得温度，天气变化不归因于单一温度因素。
- [ ] 时钟钟摆与时间测量的联系是观察入口，不宣称钟摆创造时间。
- [ ] 水滴附着时重力已作用；向上水花不意味着重力反向。
- [ ] 基线、红线与机械异常有连贯显示，昨日与今天可比较。
- [ ] 失名之夜发生约半年；人们还会阅读、装订、使用机器，不被写成丧失语言或思维能力。
- [ ] 序章无魔法和超自然现象，失名之夜的成因保持悬疑。
- [ ] Wick 没有任何说话台词或替玩家解释物理现象。
- [ ] 一章以前不能解开 `F = ma` 或吊篮设备完整救援方案。
- [ ] 城堡的 12° 与第一章的 180° 明确区分。

---

# 12. 与现有工程对接的实施顺序（推荐）

## Phase 1 — 读现有项目并建立差异清单

1. 检查 Godot 版本、项目目录结构、五张现有地图与脚本。
2. 确认已经存在的桶、梯子、残页、房间比对、警报与维修路交互，记录实际节点路径/信号。
3. 找到大厅的锁定规格 `PROLOGUE_HALL_SCENE_LOCKED.md`，如果存在，优先对照；**不得把本稿的大厅新对白当作已经批准的最终版本**。
4. 检查现有存档方式、交互按键、对话 UI、场景切换、动画组织。
5. 输出“可复用 / 需调整 / 需新建”的清单后才修改代码。

## Phase 2 — 可玩主线贯通

1. 修改大厅开场为“打开笔记→展开夹着的清单”，此后门窗、时钟、钥匙任意顺序；保留 v1.0 的简洁任务及盖章、应急红签。
2. 将 S02 自动记录仪表改为玩家手动摆铅笔痕。
3. 实现书库可调整桶位、可循环水滴及三焦点观察。
4. 实现四格草图可保存、木盒拾取、房间对齐。
5. 实现 S05 双顺序应急与 12° 城堡远望。
6. 维修路开门与 `Prologue Complete` 交接。

## Phase 3 — 角色觉醒演出与补充素材

1. 加入门窗/时钟/钥匙的**可选**观察与短停顿。
2. 将 `I want to see that again.` 绑定到玩家在接水之后自主重看水滴的动作。
3. 在书库笔记与房间旧笔记做“错误痕迹保留”的视觉呼应。
4. 加入雨前、雨夜、雨后的声音/光照节奏。
5. Wick 只在适当时机引导注意而不代替玩家做决定。

## Phase 4 — QA、试玩与回归

1. 逐个测试 T01–T20，以及反复场景切换/存档读档。
2. 跑一次**只走主线**和一次**尽量探索全部可选物件**，确认两个版本都自然。
3. 对水滴四现象做不开字幕试玩，确保画面本身足够清楚。
4. 记录过长的强制对白并删减，保留玩家自主观察空间。

---

# 13. 交给本地开发 AI 的任务指令（可复制）

> 请在我的现有 Godot 项目中，仅开发/修改序章，严格遵循本文档《序章：尚未完成的问题》 v1.2。首先检查现有项目版本、场景树、交互代码、存档、对白、UI、脚本和已做素材，并以增量修改为原则；不要先重建项目。若工程里存在 `PROLOGUE_HALL_SCENE_LOCKED.md`，它对大厅原有锁定文案和物件状态优先，本文 S01 中标记 PROPOSED 的文本与细节需要进行差异核对。请先给我一份逐场景的实现差异表和文件修改计划，再按 S01→S06 顺序施工，每完成一组交互输出对应的测试用例。保持所有主线条件、可选调查、重新进入场景的存档状态与两条应急路径。不要自动填写四格水滴草图，不在序章解释 `F = ma` 或失名之夜成因，不让 Wick 说话，不提前播放城堡 180° 翻转。每次修改后运行 Godot 项目，确认没有脚本错误、输入冲突和场景跳转死锁，最后附上已完成/未完成项目清单。对于本稿未明确的数据（例如地图尺寸、UI 坐标、动画帧率）应先从实际项目读取，再采用合理默认值并说明。

---

# 14. 需由主创检查的开放问题（不阻碍原型开发）

1. **大厅锁定稿是否完整可用？** 当前上传资料只提到 `PROLOGUE_HALL_SCENE_LOCKED.md`，未提供其全文。本稿 S01 含细化与新台词，需后续逐条对照。
2. **观测城堡与万象馆的视觉关系**：从大厅高窗、机械室观测装置、维修路分别能看到多少城堡？应由现有地图/摄影机决定，不能因叙事建议改得相互矛盾。
3. **机械仪表的视觉量纲**：当前只有“红线/上下偏转”的剧本要求；若工程有精确刻度，应保持一致。本稿不编造真实压力、温度或能量单位。
4. **晨间警报先停机分支的读数演出**：需要基于现有机械动画与控制器定义残余变化，避免“停机后仍不断启动”的误解。
5. **草图操作 UI 的精度和输入手感**：先做可编辑墨点/短线 MVP，再按试玩结果调整容差，避免自由绘图开发量压过剧情。
6. **对话配音范围**：现阶段可字幕 + 音效运行；如果制作配音，优先 Kath 的关键句，避免过多旁白压缩留白。

---

## 结语：这个序章真正让玩家学会的是什么？

不是“在序章中掌握多少物理公式”，而是经历一个由自己发起的认识过程：

**我看到了一件寻常的事 → 我发现自己并不理解 → 我愿意再看一次 → 我可以尝试、比较、留下证据 → 即使暂时没有答案，我仍然有能力继续寻找。**

故事开始，Kath 知道如何把每样东西放回正确的位置。故事结束，她仍然不能解释世界，但开始敢于面对那些尚未确定的事物，并决定自己要走向哪里。

**物理探索与自我觉醒在这里是一件事的两面：她通过重新理解世界，重新获得了主动思考和行动的能力。**
