extends TileMap

class_name SlidePuzzle

signal on_piece_ready
signal piece_moved
signal piece_entered_goal
signal puzzle_solved

signal clicked_tile
signal dragged_over_tile
signal released_on_tile


export(GDScript) var allow_tiles_script
export var puzzle_name: String = "SomePuzzle"
export var drag_area: int = 2
export var drag_duration: float = 0.05


var dragging : Sprite = null

var all_pieces: Array = []
var all_carriers: Array = []
var all_carried: Dictionary = {}
var last_count: int = 0
var tween: Tween

func _ready():
	if $Pieces == null:
		_fail_and_quit("""You need a node Pieces
		Inside this node you need one node for each piece
		for example, node Blue
		Inside this node you need another node Pieces, a node Goals 
		and an optional TileMap with the allowed path for this piece
		Inside Pieces put Sprites for the pieces
		Inside Goals put Sprites for the goals""")
	
	_get_pieces_from_pieces_node()
	
	for piece in all_pieces:
		_tile_set(piece, pos_to_tile_index(piece.position)) 
		
	for goal in _all_goals():
		_tile_set(goal, pos_to_tile_index(goal.position)) 
	
	var solved_count = 0

	for piece in all_pieces:
		emit_signal("on_piece_ready", piece)
		for goal in _get_goals_for_piece(piece):
			if _tile(piece) == _tile(goal):
				solved_count = solved_count + 1
		
	last_count = solved_count
	
	if has_node("Carriers"):
		all_carriers = $Carriers.get_children()
	else:
		all_carriers = []
	
		
	for carrier in all_carriers:
		_tile_set(carrier, pos_to_tile_index(carrier.position))
	
	tween = Tween.new()
	add_child(tween)
	tween.connect("tween_completed", self, "_update_on_move")

func _fail_and_quit(msg: String):
	print(msg)
	push_error(msg)
	get_tree().quit()

func set_as_solved() -> void:
	emit_signal("puzzle_solved", puzzle_name)

func _get_pieces_from_pieces_node():
	for pieces_node in $Pieces.get_children():
		
		if pieces_node.get_node("Pieces") == null:
			_fail_and_quit("Inside "+pieces_node.name+" you need a node Pieces")
		if pieces_node.get_node("Goals") == null:
			_fail_and_quit("Inside "+pieces_node.name+" you need a node Goals")
		
			
		var pieces: Array = pieces_node.get_node("Pieces").get_children()
		var goals: Array = pieces_node.get_node("Goals").get_children()
		
		var pieces_with_children = pieces
		
		for p in pieces:
			if p.get_child_count() > 0:
				pieces_with_children += p.get_children()
				
		all_pieces += pieces_with_children
		
		if pieces_with_children.size() != goals.size():
			_fail_and_quit("Puzzle unsolvable for "+ pieces_node.name + " pieces: "+str(pieces_with_children.size())+" goals: "+str(goals.size()))

func _all_goals():
	var all_goals = []
	for pieces_node in $Pieces.get_children():
		all_goals += pieces_node.get_node("Goals").get_children()
	return all_goals

func _get_goals_for_piece(piece):
	if piece.get_parent().get_parent().has_node("Goals"):
		return piece.get_parent().get_parent().get_node("Goals").get_children()
	if piece.get_parent().get_parent().get_parent().has_node("Goals"):
		return piece.get_parent().get_parent().get_parent().get_node("Goals").get_children()
	_fail_and_quit("Piece "+piece.name+" has no goals")

func _tile(piece: Sprite) -> Vector2:
	return piece.get_meta("current_tile")

func _tile_set(piece: Sprite, tile: Vector2) -> void:
	piece.set_meta("current_tile", tile)
	
func _emit_signal_when_piece_is_on_goal(piece):
	var solved_count = 0
	if piece.get_parent().get_parent().has_node("Goals"):
		var goals = _get_goals_for_piece(piece)
		for goal in goals:
			if _tile(piece) == _tile(goal):
				solved_count = solved_count + 1
				emit_signal("piece_entered_goal", piece, goal)
		last_count = solved_count

func _is_solved(pieces: Array, goals: Array) -> bool:
	var solved_count = 0
	var solved = false
	for piece in pieces:
		for goal in goals:
			if _tile(piece) == _tile(goal):
				solved_count = solved_count + 1
	return solved_count == goals.size()

func _signal_if_solved():
	for pieces_node in $Pieces.get_children():
		if pieces_node:
			var pieces = pieces_node.get_node("Pieces").get_children()
			var goals = pieces_node.get_node("Goals").get_children()
			if not _is_solved(pieces, goals):
				return
	set_as_solved()

func _position_is_occupied(piece_to_test: Sprite, new_tile: Vector2):
	
	if "Carrier" in piece_to_test.name:
		for c in all_carriers:
			if c != piece_to_test and _tile(c) == _tile(piece_to_test):
				return true
		return false
	
	var all_pieces_in_family =  _all_related_pieces(piece_to_test)
	
	for piece in all_pieces:
		if not piece in all_pieces_in_family:
			var a = _tile(piece)
			var b = _tile(piece_to_test)
			if _tile(piece) == new_tile:
				return true
			
	return false

func dont_allow_move(piece: Sprite, piece_path: TileMap, tile: Vector2) -> bool:
	var no_piece_path = true
	if piece_path:
		no_piece_path = piece_path.get_cell(tile.x, tile.y) == -1
	if "Carrier" in piece.name:
		return no_piece_path
	
	var no_free_path = get_cell(tile.x, tile.y) == -1
	
	var is_not_carrier = true
	for c in all_carriers:
		var carrier_tile = tile_pos_to_tile_index(pos_to_tile_pos(c.get_meta("current_tile")))
		if carrier_tile == tile:
			is_not_carrier = false
	
	return no_piece_path and no_free_path and is_not_carrier

func _test_if_path_on_x_axis_is_clear(piece, piece_path, old_tile, new_tile) -> bool:
	for i in range(min(old_tile.x, new_tile.x), max(old_tile.x, new_tile.x)):
		var test_position = Vector2(i , old_tile.y)
		if _position_is_occupied(piece, test_position):
			return false
		if dont_allow_move(piece, piece_path, test_position):
			return false
	return true

func _test_if_path_on_y_axis_is_clear(piece, piece_path, old_tile, new_tile) -> bool:
	for i in range(min(old_tile.y, new_tile.y), max(old_tile.y, new_tile.y)):
		var test_position = Vector2(old_tile.x, i)
		if _position_is_occupied(piece, test_position):
			return false
		if dont_allow_move(piece, piece_path, test_position):
			return false
	return true

func _test_if_destination_is_allowed(piece: Sprite, new_tile: Vector2) -> bool:
	var old_tile: Vector2 = _tile(piece)
	
	if allow_tiles_script != null:
		if not allow_tiles_script.move_is_allowed(piece, new_tile):
			return false
	
	var piece_path: TileMap = null
	if "Carrier" in piece.name:
		if has_node("CarriersPath"):
			piece_path = $CarriersPath
	else:
		if piece.get_parent().get_parent().has_node("Path"):
			piece_path = piece.get_parent().get_parent().get_node("Path")

	var destination_tile_is_not_allowed = dont_allow_move(piece, piece_path, new_tile)
	if destination_tile_is_not_allowed:
		return false
	
	if _position_is_occupied(piece, new_tile):
		return false
	
	var is_moving_over_the_x_axis: bool = old_tile.x != new_tile.x and old_tile.y == new_tile.y
	if is_moving_over_the_x_axis and _test_if_path_on_x_axis_is_clear(piece, piece_path, old_tile, new_tile):
		return true
		
	var is_moving_over_the_y_axis: bool = old_tile.y != new_tile.y and old_tile.x == new_tile.x
	if is_moving_over_the_y_axis and _test_if_path_on_y_axis_is_clear(piece, piece_path, old_tile, new_tile):
		return true
	
	return false

func _move_sprite_to(piece: Sprite, tile: Vector2) -> void:
	piece.position = tile_to_pos(_tile(piece))
	var delta: Vector2 = tile - _tile(piece)
	_tile_set(piece, tile)
	
	for c in piece.get_children():
		_tile_set(c, _tile(c) + delta)
		
	#tween.stop_all()
	tween.interpolate_property(piece, "position", piece.position, tile_to_pos(tile), drag_duration, Tween.TRANS_LINEAR)
	tween.start()

func move_piece_to(piece, new_tile):
	var old_tile = _tile(piece)
	
	if old_tile.x != new_tile.x and old_tile.y == new_tile.y:
		_move_sprite_to(piece, Vector2(new_tile.x, _tile(piece).y))
		if "Carrier" in piece.name and piece.name in all_carried:
			_move_sprite_to(all_carried[piece.name], Vector2(new_tile.x, _tile(all_carried[piece.name]).y))
		else:
			for c in all_carriers:
				if _tile(piece) == _tile(c):
					all_carried[c.name] = piece
					dragging = c
			_emit_signal_when_piece_is_on_goal(piece)
			_signal_if_solved()
	
	if old_tile.y != new_tile.y and old_tile.x == new_tile.x:
		_move_sprite_to(piece, Vector2(_tile(piece).x, new_tile.y))
		if "Carrier" in piece.name and piece.name in all_carried:
			_move_sprite_to(all_carried[piece.name], Vector2(_tile(all_carried[piece.name]).x, new_tile.y))
		else:
			for c in all_carriers:
				if _tile(piece) == _tile(c):
					all_carried[c.name] = piece
					dragging = c
		_emit_signal_when_piece_is_on_goal(piece)
		_signal_if_solved()

func _update_on_move(piece, path):
	var new_tile_pos = tile_pos_to_tile_index(pos_to_tile_pos(piece.position))
	emit_signal("piece_moved", piece, new_tile_pos)

func _on_button_down(mouse_pos) -> void:
	var click_pos: Vector2 = pos_to_tile_index(mouse_pos)
		
	for c in all_carriers:
		if click_pos == _tile(c):
			dragging = c
			return
	
	var closest_piece
	var closest_piece_distance = 999999999999
	for piece in all_pieces:
		var piece_tile = _tile(piece)
		if click_pos.distance_squared_to(piece_tile) < closest_piece_distance:
			closest_piece = piece
			closest_piece_distance = click_pos.distance_squared_to(piece_tile)
	if closest_piece_distance < 2:
		dragging = closest_piece

func _on_button_release() -> void:
	dragging = null

func _all_related_pieces(piece: Sprite) -> Array:
	var result: Array = piece.get_children()
	
	if piece.get_parent().name != "Pieces" and piece.get_parent().name != "Carriers":
		result.append(piece.get_parent())
		result += piece.get_parent().get_children()
	else:
		result.append(piece)
	return result

func _find_main_piece(piece: Sprite):
	if piece.get_parent().name == "Pieces" or piece.get_parent().name == "Carriers":
		return piece
	return piece.get_parent()

func _on_drag(mouse_pos):
	if dragging == null:
		return
		
	var mouse_tile: Vector2 = pos_to_tile_index(mouse_pos)
	
	if mouse_tile == _tile(dragging):
		return
	
	var is_carrier = "Carrier" in dragging.name
	
	var maybe_carrier
	var dragging_candidate: Sprite = dragging
	
	if is_carrier:#Carrier needs to fail to find a destination so piece inside can be dragged
		if _test_if_destination_is_allowed(dragging, mouse_tile):
			move_piece_to(dragging, mouse_tile)
			return
		if not dragging.name in all_carried:
			return
		dragging_candidate = all_carried[dragging.name]
	else:
		dragging_candidate = dragging
	
	
	#TEST all tiles in a range and use closest
	
	
	##FIND ALL PIECES HERE AND TREAT THEM EQUALLY
	var piece_family: Array = _all_related_pieces(dragging_candidate)
	
	var closest_possible_position = mouse_pos
	var possible_positions = []
	
	for x_delta in range(-drag_area, drag_area):
		var piece_family_is_allowed: bool = true
		for p in piece_family:
			var maybe_x =  mouse_tile.x + x_delta
			var possible = Vector2(maybe_x, mouse_tile.y)
			piece_family_is_allowed = piece_family_is_allowed and _test_if_destination_is_allowed(p, possible)
		
		if piece_family_is_allowed:
			var new_x =  mouse_tile.x + x_delta
			var possible = Vector2(new_x, mouse_tile.y)
			possible_positions.append(possible)
	
	for y_delta in range(-drag_area, drag_area):
		var piece_family_is_allowed: bool = true
		
		for p in piece_family:
			var maybe_y = mouse_tile.y + y_delta
			var possible = Vector2(mouse_tile.x, maybe_y)
			piece_family_is_allowed = piece_family_is_allowed and _test_if_destination_is_allowed(p, possible)
		
		if piece_family_is_allowed:
			var new_y =  mouse_tile.y + y_delta
			var possible = Vector2(mouse_tile.x, new_y)
			possible_positions.append(possible)
			
	if possible_positions.size() == 0:
		return
	
	var current_distance = 999999999999
	for p in possible_positions:
		if p.distance_squared_to(mouse_tile) < current_distance:
			current_distance = p.distance_squared_to(mouse_tile)
			closest_possible_position = p
	
	if closest_possible_position.distance_squared_to(mouse_tile) > _tile(dragging).distance_squared_to(mouse_tile) :
		return
	
	if is_carrier:
		all_carried.erase(dragging.name)
	dragging = dragging_candidate
	
	##FIND MAIN PIECE HERE to move to
	move_piece_to(_find_main_piece(dragging), closest_possible_position)

func _input(event: InputEvent) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_button_down(mouse_pos)
		return
		
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		_on_button_release()
		return
		
	if event is InputEventMouseMotion and event.button_mask & BUTTON_LEFT == BUTTON_LEFT:
		_on_drag(mouse_pos)
		return


func tile_to_pos(tile: Vector2) -> Vector2: 
	return tile * cell_size
		
func pos_to_tile_index(pos: Vector2) -> Vector2: 
	return tile_pos_to_tile_index(pos_to_tile_pos(pos))
	
func pos_to_tile_pos(pos: Vector2) -> Vector2: 
	var x : int = floor(pos.x / cell_size.x) * cell_size.x
	var y : int = floor(pos.y / cell_size.y) * cell_size.y
	return Vector2(x, y)

func tile_pos_to_tile_index(pos: Vector2) -> Vector2: 
	var x : int = floor(pos.x / cell_size.x)
	var y : int = floor(pos.y / cell_size.y)
	return Vector2(x, y)
