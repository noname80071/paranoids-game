class_name Stats extends Resource

signal stat_changed(stat_name: String, new_value: float)

@export var base_values: Dictionary
# Модификаторы
var modifiers: Dictionary = {}

# Функция для инициализации индивидуальных статов
func setup_custom_stats(custom_values: Dictionary) -> void:
	for stat in custom_values:
		base_values[stat] = custom_values[stat]


func get_stat(stat_name: String) -> float:
	var base = base_values.get(stat_name, 0.0)
	var total_add = 0.0
	var total_mult = 1.0
	
	# Обрабатываем все модификаторы для этой характеристики
	for mod in modifiers.get(stat_name, []):
		match mod.type:
			StatModifier.MOD_TYPE.FLAT:
				total_add += mod.amount
			StatModifier.MOD_TYPE.PERCENT_ADD:
				total_add += base * mod.amount / 100.0
				print(total_add)
			StatModifier.MOD_TYPE.PERCENT_MULT:
				total_mult *= 1.0 + mod.amount / 100.0
				
	return (base + total_add) * total_mult


func add_modifier(stat_name: String, modifier: StatModifier) -> void:
	if not modifiers.has(stat_name):
		modifiers[stat_name] = []
	modifiers[stat_name].append(modifier)
	stat_changed.emit(stat_name, get_stat(stat_name))

func remove_modifier(stat_name: String, modifier: StatModifier) -> void:
	if modifiers.has(stat_name):
		modifiers[stat_name].erase(modifier)
		stat_changed.emit(stat_name, get_stat(stat_name))
