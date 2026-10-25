class_name BattleAction
extends RefCounted
## One command chosen for a unit's turn.

enum Type { SKILL, DEFEND, SWAP_ROW, FLEE, ITEM }

var type: int = Type.SKILL
var actor: Combatant
var skill: SkillDef          # SKILL only (basic attacks are skills too)
var target: Combatant        # single-target skills and items
var item: ItemDef            # ITEM only
var row: int = -1            # SWAP_ROW only: the row to move to (-1 = the next one back)


static func use_skill(p_actor: Combatant, p_skill: SkillDef, p_target: Combatant = null) -> BattleAction:
	var a := BattleAction.new()
	a.type = Type.SKILL
	a.actor = p_actor
	a.skill = p_skill
	a.target = p_target
	return a


static func simple(p_type: int, p_actor: Combatant) -> BattleAction:
	var a := BattleAction.new()
	a.type = p_type
	a.actor = p_actor
	return a


static func move_row(p_actor: Combatant, p_row: int) -> BattleAction:
	var a := BattleAction.new()
	a.type = Type.SWAP_ROW
	a.actor = p_actor
	a.row = p_row
	return a


static func use_item(p_actor: Combatant, p_item: ItemDef, p_target: Combatant) -> BattleAction:
	var a := BattleAction.new()
	a.type = Type.ITEM
	a.actor = p_actor
	a.item = p_item
	a.target = p_target
	return a
