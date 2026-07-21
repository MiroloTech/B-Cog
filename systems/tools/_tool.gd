extends Node2D
class_name Tool

var element : Element = null

func world2scene(world : Vector2) -> Vector2:
	return (world - Project.viewport_rect.position) / Project.viewport_rect.size * Vector2(Project.resolution) - Vector2(Project.resolution) * 0.5

func scene2world(scene : Vector2) -> Vector2:
	return (scene + Project.resolution * 0.5) / Vector2(Project.resolution) * Project.viewport_rect.size + Project.viewport_rect.position

func world2scene_arr(world : Array) -> Array[Vector2]:
	var arr : Array[Vector2] = []
	for p in world:
		arr.append(world2scene(p))
	return arr

func scene2world_arr(world : Array) -> Array[Vector2]:
	var arr : Array[Vector2] = []
	for p in world:
		arr.append(scene2world(p))
	return arr

func get_dependencies() -> Array[String]:
	return []
