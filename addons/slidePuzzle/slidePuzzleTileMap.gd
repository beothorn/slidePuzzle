extends TileMap

class_name SlidePuzzle

signal on_piece_ready
signal piece_moved
signal piece_entered_goal
signal puzzle_solved


export(GDScript) var allow_tiles_script
export var puzzle_name: String = "SomePuzzle"
export var drag_area_radius_multiplier = 1.8
export var drag_duration = 0.05


var dragging : Sprite = null

var all_pieces = []
var all_carriers = []
var all_carried = {}
var last_count = 0
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
	
	var solved_count = 0
	for pieces_node in $Pieces.get_children():
		if pieces_node.get_node("Pieces") == null:
			_fail_and_quit("Inside "+pieces_node.name+" you need a node Pieces")
		var pieces = pieces_node.get_node("Pieces").get_children()
		if pieces_node.get_node("Goals") == null:
			_fail_and_quit("Inside "+pieces_node.name+" you need a node Goals")
		var goals = pieces_node.get_node("Goals").get_children()
		
		if pieces.size() != goals.size():
			_fail_and_quit("Puzzle unsolvable for "+ pieces_node.name + " pieces: "+str(pieces.size())+" goals: "+str(goals.size()))
		for piece in pieces:
			emit_signal("on_piece_ready", piece)
			for goal in goals:
				if piece.get_meta("real_position") == goal.position:
					solved_count = solved_count + 1
		all_pieces += pieces_node.get_node("Pieces").get_children()
	last_count = solved_count
	
	if has_node("Carriers"):
		all_carriers = $Carriers.get_children()
	else:
		all_carriers = []
	
	for piece in all_pieces:
		piece.set_meta("real_position", piece.position)
		
	for carrier in all_carriers:
		carrier.set_meta("real_position", carrier.position)
	
	tween = Tween.new()
	add_child(tween)
	tween.connect("tween_completed", self, "_update_on_move")

func _fail_and_quit(msg: String):
	print(msg)
	push_error(msg)
	get_tree().quit()

func set_as_solved() -> void:
	emit_signal("puzzle_solved", puzzle_name)

func _emit_signal_when_piece_is_on_goal(piece):
	var solved_count = 0
	if piece.get_parent().get_parent().get_node("Goals") != null:
		var goals = piece.get_parent().get_parent().get_node("Goals").get_children()
		for goal in goals:
			if piece.get_meta("real_position") == goal.position:
				solved_count = solved_count + 1
				emit_signal("piece_entered_goal", piece, goal)
		last_count = solved_count

func _is_solved(pieces: Array, goals: Array) -> bool:
	var solved_count = 0
	var solved = false
	for piece in pieces:
		for goal in goals:
			var piece_pos = piece.get_meta("real_position")
			var goal_pos = goal.position
			if piece_pos == goal_pos:
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

func _position_is_occupied(piece_to_test: Sprite, pos: Vector2):
	var new_tile = Vector2(pos.x / cell_size.x, pos.y/ cell_size.y)
	
	if "Carrier" in piece_to_test.name:
		for c in all_carriers:
			if c != piece_to_test:
				if c.position == pos:
					return true
		return false
	
	for piece in all_pieces:
		if piece != piece_to_test:
			if piece.get_meta("real_position") == pos:
				return true
	return false

func dont_allow_move(piece: Sprite, piece_path: TileMap, tile_x: int, tile_y: int) -> bool:
	var no_piece_path = true
	if piece_path:
		no_piece_path = piece_path.get_cell(tile_x, tile_y) == -1
	if "Carrier" in piece.name:
		return no_piece_path
	
	var no_free_path = get_cell(tile_x, tile_y) == -1
	
	var is_not_carrier = true
	for c in all_carriers:
		var carrier_tile = tile_pos_to_tile_index(pos_to_tile_pos(c.get_meta("real_position")))
		if carrier_tile == Vector2(tile_x, tile_y):
			is_not_carrier = false
	
	return no_piece_path and no_free_path and is_not_carrier

func _test_if_path_on_x_axis_is_clear(piece, piece_path, old_tile, new_tile) -> bool:
	for i in range(min(old_tile.x, new_tile.x), max(old_tile.x, new_tile.x)):
		var test_position = Vector2(i * cell_size.x, old_tile.y * cell_size.y)
		if _position_is_occupied(piece, test_position):
			return false
		if dont_allow_move(piece, piece_path, i, old_tile.y):
			return false
	return true

func _test_if_path_on_y_axis_is_clear(piece, piece_path, old_tile, new_tile) -> bool:
	for i in range(min(old_tile.y, new_tile.y), max(old_tile.y, new_tile.y)):
		var test_position = Vector2(old_tile.x * cell_size.x, i * cell_size.y)
		if _position_is_occupied(piece, test_position):
			return false
		if dont_allow_move(piece, piece_path, old_tile.x, i):
			return false
	return true

func _test_if_destination_is_allowed(piece, destination) -> bool:
	var new_position = pos_to_tile_pos(destination)
	var new_tile = Vector2(new_position.x / cell_size.x, new_position.y / cell_size.y)
	var old_position = pos_to_tile_pos(piece.get_meta("real_position"))
	var old_tile = Vector2(old_position.x / cell_size.x, old_position.y / cell_size.y)
	
	if allow_tiles_script != null:
		if not allow_tiles_script.move_is_allowed(piece, destination):
			return false
	
	var piece_path: TileMap = null
	if "Carrier" in piece.name:
		if has_node("CarriersPath"):
			piece_path = $CarriersPath
	else:
		piece_path = piece.get_parent().get_parent().get_node("Path")

	var destination_tile_is_not_allowed = dont_allow_move(piece, piece_path, new_position.x / cell_size.x, new_position.y / cell_size.y)
	if destination_tile_is_not_allowed:
		return false
	
	if _position_is_occupied(piece, new_position):
		return false
	
	var is_moving_over_the_x_axis = old_tile.x != new_tile.x and old_tile.y == new_tile.y
	if is_moving_over_the_x_axis and _test_if_path_on_x_axis_is_clear(piece, piece_path, old_tile, new_tile):
		return true
		
	var is_moving_over_the_y_axis = old_tile.y != new_tile.y and old_tile.x == new_tile.x
	if is_moving_over_the_y_axis and _test_if_path_on_x_axis_is_clear(piece, piece_path, old_tile, new_tile):
		return true
	
	return false

func _move_sprite_to(piece, x, y):
	piece.position = piece.get_meta("real_position")
	piece.set_meta("real_position", Vector2(x, y))
	#tween.stop_all()
	tween.interpolate_property(piece, "position", piece.position, Vector2(x, y), drag_duration, Tween.TRANS_LINEAR)
	tween.start()

func move_piece_to(piece, destination):
	var new_position = pos_to_tile_pos(destination)
	var new_tile = Vector2(new_position.x / cell_size.x, new_position.y / cell_size.y)
	var old_position = pos_to_tile_pos(piece.get_meta("real_position"))
	var old_tile = Vector2(old_position.x / cell_size.x, old_position.y / cell_size.y)
	
	if old_tile.x != new_tile.x and old_tile.y == new_tile.y:
		_move_sprite_to(piece, new_position.x, piece.get_meta("real_position").y)
		if "Carrier" in piece.name and piece.name in all_carried:
			_move_sprite_to(all_carried[piece.name], new_position.x, all_carried[piece.name].get_meta("real_position").y)
		else:
			for c in all_carriers:
				if piece.get_meta("real_position") == c.get_meta("real_position"):
					all_carried[c.name] = piece
					dragging = c
			_emit_signal_when_piece_is_on_goal(piece)
			_signal_if_solved()
	
	if old_tile.y != new_tile.y and old_tile.x == new_tile.x:
		_move_sprite_to(piece, piece.get_meta("real_position").x, new_position.y)
		if "Carrier" in piece.name and piece.name in all_carried:
			_move_sprite_to(all_carried[piece.name], all_carried[piece.name].get_meta("real_position").x, new_position.y)
		else:
			for c in all_carriers:
				if piece.get_meta("real_position") == c.get_meta("real_position"):
					all_carried[c.name] = piece
					dragging = c
		_emit_signal_when_piece_is_on_goal(piece)
		_signal_if_solved()

func _update_on_move(piece, path):
	var new_tile_pos = tile_pos_to_tile_index(pos_to_tile_pos(piece.position))
	emit_signal("piece_moved", piece, new_tile_pos)

func _input(event: InputEvent) -> void:
	var mouse_pos = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		var click_pos: Vector2 = pos_to_tile_pos(mouse_pos)
		
		for c in all_carriers:
			if click_pos == pos_to_tile_pos(c.get_meta("real_position")):
				dragging = c
				return
		
		var closest_piece
		var closest_piece_distance = 999999999999
		for piece in all_pieces:
			if click_pos.distance_squared_to(piece.get_meta("real_position")) < closest_piece_distance:
				closest_piece = piece
				closest_piece_distance = click_pos.distance_squared_to(piece.get_meta("real_position"))
		if closest_piece_distance < pow(drag_area_radius_multiplier * 2 * cell_size.x, 2):
			dragging = closest_piece
			return
		
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		dragging = null
		return
		
	if event is InputEventMouseMotion and event.button_mask & BUTTON_LEFT == BUTTON_LEFT:
		if dragging == null:
			return
		var new_position = pos_to_tile_pos(mouse_pos)
		var new_tile = Vector2(new_position.x / cell_size.x, new_position.y / cell_size.y)
		var old_position = pos_to_tile_pos(dragging.get_meta("real_position"))
		var old_tile = Vector2(old_position.x / cell_size.x, old_position.y / cell_size.y)
		
		if new_tile == old_tile:
			return
		
		var is_carrier = "Carrier" in dragging.name
		
		var maybe_carrier
		var dragging_candidate = dragging
		
		if is_carrier:#Carrier needs to fail to find a destination so piece inside can be dragged
			if _test_if_destination_is_allowed(dragging, mouse_pos):
				move_piece_to(dragging, mouse_pos)
				return
			if not dragging.name in all_carried:
				return
			dragging_candidate = all_carried[dragging.name]
		else:
			dragging_candidate = dragging
		
		
		#TEST all tiles in a range and use closest
		var closest_possible_position = mouse_pos
		var possible_positions = []
		var drag_area_radius = cell_size.x * drag_area_radius_multiplier
		for maybe_x in range(new_position.x - drag_area_radius, new_position.x + drag_area_radius, cell_size.x):
			var possible = Vector2(maybe_x, new_position.y)
			if _test_if_destination_is_allowed(dragging_candidate, possible):
				possible_positions.append(possible)
		for maybe_y in range(new_position.y - drag_area_radius, new_position.y + drag_area_radius, cell_size.y):
			var possible = Vector2(new_position.x, maybe_y)
			if _test_if_destination_is_allowed(dragging_candidate, possible):
				possible_positions.append(possible)
		if possible_positions.size() == 0:
			return
		
		var current_distance = 999999999999
		for p in possible_positions:
			if p.distance_squared_to(mouse_pos) < current_distance:
				current_distance = p.distance_squared_to(mouse_pos)
				closest_possible_position = p
		
		var new_closest_position = pos_to_tile_pos(closest_possible_position)
		var new_closest_tile = Vector2(new_closest_position.x / cell_size.x, new_closest_position.y / cell_size.y)
		if new_closest_tile.distance_squared_to(new_tile) > old_tile.distance_squared_to(new_tile) :
			return
		
		if is_carrier:
			all_carried.erase(dragging.name)
		dragging = dragging_candidate
		
		move_piece_to(dragging, closest_possible_position)
	
func pos_to_tile_pos(pos: Vector2) -> Vector2: 
	var x : int = floor(pos.x / cell_size.x) * cell_size.x
	var y : int = floor(pos.y / cell_size.y) * cell_size.y
	return Vector2(x, y)

func tile_pos_to_tile_index(pos: Vector2) -> Vector2: 
	var x : int = floor(pos.x / cell_size.x)
	var y : int = floor(pos.y / cell_size.y)
	return Vector2(x, y)
