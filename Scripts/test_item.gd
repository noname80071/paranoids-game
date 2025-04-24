class_name ItemBase
extends Node3D

@export var rotation_speed := 2.0
@export var detection_radius := 0.8


var item_data: ItemResource

var pickup_area: Area3D
var player_near: bool = false

func get_item_data() -> ItemResource:
	return item_data

func _ready():
	set_physics_process(true)

	add_to_group("items")

	setup_detection_area()

func setup(data: ItemResource):
	item_data = data

# Создаем Area для обнаружения игроком
func setup_detection_area():
	pickup_area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = detection_radius
	collision_shape.shape = sphere_shape

	pickup_area.add_child(collision_shape)
	add_child(pickup_area)

	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.item_in_range(self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		body.item_out_of_range(self)

func _physics_process(delta):
	rotate_y(rotation_speed * delta)
