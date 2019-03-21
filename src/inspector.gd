extends Panel

var in_action_mode = false

func _ready() -> void:
	$Name/Label.connect("text_entered", self, "set_block_id")
	$ActionsModeButton.connect("toggled", self, "toggle_mode")

	# Connect signals for defaults
	for child in $DialogueBoxContainer/Control/PropertiesVBox.get_children():
		# Update line edits
		if child.has_node("LineEdit"):
			var line_edit : LineEdit = child.get_node("LineEdit")
			line_edit.text = ""
			# Connect signals
			if line_edit.is_connected("text_changed", self, "on_string_property_changed"):
				line_edit.disconnect("text_changed", self, "on_string_property_changed")
			line_edit.connect("text_changed", self, "on_string_property_changed", [line_edit])

		# Update toggles
		if child.has_node("ToggleContainer/Toggle"):
			var toggle : Button = child.get_node("ToggleContainer/Toggle")
			toggle.pressed = false
			# Connect signals
			if !toggle.is_connected("toggled", self, "on_bool_property_changed"):
				toggle.connect("toggled", self, "on_bool_property_changed", [toggle])
	update_inspector()

func _on_Inspector_visibility_changed():
	if visible:
		update_inspector(true)


func update_inspector(force := false):
	if !visible:
		return

	$Name/Label.max_length = 10
	# Check if block actually valid
	if Editor.selected_block == null or !is_instance_valid(Editor.selected_block) or !(Editor.selected_block is Editor.DBScript):
		$Name/Label.max_length = 20
		$Name/Label.text = "No block selected."
		set_all_containers_visibility(false)
		$EmptyContainer.visible = true
		$ActionsModeButton.visible = false
		return
	# Do nothing if reselecting the same thing
	if !force and $Name/Label.text == str(Editor.selected_block.id):
		return
	$Name/Label.text = str(Editor.selected_block.id)

	set_all_containers_visibility(false)

	match Editor.selected_block.node_type:
		Editor.DB.NODE_TYPE.dialogue_block:
			$DialogueBoxContainer.visible = true
			$ActionsModeButton.visible = true
		_:
			$EmptyContainer.visible = true
			$ActionsModeButton.visible = false

	if $DialogueBoxContainer.visible:
		update_dialogue_box_container()

	#last_inspector_update = OS.get_ticks_msec()


func update_dialogue_box_container():
	# Decide whether properties or actions are shown
	if in_action_mode:
		$DialogueBoxContainer/Control/PropertiesVBox.visible = false
		$DialogueBoxContainer/Control/ActionsVBox.visible = true
	else:
		$DialogueBoxContainer/Control/PropertiesVBox.visible = true
		$DialogueBoxContainer/Control/ActionsVBox.visible = false
		update_dialogue_properties_vbox()


func update_dialogue_properties_vbox():
	# Update info text (TODO: Make terminology less confusing)
	var info_text := ""
	var connections_in_chain : Array = Editor.selected_block.get_connections_in_chain()
	var connections_to_this : Array = Editor.selected_block.previous_blocks
	info_text += "Number of connections in chain: " + str(connections_in_chain.size()) + "\n"
	info_text += "Next connection: " + Editor.selected_block.tail + "\n"
	info_text += "End of chain: " + Editor.selected_block.get_end_of_chain().id + "\n"
	info_text += "Direct connections to this: " + str(connections_to_this)


	$DialogueBoxContainer/Control/PropertiesVBox/InfoText.bbcode_text = info_text


	var properties_vbox_children : Array = $DialogueBoxContainer/Control/PropertiesVBox.get_children()
	# Update fields in properties vbox
	var attribute_separator : VSeparator = $DialogueBoxContainer/Control/PropertiesVBox/CustomAttributeSeparator
	var separator_index := attribute_separator.get_index()

	var custom_attribute_template : HBoxContainer = $DialogueBoxContainer/Control/PropertiesVBox/CustomAttributeTemplate
	custom_attribute_template.visible = false

	# Handle custom attributes

	# Clear all nodes after the separator
	var current_index : int = separator_index + 1
	while current_index < properties_vbox_children.size():
		var child = properties_vbox_children[current_index]
		if child != custom_attribute_template: # Keep the template alive so it can be copied
			# Kill child
			child.visible = false

		current_index += 1


	# Convert project custom attributes string to array
	# (TODO: Use a dictionary instead when adding default values and custom type data)
	var project_settings_dict : Dictionary = Editor.current_meta_block.project_settings
	var custom_attributes_string : String = project_settings_dict["custom_block_attributes"]
	# Separate by commas and newlines
	custom_attributes_string = custom_attributes_string.replace("\n", ",")
	var custom_attributes_array = custom_attributes_string.split(",")

	# Create custom attribute fields based on attribute names
	for attribute_name in custom_attributes_array:
		attribute_name = attribute_name.strip_edges()
		if attribute_name == "":
			continue
		var attribute_hbox : HBoxContainer = custom_attribute_template.duplicate()
		attribute_hbox.name = attribute_name
		attribute_hbox.get_node("Label").text = attribute_name
		attribute_hbox.visible = true
		$DialogueBoxContainer/Control/PropertiesVBox.add_child(attribute_hbox)

		var line_edit : LineEdit = attribute_hbox.get_node("LineEdit")
		line_edit.text = ""
		if Editor.selected_block.extra_data.has(attribute_name):
			line_edit.text = Editor.selected_block.extra_data[attribute_name]
		# Connect signals
		if line_edit.is_connected("text_changed", self, "on_string_property_changed"):
			line_edit.disconnect("text_changed", self, "on_string_property_changed")

		line_edit.connect("text_changed", self, "on_string_property_changed", [line_edit])


	for child in properties_vbox_children:
		if !child.has_node("Label") or child == custom_attribute_template or !child.visible:
			continue

		var label : Label = child.get_node("Label")
		var property_name : String = label.text

		# Update line edits
		if child.has_node("LineEdit"):
			var line_edit : LineEdit = child.get_node("LineEdit")
			line_edit.text = ""
			if Editor.selected_block.extra_data.has(property_name):
				line_edit.text = Editor.selected_block.extra_data[property_name]

		# Update toggles
		if child.has_node("ToggleContainer/Toggle"):
			var toggle : Button = child.get_node("ToggleContainer/Toggle")
			toggle.pressed = false
			if Editor.selected_block.extra_data.has(property_name):
				toggle.pressed = Editor.selected_block.extra_data[property_name]


func on_string_property_changed(new_text, line_edit):
	var property_name : String = line_edit.get_parent().get_node("Label").text
	if new_text == "":
		# Remove property if blank to avoid cluttering file
		Editor.selected_block.extra_data.erase(property_name)
		return
	Editor.selected_block.extra_data[property_name] = new_text

func toggle_mode(button_pressed):
	in_action_mode = button_pressed
	update_inspector(true)

func on_bool_property_changed(button_pressed, button):
	var property_name : String = button.get_parent().get_parent().get_node("Label").text
	if button_pressed == false:
		# Remove property if false to avoid cluttering file
		Editor.selected_block.extra_data.erase(property_name)
		return
	Editor.selected_block.extra_data[property_name] = button_pressed


func set_block_id(new_text):
	if !Editor.is_node_alive(Editor.selected_block):
		return
	Editor.selected_block.set_id(new_text)
	Editor.selected_block.id_label.text = Editor.selected_block.id
	update_inspector()

func set_all_containers_visibility(visibility):
	for container in get_children():
		if container is ScrollContainer:
			container.visible = visibility

func _on_ViewConnections_pressed() -> void:
	var output : String = ""

	if !Editor.is_node_alive(Editor.selected_block):
		Editor.push_message("Error: Selected block does not exist")
		return

	var all_tails = Editor.selected_block.get_connections()

	var tails_str := ""
	for tail in all_tails:
		tails_str += tail.id + "\n"
	tails_str = tails_str.substr(0, tails_str.length() - 2)
	#Editor.push_message(tails_str)
	Editor.popup_message(tails_str, "View Connections", true)


func _on_ViewChainAsScript_pressed() -> void:
	var script_str := ""
	for block in Editor.selected_block.get_connections(true):
		script_str += block.to_script_string()
		script_str += "\n\n"
	script_str = script_str.strip_edges()
	Editor.popup_message(script_str, "View Chain as Script", true)



func _on_GoToEndOfChain_pressed() -> void:
	if !Editor.is_node_alive(Editor.selected_block):
		Editor.push_message("Error: Selected block does not exist")
		return

	var end_block : DialogueBlock = Editor.selected_block.get_end_of_chain()
	if end_block == null:
		Editor.push_message("Error: End of chain does not exist")
		return

	MainCamera.lerp_camera_pos(end_block.rect_position)
	Editor.set_selected_block(end_block)

