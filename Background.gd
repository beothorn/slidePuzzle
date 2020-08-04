extends Sprite

func _on_nextSlide_button_down():
	$Tween.interpolate_property(self, "position:x", position.x, position.x + 1024, 0.2)
	$Tween.start()


func _on_previousSlide_button_down():
	$Tween.interpolate_property(self, "position:x", position.x, position.x - 1024, 0.2)
	$Tween.start()
