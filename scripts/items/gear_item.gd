class_name GearItem
extends Resource
## One piece of equipment. Each drop is its own instance with rolled stats.

enum Slot { WEAPON, ARMOR, ACCESSORY }

const SLOT_NAMES := { Slot.WEAPON: "Weapon", Slot.ARMOR: "Armor", Slot.ACCESSORY: "Accessory" }

@export var display_name: String
@export var base_id: StringName
@export var slot: int = Slot.WEAPON
@export var rarity: int = Rarity.Tier.COMMON
@export var bonuses: Dictionary = {}        # Stats.Type -> int
## Unique weapons: only this class can equip it. Empty = anyone.
@export var class_lock: StringName = &""
@export var item_level: int = 1             # floor it dropped on
## Rewards from questlines are earned again each run, so they don't carry into New Game+.
@export var quest_reward: bool = false
@export_multiline var description: String
## Elemental weapons (Element.Type, -1 = none): adds that element to basic attacks.
@export var element: int = -1


static func slot_name(s: int) -> String:
	return SLOT_NAMES.get(s, "?")


## Slash / Pierce / Blunt for weapons (from the base item), -1 for anything else.
func weapon_kind() -> int:
	return LootTable.BASES.get(base_id, {}).get("kind", -1) if slot == Slot.WEAPON else -1


## New Game+ keeps only hard-to-get gear: Uniques that aren't questline rewards.
func carries_into_ng_plus() -> bool:
	return rarity == Rarity.Tier.UNIQUE and not quest_reward


func can_equip(c: CharacterData) -> bool:
	return class_lock == &"" or c.class_id == class_lock


func lock_text() -> String:
	if class_lock == &"":
		return ""
	var def := ClassRegistry.get_class_def(class_lock)
	return "%s only" % (def.display_name if def else String(class_lock))


func total_bonus() -> int:
	var t := 0
	for s in bonuses:
		t += bonuses[s]
	return t


func bonus_text() -> String:
	var parts: PackedStringArray = []
	for s in Stats.all():
		if bonuses.get(s, 0) != 0:
			parts.append("+%d %s" % [bonuses[s], Stats.short_name_of(s)])
	return ", ".join(parts)


## "[Rare] Mithril Bow (+4 AGI, +3 STR)"
func summary() -> String:
	var s := "[%s] %s (%s)" % [Rarity.name_of(rarity), display_name, bonus_text()]
	if slot == Slot.WEAPON:
		s += " · " + Element.name_of(weapon_kind())
		if element >= 0:
			s += " + " + Element.name_of(element)
	if class_lock != &"":
		s += " — " + lock_text()
	return s
