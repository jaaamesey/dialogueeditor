extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("button_down", self, "_on_button_down")
	pass # Replace with function body.

func _on_mouse_entered():
	modulate = Color("ffffff")
	pass

func _on_mouse_exited():
	modulate = Color("a3a3a3")
	pass

func _on_button_down():
	#modulate = Color("1e7da6")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



