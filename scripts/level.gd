class_name Level
extends Node2D
## Root script for every level scene. A level needs a Marker2D named "Spawn" and at least
## one LandingPad (usually a child of an Asteroid). Everything else (camera, HUD, ghost,
## background) is added automatically when the level runs.

signal state_changed(new_state: State)

enum State { READY, FLYING, LANDED, CRASHED }

const LANDER_SCENE := preload("res://scenes/lander.tscn")
const GHOST_SCENE := preload("res://scenes/ghost.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")

@export var level_name := "Untitled" # shown in menu and HUD
@export_multiline var briefing := "" # short hint shown before launch
@export var fuel_capacity := -1.0 # tank size for this level, -1 uses GameConfig default
@export var camera_zoom := 1.0 # >1 zooms in, <1 shows more space
@export var bounds_radius := 3500.0 # ship is lost beyond this distance from Spawn, px

var player_controlled := true # tests turn this off before adding the level to the tree
var state := State.READY
var elapsed := 0.0
var level_id := ""
var best_time := -1.0
var new_record := false
var lander: Lander
var ghost: Ghost
var camera: Camera2D
var hud: Hud
var recording := GhostData.new()
var asteroids: Array[Asteroid] = []
var pads: Array[LandingPad] = []

var _ticks := 0
var _shake := 0.0
var _spawn_position := Vector2.ZERO
var _starfield: Starfield


func _ready() -> void:
	level_id = Game.level_id_from_path(scene_file_path)
	best_time = Game.get_best_time(level_id)
	_collect_nodes(self)
	_setup_background()
	_spawn_lander()
	_setup_ghost()
	_setup_camera()
	var preview := TrajectoryPreview.new()
	preview.level = self
	add_child(preview)
	hud = HUD_SCENE.instantiate()
	hud.level = self
	add_child(hud)
	recording.interval = float(GameConfig.GHOST_RECORD_TICKS) / Engine.physics_ticks_per_second


func _collect_nodes(node: Node) -> void:
	for child in node.get_children():
		if child is Asteroid:
			asteroids.append(child)
		elif child is LandingPad:
			pads.append(child)
		_collect_nodes(child)


func _setup_background() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CANVAS
	env.environment.glow_enabled = true
	env.environment.glow_intensity = 0.8 # bloom strength on HDR colors
	env.environment.glow_hdr_threshold = 1.0 # only colors brighter than white glow
	add_child(env)
	var layer := CanvasLayer.new()
	layer.layer = -100 # behind everything
	_starfield = Starfield.new()
	layer.add_child(_starfield)
	add_child(layer)


func _spawn_lander() -> void:
	var spawn := get_node_or_null("Spawn") as Node2D
	if spawn == null:
		push_error("Level '%s' has no Marker2D named Spawn" % level_name)
	lander = LANDER_SCENE.instantiate()
	lander.player_controlled = player_controlled
	lander.freeze = true
	add_child(lander)
	if spawn:
		lander.global_transform = spawn.global_transform
	_spawn_position = lander.global_position
	lander.set_fuel_capacity(fuel_capacity if fuel_capacity >= 0.0 else GameConfig.LANDER_FUEL_CAPACITY)
	lander.landed.connect(_on_landed)
	lander.crashed.connect(_on_crashed)


func _setup_ghost() -> void:
	var data := Game.load_ghost(level_id)
	if data == null:
		return
	ghost = GHOST_SCENE.instantiate()
	ghost.data = data
	add_child(ghost)
	move_child(ghost, lander.get_index()) # draw behind the player


func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * camera_zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = GameConfig.CAMERA_SMOOTHING
	camera.global_position = lander.global_position
	add_child(camera)
	camera.make_current()
	camera.reset_smoothing()


func start() -> void:
	if state != State.READY:
		return
	lander.freeze = false
	_set_state(State.FLYING)


func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)


func _physics_process(delta: float) -> void:
	if state == State.READY and lander.wants_to_move():
		start()
	if state == State.FLYING:
		if _ticks % GameConfig.GHOST_RECORD_TICKS == 0:
			recording.add_sample(lander.global_position, lander.global_rotation, lander.thrust_visual)
		_ticks += 1
		elapsed += delta
		if lander.global_position.distance_to(_spawn_position) > bounds_radius:
			lander.crash("Lost in space")
	if ghost and state != State.READY:
		ghost.show_time(elapsed)


func _process(delta: float) -> void:
	if lander and not lander.is_dead:
		var lead := (lander.linear_velocity * GameConfig.CAMERA_LOOKAHEAD).limit_length(GameConfig.CAMERA_LOOKAHEAD_MAX)
		camera.global_position = lander.global_position + lead
	_shake = maxf(0.0, _shake - GameConfig.CAMERA_SHAKE_DECAY * delta)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * GameConfig.CAMERA_SHAKE_STRENGTH * _shake * _shake
	_starfield.scroll = camera.get_screen_center_position() * camera_zoom


func _unhandled_input(event: InputEvent) -> void:
	if not player_controlled:
		return
	if event.is_action_pressed("restart"):
		Game.restart_level()
	elif event.is_action_pressed("next_level") and state == State.LANDED:
		Game.next_level()
	elif event.is_action_pressed("pause") and state != State.LANDED:
		hud.toggle_pause()


func get_gravity_at(world_point: Vector2) -> Vector2:
	var g := Vector2.ZERO
	for a in asteroids:
		g += a.gravity_at(world_point)
	return g


func is_point_in_rock(world_point: Vector2) -> bool:
	for a in asteroids:
		if a.is_point_inside(world_point):
			return true
	return false


func nearest_pad(from: Vector2) -> LandingPad:
	var best: LandingPad = null
	for p in pads:
		if best == null or p.global_position.distance_to(from) < best.global_position.distance_to(from):
			best = p
	return best


func _on_landed(_pad: LandingPad) -> void:
	recording.add_sample(lander.global_position, lander.global_rotation, 0.0)
	new_record = Game.submit_result(level_id, elapsed, recording)
	_set_state(State.LANDED)


func _on_crashed(reason: String) -> void:
	_shake = 1.0
	hud.crash_reason = reason
	_set_state(State.CRASHED)
