extends Node2D

func _ready():
	set_process(false)
	set_process_input(false)
	set_physics_process(false)
	update()

onready var _line_start_pos := Vector2(0,0)
onready var _tail_location := Vector2(0,0)

func _draw():
	position.x = 0
	position.y = -8 + get_parent().get_node("NinePatchRect").margin_bottom

	# Set draw transform to global coordinates
	var inv = get_global_transform().inverse()
	draw_set_transform(inv.get_origin(), inv.get_rotation(), inv.get_scale())

	_line_start_pos = get_global_transform().origin
	_tail_location =  get_global_mouse_position()

	# If in process of connecting to another potential node
	if MainCamera.CURRENT_CONNECTION_HEAD_NODE == get_parent():
		draw_circle(_line_start_pos, 2, Color.white)
		draw_line(_line_start_pos, _tail_location, Color.white, 4, true)

	# If node has a defined tail node
	var tail : String = get_parent().tail
	if tail != "" and Editor.blocks.has_node(tail):
		var tail_node = Editor.blocks.get_node(tail)
		if tail_node == null:
			get_parent().set_tail("")
			return
		_tail_location = tail_node.rect_position
		_tail_location.y += 14
		draw_circle(_line_start_pos, 2, Color.white)
		draw_line(_line_start_pos, _tail_location, Color("eaeaea"), 4, true)
		draw_circle(_tail_location, 10, Color.white)