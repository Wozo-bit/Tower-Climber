class_name ItemLibrary
extends RefCounted
## All consumables. Prices/amounts are placeholders.

static var _items: Dictionary = _build()

## What the rest-floor merchant sells.
## Goddess Tears are deliberately pricey here; bosses drop them for free.
const SHOP_STOCK := [&"potion", &"advanced_potion", &"ether", &"goddess_tear"]


static func _build() -> Dictionary:
	var list: Array[ItemDef] = [
		ItemDef.make(&"potion", "Potion", "Restores 80 HP to one ally.", {"heal_hp": 80, "price": 40}),
		ItemDef.make(&"advanced_potion", "Advanced Potion", "Restores 200 HP to one ally.", {"heal_hp": 200, "price": 110}),
		ItemDef.make(&"ether", "Ether", "Restores 25 MP to one ally.", {"restore_mp": 25, "price": 90}),
		ItemDef.make(&"goddess_tear", "Goddess Tear",
			"Revives a downed ally with 30% HP. Rare — bosses drop them.",
			{"revive_hp_pct": 0.3, "price": 1500}),
	]
	# One skill book per learnable skill: "Skill Book: Power Strike", etc.
	for s in SkillLibrary.learnable_skills():
		list.append(ItemDef.make(SkillBooks.book_item_id(s.id), "Skill Book: %s" % s.display_name,
			"[%s] Teaches %s: %s" % [SkillTier.name_of(s.tier), s.display_name, s.description],
			{"teaches_skill": s.id, "tier": s.tier, "price": 0}))
	var d := {}
	for i in list:
		d[i.id] = i
	return d


static func get_item(id: StringName) -> ItemDef:
	return _items.get(id)
