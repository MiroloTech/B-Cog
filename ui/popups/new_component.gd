extends Window

@onready var search_bar : LineEdit = $Panel/MarginContainer/Content/Search
@onready var component_container : VBoxContainer = $Panel/MarginContainer/Content/ScrollContainer/List

const DEFAULT_ICON : Texture = preload('res://assets/icons/MissingResource.svg')

var element : Element = null

func _ready():
	var components : Array[Dictionary] = _get_all_valid_components()
	fill_list_with_components(components)


## Adds a filter fo the search bar, which excludes all components, that are not compatible with the parent element
func add_filter_element(element_tag : String) -> void:
	search_bar.text = "#" + element_tag + " " + search_bar.text
	search_bar.grab_focus()
	search_bar.caret_column = search_bar.text.length()


func _get_all_valid_components() -> Array[Dictionary]:
	if element == null:
		return []
	
	var valid_components : Array[Dictionary] = []
	var element_class : String = element.get_script().get_global_name()
	
	var classes : Array[Dictionary] = ProjectSettings.get_global_class_list()
	for c in classes:
		if c.base == "Component":
			var component : Component = load(c.path).new()
			var valid_element_classed : Array[String] = component._get_valid_elements()
			if element_class in valid_element_classed:
				valid_components.append(c)
	
	for child in Project.selected_element.get_children():
		if child is Component:
			for component in valid_components:
				if child.get_script().get_global_name() == component.class:
					valid_components.erase(component)
	
	return valid_components

func fill_list_with_components(list : Array[Dictionary]) -> void:
	# Remove old elements
	for child in component_container.get_children():
		child.queue_free()
	
	# Add element's Icon and Name as button
	for component in list:
		var btn : Button = Button.new()
		btn.text = component.class
		if component.icon == "":
			btn.icon = DEFAULT_ICON
		else:
			btn.icon = load(component.icon)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.flat = true
		btn.expand_icon = true
		btn.custom_minimum_size.y = 24.0
		btn.pressed.connect(on_add_component_pressed.bind(component))
		component_container.add_child(btn)

func on_add_component_pressed(component_data : Dictionary) -> void:
	if Project.selected_element != null:
		var component : Component = load(component_data.path).new()
		component.name = component_data.class
		Project.selected_element.add_child(component)
		Project.selected_element.components.append(component)
		
		Project.emit_signal("element_selected", Project.selected_element)
		emit_signal("close_requested")
		call_deferred("queue_free")
