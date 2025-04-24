extends PassiveEffect
class_name MoveSpeed

func _init():
	amount = 3.0
	name = "Move Speed"
	stat_name = "speed"
	mod_type = StatModifier.MOD_TYPE.FLAT
	source_name = "Move speed item"
