extends Control

@onready var viewport_rect : SubViewportContainer = $ViewportContainer
@onready var tool_list : HBoxContainer = $ToolMargin/ToolContainer
@onready var tool_container : Node2D = $ToolContainer

var panning : bool = false
var zoom : float = 0.5

func _enter_tree():
	Project.element_selected.connect(update_tool_list)
	Project.scene_opened.connect(_on_scene_opened)

func _on_scene_opened(scene : Scene) -> void:
	# Remove old scene
	for child in viewport_rect.get_children():
		viewport_rect.remove_child(scene)
	
	# Add new scene
	viewport_rect.add_child(scene)

func _ready():
	viewport_rect.size = Project.resolution

func _input(event):
	if event is InputEventMouseMotion:
		if not get_global_rect().has_point(event.position):
			panning = false
			# TODO : Wrap cursor around viewport edges here
			return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
		
		if get_global_rect().has_point(get_global_mouse_position()):
			var local_mpos : Vector2 = (get_global_mouse_position() - viewport_rect.global_position) * viewport_rect.scale
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				viewport_rect.position += local_mpos * (Vector2.ONE - viewport_rect.scale) * 0.5
				zoom *= 0.9
				viewport_rect.scale = Vector2(zoom, zoom)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				viewport_rect.position -= local_mpos * (Vector2.ONE - viewport_rect.scale) * 0.5
				zoom /= 0.9
				viewport_rect.scale = Vector2(zoom, zoom)
	
	elif event is InputEventMouseMotion:
		if panning:
			viewport_rect.position += event.relative

func _process(_delta : float) -> void:
	Project.viewport_rect = Rect2(viewport_rect.global_position, viewport_rect.size * viewport_rect.scale)
	
	for tool_child in tool_container.get_children():
		if tool_child is Tool:
			tool_child.queue_redraw()
		else:
			tool_container.remove_child(tool_child)
			tool_child.queue_free()


func update_tool_list(new_element : Element) -> void:
	for item in tool_list.get_children():
		item.queue_free()
	
	for tool_class_data in ProjectSettings.get_global_class_list():
		if tool_class_data.base == "Tool":
			var tool : Tool = load(tool_class_data.path).new()
			if new_element == null:
				break
			
			var element_name : String = new_element.get_script().get_global_name()
			if not tool.get_dependencies().has(element_name):
				continue
			
			var icon : Texture = load(tool_class_data.icon)
			var btn : TextureButton = TextureButton.new()
			btn.custom_minimum_size = Vector2(24.0, 24.0)
			btn.texture_normal = icon
			btn.ignore_texture_size = true
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			# btn.flat = true
			tool_list.add_child(btn)
			
			tool.element = new_element
			btn.pressed.connect(tool_clicked.bind(tool))
	
	tool_clicked(null)

func tool_clicked(tool : Tool) -> void:
	for child in tool_container.get_children():
		tool_container.remove_child(child)
		child.queue_free()
	
	if tool != null:
		tool_container.add_child(tool)
