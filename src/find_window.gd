extends WindowDialog

onready var search_line_edit : LineEdit = $VBoxContainer/HBoxContainer/FindLineEdit
onready var replace_line_edit : LineEdit = $VBoxContainer/HBoxContainer2/ReplaceLineEdit
onready var replace_checkbox : CheckBox = $VBoxContainer/HBoxContainer2/ReplaceCheckBox

var matches : Array = []

func _ready() -> void:
	$SearchButton.connect("pressed", self, "search")
	$ItemList.connect("item_selected", self, "on_block_selected")
	replace_checkbox.connect("toggled", self, "on_replace_checkbox_toggled")
	connect("visibility_changed", self, "on_visibility_changed")

	$SearchCountLabel.text = ""
	$RefineCheckbox.disabled = true
	replace_checkbox.pressed = false
	on_replace_checkbox_toggled(false)


func _input(event: InputEvent) -> void:
	if !visible:
		return
	var enter_pressed : bool = Input.is_action_just_pressed("enter")
	if enter_pressed and get_focus_owner() == search_line_edit:
		search()

func on_visibility_changed():
	if visible:
		yield(get_tree().create_timer(0), "timeout")
		search_line_edit.grab_focus()

func on_replace_checkbox_toggled(button_pressed):
	replace_line_edit.editable = button_pressed

func search() -> void:
	var includes : Array = get_included_block_types()
	var properties_to_match : Array = get_properties_to_match()
	var match_text : bool = "text" in properties_to_match
	var match_id : bool = "id" in properties_to_match
	var match_character : bool = "id" in properties_to_match

	var all_blocks : Array = []

	# If refine previous is enabled, only the previous matches are searched rather than all blocks in the project.
	var refine_previous : bool = $RefineCheckbox.pressed and !$RefineCheckbox.disabled
	if refine_previous:
		all_blocks = matches.duplicate()
	else:
		all_blocks = Editor.blocks.get_children()

	# Clear matches array
	matches = []

	# Get blocks to include
	var eligible_blocks : Array = []
	for block in all_blocks:
		if block is DialogueBlock and block.node_type in includes:
			eligible_blocks.append(block)

	# Match text against search string
	var search_str : String = search_line_edit.text
	var case_sensitive : bool = $VBoxContainer/MiscGridContainer/CaseSensitiveCheckBox.pressed
	if !case_sensitive:
		search_str = search_str.to_lower()

	# If string is empty, show all eligible blocks. Otherwise, check if they have the input.
	if search_str == "":
		matches = eligible_blocks
	else:
		for block in eligible_blocks:
			if case_sensitive:
				if match_text and search_str in block.get_dialogue_string()\
				or match_id and search_str in block.get_id()\
				or match_character and search_str in block.get_character_name():
					matches.append(block)
			else:
				if match_text and search_str in block.get_dialogue_string().to_lower()\
				or match_id and search_str in block.get_id().to_lower()\
				or match_character and search_str in block.get_character_name().to_lower():
					matches.append(block)


	matches.sort_custom(Editor.Sorter, "y_pos")

	var search_count_str : String = ""

	match matches.size():
		0:
			search_count_str = "No matches found."
		1:
			search_count_str = "Found 1 match."
		_:
			search_count_str = "Found " + str(matches.size()) + " matches."

	$SearchCountLabel.text = search_count_str


	if matches.size() > 0:
		$RefineCheckbox.disabled = false
	else:
		$RefineCheckbox.pressed = false
		$RefineCheckbox.disabled = true


	# Add items to item list
	$ItemList.clear()
	for block in matches:
		$ItemList.add_item(block.name)

func on_block_selected(index):
	var block : DialogueBlock = matches[index]
	MainCamera.lerp_time = 0
	MainCamera.lerp_camera_pos(block.rect_position)
	Editor.set_selected_block(block)

func get_included_block_types() -> Array:
	var output : Array = []
	for element in $VBoxContainer/IncludeGridContainer.get_children():
		if !(element is CheckBox):
			continue
		var check_box : CheckBox = element
		if check_box.pressed:
			match check_box.text.to_lower():
				"dialogue":
					output.append(DialogueBlock.NODE_TYPE.dialogue_block)
				"titles":
					output.append(DialogueBlock.NODE_TYPE.title_block)
				"comments":
					output.append(DialogueBlock.NODE_TYPE.comment_block)
				_:
					push_warning("UNIMPLEMENTED INCLUDED BLOCK TYPE: " + check_box.text)
	return output


func get_properties_to_match() -> Array:
	var output : Array = []
	for element in $VBoxContainer/MatchGridContainer.get_children():
		if !(element is CheckBox):
			continue
		var check_box : CheckBox = element
		if check_box.pressed:
			output.append(check_box.text.to_lower())
	return output


func _on_Find_pressed() -> void:
	popup_centered()

