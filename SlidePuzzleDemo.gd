extends Node2D


func _on_puzzle_solved(puzzle_name: String) -> void:
	$CanvasLayer/PuzzleSolved.visible = true
	$CanvasLayer/PuzzleSolved/Player.play("Solved")


func _on_nextSlide_button_down():
	$Background.nextSlide()
	$CanvasLayer/PuzzleSolved.visible = false

func _on_previousSlide_button_down():
	$Background.previousSlide()
	$CanvasLayer/PuzzleSolved.visible = false
