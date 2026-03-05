# AGENTS.md - RPG Game Development Guide

## Project Overview
- **Engine**: Godot 4.6
- **Language**: GDScript
- **Renderer**: Forward Plus
- **Physics**: Jolt Physics (3D)
- **Platform**: Windows (D3D12)

---

## Build & Run Commands

### Running the Game
```bash
# Open in Godot Editor
godot

# Run directly (headless/server mode)
godot --headless --script my_script.gd
```

### Exporting
```bash
godot --headless --export-release "Windows" output/game.exe
```

### Running Tests
Godot 4.x uses GUT (Godot Unit Test) framework for testing:
```bash
# Install GUT from Asset Library first, then:
godot --headless --script res://addons/gut/gut_cmdln.gd -gdir=res://test/

# Run specific test file
godot --headless --script res://addons/gut/gut_cmdln.gd -gtest=res://test/test_player.gd
```

---

## Code Style Guidelines

### General Principles
- Follow Godot's official GDScript style guide
- Keep code concise and readable
- Use built-in GDScript features (type hints, annotations)

### Formatting
- **Indentation**: 4 spaces (Godot default)
- **Line length**: Maximum 120 characters
- **File encoding**: UTF-8

```gdscript
func move_player(direction: Vector3, speed: float) -> void:
    velocity = direction * speed
    move_and_slide()
```

### Naming Conventions
- **Classes**: PascalCase (`PlayerController`)
- **Functions**: snake_case (`get_player_data`)
- **Variables**: snake_case (`current_health`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_HEALTH`)
- **Enums**: PascalCase enum, UPPER_SNAKE_CASE values
- **Signals**: past tense (`damage_taken`)

```gdscript
const MAX_HEALTH: int = 100
enum ItemType { WEAPON, ARMOR, CONSUMABLE }

class_name PlayerController
extends CharacterBody3D
signal health_changed(new_health: int)
```

### Type Hints
- **Always use type hints** for variables, parameters, and return types
- Use inference (`:=`) only for local variables when type is obvious

```gdscript
var player_name: String = "Hero"
var enemies: Array[Enemy] = []

func take_damage(amount: int) -> void:
    current_health -= amount
```

### Imports & Autoloads
- Use Godot's autoload system for global singletons
- Define autoloads in `project.godot` under `[autoload]`
- Use `preload()` for static resources

```gdscript
var gold: int = GameManager.gold
var player_scene := preload("res://scenes/player.tscn")
```

### Error Handling
- Use `assert()` for development checks
- Use `push_error()` and `push_warning()` for runtime issues

```gdscript
assert(player.is_inside_tree(), "Player must be in scene tree")
if item.is_empty():
    push_warning("Inventory is empty")
    return
```

### GDScript Patterns

#### Export Variables
```gdscript
@export_category("Movement")
@export var move_speed: float = 5.0
@export_group("Combat")
@export var damage: int = 10
```

#### Node References
```gdscript
@onready var animation_player := $AnimationPlayer
@export var spawn_point: Node3D
```

---

## Project Structure

```
rpg_game/
├── addons/              # Godot addons (GUT testing, etc.)
├── assets/              # Raw assets
│   ├── audio/
│   ├── textures/
│   └── models/
├── resources/           # Godot resources (.tres files)
├── scenes/              # Scene files (.tscn)
├── scripts/             # GDScript files (.gd)
├── test/                # Unit tests
├── project.godot        # Project configuration
└── README.md
```

---

## Best Practices

1. **Scene Composition**: Use composition over inheritance
2. **Singletons**: Use autoloads for game managers, not static classes
3. **Resources**: Use `.tres` files for shared data (items, stats)
4. **Groups**: Use groups for organizing related nodes
5. **Documentation**: Add brief docstrings to classes and complex functions
6. **Performance**: Use `call_deferred()` for tree modifications, avoid frequent `get_node()` calls in `_process()`, use static typing for performance-critical code
