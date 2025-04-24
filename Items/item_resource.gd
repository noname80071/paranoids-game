class_name ItemResource
extends Resource

@export var id: String                    # Уникальный ID
@export var name: String                  # Название
@export var description: String
@export var price: int
@export var texture: PackedScene          # Иконка
@export var model: PackedScene            # Модель
@export var grid_cells: Array[Vector2i]   # Размер
@export var item_type: String             # Тип 
@export var effects: Array[ItemEffect]    # Массив эффектов


# Автоматически вычисляемые размеры
var width: int:
	get:
		var min_x = 0
		var max_x = 0
		for cell in grid_cells:
			min_x = min(min_x, cell.x)
			max_x = max(max_x, cell.x)
		return max_x - min_x + 1

var height: int:
	get:
		var min_y = 0
		var max_y = 0
		for cell in grid_cells:
			min_y = min(min_y, cell.y)
			max_y = max(max_y, cell.y)
		return max_y - min_y + 1
