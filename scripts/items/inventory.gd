class_name Inventory
extends Resource
## Party-wide bag of consumables: item id -> count. Emits Resource.changed on edits.


@export var counts: Dictionary = {}
## Unequipped gear. Each piece is its own instance (stats are rolled per drop).
@export var gear: Array[GearItem] = []


func add_gear(item: GearItem) -> void:
	if item:
		gear.append(item)
		emit_changed()


func remove_gear(item: GearItem) -> bool:
	var i := gear.find(item)
	if i < 0:
		return false
	gear.remove_at(i)
	emit_changed()
	return true


func count(id: StringName) -> int:
	return counts.get(id, 0)


## Adds up to the item's carry limit (if it has one). Returns how many were added.
func add(id: StringName, amount: int = 1) -> int:
	var item := ItemLibrary.get_item(id)
	if item and item.max_carry > 0:
		amount = clampi(item.max_carry - count(id), 0, amount)
	if amount <= 0:
		return 0
	counts[id] = count(id) + amount
	emit_changed()
	return amount


## True if one more fits under the item's carry limit.
func has_room(id: StringName) -> bool:
	var item := ItemLibrary.get_item(id)
	return item == null or item.max_carry <= 0 or count(id) < item.max_carry


func remove(id: StringName, amount: int = 1) -> bool:
	if count(id) < amount:
		return false
	counts[id] = count(id) - amount
	if counts[id] <= 0:
		counts.erase(id)
	emit_changed()
	return true


## Items with count > 0, as ItemDefs, in a stable order.
func owned() -> Array[ItemDef]:
	var out: Array[ItemDef] = []
	var ids := counts.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))   # by name (StringNames sort by address)
	for id in ids:
		if count(id) > 0:
			out.append(ItemLibrary.get_item(id))
	return out


## Use an item on a character outside battle. Returns false if it would do nothing.
func use_on_character(id: StringName, target: CharacterData) -> bool:
	var item := ItemLibrary.get_item(id)
	if item == null or count(id) <= 0:
		return false
	if item.is_skill_book():
		if not target.learn_skill(item.teaches_skill):
			return false
		remove(id)
		return true
	if item.is_revive():
		if not target.revive(roundi(target.max_hp() * item.revive_hp_pct)):
			return false
		remove(id)
		return true
	if target.is_downed():
		return false
	var useful := (item.heal_hp > 0 and target.current_hp() < target.max_hp()) \
		or (item.restore_mp > 0 and target.current_mp() < target.max_mp())
	if not useful:
		return false
	target.heal(item.heal_hp)
	target.restore_mp(item.restore_mp)
	remove(id)
	return true
