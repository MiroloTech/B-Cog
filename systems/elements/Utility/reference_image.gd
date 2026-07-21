@icon("res://assets/icons/PlaceholderTexture2D.svg")
extends Element
class_name ReferenceImage

@export var source : String = ""
@export var offset : Vector2 = Vector2.ZERO
@export var scale : Vector2 = Vector2.ONE

var sprite : Sprite2D = Sprite2D.new()

func _setup() -> void:
	var texture = load(source)
	if texture is Texture2D:
		sprite.texture = texture
		add_child(sprite)
	else:
		printerr("Failed to load source image for reference image : " + source + " is not loaded as a Texture2D.")

func _process(_delta : float) -> void:
	sprite.position = offset
	sprite.scale = scale

func _remove() -> void:
	pass
