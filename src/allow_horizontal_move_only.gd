extends Node

static func move_is_allowed(piece, destination: Vector2) -> bool:
	if piece.name != "BluePiece":
		return true
	return piece.position.y == destination.y
