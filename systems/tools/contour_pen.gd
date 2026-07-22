@icon("res://assets/icons/CurveCreate.svg")
extends Tool
class_name ContourPen

var dragging : bool = false
var first_half : bool = true
# var from_last_point : bool = false
# var last_point : Vector2 = Vector2.ZERO
var segment_id : int = -1

func get_dependencies() -> Array[String]:
	return ["Contour"]

func _ready() -> void:
	segment_id = -1
	dragging = false
	first_half = true

func _draw() -> void:
	# Draw active segment
	if segment_id == -1:
		return
	
	if element is Contour:
		var a : Vector2 = element.points[segment_id + 0]
		var b : Vector2 = element.points[segment_id + 1]
		var c : Vector2 = element.points[segment_id + 2]
		var d : Vector2 = element.points[segment_id + 3]
		
		# Draw Arms
		draw_line(scene2world(a), scene2world(b), Color.CORAL, 1.0, true)
		draw_line(scene2world(c), scene2world(d), Color.CORAL, 1.0, true)
		
		# Draw Points
		draw_circle(scene2world(a), 4.0, Color.GREEN_YELLOW, true, -1, true)
		draw_circle(scene2world(b), 4.0, Color.GREEN_YELLOW, true, -1, true)
		draw_circle(scene2world(c), 4.0, Color.GREEN_YELLOW, true, -1, true)
		draw_circle(scene2world(d), 4.0, Color.GREEN_YELLOW, true, -1, true)

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		var point : Vector2 = world2scene(event.global_position)
		
		# Set Starting point (Point a)
		if event.pressed and event.button_index == 1 and not dragging and first_half:
			segment_id = element.points.size()
			first_half = true
			dragging = true
			element.points.append_array([point, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		
		# Set first arm point
		if not event.pressed and event.button_index == 1 and dragging and first_half:
			first_half = false
			dragging = false
		
		
		# Set finishing point
		if event.pressed and event.button_index == 1 and not dragging and not first_half:
			element.points[segment_id + 3] = point
			dragging = true
		
		# Set second arm point
		if not event.pressed and event.button_index == 1 and dragging and not first_half:
			first_half = true
			dragging = false
	
	if event is InputEventMouseMotion:
		var point : Vector2 = world2scene(event.global_position)
		
		# Set first arm point
		if dragging and first_half:
			element.points[segment_id + 1] = point
			element.points[segment_id + 2] = point
			element.points[segment_id + 3] = point
		
		# Preview final point
		if not dragging and not first_half:
			element.points[segment_id + 2] = point
			element.points[segment_id + 3] = point
		
		# Set second arm point
		if dragging and not first_half:
			element.points[segment_id + 2] = point
