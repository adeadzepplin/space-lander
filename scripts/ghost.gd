class_name Ghost
extends Node2D
## Plays back a GhostData recording using the same ship drawing as the player.

var data: GhostData

@onready var visual: LanderVisual = $Visual


func _ready() -> void:
	modulate = Color(GameConfig.COLOR_GHOST, GameConfig.GHOST_ALPHA)
	visual.hull_color = GameConfig.COLOR_GHOST
	visual.accent_color = GameConfig.COLOR_GHOST
	show_time(0.0)


func show_time(t: float) -> void:
	var s := data.sample(t) if data else {}
	visible = not s.is_empty()
	if s.is_empty():
		return
	global_position = s.position
	global_rotation = s.rotation
	visual.thrust = s.thrust if t < data.total_time else 0.0
