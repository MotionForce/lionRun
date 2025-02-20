extends Control

var game_scene = preload("res://Game_Scene.tscn").instantiate()

func _unhandled_input(event):
    if event is InputEventKey:
        if event.pressed:
					get_tree().root.add_child(game_scene)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "intro_sequence":
		print("Animation finished")
		get_tree().change_scene_to_file("res://Game_Scene.tscn")
