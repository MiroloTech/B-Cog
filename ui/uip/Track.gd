extends Control
class_name Track

@export var drag_step : float = 1.0
@export var time_scale : float = 50.0
@export var offset : float = 0.0
@export var main_color : Color = Color.SKY_BLUE

const TITLE_WIDTH : float = 150.0

signal elemnt_dragged(element_id : int, time : float)

var track_type : TrackType = TrackType.KEYFRAME
var elements : Array[Control] = []

enum TrackType {
	KEYFRAME,
	BLOCK,
	AUDIO,
	SEPERATOR,
}

func _init(type : TrackType, title : String = "unnamed"):
	track_type = type
	custom_minimum_size.y = 24.0
	if type == TrackType.BLOCK:
		custom_minimum_size.y = 32.0
	# Track title
	var panel : Panel = Panel.new()
	add_child(panel)
	panel.theme_type_variation = "PanelBright"
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.custom_minimum_size.x = 150.0
	panel.z_index = 3
	
	var label : Label = Label.new()
	panel.add_child(label)
	label.text = title
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if title == "\t":
		label.hide()
		panel.hide()

func _time2px(t : float) -> float:
	return t * time_scale + offset + TITLE_WIDTH


# ===== ELEMENT CONSTRUCTORS =====

func add_keyframe(t : float) -> void:
	var pos : float = _time2px(int(t)) - 8.0
	
	var button : TextureButton = TextureButton.new()
	elements.append(button)
	add_child(button)
	
	button.texture_normal = preload("res://assets/icons/KeyBezierPoint.svg")
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.position = Vector2(pos, 4)
	button.size = Vector2(16, 16)
	button.set_meta("t", t)
	
	# button.z_index = -1
	button.modulate = main_color

func add_block(tag : String, from : int, length : int) -> void:
	var start : float = _time2px(from)
	var end : float = _time2px(from + length)
	
	var block : Button = Button.new()
	elements.append(block)
	add_child(block)
	
	block.clip_text = true
	block.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	block.text = " " + tag
	block.alignment = HORIZONTAL_ALIGNMENT_LEFT
	block.size = Vector2(end - start, custom_minimum_size.y)
	block.position.x = start
	block.set_meta("from", from)
	block.set_meta("length", length)

func update_scaling() -> void:
	if track_type == TrackType.KEYFRAME:
		for element in elements:
			element.position.x = _time2px(element.get_meta("t")) - 8.0
	elif track_type == TrackType.BLOCK:
		for element in elements:
			var start : float = _time2px(element.get_meta("from"))
			var end : float = _time2px(element.get_meta("from") + element.get_meta("length"))
			element.position.x = start
			element.size.x = end - start
