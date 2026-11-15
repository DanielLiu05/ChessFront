class_name MoveCommit
extends RefCounted

var player: GameConfig.Player
var unit_id: int
var destination: Vector2i
var exploration: ExplorationProvider
var detected_enemy_ids: Dictionary[int, bool] = {}


static func from_view(
	view: PlayerView,
	selected_unit_id: int,
	selected_destination: Vector2i
) -> MoveCommit:
	var commit := MoveCommit.new()
	commit.player = view.player
	commit.unit_id = selected_unit_id
	commit.destination = selected_destination
	commit.exploration = view.exploration
	for enemy_id: int in view.knowledge.detected_enemy_ids:
		commit.detected_enemy_ids[enemy_id] = true
	return commit
