# 序章场景一：万象馆大厅互动脚本（第 1 步锁定稿）

本文锁定**玩家看到的英文文字、物件动作、可见结果与剧情触发**，作为后续素材和 Godot 实现的依据。现阶段只确定内容，不代表近景、美术或逻辑已接入游戏。主角为 **Kath**；Wick 以动作陪伴，不说话。

## 场景节奏

傍晚，暴雨将至，**尚未下雨**。窗外云层变暗，树枝被风吹动；东侧高窗的松扣使窗框间歇轻拍。大厅钟的摆动正在减弱。Kath 的笔记上有反复擦改的值班时间，没有关于她过去身份的解释。玩家进场后立即能行走和调查物件，无片头说明。

> Kath: “Storm before nightfall. Doors and windows, clock, keys. One round at a time.”

第一次打开巡查册后，玩家可按任意顺序完成三项；不先读册子也能完成操作。门闩和窗扣**共同**构成第一项。每次进入可操作物件都显示该物件的独立放大近景，玩家亲手动作，之后先看到近景变化，再在大厅中看到持续的变化。Kath 的一句反应只在动作完成后出现。Esc 离开未操作的近景不改变完成状态。重复查看只呈现已完成状态，不重复记日志或播放首次反应。

## 互动清单与最终英文文案

### 1. 档案门：扣紧门闩

- **初始状态：**门闩偏离卡槽，门在阵风中有轻微碰撞声。近景可辨认活动的铜栓、卡槽和门框。
- **玩家动作：**靠近门闩，`E Inspect Door Latch` 打开近景；按 **E** 扳下铜栓并使它扣入卡槽。
- **可见变化：**铜栓移进卡槽并停住，碰撞声停止；大厅门上的铜栓保持闭合。巡查册第一项仍不打勾，直到窗扣也固定。
- **Kath：**“The bolt is set. I still need to check the window.”
- **再次查看：**近景显示已扣紧的门闩，不再提供重复上锁动作。

旧铭牌是同一近景中的可选部位；其内容见“可选发现”。归档后，门的通行位置显示 `E Enter Machine Room`，门框旁的检查位置仍可重看门闩和铭牌，避免入口取代可选调查。

### 2. 东侧高窗：固定窗扣

- **初始状态：**窗扣歪斜，窗框随阵风拍打；窗外树枝摇晃，玻璃上没有雨滴。窗台有旧水渍，但不声称上层已经漏水。
- **玩家动作：**`E Inspect Window` 打开近景；按 **E** 推回窗扣，让它咬合窗框。
- **可见变化：**窗扣卡入位置，窗框不再拍打；外面的树枝仍继续摆动。返回大厅后窗户保持固定，拍打声持续消失。
- **Kath：**“The frame's quiet now. The wind isn't.”
- **任务反馈：**仅当**门闩和窗扣都完成**时，巡查册 `Check doors and windows before the storm` 由空框变为勾选，并在笔记记下一条完成记录。先做窗、后做门也产生相同结果。

### 3. 大厅钟：给钟上弦

- **初始状态：**摆锤幅度变小，滴答声拉长；近景有上弦柄和摆锤。
- **玩家动作：**`E Inspect Hall Clock` 打开近景；**按住 E 约一秒**转动上弦柄。提前松开时柄停在当前角度，已完成的进度保留，继续按住即可完成。
- **可见变化：**上弦柄逐步转动，摆锤恢复规律摆动，滴答声恢复稳定；大厅钟的摆动和声响同步保持。进度完成前按 Esc 不打勾。
- **Kath：**“Steady again. I'll write down the hour.”
- **任务反馈：**完成后，巡查册 `Wind the hall clock` 打勾，笔记只写入一次。再次查看显示已上弦的钟。

钟内盖是可选部位；其内容见“可选发现”。

### 4. 值班台钥匙架：挂回东侧钥匙

- **初始状态：**近景清楚展示三个固定挂位：`MACHINE ROOM`、`UPPER STACKS`、`EAST SERVICE WAY`。前两把钥匙各在对应挂位；第三把挂在旁边的临时钉上。**三把钥匙一开始就齐全。**
- **玩家动作：**`E Inspect Duty Keys` 打开近景；用左右键选中临时钉上的钥匙，按 **E** 将它挂回 `EAST SERVICE WAY` 挂位。
- **可见变化：**钥匙从临时钉移到正确挂钩，木牌晃动并短暂翻面，背面露出 `OBSERVATORY CASTLE`；回大厅时钥匙架排列同步改变。
- **Kath：**“All three are here. Why was the east key set aside?”
- **任务反馈：**巡查册 `Check the duty keys` 打勾；笔记仅记录“Three duty keys present; east key returned to its hook”，不猜测谁移过钥匙。再看背面时，Kath 可补一句：“Observatory Castle. That's past the east service way.”
- **再次查看：**三把钥匙保持在原挂位，可翻看钥匙牌；不出现寻找或领取钥匙的额外任务。日后开门沿用已有自动使用钥匙的流程。

### 5. 巡查册：勾选、归档、查看应急页

- **初始状态：**值班台的巡查册处于本次值班页，三个方框为空。近景文字为：

  ```text
  EVENING ROUND
  [ ] Check doors and windows before the storm
  [ ] Wind the hall clock
  [ ] Check the duty keys
  ```

- **玩家动作与实时结果：**`E Inspect Round Book` 打开近景。每项任务完成后，对应方框出现手写勾；顺序由实际完成顺序决定。近景内可用左右键在“本次值班页”和红签应急页间选择，**未完成巡查时也可读应急页**。
- **盖章条件：**只有三项都打勾，当前页才出现 `E Stamp and File`。按 E 后，印章压下并留下 `ROUND FILED`，完成页翻入已归档部分；眼前**当前任务页成为空白页**，不再显示未完成的旧任务。归档页保留三项的勾选，可反复翻回查看。机械室入口此时开放；仅做完三项、尚未盖章时仍显示待归档提示。
- **盖章后反应：**“Round filed. One reading downstairs before I'm done.”
- **红签页：**红签在盖章前后始终可见、可翻阅。玩家按 E 翻开，纸张动作停在印有以下原文的一页：

  ```text
  EMERGENCY PROCEDURE
  If the upper needle crosses the red line,
  pull lever 2, then lever 4.
  Check the needle again.
  ```

- **应急页反应，仅首次：**“Two, then four. Check the needle again. I hope I never need this.” Kath 只抄下操作顺序；她此时不知道指针测量什么。应急页不自动承诺操作一定能排除异常。
- **重复查看：**不会再盖章、清空或写入记录；空白页、归档页、应急页都可重看。

### 6. 可选发现：不计入三项任务

- **门旁旧铭牌。** 初始被灰覆盖，只露出磨损边缘。玩家在门闩近景用左右键选中铭牌、按 E 擦拭；灰被抹开，出现 `Grand Archive`，旁边较新的牌子写着 `Public Library`。Kath：“Grand Archive. Why keep a name no one uses?” 擦拭结果永久保留，可重复阅读，不解锁出口。
- **钟内盖。** 初始合上。玩家在钟近景选择内盖、按 E 掀开；内侧露出与钟点刻度不同的旧校准刻痕。Kath：“These marks aren't hours. What were they checking?” 内盖保持打开，可重看，不影响上弦。
- **目录卡。** 值班台上的卡片正面印着 `PUBLIC LIBRARY — LOCAL HISTORY`，背面朝下。玩家 `E Inspect Catalogue Card` 进入近景并按 E 翻卡；背面旧分类为 `GRAND ARCHIVE — OBSERVATIONS`，其上盖有 `RECATALOGUED AFTER THE NIGHT OF UNNAMING`。Kath：“The shelves stayed. The labels changed.” 翻面结果保留，可反复查看，不进入 `3/3`，也不说明失名之夜的成因或 Kath 的过去。

## 流程收束与返回对白

- 三项操作可任意顺序；实际任务状态在巡查册内自动反映。**盖章才开放机械室**，让“归档”成为玩家亲手完成的收束动作。
- 首次进入机械室时外面开始下雨。Kath 在机械室标记当日指针基线后返回大厅，雨势加重；窗扣依旧固定，屋顶深处传来滴水声。Kath：“The window is still shut. That water is coming from above.” 随后右侧楼梯指向顶层书库。这个观察不把漏水、机器或城堡故障断定为同一原因。
- 如果尚未标记基线就返回大厅，Kath：“I still need to mark today's needle.” 此时不触发上层滴水提示。
- 下一次进入大厅不重复开场、盖章和首次反应；归档页、应急页与全部物件保留已完成的样子。

## 制作与验收边界

- 玩家要从铜栓、窗框、摆锤、钥匙位置、纸页变化看出行动的结果。对白只补一个观察或疑问，不替代道具变化。
- `Grand Archive` 与 `Night of Unnaming` 只通过可选的铭牌、目录卡显露。开场不解释万象馆旧用途，不揭露事件成因，也不提前恢复 Kath 的科学记忆。
- 第一项完成判断为**门闩已扣紧且窗扣已固定**；可选发现与应急页阅读不计入 `3/3`。日志记录按唯一事件写一次。
- 本文只完成第 1 步的脚本锁定。独立近景图片、场景状态、存档版本与游戏内实现分别属于后续步骤。
