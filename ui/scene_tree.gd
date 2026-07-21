extends Panel

@onready var tree : Tree = $Content/Tree
@onready var popup_manager : Control = %PopupManager

var selected_element : Element = null
var click_pos : Vector2 = Vector2(-1, -1)
var dragging : bool = false

func _ready() -> void:
	Project.scene_opened.connect(reload_tree)
	Project.scene_tree_changed.connect(reload_tree)

func _process(_delta : float) -> void:
	var mpos : Vector2 = get_global_mouse_position() - tree.global_position
	if Input.is_action_pressed('dragging') and click_pos != Vector2(-1, -1):
		if click_pos.distance_to(mpos) > 10.0:
			dragging = true
			tree.drop_mode_flags = Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN
	
	if Input.is_action_just_released("dragging") and dragging:
		var dragging_tree_item : TreeItem = tree.get_selected()
		var target_tree_item : TreeItem = tree.get_item_at_position(mpos)
		var dragging_node : Node = get_node_from_item(dragging_tree_item)
		var target_node : Node = get_node_from_item(target_tree_item)
		var drop_dir : int = tree.get_drop_section_at_position(mpos)
		var old_dragging_path : NodePath = dragging_node.get_path()
		
		# Take care of unhadleable scenarios
		if dragging_node == null or target_node == null:
			return
		if dragging_node == target_node:
			return
		# Prevent dropping a node into its own subtree (would create a cycle)
		if dragging_node.is_ancestor_of(target_node):
			push_error("Failed to element node in Scene Tree : Cannot reparent a node into its own descendant.")
			return
		
		# Reparent node if drop has no direction
		if drop_dir == 0 or drop_dir == 2:
			dragging_node.reparent(target_node)
			if drop_dir == 0:
				target_node.move_child(dragging_node, -1)
			else:
				target_node.move_child(dragging_node, 0)
		elif drop_dir == 1 or drop_dir == -1:
			dragging_node.reparent(target_node.get_parent())
			# var target_index : int = max(0, target_node.get_index() + min(0, drop_dir))
			var target_index : int = target_node.get_index() + min(0, drop_dir)
			if target_node.get_index() < dragging_node.get_index():
				target_index += 1
			target_index = max(0, target_index)
			target_node.get_parent().move_child(dragging_node, target_index)
		
		# Update tree
		Project.emit_signal("scene_tree_changed", Project.active_scene)
		
		# Update effected animation
		var new_dragging_path : NodePath = dragging_node.get_path()
		for track_id in Project.active_scene.animation.get_track_count():
			var old_track_path : NodePath = Project.active_scene.animation.track_get_path(track_id)
			if str(old_track_path).begins_with(str(old_dragging_path)):
				var new_path : NodePath = NodePath( str(old_track_path).replace(old_dragging_path, str(new_dragging_path)) )
				Project.active_scene.animation.track_set_path(track_id, new_path)
	
	# Reset tree state
	if Input.is_action_just_released('dragging'):
		dragging = false
		click_pos = Vector2(-1, -1)
		tree.drop_mode_flags = Tree.DROP_MODE_DISABLED


func _assign_owner_recursive(node : Node, scene_owner : Node) -> void:
	if node != scene_owner:
		node.owner = scene_owner
	for child in node.get_children():
		_assign_owner_recursive(child, scene_owner)


func reload_tree(scene : Scene) -> void:
	# Clear old elements
	tree.deselect_all()
	tree.clear()
	
	# Create items recursively
	var root_item : TreeItem = tree.create_item(null)
	root_item.set_text(0, scene.name)
	# root_item.set_editable(0, true)
	
	for element in scene.get_children():
		if element is Element:
			_create_item(element, root_item)

func _create_item(parent_element : Element, parent_item : TreeItem) -> void:
	var item : TreeItem = tree.create_item(parent_item)
	item.set_text(0, parent_element.name)
	item.set_editable(0, true)
	
	for element in parent_element.get_children():
		if element is Element:
			_create_item(element, item)

# ===== REACTORS =====

func _on_tree_item_selected():
	# Determine path to selected item
	var tree_item : TreeItem = tree.get_selected()
	if tree_item.get_parent() == null:
		# TODO : Show Scene-specific settings here (length, bg color, etc.)
		Project.emit_signal("element_selected", null)
		Project.selected_node = Project.active_scene
		return
	
	var parent : TreeItem = tree_item
	var path : String = ""
	while parent.get_parent() != null:
		path = parent.get_text(0) + "/" + path
		parent = parent.get_parent()
	
	# Get Element in scene based on Scene Tree
	var element : Element = Project.active_scene.get_node_or_null(path)
	if element == null:
		printerr("Path from Scene Tree doesn't exist in scene : " + path)
		return
	selected_element = element
	
	Project.emit_signal("element_selected", element)

func _on_tree_nothing_selected():
	selected_element = null


func _on_add_pressed():
	var add_element_popup : Window = preload("res://ui/popups/new_element.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	popup_manager.open_popup(add_element_popup)


func _on_rename_pressed():
	# Collect every sleected tree item
	var selected_item : TreeItem = tree.get_selected()
	if selected_item == null or selected_element == tree.get_root():
		return
	
	tree.edit_selected(true)


func _on_remove_pressed():
	# Collect every sleected tree item
	var selected_items : Array[TreeItem] = get_all_selected_items()
	if selected_items.size() == 0:
		printerr("Failed to delete element form Scene Tree : No element selected")
	
	# Extract the NodePath for every item in the scene
	for item in selected_items:
		var path : String = get_tree_item_path(item)
		if path.count("/") <= 1:
			printerr("Can't delete scene root (Scene) in Scene Tree. This can only be done in the Timeline")
			continue
		var node_path : NodePath = NodePath(str(Project.active_scene.get_path()) + "/" + path.substr(path.find("/"), -1))
		
		# > Delete from scene
		var element : Element = get_node_or_null(node_path)
		if element == null:
			printerr("Failed to delete element : Element at path " + str(node_path) + " is null.")
			continue
		
		Project.active_scene.delete_scene_object(element)
	
	# Reload scene tree
	Project.emit_signal("scene_tree_changed", Project.active_scene)


func _on_save_as_preset_pressed():
	pass # Replace with function body.


func _on_tree_item_edited():
	var editing_item : TreeItem = tree.get_selected()
	if editing_item.get_text(0) == "":
		editing_item.set_text(0, "unnamed")
	
	# TODO : Make sure, that two elements don't have the same name under the same parent
	
	var path : String = get_tree_item_path(editing_item)
	
	# > Rename scene
	if path.count("/") <= 1:
		Project.active_scene.name = editing_item.get_text(0)
		Project.emit_signal("animation_state_updated", Project.active_scene.animation)
		# TODO : Update EVERY Track path
	elif selected_element != null:
		Project.active_scene.rename_element(selected_element, editing_item.get_text(0))
		Project.emit_signal("animation_state_updated", Project.active_scene.animation)


func _on_tree_item_mouse_selected(mouse_position, mouse_button_index):
	if mouse_button_index == 1:
		click_pos = mouse_position
		var element : TreeItem = tree.get_item_at_position(mouse_position)
		if element == null:
			click_pos = Vector2(-1, -1)

# ===== UTILITY ====

func get_all_selected_items() -> Array[TreeItem]:
	# Collect every sleected tree item
	if tree.get_selected() == null:
		# printerr("Failed to delete element form Scene Tree : No element selected")
		return []
	
	var selected_items : Array[TreeItem] = [tree.get_selected()]
	while true:
		var next : TreeItem = tree.get_next_selected(selected_items[selected_items.size() - 1])
		if next == null:
			break
		selected_items.append(next)
		next.deselect(0)
	return selected_items

func get_tree_item_path(item : TreeItem) -> String:
	var path : String = ""
	var active_item : TreeItem = item
	while active_item != null:
		path = active_item.get_text(0) + "/" + path
		active_item = active_item.get_parent()
	return path

func get_node_from_item(item : TreeItem) -> Node:
	if item == tree.get_root():
		return Project.active_scene
	
	var scene_path : String = Project.active_scene.get_path()
	var local_path : String = get_tree_item_path(item)
	var path : String = scene_path + local_path.substr(local_path.find("/"), -1)
	return get_node_or_null(NodePath(path))
