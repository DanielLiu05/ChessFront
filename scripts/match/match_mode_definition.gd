class_name MatchModeDefinition
extends Resource

enum OpponentKind {
	AI,
	ONLINE_HUMAN,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var opponent_kind: OpponentKind = OpponentKind.AI
@export var enabled: bool = true


func uses_ai() -> bool:
	return opponent_kind == OpponentKind.AI


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if id.strip_edges().is_empty():
		errors.append("Mode id is empty")
	elif id != id.strip_edges():
		errors.append("Mode id '%s' has leading or trailing whitespace" % id)
	if display_name.strip_edges().is_empty():
		errors.append("Mode '%s' has no display name" % id)
	if opponent_kind != OpponentKind.AI and opponent_kind != OpponentKind.ONLINE_HUMAN:
		errors.append("Mode '%s' has an unknown opponent kind" % id)
	return errors
