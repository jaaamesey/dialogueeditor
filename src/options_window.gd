extends Popup

onready var item_list = $ItemList

onready var scroll_speed_slider = get_node("General/ScrollSpeedSlider")
onready var zoom_speed_slider = get_node("General/ZoomSpeedSlider")
# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	scroll_speed_slider.connect("value_changed",self,"_on_scroll_speed_changed")
	zoom_speed_slider.connect("value_changed",self,"_on_zoom_speed_changed")

	$General/EditorBackgroundSelect.connect("item_selected", self, "_on_BGSelect_selected")

	$General/LowProcessorMode.connect("toggled", self, "_on_LowProcessorMode_toggled")
	$General/DisableAnimations.connect("toggled", self, "_on_DisableAnimations_toggled")
	$General/EnableVSync.connect("toggled", self, "_on_VSync_toggled")
	$General/MuteSound.connect("toggled", self, "_on_MuteSound_toggled")
	$General/MoveBlocksAsChain.connect("toggled", self, "_on_MoveBlocksAsChain_toggled")

	connect("visibility_changed", self, "on_visibility_changed")

	item_list.select(0)
	_on_ItemList_item_selected(0)

	# Wait for dialogue editor before loading settings just in case
	yield(get_tree().create_timer(0.0),"timeout")
	load_editor_settings()



func _on_Options_pressed():
	popup_centered()

func _on_Options_toggled(button_pressed):
	visible = button_pressed

func save_options_to_file():
	# Ensure things are updated
	update_spellcheck_settings()
	var dict_string : String = JSON.print(Editor.editor_settings, "  ")
	var path : String = "user://editor_settings.json"
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(dict_string)
	file.close()

func load_editor_settings():
	if Editor.editor_settings.has("spellcheck_ignored_words"):
		$Spellcheck/IgnoredWords.text = Editor.editor_settings["spellcheck_ignored_words"]
	update_spellcheck_settings()

func on_visibility_changed():
	if !visible:
		update_spellcheck_settings()
		save_options_to_file()


# Move between different settings tabs
func _on_ItemList_item_selected(index: int) -> void:
	var item_name : String = item_list.get_item_text(index)

	for item in get_children():
		if item is GridContainer:
			item.visible = false

	get_node(item_name).visible = true

func update_spellcheck_settings():
	update_ignored_words()
	if CSharp.is_working:
		CSharp.SpellCheck.SetRealtimeEnabled($Spellcheck/RealtimeSpellcheckEnabled.pressed)

func update_ignored_words():
	var ignored_words_dict : Dictionary = {}
	var current_word : String = ""
	var text : String = $Spellcheck/IgnoredWords.text
	for i in range(len(text)):
		var character : String = text[i]
		var is_separator : bool = character in [' ', '\n', ',', ';']
		if is_separator or i >= len(text) - 1:
			if !is_separator:
				current_word += character
			if current_word != "":
				ignored_words_dict[(current_word.strip_edges().to_lower())] = ""
			current_word = ""
			continue
		current_word += character

	Editor.editor_settings["spellcheck_ignored_words"] = $Spellcheck/IgnoredWords.text

	if CSharp.is_working:
		CSharp.SpellCheck.SetIgnoredWords(ignored_words_dict)


func _on_scroll_speed_changed(value):
	MainCamera.scroll_spd = value
	Editor.editor_settings["scroll_speed"] = value

func _on_zoom_speed_changed(value):
	MainCamera.zoom_spd = value
	Editor.editor_settings["zoom_speed"] = value

func _on_BGSelect_selected(ID):
	var selected_bg = $General/EditorBackgroundSelect.get_item_text(ID)
	var bg_path = "res://sprites/backgrounds/" + selected_bg + ".jpg"
	Editor.get_node("BGLayer/Background").texture = load(bg_path)
	Editor.editor_settings["bg_select"] = ID

func _on_LowProcessorMode_toggled(button_pressed: bool) -> void:
	OS.low_processor_usage_mode = button_pressed
	Editor.editor_settings["low_processor_mode"] = button_pressed

func _on_DisableAnimations_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Editor.get_node("InspectorLayer/Inspector/AnimationPlayer").stop()
	else:
		Editor.get_node("InspectorLayer/Inspector/AnimationPlayer").play("MovingDots")
	Editor.editor_settings["disable_animations"] = button_pressed

func _on_VSync_toggled(button_pressed: bool) -> void:
	OS.set_use_vsync(button_pressed)
	Editor.editor_settings["use_vsync"] = button_pressed

func _on_MuteSound_toggled(button_pressed: bool) -> void:
	AudioServer.set_bus_mute(0, button_pressed)
	Editor.editor_settings["mute_sound"] = button_pressed

func _on_MoveBlocksAsChain_toggled(button_pressed: bool) -> void:
	Editor.editor_settings["move_blocks_as_chain"] = button_pressed


