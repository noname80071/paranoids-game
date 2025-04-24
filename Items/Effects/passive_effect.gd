extends ItemEffect
class_name PassiveEffect

@export_range(1, 100) var amount
@export var name = ''
@export var stat_name = ''
@export var mod_type = StatModifier.MOD_TYPE.FLAT
@export var source_name: String = ""

var applied_modifier: StatModifier

func apply_effect(target: Node) -> void:
	if target.has_method('get_stats'):
		var stats: Stats = target.get_stats()
		applied_modifier = StatModifier.new(amount, mod_type, source_name)
		stats.add_modifier(stat_name, applied_modifier)

func remove_effect(target: Node) -> void:
	if target.has_method('get_stats') and applied_modifier:
		var stats: Stats = target.get_stats()
		stats.remove_modifier(stat_name, applied_modifier)
