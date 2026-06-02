extends Node2D

var maze_offset:Vector2 = Vector2(0, 0);
var floor_offsets = [
	Vector2(0, 0),
	Vector2(1600, 0),
	Vector2(3200, 0)
];

func _ready():
	var is_workshop = (GameLevelManager.play_mode == "workshop")
	$CanvasLayer/Panel_NormalPlay.visible = !is_workshop;
	$CanvasLayer/Panel_Playtest.visible = is_workshop;
	
	var level_path = GameLevelManager.current_level_path;
	if level_path == "":
		level_path = "res://level/original/level_test.json";
		
	if GameLevelManager.load_level(level_path):
		maze_offset = Vector2(800, 450) - Vector2(GameLevelManager.width * 32, GameLevelManager.height * 32) * 0.5;
		GameSystemManager.status_reset();
		CameraManager.setup(maze_offset, floor_offsets);
		CameraManager.switch_to_floor(0);
		_spawn_level();
	else:
		print("level load fail");
		
	if not GameSystemManager.level_won.is_connected(_on_level_won):
		GameSystemManager.level_won.connect(_on_level_won);

func _spawn_level():
	for floor_index in range(GameLevelManager.floor_count):
		for y in range(GameLevelManager.height):
			for x in range(GameLevelManager.width):
				var chara = GameLevelManager.get_block_object(floor_index, x, y);
				var pos = GameLevelManager.grid_to_world(x, y) + maze_offset + floor_offsets[floor_index];

				if chara == "W":
					var wall = GameLevelManager.obj_wall.instantiate();
					wall.global_position = pos;
					add_child(wall);
				elif chara == "1" or chara == "2" or chara == "G":
					var target = GameLevelManager.obj_goal.instantiate();
					target.global_position = pos;
					add_child(target);
				elif chara == "U":
					var elevator = GameLevelManager.obj_elevator.instantiate();
					elevator.global_position = pos;
					add_child(elevator);
				elif chara == "D":
					var pit = GameLevelManager.obj_pit.instantiate();
					pit.global_position = pos;
					pit.address = Vector3(floor_index, x, y);
					add_child(pit);
				elif chara != "V":
					var ground = GameLevelManager.obj_floor.instantiate();
					ground.global_position = pos;
					add_child(ground);

	var boxes = GameLevelManager.get_all_boxes_location();
	for box_index in boxes:
		var box = GameLevelManager.obj_box.instantiate();
		box.global_position = GameLevelManager.grid_to_world(box_index.x, box_index.y) + maze_offset + floor_offsets[box_index.floor_index];
		box.current_floor = box_index.floor_index;
		box.floor_offset = floor_offsets[box_index.floor_index];
		box.maze_offset = maze_offset;
		add_child(box);

	var spawn = GameLevelManager.get_player_starting_point();
	if not spawn.is_empty():
		var player = GameLevelManager.player.instantiate();
		player.global_position = GameLevelManager.grid_to_world(spawn.x, spawn.y) + maze_offset + floor_offsets[spawn.floor_index];
		player.current_floor = spawn.floor_index;
		player.floor_offset = floor_offsets[spawn.floor_index];
		player.maze_offset = maze_offset;
		add_child(player);
		CameraManager.switch_to_floor(spawn.floor_index);

func _on_normalplay_reset():
	GameSystemManager.reset_level();
	
func _on_normalplay_exit():
	get_tree().change_scene_to_file("res://scene/level_select.tscn");
	
func _on_workshop_return():
	GameSystemManager.is_playtest_win = false;
	get_tree().change_scene_to_file("res://scene/workshop.tscn");
	
func _on_level_won():
	if GameLevelManager.play_mode == "workshop":
		_popup_workshop_win();
	else:
		_popup_normal_win();
		
func _popup_normal_win():
	var dialog = AcceptDialog.new();
	dialog.title = "win";
	dialog.dialog_text = "return to level selector";
	dialog.confirmed.connect(
		func(): 
			get_tree().change_scene_to_file("res://scene/level_select.tscn")
	);
	add_child(dialog);
	dialog.popup_centered();
	
func _popup_workshop_win():
	var dialog = AcceptDialog.new();
	dialog.title = "validated";
	dialog.dialog_text = "level allowed, back to workshop";
	dialog.confirmed.connect(
		func():
			GameSystemManager.is_playtest_win = true;
			get_tree().change_scene_to_file("res://scene/workshop.tscn");
	);
	add_child(dialog);
	dialog.popup_centered();
