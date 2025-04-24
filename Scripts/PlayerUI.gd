extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HPBar
@onready var balance_label: Label = $Control/Balance
@onready var crosshair = $Control/Crosshair

func _ready() -> void:
	randomize()
	crosshair.position.x = get_viewport().size.x / 2 - 32
	crosshair.position.y = get_viewport().size.y / 2 - 32

func update_health(current: float, max_hp: float):
	health_bar.max_value = max_hp
	health_bar.value = current
	
	# Визуальные эффекты при повреждении через стили
	var style_box = health_bar.get_theme_stylebox("fill").duplicate()
	
	if current < max_hp * 0.3:
		style_box.bg_color = Color.RED
	else:
		style_box.bg_color = Color.GREEN
	
	health_bar.add_theme_stylebox_override("fill", style_box)

func update_balance(amount: int):
	var old_balance = int(balance_label.text)
	balance_label.text = str(old_balance + amount)
