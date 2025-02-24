extends AudioStreamPlayer2D

var sound_started = false

func start_sound():
	sound_started = true
	play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if sound_started == false:
		return
	if volume_db <= -8:
		fade_in_game_over_sound(delta)

func fade_in_game_over_sound(delta):
	volume_db += 8 * delta
