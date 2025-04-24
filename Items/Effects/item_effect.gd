# item_effect.gd
extends Resource
class_name ItemEffect

@export var effect_type: String  # "stat_modifier", "dot_effect", "trigger_skill", etc.

# Базовый метод, который переопределяется в дочерних классах
func apply(target: Node) -> void:
	pass
