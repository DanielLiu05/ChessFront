extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const EXPORT_PATH: String = "user://phase5_demo_export.json"
const INVALID_PATH: String = "user://phase5_demo_invalid.json"

var _failures: int = 0


func _initialize() -> void:
	_show_library()
	_show_symmetric_editing()
	_show_export_gate()
	_show_exported_match()
	_remove_file(EXPORT_PATH)
	_remove_file(INVALID_PATH)
	print("Phase 5 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _show_library() -> void:
	print("=== Map library ===")
	var errors := MapLibrary.library_errors()
	if not errors.is_empty():
		for message: String in errors:
			push_error(message)
		_failures += errors.size()
	for map_id: String in MapLibrary.get_ids():
		var result := MapLibrary.load_by_id(map_id)
		if not result.is_valid():
			push_error("Map %s is not valid: %s" % [map_id, str(result.errors)])
			_failures += 1
			continue
		var state := GameState.new(result.map)
		print(
			"%s: %d playable tiles, %d mines, %d units"
			% [
				map_id,
				result.map.board.playable_count(),
				result.map.gold_mines.size(),
				state.get_all_units().size(),
			]
		)


func _show_symmetric_editing() -> void:
	print("=== Symmetric editing ===")
	var document := MapDocument.create_new("phase5_demo", "Phase 5 Demo")
	var tile := Vector2i(3, 6)
	var mirror := GameConfig.mirror_tile(tile)
	if document.paint_terrain(tile, TerrainType.Type.FOREST):
		print(
			"Forest at %s; mirror %s is %s"
			% [
				str(tile),
				str(mirror),
				TerrainRegistry.get_definition(document.get_terrain(mirror)).display_name,
			]
		)
	else:
		push_error("Terrain paint failed")
		_failures += 1
	var mine_tile := Vector2i(5, 6)
	if document.toggle_mine(mine_tile):
		print(
			"Mine at %s and mirror %s; total mines: %d"
			% [
				str(mine_tile),
				str(GameConfig.mirror_tile(mine_tile)),
				document.map.gold_mines.size(),
			]
		)
	else:
		push_error("Mine placement failed")
		_failures += 1
	var issues := document.validate()
	if issues.is_empty():
		print("Full validation: OK")
	else:
		for issue: MapValidationIssue in issues:
			push_error("Validation: %s" % issue.message)
		_failures += 1


func _show_export_gate() -> void:
	print("=== Export gate ===")
	_remove_file(INVALID_PATH)
	var invalid := MapDocument.create_new("phase5_invalid", "Phase 5 Invalid")
	var errors := invalid.export_map(INVALID_PATH)
	if errors.is_empty():
		push_error("Invalid export was not blocked")
		_failures += 1
	else:
		print("Invalid export blocked: %s" % errors[0])
	if FileAccess.file_exists(INVALID_PATH):
		push_error("Invalid export wrote a file")
		_failures += 1


func _show_exported_match() -> void:
	print("=== Editor export to match ===")
	_remove_file(EXPORT_PATH)
	var document := MapDocument.create_new("phase5_export", "Phase 5 Export")
	if not document.toggle_mine(Vector2i(5, 6)):
		push_error("Could not add the mine pair")
		_failures += 1
		return
	var errors := document.export_map(EXPORT_PATH)
	if not errors.is_empty():
		for message: String in errors:
			push_error("Export: %s" % message)
		_failures += 1
		return
	var result := MapIO.load_from_file(EXPORT_PATH)
	if not result.is_valid():
		push_error("Exported map does not load: %s" % str(result.errors))
		_failures += 1
		return
	var state := GameState.new(result.map)
	print(
		"Exported map: %d units, active=P%d, ply=%d"
		% [state.get_all_units().size(), int(state.active_player), state.ply]
	)
	var pawn := state.get_unit_at(Vector2i(4, 14))
	if pawn == null:
		push_error("Player 1 pawn is missing")
		_failures += 1
		return
	var action := MoveAction.new(pawn.id, Vector2i(4, 13))
	var move := ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
	if move.success:
		print(
			"Move %s -> active=P%d, ply=%d"
			% [action.describe(), int(state.active_player), state.ply]
		)
	else:
		push_error("Exported map move failed: %s" % move.error)
		_failures += 1
	print(AsciiBoardRenderer.render(state))


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
