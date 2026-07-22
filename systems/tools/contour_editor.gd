@icon("res://assets/icons/CurveEdit.svg")
extends Tool
class_name ContourEditor

var dragging_point_idx : int = -1
var focused_point_idx : int = -1
const DRAG_DIST : float = 5.0

func get_dependencies() -> Array[String]:
	return ["Contour"]

func _draw() -> void:
	if element is Contour:
		var i : int = 0
		for _i in (element.points.size() / 4):
			var a : Vector2 = element.points[i + 0]
			var b : Vector2 = element.points[i + 1]
			var c : Vector2 = element.points[i + 2]
			var d : Vector2 = element.points[i + 3]
			
			# Draw Arms
			draw_line(scene2world(a), scene2world(b), Color.CORAL, 1.0, true)
			draw_line(scene2world(c), scene2world(d), Color.CORAL, 1.0, true)
			
			# Draw Points
			draw_circle(scene2world(a), DRAG_DIST * 0.5, Color.GREEN_YELLOW, true, -1, true)
			draw_circle(scene2world(b), DRAG_DIST * 0.5, Color.GREEN_YELLOW, true, -1, true)
			draw_circle(scene2world(c), DRAG_DIST * 0.5, Color.GREEN_YELLOW, true, -1, true)
			draw_circle(scene2world(d), DRAG_DIST * 0.5, Color.GREEN_YELLOW, true, -1, true)
			
			i += 4

func _input(event : InputEvent) -> void:
	if element is not Contour:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				focused_point_idx = -1
				for i in element.points.size():
					var p : Vector2 = element.points[i]
					var dist : float = world2scene(get_global_mouse_position()).distance_squared_to(p)
					if dist <= DRAG_DIST * DRAG_DIST:
						dragging_point_idx = i
						focused_point_idx = i
			else:
				dragging_point_idx = -1
	
	if event is InputEventMouseMotion and dragging_point_idx > -1:
		element.points[dragging_point_idx] = world2scene(get_global_mouse_position())
		element.draw_segmented_curve()
