extends Node

var audio_preview : Dictionary[AudioStream, Array] = {}
const audio_preview_tick_interval : float = 0.2

func cache_audio_preview(song : AudioStream) -> Array[float]:
	return []
