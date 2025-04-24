extends Node2D

@onready var IconRect_path = $Icon

var item_ID: int
var item_grids := []
var selected = false
var grid_anchor = null
var cell_size = Vector2i(50.0, 50.0)

func _process(delta: float) -> void:
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)


# В классе предмета (Item) исправляем load_item:
func load_item(item_data: ItemResource) -> void:
	
	var icon_path = "res://Items/Sprites/" + item_data.name + ".jpg"  # Обычно используют .png для текстур
	if IconRect_path and ResourceLoader.exists(icon_path):
		IconRect_path.texture = load(icon_path)
	else:
		printerr("Failed to load icon: ", icon_path)

	item_grids = item_data.grid_cells  # Используем присваивание вместо push_back
	
	var item_pixel_size = Vector2i(item_data.width, item_data.height) * cell_size
	IconRect_path.custom_minimum_size = item_pixel_size


func rotate_item():
	for grid in item_grids:
		var temp_y = grid.x
		grid.x = -grid.y
		grid.y = temp_y
	rotation_degrees += 90
	if rotation_degrees >= 360:
		rotation_degrees = 0


func _snap_to(destination: Vector2):
	var tween = get_tree().create_tween()
	if int(rotation_degrees) % 180 == 0:
		destination += IconRect_path.size/2
	else:
		var temp_xy_switch = Vector2(IconRect_path.size.y, IconRect_path.size.x)
		destination += temp_xy_switch/2
		
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
