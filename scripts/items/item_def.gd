class_name ItemDef
extends Resource
## A consumable item. Usable in battle (Items command) and on the floor
## (party menu). Targets one living ally.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var heal_hp: int = 0
@export var restore_mp: int = 0
## Revive items: only usable on a DOWNED ally; brings them back at this % of max HP.
@export_range(0.0, 1.0, 0.05) var revive_hp_pct: float = 0.0
@export var price: int = 0
## Skill books: teaches this shared skill when used on a character (out of battle).
@export var teaches_skill: StringName = &""
@export var tier: int = 0   # SkillTier, for books


func is_skill_book() -> bool:
	return teaches_skill != &""


func is_revive() -> bool:
	return revive_hp_pct > 0.0


static func make(p_id: StringName, p_name: String, p_desc: String, props: Dictionary) -> ItemDef:
	var i := ItemDef.new()
	i.id = p_id
	i.display_name = p_name
	i.description = p_desc
	for key in props:
		i.set(key, props[key])
	return i
