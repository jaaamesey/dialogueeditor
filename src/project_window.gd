extends Control

onready var dbox_style_select = $Panel/GridContainer/DBoxStyleSelect
onready var author_field = $Panel/GridContainer/AuthorField
onready var description_field = $Panel/GridContainer/DescriptionField
onready var custom_block_attributes_text_edit = $Panel/CustomBlockAttributesTextEdit

func _ready():
	dbox_style_select.connect("item_selected", self, "_on_dbox_style_select")
	author_field.connect("text_changed", self, "_on_author_changed")
	description_field.connect("text_changed", self, "_on_description_changed")
	custom_block_attributes_text_edit.connect("text_changed", self, "_on_custom_block_attributes_changed")

func _on_Project_pressed():
	reset_fields_to_current_values()
	get_node("Panel").popup_centered()


func _on_dbox_style_select(id : int):
	set_project_setting("dialogue_box_style", id)

func _on_author_changed(new_text):
	set_project_setting("author", new_text)

func _on_description_changed(new_text):
	set_project_setting("description", new_text)

func _on_custom_block_attributes_changed():
	set_project_setting("custom_block_attributes", custom_block_attributes_text_edit.text)
	if Editor.get_inspector().visible:
		Editor.update_inspector(true)


func reset_fields_to_current_values():
	dbox_style_select.selected = int(get_project_setting("dialogue_box_style"))
	author_field.text = str(get_project_setting("author"))
	description_field.text = str(get_project_setting("description"))
	custom_block_attributes_text_edit.text = str(get_project_setting("custom_block_attributes"))

func get_project_setting(pref : String):
	if Editor.current_meta_block.project_settings.has(pref):
		return Editor.current_meta_block.project_settings[pref]

func set_project_setting(pref : String, value):
	Editor.current_meta_block.project_settings[pref] = value



