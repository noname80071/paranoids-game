extends Node3D

# Настройки
@export var mob_scene: PackedScene
@export var spawn_area_size: Vector3 = Vector3(50, 0, 50)
@export var spawn_height: float = 100.0
@export var min_spawn_distance: float = 10.0
@export var max_spawn_attempts: int = 20
@export var initial_spawn_count: int = 1
@export var spawn_interval: float = 5.0
@export var max_mobs: int = 15

var current_mobs: int = 0
var player: Node3D
var spawn_timer: Timer

func _ready():
	randomize()
	player = get_tree().get_first_node_in_group("player")
	
	# Инициализация таймера
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()
	
	# Начальный спавн
	for i in range(initial_spawn_count):
		spawn_mob()

func _on_spawn_timer_timeout():
	if current_mobs < max_mobs:
		spawn_mob()

func spawn_mob():
	var raycast = RayCast3D.new()
	add_child(raycast)
	
	# Настройка RayCast3D
	raycast.target_position = Vector3.DOWN * spawn_height * 2
	raycast.hit_from_inside = true
	raycast.collision_mask = 1  # Проверяем только первый слой коллизий
	
	var spawn_success = false
	var attempts = 0
	
	while not spawn_success and attempts < max_spawn_attempts:
		attempts += 1
		
		var random_pos = Vector3(
			randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
			spawn_height,
			randf_range(-spawn_area_size.z/2, spawn_area_size.z/2)
		)
		
		if random_pos.distance_to(player.global_position) < min_spawn_distance:
			continue
		
		raycast.global_position = random_pos
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			var collision_normal = raycast.get_collision_normal()
			
			if collision_normal.angle_to(Vector3.UP) < deg_to_rad(30):
				var mob = mob_scene.instantiate()
				add_child(mob)

				mob.global_position = collision_point + Vector3.UP * 0.5  # 0.5 - отступ от земли

				
				mob.global_position = collision_point + Vector3.UP * 0.5
				mob.rotate_y(randf_range(0, 2 * PI))
				
				print('Моб заспавнен в ', mob.global_position)
				
				# Подключаем сигнал смерти моба
				if mob.has_signal("died"):
					mob.died.connect(_on_mob_died)
				
				current_mobs += 1
				spawn_success = true
	
	raycast.queue_free()
	
	if not spawn_success:
		print("Не удалось найти валидную позицию для спавна после ", attempts, " попыток")

func _on_mob_died():
	current_mobs -= 1
