extends Node

func _on_SlidePuzzle_piece_moved(piece, new_tile_position):
	if piece.name != "BluePiece":
		return
	if new_tile_position == Vector2(62, 3):
		$SlidePuzzle.set_cell(55, 5, 0)
	else:
		$SlidePuzzle.set_cell(55, 5, -1)
