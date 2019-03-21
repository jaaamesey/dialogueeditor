extends AudioStreamPlayer

var random_pitch : bool = false
func _ready():
	if random_pitch:
		pitch_scale = rand_range(0.6,1.4)
	pass # Replace with function body.

func _on_ThrowawaySound_finished():
	self.queue_free()
	pass # Replace with function body.
