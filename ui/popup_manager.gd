extends Control

@onready var darkening : ColorRect = $Darkening

var open_popups : Array[Window] = []

signal popup_closed(popup : Window)

func open_popup(popup : Window) -> void:
	open_popups.append(popup)
	darkening.show()
	darkening.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(popup)
	popup.popup_centered(popup.size)
	popup.close_requested.connect(close_popup.bind(popup))

func close_popup(popup : Window) -> void:
	popup.hide()
	darkening.mouse_filter = Control.MOUSE_FILTER_IGNORE
	remove_child(popup)
	open_popups.erase(popup)
	if open_popups.size() == 0:
		darkening.hide()
	emit_signal("popup_closed", popup)
