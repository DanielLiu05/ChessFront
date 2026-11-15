class_name BoardView
extends Node3D

signal tile_clicked(tile: Vector2i)
signal tile_hovered(tile: Vector2i)

const TILE_SCENE: PackedScene = preload("res://scenes/board/Tile.tscn")
const PIECE_SCENE: PackedScene = preload("res://scenes/pieces/Piece.tscn")
const PICK_COLLISION_MASK: int = 1 << 0
const NO_TILE: Vector2i = Vector2i(-1, -1)

const MOVE_COLOR: Color = Color(0.2, 0.95, 0.35, 0.5)
const CAPTURE_COLOR: Color = Color(1.0, 0.25, 0.2, 0.58)
const BRIDGE_BUILD_COLOR: Color = Color(0.2, 0.85, 1.0, 0.58)
const BRIDGE_DESTROY_COLOR: Color = Color(1.0, 0.55, 0.1, 0.58)
const RECRUIT_COLOR: Color = Color(0.35, 0.6, 1.0, 0.5)
const SELECT_COLOR: Color = Color(1.0, 0.9, 0.2, 0.65)
const HOVER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.25)

static var _highlight_materials: Dictionary[Color, StandardMaterial3D] = {}

var tile_views: Dictionary[Vector2i, TileView] = {}
var piece_views: Dictionary[int, PieceView] = {}
var current_view: PlayerView
var touch_input_enabled: bool = false
var mobile_quality: bool = false

var _piece_root: Node3D
var _highlight_root: Node3D
var _effect_root: Node3D
var _hover_tile: Vector2i = NO_TILE
var _selection_tile: Vector2i = NO_TILE
var _move_tiles: Array[Vector2i] = []
var _capture_tiles: Array[Vector2i] = []
var _bridge_build_tiles: Array[Vector2i] = []
var _bridge_destroy_tiles: Array[Vector2i] = []
var _recruit_tiles: Array[Vector2i] = []
var _highlight_nodes: Array[MeshInstance3D] = []
var _active_highlight_tiles: Dictionary[Vector2i, bool] = {}


func build(board: BoardData) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	tile_views.clear()
	piece_views.clear()
	_highlight_nodes.clear()
	_active_highlight_tiles.clear()
	current_view = null
	_hover_tile = NO_TILE
	_selection_tile = NO_TILE
	_clear_highlight_arrays()
	_piece_root = Node3D.new()
	_piece_root.name = "Pieces"
	add_child(_piece_root)
	_highlight_root = Node3D.new()
	_highlight_root.name = "Highlights"
	add_child(_highlight_root)
	_effect_root = Node3D.new()
	_effect_root.name = "Effects"
	add_child(_effect_root)
	for tile: Vector2i in board.get_playable_tiles():
		var data := board.get_tile(tile)
		var view := TILE_SCENE.instantiate() as TileView
		view.setup(tile, data.terrain, tile_to_world(tile))
		view.set_decorations_enabled(not mobile_quality)
		add_child(view)
		tile_views[tile] = view


func set_mobile_quality(enabled: bool) -> void:
	mobile_quality = enabled
	for view: TileView in tile_views.values():
		view.set_decorations_enabled(not enabled)


func update_from_view(
	view: PlayerView,
	mine_tiles: Array[Vector2i],
	token_tiles: Array[Vector2i]
) -> void:
	if view == null:
		return
	current_view = view
	var mines: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in mine_tiles:
		mines[tile] = true
	var tokens: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in token_tiles:
		tokens[tile] = true
	for tile: Vector2i in tile_views:
		var data := view.board.get_tile(tile)
		if data == null:
			continue
		var fog := TileView.FogState.VISIBLE
		if not view.knowledge.is_explored(tile):
			fog = TileView.FogState.UNEXPLORED
		elif not view.knowledge.is_visible(tile):
			fog = TileView.FogState.EXPLORED
		tile_views[tile].set_view(
			data.terrain,
			data.has_bridge,
			fog,
			mines.has(tile),
			tokens.has(tile)
		)
	_update_pieces(view)
	_rebuild_highlights()


func set_highlights(
	selection_tile: Vector2i,
	move_tiles: Array[Vector2i],
	capture_tiles: Array[Vector2i],
	bridge_build_tiles: Array[Vector2i],
	bridge_destroy_tiles: Array[Vector2i],
	recruit_tiles: Array[Vector2i]
) -> void:
	_selection_tile = selection_tile
	_move_tiles.clear()
	_move_tiles.append_array(move_tiles)
	_capture_tiles.clear()
	_capture_tiles.append_array(capture_tiles)
	_bridge_build_tiles.clear()
	_bridge_build_tiles.append_array(bridge_build_tiles)
	_bridge_destroy_tiles.clear()
	_bridge_destroy_tiles.append_array(bridge_destroy_tiles)
	_recruit_tiles.clear()
	_recruit_tiles.append_array(recruit_tiles)
	_rebuild_highlights()


func clear_highlights() -> void:
	_selection_tile = NO_TILE
	_clear_highlight_arrays()
	_rebuild_highlights()


func has_highlight(tile: Vector2i) -> bool:
	return _active_highlight_tiles.has(tile)


func highlighted_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in _active_highlight_tiles:
		tiles.append(tile)
	tiles.sort_custom(_sort_tiles)
	return tiles


func get_piece_view(unit_id: int) -> PieceView:
	return piece_views.get(unit_id) as PieceView


func get_tile_view(tile: Vector2i) -> TileView:
	return tile_views.get(tile) as TileView


func get_world_bounds() -> Rect2:
	if tile_views.is_empty():
		return Rect2(
			Vector2(-GameConfig.BOARD_WIDTH * 0.5, -GameConfig.BOARD_HEIGHT * 0.5),
			Vector2(GameConfig.BOARD_WIDTH, GameConfig.BOARD_HEIGHT)
		)
	var min_x := INF
	var min_z := INF
	var max_x := -INF
	var max_z := -INF
	for tile: Vector2i in tile_views:
		var world := tile_to_world(tile, 0.0)
		min_x = minf(min_x, world.x - 0.5)
		max_x = maxf(max_x, world.x + 0.5)
		min_z = minf(min_z, world.z - 0.5)
		max_z = maxf(max_z, world.z + 0.5)
	return Rect2(
		Vector2(min_x, min_z),
		Vector2(max_x - min_x, max_z - min_z)
	)


func get_visible_unit_ids() -> Array[int]:
	var ids: Array[int] = []
	for unit_id: int in piece_views:
		ids.append(unit_id)
	ids.sort()
	return ids


func animate_move(
	unit_id: int,
	from_tile: Vector2i,
	to_tile: Vector2i,
	duration: float = 0.25
) -> Tween:
	var piece := get_piece_view(unit_id)
	if piece == null or from_tile == to_tile:
		return null
	var target := piece.position
	piece.position = _piece_world_position(from_tile)
	var tween := piece.create_tween()
	tween.tween_property(piece, "position", target, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tween


func spawn_effect(tile: Vector2i, color: Color) -> void:
	if _effect_root == null:
		return
	var effect := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.18
	mesh.outer_radius = 0.3
	mesh.rings = 16
	mesh.ring_segments = 8
	effect.mesh = mesh
	effect.material_override = _effect_material(color)
	effect.position = tile_to_world(tile, _highlight_height(tile) + 0.05)
	effect.scale = Vector3(0.3, 0.3, 0.3)
	_effect_root.add_child(effect)
	var tween := effect.create_tween()
	tween.tween_property(effect, "scale", Vector3(1.5, 1.5, 1.5), 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(effect.queue_free)


func pulse_piece(unit_id: int) -> void:
	var piece := get_piece_view(unit_id)
	if piece != null:
		piece.play_spawn_animation()


func screen_position_for_tile(tile: Vector2i) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not tile_views.has(tile):
		return Vector2(-INF, -INF)
	var view := tile_views[tile] as TileView
	return camera.unproject_position(
		tile_to_world(tile, view.surface_height())
	)


func nearest_screen_tile(
	screen_position: Vector2,
	candidates: Array[Vector2i],
	radius: float
) -> Vector2i:
	var best := NO_TILE
	var best_distance := maxf(radius, 0.0)
	for tile: Vector2i in candidates:
		if not tile_views.has(tile):
			continue
		var center := screen_position_for_tile(tile)
		var distance := screen_position.distance_to(center)
		if distance <= best_distance:
			best_distance = distance
			best = tile
	return best


func tile_from_screen(screen_position: Vector2) -> Vector2i:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return NO_TILE
	var from := camera.project_ray_origin(screen_position)
	var to := from + camera.project_ray_normal(screen_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PICK_COLLISION_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NO_TILE
	var collider := hit.get("collider") as Node
	if collider == null or not collider.has_meta("tile"):
		return NO_TILE
	var tile_value: Variant = collider.get_meta("tile")
	if not (tile_value is Vector2i):
		return NO_TILE
	return tile_value


func _unhandled_input(event: InputEvent) -> void:
	if touch_input_enabled and event is InputEventMouse:
		var mouse_event := event as InputEventMouse
		if mouse_event.device == InputEvent.DEVICE_ID_EMULATION:
			return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var tile := tile_from_screen(motion.position)
		if tile != _hover_tile:
			_hover_tile = tile
			_rebuild_highlights()
			tile_hovered.emit(tile)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			var tile := tile_from_screen(mouse.position)
			if tile != NO_TILE:
				tile_clicked.emit(tile)
				get_viewport().set_input_as_handled()


func _update_pieces(view: PlayerView) -> void:
	var seen: Dictionary[int, bool] = {}
	for unit: GameUnit in view.get_known_units():
		seen[unit.id] = true
		var world := _piece_world_position(unit.tile)
		var piece := get_piece_view(unit.id)
		if piece == null:
			piece = PIECE_SCENE.instantiate() as PieceView
			piece.setup(unit.id, unit.type, unit.owner, unit.tile, world)
			_piece_root.add_child(piece)
			if piece.is_inside_tree():
				piece.play_spawn_animation()
			piece_views[unit.id] = piece
		else:
			piece.update_unit(unit.type, unit.owner, unit.tile, world)
	for unit_id: int in piece_views.keys():
		if seen.has(unit_id):
			continue
		var stale := piece_views[unit_id] as PieceView
		piece_views.erase(unit_id)
		if stale != null:
			_piece_root.remove_child(stale)
			stale.queue_free()


func _piece_world_position(tile: Vector2i) -> Vector3:
	var tile_view := tile_views.get(tile) as TileView
	var height := tile_view.surface_height() if tile_view != null else 0.12
	return tile_to_world(tile, height)


func _clean_highlights() -> void:
	for node: MeshInstance3D in _highlight_nodes:
		if is_instance_valid(node):
			node.free()
	_highlight_nodes.clear()
	_active_highlight_tiles.clear()


func _rebuild_highlights() -> void:
	if _highlight_root == null:
		return
	_clean_highlights()
	var colors: Dictionary[Vector2i, Color] = {}
	for tile: Vector2i in _move_tiles:
		colors[tile] = MOVE_COLOR
	for tile: Vector2i in _capture_tiles:
		colors[tile] = CAPTURE_COLOR
	for tile: Vector2i in _bridge_build_tiles:
		colors[tile] = BRIDGE_BUILD_COLOR
	for tile: Vector2i in _bridge_destroy_tiles:
		colors[tile] = BRIDGE_DESTROY_COLOR
	for tile: Vector2i in _recruit_tiles:
		colors[tile] = RECRUIT_COLOR
	if _selection_tile != NO_TILE:
		colors[_selection_tile] = SELECT_COLOR
	for tile: Vector2i in colors:
		_add_highlight(tile, colors[tile], 0.0)
		_active_highlight_tiles[tile] = true
	if _hover_tile.x >= 0:
		_add_highlight(_hover_tile, HOVER_COLOR, 0.015)


func _add_highlight(tile: Vector2i, color: Color, extra_height: float) -> void:
	var tile_view := tile_views.get(tile) as TileView
	if tile_view == null:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.012, 0.9)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _highlight_material(color)
	instance.position = tile_to_world(tile, tile_view.highlight_height() + extra_height)
	_highlight_root.add_child(instance)
	_highlight_nodes.append(instance)


func _highlight_height(tile: Vector2i) -> float:
	var tile_view := tile_views.get(tile) as TileView
	if tile_view == null:
		return 0.15
	return tile_view.highlight_height()


func _clear_highlight_arrays() -> void:
	_move_tiles.clear()
	_capture_tiles.clear()
	_bridge_build_tiles.clear()
	_bridge_destroy_tiles.clear()
	_recruit_tiles.clear()


static func _highlight_material(color: Color) -> StandardMaterial3D:
	if _highlight_materials.has(color):
		return _highlight_materials[color]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_highlight_materials[color] = material
	return material


static func _effect_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _sort_tiles(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x


static func tile_to_world(tile: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(
		tile.x - (GameConfig.BOARD_WIDTH - 1) * 0.5,
		height,
		tile.y - (GameConfig.BOARD_HEIGHT - 1) * 0.5
	)


static func world_to_tile(world_position: Vector3) -> Vector2i:
	return Vector2i(
		roundi(world_position.x + (GameConfig.BOARD_WIDTH - 1) * 0.5),
		roundi(world_position.z + (GameConfig.BOARD_HEIGHT - 1) * 0.5)
	)
