extends AudioStreamPlayer2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_tree().is_paused() == false:
		return
	fade_out_background_music(delta)
	if volume_db <= -40:
		stop()

func restart_background_music():
	play()

func fade_out_background_music(delta):
	volume_db -= 16 * delta
