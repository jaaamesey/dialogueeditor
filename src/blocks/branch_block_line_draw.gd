extends Node2D

func _ready():
	set_process(true)
	set_process_input(false)
	set_physics_process(false)
	update()


onready var _tail_locations := [Vector2(), Vector2(), Vector2(), Vector2(), Vector2(), Vector2()]

func _process(delta):
	if Input.is_action_pressed("click"):
		update()
	set_process(true)


func _draw():
	position.x = 0
	position.y = -10 + get_parent().get_node("NinePatchRect").margin_bottom

	# Set draw transform to global coordinates
	var inv = get_global_transform().inverse()
	draw_set_transform(inv.get_origin(), inv.get_rotation(), inv.get_scale())

	var selected_tail = 0
	var line_start_pos = Vector2()
	line_start_pos.x = 18 + get_parent().get_selected_tail_connector().rect_global_position.x
	line_start_pos.y = get_global_transform().origin.y
	_tail_locations[selected_tail] =  get_global_mouse_position()
	var line_color = get_parent().get_selected_tail_connector().get_parent().modulate
	# If in process of connecting to another potential node

	if MainCamera.CURRENT_CONNECTION_HEAD_NODE == get_parent():
		draw_circle(line_start_pos, 2, line_color)
		draw_line(line_start_pos, _tail_locations[selected_tail], line_color, 4, true)

	# If node has a defined tail node
	if !get_parent().tails.empty():
		for i in range(get_parent().tails.size()):
			var tail = get_parent().tails[i]
			if tail != null and tail != "":
				if !Editor.blocks.has_node(tail):
					get_parent().tails[i] = ""
					get_parent().update_choices()
					continue
				var tail_block = Editor.blocks.get_node(tail)
				line_color = get_parent().get_tail_connector(i).get_parent().modulate
				var start_pos = Vector2()
				start_pos.x = 18 + get_parent().get_tail_connector(i).rect_global_position.x
				start_pos.y = get_global_transform().origin.y
				var tail_pos = tail_block.rect_position
				tail_pos.y += 14
				draw_circle(start_pos, 2, line_color)
				draw_line(start_pos, tail_pos, line_color, 4, true)
				draw_circle(tail_pos, 10, Color.white)
