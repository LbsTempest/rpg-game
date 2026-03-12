# RPG 重构进展报告（可交接版）

## 1. 报告元信息
- 项目路径：`C:\Users\16411\Code\rpg-game`
- 基准提交：`33298cc`（`main`）
- 报告日期：2026-03-12
- 参考文档：`REFACTOR_CHECKLIST.md`

---

## 2. 一句话现状
当前已完成 **Phase 1 ~ Phase 11 的主体迁移与清理**，项目可运行、可导入；接下来应进入 **Phase 12（文档/测试/回归保障）**。

---

## 3. 阶段完成度（对照 REFACTOR_CHECKLIST）

## Phase 1 - ContentDB 统一内容定义
**状态：已完成（核心）**
- 已有目录：`resources/data/items|skills|quests|shops|story|maps|encounters|actors`
- 已有加载链：
  - `scripts/content/content_loader.gd`
  - `scripts/content/content_db.gd`
  - `scripts/content/*_catalog.gd`
- 已删除旧权威数据文件：
  - `resources/data/items_data.gd`
  - `resources/data/skills_data.gd`
  - `resources/data/quests_data.gd`

## Phase 2 - 运行时状态拆分
**状态：已完成（核心）**
- 已有状态层：`scripts/state/profile_state.gd`、`run_state.gd`、`party_state.gd`、`inventory_state.gd`、`quest_state.gd`、`shop_state.gd`、`story_state.gd`、`world_state.gd`
- `Session` 已作为状态总入口：`scripts/core/session.gd`

## Phase 3 - SaveService 与迁移
**状态：已完成（核心）**
- 已有：
  - `scripts/core/save_service.gd`
  - `scripts/core/save_migrator.gd`
  - `scripts/core/run_state_serializer.gd`
  - `scripts/core/profile_state_serializer.gd`
  - `scripts/core/save_slot_info.gd`

## Phase 4 - 条件/动作层
**状态：已完成（核心）**
- 已有：
  - `scripts/services/condition_service.gd`
  - `scripts/services/action_executor.gd`
  - `scripts/services/trigger_router.gd`
  - `scripts/core/game_events.gd`

## Phase 5 - UI 路由与输入路由
**状态：已完成（结构到位，仍有兼容 UI 逻辑）**
- 已有：
  - `scripts/core/ui_router.gd`
  - `scripts/core/input_router.gd`
- 已补 UI 分屏骨架：
  - `scripts/ui/hud_screen.gd` + `scenes/ui/hud_screen.tscn`
  - `scripts/ui/inventory_screen.gd` + `scenes/ui/inventory_screen.tscn`
  - `scripts/ui/character_screen.gd` + `scenes/ui/character_screen.tscn`
  - `scripts/ui/dialogue_screen.gd` + `scenes/ui/dialogue_screen.tscn`
  - `scripts/ui/shop_screen.gd` + `scenes/ui/shop_screen.tscn`
  - `scripts/ui/battle_screen.gd` + `scenes/ui/battle_screen.tscn`
  - `scripts/ui/journal_screen.gd` + `scenes/ui/journal_screen.tscn`
- 说明：现有 `scripts/ui.gd` 仍承载主 HUD/背包逻辑，属兼容层。

## Phase 6 - 世界层与地图规则
**状态：已完成（基础）**
- 已有：
  - `scripts/world/map_service.gd`
  - `scripts/world/movement_service.gd`
  - `scripts/world/collision_service.gd`
  - `scripts/world/elevation_service.gd`
  - `scripts/world/map_runtime.gd`
  - `scripts/world/interaction_source.gd`
  - `scripts/world/interaction_registry.gd`
  - `scripts/world/spawn_service.gd`
- 场景到位：
  - `scenes/world/world_root.tscn`
  - `scenes/interaction/shop_source.tscn`
  - `scenes/interaction/quest_board_source.tscn`
  - `scenes/interaction/story_trigger.tscn`

## Phase 7 - 任务/商店领域重构
**状态：已完成（主逻辑已迁移）**
- 已有服务：
  - `scripts/progression/quest_service.gd`
  - `scripts/progression/shop_service.gd`
  - `scripts/progression/reward_service.gd`
- 已删除旧管理器：
  - `scripts/quest_manager.gd`（已删）
  - `scripts/shop_manager.gd`（已删）
- 已删除旧商店 UI 链路：
  - `scripts/shop_ui.gd`（已删）
  - `scripts/shop_ui_controller.gd`（已删）
  - `scenes/shop_ui.tscn`（已删，已迁至 `scenes/ui/shop_screen.tscn`）

## Phase 8 - 队伍制战斗核心
**状态：已完成（核心）**
- 已有：
  - `scripts/battle/combatant_state.gd`
  - `scripts/battle/battle_session.gd`
  - `scripts/battle/battle_resolver.gd`
  - `scripts/battle/targeting_service.gd`
  - `scripts/battle/encounter_service.gd`
- `scripts/battle_manager.gd` 已接入会话驱动与状态快照 UI
- 已新增遭遇内容源：
  - `resources/data/encounters/default_encounters.gd`
  - `scripts/content/encounter_catalog.gd`
  - `ContentDB.get_encounter_definition()`

## Phase 9 - 剧情系统与结局
**状态：已完成（基础实现）**
- 已有：
  - `scripts/narrative/story_service.gd`
  - `scripts/narrative/ending_resolver.gd`
  - `scripts/narrative/dialogue_presenter.gd`
- 已有故事数据：
  - `resources/data/story/default_story.gd`
- 存档字段已包含 story：
  - flags / current_segment_id / current_step_index / branch_choices

## Phase 10 - 二周目规则层
**状态：已完成（基础实现）**
- 已有：
  - `scripts/progression/cycle_service.gd`
  - `scripts/progression/carry_over_policy.gd`
  - `scripts/progression/cycle_condition_service.gd`
  - `scripts/ui/cycle_summary_screen.gd`
  - `scenes/ui/cycle_summary_screen.tscn`

## Phase 11 - 冗余清理与兼容层下线
**状态：大体完成（已进行大规模清理）**
- 已删除：
  - `scripts/game_manager.gd`
  - `scripts/item.gd`
  - `resources/item.gd`
  - `scripts/quest_manager.gd`
  - `scripts/shop_manager.gd`
  - `scripts/shop_ui.gd`
  - `scripts/shop_ui_controller.gd`
  - `scenes/shop_ui.tscn`
  - `resources/data/items_data.gd`
  - `resources/data/skills_data.gd`
  - `resources/data/quests_data.gd`
- autoload 已切换到 `App`，并移除了 `QuestManager/ShopManager`。

---

## 4. 当前 Autoload 真源（project.godot）
`GameConstants, ContentDB, Session, App, Utils, SaveService, GameEvents, StoryService, ConditionService, ActionExecutor, TriggerRouter, UIRouter, InputRouter, MapService, MovementService, InteractionRegistry, SpawnService, RewardService, QuestService, ShopService, CycleService, InventoryManager, BattleManager, DialogueManager, SkillManager, AudioManager, EnemyManager`

说明：
- `InventoryManager/BattleManager/DialogueManager/SkillManager/EnemyManager/Utils` 目前仍是运行中的兼容入口（非死代码）。

---

## 5. 关键行为验证（已做）
- 命令：`godot --headless --path . --import`
- 结果：通过。
- 曾出现的 UID warning（`main.tscn` 中 player/ui/skeleton）已修复。

---

## 6. 当前已知技术债（进入 Phase 12 前）
1. `scripts/ui.gd` 仍承担较多旧 UI 逻辑，可继续拆到 `scripts/ui/*_screen.gd`。
2. `InventoryManager/BattleManager/DialogueManager/SkillManager/EnemyManager` 仍是兼容层入口，后续可继续服务化。
3. `README.md` 仍是旧结构描述，尚未同步重构后架构与文件组织。
4. 自动化测试尚未建立（`test/` 为空，未接 GUT）。

---

## 7. 下一会话建议执行清单（Phase 12）
1. 更新 `README.md`
- 目标：反映 `App + Session + ContentDB + Services + State + World + UI` 架构。
- 同步当前 autoload 和目录结构。

2. 建立最小测试骨架（GUT）
- 目标目录：`test/`
- 建议优先：
  - `QuestService` 接取/推进/领奖
  - `ShopService` 购买/出售/库存变化
  - `StoryService` segment/branch/flag
  - `SaveService` 序列化反序列化一致性

3. 手动冒烟脚本文档化
- 新游戏
- 打开背包/使用物品/装备
- 商店买卖
- 任务接取/推进/提交
- 战斗五种操作
- 存档/读档
- 剧情 flag
- 二周目启动

4. 可选继续薄化
- 把 `ui.gd` 拆到具体 screen
- 逐步把 `InventoryManager` 的业务写入 `state/services`

---

## 8. 新会话接手提示（Prompt 模板）
可在新对话直接使用：

```text
请先读取 REFACTOR_PROGRESS_REPORT.md 和 REFACTOR_CHECKLIST.md。
当前基准提交是 33298cc（main）。
请从 Phase 12 开始，优先完成：
1) README 架构同步
2) GUT 最小测试骨架
3) 手动冒烟流程文档
保持项目可运行，每一步都执行 godot --headless --path . --import 验证。
```

