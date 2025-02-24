extends Control

@onready var on_click_sound = $OnClickSound

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_restart_button_down():
	play_on_click_sound()


func _on_main_menu_button_down():
	play_on_click_sound()


func play_on_click_sound():
	on_click_sound.play()
