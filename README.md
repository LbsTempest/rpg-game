# RPG 游戏框架

一个使用 Godot 4.6 开发的 2D 像素风格 RPG 游戏框架，包含完整的角色系统、战斗系统、对话系统和 AI 系统。

![Godot Version](https://img.shields.io/badge/Godot-4.6-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 功能特性

### 核心系统
- **平滑移动系统**：基于物理的角色移动，支持 8 方向行走，松开按键立即停止
- **属性系统**：HP/MP、攻击力、防御力、等级、经验值
- **装备系统**：武器、护甲、饰品三个装备槽，提供属性加成
- **物品系统**：支持堆叠、消耗品使用、装备穿戴
- **存档系统**：JSON 格式存档/读档，保存角色状态、位置、物品栏

### 战斗系统
- **回合制战斗**：玩家与敌人轮流行动
- **行动选择**：攻击、防御、技能、物品、逃跑
- **AI 系统**：3 种敌人类型（普通、攻击型、防御型），支持血量判断和逃跑
- **战斗奖励**：击败敌人获得经验值和金币

### 敌人 AI
- **游荡模式**：敌人在出生点周围随机游荡
- **追击模式**：检测玩家进入范围后开始追击
- **战斗触发**：靠近敌人自动进入战斗
- **距离配置**：可配置检测范围、追击范围、游荡半径

### 对话系统
- **鼠标点击推进**：单击画面任意位置推进对话
- **分支选项**：支持多分支对话，鼠标点击选项选择
- **键盘支持**：Enter/Space 键也可推进对话
- **NPC 游荡**：NPC 在指定范围内随机走动，对话时停止并面向玩家

## 操作说明

### 基础操作
| 按键 | 功能 |
|------|------|
| WASD / 方向键 | 角色移动 |
| I | 打开/关闭物品栏 |
| F5 | 存档 |
| F9 | 读档 |
| Esc | 暂停游戏 |
| Enter / Space | 对话中推进/选择 |
| 鼠标左键 | 对话中推进/点击选项 |

### 战斗操作
- 点击行动按钮选择：攻击、防御、技能、物品、逃跑
- 技能按钮自动使用第一个已学会的技能
- 逃跑成功率 50%

### 物品栏操作
- 点击物品按钮打开物品栏
- 点击物品使用（消耗品）或装备（装备）
- 物品自动堆叠显示

## 项目结构

```
rpg_game/
├── assets/                  # 游戏资源
│   ├── sprites/            # 角色和敌人精灵图
│   │   ├── player/         # 玩家动画帧
│   │   └── enemies/        # 敌人动画帧
│   ├── ui/                 # UI 元素（血条、进度条等）
│   ├── tilesets/           # 瓦片地图素材
│   └── items/              # 物品图标
├── resources/              # 游戏数据资源
│   └── dialogues/          # 对话脚本文件
├── scenes/                 # 场景文件
│   ├── enemies/            # 敌人场景
│   ├── npcs/               # NPC 场景
│   ├── player.tscn         # 玩家场景
│   ├── main.tscn           # 主场景
│   └── ui.tscn             # UI 场景
├── scripts/                # GDScript 脚本
│   ├── player.gd           # 玩家控制
│   ├── enemy.gd            # 敌人 AI
│   ├── npc.gd              # NPC 逻辑
│   ├── battle_manager.gd   # 战斗管理
│   ├── dialogue_manager.gd # 对话管理
│   └── ...
└── project.godot           # Godot 项目配置
```

## 技术栈

- **引擎**: Godot 4.6
- **语言**: GDScript
- **渲染**: 2D Forward+ Renderer
- **物理**: Godot 内置 2D 物理

## 当前游戏内容

### 场景
- **玩家起点**: (128, 128)
- **史莱姆**: (400, 200) - 绿色方块，检测范围 80px
- **骷髅**: (500, 300) - 有精灵动画，检测范围 100px
- **村民**: (600, 400) - 棕色方块，可对话
- **神秘商人**: (300, 250) - 紫色方块，分支对话

### 默认物品
- 生命药水 x3
- 魔法药水 x2
- 铁剑 x1
- 皮甲 x1
- 金币 100

### 技能
- 重斩（ slash ）- 物理攻击
- 火球术（ fireball ）- 魔法攻击

## 如何运行

### 在 Godot 编辑器中运行
1. 克隆仓库
   ```bash
   git clone https://github.com/LbsTempest/rpg-game.git
   cd rpg-game
   ```

2. 使用 Godot 4.6+ 打开 `project.godot`

3. 按 F5 或点击"运行项目"按钮

### 导出游戏
```bash
# Windows
 godot --headless --export-release "Windows Desktop" ./build/rpg_game.exe

# Web
 godot --headless --export-release "Web" ./build/web/index.html
```

## 对话系统使用指南

### 创建简单对话
```gdscript
# 在 NPC 场景中
dialogue_lines = ["你好！", "再见！"]
```

### 创建分支对话
```gdscript
# 在 NPC 场景中
dialogue_data = [
    {"text": "你好！", "type": "normal"},
    {
        "text": "你要去哪里？",
        "type": "branch",
        "options": [
            {"text": "去森林", "next": 2},
            {"text": "去村庄", "next": 3}
        ]
    },
    {"text": "森林很危险！", "type": "normal"},
    {"text": "村庄很安全！", "type": "normal"}
]
```

### 使用外部对话文件
1. 在 `resources/dialogues/` 创建 `.gd` 文件
2. 继承 Node，定义 `dialogue_data` 数组
3. 在 NPC 场景中添加子节点并附加脚本

## 自定义配置

### 调整玩家速度
编辑 `scripts/player.gd`：
```gdscript
@export var move_speed: float = 200.0  # 默认 200 px/s
```

### 调整敌人 AI 范围
编辑敌人场景文件（如 `scenes/enemies/slime.tscn`）：
```gdscript
detection_radius = 80.0   # 检测玩家范围
chase_radius = 150.0      # 追击最大范围
patrol_radius = 100.0     # 游荡范围
```

### 添加新技能
编辑 `scripts/skill_manager.gd`，在 `available_skills` 中添加：
```gdscript
"thunder": {
    "name": "雷击",
    "description": "召唤雷电攻击",
    "mana_cost": 20,
    "damage": 30,
    "target": "enemy",
    "cooldown": 3
}
```

## 开发路线图

### 已完成
- [x] 基础移动和碰撞
- [x] 属性系统和升级
- [x] 物品栏和装备系统
- [x] 回合制战斗
- [x] 敌人 AI（游荡+追击）
- [x] 分支对话系统
- [x] 存档/读档

### 计划中
- [ ] 任务系统
- [ ] 商店系统
- [ ] 更多敌人类型
- [ ] 技能树
- [ ] 地图系统（多场景切换）
- [ ] 音效和背景音乐
- [ ] 粒子特效

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 致谢

- 角色和敌人精灵图：[Sunnyside World](https://danieldiggle.itch.io/sunnyside) by Daniel Diggle
- 开发引擎：[Godot Engine](https://godotengine.org/)

---

**作者**: LbsTempest
**邮箱**: l1641101764@gmail.com
