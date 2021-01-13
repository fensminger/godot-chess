extends Control

signal clicked
signal unclicked
signal moved

export var square_width = 64 # pixels (same as chess piece images)
export(Color) var white # Square color
export(Color) var grey # Square color
export(Color) var mod_color # For highlighting squares

const num_squares = 64
enum { SIDE, KEY, PIECE_REF } # Black/white side, piece key , ref to object

var grid : Array # Map of what pieces are placed on the board

func _ready():
	# grid will map the pieces in the game
	grid.resize(num_squares)
	draw_tiles()
	setup_pieces() # Starting positions
	#test_square_is_white()
	#test_highlight_square()


func setup_pieces():
	var seq = "PPPPPPPPRNBQKBNRPPPPPPPP" # Arrangement order for chess pieces
	for i in 16:
		# Place black pieces
		var p = Pieces.get_piece(seq[i + 8], "B")
		$Grid.get_child(i).add_child(p)
		grid[i] = ["B", seq[i + 8], p]
		# Place white pieces
		p = Pieces.get_piece(seq[i])
		$Grid.get_child(i + 48).add_child(p)
		grid[i + 48] = ["W", seq[i], p]


func draw_tiles():
	var white_square = ColorRect.new()
	white_square.color = white
	white_square.mouse_filter = Control.MOUSE_FILTER_PASS
	white_square.rect_min_size = Vector2(square_width, square_width)
	var grey_square = white_square.duplicate()
	grey_square.color = grey
	# Add squares to grid
	var odd = true
	for y in 8:
		odd = !odd
		for x in 8:
			odd = !odd
			if odd:
				add_square(white_square.duplicate(), x, y)
			else:
				add_square(grey_square.duplicate(), x, y)


func add_square(s: ColorRect, x: int, y: int):
	s.connect("gui_input", self, "square_event", [x, y])
	$Grid.add_child(s)


func square_event(event: InputEvent, x: int, y: int):
	if event is InputEventMouseButton:
		get_tree().set_input_as_handled()
		print("Clicked at: ", [x, y])
		var p = get_piece_in_grid(x, y)
		print(p)
		if event.pressed:
			if p != null:
				emit_signal("clicked", x, y, p[SIDE], p[KEY], p[PIECE_REF])
		else:
			emit_signal("unclicked", x, y, p[SIDE], p[KEY], p[PIECE_REF])
	# Mouse position is relative to the square
	if event is InputEventMouseMotion:
		emit_signal("moved", event.position)


func get_piece_in_grid(x: int, y: int):
	var p = grid[x + 8 * y]
	return p


func test_highlight_square():
	for n in num_squares:
		highlight_square(n)
		yield(get_tree().create_timer(0.1), "timeout")
		highlight_square(n, false)


func highlight_square(n: int, apply = true):
	assert(n >= 0)
	assert(n < num_squares)
	var sqr: ColorRect = $Grid.get_child(n)
	if apply:
		sqr.color = mod_color
	else:
		if square_is_white(n):
			sqr.color = white
		else:
			sqr.color = grey


func test_square_is_white():
	for n in num_squares:
		if $Grid.get_child(n).color == white:
			assert(square_is_white(n))
		else:
			assert(!square_is_white(n))


func square_is_white(n: int):
# warning-ignore:integer_division
	return 0 == ((n / 8) + n) % 2
