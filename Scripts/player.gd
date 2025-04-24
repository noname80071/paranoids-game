class_name BaseCharacter
extends CharacterBody3D

# Настройки движения
@export var acceleration = 10.0
@export var friction = 10.0

# Гравитация
var gravity = 9.8

@onready var camera = $Camera3D
@onready var ui: CanvasLayer = $PlayerUI
@onready var uiBalance: Label = ui.get_node('Control/Balance')
@onready var inventory = preload("res://Scenes/inventory.tscn")
@onready var anim_player: AnimationPlayer = $Mage/AnimationPlayer # Переделать!!!!!!!!!!!!!

@onready var ray_cast = $Camera3D/RayCast3D

@export var character_resource: CharacterResource
var stats: Stats

# Настройки камеры
@export var mouse_sensitivity = 0.002
@export var camera_min_angle = -60.0
@export var camera_max_angle = 60.0

var camera_rotation = Vector2.ZERO

@export var balance: int = 1000

@export var health = 100
var is_attacking = false
var can_attack = true

var items_in_range: Array[Node] = []
var traders_in_range: Array[Node] = [] # Торговцы в области взаимодействия.

enum CharacterState {IDLE, WALK, JUMP, ATTACK}
var current_state = CharacterState.IDLE
var previous_state = CharacterState.IDLE

func get_stats():
	return stats

func _physics_process(delta):

	match current_state:
		CharacterState.IDLE:
			handle_idle_state(delta)
		CharacterState.WALK:
			handle_walk_state(delta)
		CharacterState.JUMP:
			handle_jump_state(delta)
		CharacterState.ATTACK:
			await handle_attack_state()
	
	#if Input.is_action_just_pressed('attack') and can_attack:
		#handle_attack_state()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

func handle_idle_state(delta):

	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)

	if not anim_player.current_animation == 'Idle':
		anim_player.play('Idle')
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0:
		current_state = CharacterState.WALK
	elif Input.is_action_just_pressed('ui_accept') and is_on_floor():
		current_state = CharacterState.JUMP
		velocity.y = character_resource.stats['jump_force']
		anim_player.play('Jump_Full_Short')
	elif Input.is_action_just_pressed('attack'):
		await handle_attack_state()

func handle_walk_state(delta):
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = move_toward(velocity.x, 
		direction.x * stats.get_stat('speed'), 
		acceleration * delta)
		velocity.z = move_toward(velocity.z, 
		direction.z * stats.get_stat('speed'), 
		acceleration * delta)

		if is_on_floor() and not anim_player.current_animation == 'Walking_A':
			anim_player.play('Walking_A')
	else:
		current_state = CharacterState.IDLE

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		current_state = CharacterState.JUMP
		velocity.y = character_resource.stats['jump_force']
		anim_player.play('Jump_Full_Short')
	elif Input.is_action_just_pressed('attack') and can_attack:
		await handle_attack_state()

func handle_jump_state(delta):
	if is_on_floor():
		current_state = CharacterState.IDLE

func handle_attack_state():
	pass

func _ready():
	stats = Stats.new()
	stats.setup_custom_stats(character_resource.stats)
	stats.stat_changed.connect(_on_stat_changed)
	
	print("Max HP: ", stats.get_stat("max_hp"))
	inventory = inventory.instantiate()
	ui.add_child(inventory)
	# ХП
	ui.update_health(health, stats.get_stat('max_hp'))
	ui.update_balance(balance)

	# Скрываем и фиксируем курсор
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Анимации (плавная смена)
	anim_player.playback_default_blend_time = 0.2

func _on_stat_changed(stat_name: String, new_value: float):
	if stat_name == 'max_hp':
		ui.update_health(health, new_value)

func _input(event):
	if event is InputEventMouseMotion:
		# Вращение персонажа по горизонтали
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Вращение камеры по вертикали
		camera_rotation.y = clamp(
			camera_rotation.y - event.relative.y * mouse_sensitivity,
			deg_to_rad(camera_min_angle),
			deg_to_rad(camera_max_angle)
		)
		$Camera3D.rotation.x = camera_rotation.y

	if event.is_action_pressed("attack"):
		await handle_attack_state()

	if event.is_action_pressed("pickup") and items_in_range.size() > 0:
		pickup_item()

	if event.is_action_pressed("open_inventory"):
		inventory.visible = not inventory.visible
		if inventory.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("use_item") and items_in_range.size() > 0:
		use_item()

	if event.is_action_pressed("test"):
		test()

func change_balance(amount):
	balance += amount
	ui.update_balance(amount)

func test():
	print(balance)

func perform_attack():
	pass
	#if is_attacking:
		#return
#
	#is_attacking = true
	## Создаем область атаки
	#var space = get_world_3d().direct_space_state
	#var query = PhysicsRayQueryParameters3D.create(
		#global_position,
		#global_position + -global_transform.basis.z * character_resource.stats['attack_range']
	#)
	#var result = space.intersect_ray(query)
#
	#if result:
		#var enemy = result.collider
		#if enemy.is_in_group("enemy"):
			#print('Нанёс урон врагу', enemy)
			#enemy.take_damage(character_resource.stats['attack_damage'], self)
#
#
		## Временная визуализация
		#var hit_marker = MeshInstance3D.new()
		#hit_marker.mesh = SphereMesh.new()
		#hit_marker.scale = Vector3(0.2, 0.2, 0.2)
		#add_child(hit_marker)
		#hit_marker.global_position = result.position
		#await get_tree().create_timer(0.2).timeout
		#hit_marker.queue_free()
	#
	#await get_tree().create_timer(0.5).timeout
	#is_attacking = false

func take_damage(amount):
	print('Получил', amount)
	health -= amount
	ui.update_health(health, stats.get_stat('max_hp'))
	
	if health <= 0:
		print('Умер')

func heal(amount):
	health += amount
	ui.update_health(health, stats.get_stat('max_hp'))
	print('Персонаж вылечен на ', amount)
	print('Хп = ', health)

func pickup_item():
	if items_in_range[0].is_in_group('trader_items'):
		if not buy_item(items_in_range[0].get_item_data()):
			return
	if items_in_range.size() > 0:

		var item_node = items_in_range[0]
		var item_data = item_node.get_item_data()
		# Добавляем предмет в инвентарь
		if inventory.add_item(item_data):
			print('Подобран: ', item_node.name)
			item_node.queue_free()
			items_in_range.erase(item_node)
		else:
			print("В инвентаре нет места для предмета")

func use_item():
	if items_in_range.size() > 0:
		var item_node = items_in_range[0]
		var item_data = item_node.get_item_data()
		var item_effects = item_data.effects
		
		for effect in item_effects:
			effect.apply(self)
			print(health)
			item_node.queue_free()
			items_in_range.erase(item_node)

func buy_item(item_data: ItemResource):
	if items_in_range.size() > 0 and items_in_range[0].is_in_group('trader_items'):
		var item_node = items_in_range[0]
		
		if balance >= item_data.price:
			change_balance(-item_data.price)
			
			for trader in traders_in_range:
				if trader.has_method('release_item') and item_node in trader.item_instances:
					trader.release_item(item_node, self)
					items_in_range.erase(item_node)
					break
		else:
			print('Нет мани')
			return false
		
	
	#var item_node = items_in_range[0]
	#var price = item_data.price
	#if balance < price:
		#print('Недостаточно монет.')
		#return false
	#change_balance(-price)
	#var trader = find_trader_for_item(item_node)
	#if trader and trader.has_method("remove_item"):
		#trader.remove_item(item_node)
	#print('куплено')
	#return true

func item_in_range(item):
	if not item in items_in_range:
		items_in_range.append(item)
		print('Предмет в области ', item)

func item_out_of_range(item):
	if item in items_in_range:
		items_in_range.erase(item)
		print('Предмет вне области')

func trader_in_range(trader):
	if not trader in traders_in_range:
		traders_in_range.append(trader)
		print('Зона торговца')

func trader_out_of_range(trader):
	if trader in traders_in_range:
		traders_in_range.erase(trader)

# Вспомогательная функция для поиска торговца по предмету
func find_trader_for_item(item_node: Node) -> Node:
	for trader in traders_in_range:
		if trader.has_method("remove_item") and item_node in trader.item_instances:
			return trader
	return null
