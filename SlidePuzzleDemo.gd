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
