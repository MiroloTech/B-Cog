@icon("res://assets/icons/DampedSpringJoint2D.svg")
extends Component
class_name Scribble

@export var octaves : int = 4
@export var lacunarity : float = 0.8
@export var freq : float = 20.0
@export var power : float = 5.0
@export var width_power : float = 0.2
@export var textured_stroke : bool = true

func _get_valid_elements() -> Array[String]:
	return [
		"Contour"
	]
