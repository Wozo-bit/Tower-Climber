class_name BattleSfx
extends RefCounted
## Which sound a battle action makes: one per action, for the most dramatic
## thing that happened in it. Returns a fallback list for Audio.play_sfx, so
## element sounds ("hit_fire") are used when they exist, else the plain ones.
##
## Sound names: down_ally, down_enemy, stagger, crit, weak, hit, hit_<element>,
## resist, absorb, immune, heal, miss, status, scan, staggered, defend, item.

const PRIORITY := ["down_ally", "down_enemy", "stagger", "crit", "weak", "hit", "resist", "absorb", "immune",
	"heal", "miss", "status", "scan", "staggered"]
## These fall back to the plain "hit" sound.
const HIT_LIKE := ["down_ally", "down_enemy", "stagger", "crit", "weak"]
## These try the element's sound first.
const ELEMENTAL := ["stagger", "crit", "weak", "hit"]


static func names(result: Dictionary) -> Array:
	var kinds := {}
	for e in result.get("entries", []):
		if e.kind == "damage":
			kinds["stagger" if e.get("staggered", false) else ("crit" if e.get("crit", false) else
				("weak" if e.get("weak", false) else ("resist" if e.get("resisted", false) else "hit")))] = true
			var target: Combatant = e.get("target")
			if target and not target.is_alive():
				kinds["down_ally" if target.side == Combatant.Side.PARTY else "down_enemy"] = true
		else:
			kinds[e.kind] = true
	var out := []
	var skill: SkillDef = result.get("skill")
	for k in PRIORITY:
		if not kinds.has(k):
			continue
		if k in ELEMENTAL and skill and not skill.elements.is_empty():
			out.append("hit_%s" % Element.name_of(skill.elements[0]).to_lower())
		out.append(k)
		if k in HIT_LIKE:
			out.append("hit")
		break
	if result.get("type") == BattleAction.Type.DEFEND:
		out.append("defend")
	elif result.get("type") == BattleAction.Type.ITEM:
		out.push_front("item")
	return out
