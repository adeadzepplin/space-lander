class_name GhostData
extends Resource
## A recorded flight: evenly spaced samples of ship position, rotation and throttle.

@export var interval := 0.0 # seconds between samples
@export var total_time := 0.0 # finish time of the run
@export var positions := PackedVector2Array()
@export var rotations := PackedFloat32Array()
@export var thrusts := PackedFloat32Array()


func add_sample(pos: Vector2, rot: float, thrust: float) -> void:
	positions.append(pos)
	rotations.append(rot)
	thrusts.append(thrust)


func sample_count() -> int:
	return positions.size()


## Interpolated state at time t. Clamps to the last sample once the run is over.
func sample(t: float) -> Dictionary:
	var count := sample_count()
	if count == 0 or interval <= 0.0:
		return {}
	var f := clampf(t / interval, 0.0, float(count - 1))
	var i := int(f)
	var j := mini(i + 1, count - 1)
	var w := f - i
	return {
		"position": positions[i].lerp(positions[j], w),
		"rotation": lerp_angle(rotations[i], rotations[j], w),
		"thrust": lerpf(thrusts[i], thrusts[j], w),
	}
