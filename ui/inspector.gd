extends Panel

@export var animated_color : Color = Color.PINK

@onready var controller_container : VBoxContainer = $MarginContainer/Controllers
@onready var popup_manager : Control = %PopupManager

var target : Element = null
var add_component_popup : Window = null

func _ready():
	Project.scene_opened.connect(clear_inspector)
	Project.element_selected.connect(reload_inspector)
	Project.animation_time_changed.connect(_on_timeline_dragged)
	popup_manager.popup_closed.connect(on_popup_closed)


# ===== CONSTRUCTORS =====

func clear_inspector() -> void:
	for child in controller_container.get_children():
		child.queue_free()
	
	target = null

func reload_inspector(new_target : Element) -> void:
	clear_inspector()
	target = new_target
	if add_component_popup != null:
		popup_manager.close_popup(add_component_popup)
		add_component_popup = null
	
	if target == null:
		return
	
	add_inspector_title_bar(new_target.name)
	
	for property in target.get_property_list():
		if not Project.is_valid_inspector_prop(property): continue
		
		var value : Variant = target.get(property.name)
		add_inspector_controller(value, property, target)
	
	for component in target.components:
		var component_name : String = component.get_script().get_global_name()
		add_inspector_title_bar(component_name)
		
		for property in component.get_property_list():
			if not Project.is_valid_inspector_prop(property): continue
			
			var value : Variant = component.get(property.name)
			add_inspector_controller(value, property, component)
	
	# Add component-spacer
	var add_spacer : Control = Control.new()
	add_spacer.custom_minimum_size.y = 14
	add_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controller_container.add_child(add_spacer)
	
	# Add add-component button
	var add_component_btn : Button = Button.new()
	add_component_btn.text = "Add Component"
	add_component_btn.custom_minimum_size.y = 28
	add_component_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_component_btn.modulate.a = 0.7
	add_component_btn.pressed.connect(on_add_component_pressed)
	controller_container.add_child(add_component_btn)

func add_inspector_title_bar(text : String) -> void:
	var panel : Panel = Panel.new()
	panel.custom_minimum_size.y = 28.0
	panel.theme_type_variation = "PanelBright"
	
	var title : Label = Label.new()
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = text
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	controller_container.add_child(panel)
	panel.add_child(title)


func add_inspector_controller(value : Variant, property_data : Dictionary, host : Object) -> void:
	var title_split : HBoxContainer = HBoxContainer.new()
	title_split.custom_minimum_size.y = 28.0
	
	var title : Button = Button.new()
	title.flat = true
	# title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.text = property_data.name
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if is_property_animated(host, property_data.name):
		title.modulate = animated_color
	title.pressed.connect(on_keyframe_add_clicked.bind(property_data.name, host))
	
	var controller : Control = null
	match property_data.type:
		3: # float
			controller = SpinBox.new()
			controller.min_value = -2147483648
			controller.max_value = 2147483647
			controller.value = value
			controller.value_changed.connect(on_value_changed.bind(property_data.name, host))
		5: # Vector2
			controller = HBoxContainer.new()
			var spinx : SpinBox = SpinBox.new()
			var spiny : SpinBox = SpinBox.new()
			spinx.min_value = -2147483648
			spiny.min_value = -2147483648
			spinx.max_value = 2147483647
			spiny.max_value = 2147483647
			spinx.value = value.x
			spiny.value = value.y
			controller.add_child(spinx)
			controller.add_child(spiny)
			spinx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spiny.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spinx.value_changed.connect(func(_x): on_value_changed(Vector2(spinx.value, spiny.value), property_data.name, host))
			spiny.value_changed.connect(func(_y): on_value_changed(Vector2(spinx.value, spiny.value), property_data.name, host))
		20: # Color
			controller = ColorPickerButton.new()
			controller.color = value
			controller.color_changed.connect(on_value_changed.bind(property_data.name, host))
		_:
			controller = Control.new()
	
	controller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	controller_container.add_child(title_split)
	title_split.add_child(title)
	title_split.add_child(controller)


# ===== REACTORS =====

func on_value_changed(value : Variant, attr_name : String, source : Object) -> void:
	if source != null:
		source.set(attr_name, value)
	else:
		printerr("Failed to set attribute " + attr_name + " for source of type null.")

func on_keyframe_add_clicked(property : String, source : Node) -> void:
	# var host_path : String = str(source.get_path()) if component == "" else str(target.get_path()) + "/" + str(target.get_path())
	var property_path : NodePath = NodePath(str(source.get_path()) + ":" + property)
	if not Project.active_scene.has_animation_track(property_path):
		Project.active_scene.add_animated_track(property_path)
		print("Track added for " + str(property_path))
	
	var track_id : int = Project.active_scene.get_animation_track_id(source, property)
	if track_id == -1:
		print("Failed to fetch track id for adding a new keyframe to : " + property)
		return
	var value : Variant = source.get_indexed(NodePath(property_path.get_concatenated_subnames()))
	Project.active_scene.add_animation_keyframe(track_id, Project.animation_time, value)
	Project.emit_signal('animation_state_updated', Project.active_scene.animation)

func on_add_component_pressed() -> void:
	if add_component_popup != null:
		return
	
	add_component_popup = preload("res://ui/popups/new_component.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	add_component_popup.element = target
	popup_manager.open_popup(add_component_popup)
	add_component_popup.add_filter_element(target.get_script().get_global_name())

func on_popup_closed(popup : Window) -> void:
	if popup == add_component_popup:
		add_component_popup = null

# ===== UTIL =====

func is_property_animated(host : Object, prop : String) -> bool:
	var animation : Animation = Project.active_scene.animation
	for track_id in animation.get_track_count():
		var track_node_path : NodePath = animation.track_get_path(track_id)
		var prop_name : String = track_node_path.get_concatenated_subnames()
		
		var anim_root : Node = get_node_or_null(Project.active_scene.animation_player.root_node)
		if anim_root == null:
			print("Failed to update inspector based on property animation status update : Animation root node is null")
			break
		var track_node : Node = anim_root.get_node_or_null(track_node_path)
		if track_node != null and track_node == host and (prop_name == prop or prop_name.begins_with(prop + ":")):
			return true
	
	return false



func _on_timeline_dragged(_time : int) -> void:
	for track_id in Project.active_scene.animation.get_track_count():
		var track_node_path : NodePath = Project.active_scene.animation.track_get_path(track_id)
		var anim_root : Node = get_node_or_null(Project.active_scene.animation_player.root_node)
		if anim_root == null:
			print("Failed to update inspector based on animation time update : Animation root node is null")
			break
		var track_node : Node = anim_root.get_node_or_null(track_node_path)
		if track_node == target and track_node != null:
			reload_inspector(target)
			break
