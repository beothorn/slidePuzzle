extends Sprite

func nextSlide():
	$Tween.interpolate_property(self, "position:x", position.x, position.x + 1024, 0.2)
	$Tween.start()

func previousSlide():
	$Tween.interpolate_property(self, "position:x", position.x, position.x - 1024, 0.2)
	$Tween.start()
