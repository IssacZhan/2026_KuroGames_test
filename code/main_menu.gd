extends Node2D

func _on_enter_level_select():
	get_tree().change_scene_to_file("res://scene/level_select.tscn");
	
func _on_enter_workshop():
	GameSystemManager.is_playtest_win = false;
	get_tree().change_scene_to_file("res://scene/workshop.tscn");
