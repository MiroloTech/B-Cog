extends Panel

@export var time_scale : float = 50.0
@export var offset : float = 0.0
@export var time : float = 0.0

@onready var track_list : VBoxContainer = $ControlSplit/Tracks
@onready var caret_container : Control = $ControlSplit/CaretContainer
@onready var caret_head : Button = $ControlSplit/CaretContainer/Caret

const TITLE_WIDTH : float = 150.0
var scene_track : Track = null
var tracks : Array[Track] = []
var panning : bool = false
var dragging : bool = false

func _ready():
	Project.animation_state_updated.connect(on_animation_state_updated)
	Project.open_test_scene()
	force_update_time_ticks(1600.0)
	force_update_scene_track()


func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion and panning:
		offset += event.relative.x
		update_scaling()
	elif event is InputEventMouseMotion and dragging:
		time += event.relative.x / time_scale
		caret_head.position.x = _time2px(round(time)) - 25.0 + 1.0
		caret_head.text = str(round(time))
		force_update_animation()
	
	if event is InputEventMouseButton:
		if get_global_rect().has_point(get_global_mouse_position()):
			if event.button_index == 3:
				panning = event.pressed
			elif event.button_index == 4:
				time_scale /= 0.8
			elif event.button_index == 5:
				time_scale *= 0.8
			elif event.button_index == 1 and (caret_container.get_global_rect().has_point(get_global_mouse_position()) or not event.pressed):
				dragging = event.pressed
			update_scaling()

func on_animation_state_updated(anim : Animation) -> void:
	# Delete old tracks (except for timer track)
	for track in tracks:
		track.queue_free()
	tracks.clear()
	
	# Get list of all tracks and sort it by animation target
	var sorted_tracks : Dictionary[String, Array] = {}
	for track_id in anim.get_track_count():
		var track_path : String = anim.track_get_path(track_id).get_concatenated_names()
		if sorted_tracks.has(track_path):
			sorted_tracks[track_path].append(track_id)
		else:
			sorted_tracks[track_path] = [track_id]
	
	# Create and add new tracks
	for track_path in sorted_tracks:
		var parnet_track_name : String = track_path.get_slice("/", track_path.get_slice_count("/") - 1)
		var parent_track : Track = Track.new(Track.TrackType.SEPERATOR, parnet_track_name)
		tracks.append(parent_track)
		track_list.add_child(parent_track)
		
		for track_id in sorted_tracks[track_path]:
			var track_title : String = "  " + anim.track_get_path(track_id).get_concatenated_subnames()
			var track : Track = Track.new(Track.TrackType.KEYFRAME, track_title)
			tracks.append(track)
			track_list.add_child(track)
			for key_id in anim.track_get_key_count(track_id):
				var t : float = anim.track_get_key_time(track_id, key_id)
				track.add_keyframe(t)
	
	update_scaling()


func update_scaling() -> void:
	for track in tracks:
		track.offset = offset
		track.time_scale = time_scale
		track.update_scaling()
	
	caret_head.position.x = _time2px(round(time)) - 25.0 + 1.0
	force_update_time_ticks()
	
	if scene_track != null:
		scene_track.offset = offset
		scene_track.time_scale = time_scale
		scene_track.update_scaling()

func force_update_animation() -> void:
	Project.active_scene.seek(round(time))

func force_update_time_ticks(custom_width : float = 0.0) -> void:
	for tick in caret_container.get_children():
		if tick is not Button:
			tick.queue_free()
	
	# Create new ticks for good time step
	var w : float = custom_width
	if w == 0.0:
		w = get_parent_area_size().x
	
	# > Find readable timer offset
	var time_step : float = 1.0
	while (time_step * time_scale < 30.0):
		time_step *= 2.0
	
	for t in range(-offset / time_scale, (w - offset) / time_scale + 1, time_step):
		var tick : ColorRect = ColorRect.new()
		caret_container.add_child(tick)
		tick.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		tick.custom_minimum_size.x = 2.0
		tick.custom_minimum_size.y = 24.0 - 8.0
		tick.position.x = _time2px(t) - 1.0
		tick.position.y = 8.0
		tick.modulate.a = 0.3
		
		var tick_title : Label = Label.new()
		tick_title.text = str(t)
		tick_title.position = Vector2(2, -4)
		tick.add_child(tick_title)

func force_update_scene_track() -> void:
	if scene_track != null:
		scene_track.queue_free()
	
	scene_track = Track.new(Track.TrackType.BLOCK, "\t")
	track_list.add_child(scene_track)
	track_list.move_child(scene_track, 0)
	
	# Create block for every scene in project
	for scene in Project.all_scenes:
		scene_track.add_block(scene.name, scene.from, scene.length)



func _time2px(t : float) -> float:
	return t * time_scale + offset + TITLE_WIDTH
