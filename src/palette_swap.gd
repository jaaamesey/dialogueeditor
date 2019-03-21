extends Node

onready var menu_bar_color_rect : ColorRect = owner.get_node("FrontUILayer/ColorRect")
onready var menu_bar_accent_color_rect : ColorRect = owner.get_node("FrontUILayer/AccentLine")
onready var inspector_color_rect : ColorRect = owner.get_node("InspectorLayer/Inspector/BG/ColorRect")

var panel_style_box_flat : StyleBox = preload("res://themes/panel_styleboxflat.tres")
var textedit_style_box : StyleBox = preload("res://themes/textedit_darkblue.tres")
var textedit_style_box_no_top_margin : StyleBox = preload("res://themes/textedit_darkblue_no_top_margin.tres")

# Get default settings
onready var default_panel_style_box_bg_color : Color = panel_style_box_flat.bg_color
onready var default_panel_style_box_border_color : Color = panel_style_box_flat.border_color
onready var default_menu_bar_color : Color = menu_bar_color_rect.color
onready var default_menu_bar_accent_color : Color = menu_bar_accent_color_rect.color
onready var default_inspector_color : Color = inspector_color_rect.color
onready var default_textedit_color : Color = textedit_style_box.bg_color

func set_default_theme() -> void:
	panel_style_box_flat.bg_color = default_panel_style_box_bg_color
	panel_style_box_flat.border_color = default_panel_style_box_border_color
	menu_bar_color_rect.color = default_menu_bar_color
	menu_bar_accent_color_rect.color = default_menu_bar_accent_color
	inspector_color_rect.color = default_inspector_color
	textedit_style_box.bg_color = default_textedit_color
	textedit_style_box_no_top_margin.bg_color = default_textedit_color

func set_dark_theme() -> void:
	panel_style_box_flat.bg_color = "0c0c0c"
	panel_style_box_flat.border_color = "404040"
	menu_bar_color_rect.color = "0c0c0c"
	menu_bar_accent_color_rect.color = "404040"
	inspector_color_rect.color = "a7000000"
	textedit_style_box.bg_color = "202020"
	textedit_style_box_no_top_margin.bg_color = "202020"

