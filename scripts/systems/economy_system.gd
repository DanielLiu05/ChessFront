class_name EconomySystem
extends RefCounted

const GOLD_PER_CYCLE: int = 1


static func collect_token(state: GameState, unit: GameUnit, report: EconomyReport) -> void:
	if unit == null:
		return
	var mine := state.get_gold_mine_at(unit.tile)
	if mine == null or not mine.gold_available:
		return
	mine.gold_available = false
	mine.cycle_progress = 0
	state.add_gold(unit.owner, GOLD_PER_CYCLE)
	report.add_gold(unit.owner, GOLD_PER_CYCLE)
	report.tokens_collected.append(mine.tile)


static func advance_mines(state: GameState, report: EconomyReport) -> void:
	for mine: GoldMine in state.gold_mines:
		if mine.gold_available:
			continue
		mine.cycle_progress += 1
		if mine.cycle_progress < GameConfig.MINE_CYCLE_PLIES:
			continue
		var occupant := state.get_mine_occupant(mine)
		if occupant != null:
			state.add_gold(occupant.owner, GOLD_PER_CYCLE)
			report.add_gold(occupant.owner, GOLD_PER_CYCLE)
			mine.cycle_progress = 0
		else:
			mine.gold_available = true
			mine.cycle_progress = 0
			report.tokens_spawned.append(mine.tile)
