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
