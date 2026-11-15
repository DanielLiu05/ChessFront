class_name MapLibrary
extends RefCounted


static func list_paths(
	directory: String = GameConfig.MAP_LIBRARY_DIRECTORY
) -> Array[String]:
	var paths: Array[String] = []
	var access := DirAccess.open(directory)
	if access == null:
		return paths
	for file_name: String in access.get_files():
		if file_name.ends_with(".json"):
			paths.append(directory.path_join(file_name))
	paths.sort()
	return paths


static func load_map(path: String) -> MapLoadResult:
	var result := MapIO.load_from_file(path)
	if not result.is_valid():
		return result
	var errors := MapValidator.validate_for_match(result.map)
	if not errors.is_empty():
		result.errors.append_array(errors)
	return result


static func load_all(
	directory: String = GameConfig.MAP_LIBRARY_DIRECTORY
) -> Array[MapLoadResult]:
	var results: Array[MapLoadResult] = []
	for path: String in list_paths(directory):
		results.append(load_map(path))
	return results


static func paths_for_id(
	map_id: String,
	directory: String = GameConfig.MAP_LIBRARY_DIRECTORY
) -> Array[String]:
	var matches: Array[String] = []
	for path: String in list_paths(directory):
		var result := load_map(path)
		if result.is_valid() and result.map.id == map_id:
			matches.append(path)
	return matches


static func list_entries(
	directory: String = GameConfig.MAP_LIBRARY_DIRECTORY
) -> Array[MapEntry]:
	var candidates: Array[MapEntry] = []
	var id_counts: Dictionary[String, int] = {}
	for path: String in list_paths(directory):
		var result := load_map(path)
		if not result.is_valid():
			continue
		var map := result.map
		if map.id.strip_edges().is_empty():
			continue
		id_counts[map.id] = int(id_counts.get(map.id, 0)) + 1
		candidates.append(
			MapEntry.new(
				map.id,
				map.name,
				path,
				map.board.get_playable_tiles().size(),
				map.gold_mines.size()
			)
		)
	var entries: Array[MapEntry] = []
	for entry: MapEntry in candidates:
		if int(id_counts.get(entry.id, 0)) == 1:
			entries.append(entry)
	entries.sort_custom(func(a: MapEntry, b: MapEntry) -> bool: return a.id < b.id)
	return entries


static func load_by_id(
	map_id: String,
	directory: String = GameConfig.MAP_LIBRARY_DIRECTORY
) -> MapLoadResult:
	var matches: Array[MapLoadResult] = []
	for result: MapLoadResult in load_all(directory):
		if result.is_valid() and result.map.id == map_id:
			matches.append(result)
	if matches.size() == 1:
		return matches[0]
	var outcome := MapLoadResult.new()
	if matches.is_empty():
		outcome.errors.append("Map id '%s' was not found in %s" % [map_id, directory])
	else:
		outcome.errors.append("Map id '%s' is duplicated in %s" % [map_id, directory])
	return outcome


static func get_ids(
	directory: String = GameConfig.MAP_LIBRARY_DIRECTORY
) -> Array[String]:
	var ids: Array[String] = []
	for result: MapLoadResult in load_all(directory):
		if result.is_valid():
			ids.append(result.map.id)
	ids.sort()
	return ids


static func library_errors(
	directory: String = GameConfig.MAP_LIBRARY_DIRECTORY
) -> Array[String]:
	var errors: Array[String] = []
	var paths := list_paths(directory)
	if paths.is_empty():
		errors.append("Map library directory %s contains no map files" % directory)
		return errors
	var id_paths: Dictionary[String, String] = {}
	for path: String in paths:
		var result := load_map(path)
		if not result.is_valid():
			for message: String in result.errors:
				errors.append("%s: %s" % [path, message])
			continue
		var map_id := result.map.id
		if id_paths.has(map_id):
			errors.append(
				"Duplicate map id '%s' in %s and %s" % [map_id, id_paths[map_id], path]
			)
		else:
			id_paths[map_id] = path
	return errors
