extends Node

var is_mono_build : bool = false
var use_os_file_io : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_mono_build = CSharp.is_working
	if is_mono_build and OS.get_name() == "Windows":
		use_os_file_io = true

