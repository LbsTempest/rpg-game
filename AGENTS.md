# AGENTS.md - RPG Game Development Guide

## Project Overview
- **Engine**: Godot 4.6
- **Language**: GDScript
- **Type**: 2D Pixel RPG
- **Renderer**: GL Compatibility (2D)
- **Physics**: Godot Built-in 2D Physics
- **Platform**: Windows

---

## Build & Run Commands

### Running the Game
```bash
# Open in Godot Editor
godot

# Run directly from command line (will start from main menu)
godot --path .

# Run specific scene
godot --path . --scene scenes/main.tscn
```

### Exporting
```bash
# Windows Desktop
godot --headless --export-release "Windows Desktop" ./build/rpg_game.exe

# Web
godot --headless --export-release "Web" ./build/web/index.html
```

### Running Tests
No test framework is currently set up. To add tests:
1. Install GUT (Godot Unit Test) from the Asset Library
2. Create test files in `test/` directory
3. Run with: `godot --headless --script res://addons/gut/gut_cmdln.gd -gdir=res://test/`
4. Run single test: `godot --headless --script res://addons/gut/gut_cmdln.gd -gtest=res://test/test_player.gd`

### Checking Compilation
```bash
# Check project imports and compilation
godot --headless --path . --import
```

---

## Code Style Guidelines

### Formatting
- **Indentation**: Tabs (Godot default, do NOT use spaces)
- **Line length**: Maximum 120 characters
- **File encoding**: UTF-8

### Naming Conventions
- **Classes**: PascalCase (`Player`, `BattleManager`)
- **Functions**: snake_case (`take_damage`, `get_save_data`)
- **Variables**: snake_case (`current_health`, `move_speed`)
- **Private variables**: snake_case with underscore prefix (`_direction`, `_facing_direction`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_HEALTH`, `SAVE_FILE_PATH`)
- **Enums**: PascalCase enum name, UPPER_SNAKE_CASE values
- **Signals**: snake_case, descriptive of event (`health_changed`, `died`)

```gdscript
const MAX_STACK_SIZE: int = 99
enum EquipmentSlot { NONE, WEAPON, ARMOR, ACCESSORY }

class_name Player
extends CharacterBody2D
signal health_changed(current: int, maximum: int)
```

### Type Hints
- **Always use type hints** for variables, parameters, and return types
- Use inference (`:=`) only for local variables when type is obvious
- Use typed arrays and dictionaries where possible

```gdscript
var player_name: String = "Hero"
var enemies: Array[Enemy] = []
var item_quantities: Dictionary = {}

func take_damage(amount: int) -> void:
    current_health -= amount
```

### Imports & Autoloads
The project uses these autoloads (defined in `project.godot`):
- `GameManager` - Game state, saving/loading (手动存档/读档)
- `InventoryManager` - Items and equipment
- `BattleManager` - Combat system
- `DialogueManager` - Dialogue UI and logic
- `SkillManager` - Player skills
- `AudioManager` - Sound and music
- `QuestManager` - Quest tracking and objectives
- `ShopManager` - Shop system and trading
- `EnemyManager` - Enemy state persistence

Use `preload()` for static resources:
```gdscript
var player_scene := preload("res://scenes/player.tscn")
var save_data := {
    "player": get_player_save_data(),
    "inventory": InventoryManager.get_save_data()
}
```

### Error Handling
- Use `assert()` for development checks
- Use `push_error()` and `push_warning()` for runtime issues
- Check node existence before accessing

```gdscript
assert(player.is_inside_tree(), "Player must be in scene tree")

var tilemap: TileMapLayer = get_tree().get_first_node_in_group("tilemap")
if not tilemap:
    push_warning("TileMap not found")
    return
```

### GDScript Patterns

#### Export Variables
```gdscript
@export_category("Stats")
@export var max_health: int = 100
@export var attack: int = 10

@export_category("AI Settings")
@export var ai_type: int = 0
@export var detection_radius: float = 200.0
```

#### Node References
```gdscript
@onready var animated_sprite := $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@export var spawn_point: Node2D
```

#### Class Definition
```gdscript
class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)
signal health_changed(current: int, maximum: int)
```

---

## Project Structure

```
rpg_game/
├── addons/              # Godot addons (GUT testing, etc.)
├── assets/              # Raw assets
│   ├── sprites/        # Character and enemy sprites
│   ├── ui/             # UI elements (health bars, etc.)
│   ├── tilesets/       # Tilemap assets
│   └── items/          # Item icons
├── resources/          # Godot resources (.tres, dialogue scripts)
│   └── dialogues/      # Dialogue data files
├── scenes/             # Scene files (.tscn)
│   ├── enemies/        # Enemy scenes
│   ├── npcs/           # NPC scenes
│   ├── main_menu.tscn  # Main menu (start screen)
│   ├── player.tscn     # Player scene
│   ├── main.tscn       # Main world scene
│   └── ui.tscn         # UI scene
├── scripts/            # GDScript files (.gd)
│   ├── player.gd       # Player controller
│   ├── enemy.gd        # Enemy AI
│   ├── main_menu.gd    # Main menu logic
│   ├── battle_manager.gd   # Combat system
│   ├── battle_scene.gd     # Combat UI
│   ├── inventory_manager.gd
│   ├── shop_manager.gd     # Shop system
│   ├── quest_manager.gd    # Quest system
│   ├── shop_ui.gd          # Shop UI
│   └── ...
├── test/               # Unit tests (empty, needs GUT setup)
├── project.godot       # Project configuration
└── README.md           # Project documentation (Chinese)
```

---

## Data Structure Standards

### Item Data Format (Dictionary)
All items use a standardized Dictionary structure:

```gdscript
{
    "item_id": "iron_sword",           # Unique identifier
    "item_name": "铁剑",                # Display name
    "description": "一把普通的铁剑",     # Description
    "icon_path": "res://assets/items/sword.png",
    "type": "equipment",               # consumable/equipment/key
    "equipment_slot": "weapon",        # weapon/armor/accessory/null
    "price": 100,                      # Buy price
    "sell_price": 50,                  # Sell price (optional)
    "stackable": false,                # Can stack?
    "max_stack": 1,                    # Max stack size
    # Effects
    "effects": {
        "attack": 5,                   # Equipment bonus
        "defense": 0,
        "heal_amount": 0,              # Consumable effect
        "restore_mana": 0
    }
}
```

### Quest Data Format
```gdscript
{
    "id": "quest_001",
    "name": "初出茅庐",
    "description": "击败3个史莱姆",
    "type": "main",                    # main/side/daily
    "status": "active",                # active/completed/rewarded
    "objectives": [
        {
            "type": "kill",            # kill/talk/location/collect
            "target": "slime",
            "required": 3,
            "current": 1
        }
    ],
    "rewards": {
        "experience": 100,
        "gold": 50,
        "items": [{"id": "health_potion", "quantity": 2}]
    }
}
```

### Save Data Format
```json
{
    "version": "1.1",
    "timestamp": 1234567890,
    "current_scene": "main",
    "player": { /* Player stats and position */ },
    "inventory": { /* Items and gold */ },
    "quests": {
        "active_quests": {},
        "completed_quests": [],
        "rewarded_quests": []
    },
    "shop_inventories": { /* Shop stock */ },
    "skills": {
        "learned_skills": [],
        "skill_cooldowns": {}
    }
}
```

---

## Best Practices

1. **Scene Composition**: Use composition over inheritance
2. **Autoloads**: Use for global managers (GameManager, InventoryManager, etc.)
3. **Groups**: Use groups for finding nodes (`"player"`, `"enemies"`, `"ui"`)
4. **Resources**: Use `.tres` files for shared data, `.gd` for dialogue scripts
5. **Pausing**: Use `get_tree().paused` for game pause, `PROCESS_MODE_ALWAYS` for UI
6. **Save System**: JSON-based, manual save/load only (no auto-save)
7. **Comments**: Mixed Chinese/English in codebase - follow existing file's language
8. **Performance**: Use `call_deferred()` for tree modifications, cache node references

---

## Completed Systems

### Core Systems (100% Complete)
- ✅ Main menu with New Game/Load Game/Exit
- ✅ Player movement and collision
- ✅ Turn-based combat with UI
- ✅ Inventory and equipment system
- ✅ Skills with cooldowns
- ✅ Dialogue system with branching
- ✅ Save/Load system (manual)
- ✅ Shop system with buy/sell
- ✅ Quest system with objectives

### Combat Features
- ✅ 5 actions: Attack/Defend/Skill/Item/Flee
- ✅ Skill selection UI (button list)
- ✅ Item usage in battle (consumables only)
- ✅ Enemy AI (3 types)
- ✅ Victory/defeat/flee handling

### Quest Features
- ✅ Objective types: kill/talk/location/collect
- ✅ Progress tracking
- ✅ Rewards (exp/gold/items)
- ✅ Prerequisites support

### Shop Features
- ✅ Independent shop panel
- ✅ Buy/Sell with price rates
- ✅ Infinite/limited stock
- ✅ Persistence in save file
