# Game Constants
# Centralized constants for the RPG game
# NOTE: This is an autoload singleton, access via GameConstants (not class_name)

extends Node

# Game Version
const SAVE_VERSION := "3.0"

# Window Settings
const WINDOW_WIDTH := 1920
const WINDOW_HEIGHT := 1080

# Player Settings
const PLAYER_START_HEALTH := 100
const PLAYER_START_MANA := 50
const PLAYER_START_ATTACK := 10
const PLAYER_START_DEFENSE := 5
const PLAYER_START_LEVEL := 1
const PLAYER_START_GOLD := 100

const PLAYER_SPEED := 200.0

# Experience Formula
const EXP_BASE := 100
const EXP_PER_LEVEL := 100

# Level Up Bonuses
const LEVELUP_HEALTH_BONUS := 10
const LEVELUP_MANA_BONUS := 5
const LEVELUP_ATTACK_BONUS := 2
const LEVELUP_DEFENSE_BONUS := 1

# Inventory Settings
const MAX_UNIQUE_ITEMS := 50
const MAX_STACK_SIZE := 99

# Enemy AI Chances
const AI_ATTACK_CHANCE_NORMAL := 0.8
const AI_ATTACK_CHANCE_AGGRESSIVE := 0.9
const AI_ATTACK_CHANCE_DEFENSIVE := 0.6
const AI_FLEE_THRESHOLD := 0.3

# Enemy Settings
const ENEMY_PATROL_RADIUS := 150.0
const ENEMY_DETECTION_RADIUS := 200.0
const ENEMY_CHASE_RADIUS := 300.0
const ENEMY_WANDER_INTERVAL := 2.0
const ENEMY_WANDER_SPEED := 80.0
const ENEMY_PAUSE_TIME := 1.5
const BATTLE_TRIGGER_DISTANCE := 30.0

# NPC Settings
const NPC_WANDER_RADIUS := 80.0
const NPC_WANDER_SPEED := 40.0
const NPC_WANDER_INTERVAL := 3.0
const NPC_PAUSE_TIME := 1.5
const NPC_PAUSE_CHANCE := 0.3

# Combat Settings
const BASE_FLEE_CHANCE := 0.5
const DEFEND_DEFENSE_MULTIPLIER := 2.0
const DEFEND_TEMP_BONUS := 2

# Skill Settings
const SKILL_SLASH_BASE_DAMAGE := 15
const SKILL_FIREBALL_BASE_DAMAGE := 20
const SKILL_HEAL_BASE_AMOUNT := 30

const SKILL_SLASH_ATTACK_RATIO := 0.5
const SKILL_FIREBALL_LEVEL_BONUS := 3
const SKILL_HEAL_LEVEL_BONUS := 2

# Shop Settings
const SHOP_BUY_RATE := 1.0
const SHOP_SELL_RATE := 0.5

# File Paths
const SAVE_FILE_PATH := "user://save_game.json"

# Scene Paths
const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_MAIN := "res://scenes/main.tscn"
const SCENE_BATTLE := "res://scenes/ui/battle_screen.tscn"

# Action Types
const ACTION_ATTACK := "attack"
const ACTION_DEFEND := "defend"
const ACTION_FLEE := "flee"
const ACTION_SKILL := "skill"
const ACTION_ITEM := "item"

# Quest Types
const QUEST_TYPE_MAIN := "main"
const QUEST_TYPE_SIDE := "side"
const QUEST_TYPE_DAILY := "daily"

# Objective Types
const OBJECTIVE_KILL := "kill"
const OBJECTIVE_TALK := "talk"
const OBJECTIVE_COLLECT := "collect"
const OBJECTIVE_LOCATION := "location"

# Equipment Slots
const SLOT_WEAPON := 1
const SLOT_ARMOR := 2
const SLOT_ACCESSORY := 3

# Item Types
const ITEM_TYPE_CONSUMABLE := 0
const ITEM_TYPE_EQUIPMENT := 1
const ITEM_TYPE_KEY := 2

# Shop IDs
const SHOP_MERCHANT := "merchant_shop"

# Quest IDs
const QUEST_FIRST := "quest_first"
const QUEST_MERCHANT := "quest_merchant"

# Default Names (for code use, display names are localized)
const DEFAULT_ENEMY_NAME := "Enemy"
const DEFAULT_NPC_NAME := "NPC"

# Math Constants
const FULL_CIRCLE := 2.0 * PI
