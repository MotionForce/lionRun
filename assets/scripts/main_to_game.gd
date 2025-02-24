extends Control

var game_scene = preload("res://assets/Game_Scene.tscn").instantiate()



func _on_button_pressed():
	get_tree().change_scene_to_file("res://assets/Game_Scene.tscn")
