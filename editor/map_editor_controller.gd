class_name MapEditorController
extends Control

enum Tool {
	PAINT_TERRAIN,
	TOGGLE_MINE,
	PLACE_UNIT,
	REMOVE_UNIT,
}

var document: MapDocument
var _tool: Tool = Tool.PAINT_TERRAIN
var _terrain: int = TerrainType.Type.GROUND
var _unit_type: int = UnitType.Type.PAWN
var _player: int = GameConfig.Player.PLAYER_1

@onready var _board: MapEditorBoard = %Board
@onready var _issues_list: ItemList = %IssuesList
@onready var _status_label: Label = %StatusLabel
@onready var _tool_label: Label = %ToolLabel
@onready var _id_edit: LineEdit = %IdEdit
@onready var _name_edit: LineEdit = %NameEdit
@onready var _owner_option: OptionButton = %OwnerOption
@onready var _open_dialog: FileDialog = %OpenDialog
@onready var _save_dialog: FileDialog = %SaveDialog
@onready var _export_dialog: FileDialog = %ExportDialog
@onready var _message_dialog: AcceptDialog = %MessageDialog


func _ready() -> void:
	document = MapDocument.create_new()
	_id_edit.text = document.map.id
	_name_edit.text = document.map.name
	_owner_option.clear()
	_owner_option.add_item("Player 1", GameConfig.Player.PLAYER_1)
	_owner_option.add_item("Player 2", GameConfig.Player.PLAYER_2)
	_owner_option.select(0)
	_player = GameConfig.Player.PLAYER_1
	_configure_dialogs()
	_connect_signals()
	_board.set_document(document)
	_set_terrain_tool(TerrainType.Type.GROUND)
	_refresh_validation()
	_update_status("New map ready.")


func _connect_signals() -> void:
	%NewButton.pressed.connect(_on_new_pressed)
	%OpenButton.pressed.connect(_on_open_pressed)
	%SaveButton.pressed.connect(_on_save_pressed)
	%ExportButton.pressed.connect(_on_export_pressed)
	%ValidateButton.pressed.connect(_on_validate_pressed)
	%GroundButton.pressed.connect(_set_terrain_tool.bind(TerrainType.Type.GROUND))
	%ForestButton.pressed.connect(_set_terrain_tool.bind(TerrainType.Type.FOREST))
	%HillButton.pressed.connect(_set_terrain_tool.bind(TerrainType.Type.HILL))
	%WaterButton.pressed.connect(_set_terrain_tool.bind(TerrainType.Type.WATER))
	%MineButton.pressed.connect(_set_mine_tool)
	%RemoveUnitButton.pressed.connect(_set_remove_tool)
	%KingButton.pressed.connect(_set_unit_tool.bind(UnitType.Type.KING))
	%QueenButton.pressed.connect(_set_unit_tool.bind(UnitType.Type.QUEEN))
	%RookButton.pressed.connect(_set_unit_tool.bind(UnitType.Type.ROOK))
	%BishopButton.pressed.connect(_set_unit_tool.bind(UnitType.Type.BISHOP))
	%KnightButton.pressed.connect(_set_unit_tool.bind(UnitType.Type.KNIGHT))
	%PawnButton.pressed.connect(_set_unit_tool.bind(UnitType.Type.PAWN))
	_owner_option.item_selected.connect(_on_owner_selected)
	_id_edit.text_changed.connect(_on_id_changed)
	_name_edit.text_changed.connect(_on_name_changed)
	_board.tile_clicked.connect(_on_tile_clicked)
	_open_dialog.file_selected.connect(_on_open_file_selected)
	_save_dialog.file_selected.connect(_on_save_file_selected)
	_export_dialog.file_selected.connect(_on_export_file_selected)


func _configure_dialogs() -> void:
	_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_open_dialog.add_filter("*.json", "JSON map files")
	_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.add_filter("*.json", "JSON map files")
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.add_filter("*.json", "JSON map files")


func _on_new_pressed() -> void:
	document = MapDocument.create_new()
	_sync_metadata_fields()
	_board.set_document(document)
	_set_terrain_tool(TerrainType.Type.GROUND)
	_refresh_validation()
	_update_status("New map created.")


func _on_open_pressed() -> void:
	_open_dialog.current_dir = ProjectSettings.globalize_path(
		GameConfig.MAP_LIBRARY_DIRECTORY
	)
	_open_dialog.popup_centered_ratio(0.75)


func _on_save_pressed() -> void:
	var default_path := document.default_save_path()
	if default_path.is_empty():
		_save_dialog.current_dir = ProjectSettings.globalize_path("user://")
	else:
		_save_dialog.current_path = ProjectSettings.globalize_path(default_path)
	_save_dialog.popup_centered_ratio(0.75)


func _on_export_pressed() -> void:
	var default_path := document.default_export_path()
	if default_path.is_empty():
		_export_dialog.current_dir = ProjectSettings.globalize_path(
			GameConfig.MAP_LIBRARY_DIRECTORY
		)
	else:
		_export_dialog.current_path = ProjectSettings.globalize_path(default_path)
	_export_dialog.popup_centered_ratio(0.75)


func _on_open_file_selected(path: String) -> void:
	var errors := document.load_draft(path)
	if not errors.is_empty():
		_show_errors("Open failed", errors)
		return
	_sync_metadata_fields()
	_board.set_document(document)
	_refresh_validation()
	_update_status("Loaded %s." % path)


func _on_save_file_selected(path: String) -> void:
	var errors := document.save_draft(path)
	if not errors.is_empty():
		_show_errors("Save failed", errors)
		return
	_update_status("Saved draft to %s." % path)


func _on_export_file_selected(path: String) -> void:
	var errors := document.export_map(path)
	if not errors.is_empty():
		_refresh_validation()
		_show_errors("Export blocked", errors)
		return
	_update_status("Exported %s." % path)


func _on_validate_pressed() -> void:
	_refresh_validation()
	_update_status("Validation refreshed.")


func _set_terrain_tool(terrain: int) -> void:
	_tool = Tool.PAINT_TERRAIN
	_terrain = terrain
	_update_tool_label()
	_update_status("Paint tool selected.")


func _set_mine_tool() -> void:
	_tool = Tool.TOGGLE_MINE
	_update_tool_label()
	_update_status("Mine tool selected.")


func _set_unit_tool(unit_type: int) -> void:
	_tool = Tool.PLACE_UNIT
	_unit_type = unit_type
	_update_tool_label()
	_update_status("Unit placement tool selected.")


func _set_remove_tool() -> void:
	_tool = Tool.REMOVE_UNIT
	_update_tool_label()
	_update_status("Remove-unit tool selected.")


func _on_owner_selected(index: int) -> void:
	_player = _owner_option.get_item_id(index)
	_update_tool_label()
	_update_status("Placing units for player %d." % _player)


func _on_id_changed(value: String) -> void:
	document.set_id(value)
	_update_status("Map id updated.")


func _on_name_changed(value: String) -> void:
	document.set_name(value)
	_update_status("Map name updated.")


func _on_tile_clicked(tile: Vector2i) -> void:
	var changed := false
	var message := ""
	match _tool:
		Tool.PAINT_TERRAIN:
			changed = document.paint_terrain(tile, _terrain)
			message = "Painted %s at %s." % [
				TerrainRegistry.get_definition(_terrain).display_name, str(tile)
			]
		Tool.TOGGLE_MINE:
			changed = document.toggle_mine(tile)
			message = "Toggled mine at %s." % str(tile)
		Tool.PLACE_UNIT:
			changed = document.place_starting_unit(_player, _unit_type, tile)
			message = "Placed %s for player %d at %s." % [
				UnitRegistry.get_definition(_unit_type).display_name, _player, str(tile)
			]
		Tool.REMOVE_UNIT:
			changed = document.remove_starting_unit(tile)
			message = "Removed unit at %s." % str(tile)
	if not changed:
		_update_status("Action not allowed at %s." % str(tile))
		return
	_board.queue_redraw()
	_refresh_validation()
	_update_status(message)


func _refresh_validation() -> void:
	var issues := document.validate()
	var error_tiles: Array[Vector2i] = []
	_issues_list.clear()
	for issue: MapValidationIssue in issues:
		_issues_list.add_item(issue.message)
		error_tiles.append_array(issue.tiles)
	_board.set_error_tiles(error_tiles)
	if issues.is_empty():
		_issues_list.add_item("No issues: map is valid for a match.")


func _update_tool_label() -> void:
	match _tool:
		Tool.PAINT_TERRAIN:
			_tool_label.text = "Tool: paint %s" % TerrainRegistry.get_definition(_terrain).display_name
		Tool.TOGGLE_MINE:
			_tool_label.text = "Tool: toggle mine"
		Tool.PLACE_UNIT:
			_tool_label.text = "Tool: place %s for player %d" % [
				UnitRegistry.get_definition(_unit_type).display_name, _player
			]
		Tool.REMOVE_UNIT:
			_tool_label.text = "Tool: remove unit"


func _update_status(message: String) -> void:
	var dirty_marker := "modified" if document.dirty else "clean"
	_status_label.text = "%s  [%s]" % [message, dirty_marker]


func _sync_metadata_fields() -> void:
	_id_edit.set_block_signals(true)
	_id_edit.text = document.map.id
	_id_edit.set_block_signals(false)
	_name_edit.set_block_signals(true)
	_name_edit.text = document.map.name
	_name_edit.set_block_signals(false)


func _show_errors(title: String, errors: Array[String]) -> void:
	var lines: Array[String] = []
	for message: String in errors:
		lines.append(message)
	_message_dialog.title = title
	_message_dialog.dialog_text = "\n".join(PackedStringArray(lines))
	_message_dialog.popup_centered()
	if not errors.is_empty():
		_update_status("%s: %s" % [title, errors[0]])
