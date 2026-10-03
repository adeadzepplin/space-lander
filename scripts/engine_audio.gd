class_name EngineAudio
extends AudioStreamPlayer
## Synthesized engine rumble and crash boom (filtered noise), so no audio files are needed.

const FILTER_GAIN := 3.0 # makes up volume lost by the low-pass filter

var thrust := 0.0 # 0..1 engine throttle
var _boom := 0.0 # current crash noise level
var _filtered := 0.0 # low-pass filter state
var _playback: AudioStreamGeneratorPlayback


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = GameConfig.AUDIO_MIX_RATE
	gen.buffer_length = GameConfig.AUDIO_BUFFER
	stream = gen
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _exit_tree() -> void:
	_playback = null
	stop()
	stream = null


func boom() -> void:
	_boom = GameConfig.BOOM_VOLUME


func _process(delta: float) -> void:
	_boom = maxf(0.0, _boom - _boom * GameConfig.BOOM_DECAY * delta)
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	var level := thrust * GameConfig.ENGINE_VOLUME
	for i in frames:
		var noise := randf_range(-1.0, 1.0)
		_filtered += (noise - _filtered) * GameConfig.ENGINE_LOWPASS
		var s := _filtered * level * FILTER_GAIN + noise * _boom * _boom # boom is unfiltered for crunch
		_playback.push_frame(Vector2(s, s))
