class_name SkillDef
extends Resource
## A combat action: basic attacks, class skills and enemy moves all use this.

## GUARD: the user steps in front of an ally and takes single-target hits for
## them until the user's next turn. RESTORE_MP: restores `power` x max MP.
## SUMMON: calls `summon_id` (an EnemyLibrary "spirit" def) onto the user's
## side for the rest of the fight (one per summoner; recasting refreshes it).
enum Effect { DAMAGE, HEAL, STATUS, GUARD, RESTORE_MP, SUMMON }
## MELEE is affected by rows. RANGED and MAGIC ignore rows.
## MELEE and RANGED can be dodged; MAGIC cannot.
enum DamageType { MELEE, RANGED, MAGIC }
enum Targeting { ENEMY_SINGLE, ENEMY_ALL, ALLY_SINGLE, ALLY_ALL, SELF }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var mp_cost: int = 0
## Miracles: paid from the god's faith (DivinityState) instead of MP.
@export var faith_cost: int = 0
@export var effect: Effect = Effect.DAMAGE
@export var damage_type: DamageType = DamageType.MELEE
@export var targeting: Targeting = Targeting.ENEMY_SINGLE
## Multiplier on the attacker's power (damage or heal).
@export var power: float = 1.0
## Melee skill that can reach a protected back row (e.g. Backstab).
@export var ignores_row: bool = false
## Fraction of target defense ignored (0.0-1.0).
@export var def_pierce: float = 0.0
## Added to the attacker's crit chance for this skill.
@export var bonus_crit: float = 0.0
## Adaptive skills hit with Strength (physical) or Intelligence (magic),
## whichever is higher for the user. They ignore rows.
@export var adaptive: bool = false
## HEAL skills also restore this fraction of the target's max HP (so they stay
## useful for low-Intelligence characters).
@export var heal_pct_max_hp: float = 0.0
## Shared skills anyone can learn (level-up picks or skill books). Class skills
## and enemy-only moves are not learnable.
@export var learnable: bool = false
@export var tier: int = 0   # SkillTier.Tier, for learnable skills
## Element.Type values this skill hits with. Physical (melee/ranged) skills
## with no weapon kind here (Slash/Pierce/Blunt) use the attacker's weapon's kind.
@export var elements: Array[int] = []
## Status applied by STATUS skills (or as a rider on others).
@export var status_id: StringName = &""
@export var status_turns: int = 0
## SUMMON skills: the EnemyDef id called onto the field.
@export var summon_id: StringName = &""


static func make(p_id: StringName, p_name: String, p_desc: String, props: Dictionary = {}) -> SkillDef:
	var s := SkillDef.new()
	s.id = p_id
	s.display_name = p_name
	s.description = p_desc
	for key in props:
		s.set(key, props[key])
	return s


func is_single_target() -> bool:
	return targeting == Targeting.ENEMY_SINGLE or targeting == Targeting.ALLY_SINGLE


func targets_enemies() -> bool:
	return targeting == Targeting.ENEMY_SINGLE or targeting == Targeting.ENEMY_ALL


func targets_allies() -> bool:
	return targeting == Targeting.ALLY_SINGLE or targeting == Targeting.ALLY_ALL
