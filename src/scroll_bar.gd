extends VScrollBar

onready var label = get_node("Label")
# Called when the node enters the scene tree for the first time.
func _ready():
	connect("scrolling", self, "set_new_camera_pos")
	update_position_label()

var last_camera_pos = Vector2()
var last_camera_zoom_level = 1
func _process(delta):
	# if camera position updates
	if Input.is_mouse_button_pressed(BUTTON_LEFT) or last_camera_pos.floor() != MainCamera.position.floor():
		update_scroll_bar()
		update_position_label()
	elif MainCamera.zoom_level != last_camera_zoom_level:
		update_position_label()

	last_camera_pos = MainCamera.position

func set_new_camera_pos():
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		MainCamera.position.y = value

func update_position_label():
	var zoom_percent = 100 * (MainCamera.zoom_level/MainCamera.zoom_level_max)
	label.text = str(MainCamera.position.floor()) +  " | " + str(round(zoom_percent)) + "%"
	label.visible = true

func update_scroll_bar():
	min_value = Editor.highest_position
	max_value = Editor.lowest_position + 900
	if MainCamera.position.y > max_value:
		max_value = MainCamera.position.y
	elif MainCamera.position.y < min_value:
		min_value = MainCamera.position.y
	if last_camera_pos.floor() != MainCamera.position.floor():
		value = MainCamera.position.y