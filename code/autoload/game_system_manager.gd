extends Node

enum GameState { menu, playing, workshop };
var current_state: GameState = GameState.menu;

var total_goals: int = 0;
var goals_occupied: int = 0;

signal level_won;
var is_playtest_win: bool = false;

func check_win():
	if total_goals > 0 and goals_occupied >= total_goals:
		print("win");
		is_playtest_win = true;
		emit_signal("level_won");

func _ready():
	pass;

func status_reset():
	total_goals = 0;
	goals_occupied = 0;

	for entry in GameLevelManager.special_blocks:
		var prop = GameLevelManager.special_blocks[entry];
		if prop == "goal":
			total_goals += 1;

func on_box_entered_goal():
	goals_occupied += 1;
	check_win();

func on_box_left_goal():
	goals_occupied -= 1;
		
func kill_player():
	var dialog = AcceptDialog.new()
	dialog.title = "You Died";
	
	if GameLevelManager.play_mode == "workshop":
		dialog.dialog_text = "returning to workshop";
		dialog.confirmed.connect(
			func(): get_tree().change_scene_to_file("res://scene/workshop.tscn");
		)
	else:
		dialog.dialog_text = "returning to level select";
		dialog.confirmed.connect(
			func(): get_tree().change_scene_to_file("res://scene/level_select.tscn");
		)
	add_child(dialog);
	dialog.popup_centered();
	
func remove_box(box: StaticBody2D):
	var pos = GameLevelManager.get_object_grid_pos(box);
	if box.under == "goal":
		on_box_left_goal();
	box.queue_free();
	if pos.x == 0:
		for pit in get_tree().get_nodes_in_group("pit"):
			if pit.address == Vector3(0, pos.y, pos.z):
				pit.mark_filled_by_fallen_box();
	refresh_all_pit();

func get_player_at(player_floor: int, x: int, y: int) -> CharacterBody2D:
	for player in get_tree().get_nodes_in_group("player"):
		var pos = GameLevelManager.get_object_grid_pos(player);
		if pos.x == player_floor and pos.y == x and pos.z == y:
			return player;
	return null;
	
func handle_pit(subject: Node, current_floor: int, x: int, y: int) -> bool:
	for pit in get_tree().get_nodes_in_group("pit"):
		if pit.address == Vector3(current_floor, x, y) and pit.is_pit_filled:
			return false;
			
	while true:
		var drop_floor = current_floor - 1;
		print("[handle_pit] 当前层=%d, 尝试下落到层=%d, 坐标=(%d,%d)" % [current_floor, drop_floor, x, y]);
		if drop_floor < 0:
			if subject is CharacterBody2D:
				kill_player();
				return true;
			else:
				remove_box(subject);
				return false;

		var drop_tile = GameLevelManager.get_block_object(drop_floor, x, y);
		print("[handle_pit] 下层格子类型: %s" % drop_tile);
		
		if drop_tile == "V" or drop_tile == "W":
			if subject is CharacterBody2D:
				kill_player();
				return true;
			else:
				remove_box(subject);
				return false;
				
		var can_stop = false;
		if drop_tile != "D":
			can_stop = true;
		else:
			for pit in get_tree().get_nodes_in_group("pit"):
				if pit.address == Vector3(drop_floor, x, y) and pit.is_pit_filled:
					can_stop = true;
					break;
					
		var offset_diff = CameraManager.floor_offsets[drop_floor] - CameraManager.floor_offsets[current_floor];
		subject.global_position += offset_diff;
		if subject.has_node("Sprite2D"):
			subject.get_node("Sprite2D").global_position = subject.global_position;
		if subject.get("sprite_node_pos_tween"):
			subject.sprite_node_pos_tween.kill();
			
		if subject is CharacterBody2D:
			subject.current_floor = drop_floor;
			subject.floor_offset = CameraManager.floor_offsets[drop_floor];
			CameraManager.switch_to_floor(subject.current_floor);
		elif subject.is_in_group("box_normal"):
			subject.current_floor = drop_floor;
			subject.floor_offset = CameraManager.floor_offsets[drop_floor];
			var under = GameLevelManager.get_box_under(drop_floor, x, y);
			if under == "goal":
				subject.under = "goal"
				subject._update_visual();
				on_box_entered_goal();
			else:
				if subject.under == "goal":
					on_box_left_goal();
				subject.under = "";
				subject._update_visual();
				
		if get_player_at(drop_floor, x, y) != null and subject != get_player_at(drop_floor, x, y):
			kill_player();
			return true;
			
		if can_stop:
			print("[handle_pit] 停止于层%d" % drop_floor);
			break;
		else:
			current_floor = drop_floor;
			print("[handle_pit] 继续下落");
	refresh_all_pit();
	return false;
	
func check_support_removed(support_floor: int, x: int, y: int):
	var above_floor = support_floor + 1;
	if above_floor >= GameLevelManager.floor_count:
		return;
	var above_tile = GameLevelManager.get_block_object(above_floor, x, y);
	if above_tile != "D":
		return;
	var subject = GameLevelManager.get_box_at(above_floor, x, y);
	if subject != null:
		handle_pit(subject, above_floor, x, y);
		
func reset_level():
	get_tree().reload_current_scene();
	
func refresh_all_pit():
	for pit in get_tree().get_nodes_in_group("pit"):
		pit.update_filled_state();
