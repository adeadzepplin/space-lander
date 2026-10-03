@tool
class_name LanderVisual
extends Node2D
## Draws the ship. Shared by the player lander and ghosts so they always look the same.

# Ship outline in local pixels. Ship faces up (-y). Matches the collision polygon in lander.tscn.
const HULL := [Vector2(-7, -16), Vector2(7, -16), Vector2(12, -9), Vector2(12, 2), Vector2(-12, 2), Vector2(-12, -9)]
const NOZZLE := [Vector2(-4, 2), Vector2(4, 2), Vector2(6, 9), Vector2(-6, 9)]
const WINDOW_POS := Vector2(0, -7) # cockpit window center
const WINDOW_RADIUS := 4.5 # cockpit window size
const LEG_TOP := Vector2(9, 0) # where a leg leaves the hull (mirrored)
const LEG_FOOT := Vector2(18, 14) # where a leg touches down (mirrored)
const FOOT_HALF_WIDTH := 4.0 # foot pad half length
const LINE_WIDTH := 2.0 # outline and leg thickness
const FLAME_TOP_Y := 9.0 # flame starts at the nozzle exit
const FLAME_HALF_WIDTH := 5.0 # flame width at the nozzle
const FLAME_FLICKER := 0.25 # random flame length variation 0..1

@export var hull_color := GameConfig.COLOR_HULL:
	set(v):
		hull_color = v
		queue_redraw()
@export var accent_color := GameConfig.COLOR_HULL_ACCENT:
	set(v):
		accent_color = v
		queue_redraw()
@export var draw_flame := true # ghosts can turn off the flame

var thrust := 0.0:
	set(v):
		thrust = v
		queue_redraw()


func _process(_delta: float) -> void:
	if thrust > 0.0:
		queue_redraw() # flame flicker


func _draw() -> void:
	if draw_flame and thrust > 0.01:
		var length := GameConfig.FLAME_LENGTH * thrust * (1.0 - randf() * FLAME_FLICKER)
		var glow := GameConfig.HDR_GLOW
		var outer := GameConfig.COLOR_FLAME_OUTER * Color(glow, glow, glow, 1.0)
		var core := GameConfig.COLOR_FLAME_CORE * Color(glow, glow, glow, 1.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-FLAME_HALF_WIDTH, FLAME_TOP_Y), Vector2(FLAME_HALF_WIDTH, FLAME_TOP_Y),
			Vector2(0, FLAME_TOP_Y + length)]), outer)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-FLAME_HALF_WIDTH * 0.5, FLAME_TOP_Y), Vector2(FLAME_HALF_WIDTH * 0.5, FLAME_TOP_Y),
			Vector2(0, FLAME_TOP_Y + length * 0.6)]), core)

	for side in [-1.0, 1.0]:
		var mirror := Vector2(side, 1.0)
		draw_line(LEG_TOP * mirror, LEG_FOOT * mirror, hull_color.darkened(0.25), LINE_WIDTH, true)
		draw_line((LEG_FOOT + Vector2(-FOOT_HALF_WIDTH, 0)) * mirror, (LEG_FOOT + Vector2(FOOT_HALF_WIDTH, 0)) * mirror,
			hull_color.darkened(0.25), LINE_WIDTH + 1.0, true)

	draw_colored_polygon(PackedVector2Array(NOZZLE), hull_color.darkened(0.45))
	var hull := PackedVector2Array(HULL)
	draw_colored_polygon(hull, hull_color)
	hull.append(hull[0])
	draw_polyline(hull, accent_color, LINE_WIDTH, true)
	draw_circle(WINDOW_POS, WINDOW_RADIUS, GameConfig.COLOR_WINDOW)
	draw_circle(WINDOW_POS + Vector2(-1.5, -1.5), WINDOW_RADIUS * 0.35, Color(1, 1, 1, 0.7))
