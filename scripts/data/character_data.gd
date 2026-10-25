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
const XP_BASE := 25
## Max HP every level gives on top of Health (see max_hp()).
const HP_PER_LEVEL := 10
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
## The one free class change (Hayden 2026-10-25), offered once the tier-2
## gate's floor is beaten, while still in a tier-1 class.
@export var class_change_used: bool = false
## Hired by the floor (Hayden 2026-10-25): gold owed every floor (0 = paid
## up front or not hired), floors in a row it went unpaid, and gold owed.
@export var wage: int = 0
@export var wage_missed: int = 0
@export var wage_owed: int = 0
## An earned title shown with the name ("the Lone Climber"). Only EPITHETS.
@export var epithet: String = ""
const SOLO_EPITHET := "the Lone Climber"
const EPITHETS := [SOLO_EPITHET]
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
## Ranked-up skills: skill id -> rank (2..SkillLibrary.MAX_SKILL_RANK).
@export var skill_ranks: Dictionary = {}
## Recruits: their own skill (NpcLibrary "personal_skill"), usable once their
## loyalty quest is done (personal_unlocked).
@export var personal_skill: StringName = &""
@export var personal_unlocked: bool = false
## NG+: this character Ascended their top-tier class ("Ascended Pyromancer"):
## +ClassRegistry.ASCENSION_BONUS to every stat and the Apotheosis skill.
@export var ascended: bool = false
## Blessing from a god / demon / devil (BeingLibrary id; &"" = none) and its level.
@export var blessing_id: StringName = &""
@export var blessing_level: int = 0
## A punishment curse that lingers after a blessing is taken away.
@export var curse_id: StringName = &""
@export var curse_level: int = 0
## The curse lifts once you climb past this floor (0 = no curse).
@export var curse_until_floor: int = 0


func _init() -> void:
	if stats == null:
		stats = StatBlock.new()


# =========================================================
# Blessings and curses (see BeingLibrary / BlessingState)
# =========================================================

func is_blessed() -> bool:
	return blessing_id != &""


func bless(id: StringName, level: int) -> void:
	blessing_id = id
	blessing_level = clampi(level, 1, BlessingState.LEVEL_INTEREST.size())
	refresh_blessing()


func unbless() -> void:
	blessing_id = &""
	blessing_level = 0
	refresh_blessing()


func curse(id: StringName, level: int, until_floor: int) -> void:
	curse_id = id
	curse_level = level
	curse_until_floor = until_floor
	refresh_blessing()


func lift_curse() -> void:
	curse_id = &""
	curse_level = 0
	curse_until_floor = 0
	refresh_blessing()


## Every effect dictionary active on this character: the blessing's buff and
## curse, plus a lingering punishment curse.
func active_effects() -> Array:
	var out := []
	if is_blessed():
		var lv := BeingLibrary.level_effects(blessing_id, blessing_level)
		out.append(lv.get("buff", {}))
		out.append(lv.get("curse", {}))
	if curse_id != &"":
		out.append(BeingLibrary.level_effects(curse_id, curse_level).get("curse", {}))
	return out


## Sum of a number effect ("gold_mult", "xp_mult", "price_mult", "regen_pct").
func effect_sum(key: String) -> float:
	var total := 0.0
	for e in active_effects():
		total += e.get(key, 0.0)
	return total


## Merged dictionary effect ("stats", "element_power" add up; "affinities" — later wins).
func effect_map(key: String) -> Dictionary:
	var out := {}
	for e in active_effects():
		var m: Dictionary = e.get(key, {})
		for k in m:
			out[k] = m[k] if key == "affinities" else out.get(k, 0.0) + m[k]
	return out


## Applies blessing/curse stat changes. Keeps current HP/MP sensible.
func refresh_blessing() -> void:
	var was_alive := not is_downed()
	stats.blessing_pct = effect_map("stats")
	if was_alive and current_hp() <= 0:
		missing_hp = max_hp() - 1
	missing_hp = mini(missing_hp, max_hp())
	missing_mp = mini(missing_mp, max_mp())
	stats_changed.emit()


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
	return learned_skills.has(id) or SkillLibrary.skills_for_class(class_id).any(func(s): return s.id == id) \
		or (personal_unlocked and id == personal_skill and id != &"")


## Learn a shared skill (from a skill book). False if unknown, not learnable,
## or already known.
func learn_skill(id: StringName) -> bool:
	var s := SkillLibrary.get_skill_or_null(id)
	if s == null or not s.learnable or learned_skills.has(id):
		return false
	learned_skills.append(id)
	stats_changed.emit()
	return true


## Spend a skill pick on a skill from your class's pool (SkillLibrary.pick_pool_for).
func pick_skill(id: StringName) -> bool:
	if skill_picks <= 0:
		return false
	var s := SkillLibrary.get_skill_or_null(id)
	if s == null or not SkillLibrary.pick_pool_for(class_id).has(s) or learned_skills.has(id):
		return false
	learned_skills.append(id)
	skill_picks -= 1
	stats_changed.emit()
	return true


## Pool skills you could still pick.
func pickable_skills() -> Array[SkillDef]:
	var out: Array[SkillDef] = []
	for s in SkillLibrary.pick_pool_for(class_id):
		if not learned_skills.has(s.id):
			out.append(s)
	return out


## A skill's rank (1 = as learned).
func skill_rank(id: StringName) -> int:
	return skill_ranks.get(id, 1)


## Can a skill pick rank this skill up? (Known, not maxed, not a blessed skill.)
func can_rank_up(id: StringName) -> bool:
	return skill_picks > 0 and knows_skill(id) and skill_rank(id) < SkillLibrary.MAX_SKILL_RANK \
		and not _is_blessed_skill(id)


## Spend a skill pick to rank up a skill you know.
func rank_up_skill(id: StringName) -> bool:
	if not can_rank_up(id):
		return false
	skill_ranks[id] = skill_rank(id) + 1
	skill_picks -= 1
	stats_changed.emit()
	return true


func _is_blessed_skill(id: StringName) -> bool:
	for b in BeingLibrary.beings.values():
		if StringName(str(b.get("skill", ""))) == id:
			return true
	return false


## Class skills first, then learned shared skills (each at its rank).
func all_skills() -> Array[SkillDef]:
	var out: Array[SkillDef] = []
	for s in SkillLibrary.skills_for_class(class_id):
		out.append(SkillLibrary.ranked(s, skill_rank(s.id)))
	for id in learned_skills:
		var s := SkillLibrary.get_skill_or_null(id)
		if s and not out.any(func(o): return o.id == s.id):
			out.append(SkillLibrary.ranked(s, skill_rank(s.id)))
	if ascended:   # an Ascended line's capstone
		var ap := SkillLibrary.get_skill_or_null(SkillLibrary.ASCENSION_SKILL)
		if ap and not out.any(func(o): return o.id == ap.id):
			out.append(SkillLibrary.ranked(ap, skill_rank(ap.id)))
	if class_id == &"ascendant":   # the Ascendant grows with each advancement gate
		for t in SkillLibrary.ASCENDANT_GATE_SKILLS:
			if gate_open(t):
				var gs := SkillLibrary.get_skill_or_null(SkillLibrary.ASCENDANT_GATE_SKILLS[t])
				if gs and not out.any(func(o): return o.id == gs.id):
					out.append(SkillLibrary.ranked(gs, skill_rank(gs.id)))
	if personal_unlocked and personal_skill != &"":   # a recruit's own skill, after their loyalty quest
		var ps := SkillLibrary.get_skill_or_null(personal_skill)
		if ps and not out.any(func(o): return o.id == ps.id):
			out.append(SkillLibrary.ranked(ps, skill_rank(ps.id)))
	if is_blessed():   # the blessed skill, while the blessing lasts
		var bs := SkillLibrary.get_skill_or_null(BeingLibrary.get_being(blessing_id).get("skill", &""))
		if bs and not out.any(func(o): return o.id == bs.id):
			out.append(bs)
	return out


# =========================================================
# HP / MP (persistent between battles)
# =========================================================

## Stats decide most of your HP; every level adds a little on top, so
## levelling up always makes you sturdier (balance pass).
func max_hp() -> int:
	return stats.max_hp() + HP_PER_LEVEL * (level - 1)


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
	stats.class_bonus_pct = (def.stat_bonus_pct if def else 0.0) + (ClassRegistry.ASCENSION_BONUS if ascended else 0.0)
	if was_alive and current_hp() <= 0:
		missing_hp = max_hp() - 1
	missing_mp = mini(missing_mp, max_mp())


func get_class_def() -> ClassDef:
	return ClassRegistry.get_class_def(class_id) if has_class() else null


func get_qualifying_classes() -> Array[ClassDef]:
	var out: Array[ClassDef] = []
	for def in ClassRegistry.get_qualifying(stats, 1, GameState.unlocked_secret_classes()):
		if def.route_allows():   # route-only classes (tier 2 later)
			out.append(def)
	return out


## Switch to an unlocked secret class, even if a class was already chosen.
## The caller (GameState.take_secret_class) checks it's unlocked.
func can_take_secret_class(def: ClassDef) -> bool:
	return def != null and def.is_secret and level >= CLASS_UNLOCK_LEVEL \
		and class_id != def.id and def.qualifies(stats) and def.route_allows()


func take_secret_class(def: ClassDef) -> bool:
	if not can_take_secret_class(def):
		return false
	class_id = def.id
	_apply_class_bonus()
	battle_row = -1   # use the new class's default row
	class_chosen.emit(def)
	stats_changed.emit()
	return true


## Can give up their tier-1 class once (see class_change_used): after the
## tier-2 gate's floor, before advancing. Not the NG+ Ascendant.
func class_change_open() -> bool:
	var def := get_class_def()
	var gate: Dictionary = ClassRegistry.ADVANCEMENT_GATES.get(2, {})
	return def != null and def.tier == 1 and class_id != &"ascendant" and not class_change_used 		and not gate.is_empty() and GameState.highest_floor > gate.floor


## Gives up the class (once) and gets a free respec, then picks again like
## at level 10 (or takes an unlocked secret class). Learned skills stay.
func release_class() -> bool:
	if not class_change_open():
		return false
	class_change_used = true
	class_id = &""
	free_respec_pre_class_used = false   # the respec before choosing again is free
	_apply_class_bonus()
	battle_row = -1
	stats_changed.emit()
	return true


func choose_class(def: ClassDef) -> bool:
	if def == null or not can_choose_class() or not def.qualifies(stats) or not def.route_allows():
		return false
	class_id = def.id
	_apply_class_bonus()
	battle_row = -1   # start in the class's recommended row (can be moved)
	class_chosen.emit(def)
	stats_changed.emit()
	return true


# =========================================================
# Class advancement (tier 2, 3, ...)
# =========================================================
# An advancement needs: its tier's gate (floor passed + level, ClassRegistry.
# ADVANCEMENT_GATES), its stat build, its route (if any) and its trial quest.
# You keep every skill from the classes you came from.

## Has this character reached tier `t`'s advancement gate (floor + level)?
func gate_open(t: int) -> bool:
	var gate: Dictionary = ClassRegistry.ADVANCEMENT_GATES.get(t, {})
	return not gate.is_empty() and GameState.highest_floor > gate.floor and level >= gate.level


## "Ophelius the Lone Climber" (or just the name).
func full_name() -> String:
	return character_name + (" " + epithet if epithet != "" else "")


## "Ascended Pyromancer" / "Pyromancer" / "No class".
func class_title() -> String:
	var def := get_class_def()
	if def == null:
		return "No class"
	return ("Ascended " if ascended else "") + def.display_name


## NG+ Ascension: why this character can't Ascend yet ("" = they can).
func ascension_refusal() -> String:
	var g: Dictionary = ClassRegistry.ASCENSION_GATE
	var def := get_class_def()
	if ascended:
		return "Already Ascended."
	if GameState.ng_plus_cycle < 1:
		return "Only in New Game+ (conquer the tower first)."
	if def == null or def.tier < g.tier or class_id == &"ascendant":
		return "Reach a tier-%d class first." % g.tier
	if GameState.highest_floor <= g.floor:
		return "Climb past floor %d." % g.floor
	if level < g.level:
		return "Reach level %d." % g.level
	return ""


func ascend() -> bool:
	if ascension_refusal() != "":
		return false
	ascended = true
	_apply_class_bonus()
	stats_changed.emit()
	return true


## The quest id of an advanced class's trial.
static func trial_id(def: ClassDef) -> StringName:
	return StringName("trial_" + String(def.id))


## Each requirement and whether it's met:
## { "floor": bool, "level": bool, "stats": bool, "route": bool, "trial": bool, "gate": Dictionary }
func advancement_status(def: ClassDef) -> Dictionary:
	var gate: Dictionary = ClassRegistry.ADVANCEMENT_GATES.get(def.tier, {})
	return {
		"gate": gate,
		"floor": not gate.is_empty() and GameState.highest_floor > gate.floor,
		"level": not gate.is_empty() and level >= gate.level,
		"stats": def.qualifies(stats),
		"route": def.route_allows(),
		"trial": GameState.quests.is_done(trial_id(def)),
	}


## Advancements this character's class leads to (route-only ones hidden while
## you're not on that route, so they're not spoiled).
func available_advancements() -> Array[ClassDef]:
	var out: Array[ClassDef] = []
	for def in ClassRegistry.advancements_for(class_id):
		if def.route_allows():
			out.append(def)
	return out


## True once the tier's floor + level gate is met (the Advance button shows).
func advancement_open() -> bool:
	for def in available_advancements():
		var s := advancement_status(def)
		if s.floor and s.level:
			return true
	return false


func can_advance(def: ClassDef) -> bool:
	if def == null or def.advances_from != class_id or class_id == &"":
		return false
	var s := advancement_status(def)
	return s.floor and s.level and s.stats and s.route and s.trial


## Advance into `def`. Keeps all skills of the classes you came from.
func advance_class(def: ClassDef) -> bool:
	if not can_advance(def):
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
