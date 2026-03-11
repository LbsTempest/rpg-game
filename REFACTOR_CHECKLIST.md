# RPG Game Refactor Checklist

本文档用于记录本项目的重构设计方案、阶段划分、涉及文件与验收标准。
当前阶段只制定方案，不代表这些改动已经开始实施。

## 1. 文档目的

本次重构的目标不是单纯修几个 bug，而是解决当前项目里几个更根本的问题：
- 数据定义分散，物品、任务、商店、技能在多个脚本里各有一套结构。
- 运行时状态和场景节点强耦合，导致存档、读档、切场景和新游戏重置都容易出错。
- UI、输入、业务逻辑和场景实例混在一起，导致 `Esc`、暂停、界面切换等行为冲突。
- 当前实现虽然已经覆盖了移动、战斗、对话、物品、技能、商店、任务、存档等核心闭环，但内部冗余较多，后续继续加功能会越来越难维护。
- 未来明确会加入剧情系统、多结局、二周目、地图高低差规则、任务日志、商店解耦、队友加入等内容，现有结构不适合直接扩展。

## 2. 本次重构的总目标

### 2.1 必须保留的现有功能
- 主菜单、新游戏、读档、退出。
- 世界内移动、敌人巡逻与追击、接触触发战斗。
- 回合制战斗：攻击、防御、技能、道具、逃跑。
- 背包、装备、金币、技能、敌人状态保存。
- NPC 对话、分支选项、商店入口。
- 任务系统基础能力。
- JSON 存档读档。

### 2.2 本次重构的非目标
- 暂不直接实装未来功能的完整玩法内容。
- 暂不大规模重做美术、地图内容或 UI 视觉风格。
- 暂不扩充剧情文本、任务数量、敌人种类。

### 2.3 新架构必须解决的已知问题
- 游戏内读档不能完整恢复当前玩家状态。
- 玩家 HP/MP 在载入后会被 `_ready()` 覆盖。
- 战斗里的“防御”不真正参与伤害结算。
- 技能冷却推进规则错误。
- 任务目标使用显示名和内部名混用，导致推进失败。
- 任务奖励的物品数据结构与背包/装备/战斗的消费结构不兼容。
- 新游戏与部分读档路径下，装备状态没有彻底重置。
- 战斗 UI 与战斗状态只有半连接。
- `Esc` 被多个系统同时监听，暂停和关界面会互相打架。
- 地图碰撞和世界通行缺少单一真源。
- 商店和物品定义重复实现。
- 仓库里存在旧版 UI 或旧版管理器残留。

## 3. 设计方案

## 3.1 分层原则

重构后建议把项目拆成六层：

| 层 | 职责 | 说明 |
|---|---|---|
| `core` | 应用生命周期、场景切换、输入路由、存档调度、UI 路由 | 少量全局入口 |
| `content` | 只读内容定义：物品、技能、任务、商店、地图、剧情、遭遇等 | 单一数据真源 |
| `state` | 当前运行状态与跨周目档案状态 | 不直接操作 UI |
| `services` | 业务逻辑：任务、商店、剧情、战斗、地图规则、刷怪、奖励 | 负责修改状态 |
| `world` | 世界场景实例、玩家/敌人/NPC 外壳、触发点、地图运行时桥接 | 只做场景与状态同步 |
| `ui` | HUD、背包、任务日志、对话、商店、战斗、角色界面 | 只展示状态并发出意图 |

核心原则：
- 内容定义和运行时状态彻底分离。
- 所有内部逻辑统一使用稳定 ID，不再使用显示名做逻辑判断。
- UI 不直接拥有业务状态。
- 场景节点不再承担“数据真源”角色。
- 所有未来功能都通过统一条件系统接入，而不是各写一套判断。

## 3.2 推荐的顶层运行入口

| 模块 | 建议职责 | 是否建议 Autoload |
|---|---|---|
| `App` | 启动流程、主场景切换、应用级暂停协调 | 是 |
| `Session` | 当前周目的运行状态总入口 | 是 |
| `ContentDB` | 统一读取各类内容定义 | 是 |
| `SaveService` | 档案存档、周目存档、版本迁移、加载同步 | 是 |
| `UIRouter` | 界面打开/关闭/返回栈/焦点优先级 | 是 |
| `GameEvents` | 域事件中心，降低模块耦合 | 可选 |

## 3.3 目标目录组织

```text
rpg_game/
├── REFACTOR_CHECKLIST.md
├── resources/
│   ├── data/
│   │   ├── items/
│   │   ├── skills/
│   │   ├── quests/
│   │   ├── shops/
│   │   ├── story/
│   │   ├── maps/
│   │   ├── encounters/
│   │   └── actors/
│   └── dialogue/
├── scenes/
│   ├── world/
│   ├── battle/
│   ├── ui/
│   ├── actors/
│   └── interaction/
└── scripts/
    ├── core/
    ├── content/
    ├── state/
    ├── services/
    ├── world/
    ├── battle/
    ├── narrative/
    ├── progression/
    └── ui/
```

## 3.4 统一数据模型

### A. 内容定义对象
- `ItemDefinition`
- `SkillDefinition`
- `QuestDefinition`
- `ShopDefinition`
- `StorySegmentDefinition`
- `EncounterDefinition`
- `MapDefinition`
- `ActorDefinition`

### B. 运行时状态对象
- `ProfileState`
  - 跨周目永久数据
  - 已达成结局
  - 已解锁内容
  - 当前周目数
- `RunState`
  - 当前地图
  - 队伍状态
  - 背包状态
  - 任务状态
  - 商店状态
  - 剧情状态
  - 世界状态
- `PartyState`
  - 出战成员
  - 替补成员
  - 编队顺序
- `StoryState`
  - 剧情旗标
  - 当前章节/段落
  - 分支选择
  - 候选结局标记
- `WorldState`
  - 地图局部状态
  - 敌人刷新与死亡状态
  - 交互点状态
  - 地图机关和地形变化状态

### C. 跨系统共享抽象
- `ConditionSet`
  - 内容开放条件统一模型
  - 剧情、任务、商店、地图事件、二周目内容都共用
- `ActionExecutor`
  - 对话、剧情、任务奖励、交互点统一动作执行入口
- `InteractionSource`
  - 通用交互源
  - NPC 只是交互源的一种，不再承载全部系统逻辑
- `CombatantState`
  - 战斗单位的统一状态模型
  - 主角、未来队友、敌人共用

## 3.5 未来功能如何融入架构

### 剧情系统与多结局
- 剧情进度由 `StoryState` 统一保存。
- 分支与局部过场由 `StoryService` 驱动。
- 结局由 `EndingResolver` 根据剧情旗标、任务状态、关键事件和周目数据计算。
- 对话文本和剧情推进分离：
  - 对话是展示内容。
  - 剧情状态是业务逻辑。

### 二周目
- 档案层拆为：
  - `ProfileState`：跨周目永久存在。
  - `RunState`：单周目即时状态。
- `CycleService` 负责：
  - 开启新周目
  - 应用继承规则
  - 判断哪些内容属于一周目专属或二周目专属

### 地图系统
- 地图表现使用 TileMap。
- 移动采用细粒度连续移动，而不是格子一步一步跳。
- 地图规则需要拆成三层：
  - tile 自身阻挡
  - tile 边界阻挡
  - 高差与层级规则
- `MovementService` 负责移动请求。
- `CollisionService` 和 `ElevationService` 负责通行判定。

### 商店与任务解耦
- 商店不再属于 NPC 脚本，而属于 `shop_id` 对应的内容定义与运行时状态。
- 不同商人可指向不同 `shop_id`，共享统一商店 UI。
- 任务不再必须由 NPC 提供，可以由任务板、调查点、剧情段、地图触发器等来源发起。
- 已接和已完成任务统一由 `JournalScreen` 或角色界面查看。

### 队友加入后的战斗
- 当前主角只是 `PartyState` 里的第一个成员。
- 战斗逻辑按“队伍 vs 敌方单位组”设计。
- 未来加入队友时，不重写战斗架构，只补充内容和 UI。

## 3.6 命名与接口规范

### ID 命名
- 统一使用 `snake_case`
- 示例：
  - `quest_first`
  - `merchant_shop`
  - `map_village`
  - `encounter_forest_slime_group`

### Flag 命名
- 统一使用带命名空间的字符串
- 示例：
  - `story.chapter_01.met_merchant`
  - `story.branch.saved_villager`
  - `world.bridge_lowered`
  - `cycle.ng_plus_unlocked`

### 方法命名
- 查询：`get_`、`has_`、`can_`、`list_`
- 命令：`start_`、`open_`、`accept_`、`turn_in_`、`apply_`、`resolve_`、`set_`、`request_`

### 建议的公开接口

#### 剧情
- `start_story_segment(segment_id: String)`
- `advance_story()`
- `choose_story_branch(branch_id: String)`
- `set_story_flag(flag_id: String, value: bool = true)`
- `has_story_flag(flag_id: String) -> bool`
- `resolve_ending_id() -> String`

#### 二周目
- `start_new_cycle(profile_slot_id: String)`
- `get_cycle_index() -> int`
- `is_ng_plus() -> bool`
- `apply_carry_over_rules()`
- `is_content_available(content_id: String, conditions: Dictionary) -> bool`

#### 地图与移动
- `request_world_move(actor_id: String, input_vector: Vector2, delta: float)`
- `can_traverse_segment(actor_id: String, from_pos: Vector2, to_pos: Vector2) -> bool`
- `get_tile_height(map_id: String, cell: Vector2i) -> int`
- `has_edge_barrier(map_id: String, cell: Vector2i, direction: Vector2i) -> bool`

#### 商店
- `open_shop(shop_id: String)`
- `list_shop_items(shop_id: String) -> Array`
- `purchase_item(shop_id: String, item_id: String, quantity: int)`
- `sell_item(shop_id: String, item_id: String, quantity: int)`

#### 任务
- `accept_quest(quest_id: String, source_id: String = "")`
- `turn_in_quest(quest_id: String, source_id: String = "")`
- `update_quest_progress(trigger_id: String, target_id: String, amount: int = 1)`
- `get_active_quest_entries() -> Array`
- `get_completed_quest_entries() -> Array`
- `get_journal_view_data() -> Dictionary`

#### 战斗
- `start_encounter(encounter_id: String)`
- `start_world_encounter(enemy_group_id: String)`
- `list_player_combatants() -> Array`
- `queue_action(actor_id: String, action_id: String, target_spec: Dictionary)`
- `resolve_next_turn()`
- `can_use_skill(actor_id: String, skill_id: String) -> Dictionary`
- `use_item_in_battle(user_id: String, item_id: String, target_spec: Dictionary)`

## 4. 重构阶段清单

以下阶段按优先级排序，建议严格顺序推进。

## Phase 0 - 基线冻结与现状建档

### 目标
先固定“现在项目真实能做什么、哪里有问题、哪些功能不能在重构时被弄丢”。

### 任务
- 记录当前已实现功能矩阵。
- 记录已发现的问题与风险。
- 明确当前单例、场景和主流程关系。
- 标记已经过时但仍在仓库里的旧实现。

### 需重点梳理的现有文件
- `README.md`
- `project.godot`
- `scripts/game_manager.gd`
- `scripts/inventory_manager.gd`
- `scripts/battle_manager.gd`
- `scripts/dialogue_manager.gd`
- `scripts/skill_manager.gd`
- `scripts/quest_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/enemy_manager.gd`
- `scripts/player.gd`
- `scripts/enemy.gd`
- `scripts/npc.gd`
- `scripts/ui.gd`
- `scripts/battle_scene.gd`
- `scripts/main_menu.gd`
- `scripts/main.gd`
- `scenes/main.tscn`
- `scenes/player.tscn`
- `scenes/ui.tscn`
- `scenes/shop_ui.tscn`
- `scenes/battle_scene.tscn`
- `scenes/npcs/villager.tscn`
- `scenes/npcs/merchant.tscn`
- `scenes/enemies/slime.tscn`
- `scenes/enemies/skeleton.tscn`

### 验收标准
- 当前项目现状、风险和优先级可以被持续追踪。
- 每个后续阶段都有可回退边界。

## Phase 1 - 统一内容定义与 ContentDB

### 目标
把散落在多个脚本里的物品、技能、任务、商店、剧情和地图定义统一起来。

### 任务
- 定义统一的内容结构。
- 建立 `ContentDB` 作为内容读取总入口。
- 为旧数据结构做临时兼容适配。
- 停止在业务脚本里继续硬编码物品、奖励和商店内容。

### 现有文件改造范围
- `resources/data/items_data.gd`
- `resources/data/skills_data.gd`
- `resources/data/quests_data.gd`
- `resources/dialogues/default_npc_dialogue.gd`
- `resources/dialogues/merchant_dialogue.gd`
- `scripts/constants.gd`
- `scripts/game_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/skill_manager.gd`
- `scripts/quest_manager.gd`

### 规划新增文件
- `scripts/content/content_db.gd`
- `scripts/content/content_loader.gd`
- `scripts/content/definition_adapter.gd`
- `scripts/content/item_catalog.gd`
- `scripts/content/skill_catalog.gd`
- `scripts/content/quest_catalog.gd`
- `scripts/content/shop_catalog.gd`
- `scripts/content/story_catalog.gd`
- `scripts/content/map_catalog.gd`
- `resources/data/items/`
- `resources/data/skills/`
- `resources/data/quests/`
- `resources/data/shops/`
- `resources/data/story/`
- `resources/data/maps/`
- `resources/data/encounters/`

### 验收标准
- 物品、任务、技能、商店定义不再散落在多个业务脚本里。
- 内部逻辑不再依赖显示名推进任务或触发剧情。

## Phase 2 - 运行时状态拆分：ProfileState / RunState

### 目标
把当前“节点即状态源”的模式改为“状态对象为真源”。

### 任务
- 定义 `ProfileState`、`RunState`、`PartyState`、`InventoryState`、`QuestState`、`ShopState`、`StoryState`、`WorldState`。
- 明确哪些数据属于跨周目档案，哪些属于当前周目运行状态。
- 用 `Session` 统一暴露运行状态入口。
- 逐步让场景节点从“保存状态的人”变成“展示状态的人”。

### 现有文件改造范围
- `scripts/game_manager.gd`
- `scripts/inventory_manager.gd`
- `scripts/quest_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/enemy_manager.gd`
- `scripts/skill_manager.gd`
- `scripts/player.gd`

### 规划新增文件
- `scripts/state/profile_state.gd`
- `scripts/state/run_state.gd`
- `scripts/state/party_state.gd`
- `scripts/state/character_state.gd`
- `scripts/state/inventory_state.gd`
- `scripts/state/quest_state.gd`
- `scripts/state/shop_state.gd`
- `scripts/state/story_state.gd`
- `scripts/state/world_state.gd`
- `scripts/core/session.gd`

### 验收标准
- 新游戏和读档可以描述成“初始化状态 + 同步场景”。
- 装备状态有明确的重置和恢复位置。
- 未来加入队友和二周目时，不需要再发明新的全局变量。

## Phase 3 - SaveService 与存档迁移管线

### 目标
把存档读档统一收口，并为版本迁移和二周目存档结构打基础。

### 任务
- 引入 `SaveService`。
- 分离 Profile 存档和 Run 存档。
- 明确存档版本号和迁移入口。
- 定义加载后如何把状态同步回世界和 UI。

### 现有文件改造范围
- `scripts/game_manager.gd`
- `scripts/player.gd`
- `scripts/ui.gd`
- `scripts/main_menu.gd`
- `scripts/enemy_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/quest_manager.gd`
- `scripts/skill_manager.gd`

### 规划新增文件
- `scripts/core/save_service.gd`
- `scripts/core/save_slot_info.gd`
- `scripts/core/save_migrator.gd`
- `scripts/core/run_state_serializer.gd`
- `scripts/core/profile_state_serializer.gd`

### 验收标准
- 游戏内读档和主菜单读档恢复结果一致。
- 玩家位置、HP/MP、装备、任务、商店、世界状态都能恢复。
- 不再依赖 `_ready()` 的偶然顺序去“顺便恢复数据”。

## Phase 4 - ConditionSet、ActionExecutor 与事件契约

### 目标
建立剧情、任务、商店、地图事件和二周目内容都能复用的条件与动作层。

### 任务
- 定义 `ConditionSet` 结构。
- 定义 `ActionExecutor` 可执行动作集合。
- 建立统一域事件命名。
- 逐步把对话分支、任务奖励、商店开放、剧情推进切到共享动作。

### 现有文件改造范围
- `scripts/npc.gd`
- `scripts/dialogue_manager.gd`
- `scripts/quest_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/battle_manager.gd`
- `scripts/main.gd`

### 规划新增文件
- `scripts/core/game_events.gd`
- `scripts/services/condition_service.gd`
- `scripts/services/action_executor.gd`
- `scripts/services/trigger_router.gd`

### 验收标准
- 任务、商店、剧情和地图事件都能用统一条件表达开放规则。
- 交互动作不再散落成多个脚本里的硬编码分支。

## Phase 5 - UIRouter、InputRouter 与界面归属清理

### 目标
把当前互相抢输入、互相切状态的 UI 行为梳理干净。

### 任务
- 引入 `UIRouter` 和 `InputRouter`。
- 统一 `Esc`、确认、存档、读档、打开背包、打开任务日志、打开商店等输入规则。
- 把 HUD、背包、角色界面、任务日志、商店、对话、战斗界面拆成独立屏幕。

### 现有文件改造范围
- `scripts/ui.gd`
- `scripts/dialogue_manager.gd`
- `scripts/battle_scene.gd`
- `scripts/shop_ui_controller.gd`
- `scripts/shop_ui.gd`
- `scripts/main_menu.gd`
- `scripts/game_manager.gd`
- `scripts/shop_manager.gd`

### 现有场景改造范围
- `scenes/ui.tscn`
- `scenes/dialogue_manager.tscn`
- `scenes/battle_scene.tscn`
- `scenes/shop_ui.tscn`
- `scenes/main_menu.tscn`

### 规划新增文件
- `scripts/core/ui_router.gd`
- `scripts/core/input_router.gd`
- `scripts/ui/hud_screen.gd`
- `scripts/ui/inventory_screen.gd`
- `scripts/ui/journal_screen.gd`
- `scripts/ui/character_screen.gd`
- `scripts/ui/dialogue_screen.gd`
- `scripts/ui/shop_screen.gd`
- `scripts/ui/battle_screen.gd`
- `scenes/ui/hud_screen.tscn`
- `scenes/ui/inventory_screen.tscn`
- `scenes/ui/journal_screen.tscn`
- `scenes/ui/character_screen.tscn`
- `scenes/ui/dialogue_screen.tscn`
- `scenes/ui/shop_screen.tscn`
- `scenes/ui/battle_screen.tscn`

### 验收标准
- `Esc` 不会在同一帧同时触发暂停和关闭界面。
- 背包、商店、战斗、对话、任务日志都能通过统一路由打开和关闭。
- 旧版商店 UI 被明确标记为待删除。

## Phase 6 - 世界层、地图规则与交互源抽象

### 目标
为细粒度移动 + TileMap + 高差 + 边界阻挡打地基。

### 任务
- 定义 `MapDefinition` 与地图元数据结构。
- 引入 `MapService`、`MovementService`、`CollisionService`、`ElevationService`。
- 让玩家和敌人共用地图通行查询。
- 用 `InteractionSource` 替代“NPC 顺手就能开商店/发任务”的模式。
- 按 `map_id` 管理敌人和交互点的状态。

### 现有文件改造范围
- `scripts/utils.gd`
- `scripts/player.gd`
- `scripts/enemy.gd`
- `scripts/npc.gd`
- `scripts/main.gd`
- `scripts/enemy_manager.gd`
- `scenes/main.tscn`
- `scenes/world_map.tscn`
- `scenes/world_tilemap.tscn`
- `scenes/player.tscn`
- `scenes/enemies/slime.tscn`
- `scenes/enemies/skeleton.tscn`
- `scenes/npcs/villager.tscn`
- `scenes/npcs/merchant.tscn`

### 规划新增文件
- `scripts/world/map_service.gd`
- `scripts/world/map_runtime.gd`
- `scripts/world/movement_service.gd`
- `scripts/world/collision_service.gd`
- `scripts/world/elevation_service.gd`
- `scripts/world/spawn_service.gd`
- `scripts/world/interaction_source.gd`
- `scripts/world/interaction_registry.gd`
- `scenes/world/world_root.tscn`
- `scenes/interaction/shop_source.tscn`
- `scenes/interaction/quest_board_source.tscn`
- `scenes/interaction/story_trigger.tscn`

### 验收标准
- 主场景不再依赖“找到第一个 tilemap 组节点就开始判定”。
- 玩家和敌人移动都通过同一套地图规则。
- 高差、边界阻挡未来可以直接接入，而不用再次重写移动架构。

## Phase 7 - 任务与商店领域重构

### 目标
把任务和商店从 NPC 脚本里解耦出来，并准备任务日志界面。

### 任务
- 引入 `QuestService` 和 `ShopService`。
- 引入 `JournalScreen` 或角色界面的任务页。
- 把任务接取、提交和奖励流程改成来源驱动。
- 把商店打开逻辑改成 `shop_id` 驱动。
- 背包交易统一走新的内容定义和状态层。

### 现有文件改造范围
- `scripts/quest_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/npc.gd`
- `scripts/ui.gd`
- `scripts/shop_ui_controller.gd`
- `scripts/shop_ui.gd`
- `resources/data/quests_data.gd`
- `resources/data/items_data.gd`

### 现有场景改造范围
- `scenes/npcs/villager.tscn`
- `scenes/npcs/merchant.tscn`
- `scenes/shop_ui.tscn`

### 规划新增文件
- `scripts/progression/quest_service.gd`
- `scripts/progression/shop_service.gd`
- `scripts/progression/reward_service.gd`
- `scripts/ui/journal_screen.gd`
- `scripts/ui/shop_screen.gd`
- `resources/data/shops/`
- `resources/data/quests/`

### 验收标准
- 任务可由 NPC、任务板、剧情或触发点统一发放。
- 商店可由不同交互源打开，但仍使用统一 UI。
- 玩家可从统一界面查看已接和已完成任务。

## Phase 8 - 队伍制战斗核心

### 目标
把战斗重构为“会话驱动 + 队伍制”的底层结构。

### 任务
- 引入 `CombatantState`、`BattleSession`、`BattleResolver`、`TargetingService`、`EncounterService`。
- 把防御、冷却、日志、回合、奖励结算集中到战斗会话中。
- 去掉“单玩家 + 单敌人”写死假设。
- 让战斗界面只展示战斗会话快照。

### 现有文件改造范围
- `scripts/battle_manager.gd`
- `scripts/battle_scene.gd`
- `scripts/player.gd`
- `scripts/enemy.gd`
- `scripts/skill_manager.gd`
- `scripts/inventory_manager.gd`

### 现有场景改造范围
- `scenes/battle_scene.tscn`

### 规划新增文件
- `scripts/battle/battle_session.gd`
- `scripts/battle/battle_resolver.gd`
- `scripts/battle/encounter_service.gd`
- `scripts/battle/targeting_service.gd`
- `scripts/battle/combatant_state.gd`
- `scripts/battle/action_definition.gd`
- `scripts/ui/battle_screen.gd`
- `resources/data/encounters/`

### 验收标准
- 防御真实参与伤害结算。
- 技能冷却按统一规则推进。
- 战斗 UI 由战斗状态驱动，而不是手工补调用。
- 未来加入队友时，不需要重写战斗内核。

## Phase 9 - 剧情系统与结局解析

### 目标
建立独立剧情领域，支持局部分支与 flag 决定结局。

### 任务
- 引入 `StoryService`、`StoryState`、`StorySegmentDefinition`、`EndingResolver`。
- 把普通对话展示和剧情推进逻辑拆开。
- 把剧情相关动作接到统一 `ActionExecutor`。
- 建立剧情旗标命名规范。

### 现有文件改造范围
- `scripts/dialogue_manager.gd`
- `scripts/npc.gd`
- `resources/dialogues/default_npc_dialogue.gd`
- `resources/dialogues/merchant_dialogue.gd`

### 规划新增文件
- `scripts/narrative/story_service.gd`
- `scripts/narrative/story_state.gd`
- `scripts/narrative/ending_resolver.gd`
- `scripts/narrative/dialogue_presenter.gd`
- `resources/data/story/`
- `resources/dialogue/`

### 验收标准
- 局部分支和全局 flag 可以同时存在。
- 结局由状态和旗标计算，而不是某一个临时选择决定。

## Phase 10 - 二周目规则层

### 目标
在不破坏现有一周目逻辑的前提下，为二周目准备扩展层。

### 任务
- 引入 `CycleService`。
- 定义继承规则与重置规则。
- 让 `ConditionSet` 支持 `min_cycle`、`max_cycle` 等周目条件。
- 为剧情、任务、商店、地图和遭遇内容预留周目差分能力。

### 现有文件改造范围
- `scripts/game_manager.gd`
- `scripts/constants.gd`
- `scripts/main_menu.gd`
- `scripts/quest_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/battle_manager.gd`
- `resources/data/quests_data.gd`
- `resources/data/skills_data.gd`

### 规划新增文件
- `scripts/progression/cycle_service.gd`
- `scripts/progression/carry_over_policy.gd`
- `scripts/progression/cycle_condition_service.gd`
- `scripts/ui/cycle_summary_screen.gd`

### 验收标准
- 内容可通过统一条件表达一周目限定或二周目限定。
- 周目切换不需要在多个系统里各自写特殊分支。

## Phase 11 - 冗余清理与兼容层下线

### 目标
在新路径稳定后，删除旧版实现和多余中间层。

### 任务
- 删除旧版商店 UI。
- 删除被新服务和状态层取代的旧管理器。
- 合并重复常量和辅助函数。
- 清理不再权威的数据文件。
- 更新 autoload 配置。

### 预计删除或大幅缩减的文件
- `scripts/shop_ui.gd`
- `scripts/game_manager.gd`
- `scripts/inventory_manager.gd`
- `scripts/battle_manager.gd`
- `scripts/quest_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/enemy_manager.gd`
- `scripts/dialogue_manager.gd`
- `scripts/skill_manager.gd`
- `scripts/utils.gd`

### 需要同步更新的文件
- `project.godot`
- `README.md`
- 所有引用旧脚本的场景文件

### 验收标准
- 可以清晰回答“某个逻辑现在应该去哪里改”。
- 旧脚本不是被删掉，就是明确标记为临时兼容层。

## Phase 12 - 回归保障、文档与测试

### 目标
让重构后的项目能稳定继续演进，而不是再次回到“只能靠手工猜”的状态。

### 任务
- 建立最小测试策略。
- 记录模块职责文档。
- 更新 README。
- 补充手动冒烟流程，覆盖：
  - 新游戏
  - 背包打开/使用/装备
  - 商店买卖
  - 任务接取/推进/提交
  - 战斗五种操作
  - 存档/读档
  - 剧情 flag 变化
  - 周目切换准备流程

### 需要新增或更新的文件
- `README.md`
- `test/`
- `addons/` 下的测试框架接入文件（如果引入）
- 后续可新增 `docs/` 或根目录架构说明文件

### 验收标准
- 后续功能开发不需要重新摸索架构边界。
- 新加剧情、二周目、地图规则、队友战斗时有明确接入点。

## 5. 推荐执行顺序摘要

1. Phase 0：冻结基线，明确风险。
2. Phase 1：统一内容定义，不先碰大规模玩法逻辑。
3. Phase 2：拆状态层，先让数据归位。
4. Phase 3：统一存档读档，消除最危险的状态错乱。
5. Phase 4：建立条件与动作底座，为未来功能铺路。
6. Phase 5：清理 UI 和输入归属。
7. Phase 6：搭建世界与地图规则底层。
8. Phase 7：重构任务与商店。
9. Phase 8：重构战斗为队伍制底座。
10. Phase 9：接入剧情与结局系统。
11. Phase 10：接入二周目规则。
12. Phase 11：删除冗余实现。
13. Phase 12：补齐文档和测试。

## 6. 实施时的原则

- 不做一次性推倒重来，每个阶段结束后项目都应保持可运行。
- 先建新路径，再迁移调用，再删除旧路径。
- 先统一数据，再改状态，再动 UI 和场景。
- 每次只重构一个清晰边界的领域，避免多系统同时改崩。
- 所有新逻辑先放到目标目录，不继续往旧管理器里补功能。

## 7. 启动实施时的第一步

真正开始写代码时，优先进入 Phase 1，不要先改战斗、地图或 UI。
原因很简单：如果内容定义和状态模型还没统一，后面对战斗、剧情、商店、任务和地图做的任何重构，都还会再次碰到同样的数据结构问题。
