# RPG 重构进展报告（可交接版）

## 1. 报告元信息
- 项目路径：`C:\Users\lbs\Code\rpg_game`
- 参考清单：`REFACTOR_CHECKLIST.md`
- 报告日期：2026-03-14
- 当前状态：工作区存在未提交改动（处于重构收口阶段）

---

## 2. 一句话现状
当前已完成 **Phase 1 ~ Phase 11 的主体迁移与大部分清理**，并通过导入验证；正在推进 **Phase 12（文档/测试/回归保障）** 与最终收口。

---

## 3. 阶段完成度（对照 REFACTOR_CHECKLIST）

## Phase 1 - ContentDB 统一内容定义
**状态：已完成（核心）**
- 已落地内容层：`scripts/content/content_db.gd`、`content_loader.gd`、`*_catalog.gd`
- 数据目录已统一到 `resources/data/items|skills|quests|shops|story|maps|encounters|actors`
- 旧权威数据文件已删除：`items_data.gd`、`skills_data.gd`、`quests_data.gd`

## Phase 2 - 运行时状态拆分
**状态：已完成（核心）**
- 状态层已落地：`profile_state`、`run_state`、`party_state`、`inventory_state`、`quest_state`、`shop_state`、`story_state`、`world_state`
- `Session` 已作为运行状态入口

## Phase 3 - SaveService 与迁移
**状态：已完成（核心）**
- 已落地：`save_service.gd`、`save_migrator.gd`、`run_state_serializer.gd`、`profile_state_serializer.gd`
- 旧档迁移链仍保留（`legacy save -> 新结构`）

## Phase 4 - 条件/动作层
**状态：已完成（核心）**
- 已落地：`condition_service.gd`、`action_executor.gd`、`trigger_router.gd`、`game_events.gd`

## Phase 5 - UI 路由与输入路由
**状态：已完成（收口）**
- 已落地：`ui_router.gd`、`input_router.gd`
- `scripts/ui.gd` 已删除，HUD/背包逻辑已拆分到 `scripts/ui/hud_screen.gd` 与 `scripts/ui/inventory_screen.gd`
- 战斗与对话入口已迁移为 `scripts/ui/battle_screen.gd`、`scripts/ui/dialogue_screen.gd`
- 已删除未接线占位 UI：`scenes/ui/hud_screen.tscn`、`scenes/ui/inventory_screen.tscn`、`scenes/ui/character_screen.tscn`

## Phase 6 - 世界层与地图规则
**状态：已完成（基础）**
- 已落地：`map_service.gd`、`movement_service.gd`、`collision_service.gd`、`elevation_service.gd`、`interaction_registry.gd`、`spawn_service.gd`
- 交互源场景已落地：`shop_source.tscn`、`quest_board_source.tscn`、`story_trigger.tscn`

## Phase 7 - 任务/商店领域重构
**状态：已完成（主逻辑已迁移）**
- 已落地：`quest_service.gd`、`shop_service.gd`、`reward_service.gd`
- 旧链路已删：`quest_manager.gd`、`shop_manager.gd`、`shop_ui*.gd`、`scenes/shop_ui.tscn`

## Phase 8 - 队伍制战斗核心
**状态：已完成（核心）**
- 核心已落地：`battle_session.gd`、`battle_resolver.gd`、`targeting_service.gd`、`encounter_service.gd`、`combatant_state.gd`
- 战斗服务已迁移为：`scripts/battle/battle_service.gd`
- 旧战斗入口文件已删除：`scripts/battle_manager.gd`、`scripts/battle_scene.gd`、`scenes/battle_scene.tscn`

## Phase 9 - 剧情系统与结局
**状态：已完成（基础实现）**
- 已落地：`story_service.gd`、`ending_resolver.gd`、`dialogue_presenter.gd`
- 对话入口场景已迁移为：`scenes/ui/dialogue_screen.tscn`
- 旧文件已删除：`scripts/dialogue_manager.gd`、`scenes/dialogue_manager.tscn`

## Phase 10 - 二周目规则层
**状态：已完成（基础实现）**
- 已落地：`cycle_service.gd`、`carry_over_policy.gd`、`cycle_condition_service.gd`
- `cycle_summary_screen` 已实现但目前未接线到主流程

## Phase 11 - 冗余清理与兼容层下线
**状态：进行中（高完成度）**
- 已完成命名与路径收口：
  - `InventoryService -> scripts/services/inventory_service.gd`
  - `SkillService -> scripts/services/skill_service.gd`
  - `BattleService -> scripts/battle/battle_service.gd`
  - `EnemyStateService -> scripts/world/enemy_state_service.gd`
  - `DialogueService -> scenes/ui/dialogue_screen.tscn`（autoload）
- 旧兼容入口文件已删除：
  - `scripts/inventory_manager.gd`
  - `scripts/skill_manager.gd`
  - `scripts/battle_manager.gd`
  - `scripts/enemy_manager.gd`
  - `scripts/ui.gd`

---

## 4. 当前 Autoload 真源（project.godot）
`GameConstants, ContentDB, Session, App, Utils, SaveService, GameEvents, StoryService, ConditionService, ActionExecutor, TriggerRouter, UIRouter, InputRouter, MapService, MovementService, InteractionRegistry, SpawnService, RewardService, QuestService, ShopService, CycleService, InventoryService, BattleService, DialogueService, SkillService, AudioManager, EnemyStateService`

---

## 5. 最新可运行验证
- 命令（2026-03-14）：
```powershell
& "C:\Users\lbs\Code\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --headless --path . --import
```
- 结果：通过（Exit code 0）

---

## 6. 当前已知待办（Phase 12 + 收口）
1. 文档仍落后于代码
- `README.md` 仍有旧路径/旧命名描述（如旧 manager 文件名）
- 本报告已更新，但 `README.md` 需同步

2. 测试体系未建立
- `test/` 仍缺最小自动化回归骨架

3. 二周目总结界面未接线
- `scripts/ui/cycle_summary_screen.gd` 与 `scenes/ui/cycle_summary_screen.tscn` 仍未接主流程

4. 旧档迁移链是否保留待决策
- 若不再支持旧档，可移除 `save_migrator` 与 legacy 路径逻辑

5. 提交收口未完成
- 当前为大量未提交改动状态，需分批提交并回归验证

---

## 7. 下一会话建议执行顺序
1. 同步 `README.md` 到当前架构与文件路径
2. 为 `QuestService/ShopService/SaveService/StoryService` 建最小测试骨架
3. 决策并处理 `cycle_summary_screen`（接线或下线）
4. 决策并处理 legacy save 迁移链
5. 分批提交重构改动，每批后执行一次 `--headless --import`
