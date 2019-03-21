extends Control

onready var dialogue_box_sprite = $DialogueBoxSprite
onready var character_line_edit = $CharacterLineEdit
onready var dialogue_rich_text_label : RichTextLabel = $DialogueRichTextLabel


func _ready():
	# Do stuff on next frame to avoid bugs
	yield(get_tree().create_timer(0), "timeout")
	var dbox_style_index : int = Editor.current_meta_block.project_settings["dialogue_box_style"]
	match dbox_style_index:
		1:
			swap_dialogue_box_tscn("res://src/blocks/dialogue_boxes/black_serif.tscn")
		2:
			swap_dialogue_box_tscn("res://src/blocks/dialogue_boxes/jangnanmon.tscn")
		3:
			swap_dialogue_box_tscn("res://src/blocks/dialogue_boxes/cactus.tscn")



func swap_dialogue_box_tscn(path : String):
	var new_dialogue_box = load(path)
	new_dialogue_box = new_dialogue_box.instance()

	rect_scale = new_dialogue_box.rect_scale

	dialogue_box_sprite.texture           = new_dialogue_box.get_node("DialogueBoxSprite").texture
	dialogue_box_sprite.transform         = new_dialogue_box.get_node("DialogueBoxSprite").transform
	dialogue_box_sprite.scale             = new_dialogue_box.get_node("DialogueBoxSprite").scale

	var new_cle = new_dialogue_box.get_node("CharacterLineEdit")
	character_line_edit.align             = new_cle.align
	character_line_edit.rect_position     = new_cle.rect_position
	character_line_edit.rect_size         = new_cle.rect_size
	character_line_edit.rect_scale        = new_cle.rect_scale
	character_line_edit.margin_bottom     = new_cle.margin_bottom
	character_line_edit.margin_right      = new_cle.margin_right
	character_line_edit.margin_top        = new_cle.margin_top
	character_line_edit.margin_left       = new_cle.margin_left

	character_line_edit.set("custom_fonts/font",       new_cle.get("custom_fonts/font"))

	character_line_edit.set("custom_colors/default_color",    new_cle.get("custom_colors/default_color"))
	character_line_edit.set("custom_colors/font_color_shadow",new_cle.get("custom_colors/font_color_shadow"))


	var new_rtl = new_dialogue_box.get_node("DialogueRichTextLabel")
	dialogue_rich_text_label.rect_position     = new_rtl.rect_position
	dialogue_rich_text_label.rect_size         = new_rtl.rect_size
	dialogue_rich_text_label.rect_scale        = new_rtl.rect_scale
	dialogue_rich_text_label.margin_bottom     = new_rtl.margin_bottom
	dialogue_rich_text_label.margin_right      = new_rtl.margin_right
	dialogue_rich_text_label.margin_top        = new_rtl.margin_top
	dialogue_rich_text_label.margin_left       = new_rtl.margin_left

	dialogue_rich_text_label.set("custom_fonts/mono_font",         new_rtl.get("custom_fonts/mono_font"))
	dialogue_rich_text_label.set("custom_fonts/bold_italics_font", new_rtl.get("custom_fonts/bold_italics_font"))
	dialogue_rich_text_label.set("custom_fonts/italics_font",      new_rtl.get("custom_fonts/italics_font"))
	dialogue_rich_text_label.set("custom_fonts/bold_font",         new_rtl.get("custom_fonts/bold_font"))
	dialogue_rich_text_label.set("custom_fonts/normal_font",       new_rtl.get("custom_fonts/normal_font"))

	dialogue_rich_text_label.set("custom_colors/default_color", new_rtl.get("custom_colors/default_color"))
	dialogue_rich_text_label.set("custom_colors/font_color_shadow", new_rtl.get("custom_colors/font_color_shadow"))

	dialogue_rich_text_label.set("custom_constants/line_separation", new_rtl.get("custom_constants/line_separation"))

	new_dialogue_box.queue_free()

func _on_CharacterLineEdit_focus_exited() -> void:
	pass
	#if Input.is_key_pressed(KEY_TAB):
	#	get_parent().get_node("DialogueTextEdit").grab_focus()

