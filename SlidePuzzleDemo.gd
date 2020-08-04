extends Node2D


func _on_FirstExample_puzzle_solved(puzzle_name: String) -> void:
	if puzzle_name == "First":
		$Slide1/PuzzleSolved.visible = true
		$Slide1/PuzzleSolved/Player.play("Solved")
