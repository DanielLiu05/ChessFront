class_name AiConfig
extends RefCounted

const KING_VALUE: float = 10000.0
const QUEEN_VALUE: float = 90.0
const ROOK_VALUE: float = 50.0
const BISHOP_VALUE: float = 30.0
const KNIGHT_VALUE: float = 30.0
const PAWN_VALUE: float = 10.0
const SCOUT_VALUE: float = 15.0
const ENGINEER_VALUE: float = 20.0

const CAPTURE_BONUS: float = 12.0
const MINE_TILE_BONUS: float = 18.0
const MINE_ADJACENT_BONUS: float = 3.0
const GOLD_TOKEN_BONUS: float = 20.0
const MINE_PROGRESS_PER_TILE: float = 6.0
const KING_PROGRESS_PER_TILE: float = 7.0
const KING_THREAT_BONUS: float = 24.0
const FRONTIER_PROGRESS_PER_TILE: float = 2.0
const EXPLORE_BONUS: float = 3.0
const RECRUIT_BASE: float = 10.0
const BRIDGE_BASE: float = 6.0
const BRIDGE_EXPLORE_BONUS: float = 2.0
const THREAT_PENALTY_SCALE: float = 0.2
const REVERSAL_PENALTY: float = 3.0
const PROMOTION_BONUS: float = 12.0
const EMERGENCY_BRIDGE_SCORE: float = 0.1
const NO_DISTANCE: int = 9999


static func unit_value(unit_type: int) -> float:
	match unit_type:
		UnitType.Type.KING:
			return KING_VALUE
		UnitType.Type.QUEEN:
			return QUEEN_VALUE
		UnitType.Type.ROOK:
			return ROOK_VALUE
		UnitType.Type.BISHOP:
			return BISHOP_VALUE
		UnitType.Type.KNIGHT:
			return KNIGHT_VALUE
		UnitType.Type.SCOUT:
			return SCOUT_VALUE
		UnitType.Type.ENGINEER:
			return ENGINEER_VALUE
		_:
			return PAWN_VALUE
