extends Node2D

@onready var official_list: VBoxContainer = $CanvasLayer/HBoxContainer/OfficialVBox/ScrollContainer/OfficialList;
@onready var workshop_list: VBoxContainer = $CanvasLayer/HBoxContainer/WorkshopVBox/ScrollContainer/WorkshopList;

func _ready():
	_populate_list(official_list, "res://level/original/", "normal");
	_populate_list(workshop_list, "res://level/workshop/", "normal");

func _populate_list(container: VBoxContainer, dir_path: String, mode: String):
	for child in container.get_children():
		child.queue_free();

	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path);

	var dir = DirAccess.open(dir_path)
	if dir == null:
		_add_placeholder(container, "menu failed to access");
		return;

	var files := [];
	dir.list_dir_begin();
	var file_name = dir.get_next();
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(file_name);
		file_name = dir.get_next();
	dir.list_dir_end();

	if files.is_empty():
		_add_placeholder(container, "there's no levels");
		return;

	for fname in files:
		var full_path = dir_path + fname;
		var level_name = fname.replace(".json", "");
		var file = FileAccess.open(full_path, FileAccess.READ);
		if file:
			var text = file.get_as_text();
			file.close();
			var json = JSON.new();
			if json.parse(text) == OK:
				var data = json.get_data();
				if data is Dictionary and data.has("name"):
					level_name = data["name"];
		
		var btn = Button.new();
		btn.text = level_name;
		btn.size_flags_horizontal = Control.SIZE_FILL;
		btn.pressed.connect(Callable(self, "_on_level_selected").bind(full_path, mode));
		container.add_child(btn);

func _add_placeholder(container: VBoxContainer, text: String):
	var label = Label.new();
	label.text = text;
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
	label.add_theme_color_override("font_color", Color.GRAY);
	container.add_child(label);

func _on_level_selected(level_path: String, mode: String):
	GameLevelManager.current_level_path = level_path;
	GameLevelManager.play_mode = mode;
	get_tree().change_scene_to_file("res://scene/playground.tscn");

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scene/main_menu.tscn");
