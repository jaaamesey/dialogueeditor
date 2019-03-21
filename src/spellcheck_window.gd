extends WindowDialog

onready var item_list : ItemList = $ItemList
onready var error_count_label : Label = $ErrorCountLabel

var error_arr : Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !CSharp.is_working:
		queue_free()
		return
	connect("visibility_changed", self, "on_visibility_changed")
	$CheckButton.connect("pressed", self, "on_check_pressed")
	$ItemList.connect("item_selected", self, "on_item_selected")
	error_count_label.text = ""

func on_visibility_changed():
	if visible:
		on_check_pressed()

func on_check_pressed():
	var blocks : Array = Editor.blocks.get_children()
	error_arr = CSharp.SpellCheck.CheckBlocks(blocks)

	# Sort error_arr by block y pos
	error_arr.sort_custom(Sorter, "spellcheck_y_pos")

	item_list.clear()
	for error in error_arr:
		var error_string : String
		error_string = '"' + error.Word +'" at '
		error_string += error.Block.id + " : " + str(error.Index)
		item_list.add_item(error_string)


	# Update error count label
	var error_count : int = len(error_arr)
	match error_count:
		0:
			error_count_label.text = "No errors found."
		1:
			error_count_label.text = "1 error found."
		_:
			error_count_label.text = str(error_count) + " errors found."




func on_item_selected(index : int):
	var block : DialogueBlock = error_arr[index].Block
	MainCamera.lerp_time = 0
	MainCamera.lerp_camera_pos(block.rect_position)
	Editor.set_selected_block(block)

class Sorter:
	static func spellcheck_y_pos(a, b):
		if a.Block.rect_position.y < b.Block.rect_position.y:
			return true
		return false