class_name StatModifier extends RefCounted

enum MOD_TYPE {
	FLAT = 0,        # Простое добавление (+10)
	PERCENT_ADD = 1,  # Процент от базового значения (+10%)
	PERCENT_MULT = 2  # Процентное умножение (x1.1)
}

var amount: float
var type: MOD_TYPE
var source: String

func _init(p_amount: float, p_type: MOD_TYPE = MOD_TYPE.FLAT, p_source: String = ""):
	amount = p_amount
	type = p_type
	source = p_source
