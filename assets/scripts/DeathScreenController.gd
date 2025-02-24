extends Control

@onready var on_click_sound = $OnClickSound


func _on_restart_button_down():
	play_on_click_sound()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_down():
	play_on_click_sound()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://assets/Main_Menu.tscn")


func play_on_click_sound():
	on_click_sound.play()
