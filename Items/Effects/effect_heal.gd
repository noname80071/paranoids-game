extends ItemEffect
class_name HealEffect

@export_range(1, 1000) var heal_amount: int = 10

func apply(target: Node) -> void:
	if target.has_method("heal"):
		target.heal(heal_amount)
	else:
		push_error("Таргет не имеет метода heal")
