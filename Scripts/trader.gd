extends CharacterBody3D

@export var items_for_sale: Array[ItemResource]

@onready var items: Node3D = $Items
@export var ui_scene: PackedScene
var ui_instance: Control
var item_labels: Array[Label3D] = []
var item_instances: Array[Node] = []  # Для хранения созданных экземпляров предметов

func _ready() -> void:
	for i in range(items.get_children().size()): # По количеству стоек для предметов у торговца
		var item_rack = items.get_child(i) # Стойка для предмета.
		if i < items_for_sale.size():
			var item_instance = items_for_sale[i].model.instantiate()
			item_rack.add_child(item_instance)
			item_instance.position.y += 1
			item_instance.add_to_group('trader_items')
			item_instance.setup(items_for_sale[i])
			item_instances.append(item_instance)  # Сохраняем ссылку

			# Создаем Label для каждого предмета
			var label = Label3D.new()
			label.text = "%s\nЦена: %d\n%s" % [items_for_sale[i].name, items_for_sale[i].price, items_for_sale[i].description]
			label.font_size = 32
			label.outline_size = 16
			label.pixel_size = 0.005
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.position.y = 2  # Размещаем над предметом
			item_rack.add_child(label)
			item_labels.append(label)
			item_instance.set_meta('price_label', label)
			label.visible = false

func remove_item(item_node: Node) -> bool:
	var index = item_instances.find(item_node)
	if index != -1:
		# Удаляем метку
		if index < item_labels.size():
			item_labels[index].queue_free()
			item_labels.remove_at(index)

		# Удаляем предмет
		item_instances.remove_at(index)
		item_node.queue_free()
		return true
	return false
	
func release_item(item_node: Node, buyer: Node3D):  # Добавляем параметр buyer - это нода игрока
	if item_node in item_instances:
		var label = item_node.get_meta('price_label')
		if label:
			label.queue_free()
			item_labels.erase(label)
			
		item_node.remove_from_group('trader_items')
		item_instances.erase(item_node)
		
		var item_height = 0.1

		var stand = item_node.get_parent()
		var drop_position = stand.global_position
		
		# Определяем направление к игроку
		var to_buyer = (buyer.global_position - stand.global_position).normalized()
		
		# Корректируем направление - оставляем только X и Z компоненты (горизонтальная плоскость)
		to_buyer.y = 0
		to_buyer = to_buyer.normalized()
		
		# Задаем конечную позицию в направлении игрока на расстоянии
		drop_position += to_buyer * 0.5
		drop_position.y = stand.global_position.y  # Сбрасываем Y-компоненту
		
		# Определяем точное положение поверхности
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = drop_position + Vector3.UP * 10  # Начинаем выше
		query.to = drop_position - Vector3.UP * 10    # Заканчиваем ниже
		query.collision_mask = 1  # Проверяем только слой 1
		
		var result = space_state.intersect_ray(query)
		if result:
			drop_position.y = result.position.y + item_height  # Устанавливаем точную высоту поверхности
		
		item_node.scale = Vector3(0.2, 0.2, 0.2)

		stand.remove_child(item_node)
		get_parent().add_child(item_node)
		item_node.global_position = stand.global_position + Vector3(0, 0.2, 0)

		animate_item_drop(item_node, drop_position)


func animate_item_drop(item_node: Node, target_position: Vector3):
	var tween = create_tween().set_parallel(true)
	var total_duration = 1.0
	var start_position = item_node.global_position
	
	# Вычисляем дугу с учетом точной высоты поверхности
	var arc_height = 1.5
	var mid_point = (start_position + target_position) * 0.5
	mid_point.y = max(start_position.y, target_position.y) + arc_height
	
	# Анимация движения по дуге
	tween.tween_method(
		func(t):
			# Квадратичная кривая для плавной дуги
			var current_pos = start_position.lerp(target_position, t)
			current_pos.y += sin(t * PI) * arc_height
			item_node.global_position = current_pos,
		0.0, 1.0, total_duration
	).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
func show_ui():
	ui_instance = ui_scene.instantiate()
	get_tree().root.add_child(ui_instance)
	ui_instance.visible = true
	# Анимация появления
	ui_instance.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(ui_instance, "modulate:a", 1, 0.3)
	
	# Показываем все labels
	for label in item_labels:
		label.visible = true

func hide_ui():
	# Анимация исчезновения перед удалением
	var tween = create_tween()
	tween.tween_property(ui_instance, "modulate:a", 0, 0.3)
	await tween.finished
	ui_instance.queue_free()
	
	# Скрываем все labels
	for label in item_labels:
		label.visible = false

func _on_trader_entered(body) -> void:
	if body.is_in_group('player'):
		body.trader_in_range(self)
		show_ui()

func _on_trader_exited(body) -> void:
	if body.is_in_group('player'):
		body.trader_out_of_range(self)
		hide_ui()
