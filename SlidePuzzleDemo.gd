extends Node2D

func _ready():
	print("Hey")

func _on_puzzle_solved(puzzle_name: String) -> void:
	$CanvasLayer/PuzzleSolved.visible = true
	$CanvasLayer/PuzzleSolved/Player.play("Solved")

func _on_nextSlide_button_down():
	var new_x_position = $Background.position.x + 1024
	$CanvasLayer/previousSlide.visible = new_x_position != 0
	$Background.move(new_x_position)
	$CanvasLayer/PuzzleSolved.visible = false

func _on_previousSlide_button_down():
	var new_x_position = $Background.position.x - 1024
	$CanvasLayer/previousSlide.visible = new_x_position != 0
	$Background.move(new_x_position)
	$CanvasLayer/PuzzleSolved.visible = false


func _on_SlidePuzzle_clicked_tile(pos):
	print("Clicked: "+str(pos))


func _on_SlidePuzzle_piece_entered_goal(piece, goal, tile):
	print("On Goal: Piece "+piece.name+" on goal "+goal.name+" at "+str(tile))


func _on_SlidePuzzle_clicked_piece(piece, tile):
	print("Clicked: Piece "+piece.name+" at "+str(tile))


func _on_SlidePuzzle_piece_moved(piece, tile_from, tile_to):
	print("Moved: Piece "+piece.name+" from "+str(tile_from)+" to "+str(tile_to))


func _on_SlidePuzzle_piece_released(piece, tile):
	print("Released: Piece "+piece.name+" at "+str(tile))
