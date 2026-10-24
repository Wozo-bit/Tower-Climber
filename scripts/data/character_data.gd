class_name CharacterData
extends Resource
## A character's progression state: level, XP, stat points, class, respecs.
## Pure data + rules, no UI. Party members/NPCs can reuse this later.

signal stats_changed
signal leveled_up(new_level: int, points_gained: int)
signal class_selection_available
signal class_chosen(def: ClassDef)
signal respecced(was_free: bool, cost: int)

# --- Progression rules ---
const CLASS_UNLOCK_LEVEL := 10
const EARLY_LEVEL_CAP := 5          # level-ups up to and including this level...
const EARLY_POINTS_PER_LEVEL := 5   # ...grant 5 points
const LATE_POINTS_PER_LEVEL := 3    # level 6+ grants 3 points

# --- Shared skill picks ---
const STARTING_SKILL_PICKS := 1
const SKILL_PICK_EVERY := 3        # levels 3, 6, 9, 12, ...

# --- XP curve (placeholder) ---
const XP_BASE := 100
const XP_EXPONENT := 1.5

# --- Respec rules ---
const RESPEC_BASE_COST := 500       # first paid respec
const RESPEC_COST_MULTIPLIER := 2.0 # each paid respec costs this much more

@export var character_name: String = "Climber"
@export var level: int = 1
@export var xp: int = 0
@export var unspent_points: int = 0
@export var stats: StatBlock
@export var class_id: StringName = &""
@export var gold: int = 0
@export var free_respec_pre_class_used: bool = false
@export var free_respec_post_class_used: bool = false
@export var paid_respec_count: int = 0
## Battle row (Combatant.Row). -1 = use the class default. Saved when changed in battle.
@export var battle_row: int = -1
## HP/MP carry over between battles. Stored as "missing" amounts so that
## raising Health/Intelligence raises current HP/MP along with the max.
@export var missing_hp: int = 0
@export var missing_mp: int = 0
## Equipped gear: GearItem.Slot -> GearItem
@export var equipment: Dictionary = {}
## Stable id for the Hall of Climbers, so clearing the tower again with the same
## character updates their record instead of adding a new one.
@export var legacy_id: String = ""
## Story companions have an id (e.g. &"childhood_friend"); test companions don't.
@export var companion_id: StringName = &""
## Shared skills this character has learned (picks + skill books). Kept when
## changing class and carried into New Game+.
@export var learned_skills: Array[StringName] = []
## Unspent skill picks. Everyone starts with 1 (a "starting skill") and gets
## another every SKILL_PICK_EVERY levels.
@export var skill_picks: int = STARTING_SKILL_PICKS


func _init() -> void:
	if stats == null:
		stats = StatBlock.new()


# =========================================================
# Name
# =========================================================

const NAME_MAX_LENGTH := 16


## Trims, collapses repeated spaces and caps the length. Returns "" if nothing's left.
static func clean_name(raw: String) -> String:
	var parts := raw.strip_edges().split(" ", false)
	return " ".join(parts).left(NAME_MAX_LENGTH)


## Renames the character. Returns false (and changes nothing) for a blank name.
func rename(new_name: String) -> bool:
	var cleaned := clean_name(new_name)
	if cleaned.is_empty():
		return false
	character_name = cleaned
	stats_changed.emit()
	return true


# =========================================================
# Equipment
# =========================================================

func get_equipped(slot: int) -> GearItem:
	return equipment.get(slot)


## Equips `item` and returns whatever was in that slot (or null).
## Returns `item` itself if this character can't equip it (class-locked).
func equip(item: GearItem) -> GearItem:
	if item == null or not item.can_equip(self):
		return item
	var prev: GearItem = equipment.get(item.slot)
	equipment[item.slot] = item
	_refresh_gear_bonus()
	return prev


func unequip(slot: int) -> GearItem:
	var prev: GearItem = equipment.get(slot)
	if prev:
		equipment.erase(slot)
		_refresh_gear_bonus()
	return prev


func _refresh_gear_bonus() -> void:
	var was_alive := not is_downed()
	var total := {}
	for item: GearItem in equipment.values():
		for s in item.bonuses:
			total[s] = total.get(s, 0) + item.bonuses[s]
	stats.gear_bonus = total
	# Taking off +Health gear lowers max HP; never let that knock someone out.
	if was_alive and current_hp() <= 0:
		missing_hp = max_hp() - 1
	missing_mp = mini(missing_mp, max_mp())
	stats_changed.emit()


# =========================================================
# Shared skills
# =========================================================

func knows_skill(id: StringName) -> bool:
	return learned_skills.has(id) or SkillLibrary.CLASS_SKILLS.get(class_id, []).has(id)


## Learn a shared skill (from a skill book). False if unknown, not learnable,
## or already known.
func learn_skill(id: StringName) -> bool:
	var s := SkillLibrary.get_skill_or_null(id)
	if s == null or not s.learnable or learned_skills.has(id):
		return false
	learned_skills.append(id)
	stats_changed.emit()
	return true


## Spend a skill pick on a Common shared skill.
func pick_skill(id: StringName) -> bool:
	if skill_picks <= 0:
		return false
	var s := SkillLibrary.get_skill_or_null(id)
	if s == null or not SkillLibrary.pick_pool().has(s) or learned_skills.has(id):
		return false
	learned_skills.append(id)
	skill_picks -= 1
	stats_changed.emit()
	return true


## Class skills first, then learned shared skills.
func all_skills() -> Array[SkillDef]:
	var out := SkillLibrary.skills_for_class(class_id)
	for id in learned_skills:
		var s := SkillLibrary.get_skill_or_null(id)
		if s and not out.has(s):
			out.append(s)
	return out


# =========================================================
# HP / MP (persistent between battles)
# =========================================================

func max_hp() -> int:
	return stats.max_hp()


func max_mp() -> int:
	return stats.max_mp()


func current_hp() -> int:
	return clampi(max_hp() - missing_hp, 0, max_hp())


func current_mp() -> int:
	return clampi(max_mp() - missing_mp, 0, max_mp())


## Knocked out: stays at 0 HP until revived (rest floor campfire for now).
func is_downed() -> bool:
	return current_hp() <= 0


func set_current_hp(value: int) -> void:
	missing_hp = clampi(max_hp() - value, 0, max_hp())
	stats_changed.emit()


func set_current_mp(value: int) -> void:
	missing_mp = clampi(max_mp() - value, 0, max_mp())
	stats_changed.emit()


## Heals a living character. Returns HP actually restored. Downed = no effect.
func heal(amount: int) -> int:
	if is_downed():
		return 0
	var before := current_hp()
	set_current_hp(before + amount)
	return current_hp() - before


func restore_mp(amount: int) -> int:
	var before := current_mp()
	set_current_mp(before + amount)
	return current_mp() - before


## Brings a downed character back with `hp` HP. Returns false if they weren't downed.
func revive(hp: int) -> bool:
	if not is_downed():
		return false
	set_current_hp(clampi(hp, 1, max_hp()))
	return true


## Full HP/MP and revive. Used by rest-floor campfires.
func full_restore() -> void:
	missing_hp = 0
	missing_mp = 0
	stats_changed.emit()


# =========================================================
# Leveling
# =========================================================

## Stat points granted when reaching `new_level`.
static func points_for_level(new_level: int) -> int:
	return EARLY_POINTS_PER_LEVEL if new_level <= EARLY_LEVEL_CAP else LATE_POINTS_PER_LEVEL


## XP needed to go from `from_level` to the next level.
static func xp_to_next(from_level: int) -> int:
	return roundi(XP_BASE * pow(from_level, XP_EXPONENT))


## Total points a character will have earned by reaching `target_level`.
static func total_points_at_level(target_level: int) -> int:
	var total := 0
	for lv in range(2, target_level + 1):
		total += points_for_level(lv)
	return total


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level_up()


func level_up() -> void:
	level += 1
	var gained := points_for_level(level)
	unspent_points += gained
	if level % SKILL_PICK_EVERY == 0:
		skill_picks += 1
	leveled_up.emit(level, gained)
	stats_changed.emit()
	if can_choose_class():
		class_selection_available.emit()


# =========================================================
# Stat allocation
# =========================================================

func allocate(stat: int, amount: int = 1) -> bool:
	if amount <= 0 or amount > unspent_points:
		return false
	stats.add_allocated(stat, amount)
	unspent_points -= amount
	stats_changed.emit()
	return true


## Commit several allocations at once, e.g. from a "pending" UI.
## `pending` is Stats.Type -> int. All-or-nothing.
func apply_allocation(pending: Dictionary) -> bool:
	var sum := 0
	for stat in pending:
		var amt: int = pending[stat]
		if amt < 0:
			return false
		sum += amt
	if sum == 0 or sum > unspent_points:
		return false
	for stat in pending:
		if pending[stat] > 0:
			stats.add_allocated(stat, pending[stat])
	unspent_points -= sum
	stats_changed.emit()
	return true


# =========================================================
# Classes
# =========================================================

func has_class() -> bool:
	return class_id != &""


func can_choose_class() -> bool:
	return level >= CLASS_UNLOCK_LEVEL and not has_class()


## Keeps the stat multiplier in sync with the current class. Raising max HP this
## way raises current HP too (same as allocating Health).
func _apply_class_bonus() -> void:
	var was_alive := not is_downed()
	var def := get_class_def()
	stats.class_bonus_pct = def.stat_bonus_pct if def else 0.0
	if was_alive and current_hp() <= 0:
		missing_hp = max_hp() - 1
	missing_mp = mini(missing_mp, max_mp())


func get_class_def() -> ClassDef:
	return ClassRegistry.get_class_def(class_id) if has_class() else null


func get_qualifying_classes() -> Array[ClassDef]:
	return ClassRegistry.get_qualifying(stats, 1, GameState.unlocked_secret_classes())


## Switch to an unlocked secret class, even if a class was already chosen.
## The caller (GameState.take_secret_class) checks it's unlocked.
func can_take_secret_class(def: ClassDef) -> bool:
	return def != null and def.is_secret and level >= CLASS_UNLOCK_LEVEL \
		and class_id != def.id and def.qualifies(stats)


func take_secret_class(def: ClassDef) -> bool:
	if not can_take_secret_class(def):
		return false
	class_id = def.id
	_apply_class_bonus()
	battle_row = -1   # use the new class's default row
	class_chosen.emit(def)
	stats_changed.emit()
	return true


func choose_class(def: ClassDef) -> bool:
	if def == null or not can_choose_class() or not def.qualifies(stats):
		return false
	class_id = def.id
	_apply_class_bonus()
	class_chosen.emit(def)
	stats_changed.emit()
	return true


# =========================================================
# Respec
# =========================================================
# Rule: 1 free respec before choosing a class, 1 more free after choosing,
# then each respec costs gold (escalating). The pre-class free respec does
# not carry over if unused.

func has_free_respec() -> bool:
	return not free_respec_post_class_used if has_class() else not free_respec_pre_class_used


func next_respec_cost() -> int:
	if has_free_respec():
		return 0
	return roundi(RESPEC_BASE_COST * pow(RESPEC_COST_MULTIPLIER, paid_respec_count))


func can_respec() -> bool:
	return stats.total_allocated() > 0 and gold >= next_respec_cost()


func respec() -> bool:
	if not can_respec():
		return false
	var was_free := has_free_respec()
	var cost := next_respec_cost()
	if was_free:
		if has_class():
			free_respec_post_class_used = true
		else:
			free_respec_pre_class_used = true
	else:
		gold -= cost
		paid_respec_count += 1
	var hp_before := current_hp()
	var mp_before := current_mp()
	unspent_points += stats.reset_allocated()
	# Respec keeps current HP/MP (capped to the new max). It never heals and
	# never knocks anyone out.
	missing_hp = max_hp() - clampi(hp_before, 0, max_hp())
	missing_mp = max_mp() - clampi(mp_before, 0, max_mp())
	respecced.emit(was_free, cost)
	stats_changed.emit()
	return true
