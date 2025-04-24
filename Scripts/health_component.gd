# Пока бессмысленно, не используется
# Возможно буду использовать потом, незнаю надо оно или нет.
extends Node
class_name HealthComponent

signal health_changed(current_hp: float, max_hp: float)
signal died()

@export var max_hp: float = 100.0
var current_hp: float = max_hp

func initialize_health(new_max_hp: float):
	max_hp = new_max_hp
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

func set_max_hp(new_max_hp: float):
	max_hp = new_max_hp
	health_changed.emit(current_hp, max_hp)

func heal(amount: float):
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)
