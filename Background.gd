extends Sprite

func move(new_x_position):
	$Tween.interpolate_property(self, "position:x", position.x, new_x_position, 0.2)
	$Tween.start()
