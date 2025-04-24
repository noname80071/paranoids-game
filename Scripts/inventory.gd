extends Control

@onready var slot_scene = preload("res://Scenes/slot.tscn")
@onready var grid_container = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var scroll_container = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count = grid_container.columns

var grid_array := []
var item_held = null
var current_slot = null
var can_place := false
var icon_anchor := Vector2i.ZERO

var active_items_with_effects: Array = []

func _ready() -> void:
	# Создаем слоты инвентаря
	for i in range(80):
		create_slot()
	
	# Инициализация инвентаря перед скрытием
	await get_tree().process_frame
	hide()

func _process(delta: float) -> void:
	if item_held:
		# Перемещаем предмет за курсором
		item_held.global_position = get_global_mouse_position() - item_held.IconRect_path.size / 2
		
		if Input.is_action_just_pressed("rotate_item"):
			rotate_item()
		
		if Input.is_action_just_pressed("inventory_mouse_leftclick"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				place_item()
	else:
		if Input.is_action_just_pressed("inventory_mouse_leftclick"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				pick_item()

func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_container.add_child(new_slot)
	grid_array.push_back(new_slot)
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)

func _on_slot_mouse_entered(slot: Control) -> void:
	current_slot = slot
	if item_held:
		check_slot_availability(slot)
		set_grids(slot)

func _on_slot_mouse_exited(_slot: Control) -> void:
	clear_grid()

func check_slot_availability(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid.x + grid.y * col_count
		var line_switch_check = a_Slot.slot_ID % col_count + grid.x
		if line_switch_check < 0 or line_switch_check >= col_count:
			can_place = false
			return
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			can_place = false
			return
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			can_place = false
			return

	can_place = true

func set_grids(a_slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_slot.slot_ID + grid.x + grid.y * col_count
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
		#make sure the check don't wrap around boarders
		var line_switch_check = a_slot.slot_ID % col_count + grid.x
		if line_switch_check <0 or line_switch_check >= col_count:
			continue
		
		if can_place:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.FREE)
			#save anchor for snapping
			if grid.y < icon_anchor.x: icon_anchor.x = grid.y
			if grid.x < icon_anchor.y: icon_anchor.y = grid.x
				
		else:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.TAKEN)

func clear_grid() -> void:
	for slot in grid_array:
		slot.set_color(slot.States.DEFAULT)

func rotate_item() -> void:
	if item_held:
		item_held.rotate_item()
		clear_grid()
		if current_slot:
			check_slot_availability(current_slot)
			set_grids(current_slot)

func place_item():
	if not can_place or not current_slot: 
		return 
		
	item_held.get_parent().remove_child(item_held)
	grid_container.add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	var calculated_grid_id = current_slot.slot_ID + icon_anchor.x * col_count + icon_anchor.y
	item_held._snap_to(grid_array[calculated_grid_id].global_position)
	
	item_held.grid_anchor = current_slot
	for grid in item_held.item_grids:
		var grid_to_check = current_slot.slot_ID + grid.x + grid.y * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN 
		grid_array[grid_to_check].item_stored = item_held
	
	
	item_held = null
	clear_grid()

func pick_item():
	if not current_slot or not current_slot.item_stored: 
		return
	item_held = current_slot.item_stored
	item_held.selected = true

	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()

	
	for grid in item_held.item_grids:
		var grid_to_check = item_held.grid_anchor.slot_ID + grid.x + grid.y * col_count 
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE 
		grid_array[grid_to_check].item_stored = null
	
	check_slot_availability(current_slot)
	set_grids.call_deferred(current_slot)

# Добавляем этот метод в ваш инвентарь
func find_free_space_for_item(item_grids: Array) -> int:
	# Проходим по всем слотам инвентаря
	for slot in grid_array:
		
		# Проверяем, можно ли разместить предмет в текущем слоте
		if can_item_fit_at_slot(slot.slot_ID, item_grids):
			return slot.slot_ID
	return -1  # Возвращаем -1 если место не найдено

# Вспомогательный метод для проверки, помещается ли предмет в указанный слот
func can_item_fit_at_slot(slot_id: int, item_grids: Array) -> bool:
	# Проверяем каждый блок предмета
	for grid in item_grids:
		var grid_to_check = slot_id + grid.x + grid.y * col_count
		
		# Проверка выхода за границы инвентаря
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			return false
		
		# Проверка на перенос между строками
		var line_switch_check = slot_id % col_count + grid.x
		if line_switch_check < 0 or line_switch_check >= col_count:
			return false
		
		# Проверка занятости слота
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			return false
	
	return true

func add_item(item_data: ItemResource) -> bool:
	var new_item = item_data.texture.instantiate()
	grid_container.add_child(new_item)
	new_item.load_item(item_data)

	# Находим свободное место
	var anchor_slot_id := find_free_space_for_item(item_data.grid_cells)
	if anchor_slot_id == -1:
		new_item.queue_free()
		return false

	var anchor_slot = grid_array[anchor_slot_id]

	var calculated_grid_id = anchor_slot.slot_ID + icon_anchor.x * col_count + icon_anchor.y
	new_item._snap_to(grid_array[calculated_grid_id].global_position)
	new_item.grid_anchor = anchor_slot

	# Вычисляем якорь для этого предмета (минимальные x и y в grid_cells)
	#var item_anchor := Vector2i.ZERO
	#for cell in item_data.grid_cells:
		#item_anchor.x = min(item_anchor.x, cell.y)
		#item_anchor.y = min(item_anchor.y, cell.x)

	## Правильно вычисляем основной слот для позиционирования
	#var main_slot_id = anchor_slot.slot_ID + item_anchor.x * col_count + item_anchor.y
	#if main_slot_id < 0 or main_slot_id >= grid_array.size():
		#new_item.queue_free()
		#return false
	#print(main_slot_id)
	## Позиционируем предмет
	#new_item._snap_to(grid_array[main_slot_id].global_position)
	#new_item.grid_anchor = anchor_slot

	# Помечаем ВСЕ занятые слоты
	for cell in item_data.grid_cells:
		var slot_id = anchor_slot.slot_ID + cell.x + cell.y * col_count
		if 0 <= slot_id and slot_id < grid_array.size():
			grid_array[slot_id].state = grid_array[slot_id].States.TAKEN
			grid_array[slot_id].item_stored = new_item
	
	_apply_item_effects(item_data)
	
	return true


func _apply_item_effects(item) -> void:
	if item.effects.is_empty():
		return

	active_items_with_effects.append(item)
	for effect in item.effects:
		effect.apply_effect(get_player())

func get_player():
	# Реализуйте получение ссылки на игрока
	return get_node("/root/Floor/Player") # или ваш путь к игроку
