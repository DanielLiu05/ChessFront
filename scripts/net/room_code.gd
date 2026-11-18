class_name RoomCode
extends RefCounted

const LENGTH: int = 6
const ALPHABET: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"


static func generate(rng: RandomNumberGenerator = null) -> String:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var code := ""
	for _index in LENGTH:
		var position := generator.randi_range(0, ALPHABET.length() - 1)
		code += ALPHABET.substr(position, 1)
	return code


static func normalize(code: String) -> String:
	return code.strip_edges().to_upper()


static func is_valid(code: String) -> bool:
	var normalized := normalize(code)
	if normalized.length() != LENGTH:
		return false
	for index in normalized.length():
		if ALPHABET.find(normalized.substr(index, 1)) == -1:
			return false
	return true
