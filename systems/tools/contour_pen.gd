@icon("res://assets/icons/CurveCreate.svg")
extends Tool
class_name ContourPen

var dragging : bool = false
var from_last_point : bool = false
var editing_points : Array[Vector2] = []
var a : Vector2 = Vector2.ZERO
var b : Vector2 = Vector2.ZERO
var c : Vector2 = Vector2.ZERO
var d : Vector2 = Vector2.ZERO

func get_dependencies() -> Array[String]:
	return ["Contour"]

func _ready():
	from_last_point = false
	editing_points.clear()

# TODO : Construct a Contour-drawing tool to FINALLY DRAW A CHICKEN

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 0:
			var point : Vector2 = world2scene(event.global_position)
			if not from_last_point:
				a = point
				dragging = true
				from_last_point = true
			else:
				c = point
				
		if not event.pressed and event.button_index == 0 and dragging:
			dragging = false
			var point : Vector2 = world2scene(event.global_position)
			b = point
