extends Control

func _process(_delta : float) -> void:
	if Input.is_action_just_pressed("save"):
		Project.save_active_scene("res://test/test_scene_save.json")
