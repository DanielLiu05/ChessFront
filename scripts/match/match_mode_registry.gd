class_name MatchModeRegistry
extends RefCounted

const MODE_DIRECTORY: String = "res://resources/match_modes"
const BUILT_IN_MODE_PATHS: Array[String] = [
	"res://resources/match_modes/vs_ai.tres",
]
const BUILT_IN_MODES: Array = [
	preload("res://resources/match_modes/vs_ai.tres"),
]


static func built_in_modes() -> Array[MatchModeDefinition]:
	var modes: Array[MatchModeDefinition] = []
	for mode: MatchModeDefinition in BUILT_IN_MODES:
		if mode != null:
			modes.append(mode)
	return modes


static func list_paths(directory: String = MODE_DIRECTORY) -> Array[String]:
	var paths: Array[String] = []
	var access := DirAccess.open(directory)
	if access == null:
		return paths
	for file_name: String in access.get_files():
		if file_name.ends_with(".tres"):
			paths.append(directory.path_join(file_name))
	paths.sort()
	return paths


static func load_mode(path: String) -> MatchModeDefinition:
	var resource := load(path)
	if resource is MatchModeDefinition:
		return resource as MatchModeDefinition
	return null


static func load_all(directory: String = MODE_DIRECTORY) -> Array[MatchModeDefinition]:
	var modes: Array[MatchModeDefinition] = []
	var seen_paths: Dictionary[String, bool] = {}
	if directory == MODE_DIRECTORY:
		for path: String in BUILT_IN_MODE_PATHS:
			seen_paths[path] = true
		for mode: MatchModeDefinition in built_in_modes():
			modes.append(mode)
			_remember_path(mode, seen_paths)
	for path: String in list_paths(directory):
		if seen_paths.has(path):
			continue
		var mode := load_mode(path)
		if mode != null:
			modes.append(mode)
	return modes


static func get_modes(directory: String = MODE_DIRECTORY) -> Array[MatchModeDefinition]:
	var loaded := load_all(directory)
	var counts := _id_counts(loaded)
	var modes: Array[MatchModeDefinition] = []
	for mode: MatchModeDefinition in loaded:
		if not mode.validation_errors().is_empty():
			continue
		if counts.get(mode.id, 0) != 1:
			continue
		modes.append(mode)
	modes.sort_custom(_sort_modes)
	return modes


static func get_enabled_modes(
	directory: String = MODE_DIRECTORY
) -> Array[MatchModeDefinition]:
	var modes: Array[MatchModeDefinition] = []
	for mode: MatchModeDefinition in get_modes(directory):
		if mode.enabled:
			modes.append(mode)
	return modes


static func get_mode(
	mode_id: String,
	directory: String = MODE_DIRECTORY
) -> MatchModeDefinition:
	for mode: MatchModeDefinition in get_modes(directory):
		if mode.id == mode_id:
			return mode
	return null


static func registry_errors(directory: String = MODE_DIRECTORY) -> Array[String]:
	var errors: Array[String] = []
	var paths := list_paths(directory)
	var modes: Array[MatchModeDefinition] = []
	var seen_paths: Dictionary[String, bool] = {}
	if directory == MODE_DIRECTORY:
		for path: String in BUILT_IN_MODE_PATHS:
			seen_paths[path] = true
		for mode: MatchModeDefinition in built_in_modes():
			modes.append(mode)
			_remember_path(mode, seen_paths)
	for path: String in paths:
		if seen_paths.has(path):
			continue
		var mode := load_mode(path)
		if mode == null:
			errors.append("%s: not a MatchModeDefinition" % path)
			continue
		for message: String in mode.validation_errors():
			errors.append("%s: %s" % [path, message])
		modes.append(mode)
	if modes.is_empty():
		errors.append(
			"Mode directory %s contains no mode resources" % directory
		)
		return errors
	var counts := _id_counts(modes)
	for mode: MatchModeDefinition in modes:
		if mode.id.strip_edges().is_empty():
			continue
		if counts.get(mode.id, 0) > 1:
			errors.append("Duplicate mode id '%s'" % mode.id)
	return errors


static func validate_modes(modes: Array[MatchModeDefinition]) -> Array[String]:
	var errors: Array[String] = []
	var counts := _id_counts(modes)
	for mode: MatchModeDefinition in modes:
		if mode == null:
			errors.append("Mode entry is null")
			continue
		for message: String in mode.validation_errors():
			errors.append(message)
	for mode_id: String in counts:
		if counts[mode_id] > 1:
			errors.append("Duplicate mode id '%s'" % mode_id)
	return errors


static func _remember_path(
	mode: MatchModeDefinition,
	seen_paths: Dictionary[String, bool]
) -> void:
	if mode.resource_path.is_empty():
		return
	seen_paths[mode.resource_path] = true


static func _id_counts(modes: Array[MatchModeDefinition]) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for mode: MatchModeDefinition in modes:
		if mode == null or mode.id.strip_edges().is_empty():
			continue
		counts[mode.id] = int(counts.get(mode.id, 0)) + 1
	return counts


static func _sort_modes(a: MatchModeDefinition, b: MatchModeDefinition) -> bool:
	return a.id < b.id
