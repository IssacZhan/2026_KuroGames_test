extends CharacterBody2D

const tile_size: Vector2 = Vector2(32, 32);
const sprite_up = preload("res://sprite/player/player_up.png");
const sprite_down = preload("res://sprite/player/player_down.png");
const sprite_left = preload("res://sprite/player/player_left.png");
const sprite_right = preload("res://sprite/player/player_right.png");
var sprite_node_pos_tween: Tween = null;
var maze_offset: Vector2 = Vector2(0, 0);
var current_floor = 0;
var floor_offset: Vector2 = Vector2(0, 0);
var last_teleport_pos: Vector3 = Vector3(-1, -1, -1);

func _ready():
	add_to_group("player");
	z_index = 2;
	last_teleport_pos = Vector3(-1, -1, -1);

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_up"):
		$Sprite2D.texture = sprite_up;
		_test_if_can_move($up, Vector2(0, -1));
	elif Input.is_action_just_pressed("ui_down"):
		$Sprite2D.texture = sprite_down;
		_test_if_can_move($down, Vector2(0, 1));
	elif Input.is_action_just_pressed("ui_left"):
		$Sprite2D.texture = sprite_left;
		_test_if_can_move($left, Vector2(-1, 0));
	elif Input.is_action_just_pressed("ui_right"):
		$Sprite2D.texture = sprite_right;
		_test_if_can_move($right, Vector2(1, 0));
			
func _test_if_can_move(ray: RayCast2D, dir: Vector2):
	if !ray.is_colliding():
		_move(dir);
		return;
		
	var obj = ray.get_collider()
	if obj.is_in_group("box_normal"):
		var box_old_grid = GameLevelManager.get_object_grid_pos(obj);
		var target_floor = box_old_grid.x;
		var target_x = box_old_grid.y + int(dir.x);
		var target_y = box_old_grid.z + int(dir.y);
		
		if GameLevelManager.get_block_object(target_floor, target_x, target_y) == "U":
			return;
			
		var box_ray = obj.get_box_raycast(dir);
		if box_ray and !box_ray.is_colliding():
			obj.move(dir);
			_move(dir);
			GameSystemManager.check_support_removed(box_old_grid.x, box_old_grid.y, box_old_grid.z);
			GameSystemManager.refresh_all_pit();
		
func _move(dir: Vector2):
	global_position += dir * tile_size;
	$Sprite2D.global_position -= dir * tile_size;
	
	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill();
	sprite_node_pos_tween = create_tween();
	sprite_node_pos_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS);
	sprite_node_pos_tween.tween_property($Sprite2D, "global_position", global_position, 0.2).set_trans(Tween.TRANS_SINE);
	
	_check_special_tile();
	_check_player_pit();
	GameSystemManager.refresh_all_pit();
	
func _check_special_tile():
	var gx = GameLevelManager.get_object_grid_pos(self).y;
	var gy = GameLevelManager.get_object_grid_pos(self).z;
	var under = GameLevelManager.get_box_under(current_floor, gx, gy);

	if under == "elevator":
		if GameLevelManager.get_object_grid_pos(self) == last_teleport_pos:
			return;

		var target_floor = -1;
		if current_floor - 1 >= 0 and GameLevelManager.get_block_object(current_floor - 1, gx, gy) == "U":
			target_floor = current_floor - 1;
		elif current_floor + 1 < GameLevelManager.floor_count and GameLevelManager.get_block_object(current_floor + 1, gx, gy) == "U":
			target_floor = current_floor + 1;

		if target_floor != -1:
			_teleport(target_floor);
			last_teleport_pos = Vector3(target_floor, gx, gy);
		return

	last_teleport_pos = Vector3(-1, -1, -1)

func _teleport(target_floor: int):
	var temp = CameraManager.floor_offsets[target_floor] - floor_offset;
	global_position += temp;
	$Sprite2D.global_position = global_position;
	if sprite_node_pos_tween:
		sprite_node_pos_tween.kill();
		
	current_floor = target_floor;
	floor_offset = CameraManager.floor_offsets[target_floor];
	CameraManager.switch_to_floor(target_floor);
	
func _check_player_pit():
	var my_pos = GameLevelManager.get_object_grid_pos(self);
	if GameLevelManager.get_block_object(my_pos.x, my_pos.y, my_pos.z) == "D":
		if GameSystemManager.handle_pit(self, my_pos.x, my_pos.y, my_pos.z):
			return;
