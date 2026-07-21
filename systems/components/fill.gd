@icon('res://assets/icons/Bucket.svg')
extends Component
class_name Fill

@export var color : Color = Color.BLACK

func _get_valid_elements() -> Array[String]:
	return [
		"Contour"
	]
