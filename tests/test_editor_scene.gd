extends TestCase


func test_editor_scene_instantiates() -> bool:
	var packed := load("res://editor/MapEditor.tscn") as PackedScene
	assert_not_null(packed, "editor scene loads")
	if packed == null:
		return true
	var instance := packed.instantiate()
	assert_not_null(instance, "editor scene instantiates")
	if instance == null:
		return true
	var editor := instance as MapEditorController
	assert_not_null(editor, "root uses the editor controller")
	assert_not_null(
		instance.get_node_or_null("MarginContainer/Layout/Content/Board"),
		"editor scene contains the board view"
	)
	assert_not_null(
		instance.get_node_or_null("MarginContainer/Layout/Content/ValidationPanel/IssuesList"),
		"editor scene contains the validation list"
	)
	assert_not_null(
		instance.get_node_or_null("MarginContainer/Layout/Content/Tools/OwnerOption"),
		"editor scene contains the unit owner selector"
	)
	instance.free()
	return true


func test_editor_main_scene_override_is_present() -> bool:
	var path := String(
		ProjectSettings.get_setting("application/run/main_scene.map_editor", "")
	)
	assert_eq(path, "res://editor/MapEditor.tscn", "map_editor feature uses the editor scene")
	return true


func test_export_presets_exclude_editor_from_game() -> bool:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	assert_eq(error, OK, "export presets load")
	if error != OK:
		return true
	var game_features := String(config.get_value("preset.0", "custom_features", ""))
	var game_include := String(config.get_value("preset.0", "include_filter", ""))
	var game_exclude := String(config.get_value("preset.0", "exclude_filter", ""))
	var editor_features := String(config.get_value("preset.1", "custom_features", ""))
	var editor_exclude := String(config.get_value("preset.1", "exclude_filter", ""))
	assert_eq(game_features, "", "game preset has no tool feature")
	assert_true(game_include.contains("maps/"), "game preset includes map files")
	assert_true(game_exclude.contains("editor/"), "game preset excludes editor code")
	assert_true(game_exclude.contains("tests/"), "game preset excludes tests")
	assert_eq(editor_features, "map_editor", "editor preset enables map_editor")
	assert_true(editor_exclude.contains("tests/"), "editor preset excludes tests")
	assert_false(editor_exclude.contains("editor/"), "editor preset includes editor code")
	return true
