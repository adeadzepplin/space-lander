class_name TrajectoryPreview
extends Node2D
## Dotted line showing where the ship will drift if the engine stays off.

var level: Level


func _process(_delta: float) -> void:
	queue_redraw()


func predict() -> PackedVector2Array:
	var out := PackedVector2Array()
	var lander := level.lander
	var pos := lander.global_position
	var vel := lander.linear_velocity
	var dt := GameConfig.TRAJECTORY_STEP_TIME
	for i in GameConfig.TRAJECTORY_STEPS:
		vel += level.get_gravity_at(pos) * dt
		pos += vel * dt
		if level.is_point_in_rock(pos):
			break
		out.append(pos)
	return out


func _draw() -> void:
	if level == null or level.state != Level.State.FLYING:
		return
	var path := predict()
	for i in path.size():
		var fade := 1.0 - float(i) / GameConfig.TRAJECTORY_STEPS
		draw_circle(to_local(path[i]), 1.5, Color(GameConfig.COLOR_UI, GameConfig.TRAJECTORY_ALPHA * fade))
