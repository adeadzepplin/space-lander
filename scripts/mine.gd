@tool
class_name Mine
extends Area2D
## Space mine. Touching it destroys the ship. Can patrol back and forth.

@export var patrol_offset := Vector2.ZERO # moves between start and start + this, px
@export var patrol_time := 3.0 # seconds for one leg of the patrol

var _time := 0.0
var _start := Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConfig.LAYER_LANDER
	_start = position
	if not Engine.is_editor_hint():
		var circle := CircleShape2D.new()
		circle.radius = GameConfig.MINE_RADIUS
		($CollisionShape2D as CollisionShape2D).shape = circle
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Lander:
		body.crash("Hit a mine")


func _physics_process(delta: float) -> void:
	_time += delta
	if not Engine.is_editor_hint() and patrol_offset != Vector2.ZERO and patrol_time > 0.0:
		var t := 0.5 - 0.5 * cos(_time * PI / patrol_time) # smooth back-and-forth 0..1
		position = _start + patrol_offset * t
	queue_redraw()


func _draw() -> void:
	var r := GameConfig.MINE_RADIUS
	var pulse := 0.5 + 0.5 * sin(_time * GameConfig.MINE_PULSE_SPEED)
	for i in GameConfig.MINE_SPIKES:
		var dir := Vector2.from_angle(TAU * i / GameConfig.MINE_SPIKES)
		draw_line(dir * r * 0.6, dir * r * 1.35, GameConfig.COLOR_MINE.darkened(0.3), 3.0, true)
	draw_circle(Vector2.ZERO, r * 0.75, GameConfig.COLOR_MINE.darkened(0.5))
	var glow := 1.0 + (GameConfig.HDR_GLOW - 1.0) * pulse
	draw_circle(Vector2.ZERO, r * 0.3, GameConfig.COLOR_MINE * Color(glow, glow, glow, 1.0))
	if Engine.is_editor_hint() and patrol_offset != Vector2.ZERO:
		draw_line(Vector2.ZERO, patrol_offset, Color(GameConfig.COLOR_MINE, 0.4), 1.0)
