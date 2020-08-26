extends Node

static func move_is_allowed(piece: Sprite, destination: Vector2) -> bool:
	if piece.name != "BluePiece":
		return true
	return piece.get_meta("current_tile").y == destination.y
