class_name TileView
extends Node3D

enum FogState {
	UNEXPLORED,
	EXPLORED,
	VISIBLE,
}

const COLLISION_LAYER: int = 1
const TILE_SIZE: float = 0.98
const BRIDGE_THICKNESS: float = 0.07
const FOG_TILE_HEIGHT: float = 0.12

const HEIGHTS: Dictionary[int, float] = {
	TerrainType.Type.GROUND: 0.12,
	TerrainType.Type.FOREST: 0.12,
	TerrainType.Type.HILL: 0.34,
	TerrainType.Type.WATER: 0.05,
}

static var _materials: Dictionary[String, StandardMaterial3D] = {}

var tile: Vector2i = Vector2i(-1, -1)
var terrain: int = TerrainType.Type.GROUND
var _fog_state: FogState = FogState.VISIBLE
var _has_bridge: bool = false
var _has_mine: bool = false
var _has_token: bool = false

var _current_terrain: int = -1
var _terrain_height: float = 0.12
var _mesh_instance: MeshInstance3D
var _detail_root: Node3D
var _bridge_root: Node3D
var _mine_root: Node3D
var _token_marker: MeshInstance3D
var _fog_tile: MeshInstance3D
var _body: StaticBody3D
var _collision: CollisionShape3D


func setup(tile_coord: Vector2i, tile_terrain: int, world_position: Vector3) -> void:
	tile = tile_coord
	name = "Tile_%d_%d" % [tile.x, tile.y]
	position = world_position
	_ensure_nodes()
	_apply_terrain(tile_terrain)
	set_view(tile_terrain, false, FogState.VISIBLE, false, false)


func set_terrain(value: int) -> void:
	_ensure_nodes()
	_apply_terrain(value)


func set_view(
	tile_terrain: int,
	has_bridge: bool,
	fog_state: FogState,
	has_mine: bool,
	has_token: bool
) -> void:
	if tile_terrain != _current_terrain:
		_apply_terrain(tile_terrain)
	_has_bridge = has_bridge
	_has_mine = has_mine
	_has_token = has_token
	_fog_state = fog_state
	var known := fog_state != FogState.UNEXPLORED
	_mesh_instance.visible = known
	_detail_root.visible = known
	_bridge_root.visible = known and has_bridge
	_mine_root.visible = known and has_mine
	_token_marker.visible = known and fog_state == FogState.VISIBLE and has_mine and has_token
	_fog_tile.visible = fog_state == FogState.UNEXPLORED
	_body.set_meta("tile", tile)


func surface_height() -> float:
	if _has_bridge:
		return _terrain_height + BRIDGE_THICKNESS
	return _terrain_height


func highlight_height() -> float:
	if _fog_state == FogState.UNEXPLORED:
		return FOG_TILE_HEIGHT + 0.02
	if _fog_state == FogState.EXPLORED:
		return maxf(surface_height(), 0.95) + 0.02
	return surface_height() + 0.02


func cursor_height() -> float:
	if _fog_state == FogState.UNEXPLORED:
		return FOG_TILE_HEIGHT + 0.02
	return surface_height() + 0.02


func get_fog_state() -> FogState:
	return _fog_state


func is_terrain_visible() -> bool:
	return _mesh_instance != null and _mesh_instance.visible


func is_fog_tile_visible() -> bool:
	return _fog_tile != null and _fog_tile.visible


func is_bridge_visible() -> bool:
	return _bridge_root != null and _bridge_root.visible


func is_mine_visible() -> bool:
	return _mine_root != null and _mine_root.visible


func is_token_visible() -> bool:
	return _token_marker != null and _token_marker.visible


func _ensure_nodes() -> void:
	if _mesh_instance != null:
		return
	_body = StaticBody3D.new()
	_body.name = "PickBody"
	_body.collision_layer = COLLISION_LAYER
	_body.collision_mask = 0
	_body.set_meta("tile", tile)
	add_child(_body)
	_collision = CollisionShape3D.new()
	_collision.name = "PickShape"
	_body.add_child(_collision)
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TerrainMesh"
	add_child(_mesh_instance)
	_detail_root = Node3D.new()
	_detail_root.name = "TerrainDetail"
	add_child(_detail_root)
	_bridge_root = _build_bridge()
	add_child(_bridge_root)
	_mine_root = _build_mine()
	add_child(_mine_root)
	_token_marker = MeshInstance3D.new()
	_token_marker.name = "TokenMarker"
	_token_marker.mesh = _cylinder(0.09, 0.09, 0.02)
	_token_marker.material_override = _token()
	add_child(_token_marker)
	_token_marker.visible = false
	_fog_tile = MeshInstance3D.new()
	_fog_tile.name = "FogTile"
	var fog_mesh := _box(Vector3(TILE_SIZE, FOG_TILE_HEIGHT, TILE_SIZE))
	_fog_tile.mesh = fog_mesh
	_fog_tile.material_override = _fog()
	_fog_tile.position = Vector3(0.0, FOG_TILE_HEIGHT * 0.5, 0.0)
	add_child(_fog_tile)
	_fog_tile.visible = false


func _build_bridge() -> Node3D:
	var root := Node3D.new()
	root.name = "Bridge"
	for index in 4:
		var z := -0.36 + 0.24 * index
		_add_mesh_child(
			root,
			_box(Vector3(0.86, 0.05, 0.2)),
			_wood(),
			Vector3(0.0, 0.04, z)
		)
	for side in [-1.0, 1.0]:
		_add_mesh_child(
			root,
			_box(Vector3(0.05, 0.09, 0.98)),
			_wood(),
			Vector3(side * 0.43, 0.11, 0.0)
		)
		for z in [-0.42, 0.42]:
			_add_mesh_child(
				root,
				_cylinder(0.035, 0.04, 0.2),
				_wood(),
				Vector3(side * 0.4, -0.06, z)
			)
	root.visible = false
	return root


func _build_mine() -> Node3D:
	var root := Node3D.new()
	root.name = "MineMarker"
	_add_mesh_child(root, _cylinder(0.1, 0.13, 0.08), _shaft(), Vector3(0.0, 0.04, 0.0))
	_add_mesh_child(root, _sphere(0.035), _lamp(), Vector3(0.0, 0.14, 0.0))
	for index in 4:
		var angle := TAU * float(index) / 4.0 + PI * 0.25
		var segment := MeshInstance3D.new()
		segment.mesh = _box(Vector3(0.07, 0.012, 0.02))
		segment.material_override = _gold()
		segment.position = Vector3(cos(angle) * 0.17, 0.09, sin(angle) * 0.17)
		segment.rotation.y = -angle
		root.add_child(segment)
	root.visible = false
	return root


func _apply_terrain(value: int) -> void:
	_current_terrain = value
	terrain = value
	_terrain_height = height_for_terrain(value)
	var box := BoxMesh.new()
	box.size = Vector3(TILE_SIZE, _terrain_height, TILE_SIZE)
	_mesh_instance.mesh = box
	_mesh_instance.position = Vector3(0.0, _terrain_height * 0.5, 0.0)
	_mesh_instance.material_override = material_for_terrain(value, tile)
	var shape := BoxShape3D.new()
	shape.size = box.size
	_collision.shape = shape
	_collision.position = Vector3(0.0, _terrain_height * 0.5, 0.0)
	_rebuild_detail(value)
	_bridge_root.position = Vector3(0.0, _terrain_height, 0.0)
	_mine_root.position = Vector3(0.27, _terrain_height, 0.27)
	_token_marker.position = Vector3(-0.27, _terrain_height + 0.03, 0.27)
	_body.set_meta("tile", tile)


func _rebuild_detail(value: int) -> void:
	for child: Node in _detail_root.get_children():
		child.free()
	match value:
		TerrainType.Type.HILL:
			_add_mesh_child(
				_detail_root,
				_box(Vector3(0.84, 0.05, 0.84)),
				_hill_cap(),
				Vector3(0.0, _terrain_height + 0.025, 0.0)
			)
			for side in [-1.0, 1.0]:
				_add_mesh_child(
					_detail_root,
					_box(Vector3(0.9, 0.16, 0.04)),
					_rock_face(),
					Vector3(0.0, _terrain_height * 0.55, side * 0.47)
				)
				_add_mesh_child(
					_detail_root,
					_box(Vector3(0.04, 0.16, 0.9)),
					_rock_face(),
					Vector3(side * 0.47, _terrain_height * 0.55, 0.0)
				)
		TerrainType.Type.WATER:
			_add_mesh_child(
				_detail_root,
				_box(Vector3(0.92, 0.012, 0.92)),
				_water_glint(),
				Vector3(0.0, _terrain_height + 0.006, 0.0)
			)
		_:
			pass


static func height_for_terrain(value: int) -> float:
	return float(HEIGHTS.get(value, HEIGHTS[TerrainType.Type.GROUND]))


static func material_for_terrain(
	value: int,
	tile: Vector2i = Vector2i.ZERO
) -> StandardMaterial3D:
	var checker := value == TerrainType.Type.GROUND and ((tile.x + tile.y) & 1) == 1
	var key := "terrain_%d%s" % [value, "_alt" if checker else ""]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = _terrain_color(value, checker)
	material.roughness = 0.9
	material.metallic = 0.0
	if value == TerrainType.Type.WATER:
		material.roughness = 0.22
		material.metallic = 0.05
	elif value == TerrainType.Type.HILL:
		material.roughness = 0.82
	_materials[key] = material
	return material


static func _terrain_color(value: int, checker: bool = false) -> Color:
	match value:
		TerrainType.Type.FOREST:
			return PresentationConfig.PALETTE["forest"].darkened(0.32)
		TerrainType.Type.HILL:
			return PresentationConfig.PALETTE["hill"]
		TerrainType.Type.WATER:
			return PresentationConfig.PALETTE["water"]
		_:
			return PresentationConfig.PALETTE["ground_alt" if checker else "ground"]


static func _shared(
	key: String,
	color: Color,
	roughness: float = 0.9,
	metallic: float = 0.0
) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_materials[key] = material
	return material


static func _fog() -> StandardMaterial3D:
	if _materials.has("fog"):
		return _materials["fog"]
	var material := StandardMaterial3D.new()
	material.albedo_color = PresentationConfig.PALETTE["void"].lightened(0.06)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	_materials["fog"] = material
	return material


static func _wood() -> StandardMaterial3D:
	return _shared("wood", PresentationConfig.PALETTE["wood"], 0.85, 0.0)


static func _gold() -> StandardMaterial3D:
	return _shared("gold", PresentationConfig.PALETTE["mine_gold"], 0.32, 0.7)


static func _shaft() -> StandardMaterial3D:
	return _shared("shaft", PresentationConfig.PALETTE["dark_body"], 0.85, 0.1)


static func _hill_cap() -> StandardMaterial3D:
	return _shared("hill_cap", PresentationConfig.PALETTE["hill"].lightened(0.16), 0.8, 0.0)


static func _rock_face() -> StandardMaterial3D:
	return _shared("rock_face", PresentationConfig.PALETTE["rock"].darkened(0.28), 0.95, 0.0)


static func _water_glint() -> StandardMaterial3D:
	return _shared("water_glint", PresentationConfig.PALETTE["water"].lightened(0.22), 0.15, 0.0)


static func _token() -> StandardMaterial3D:
	if _materials.has("token"):
		return _materials["token"]
	var material := StandardMaterial3D.new()
	material.albedo_color = PresentationConfig.PALETTE["mine_gold"]
	material.roughness = 0.24
	material.metallic = 0.5
	material.emission_enabled = true
	material.emission = PresentationConfig.PALETTE["mine_gold"]
	material.emission_energy_multiplier = 3.0
	_materials["token"] = material
	return material


static func _lamp() -> StandardMaterial3D:
	if _materials.has("lamp"):
		return _materials["lamp"]
	var material := StandardMaterial3D.new()
	material.albedo_color = PresentationConfig.PALETTE["mine_gold"]
	material.emission_enabled = true
	material.emission = PresentationConfig.PALETTE["mine_gold"]
	material.emission_energy_multiplier = 3.0
	_materials["lamp"] = material
	return material


static func _add_mesh_child(
	parent: Node3D,
	mesh: Mesh,
	material: Material,
	mesh_position: Vector3
) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = mesh_position
	parent.add_child(instance)


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh


static func _cylinder(top_radius: float, bottom_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	return mesh
