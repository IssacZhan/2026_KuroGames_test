extends StaticBody2D

const tile_size: Vector2 = Vector2(32, 32);
var sprite_node_pos_tween: Tween = null;
var maze_offset: Vector2 = Vector2(0, 0);
var current_floor = 0;
var under: String = "";
var previous_under: String = "";
var floor_offset: Vector2 = Vector2(0, 0);

func _ready():
	z_index = 1;
	add_to_group("box_normal");
	var init_local = global_position - maze_offset - floor_offset;
	under = GameLevelManager.get_box_under(current_floor,int(init_local.x / 32) , int(init_local.y / 32));
	if under == "goal":
		GameSystemManager.on_box_entered_goal();
		_update_visual();

func move(dir: Vector2):
	global_position += dir * tile_size;
	$Sprite2D.global_position -= dir * tile_size;

	var local_position = global_position - maze_offset - floor_offset;
	previous_under = under;
	under = GameLevelManager.get_box_under(current_floor, int(local_position.x / 32), int(local_position.y / 32));

	if previous_under == "goal" and under != "goal":
		GameSystemManager.on_box_left_goal();
		_update_visual();
	elif previous_under != "goal" and under == "goal":
		GameSystemManager.on_box_entered_goal();
		_update_visual();

	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill();
	sprite_node_pos_tween = create_tween();
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS);
	sprite_node_pos_tween.tween_property($Sprite2D, "global_position", global_position, 0.2).set_trans(Tween.TRANS_SINE);

	_check_box_pit();
	
func get_box_raycast(dir: Vector2) -> RayCast2D:
	if dir == Vector2(0, -1):
		return get_node("up");
	elif dir == Vector2(0, 1):
		return get_node("down");
	elif dir == Vector2(-1, 0):
		return get_node("left");
	elif dir == Vector2(1, 0):
		return get_node("right");
	return null;
	
func _update_visual():
	if under == "goal":
		$Sprite2D.modulate = Color(1.5, 1.5, 1.5, 1);
	else:
		$Sprite2D.modulate = Color(1, 1, 1, 1);
		
func _check_box_pit():
	var my_pos = GameLevelManager.get_object_grid_pos(self);
	if GameLevelManager.get_block_object(my_pos.x, my_pos.y, my_pos.z) == "D":
		if GameSystemManager.handle_pit(self, my_pos.x, my_pos.y, my_pos.z):
			return;
