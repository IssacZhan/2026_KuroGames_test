extends Camera2D

var maze_offset: Vector2 = Vector2(0, 0);
var floor_offsets: Array = [];

func _ready():
	make_current();

func setup(data_offset: Vector2, data_floor_offsets: Array):
	maze_offset = data_offset;
	floor_offsets = data_floor_offsets;

func switch_to_floor(floor_index: int):
	if floor_index < 0 or floor_index >= GameLevelManager.floor_count:
		return;
	global_position = maze_offset + floor_offsets[floor_index] + Vector2(GameLevelManager.width * 32, GameLevelManager.height * 32 ) * 0.5;
