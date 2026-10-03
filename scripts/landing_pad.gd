@tool
class_name LandingPad
extends AnimatableBody2D
## Landing target. Make it a child of an Asteroid: it faces away from the asteroid's
## center and flattens the ground under it. Its origin sits on the ground; the plate is on top.

@export var width := 90.0: # plate width, px
	set(v):
		width = maxf(v, 20.0)
		_refresh()
@export var auto_orient := true # face away from the parent asteroid's center

var is_landed := false
var _time := 0.0


func _ready() -> void:
	sync_to_physics = false # follows a moving parent asteroid
	collision_layer = GameConfig.LAYER_TERRAIN
	collision_mask = 0
	add_to_group("landing_pad")
	set_notify_local_transform(true)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_refresh()


func get_up() -> Vector2:
	return -global_transform.y.normalized()


## World position of the middle of the plate's top surface.
func get_top_center() -> Vector2:
	return to_global(Vector2(0.0, -GameConfig.PAD_THICKNESS))


func set_landed(value: bool) -> void:
	is_landed = value
	queue_redraw()


func _refresh() -> void:
	if not is_node_ready():
		return
	var parent := get_parent()
	if auto_orient and parent is Asteroid and position.length() > 0.0:
		var target := position.angle() + PI * 0.5
		if not is_equal_approx(rotation, target):
			rotation = target
	if parent is Asteroid:
		parent.rebuild()
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var plate := RectangleShape2D.new()
	plate.size = Vector2(width, GameConfig.PAD_THICKNESS)
	var shape := $CollisionShape2D as CollisionShape2D
	shape.shape = plate
	shape.position = Vector2(0.0, -GameConfig.PAD_THICKNESS * 0.5)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw() # blinking lights


func _draw() -> void:
	var t := GameConfig.PAD_THICKNESS
	var half := width * 0.5
	draw_rect(Rect2(-half, -t, width, t), GameConfig.COLOR_PAD)
	draw_rect(Rect2(-half, -t, width, t * 0.3), GameConfig.COLOR_PAD.lightened(0.3))
	# Support struts down into the rock.
	for x in [-half * 0.6, half * 0.6]:
		draw_line(Vector2(x, 0), Vector2(x * 0.8, t * 2.0), GameConfig.COLOR_PAD.darkened(0.4), 3.0)
	var blink := fmod(_time * GameConfig.PAD_LIGHT_BLINK_RATE, 1.0) < 0.5
	var glow := GameConfig.HDR_GLOW
	var light := GameConfig.COLOR_PAD_LIGHT * Color(glow, glow, glow, 1.0)
	if not is_landed and not blink:
		light = GameConfig.COLOR_PAD_LIGHT.darkened(0.7)
	draw_circle(Vector2(-half, -t), 3.0, light)
	draw_circle(Vector2(half, -t), 3.0, light)
	if is_landed:
		draw_rect(Rect2(-half, -t - 2.0, width, 2.0), light)
