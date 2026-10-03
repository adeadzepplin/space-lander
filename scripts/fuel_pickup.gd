@tool
class_name FuelPickup
extends Area2D
## Floating fuel canister. Touch it to refuel.

@export var amount := 40.0 # fuel added on pickup

var _time := 0.0
var _collected := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConfig.LAYER_LANDER
	if not Engine.is_editor_hint():
		var circle := CircleShape2D.new()
		circle.radius = GameConfig.PICKUP_RADIUS
		($CollisionShape2D as CollisionShape2D).shape = circle
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _collected or not body is Lander or body.is_dead:
		return
	_collected = true
	body.add_fuel(amount)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 2.0, 0.25) # pop outward
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var r := GameConfig.PICKUP_RADIUS
	var bob := sin(_time * GameConfig.PICKUP_BOB_SPEED) * GameConfig.PICKUP_BOB_HEIGHT
	var glow := GameConfig.HDR_GLOW
	draw_circle(Vector2(0, bob), r, Color(GameConfig.COLOR_FUEL, 0.15))
	draw_rect(Rect2(-r * 0.45, bob - r * 0.65, r * 0.9, r * 1.3), GameConfig.COLOR_FUEL * Color(glow, glow, glow, 1.0))
	draw_rect(Rect2(-r * 0.2, bob - r * 0.85, r * 0.4, r * 0.2), GameConfig.COLOR_FUEL.darkened(0.3))
	draw_line(Vector2(-r * 0.25, bob), Vector2(r * 0.25, bob), GameConfig.COLOR_BG, 2.0)
