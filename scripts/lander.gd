class_name Lander
extends RigidBody2D
## Player ship. Gravity comes from asteroid gravity areas; this script handles engine,
## turning, fuel, impact damage and the landing check.

signal landed(pad: LandingPad)
signal crashed(reason: String)

var player_controlled := true # false lets tests (or replays) drive thrust_input/turn_input
var thrust_input := 0.0 # 0..1 throttle
var turn_input := 0.0 # -1 left .. 1 right
var fuel_capacity := GameConfig.LANDER_FUEL_CAPACITY
var fuel := fuel_capacity
var is_dead := false
var has_landed := false
var landing_progress := 0.0 # 0..1 while resting on a pad
var current_pad: LandingPad
var thrust_visual := 0.0 # smoothed throttle for flame/sound

var _prev_velocity := Vector2.ZERO
var _contacts := {} # collider instance id -> true, from the last physics step
var _touching_pad := false
var _pad_relative_velocity := Vector2.ZERO
var _settle_time := 0.0

@onready var visual: LanderVisual = $Visual
@onready var thrust_particles: CPUParticles2D = $ThrustParticles
@onready var engine_audio: EngineAudio = $EngineAudio
@onready var collision: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	mass = GameConfig.LANDER_MASS
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp = GameConfig.LANDER_ANGULAR_DAMP
	contact_monitor = true
	max_contacts_reported = GameConfig.LANDER_MAX_CONTACTS
	collision_layer = GameConfig.LAYER_LANDER
	collision_mask = GameConfig.LAYER_TERRAIN
	can_sleep = false
	var mat := PhysicsMaterial.new()
	mat.friction = GameConfig.LANDER_FRICTION
	mat.bounce = GameConfig.LANDER_BOUNCE
	physics_material_override = mat
	_setup_thrust_particles()


func set_fuel_capacity(capacity: float) -> void:
	fuel_capacity = capacity
	fuel = capacity


func add_fuel(amount: float) -> void:
	fuel = minf(fuel_capacity, fuel + amount)


## Distance from the ship origin down to the bottom of its feet.
func get_foot_offset() -> float:
	var lowest := 0.0
	for p in collision.polygon:
		lowest = maxf(lowest, p.y)
	return lowest


func get_up() -> Vector2:
	return -global_transform.y.normalized()


func is_thrusting() -> bool:
	return thrust_input > 0.0 and fuel > 0.0 and not is_dead and not has_landed and not freeze


func wants_to_move() -> bool:
	return thrust_input > 0.0 or turn_input != 0.0


func _physics_process(delta: float) -> void:
	if player_controlled and not is_dead:
		thrust_input = Input.get_action_strength("thrust")
		turn_input = Input.get_axis("rotate_left", "rotate_right")
	if is_thrusting():
		fuel = maxf(0.0, fuel - GameConfig.LANDER_FUEL_BURN * thrust_input * delta)
	var target := thrust_input if is_thrusting() else 0.0
	thrust_visual = move_toward(thrust_visual, target, GameConfig.LANDER_THRUST_SMOOTHING * delta)
	visual.thrust = thrust_visual
	thrust_particles.emitting = is_thrusting()
	engine_audio.thrust = thrust_visual
	_update_landing(delta)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_dead:
		return
	var now := {}
	_touching_pad = false
	for i in state.get_contact_count():
		var collider := state.get_contact_collider_object(i)
		if collider == null:
			continue
		var id := collider.get_instance_id()
		var collider_velocity := state.get_contact_collider_velocity_at_position(i)
		if not _contacts.has(id) and not now.has(id):
			_on_impact(collider, (_prev_velocity - collider_velocity).length())
		now[id] = true
		if collider is LandingPad:
			_touching_pad = true
			current_pad = collider
			_pad_relative_velocity = state.linear_velocity - collider_velocity
	_contacts = now
	if is_dead:
		return

	if not _contacts.is_empty() and not has_landed:
		var gravity_up := -state.total_gravity.normalized()
		if gravity_up != Vector2.ZERO and absf(get_up().angle_to(gravity_up)) > deg_to_rad(GameConfig.TIP_OVER_ANGLE_DEG):
			crash("Tipped over")
			return

	# Arcade turning: steer angular velocity directly, but let collisions spin the ship when idle.
	if not has_landed and (turn_input != 0.0 or _contacts.is_empty()):
		var target_spin := turn_input * GameConfig.LANDER_TURN_SPEED
		state.angular_velocity = move_toward(state.angular_velocity, target_spin,
			GameConfig.LANDER_TURN_ACCEL * state.step)
	if is_thrusting():
		state.apply_central_force(get_up() * GameConfig.LANDER_THRUST * mass * thrust_input)
	_prev_velocity = state.linear_velocity


func _on_impact(collider: Object, impact_speed: float) -> void:
	if collider is LandingPad:
		if impact_speed > GameConfig.SAFE_LANDING_SPEED:
			crash("Hit the pad too hard (%d m/s)" % impact_speed)
	elif impact_speed > GameConfig.CRASH_SPEED:
		crash("Smashed into rock (%d m/s)" % impact_speed)


func get_tilt_to(pad: LandingPad) -> float:
	return get_up().angle_to(pad.get_up())


func _update_landing(delta: float) -> void:
	if is_dead or has_landed or freeze:
		return
	var resting := _touching_pad and current_pad != null \
		and absf(get_tilt_to(current_pad)) <= deg_to_rad(GameConfig.SAFE_LANDING_ANGLE_DEG) \
		and _pad_relative_velocity.length() <= GameConfig.LANDING_REST_SPEED
	_settle_time = _settle_time + delta if resting else 0.0
	landing_progress = clampf(_settle_time / GameConfig.LANDING_SETTLE_TIME, 0.0, 1.0)
	if landing_progress >= 1.0:
		has_landed = true
		current_pad.set_landed(true)
		landed.emit(current_pad)


func crash(reason: String) -> void:
	if is_dead or has_landed:
		return
	is_dead = true
	thrust_input = 0.0
	thrust_visual = 0.0
	visual.visible = false
	thrust_particles.emitting = false
	engine_audio.thrust = 0.0
	engine_audio.boom()
	set_deferred("freeze", true)
	set_deferred("collision_layer", 0)
	_spawn_explosion.call_deferred()
	crashed.emit(reason)


func _spawn_explosion() -> void:
	var boom := CPUParticles2D.new()
	boom.one_shot = true
	boom.explosiveness = 1.0
	boom.amount = GameConfig.EXPLOSION_PARTICLES
	boom.lifetime = GameConfig.EXPLOSION_LIFETIME
	boom.spread = 180.0
	boom.gravity = Vector2.ZERO
	boom.initial_velocity_min = GameConfig.EXPLOSION_SPEED * GameConfig.EXPLOSION_DRAG
	boom.initial_velocity_max = GameConfig.EXPLOSION_SPEED
	boom.damping_min = GameConfig.EXPLOSION_SPEED * GameConfig.EXPLOSION_DRAG
	boom.damping_max = GameConfig.EXPLOSION_SPEED * GameConfig.EXPLOSION_DRAG
	boom.scale_amount_min = GameConfig.EXPLOSION_SIZE.x
	boom.scale_amount_max = GameConfig.EXPLOSION_SIZE.y
	boom.color_ramp = _fire_gradient()
	boom.global_position = global_position
	get_parent().add_child(boom)
	boom.emitting = true
	boom.finished.connect(boom.queue_free)


func _setup_thrust_particles() -> void:
	var p := thrust_particles
	p.amount = GameConfig.THRUST_PARTICLES
	p.lifetime = GameConfig.THRUST_PARTICLE_LIFETIME
	p.local_coords = false
	p.direction = Vector2.DOWN
	p.spread = GameConfig.THRUST_PARTICLE_SPREAD
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = GameConfig.THRUST_PARTICLE_SPEED.x
	p.initial_velocity_max = GameConfig.THRUST_PARTICLE_SPEED.y
	p.scale_amount_min = GameConfig.THRUST_PARTICLE_SIZE.x
	p.scale_amount_max = GameConfig.THRUST_PARTICLE_SIZE.y
	p.color_ramp = _fire_gradient()
	p.emitting = false


func _fire_gradient() -> Gradient:
	var g := Gradient.new()
	var glow := GameConfig.HDR_GLOW
	g.set_color(0, GameConfig.COLOR_FLAME_CORE * Color(glow, glow, glow, 1.0))
	g.set_color(1, Color(GameConfig.COLOR_FLAME_OUTER, 0.0))
	g.add_point(0.3, GameConfig.COLOR_FLAME_OUTER * Color(glow, glow, glow, 1.0)) # 0.3 = turns orange early in life
	return g
