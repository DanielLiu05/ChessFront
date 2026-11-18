class_name MatchStats
extends RefCounted

var captures: int = 0
var gold_earned: int = 0
var scouts_lost: int = 0


func reset() -> void:
	captures = 0
	gold_earned = 0
	scouts_lost = 0


func note_result(result: ActionResult, mover_type: int, local_player: int) -> void:
	if result == null:
		return
	if result.captured_unit != null and result.captured_unit.owner != local_player:
		captures += 1
	if result.gold_gained.has(local_player):
		gold_earned += int(result.gold_gained[local_player])
	if result.ambushed and mover_type == UnitType.Type.SCOUT:
		scouts_lost += 1


func note_capture(victim_owner: int, local_player: int) -> void:
	if victim_owner != local_player:
		captures += 1


func note_gold(amount: int) -> void:
	if amount > 0:
		gold_earned += amount


func note_ambush_loss(mover_type: int) -> void:
	if mover_type == UnitType.Type.SCOUT:
		scouts_lost += 1
