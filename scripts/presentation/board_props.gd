class_name BoardProps
extends Node3D

const KEYS: Array[String] = ["canopy", "trunk", "rock", "grass", "pebble"]
const TREE_SLOTS: Array[Vector3] = [
	Vector3(-0.26, 0.0, -0.22),
	Vector3(0.24, 0.0, -0.20),
	Vector3(-0.04, 0.0, 0.28),
]

var _board: BoardData
var _density: float = 1.0
var _multimeshes: Dictionary[String, MultiMeshInstance3D] = {}
var _entries: Dictionary[String, Array] = {}
var _tile_entries: Dictionary[Vector2i, Array] = {}
var _tile_visible: Dictionary[Vector2i, bool] = {}
var _tile_occupied: Dictionary[Vector2i, bool] = {}

static var _materials: Dictionary[String, StandardMaterial3D] = {}


func build(board: BoardData, density: float) -> void:
	_board = board
	_density = clampf(density, 0.0, 1.0)
	_tile_visible.clear()
	_tile_occupied.clear()
	_rebuild()


func set_density(density: float) -> void:
	var clamped := clampf(density, 0.0, 1.0)
	if is_equal_approx(clamped, _density):
		return
	_density = clamped
	_rebuild()


func set_tile_view(tile: Vector2i, visible: bool, occupied: bool) -> void:
	_tile_visible[tile] = visible
	_tile_occupied[tile] = occupied
	_apply_tile(tile)


func prop_count(tile: Vector2i) -> int:
	return (_tile_entries.get(tile, []) as Array).size()


func visible_prop_count(tile: Vector2i) -> int:
	if not bool(_tile_visible.get(tile, false)):
		return 0
	return prop_count(tile)


func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_multimeshes.clear()
	_entries.clear()
	_tile_entries.clear()
	if KEYS.is_empty() or _board == null:
		return
	for key: String in KEYS:
		_entries[key] = []
	_collect_entries()
	for key: String in KEYS:
		_create_multimesh(key)
	for tile: Vector2i in _tile_entries:
		_apply_tile(tile)


func _collect_entries() -> void:
	var tree_count := clampi(int(round(3.0 * _density)), 1, 3)
	var rock_count := clampi(int(round(2.0 * _density)), 1, 2)
	for tile: Vector2i in _board.get_playable_tiles():
		var data := _board.get_tile(tile)
		if data == null:
			continue
		var height := TileView.height_for_terrain(data.terrain)
		match data.terrain:
			TerrainType.Type.FOREST:
				_add_forest(tile, height, tree_count)
			TerrainType.Type.HILL:
				_add_hill(tile, height, rock_count)
			TerrainType.Type.GROUND:
				_add_ground_scatter(tile, height)
			_:
				pass


func _add_forest(tile: Vector2i, height: float, tree_count: int) -> void:
	for index in tree_count:
		var rng := _rng(tile, 10 + index)
		var slot := TREE_SLOTS[index]
		var offset := Vector3(
			slot.x + rng.randf_range(-0.05, 0.05),
			0.0,
			slot.z + rng.randf_range(-0.05, 0.05)
		)
		_add_entry(
			"trunk",
			tile,
			Transform3D(Basis(), _world(tile, height + 0.12, offset)),
			1.0
		)
		_add_entry(
			"canopy",
			tile,
			Transform3D(
				Basis.from_scale(Vector3(1.0, 1.15, 1.0)),
				_world(tile, height + 0.31, offset)
			),
			0.45
		)


func _add_hill(tile: Vector2i, height: float, rock_count: int) -> void:
	for index in rock_count:
		var rng := _rng(tile, 40 + index)
		var offset := Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))
		_add_entry(
			"rock",
			tile,
			Transform3D(
				Basis.from_scale(Vector3(1.0, 0.7, 1.0)),
				_world(tile, height + 0.07, offset)
			),
			1.0
		)


func _add_ground_scatter(tile: Vector2i, height: float) -> void:
	var rng := _rng(tile, 70)
	if rng.randf() < _density * 0.6:
		var offset := Vector3(rng.randf_range(-0.34, 0.34), 0.0, rng.randf_range(-0.34, 0.34))
		_add_entry("grass", tile, Transform3D(Basis(), _world(tile, height + 0.06, offset)), 1.0)
	if rng.randf() < _density * 0.5:
		var offset := Vector3(rng.randf_range(-0.36, 0.36), 0.0, rng.randf_range(-0.36, 0.36))
		_add_entry("pebble", tile, Transform3D(Basis(), _world(tile, height + 0.03, offset)), 1.0)


func _add_entry(key: String, tile: Vector2i, transform: Transform3D, occupied_scale: float) -> void:
	var index: int = (_entries[key] as Array).size()
	_entries[key].append({
		"tile": tile,
		"base": transform,
		"occupied_scale": occupied_scale,
	})
	if not _tile_entries.has(tile):
		_tile_entries[tile] = []
	_tile_entries[tile].append([key, index])


func _create_multimesh(key: String) -> void:
	var entries: Array = _entries[key]
	var instance := MultiMeshInstance3D.new()
	instance.name = "Props_%s" % key
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _mesh(key)
	multimesh.instance_count = entries.size()
	for index in entries.size():
		multimesh.set_instance_transform(
			index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
		)
	instance.multimesh = multimesh
	instance.material_override = _material(key)
	add_child(instance)
	_multimeshes[key] = instance


func _apply_tile(tile: Vector2i) -> void:
	var visible := bool(_tile_visible.get(tile, false))
	var occupied := bool(_tile_occupied.get(tile, false))
	for reference: Array in _tile_entries.get(tile, []):
		var key: String = reference[0]
		var index: int = reference[1]
		var entry: Dictionary = _entries[key][index]
		var transform: Transform3D = entry["base"]
		if not visible:
			transform.basis = Basis.from_scale(Vector3.ZERO)
		elif occupied and float(entry["occupied_scale"]) < 1.0:
			transform.basis = transform.basis.scaled(
				Vector3.ONE * float(entry["occupied_scale"])
			)
		_multimeshes[key].multimesh.set_instance_transform(index, transform)


func _world(tile: Vector2i, height: float, offset: Vector3) -> Vector3:
	return BoardView.tile_to_world(tile, height) + offset


func _rng(tile: Vector2i, salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(tile.x * 73856093 + tile.y * 19349663 + salt * 83492791)
	return rng


static func _mesh(key: String) -> Mesh:
	match key:
		"canopy":
			var canopy := SphereMesh.new()
			canopy.radius = 0.17
			canopy.height = 0.39
			canopy.radial_segments = 12
			canopy.rings = 6
			return canopy
		"trunk":
			var trunk := CylinderMesh.new()
			trunk.top_radius = 0.032
			trunk.bottom_radius = 0.044
			trunk.height = 0.24
			trunk.radial_segments = 6
			return trunk
		"rock":
			var rock := SphereMesh.new()
			rock.radius = 0.12
			rock.height = 0.24
			rock.radial_segments = 8
			rock.rings = 4
			return rock
		"grass":
			var grass := CylinderMesh.new()
			grass.top_radius = 0.008
			grass.bottom_radius = 0.03
			grass.height = 0.12
			grass.radial_segments = 5
			return grass
		_:
			var pebble := SphereMesh.new()
			pebble.radius = 0.035
			pebble.height = 0.07
			pebble.radial_segments = 6
			pebble.rings = 3
			return pebble


static func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	match key:
		"canopy":
			material.albedo_color = PresentationConfig.PALETTE["canopy"]
			material.roughness = 0.95
		"trunk":
			material.albedo_color = PresentationConfig.PALETTE["trunk"]
			material.roughness = 1.0
		"rock":
			material.albedo_color = PresentationConfig.PALETTE["rock"]
			material.roughness = 0.9
		"grass":
			material.albedo_color = PresentationConfig.PALETTE["grass"]
			material.roughness = 1.0
		_:
			material.albedo_color = PresentationConfig.PALETTE["pebble"]
			material.roughness = 0.95
	material.metallic = 0.0
	_materials[key] = material
	return material
