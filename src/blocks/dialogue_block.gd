extends Control
class_name DialogueBlock

enum NODE_TYPE {
	meta_block # 0 - Stored at "__META__*****" and contains only metadata in extra_data
	dialogue_block, # 1
	title_block, # 2
	comment_block, # 3
	branch_block, # 4
	wait_block, # 5 <RESERVED>
	audio_block, # 6 <RESERVED>
	animation_block, # 7 <RESERVED>
	math_block # 8 <RESERVED>
	script_block # 9 <RESERVED>
}

# NOTE: Most non-dialogue blocks will use the extra_data dictionary for everything.

export (NODE_TYPE) var node_type := NODE_TYPE.meta_block

# IMPORTS

const ThrowawaySound := preload("res://src/throwaway_sound.tscn")

# RESOURCES

const spr_unfilled_triangle := preload("res://sprites/icons/connector_small_unfilled.png")
const spr_filled_triangle := preload("res://sprites/icons/connector_small.png")

const snd_tail := preload("res://snd/tail.ogg")
const snd_delet := preload("res://snd/delet_sound.ogg")


# FIELDS
var id := "" setget set_id, get_id
var dialogue_string := "" setget set_dialogue_string, get_dialogue_string
var character_name := "" setget set_character_name, get_character_name
var tail := "" setget set_tail, get_tail
var extra_data := {} # Treated as "properties" if just a normal dialogue block

# CHILD NODES

onready var nine_patch_rect := get_node("NinePatchRect")
onready var id_label := get_node("NinePatchRect/TitleBar/Id_Label")
onready var draggable_segment := get_node("NinePatchRect/TitleBar/DraggableSegment")
onready var dialogue_rich_text_label := get_node("NinePatchRect/Dialogue").get_node("DialogueRichTextLabel")
onready var character_line_edit : LineEdit = get_node("NinePatchRect/Dialogue").get_node("CharacterLineEdit")
onready var dialogue_line_edit : TextEdit = get_node("NinePatchRect/DialogueTextEdit")
onready var anim_player := get_node("AnimationPlayer")
onready var area_2d := get_node("Area2D")

onready var nine_patch_size : Vector2 = nine_patch_rect.rect_size

var hand_placed : bool = false
var just_created : bool = false
var dragging : bool = false
var previous_pos := Vector2(0,0)
var mouse_delta := Vector2(0,0)
var mouse_pos := Vector2(0,0)
var mouse_previous_pos := Vector2(0,0)
var mouse_offset := Vector2(0,0)
var on_screen : bool = false
var title_bar_hovered : bool = false
var in_connecting_mode : bool = false
var previous_blocks : Array = [] # Blocks connected to this one
var character_placeholder_source : String = ""

var force_process_input : bool = false


onready var _head_connector_modulate_default : Color = $NinePatchRect/TitleBar/HeadConnector.modulate
onready var _tail_connector_modulate_default : Color = $NinePatchRect/TailConnector.modulate

# TODO: Use observer pattern instead of just making all nodes with connections run every frame

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	set_physics_process(false)
	if !just_created:
		set_process_input(false)

	if node_type == NODE_TYPE.meta_block: # Kill other block if another meta block exists
		if get_parent().has_node("__META__*****"):
			if name != "__META__*****":
				get_parent().get_node("__META__*****").queue_free()
				print("OVERWRITING EXISTING META BLOCK NODE")
		name = "__META__*****"
		set_process(true)

	update()

	if node_type == NODE_TYPE.dialogue_block:
		dialogue_line_edit.connect("text_changed",self,"update_dialogue_rich_text_label")

	# Play spawn animation
	if hand_placed:
		anim_player.play("spawn")
		$AudioStreamPlayer.play()
		nine_patch_rect.visible = true

	# Do rest of stuff on frame after ready
	yield(get_tree().create_timer(0), "timeout")

	if hand_placed:
		Editor.set_selected_block(self)

	if node_type != NODE_TYPE.meta_block and node_type != NODE_TYPE.branch_block:
		$VisibilityNotifier2D.connect("screen_entered", self, "on_screen_entered")
		$VisibilityNotifier2D.connect("screen_exited", self, "on_screen_exited")
		if !$VisibilityNotifier2D.is_on_screen():
			on_screen_exited()

	# Check if new highest or new lowest and apply if necessary
	if rect_position.y > Editor.lowest_position:
		Editor.lowest_position = rect_position.y
	if rect_position.y < Editor.highest_position:
		Editor.highest_position = rect_position.y


func on_screen_entered():
	visible = true
func on_screen_exited():
	if tail != "":
		return
	if !dragging:
		set_process_input(false)
	set_process(false)
	visible = false


func serialize(): # Converts dialogue block fields to a dictionary. Yes, we're using US spelling. Deal with it.
	var dict = {
		key = id,
		type = node_type,
		text = get_dialogue_string(),
		char = get_character_name(),
		tail = tail,
		posx = floor(rect_position.x), # JSON does not support Vector2
		posy = floor(rect_position.y),
		data = extra_data
	}

	return dict

func update_dialogue_rich_text_label():
	var new_text = dialogue_line_edit.text
	var new_text_formatted = new_text #.replace("\\n","\n")
	dialogue_rich_text_label.set_bbcode(new_text_formatted)
	dialogue_string = dialogue_line_edit.text
	set_process_input(true)


func fill_with_garbage():
	character_line_edit.text = str(randi())
	dialogue_rich_text_label.bbcode_text = str(randi()).sha256_text()
	dialogue_line_edit.text = str(randi()).sha256_text()

var _all_connections = {}
var _starting_pos = Vector2()
func _input(event):
	if MainCamera.scroll_mode != 0:
		mouse_offset.y += MainCamera.scroll_mode * MainCamera.scroll_spd
	# Stop dragging
	if !Input.is_action_pressed("click"):
		dragging = false
		mouse_offset = Vector2()
		_all_connections = {}

	elif tail != "" and (_all_connections == {} or Input.is_action_just_pressed("click")):
		# Get starting position of this block on first frame of clicking
		_starting_pos = rect_position

		# Update _all_connections with their starting positions on first frame of clicking
		var connections := get_connections_in_chain()
		# Get starting positions of all connections
		for connection in connections:
			_all_connections[connection] = connection.rect_position


	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if dragging:
			# Set focus to this block
			Editor.set_selected_block(self)
			mouse_delta = (mouse_pos - mouse_previous_pos)
			# Set position of this block to wherever the mouse is dragging it to
			rect_position = previous_pos + mouse_delta  * MainCamera.zoom_level  + mouse_offset

			if just_created:
				rect_position = get_global_mouse_position()

			# Move any connections this block has (if enabled)

			var move_as_chain_enabled : bool = Editor.editor_settings.has("move_blocks_as_chain") and Editor.editor_settings["move_blocks_as_chain"] == true
			# Move as chain is shift + disabled or !shift + enabled
			if (!move_as_chain_enabled and Editor.is_modifier_down("shift")) or (move_as_chain_enabled and !Editor.is_modifier_down("shift")):
				for block in _all_connections:
					var block_previous_pos : Vector2 = _all_connections[block]
					block.rect_position = block_previous_pos + (rect_position - _starting_pos)  #* MainCamera.zoom_level + mouse_offset

			# Teleport block to cursor if too far away or if panning
			if abs(get_global_mouse_position().y - rect_position.y) > 200 or \
			abs(get_global_mouse_position().x - rect_position.x) > 2000 or MainCamera.pan_mode:
				just_created = true # Act like just created
			# Check if new highest or new lowest and apply if necessary
			if rect_position.y > Editor.lowest_position:
				Editor.lowest_position = rect_position.y
			if rect_position.y < Editor.highest_position:
				Editor.highest_position = rect_position.y
			update()

	if (draggable_segment.pressed or just_created) and !dragging and !MainCamera.pan_mode:
		mouse_offset = Vector2()
		previous_pos = rect_position
		mouse_previous_pos = mouse_pos
		dragging = true
		Editor.hovered_block = self
		Editor.selected_block = self

	if Input.is_action_just_released("click"):
		just_created = false
		dialogue_string = dialogue_line_edit.text
		character_name = character_line_edit.text
		MainCamera.LAST_MODIFIED_BLOCK = self

	if Input.is_action_just_pressed("x") and (draggable_segment.pressed or just_created):
		_on_DeleteButton_pressed()

func move_to_front():
	# Move to front of Blocks
	var index = get_parent().get_child_count()
	get_parent().move_child(self, index)

func randomise_id():
	var new_id = str(float(OS.get_ticks_usec()) + randf()).sha256_text().substr(0,10)
	if node_type == NODE_TYPE.title_block:
		set_id("Title_" + new_id)
	elif node_type == NODE_TYPE.comment_block:
		new_id = str(float(OS.get_ticks_usec()) + randf()).sha256_text().substr(0,8)
		set_id("c_" + new_id)
	else:
		set_id(new_id)
	return id

func _on_DraggableSegment_pressed():
	set_process_input(true)
	mouse_delta = Vector2(0,0)
	previous_pos = rect_position
	mouse_previous_pos = mouse_pos
	dragging = true
	move_to_front()
	nine_patch_rect.grab_focus()
	MainCamera.LAST_MODIFIED_BLOCK = self
	if Input.is_action_pressed("x"):
		_on_DeleteButton_pressed()
	Editor.hovered_block = self
	Editor.set_selected_block(self)

func _on_DeleteButton_button_down():
	move_to_front()

func _on_DeleteButton_pressed():
	# Store previous animation to check if already in kill animation later
	var previous_anim = anim_player.current_animation

	if Editor.selected_block == self:
		Editor.selected_block = null
	anim_player.play("kill")
	var death_sound = ThrowawaySound.instance()
	death_sound.pitch_scale = rand_range(0.7,1.3)
	death_sound.stream = snd_delet
	death_sound.volume_db = -6.118
	MainCamera.add_child(death_sound)

	# Save into undo buffer
	# Note: this is done at the START of the delete animation rather than the end
	# to allow for the user to panic press Ctrl+Z.
	# To avoid filling up the delete queue upon spamming of the delete button,
	# the code checks if the block is already condemned (i.e. in the death animation)
	if previous_anim != "kill":
		# Even though this is a single block, it will be treated the same by the undo system as if it were multiple.
		# This means it must be wrapped inside another dict.
		var dict = {}
		# Include serialised block data, as well as other things like what blocks were connected.
		dict[self.id] = {
			"block_dict" : self.serialize(),
			"previous_blocks" : previous_blocks.duplicate()

		}
		# TODO: Make branch blocks behave like normal blocks with regards to undoing stuff

		Editor.undo_buffer.append(["deleted", dict])
		clear_connected_tail_blocks()

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"kill":
			before_destroy()
			self.queue_free() # actually kill

# Stuff meant to be called BEFORE queue_free().
func before_destroy() -> void:
	# Tell Camera2D to reset array of last rendered stuff
	# (workaround for null pointer)
	MainCamera.last_blocks_on_screen = []
	if Editor.selected_block == self:
		Editor.selected_block = null
	# Remove references to self from old tail by setting current tail blank
	set_tail("")
	# Clear placeholder text of blocks below this
	set_character_name("")
	# Do this just to be safe
	clear_connected_tail_blocks()

# Clear tails of blocks connected to this
func clear_connected_tail_blocks():
	for tail in previous_blocks:
		var tail_block : DialogueBlock = Editor.blocks.get_node(tail)
		tail_block.set_tail("")
		tail_block.visible = false
		tail_block.visible = true


func _on_DraggableSegment_mouse_entered():
	set_process_input(true)
	Editor.hovered_block = self
	update()

func _on_DraggableSegment_mouse_exited():
	if !just_created and !dialogue_line_edit.has_focus():
		set_process_input(false)
	update()

func _on_DialogueTextEdit_focus_entered():
	set_process_input(true)
	MainCamera.LAST_MODIFIED_BLOCK = self
	Editor.hovered_block = self
	if Input.is_action_just_pressed("click") or Input.is_action_just_released("click"):
		Editor.set_selected_block(self)

func _on_DialogueTextEdit_focus_exited():
	set_process_input(false)

func _on_HeadArea2D_area_entered(area : Area2D):
	if area.name == "CursorArea" and MainCamera.CURRENT_CONNECTION_HEAD_NODE != self:
		title_bar_hovered = true
		MainCamera.CURRENT_CONNECTION_TAIL_NODE = self

		update()

func _on_HeadArea2D_area_exited(area : Area2D):
	if area.name == "CursorArea":
		title_bar_hovered = false
		MainCamera.CURRENT_CONNECTION_TAIL_NODE = null
		update()

func _on_Id_Label_text_changed(new_text):
	MainCamera.LAST_MODIFIED_BLOCK = self

func _on_CharacterLineEdit_text_changed(new_text):
	set_character_name(new_text)
	MainCamera.LAST_CHAR_NAME = character_line_edit.text
	MainCamera.LAST_MODIFIED_BLOCK = self

# SETTERS AND GETTERS
func set_id(new_id):
	new_id = new_id.strip_edges()
	var new_id_original = new_id
	if node_type == NODE_TYPE.meta_block:
		id = "__META__*****"
		name = "__META__*****"
		id_label.text = "__META__*****"
		return

	var old_id = id
	if !is_id_valid(new_id):
		if is_id_valid(old_id):
			new_id = old_id
		else:
			new_id = randomise_id()
		var error_msg : String = new_id_original + " already exists - ID changed to " + new_id
		Editor.push_message(error_msg)

	id = new_id
	id_label.text = id # Update textfield
	name = id # Update name in tree

	# Replace reference in tail block
	if tail != "" and Editor.blocks.has_node(tail):
		var tail_block : DialogueBlock = Editor.blocks.get_node(tail)
		tail_block.previous_blocks.erase(old_id)
		set_tail("")
		set_tail(tail_block.id)

	# Reconnect previous blocks to self after rename
	for block_id in previous_blocks:
		var block : DialogueBlock = Editor.blocks.get_node(block_id)
		block.set_tail("")
		block.set_tail(self.id)

	# Update character placeholder text
	update_placeholder_text_in_chain()

	MainCamera.LAST_MODIFIED_BLOCK = self
	Editor.set_selected_block(self)



func is_id_valid(test_id):
	if test_id == "__META__*****" and node_type != null and node_type != NODE_TYPE.meta_block:
		return false
	if test_id == "":
		return false
	if name != test_id and Editor.blocks.has_node(test_id):
		return false
	if test_id.length() > 100:
		return false
	return true

func get_id():
	if node_type == NODE_TYPE.meta_block:
		return "__META__*****" # Will have meta id NO MATTER WHAT
	return id

func set_dialogue_string(new_dialogue_string):
	dialogue_string = new_dialogue_string
	dialogue_line_edit.text = dialogue_string # Update textfield

func get_dialogue_string():
	return dialogue_line_edit.text

func set_character_name(new_character_name):
	character_name = new_character_name
	update_placeholder_text_in_chain()

# TODO: Make this function make more sense.

# Recursion prevention
var update_placeholder_text_in_chain_recursions = -1
func update_placeholder_text_in_chain(check_previous : bool = true):

	# Do nothing if editor is in the process of loading stuff
	if Editor.is_still_loading:
		return

	if update_placeholder_text_in_chain_recursions >= 4:
		print(update_placeholder_text_in_chain_recursions)
		return

	update_placeholder_text_in_chain_recursions += 1

	character_line_edit.placeholder_text = ""

	var character_unknown := false
	for block in get_connections_in_chain():
		if block.character_name != "":
			break
		block.character_line_edit.placeholder_alpha = 0.4
		if !character_unknown and block.are_previous_block_characters_the_same():
			block.character_line_edit.placeholder_text = character_name
			block.character_placeholder_source = self.id
		else:
			character_unknown = true
			block.character_line_edit.placeholder_text = ""

	if character_name == "":
		character_line_edit.placeholder_text = ""
		var source_block : DialogueBlock = null
		if character_placeholder_source != "" and Editor.blocks.has_node(character_placeholder_source):
			source_block = Editor.blocks.get_node(character_placeholder_source)
			if source_block != self:
				source_block.update_placeholder_text_in_chain(false)
			else:
				character_placeholder_source = ""
		# If placeholder text still not changed, try previous block's placeholder source
		if check_previous and character_line_edit.placeholder_text == "":
			if previous_blocks.size() >= 1 and are_previous_block_characters_the_same():
				var previous_block : DialogueBlock = Editor.blocks.get_node(previous_blocks[0])
				character_placeholder_source = previous_block.character_placeholder_source
				update_placeholder_text_in_chain(false)
	update_placeholder_text_in_chain_recursions = -1


func are_previous_block_characters_the_same() -> bool:
	if previous_blocks.size() <= 1:
		return true

	var block_0 : DialogueBlock = Editor.blocks.get_node(previous_blocks[0])
	var test_character : String = block_0.character_name
	if test_character == "":
		test_character = block_0.character_line_edit.placeholder_text
	for block_id in previous_blocks:
		var block : DialogueBlock = Editor.blocks.get_node(block_id)
		var actual_character : String = block.character_name
		if actual_character == "":
			actual_character = block.character_line_edit.placeholder_text
		if actual_character != test_character:
			return false
	return true


func get_character_name():
	return character_line_edit.text

func set_tail(new_tail):
	if !Editor.is_still_loading and !Editor.blocks.has_node(new_tail):
		new_tail = ""
	var old_tail : String = tail
	tail = new_tail
	update_connections(old_tail, new_tail)
	update_placeholder_text_in_chain()
	update()
	Editor.update_inspector(true)

func update_connections(old_tail : String, new_tail : String):
	# Do nothing if editor is in the process of loading stuff
	if Editor.is_still_loading:
		return
	# Remove self from old tail's list of connected nodes
	if old_tail != "" and Editor.blocks.has_node(old_tail):
		var old_tail_block : DialogueBlock = Editor.blocks.get_node(old_tail)
		old_tail_block.previous_blocks.erase(self.id)
		old_tail_block.update_placeholder_text_in_chain()

	# Add self to new tail's list of connected nodes
	if new_tail != "" and Editor.blocks.has_node(new_tail):
		var new_tail_block : DialogueBlock = Editor.blocks.get_node(new_tail)
		if !new_tail_block.previous_blocks.has(self.id):
			new_tail_block.previous_blocks.append(self.id)
		new_tail_block.update_placeholder_text_in_chain()
	update_placeholder_text_in_chain()

func get_tail():
	return tail

func _on_Id_Label_text_entered(new_text):
	set_id(new_text)
	id_label.release_focus()
	MainCamera.LAST_MODIFIED_BLOCK = self
	Editor.set_selected_block(self)
	anim_player.play("spawn")

func _on_Id_Label_focus_exited():
	if id == id_label.text:
		return
	set_id(id_label.text)
	anim_player.play("spawn")

func _on_TailConnector_button_down():
	Editor.set_selected_block(self)
	in_connecting_mode = true
	set_tail("")
	MainCamera.CURRENT_CONNECTION_HEAD_NODE = self
	update()
	set_process(true)
	$NinePatchRect/TailConnector.pressed = false
	$NinePatchRect.grab_focus()
	MainCamera.LAST_MODIFIED_BLOCK = self

	# Spawn new block on double click
	var new_block : DialogueBlock = null
	if Editor.double_click_timer > 0.001:
		# Register double click
		new_block  = spawn_block_below()


	Editor.double_click_timer = Editor.double_click_timer_time
	# If a new block has been spawned, select it.
	if Editor.is_node_alive(new_block):
		yield(get_tree().create_timer(0), "timeout")
		Editor.set_selected_block(new_block)

func _on_TailConnector_button_up():
	Editor.set_selected_block(self)


# Selecting block
func _on_NinePatchRect_focus_entered():
	Editor.hovered_block = self
	if Input.is_action_just_pressed("click") or Input.is_action_just_released("click"):
		Editor.set_selected_block(self)

func release_connection_mode():
	set_tail("")

	if MainCamera.CURRENT_CONNECTION_HEAD_NODE != self:
		return

	if Editor.is_node_alive(MainCamera.CURRENT_CONNECTION_TAIL_NODE) and MainCamera.CURRENT_CONNECTION_TAIL_NODE != self:
		set_tail(MainCamera.CURRENT_CONNECTION_TAIL_NODE.id)

	in_connecting_mode = false
	MainCamera.CURRENT_CONNECTION_HEAD_NODE = null
	update()
	Editor.update_inspector(true)
	if tail == "":
		set_process(false)

func spawn_block_below():
	release_connection_mode()
	var tail_block = Editor.spawn_block(NODE_TYPE.dialogue_block, false, rect_position + Vector2(0,600))
	tail_block.randomise_id()
	set_tail(tail_block.id)
	MainCamera.lerp_camera_pos(Vector2(MainCamera.position.x, tail_block.rect_position.y) + Vector2(0, 200), 0.5)
	tail_block.dialogue_line_edit.grab_focus()
	MainCamera.CURRENT_CONNECTION_TAIL_NODE = tail_block
	in_connecting_mode = false
	set_process(true)
	update()

	return tail_block

# Returns an array of DialogueBlocks that are subsequent connections of this block.
func get_connections_in_chain(include_self := false) -> Array:
	var all_tails := []
	if include_self:
		all_tails.append(self)
	var current_block : DialogueBlock = self
	var safety_iterator : int = 0
	while current_block.tail != "":
		var child_count : int = Editor.blocks.get_child_count()
		if !Editor.blocks.has_node(current_block.tail):
			break
		var next_block : DialogueBlock = Editor.blocks.get_node(current_block.tail)
		# Break if invalid next block or if next block is literally itself
		if !Editor.is_node_alive(next_block) or next_block == null or current_block.tail == self.id:
			break
		all_tails.append(next_block)
		current_block = next_block
		safety_iterator += 1
		if safety_iterator > child_count or current_block == self:
			print("SAFETY ITERATOR BREAK: " + str(safety_iterator))
			break
	return all_tails


func get_end_of_chain() -> DialogueBlock:
	var current_block : DialogueBlock = self
	var child_count : int = Editor.blocks.get_child_count()
	var safety_iterator : int = 0
	while current_block.tail != "":
		if !Editor.blocks.has_node(current_block.tail):
			break
		var next_block : DialogueBlock = Editor.blocks.get_node(current_block.tail)
		if !Editor.is_node_alive(next_block) or next_block == null or current_block.tail == self.id:
			break
		current_block = next_block
		safety_iterator += 1
		if safety_iterator > child_count or (safety_iterator >= 2 and current_block == self):
			print("SAFETY ITERATOR BREAK: " + str(safety_iterator))
			break
	if !Editor.is_node_alive(current_block):
		return null
	return current_block

func to_script_string(separator := "\n", character_name_to_upper := true) -> String:
	var script_string := ""
	if character_name_to_upper:
		script_string += character_name.to_upper()
	else:
		script_string += character_name
	script_string += separator
	script_string += dialogue_string

	return script_string.strip_edges()

# DRAWING CODE

func _draw():
	if tail != "" or MainCamera.CURRENT_CONNECTION_HEAD_NODE == self:
		$NinePatchRect/TailConnector.modulate = Color(1,1,1)
		$NinePatchRect/TailConnector.texture_normal = spr_filled_triangle
	else:
		$NinePatchRect/TailConnector.modulate = _tail_connector_modulate_default
		$NinePatchRect/TailConnector.texture_normal = spr_unfilled_triangle

	if MainCamera.CURRENT_CONNECTION_HEAD_NODE != null and title_bar_hovered:
		#$NinePatchRect.modulate = Color(1.3,1.3,1.3)
		$NinePatchRect/TitleBar/HeadConnector.modulate = Color(1,1,1)
	else:
		#$NinePatchRect.modulate = Color(1,1,1)
		$NinePatchRect/TitleBar/HeadConnector.modulate = _head_connector_modulate_default

	$LineDrawNode.update()


# TODO: Make this bit more performant
func _process(delta):
	if node_type == NODE_TYPE.meta_block:
		if name != "__META__*****": # Do not rest until id is changed
			id = "__META__*****"
			name = "__META__*****"
		else:
			set_process_input(false)
			set_physics_process(false)
			if tail != "":
				set_process(false)
		return

	if in_connecting_mode and Input.is_action_just_released("click"):
		release_connection_mode()

	update()


func _on_Button_button_down() -> void:
	Editor.hovered_block = self
	Editor.set_selected_block(self)


func _on_DialogueRichTextLabel_meta_clicked(meta) -> void:
	Editor.hovered_block = self
	Editor.set_selected_block(self)


func _on_DialogueRichTextLabel_gui_input(event: InputEvent) -> void:
	Editor.hovered_block = self
	Editor.set_selected_block(self)


func _on_DialogueTextEdit_cursor_changed() -> void:
	Editor.hovered_block = self
	Editor.set_selected_block(self)
