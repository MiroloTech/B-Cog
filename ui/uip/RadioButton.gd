@tool
extends CheckBox
class_name RadioButton

func _init():
	toggle_mode = true
	
	# Auto-Check first button
	select_first()
	theme_type_variation = "RadioButton"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _ready():
	fix_multi_selection()

func _enter_tree():
	fix_multi_selection()

func _exit_tree():
	select_first()

func _pressed():
	button_pressed = true
	fix_multi_selection()

func select_first() -> void:
	if get_parent() == null:
		return
	
	for element in get_parent().get_children():
		if element is RadioButton:
			element.set_pressed_no_signal(true)
			break

func fix_multi_selection() -> void:
	if get_parent() == null:
		return
	
	var any_pressed : bool = false
	for element in get_parent().get_children():
		if element is RadioButton:
			if element != self:
				element.set_pressed_no_signal(false)
			if element.button_pressed:
				any_pressed = true
	
	if not any_pressed:
		select_first()
