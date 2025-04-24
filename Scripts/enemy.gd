extends CharacterBody3D

# Настройки моба (обновленные значения)
@export var acceleration := 5.0  # Ускорение
@export var deceleration := 10.0  # Замедление
@export var rotation_speed := 8.0

# Настройки торможения перед атакой
@export var braking_distance := 1.0  # Дистанция начала торможения
@export var min_speed := 0.5  # Минимальная скорость при подходе

@export var enemy_data: MobResource
@export var stats: Stats

var health 

var target: Node3D
var can_attack := true

func _ready():
	stats = Stats.new()
	stats.setup_custom_stats(enemy_data.stats)
	stats.stat_changed.connect(_on_stat_changed)
	health = stats.get_stat('health')
	
	target = get_tree().get_first_node_in_group("player")
	if not target:
		push_error("Не найден объект с группой 'player'")
		queue_free()

func _on_stat_changed(stat_name: String, new_value: float):
	pass


func _physics_process(delta):
	if not target:
		return
	
	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction = to_target.normalized()
	direction.y = 0
	
	# Плавный поворот к игроку
	var target_rotation = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	# Управление скоростью с учетом дистанции
	if distance <= stats.get_stat('attack_range'):
		if can_attack:
			attack()
		# Полное торможение в зоне атаки
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
	elif distance < braking_distance:
		# Плавное торможение при приближении
		var target_speed = stats.get_stat('move_speed') * (distance / braking_distance)
		target_speed = max(target_speed, min_speed)
		var target_velocity = direction * target_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		# Полный разгон
		var target_velocity = direction * stats.get_stat('move_speed')
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	
	# Гравитация
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	
	move_and_slide()

# Остальные функции остаются без изменений
func attack():
	if not can_attack or not target:
		return
	
	can_attack = false
	
	if global_position.distance_to(target.global_position) <= stats.get_stat('attack_range'):
		target.take_damage(enemy_data.stats['attack_damage'])
		print("Моб атаковал игрока!")
	
	await get_tree().create_timer(enemy_data.stats['attack_cooldown']).timeout
	can_attack = true

func take_damage(amount: float, killer):
	health -= amount
	print("Моб получил урон: ", amount, ". Осталось здоровья: ", health)
	if health <= 0:
		die(killer)

func die(killer):
	print("Моб уничтожен")
	killer.change_balance(1)
	queue_free()

# Дроп предмета (возможно понадобится позже)
#func spawn_drop_item():
	#if drop_item_res:
		#var drop_item = drop_item_res.model.instantiate()
		#get_parent().add_child(drop_item)
		#drop_item.global_transform.origin = global_transform.origin
		#drop_item.scale = Vector3(0.1, 0.1, 0.1)
		#drop_item.global_transform.origin.x += randf_range(-0.5, 0.5)
		#drop_item.global_transform.origin.z += randf_range(-0.5, 0.5)
		#if drop_item.has_method("apply_impulse"):
			#var random_dir = Vector3(randf_range(-1, 1), 1, randf_range(-1, 1)).normalized()
			#drop_item.apply_impulse(random_dir * 2)
