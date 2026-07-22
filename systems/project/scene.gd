extends SubViewport
class_name Scene

var animation : Animation = null
var animation_player : AnimationPlayer = null
var main_camera : Camera2D = null
var json_data : Dictionary = {}
var from : int = 0
var length : int = 0

func _init(source : String):
	json_data = JSON.parse_string(source)
	
	# Create viewport & camera
	size = Project.resolution
	size_2d_override = Project.resolution
	size_2d_override_stretch = true
	
	main_camera = Camera2D.new()
	main_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(main_camera)
	
	# Load items from list
	for element in json_data.elements:
		_load_elements_to_scene(element, self)


func _ready():
	# Create animation
	animation = Animation.new()
	animation_player = AnimationPlayer.new()
	animation_player.root_node = get_path()
	add_child(animation_player)
	# animation_player.deterministic = true
	for animation_target in json_data.animation:
		add_anim_track(animation_target, json_data.animation[animation_target])
	
	animation_player.add_animation_library("", AnimationLibrary.new())
	animation_player.get_animation_library("").add_animation("main", animation)
	animation_player.play("main")
	animation_player.pause()
	seek(0)
	# animation_player.current_animation = "main"
	print("Animation loaded")
	

func _load_elements_to_scene(element : Dictionary, parent : Node) -> void:
	var classes : Array[Dictionary] = ProjectSettings.get_global_class_list()
	for c in classes:
		if c.class == element.type:
			# Add instance to tree
			var instance = load(c.path).new()
			if instance is Element:
				for data in element:
					if not data in ["children", "type", "components", "name"] and data in instance:
						set_instance_data(instance, data, element[data])
					
					elif data == "components":
						for comp in element[data]:
							for c2 in classes:
								# print(c2.class)
								if c2.class == comp.type:
									var component = load(c2.path).new()
									if component is Component:
										for comp_data in comp:
											set_instance_data(component, comp_data, comp[comp_data])
										instance.components.append(component)
										component.name = comp.type
										instance.add_child(component)
					
					elif data == "name":
						instance.name = element.name
				
				parent.add_child(instance)
				if instance.has_method("_setup"):
					instance._setup()
				
				# Add children to scene
				var children : Array = element.children
				for child in children:
					_load_elements_to_scene(child as Dictionary, instance)
			else:
				printerr("Class for given type " + c.class + " is not a sub-type of Element.")
			return
	
	printerr("Failed to find class matching the given element type : " + str(element.type))


func set_instance_data(instance : Object, tag : String, value : Variant) -> void:
	if instance.get(tag) is Vector2:
		instance.set(tag, Vector2(value[0], value[1]))
	elif instance.get(tag) is Vector3:
		instance.set(tag, Vector3(value[0], value[1], value[2]))
	elif instance.get(tag) is Color:
		instance.set(tag, Color.from_string(str(value), Color.DEEP_PINK))
	elif instance.get(tag) is PackedVector2Array:
		var data : PackedVector2Array = PackedVector2Array([])
		for v in value:
			data.append(Vector2(v[0], v[1]))
		instance.set(tag, data)
	else:
		instance.set(tag, value)


func add_anim_track(target : String, data : Array) -> void:
	# var path : String = target.substr(0, target.find("."))
	# var component : String = ""  if not target.contains("::")  else target.get_slice("::", 1).get_slice(":", 0)
	# var property : String = target.substr(target.rfind("::"), -1)  if component != "" else  target.substr(target.rfind(":"), -1)
	
	var track_id : int = animation.add_track(Animation.TYPE_VALUE)
	var node_path : NodePath = str(animation_player.root_node) + "/" + str(NodePath(target.replace("::", "/").replace(".", "/")))
	animation.track_set_path(track_id, node_path)
	for key in data:
		var t : int = key.t
		var v : Variant = key.v
		if v is Array:
			if v.size() > 0:
				if v[0] is Array:
					if v[0].size() == 2:
						var arr : PackedVector2Array = PackedVector2Array([])
						for value in v:
							arr.append(Vector2(value[0], value[1]))
						v = arr as PackedVector2Array
			elif v.size() == 2:
				v = Vector2(v[0], v[1])
			elif v.size() == 3:
				v = Vector3(v[0], v[1], v[2])
			elif v.size() == 4:
				v = Vector4(v[0], v[1], v[2], v[3])
		elif v is String:
			if v.begins_with("#"):
				v = Color.from_string(v, Color.DEEP_PINK)
		animation.track_insert_key(track_id, t, v)
		animation.length = max(animation.length, t)
		length = animation.length

func seek(t : int) -> void:
	var clamped_time : int = clampi(t, 0, int(animation.length - 1))
	animation_player.current_animation = "main"
	animation_player.seek(float(clamped_time))
	animation_player.pause()
	Project.animation_time = clamped_time
	Project.emit_signal('animation_time_changed', clamped_time)


func has_animation_track(path : NodePath) -> bool:
	for track_id in animation.get_track_count():
		var p : NodePath = animation.track_get_path(track_id)
		if path == p:
			return true
	return false

func add_animated_track(path : NodePath) -> void:
	var track_id : int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_id, path)

func get_animation_track_id(host : Node, prop : String) -> int:
	for track_id in animation.get_track_count():
		var track_node_path : NodePath = animation.track_get_path(track_id)
		var prop_name : String = track_node_path.get_concatenated_subnames()
		
		var anim_root : Node = get_node_or_null(animation_player.root_node)
		if anim_root == null:
			print("Failed to update inspector based on property animation status update : Animation root node is null")
			break
		var track_node : Node = anim_root.get_node_or_null(track_node_path)
		if track_node != null and track_node == host and (prop_name == prop or prop_name.begins_with(prop + ":")):
			return track_id
	
	return -1

func add_animation_keyframe(track_id : int, time : int, value : Variant) -> void:
	animation.track_insert_key(track_id, time, value)
	animation.length = max(animation.length, time)
	length = animation.length


func save(path : String) -> void:
	# Collect save data as Dictionary
	var save_file : Dictionary = {
		"elements": [],
		"animation": {}
	}
	
	# > Save Scene Tree
	for child in get_children():
		if child is Element:
			save_element_data_recursive(save_file["elements"], child)
	
	# > Save Animation
	for track_id in animation.get_track_count():
		var node_path : NodePath = animation.track_get_path(track_id)
		var shortened_path : String = str(node_path).replace(str(get_path()) + "/", "")
		var target : Node = get_node_or_null(node_path)
		if target == null:
			print("Failed to save animation track for path " + str(node_path) + " : Target Node is null.")
			continue
		if target is Component:
			var last_delim_position : int = shortened_path.rfind("/")
			shortened_path = shortened_path.erase(last_delim_position, 1).insert(last_delim_position, "::")
		
		var keyframes : Array[Dictionary] = []
		for key_id in animation.track_get_key_count(track_id):
			var key_time : float = animation.track_get_key_time(track_id, key_id)
			var key_value : Variant = animation.track_get_key_value(track_id, key_id)
			var keyframe_data : Dictionary = {
				"t": key_time
			}
			store_json_data(keyframe_data, "v", key_value)
			keyframes.append(keyframe_data)
		save_file["animation"][shortened_path] = keyframes
	
	# Save file at path
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_file, "\t", false))
	file.close()
	
	print("Scene saved.")

func save_element_data_recursive(data_array : Array, element : Element) -> void:
	# Create base data Dictionary
	var data : Dictionary = {
		"type": element.get_script().get_global_name(),
		"name": element.name,
		"children": [],
		"components": [],
	}
	data_array.append(data)
	
	# Collect Element data
	var properties : Array = element.get_script().get_script_property_list()
	for prop in properties: 
		if not Project.is_valid_inspector_prop(prop): continue
		var value : Variant = element.get(prop.name)
		store_json_data(data, prop.name, value)
	
	# Collect Children's and Component Data
	for child in element.get_children():
		if child is Element:
			save_element_data_recursive(data["children"], child)
		elif child is Component:
			var component_data : Dictionary = {
				"type": child.get_script().get_global_name()
			}
			var comp_properties : Array = child.get_script().get_script_property_list()
			for comp_prop in comp_properties:
				if not Project.is_valid_inspector_prop(comp_prop): continue
				if comp_prop.name == "name": continue
				var value : Variant = child.get(comp_prop.name)
				store_json_data(component_data, comp_prop.name, value)
			data.components.append(component_data)

func store_json_data(data : Dictionary, tag : String, value : Variant) -> void:
	# TODO : Add proper Array support here
	if value is Vector2:
		data[tag] = [value.x, value.y]
	elif value is Vector3:
		data[tag] = [value.x, value.y, value.z]
	elif value is Vector4:
		data[tag] = [value.x, value.y, value.z, value.w]
	elif value is Color:
		data[tag] = "#" + value.to_html()
	elif value is PackedVector2Array:
		var array_data : Array[Array] = []
		for v in value:
			array_data.append([v.x, v.y])
		data[tag] = array_data
	else:
		data[tag] = value


# ===== ELEMENT CONTROL =====

func delete_scene_object(element : Node) -> void:
	# Remove targets childrens tracks
	for child in element.get_children():
		if child is Component or child is Element:
			delete_scene_object(child)
	
	# Remove every track from timeline
	var track_remove_queue : Array[int] = []
	for track_id in Project.active_scene.animation.get_track_count():
		var track_path : String = Project.active_scene.animation.track_get_path(track_id).get_concatenated_names()
		if track_path == str(element.get_path()) or "/" + track_path == str(element.get_path()):
			print("Track deleted at " + track_path)
			track_remove_queue.append(track_id)
	
	track_remove_queue.reverse()
	for track_id in track_remove_queue:
		Project.active_scene.animation.remove_track(track_id)
	
	# Delete element
	element.get_parent().remove_child(element)
	element.queue_free()
	
	Project.emit_signal("animation_state_updated", Project.active_scene.animation)
	
	# Clear Inspector
	Project.emit_signal("element_selected", null)

func rename_element(element : Element, new_name : String) -> void:
	var old_element_path : String = element.get_path()
	var new_element_path : String = old_element_path.substr(0, old_element_path.rfind("/")) + "/" + new_name
	
	# > Update track paths
	for track_id in Project.active_scene.animation.get_track_count():
		var track_path : String = "/" + Project.active_scene.animation.track_get_path(track_id).get_concatenated_names()
		var property_suffix : String = ":" + Project.active_scene.animation.track_get_path(track_id).get_concatenated_subnames()
		if track_path.begins_with(old_element_path):
			track_path = track_path.replace(old_element_path, new_element_path) + property_suffix
			Project.active_scene.animation.track_set_path(track_id, track_path)
	
	element.name = new_name
