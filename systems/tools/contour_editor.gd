@icon("res://assets/icons/CurveEdit.svg")
extends Tool
class_name ContourEditor

var dragging_point_idx : int = -1
var dragging_segment_idx : int = -1
var focused_point_idx : int = -1
var focused_segment_idx : int = -1
const DRAG_DIST : float = 5.0

func get_dependencies() -> Array[String]:
	return ["Contour"]

func _draw() -> void:
	if element is Contour:
		var segments : Array[Array] = element.segment_points
		var sid : int = 0
		for segment in segments:
			if sid == focused_segment_idx:
				draw_polyline(scene2world_arr(segment), Color.ORANGE_RED, 1.0)
			else:
				draw_polyline(scene2world_arr(segment), Color.ORANGE, 1.0)
			
			var i : int = 0
			for point in segment:
				if i == focused_point_idx and sid == focused_segment_idx:
					draw_circle(scene2world(point), 7.0, Color.RED)
					draw_circle(scene2world(point), 5.0, Color.YELLOW)
				else:
					draw_circle(scene2world(point), 5.0, Color.YELLOW)
				i += 1
			sid += 1

func _input(event : InputEvent) -> void:
	if element is not Contour:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				focused_point_idx = -1
				focused_segment_idx = -1
				var sid : int = 0
				for segment in element.segment_points:
					var i : int = 0
					for p in segment:
						var dist : float = world2scene(get_global_mouse_position()).distance_squared_to(p)
						if dist <= DRAG_DIST * DRAG_DIST:
							dragging_segment_idx = sid
							dragging_point_idx = i
							focused_segment_idx = sid
							focused_point_idx = i
						i += 1
					sid += 1
			else:
				dragging_point_idx = -1
	
	if event is InputEventMouseMotion and dragging_point_idx > -1:
		element.segment_points[dragging_segment_idx][dragging_point_idx] = world2scene(get_global_mouse_position())
		element.draw_segmented_curve()
