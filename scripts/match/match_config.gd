class_name MatchConfig
extends RefCounted

var mode_id: String = "vs_ai"
var map_id: String = ""
var human_player: int = GameConfig.Player.PLAYER_1
var first_player: int = GameConfig.Player.PLAYER_1


func _init(
	selected_mode_id: String = "vs_ai",
	selected_map_id: String = "",
	selected_human_player: int = GameConfig.Player.PLAYER_1,
	selected_first_player: int = GameConfig.Player.PLAYER_1
) -> void:
	mode_id = selected_mode_id
	map_id = selected_map_id
	human_player = selected_human_player
	first_player = selected_first_player


func duplicate_config() -> MatchConfig:
	return MatchConfig.new(mode_id, map_id, human_player, first_player)


func mode() -> MatchModeDefinition:
	return MatchModeRegistry.get_mode(mode_id)


func uses_ai() -> bool:
	var selected := mode()
	return selected != null and selected.uses_ai()


func ai_player() -> int:
	if not uses_ai():
		return GameConfig.NO_PLAYER
	return int(GameConfig.opponent(human_player))


func first_is_human() -> bool:
	return first_player == human_player


func first_is_ai() -> bool:
	return uses_ai() and first_player == ai_player()


func side_label(player: int) -> String:
	if player == human_player:
		return "You"
	if uses_ai() and player == ai_player():
		return "AI"
	return "Player %d" % player


func first_label() -> String:
	if uses_ai():
		return "You" if first_is_human() else "AI"
	return "Player %d" % first_player


func map_display_name() -> String:
	var result := MapLibrary.load_by_id(map_id)
	if result.is_valid() and not result.map.name.strip_edges().is_empty():
		return result.map.name
	return map_id


func summary_text() -> String:
	var mode_name := mode_id
	var selected := mode()
	if selected != null and not selected.display_name.is_empty():
		mode_name = selected.display_name
	return "%s · %s · You: Player %d · First: %s" % [
		mode_name,
		map_display_name(),
		human_player,
		first_label(),
	]


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	var selected := mode()
	if selected == null:
		errors.append("Mode '%s' is not available" % mode_id)
	elif not selected.enabled:
		errors.append("Mode '%s' is disabled" % mode_id)
	if map_id.strip_edges().is_empty():
		errors.append("No map is selected")
	else:
		var result := MapLibrary.load_by_id(map_id)
		if not result.is_valid():
			errors.append(
				"Map '%s' is not available: %s" % [map_id, "; ".join(result.errors)]
			)
	if human_player != GameConfig.Player.PLAYER_1 \
			and human_player != GameConfig.Player.PLAYER_2:
		errors.append("Human player must be Player 1 or Player 2")
	if first_player != GameConfig.Player.PLAYER_1 \
			and first_player != GameConfig.Player.PLAYER_2:
		errors.append("First player must be Player 1 or Player 2")
	return errors
