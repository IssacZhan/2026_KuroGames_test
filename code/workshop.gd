extends Node2D

var edit_width: int = 0;
var edit_height: int = 0;
var edit_floor_count: int = 0;
var current_edit_floor: int = 0;
var floor_data: Array = [];
var selected_char: String = " ";
var selected_button: Button = null;
const tile_size: int = 32;
var grid_sprites: Array = [];
var preview_sprite: Sprite2D;
var mouse_offset: Vector2 = Vector2(16,16);

var ghost_floor: int = -1;
var ghost_sprites: Array = [];
var floor_offsets = [
	Vector2(0, 0),
	Vector2(1600, 0),
	Vector2(3200, 0)
];

@onready var status_label = $UI/StatusLabel

func _ready():
	edit_floor_count = 3;
	edit_width=42;
	edit_height=20;	
	_init_empty_map();
	_draw_grid();
	_draw_ghost();
	_connect_buttons();
	preview_sprite = Sprite2D.new()
	preview_sprite.z_index = 100;
	add_child(preview_sprite);
	_update_floor_buttons();
	CameraManager.global_position = floor_offsets[current_edit_floor] + Vector2(edit_width * tile_size, edit_height * tile_size) * 0.5;
	
	if FileAccess.file_exists("user://temp_level.json"):
		if GameSystemManager.is_playtest_win:
			_show_save_dialog();
		else:
			DirAccess.remove_absolute("user://temp_level.json");
	
func _process(_delta):
	_update_preview_sprite();

func _init_empty_map():
	floor_data.clear();
	for f in range(edit_floor_count):
		var layer = [];
		for y in range(edit_height):
			var row = "";
			for x in range(edit_width):
				row += "V";
			layer.append(row);
		floor_data.append(layer);

func _draw_grid():
	for sprite in grid_sprites:
		sprite.queue_free();
	grid_sprites.clear();
	
	var layer = floor_data[current_edit_floor];
	for y in range(edit_height):
		for x in range(edit_width):
			var ch = layer[y][x];
			var sprite = _formulate_tile_sprite(ch, x, y);
			add_child(sprite);
			grid_sprites.append(sprite);

func _char_to_texture(ch: String) -> Texture2D:
	match ch:
		"W": return preload("res://sprite/object/wall.png");
		" ": return preload("res://sprite/object/floor.png");
		"B": return preload("res://sprite/object/crate.png");
		"G": return preload("res://sprite/object/floor_target.png");
		"P": return preload("res://sprite/player/player_on_floor.png");
		"D": return preload("res://sprite/object/hole.png");
		"U": return preload("res://sprite/object/elevator.png");
		"V": return preload("res://sprite/object/void.png");
		"1": return preload("res://sprite/object/crate.png");
		"2": return preload("res://sprite/player/player_on_goal.png");
		_: return preload("res://sprite/object/floor.png");

func _connect_buttons():
	var buttons = $UI/Panel/HBoxContainer.get_children();
	for btn in buttons:
		btn.connect("pressed", Callable(self, "_on_palette_button_pressed").bind(btn));
	for btn in $UI/Panel/FloorButtons.get_children():
		btn.connect("pressed", Callable(self, "_on_floor_button_pressed").bind(btn));

func _on_palette_button_pressed(btn: Button):
	if selected_button:
		selected_button.modulate = Color(1,1,1,1);
	selected_button = btn;
	selected_button.modulate = Color(1.5, 1.5, 1.5, 1);
	
	match btn.text:
		"Wall": selected_char = "W";
		"Floor": selected_char = " ";
		"Box": selected_char = "B";
		"Goal": selected_char = "G";
		"Player": selected_char = "P";
		"Pit": selected_char = "D"
		"Elevator": selected_char = "U";
		"Erase": selected_char = "V";
		_: selected_char = " ";

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position() + mouse_offset - floor_offsets[current_edit_floor];
		var gx = int(mouse_pos.x / tile_size);
		var gy = int(mouse_pos.y / tile_size);
		if gx >= 0 and gx < edit_width and gy >= 0 and gy < edit_height:
			_place_tile(gx, gy);

func _place_tile(x: int, y: int):
	var current_char = floor_data[current_edit_floor][y][x];
	var new_char = current_char;

	match selected_char:
		"P":
			_remove_all_char("P");
			_remove_all_char("2");
			if current_char == " ":
				new_char = "P";
			elif current_char == "G":
				new_char = "2";
			elif current_char == "B":
				new_char = "P";
			elif current_char == "1":
				new_char = "2";
		"B":
			if current_char == " ":
				new_char = "B";
			elif current_char == "G":
				new_char = "1";
			elif current_char == "P":
				new_char = "B";
			elif current_char == "2":
				new_char = "1";
		"G":
			if current_char == " ":
				new_char = "G";
			elif current_char == "B":
				new_char = "1";
			elif current_char == "P":
				new_char = "2";
		"W", "D", "U":
			new_char = selected_char;
		" ":
			if current_char == "1":
				new_char = "G";
			elif current_char == "2":
				new_char = "G";
			else:
				new_char = " ";
		"V":
			new_char = "V";
			
	var row = floor_data[current_edit_floor][y];
	floor_data[current_edit_floor][y] = row.left(x) + new_char + row.right(edit_width - x - 1);
	_draw_grid();
	_draw_ghost();
	status_label.text = "放置 %s 于 (%d, %d)" % [selected_char, x, y];

func _remove_all_char(c: String):
	for f in range(edit_floor_count):
		for y in range(edit_height):
			var row = floor_data[f][y];
			var new_row = "";
			for x in range(edit_width):
				if row[x] == c:
					new_row += " ";
				else:
					new_row += row[x];
			floor_data[f][y] = new_row;
			
func _formulate_tile_sprite(ch: String, x: int, y: int) -> Sprite2D:
	var texture = _char_to_texture(ch);
	var sprite = Sprite2D.new();
	sprite.texture = texture;
	sprite.position = Vector2(x * tile_size, y * tile_size) + floor_offsets[current_edit_floor];
	var tex_size = texture.get_size();
	if tex_size.x > 0 and tex_size.y > 0:
		sprite.scale = Vector2(tile_size / tex_size.x, tile_size / tex_size.y);
	return sprite;

func _update_preview_sprite():
	var mouse_pos = get_global_mouse_position() + mouse_offset - floor_offsets[current_edit_floor];
	var gx = int(mouse_pos.x / tile_size);
	var gy = int(mouse_pos.y / tile_size);
	if gx >= 0 and gx < edit_width and gy >= 0 and gy < edit_height:
		preview_sprite.visible = true;
		preview_sprite.texture = _char_to_texture(selected_char);
		preview_sprite.position = Vector2(gx * tile_size, gy * tile_size) + floor_offsets[current_edit_floor];
		var tex = preview_sprite.texture;
		if tex:
			var ts = tex.get_size();
			if ts.x > 0 and ts.y > 0:
				preview_sprite.scale = Vector2(tile_size / ts.x, tile_size / ts.y);
	else:
		preview_sprite.visible = false;
		
func _on_floor_button_pressed(btn: Button):
	var floor_text = btn.text;
	var idx = floor_text.substr(1).to_int() - 1;
	if idx >= 0 and idx < edit_floor_count:
		current_edit_floor = idx;
		_draw_grid();
		_draw_ghost();
		_update_floor_buttons();
		status_label.text = "切换到楼层 %d" % (idx + 1);
		CameraManager.global_position = floor_offsets[current_edit_floor] + Vector2(edit_width * tile_size, edit_height * tile_size) * 0.5;;

func _update_floor_buttons():
	for btn in $UI/Panel/FloorButtons.get_children():
		var floor_idx = btn.text.substr(1).to_int() - 1;
		if floor_idx == current_edit_floor:
			btn.modulate = Color(1.5, 1.5, 1.5, 1);
		else:
			btn.modulate = Color(1, 1, 1, 1);
			
func _on_ghost_option_selected(index: int):
	if index == 0:
		ghost_floor = -1;
	else:
		ghost_floor = index - 1;
	_draw_ghost();
	
func _draw_ghost():
	for sprite in ghost_sprites:
		sprite.queue_free();
	ghost_sprites.clear();

	if ghost_floor < 0 or ghost_floor == current_edit_floor or ghost_floor >= edit_floor_count:
		return;

	var layer = floor_data[ghost_floor];
	for y in range(edit_height):
		for x in range(edit_width):
			var ch = layer[y][x];
			if ch == "V":
				continue;
			var sprite = Sprite2D.new();
			sprite.texture = _char_to_texture(ch);
			sprite.position = Vector2(x * tile_size, y * tile_size) + floor_offsets[current_edit_floor];
			sprite.z_index = 150;
			sprite.modulate = Color(1, 1, 1, 0.5);
			var tex = sprite.texture;
			if tex:
				var ts = tex.get_size();
				if ts.x > 0 and ts.y > 0:
					sprite.scale = Vector2(tile_size / ts.x, tile_size / ts.y);
			add_child(sprite);
			ghost_sprites.append(sprite);
			
func validate_level() -> bool:
	var errors = [];
	
	var player_count = 0;
	var box_count = 0;
	var goal_count = 0;
	var player_pos = [-1, -1, -1];
	
	for f in range(edit_floor_count):
		for y in range(edit_height):
			for x in range(edit_width):
				var ch = floor_data[f][y][x]
				if ch == "P" or ch == "2":
					player_count += 1;
					player_pos = [f, x, y];
				if ch == "B" or ch == "1":
					box_count += 1;
				if ch == "G" or ch == "1" or ch == "2":
					goal_count += 1;
					
	if player_count == 0:
		errors.append("no player");
	if player_count > 1:
		errors.append("more than one player");
	if box_count == 0:
		errors.append("at least 1 box");
	if goal_count == 0:
		errors.append("at least 1 goal");
		
	for f in range(1, edit_floor_count):
		for y in range(edit_height):
			for x in range(edit_width):
				if floor_data[f][y][x] == "D" and floor_data[f-1][y][x] == "W":
					errors.append("a wall under a pit");
					
	for y in range(edit_height):
		for x in range(edit_width):
			var has_D = false;
			var has_U = false;
			for f in range(edit_floor_count):
				var ch = floor_data[f][y][x]
				if ch == "D": has_D = true;
				if ch == "U": has_U = true;
			if has_D and has_U:
				errors.append("pit and elevator at same address");
				
	if player_count == 1:
		if player_pos != null:
			var visited = [];
			var queue = [player_pos];
			var is_open = false;
			while queue.size() > 0:
				var pos = queue.pop_front();
				if pos in visited: continue;
				visited.append(pos);
				var f = pos[0]; var x = pos[1]; var y = pos[2];
				var neighbors = [[f, x-1, y], [f, x+1, y], [f, x, y-1], [f, x, y+1]];
				for n in neighbors:
					var nf = n[0]; var nx = n[1]; var ny = n[2];
					if nx < 0 or nx >= edit_width or ny < 0 or ny >= edit_height:
						is_open = true;
						break;
					if n in visited:
						continue;
					var nc = floor_data[nf][ny][nx];
					if nc == "W" or nc == "V":
						continue;
					queue.append([nf, nx, ny]);
				if is_open:
					break;
			if is_open:
				errors.append("room not sealed");
				
	if errors.size() > 0:
		status_label.text = errors[0];
		return false;
	else:
		status_label.text = "map valid";
		return true;
		
func _on_test_play_pressed():
	if not validate_level():
		return;
	_export_temp_level();
	GameLevelManager.current_level_path = "user://temp_level.json";
	GameLevelManager.play_mode = "workshop";
	get_tree().change_scene_to_file("res://scene/playground.tscn");
	
func _on_return_menu_pressed():
	get_tree().change_scene_to_file("res://scene/main_menu.tscn");

func _export_temp_level():
	var bounds = _get_minimal_bounds();
	var cropped_width = bounds[1] - bounds[0] + 1;
	var cropped_height = bounds[3] - bounds[2] + 1;

	var cropped_floors = [];
	for f in range(edit_floor_count):
		var layer = [];
		for y in range(bounds[2], bounds[3] + 1):
			var row = floor_data[f][y].substr(bounds[0], cropped_width);
			layer.append(row);
		cropped_floors.append(layer);

	var data = {
		"name": "workshop_temp",
		"width": cropped_width,
		"height": cropped_height,
		"floors": []
	};
	for layer in cropped_floors:
		data["floors"].append({"data": layer});

	var file = FileAccess.open("user://temp_level.json", FileAccess.WRITE);
	if file == null:
		status_label.text = "save failed";
		return;
	file.store_string(JSON.stringify(data, "\t"));
	file.close();
	
func _get_minimal_bounds() -> Array:
	var min_x = edit_width;
	var max_x = -1;
	var min_y = edit_height;
	var max_y = -1;
	for f in range(edit_floor_count):
		for y in range(edit_height):
			for x in range(edit_width):
				if floor_data[f][y][x] != "V":
					if x < min_x: min_x = x;
					if x > max_x: max_x = x;
					if y < min_y: min_y = y;
					if y > max_y: max_y = y;
	if min_x > max_x:
		min_x = 0; 
		max_x = 0; 
		min_y = 0; 
		max_y = 0;
	return [min_x, max_x, min_y, max_y];
	
func _show_save_dialog():
	var dialog = AcceptDialog.new();
	dialog.title = "save level";
	dialog.dialog_text = "input name:"
	dialog.size = Vector2(400, 150);
	var line_edit = LineEdit.new();
	line_edit.placeholder_text = "My Level";
	dialog.add_child(line_edit);
	dialog.register_text_enter(line_edit);
	dialog.confirmed.connect(Callable(self, "_on_save_dialog_confirmed").bind(line_edit));
	add_child(dialog);
	dialog.popup_centered();

func _on_save_dialog_confirmed(line_edit: LineEdit):
	var file_name = line_edit.text.strip_edges()
	if file_name == "":
		file_name = "untitled";
	var dir = "res://level/workshop/";
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir);
	var dest_path = dir + file_name + ".json";
	var temp_file = FileAccess.open("user://temp_level.json", FileAccess.READ);
	var content = temp_file.get_as_text();
	temp_file.close();
	var json = JSON.new();
	json.parse(content);
	var data = json.get_data();
	data["name"] = file_name;
	content = JSON.stringify(data, "\t");
	var dest_file = FileAccess.open(dest_path, FileAccess.WRITE);
	dest_file.store_string(content);
	dest_file.close();
	DirAccess.remove_absolute("user://temp_level.json");
