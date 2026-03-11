extends RefCounted

@export var skills_database: Dictionary = SkillCatalog.new().load_definitions()
