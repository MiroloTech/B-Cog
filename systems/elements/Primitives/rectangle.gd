@icon("res://assets/icons/RectangleShape2D.svg")
extends Element
class_name Rectangle

@export var center : Vector2 = Vector2(0.0, 0.0)
@export var size : Vector2 = Vector2(50.0, 50.0)
@export var color : Color = Color.AQUA

var rect : ColorRect = null

func _setup() -> void:
	rect = ColorRect.new()
	add_child(rect)

func _process(_delta : float) -> void:
	if rect == null:
		return
	
	rect.position = center - size * 0.5
	rect.size = size
	rect.color = color
