extends PassiveEffect
class_name MaxHP

func _init():
	amount = 20
	name = "Max HP"
	stat_name = "max_hp"
	mod_type = StatModifier.MOD_TYPE.PERCENT_ADD
	source_name = "Health Item"
