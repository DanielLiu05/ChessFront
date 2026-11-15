class_name HudFormat
extends RefCounted


static func movement_text(category: int) -> String:
	match category:
		UnitDefinition.MovementCategory.SINGLE:
			return "Single tile"
		UnitDefinition.MovementCategory.RAY:
			return "Sliding"
		UnitDefinition.MovementCategory.STEP:
			return "Step"
		UnitDefinition.MovementCategory.JUMP:
			return "Jump"
		_:
			return "Unknown"


static func reach_text(info: Dictionary) -> String:
	var category := int(info["movement_category"])
	if category == UnitDefinition.MovementCategory.RAY:
		return "Reach: explored territory"
	if category == UnitDefinition.MovementCategory.JUMP:
		return "Reach: jump"
	var base := int(info["base_reach"])
	var explored := int(info["explored_reach"])
	if base == explored:
		return "Reach: %d" % base
	return "Reach: %d / %d explored" % [base, explored]


static func unit_summary(info: Dictionary) -> String:
	if info.is_empty():
		return "No unit selected."
	var capture_text := "Can capture" if bool(info["can_capture"]) else "Cannot capture"
	var text := "%s (P%d)\n%s\nVision %d | %s\n%s | %s" % [
		String(info["name"]),
		int(info["owner"]),
		String(info["terrain"]),
		int(info["vision"]),
		capture_text,
		movement_text(int(info["movement_category"])),
		reach_text(info),
	]
	if bool(info["can_build_bridges"]):
		text += "\nBuilder: bridges"
	return text


static func unit_compact(info: Dictionary) -> String:
	if info.is_empty():
		return "Tap a unit to select."
	var capture_text := "captures" if bool(info["can_capture"]) else "no capture"
	var text := "%s (P%d) · %s\nVision %d · %s · %s · %s" % [
		String(info["name"]),
		int(info["owner"]),
		String(info["terrain"]),
		int(info["vision"]),
		capture_text,
		movement_text(int(info["movement_category"])),
		reach_text(info),
	]
	if bool(info["can_build_bridges"]):
		text += " · bridges"
	return text


static func draw_reason_text(reason: String) -> String:
	match reason:
		DrawSystem.REASON_TURN_LIMIT:
			return "turn limit"
		DrawSystem.REASON_THREEFOLD:
			return "threefold repetition"
		DrawSystem.REASON_AGREEMENT:
			return "agreement"
		_:
			return reason


static func draw_detail_text(reason: String) -> String:
	match reason:
		DrawSystem.REASON_TURN_LIMIT:
			return "The turn limit was reached."
		DrawSystem.REASON_THREEFOLD:
			return "The same position occurred three times."
		DrawSystem.REASON_AGREEMENT:
			return "Both players agreed to a draw."
		_:
			return reason
