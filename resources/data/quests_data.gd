extends RefCounted

@export var quest_database: Dictionary = QuestCatalog.new().load_definitions()
