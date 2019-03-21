extends ColorRect

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var default_color = color
var lerp_time = 0
var target = Color("a61e1e")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

func _process(delta):
#	lerp_time += delta
#	color = color.linear_interpolate(target, lerp_time)
#
#	if lerp_time >= 1:
#		lerp_time = 0
#		if target == default_color:
#			target = Color("a61e1e")
#		else: 
#			target = default_color
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
