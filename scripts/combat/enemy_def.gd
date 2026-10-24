class_name EnemyDef
extends Resource
## A hand-designed enemy type. Enemies use the same StatBlock math as players,
## but HP is set directly so fights can be tuned per enemy.

@export var id: StringName
@export var display_name: String
@export var max_hp: int = 100
@export var stats: Dictionary = {}          # Stats.Type -> int (unlisted stats = 5)
@export var row: int = 0                    # Combatant.Row (0 = FRONT, 1 = BACK)
@export var basic_attack: StringName = &"attack_melee"
@export var skills: Array[StringName] = []
## Chance (0-1) the AI uses a skill instead of its basic attack when it can.
@export var skill_chance: float = 0.35
@export var xp_reward: int = 20
@export var gold_reward: int = 5
@export var color: Color = Color.GRAY   # placeholder "sprite" colour
## Bosses: can't be fled from.
@export var is_boss: bool = false
## Item drops rolled on victory: [{ "item": StringName, "chance": float (0-1), "count": int }]
@export var drops: Array = []
## Random gear pieces rolled on victory (rarity scales with the party's Luck).
@export var loot_rolls: int = 0
## Minibosses stand guard in front of the stairs instead of wandering.
@export var is_miniboss: bool = false
## Roaming bosses: lore bosses loose on lower floors. They wander, and you CAN flee.
@export var is_roaming: bool = false
## Hide this enemy's planned move from the player ("Intent: ???").
@export var hide_intent: bool = false
@export_multiline var lore: String = ""
## EnemyFamilies id: shared weaknesses, resistances and traits.
@export var family: StringName = &""
## Element.Type -> Element.Affinity overrides on top of the family's.
@export var affinities: Dictionary = {}
## Extra traits on top of the family's (EnemyFamilies.TRAITS ids).
@export var traits: Array[StringName] = []

# --- Loot profile (only matters if loot_rolls > 0) ---
## Added to the party's Luck for this enemy's rarity rolls.
@export var loot_luck_bonus: int = 0
## Drops are never worse than this tier.
@export var min_loot_rarity: int = 0        # Rarity.Tier
## Chance (0-1) that ONE of the loot rolls is a Unique weapon instead.
## Only floor bosses and roaming bosses should have this. Luck boosts it a little.
@export var unique_chance: float = 0.0


static func make(p_id: StringName, p_name: String, props: Dictionary) -> EnemyDef:
	var e := EnemyDef.new()
	e.id = p_id
	e.display_name = p_name
	for key in props:
		e.set(key, props[key])
	return e
