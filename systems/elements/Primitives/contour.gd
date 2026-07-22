@icon("res://assets/icons/SphereShape3D.svg")
extends Element
class_name Contour

@export var points : PackedVector2Array = []
@export var color : Color = Color.BLACK : 
	set(v):
		color = v
		draw_segmented_curve()
@export var width : float = 1.0 : 
	set(v):
		width = v
		draw_segmented_curve()

var line_segments : Array[Line2D] = []

func _setup() -> void:
	draw_segmented_curve()

func draw_segmented_curve() -> void:
	# Update amount of line segments
	while line_segments.size() * 4 > points.size():
		var i : int = line_segments.size() - 1
		line_segments[i].queue_free()
		line_segments.remove_at(i)
	while line_segments.size() * 4 < points.size():
		var new_line : Line2D = Line2D.new()
		new_line.width = width
		new_line.default_color = color
		new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line_segments.append(new_line)
		add_child(new_line)
	
	var i : int = 0
	for line in line_segments:
		line.width = width
		line.default_color = color
		line.points = bezier_to_polyline(points[i + 0], points[i + 1], points[i + 2], points[i + 3])
		i += 4


func bezier_to_polyline(a : Vector2, b : Vector2, c : Vector2, d : Vector2) -> Array[Vector2]:
	var pts : Array[Vector2] = [a]
	flatten_bezier_curve(a, b, c, d, 0.5, pts)
	return pts

func flatten_bezier_curve(a : Vector2, b : Vector2, c : Vector2, d : Vector2, tolerance : float, pts : Array[Vector2], depth : int = 0) -> void:
	# Break out of recursvie function
	if (depth > 24):
		pts.append(d)
		return
	
	# Calculate flattness to determine, if part of line is flat enough
	var u : Vector2 = Vector2( 3.0 * b.x - 2.0 * a.x - d.x, 3.0 * b.y - 2.0 * a.y - d.y )
	var v : Vector2 = Vector2( 3.0 * c.x - 2.0 * d.x - a.x, 3.0 * c.y - 2.0 * d.y - a.y )
	var err : Vector2 = Vector2( max(u.x * u.x, v.x * v.x), max(u.y * u.y, v.y * v.y), )
	var flat_enough : bool = (err.x + err.y) <= 16.0 * tolerance * tolerance
	
	if (flat_enough):
		pts.append(d)
		return
	
	var de_casteljau : Array[Array] = de_casteljau_split(a, b, c, d)
	var half1 : Array = de_casteljau[0]
	var half2 : Array = de_casteljau[1]
	flatten_bezier_curve(half1[0], half1[1], half1[2], half1[3], tolerance, pts, depth + 1)
	flatten_bezier_curve(half2[0], half2[1], half2[2], half2[3], tolerance, pts, depth + 1)

func de_casteljau_split(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Array[Array]:
	var p01 = p0.lerp(p1, 0.5)
	var p12 = p1.lerp(p2, 0.5)
	var p23 = p2.lerp(p3, 0.5)
	var p012 = p01.lerp(p12, 0.5)
	var p123 = p12.lerp(p23, 0.5)
	var p0123 = p012.lerp(p123, 0.5)
	
	return [
		[p0, p01, p012, p0123],   # first half
		[p0123, p123, p23, p3]    # second half
	]

func _process(_delta : float) -> void:
	draw_segmented_curve()
