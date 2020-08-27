extends Node

func _on_SlidePuzzle_piece_moved(piece, from, to):
	if piece.name != "BluePiece":
		return
	if to == Vector2(62, 3):
		$SlidePuzzle.set_cell(55, 5, 0)
	else:
		$SlidePuzzle.set_cell(55, 5, -1)
