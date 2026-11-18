class_name CosmeticRandom
extends RefCounted


static func rng_for(ply: int, tile: Vector2i, event_type: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d:%s" % [ply, tile.x, tile.y, event_type])
	return rng


static func offsets(
	ply: int,
	tile: Vector2i,
	event_type: String,
	count: int,
	radius: float
) -> Array[Vector3]:
	var rng := rng_for(ply, tile, event_type)
	var result: Array[Vector3] = []
	for index in count:
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(radius * 0.25, radius)
		var lift := rng.randf_range(0.02, 0.22)
		result.append(Vector3(cos(angle) * distance, lift, sin(angle) * distance))
	return result
