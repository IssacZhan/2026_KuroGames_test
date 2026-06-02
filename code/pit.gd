extends StaticBody2D

var is_pit_filled: bool = false;
const sprite_empty = preload("res://sprite/object/hole.png");
const sprite_filled = preload("res://sprite/object/crate_down.png");
var address: Vector3 = Vector3(-1, -1, -1);

func _ready():
	add_to_group("pit");
	update_filled_state();
	_apply_sprite();

func update_filled_state():
	var below_floor = address.x - 1;
	if below_floor >= 0:
		var box_below = GameLevelManager.get_box_at(below_floor, int(address.y), int(address.z));
		is_pit_filled = (box_below != null);
	_apply_sprite();

func mark_filled_by_fallen_box():
	if address.x == 0:
		is_pit_filled = true;
		_apply_sprite();
		
func _apply_sprite():
	if is_pit_filled:
		$Sprite2D.texture = sprite_filled;
	else:
		$Sprite2D.texture = sprite_empty;
