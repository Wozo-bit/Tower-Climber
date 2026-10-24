class_name Combatant
extends RefCounted
## A unit inside one battle. Built from a CharacterData (party) or an
## EnemyDef (enemy). HP/MP/statuses live here only for the fight.

enum Side { PARTY, ENEMY }
enum Row { FRONT, BACK }

const EVASIVE_DODGE_BONUS := 0.3

## Placeholder "sprite" colours for party members until real art exists.
const CLASS_COLORS := {
	&"tank": Color(0.55, 0.6, 0.7),
	&"mage": Color(0.55, 0.35, 0.85),
	&"archer": Color(0.3, 0.65, 0.4),
	&"rogue": Color(0.35, 0.3, 0.35),
	&"support": Color(0.9, 0.85, 0.6),
	&"ashbound_knight": Color(0.85, 0.4, 0.2),
	&"ascendant": Color(0.95, 0.95, 1.0),
}

var display_name: String
var side: int = Side.PARTY
var row: int = Row.FRONT
var stats: StatBlock
var max_hp: int
var hp: int
var max_mp: int
var mp: int
var basic_attack: SkillDef
var skills: Array[SkillDef] = []
var statuses: Dictionary = {}   # StringName -> turns remaining
var ai_controlled := false
var skill_chance := 0.0         # AI only
var color := Color(0.6, 0.6, 0.7)

var source_character: CharacterData
var source_enemy: EnemyDef

# --- Elements, traits, stagger ---
## Element.Type -> Element.Affinity (enemies, from their family). Party: none yet.
var affinities: Dictionary = {}
var traits: Array[StringName] = []
## Physical attacks use this kind (Slash/Pierce/Blunt), -1 = none (enemies).
var weapon_kind := -1
## Elemental weapon: added to basic attacks. -1 = none.
var weapon_element := -1
## Weakness hits fill this; at stagger_max the unit loses its next turn.
var stagger := 0
var stagger_max := STAGGER_HITS
## Set when the meter fills; the unit skips its next turn, then it clears.
var staggered := false
## Who damaged it last (Easily distracted enemies go after them).
var last_attacker: Combatant
## Gelatinous: has it already softened a physical hit this round?
var gel_used := false

## Weakness hits to stagger a normal enemy / a boss or miniboss. After each
## stagger it takes STAGGER_GROWTH more, so a boss can't be stun-locked.
const STAGGER_HITS := 2
const STAGGER_HITS_BOSS := 4
const STAGGER_GROWTH := 1


static func from_character(c: CharacterData) -> Combatant:
	var u := Combatant.new()
	u.display_name = c.character_name
	u.side = Side.PARTY
	u.source_character = c
	u.stats = c.stats
	u.max_hp = c.max_hp()
	u.hp = c.current_hp()   # HP/MP carry over between battles
	u.max_mp = c.max_mp()
	u.mp = c.current_mp()
	u.basic_attack = SkillLibrary.basic_attack_for_class(c.class_id)
	u.skills = c.all_skills()   # class skills + learned shared skills
	u.row = c.battle_row if c.battle_row >= 0 else SkillLibrary.default_row_for_class(c.class_id)
	u.skill_chance = 0.4
	u.color = CLASS_COLORS.get(c.class_id, Color(0.75, 0.7, 0.65))
	var weapon := c.get_equipped(GearItem.Slot.WEAPON)
	u.weapon_kind = weapon.weapon_kind() if weapon else Element.Type.BLUNT   # fists are blunt
	u.weapon_element = weapon.element if weapon else -1
	return u


## `scale` multiplies HP and every stat — used to make enemies tougher on higher floors.
static func from_enemy(def: EnemyDef, scale: float = 1.0) -> Combatant:
	var u := Combatant.new()
	u.display_name = def.display_name
	u.side = Side.ENEMY
	u.source_enemy = def
	u.stats = StatBlock.new()
	for stat in Stats.all():
		u.stats.base[stat] = maxi(1, roundi(def.stats.get(stat, Stats.BASE_VALUE) * scale))
	u.max_hp = maxi(1, roundi(def.max_hp * scale))
	u.hp = u.max_hp
	u.max_mp = u.stats.max_mp()
	u.mp = u.max_mp
	u.basic_attack = SkillLibrary.get_skill(def.basic_attack)
	for sid in def.skills:
		u.skills.append(SkillLibrary.get_skill(sid))
	u.row = def.row
	u.ai_controlled = true
	u.skill_chance = def.skill_chance
	u.color = def.color
	u.affinities = EnemyFamilies.affinities_for(def)
	u.traits = EnemyFamilies.traits_for(def)
	u.stagger_max = (STAGGER_HITS_BOSS if def.is_boss or def.is_roaming else STAGGER_HITS) \
		+ (1 if u.has_trait(&"thick_skulled") else 0)
	return u


func has_trait(id: StringName) -> bool:
	return traits.has(id)


## One weakness hit. Returns true if that filled the meter (staggered).
func add_stagger() -> bool:
	if staggered or not is_alive():
		return false
	stagger += 1
	if stagger < stagger_max:
		return false
	stagger = 0
	stagger_max += STAGGER_GROWTH
	staggered = true
	return true


func is_alive() -> bool:
	return hp > 0


func has_status(id: StringName) -> bool:
	return statuses.has(id)


func add_status(id: StringName, turns: int) -> void:
	statuses[id] = maxi(statuses.get(id, 0), turns)


## Called at the start of this unit's turn.
func tick_statuses() -> void:
	for id in statuses.keys():
		statuses[id] -= 1
		if statuses[id] <= 0:
			statuses.erase(id)


func dodge_chance() -> float:
	var d := stats.dodge_chance()
	if has_status(&"evasive"):
		d += EVASIVE_DODGE_BONUS
	return minf(d, 0.8)


func crit_chance() -> float:
	return stats.crit_chance()


## Set by the Guard skill: this unit is protected by `guarded_by` until the
## guardian's next turn (the guardian has the "guarding" status).
var guarded_by: Combatant


func active_guardian() -> Combatant:
	if guarded_by and guarded_by.is_alive() and guarded_by.has_status(&"guarding"):
		return guarded_by
	return null


func can_afford(skill: SkillDef) -> bool:
	return mp >= skill.mp_cost


func take_damage(amount: int) -> int:
	var dealt := mini(amount, hp)
	hp -= dealt
	return dealt


## Brings a downed unit back. It rejoins the turn order next round.
func revive(amount: int) -> bool:
	if is_alive():
		return false
	hp = clampi(amount, 1, max_hp)
	statuses.clear()
	return true


func restore_hp(amount: int) -> int:
	var healed := mini(amount, max_hp - hp)
	hp += healed
	return healed


func row_name() -> String:
	return "Front" if row == Row.FRONT else "Back"
