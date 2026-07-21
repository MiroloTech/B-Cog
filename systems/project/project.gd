extends Node

signal scene_opened(scene : Scene)
signal scene_tree_changed(scene : Scene)
signal element_selected(element : Element)
signal animation_state_updated(animation : Animation)
signal animation_time_changed(time : int)

const INSPECTOR_VAR_BLACKLIST : Array[String] = ["script", "components"]

var animation_time : int = 0
var resolution : Vector2i = Vector2i(1920, 1080)

var active_scene : Scene = null
var all_scenes : Array[Scene] = [] # WARNING : This might be very RAM-heavy (maybe cache essential Scene data, that isn't from the active scene)
var viewport_rect : Rect2 = Rect2(0.0, 0.0, 1920.0, 1080.0)
var selected_element : Element = null
var selected_node : Node = null # > Mostly similar to selected_element, but points to the active scene, if the scene tree root is selected (only used in adding elements)

func _ready():
	element_selected.connect(on_element_selected)

func open_test_scene():
	# TEST : Load test scene
	# var scene_file : FileAccess = FileAccess.open("D:/DATA/Games/animator/test/test_scene.json", FileAccess.READ)
	var scene_file : FileAccess = FileAccess.open("D:/DATA/Games/animator/test/test_scene_save.json", FileAccess.READ)
	var scene_raw : String = scene_file.get_as_text()
	scene_file.close()
	
	var scene : Scene = Scene.new(scene_raw)
	open_scene(scene)
	print("Test Scene loaded!")

func open_scene(scene : Scene) -> void:
	if not scene in all_scenes:
		all_scenes.append(scene)
	
	self.active_scene = scene
	emit_signal("scene_opened", scene)
	emit_signal("animation_state_updated", scene.animation)

func save_active_scene(path : String) -> void:
	active_scene.save(path)


func on_element_selected(element : Element) -> void:
	selected_element = element
	selected_node = element

func is_valid_inspector_prop(prop : Dictionary) -> bool:
	if prop.type == 0: return false
	if prop.usage < 4096: return false
	if prop.name in INSPECTOR_VAR_BLACKLIST: return false
	if prop.usage & PROPERTY_USAGE_EDITOR != PROPERTY_USAGE_EDITOR: return false
	return true
