extends Window

@onready var tree : Tree = $Panel/MarginContainer/Content/ScrollContainer/Tree

const FOLDER_ICON : Texture2D = preload('res://assets/icons/Folder.svg')
const NO_ICON : Texture2D = preload('res://assets/icons/Object.svg')

var element_map : Dictionary[TreeItem, Element] = {}

func _ready():
	load_full_element_tree()

func load_full_element_tree() -> void:
	element_map = {}
	var root_item : TreeItem = create_tree_item_from_path("", null)
	load_element_dir("res://systems/elements/", root_item)

func load_element_dir(path : String, parent_tree_item : TreeItem) -> void:
	# Loop through every file / dir in the parent dir
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".uid") or file_name.begins_with("_"):
				file_name = dir.get_next()
				continue
			
			# Build new Tree Item
			var full_path : String = path.path_join(file_name)
			var new_tree_item : TreeItem = create_tree_item_from_path(full_path, parent_tree_item, dir.current_is_dir())
			
			# Recursively build tree from sub-directories
			if dir.current_is_dir():
				load_element_dir(full_path, new_tree_item)
			file_name = dir.get_next()
	else:
		printerr("Failed to open directory at path " + path + " to list elements in that directory")

func create_tree_item_from_path(path : String, parent : TreeItem, is_dir : bool = false) -> TreeItem:
	var tree_item : TreeItem = tree.create_item(parent)
	element_map[tree_item] = null
	tree_item.set_selectable(0, !is_dir)
	var item_name : String = path.replace("\\", "/").substr(path.rfind("/") + 1, path.length()).to_pascal_case()
	var item_icon : Texture2D = FOLDER_ICON if is_dir else NO_ICON
	
	# Fetch Element-specific data for the tree item if available
	if parent != null and not is_dir:
		var element_base : Resource = load(path)
		if element_base != null:
			var element : Element = element_base.new()
			element_map[tree_item] = element
			var script : Script = element.get_script()
			if script != null:
				item_name = script.get_global_name()
				if script.source_code.contains("@icon"):
					var icon_path = script.source_code.get_slice("\n", 0).replace("@icon(", "").replace(")", "").replace('"', '')
					item_icon = load(icon_path) as Texture2D
			else:
				printerr("Failed to load element in NewElement popup : script of element " + path + " is null.")
	
	# Edit tree item data
	tree_item.set_icon_max_width(0, 20)
	tree_item.set_icon(0, item_icon)
	tree_item.set_text(0, item_name)
	
	return tree_item


# ===== REACTORS =====

func _on_add_pressed():
	if tree.get_selected() == null or Project.selected_node == null:
		return
	
	var selected_element : Element = element_map[tree.get_selected()]
	Project.selected_node.add_child(selected_element)
	selected_element._setup()
	selected_element.name = selected_element.get_script().get_global_name()
	Project.emit_signal("scene_tree_changed", Project.active_scene)
	emit_signal("close_requested")
	call_deferred("queue_free")
