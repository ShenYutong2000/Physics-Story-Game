# 序章场景图 v2：出图清单

提示词在 `prompts/`，每个文件可以整段复制。文件名前缀是出图顺序，后半段是要保存成的文件名。
美术规则和取舍说明见 `docs/PROLOGUE_ART_DIRECTION_V2.md`。

所有图：1672×941，PNG，文件名与 v1 相同。

## 顺序

先只做 **01 大厅的干净底图**，确认风格满意，再做其余的。风格定下来之后，后面每张都把这张大厅图一起作为风格输入，五个场景才会统一。

| 步骤 | 提示词 | 输入图 | 保存为 |
| --- | --- | --- | --- |
| 1 | `1-clean_<名称>.txt` | v1 的 `prologue-asset-pack-v1/backgrounds/<名称>.png`（只取布局），加上你的参考图 | `backgrounds/<名称>.png` |
| 2 | `2-far_archive-prestorm-city.txt` | 无 | `far/archive-prestorm-city.png` |
| 2 | `2-far_archive-night-city.txt`、`2-far_archive-dawn-city.txt` | 上一行生成的 prestorm 图 | `far/archive-night-city.png`、`far/archive-dawn-city.png` |
| 2 | `2-far_05-service-road-far.txt` | 新的 05 干净底图 | `far/05-service-road-far.png` |
| 3 | `3-mid_interiors-01-to-04.txt`（四个室内各跑一次） | 该场景新的干净底图 | `mid/01-library-hall-mid.png` 等四张 |
| 3 | `3-mid_05-service-road-mid.txt` | 新的 05 干净底图 | `mid/05-service-road-mid.png` |
| 4 | `4-front_<名称>.txt` | 该场景新的干净底图 | `foregrounds/<名称>.png` |

共 19 张：5 张底图、4 张远景、5 张中景、5 张前景。

## 每张图出来后检查

- 大件的位置和 v1 一致：门洞、窗、桌子、书架、楼梯、空白的控制板、地栅、空的圆环。位置偏了，热点和道具就对不上。
- 行走带（画面高度约 80% 处往下）是干净的，没有物件。
- 底图里没有被要求去掉的东西：钟、梯子、木匣、水桶、手柄、仪表指针、路牌、栅门、人物。
- 中景和前景是真透明，不是画出来的棋盘格或黑白底。
- 没有魔法、霓虹、电子屏幕，没有可读的文字。
- 尺寸是 1672×941。工具输出的尺寸不同也没关系，放进来后可以统一缩放。
