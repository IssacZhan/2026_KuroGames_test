extends Node

# 关卡数据
var level_name: String = "";
var width: int = 0;
var height: int = 0;
var floor_count: int = 0;
var floors: Array = [];
var special_blocks: Dictionary = {};

const obj_wall = preload("res://obj/block/wall.tscn");
const obj_floor = preload("res://obj/block/floor.tscn");
const obj_box = preload("res://obj/block/box.tscn");
const obj_goal = preload("res://obj/block/goal.tscn");
const obj_elevator = preload("res://obj/block/elevator.tscn");
const obj_pit = preload("res://obj/block/pit.tscn");
const player = preload("res://obj/player.tscn");

var play_mode: String = "normal";
var current_level_path: String = "";

func load_level(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ);
	if file == null:
		print("file cant read");
		return false;

	var json_text = file.get_as_text();
	file.close();
	var json = JSON.new();
	var error = json.parse(json_text);
	if error != OK:
		print(json.get_error_message());
		return false;
	var data = json.get_data();
	if data == null or not data is Dictionary:
		print("file format wrong");
		return false;

	level_name = data.get("name", "unnamed file");
	width = data.get("width", 0);
	height = data.get("height", 0);
	if width <= 0 or height <= 0:
		print("level size error");
		return false;

	var floor_maps_json = data.get("floors", []);
	if floor_maps_json.is_empty():
		print("at least 1 floor");
		return false;

	floor_count = floor_maps_json.size();
	floors.clear();
	special_blocks.clear();

	for floor_index in range(floor_count):
		var this_floor_json = floor_maps_json[floor_index].get("data", []);
		if this_floor_json.size() != height:
			print("data height does not match with floor map of floor ", floor_index);
			return false;

		var this_floor_map = [];
		for y in range(height):
			var this_row: String = this_floor_json[y];
			if this_row.length() != width:
				print("data width does not match with floor map of floor ", floor_index);
				return false;
			this_floor_map.append(this_row);
		floors.append(this_floor_map);
		
	_build_properties();
	
	for floor_idx in range(1, floor_count):
		for y in range(height):
			for x in range(width):
				if get_block_object(floor_idx, x, y) == "D" and get_block_object(floor_idx - 1, x, y) == "W":
					print("a pit has wall below it");
					return false;
					
	for y in range(height):
		for x in range(width):
			var has_D = false;
			var has_U = false;
			for f in range(floor_count):
				var tile = get_block_object(f, x, y);
				if tile == "D":
					has_D = true;
				elif tile == "U":
					has_U = true;
			if has_D and has_U:
				print("elevator and pit in same location");
				return false;
					
	return true;

func _build_properties():
	special_blocks.clear();
	for floor_index in range(floor_count):
		for y in range(height):
			for x in range(width):
				if _translate_map(floors[floor_index][y][x]) != "":
					special_blocks[Vector3(floor_index, x, y)] = _translate_map(floors[floor_index][y][x]);

func _translate_map(temp: String) -> String:
	match temp:
		#"W": return "wall";
		"G": return "goal";
		"1": return "goal";
		"2": return "goal";
		"D": return "pit";
		"U": return "elevator";
		_: return "";

func get_block_object(floor_index: int, x: int, y: int) -> String:
	if floor_index < 0 or floor_index >= floor_count: 
		return "V";
	if x < 0 or x >= width or y < 0 or y >= height: 
		return "V";
	return floors[floor_index][y][x];

func get_box_under(floor_index: int, x: int, y: int) -> String:
	return special_blocks.get(Vector3(floor_index, x, y), "");
	
func get_player_starting_point() -> Dictionary:
	for floor_index in range(floor_count):
		for y in range(height):
			for x in range(width):
				if floors[floor_index][y][x] == "P" or floors[floor_index][y][x] == "2":
					return {"floor_index": floor_index, "x": x, "y": y};
	return {};
	
func get_all_boxes_location() -> Array:
	var box_address = [];
	for floor_index in range(floor_count):
		for y in range(height):
			for x in range(width):
				if floors[floor_index][y][x] == "B" or floors[floor_index][y][x] == "1":
					box_address.append({"floor_index": floor_index, "x": x, "y": y});
	return box_address;

func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(x * 32, y * 32);
	
func get_object_grid_pos(obj: Node) -> Vector3:
	var local = obj.global_position - obj.maze_offset - obj.floor_offset;
	var gx = int(local.x / 32);
	var gy = int(local.y / 32);
	return Vector3(obj.current_floor, gx, gy);
	
func get_box_at(floor_idx: int, x: int, y: int) -> StaticBody2D:
	for box in get_tree().get_nodes_in_group("box_normal"):
		if box.is_queued_for_deletion():
			continue;
		var pos = get_object_grid_pos(box);
		if pos.x == floor_idx and pos.y == x and pos.z == y:
			return box;
	return null;
	
func is_cell_supported(floor_idx: int, x: int, y: int) -> bool:
	if get_box_at(floor_idx, x, y) != null:
		return true;
	for hole in get_tree().get_nodes_in_group("pit"):
		if hole.address == Vector3(floor_idx, x, y) and hole.is_pit_filled:
			return true;
	return false;
