extends "res://src/blocks/dialogue_block.gd"


const spr_triangle_normal = preload("res://sprites/icons/connector_small_unfilled.png")
const spr_triangle_pressed = preload("res://sprites/icons/connector_small.png")

var tail_count := 2
var tails := ["","","","","",""]
var choices := ["","","","","",""]
var selected_tail_connector := 0

onready var line_draw_node = $LineDrawNode

func _ready():
	# Call _ready() of dialogue_block
	._ready()
	node_type = NODE_TYPE.branch_block
	set_process(true)
	# Do rest of stuff on frame after ready
	yield(get_tree().create_timer(0), "timeout")
	# Load extra_data
	if !extra_data.empty():
		tail_count = extra_data.tail_count
		tails = extra_data.tails
		choices = extra_data.choices
	# Load data into fields
	$NinePatchRect/TailCountHSlider.value = tail_count
	# Update choice field text
	for i in range(choices.size()):
		get_choice_field(i).text = choices[i]
		# Connect click signals
		var connector = get_tail_connector(i)
		connector.connect("button_down", self, "on_tail_connector_button_down", [i])

		connector.texture_normal = spr_triangle_normal
		connector.modulate.a = 0.32
		# Update button sprites
		if tails[i] != "" and tails[i] != null:
			connector.texture_normal = spr_triangle_pressed
			connector.modulate.a = 1

	# Run tailcount update code
	_on_TailCountHSlider_value_changed(tail_count)


func on_tail_connector_button_down(index : int):
	line_draw_node.set_process(true)
	tails[index] = ""
	set_process_input(true)
	MainCamera.CURRENT_CONNECTION_HEAD_NODE = self
	selected_tail_connector = index
	get_selected_tail_connector().texture_normal = spr_triangle_pressed
	get_selected_tail_connector().modulate.a = 1

func _input(event):
	if Input.is_action_just_released("click") and MainCamera.CURRENT_CONNECTION_HEAD_NODE == self :
		line_draw_node.set_process(false)
		MainCamera.CURRENT_CONNECTION_HEAD_NODE = null

		if MainCamera.CURRENT_CONNECTION_TAIL_NODE != null and MainCamera.CURRENT_CONNECTION_TAIL_NODE.name != id:
			tails[selected_tail_connector] = MainCamera.CURRENT_CONNECTION_TAIL_NODE.name
		else:
			get_selected_tail_connector().texture_normal = spr_triangle_normal
			get_selected_tail_connector().modulate.a = 0.32
		line_draw_node.update()



func get_choice_field(index : int):
	if index < 0 or index > 5:
		return null
	var path = "NinePatchRect/Choices/" + str(index) + "/LineEdit"
	return get_node(path)

func get_tail_connector(index : int):
	if index < 0 or index > 5:
		return null
	var path = "NinePatchRect/Tails/" + str(index) + "/TailConnector"
	return get_node(path)

func get_selected_tail_connector():
	return get_tail_connector(selected_tail_connector)

func serialize():
	for i in range(choices.size()):
		choices[i] = get_choice_field(i).text
		# Check for invalid tails and set them equal to ""
		if !Editor.blocks.has_node(tails[i]):
			print("Invalid tail: ", tails[i])
			tails[i] = ""


	extra_data = {
		tail_count = tail_count,
		tails = tails,
		choices = choices
	}
	var dict = .serialize()
	return dict

func update_choices():
	# Hide and reveal choice fields
	for i in range(choices.size()):
		if !Editor.blocks.has_node(tails[i]):
			tails[i] = ""
			continue
		var field = get_choice_field(i)
		var connector = get_tail_connector(i)
		if i >= tail_count:
			field.get_parent().visible = false
			connector.get_parent().visible = false
			tails[i] = ""
			connector.texture_normal = spr_triangle_normal
			connector.modulate.a = 0.32
		else:
			field.get_parent().visible = true
			connector.get_parent().visible = true


func _on_TailCountHSlider_value_changed(value: float) -> void:
	tail_count = int(value)

	# Resize NinePatchRect
	if value >= 5:
		$NinePatchRect.rect_size.y = 300
	elif value >= 3:
		$NinePatchRect.rect_size.y = 220
	else:
		$NinePatchRect.rect_size.y = 150

	update_choices()

	line_draw_node.update()
