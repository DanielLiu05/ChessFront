extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const DRAFT_PATH: String = "user://chessfront_draft.json"
const EXPORT_PATH: String = "user://chessfront_export.json"
const DUPLICATE_PATH: String = "user://chessfront_duplicate.json"


func test_draft_save_and_load_without_validation() -> bool:
	_remove_file(DRAFT_PATH)
	var document := MapDocument.create_new("draft_map", "Draft Map")
	assert_true(document.remove_starting_unit(Vector2i(8, 15)), "draft made invalid")
	var errors := document.save_draft(DRAFT_PATH)
	assert_true(errors.is_empty(), "draft saves: %s" % str(errors))
	assert_true(FileAccess.file_exists(DRAFT_PATH), "draft file exists")
	assert_false(document.dirty, "save marks the document clean")
	var default_load := MapIO.load_from_file(DRAFT_PATH)
	assert_false(default_load.is_valid(), "default load rejects the draft")
	assert_true(_errors_contain(default_load.errors, "16"), "draft rejection is clear")
	var relaxed := MapIO.load_from_file(DRAFT_PATH, false)
	assert_true(relaxed.is_valid(), "relaxed load accepts the draft")
	if relaxed.is_valid():
		assert_eq(relaxed.map.get_starting_units(PLAYER_1).size(), 15, "draft keeps 15 units")
		assert_eq(relaxed.map.get_starting_units(PLAYER_2).size(), 15, "both sides keep 15 units")
	var loaded := MapDocument.new()
	var load_errors := loaded.load_draft(DRAFT_PATH)
	assert_true(load_errors.is_empty(), "document loads the draft: %s" % str(load_errors))
	assert_eq(loaded.map.get_starting_units(PLAYER_1).size(), 15, "loaded draft units")
	assert_eq(loaded.source_path, DRAFT_PATH, "source path is recorded")
	assert_false(loaded.dirty, "loaded draft is clean")
	_remove_file(DRAFT_PATH)
	return true


func test_save_refuses_library_path() -> bool:
	var document := MapDocument.create_new("library_draft", "Library Draft")
	var target := "res://maps/library/test_library_draft.json"
	var errors := document.save_draft(target)
	assert_true(_errors_contain(errors, "Use Export"), "draft save into the library is blocked")
	assert_false(FileAccess.file_exists(target), "no draft file is written into the library")
	return true


func test_export_blocks_invalid_maps() -> bool:
	_remove_file(EXPORT_PATH)
	var document := MapDocument.create_new("invalid_export", "Invalid Export")
	var errors := document.export_map(EXPORT_PATH)
	assert_true(_errors_contain(errors, "shared gold mines"), "mine-free export is blocked")
	assert_false(FileAccess.file_exists(EXPORT_PATH), "invalid export writes nothing")

	var empty_document := MapDocument.create_new("", "")
	errors = empty_document.export_map(EXPORT_PATH)
	assert_true(_errors_contain(errors, "id must not be empty"), "empty id is blocked")
	assert_true(_errors_contain(errors, "name must not be empty"), "empty name is blocked")
	assert_false(FileAccess.file_exists(EXPORT_PATH), "metadata failure writes nothing")

	document.remove_starting_unit(Vector2i(8, 15))
	document.toggle_mine(Vector2i(5, 6))
	errors = document.export_map(EXPORT_PATH)
	assert_true(_errors_contain(errors, "16"), "invalid composition is blocked")
	assert_false(FileAccess.file_exists(EXPORT_PATH), "composition failure writes nothing")
	return true


func test_valid_export_reloads_and_plays() -> bool:
	_remove_file(EXPORT_PATH)
	var document := MapDocument.create_new("exported_map", "Exported Map")
	assert_true(document.toggle_mine(Vector2i(5, 6)), "mine pair added")
	var errors := document.export_map(EXPORT_PATH)
	assert_true(errors.is_empty(), "valid export succeeds: %s" % str(errors))
	assert_true(FileAccess.file_exists(EXPORT_PATH), "export file exists")
	assert_false(document.dirty, "export marks the document clean")
	var result := MapIO.load_from_file(EXPORT_PATH)
	assert_true(result.is_valid(), "exported map loads: %s" % str(result.errors))
	if not result.is_valid():
		return true
	var full := MapValidator.validate_for_match(result.map)
	assert_true(full.is_empty(), "exported map passes full validation: %s" % str(full))
	var state := GameState.new(result.map)
	assert_eq(state.get_all_units().size(), 32, "exported map deploys 32 units")
	var pawn := state.get_unit_at(Vector2i(4, 14))
	assert_not_null(pawn, "player 1 pawn exists")
	if pawn == null:
		return true
	var action := MoveAction.new(pawn.id, Vector2i(4, 13))
	var move := ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
	assert_true(move.success, "exported map plays a move: %s" % move.error)
	assert_eq(state.active_player, GameConfig.Player.PLAYER_2, "turn advances")
	_remove_file(EXPORT_PATH)
	return true


func test_export_blocks_duplicate_library_id() -> bool:
	_remove_file(DUPLICATE_PATH)
	var document := MapDocument.create_new("borderlands", "Duplicate Borderlands")
	assert_true(document.toggle_mine(Vector2i(5, 6)), "mine pair added")
	var errors := document.export_map(DUPLICATE_PATH)
	assert_true(_errors_contain(errors, "already exists"), "duplicate id is blocked")
	assert_true(_errors_contain(errors, "borderlands"), "duplicate id error names the id")
	assert_false(FileAccess.file_exists(DUPLICATE_PATH), "duplicate export writes nothing")
	return true


func test_default_paths() -> bool:
	var document := MapDocument.create_new("default_paths", "Default Paths")
	assert_eq(
		document.default_export_path(),
		"res://maps/library/default_paths.json",
		"default export path"
	)
	assert_eq(document.default_save_path(), "user://default_paths.json", "default draft path")
	document.mark_clean("user://saved_draft.json")
	assert_eq(document.default_save_path(), "user://saved_draft.json", "loaded path wins")
	return true


func _errors_contain(errors: Array[String], needle: String) -> bool:
	for message: String in errors:
		if message.contains(needle):
			return true
	return false


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
