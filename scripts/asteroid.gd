@tool
class_name Asteroid
extends AnimatableBody2D
## Lumpy asteroid with its own point gravity. Shape is generated from `shape_seed`.
## Put LandingPads as children and the ground under them is flattened automatically.
## Use `radius` to size it (don't scale the node, gravity math assumes no scale).

@export var radius := 200.0: # average surface radius, px
	set(v):
		radius = maxf(v, 10.0)
		rebuild()
@export_range(0.0, 0.4) var roughness := 0.12: # surface bumpiness as a fraction of radius
	set(v):
		roughness = v
		rebuild()
@export var shape_seed := 1: # change for a different shape
	set(v):
		shape_seed = v
		rebuild()
@export var point_count := GameConfig.ASTEROID_DEFAULT_POINTS: # outline resolution
	set(v):
		point_count = maxi(v, 8)
		rebuild()

@export_group("Gravity")
@export var surface_gravity := 40.0: # pull at the surface, px/s^2 (falls off with distance squared)
	set(v):
		surface_gravity = v
		rebuild()
@export var gravity_range := 3.5: # gravity reach as a multiple of radius
	set(v):
		gravity_range = maxf(v, 1.0)
		rebuild()
@export var show_gravity_ring := true # faint circle showing where gravity ends

@export_group("Motion")
@export var spin_speed := 0.0 # rotation, degrees per second
@export var orbit_around: Node2D # sibling to circle around, keeping the distance set in the editor
@export var orbit_speed := 0.0 # degrees per second around orbit_around

@export_group("Look")
@export var rock_color := GameConfig.COLOR_ROCK:
	set(v):
		rock_color = v
		queue_redraw()

var points := PackedVector2Array() # outline in local space
var _craters: Array[Vector3] = [] # x, y, radius
var _orbit_radius := 0.0
var _orbit_angle := 0.0
var _gravity_area: Area2D
var _gravity_shape: CollisionShape2D
var _collision: CollisionPolygon2D


func _ready() -> void:
	_collision = $CollisionPolygon2D
	_gravity_area = $GravityArea
	_gravity_shape = $GravityArea/CollisionShape2D
	sync_to_physics = false # pads nested inside need plain transform syncing
	collision_layer = GameConfig.LAYER_TERRAIN
	collision_mask = 0
	if orbit_around:
		var offset := global_position - orbit_around.global_position
		_orbit_radius = offset.length()
		_orbit_angle = offset.angle()
	rebuild()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if spin_speed != 0.0:
		rotation += deg_to_rad(spin_speed) * delta
	if orbit_around and orbit_speed != 0.0:
		_orbit_angle += deg_to_rad(orbit_speed) * delta
		global_position = orbit_around.global_position + Vector2.from_angle(_orbit_angle) * _orbit_radius


## Gravity this asteroid applies at a world point. Mirrors Godot's point-gravity area math.
func gravity_at(world_point: Vector2) -> Vector2:
	var offset := global_position - world_point
	var dist := offset.length()
	if dist < 0.001 or dist > radius * gravity_range:
		return Vector2.ZERO
	return offset / dist * surface_gravity * (radius * radius) / (dist * dist)


func is_point_inside(world_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(world_point), points)


func get_pads() -> Array[LandingPad]:
	var pads: Array[LandingPad] = []
	for child in get_children():
		if child is LandingPad:
			pads.append(child)
	return pads


func rebuild() -> void:
	if not is_node_ready():
		return
	points = _generate_outline()
	_generate_craters()
	queue_redraw()
	if Engine.is_editor_hint():
		return # keep generated data out of saved scenes
	_collision.polygon = points
	_gravity_area.collision_layer = 0
	_gravity_area.collision_mask = GameConfig.LAYER_LANDER
	_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_COMBINE
	_gravity_area.gravity_point = true
	_gravity_area.gravity_point_center = Vector2.ZERO
	_gravity_area.gravity_point_unit_distance = radius
	_gravity_area.gravity = surface_gravity
	var circle := CircleShape2D.new()
	circle.radius = radius * gravity_range
	_gravity_shape.shape = circle


# --- Shape generation ---

func _noise_params() -> Array[Vector3]:
	# Each octave: x = frequency, y = phase, z = amplitude.
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	var out: Array[Vector3] = []
	for o in GameConfig.ASTEROID_NOISE_OCTAVES:
		var freq := float(2 + o * 2 + rng.randi_range(0, 2))
		out.append(Vector3(freq, rng.randf() * TAU, rng.randf_range(0.5, 1.0) / (o + 1)))
	return out


func _flat_zones() -> Array[Vector3]:
	# Each pad: x = angle, y = half angular width, z = surface radius.
	var zones: Array[Vector3] = []
	for pad in get_pads():
		var d := pad.position.length()
		if d < 1.0:
			continue
		var half := (pad.width * 0.5 + GameConfig.ASTEROID_PAD_FLAT_MARGIN) / d
		zones.append(Vector3(pad.position.angle(), half, d))
	return zones


func _surface_radius(angle: float, octaves: Array[Vector3], zones: Array[Vector3]) -> float:
	var n := 0.0
	var total := 0.0
	for o in octaves:
		n += sin(angle * o.x + o.y) * o.z
		total += o.z
	var r := radius * (1.0 + roughness * n / total)
	for z in zones:
		var diff := absf(angle_difference(angle, z.x))
		if diff <= z.y:
			return z.z
		if diff < z.y + GameConfig.ASTEROID_PAD_BLEND:
			var t := smoothstep(0.0, 1.0, (diff - z.y) / GameConfig.ASTEROID_PAD_BLEND)
			r = lerpf(z.z, r, t)
	return r


func _generate_outline() -> PackedVector2Array:
	var octaves := _noise_params()
	var zones := _flat_zones()
	var angles: Array[float] = []
	for i in point_count:
		var a := TAU * i / point_count
		var inside_zone := false
		for z in zones:
			if absf(angle_difference(a, z.x)) < z.y:
				inside_zone = true
		if not inside_zone:
			angles.append(a)
	for z in zones: # exact corners so the flat part really is flat
		angles.append(fposmod(z.x - z.y, TAU))
		angles.append(fposmod(z.x + z.y, TAU))
	angles.sort()
	var out := PackedVector2Array()
	for a in angles:
		out.append(Vector2.from_angle(a) * _surface_radius(a, octaves, zones))
	return out


func _generate_craters() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed * 7919 + 1 # different stream from the outline
	_craters.clear()
	for i in GameConfig.ASTEROID_CRATER_COUNT:
		var p := Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.0, 0.65)
		_craters.append(Vector3(p.x, p.y, radius * rng.randf_range(0.06, 0.16)))


func _draw() -> void:
	if points.size() < 3:
		return
	if show_gravity_ring:
		var ring_r := radius * gravity_range
		var dashes := GameConfig.ASTEROID_GRAVITY_RING_DASHES
		for i in dashes:
			var a0 := TAU * i / dashes
			draw_arc(Vector2.ZERO, ring_r, a0, a0 + TAU / dashes * 0.5, 4, GameConfig.COLOR_GRAVITY_RING, 2.0, true)
	draw_colored_polygon(points, rock_color)
	for c in _craters:
		draw_circle(Vector2(c.x, c.y), c.z, GameConfig.COLOR_CRATER)
		draw_arc(Vector2(c.x, c.y), c.z, PI * 0.9, PI * 1.9, 12, GameConfig.COLOR_ROCK_EDGE.darkened(0.3), 2.0, true)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, GameConfig.COLOR_ROCK_EDGE, 3.0, true)
