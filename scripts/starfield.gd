class_name Starfield
extends Node2D
## Screen-space parallax stars and nebula clouds. Put it inside a CanvasLayer behind the game
## and set `scroll` to the camera position each frame.

const STAR_SIZE := Vector2(0.6, 2.2) # min/max star radius, px
const NEBULA_SIZE := Vector2(0.25, 0.6) # min/max cloud radius as fraction of screen height
const NEBULA_ALPHA := 0.05 # cloud opacity
const NEBULA_PARALLAX := 0.01 # clouds scroll slower than every star
const NEBULA_COLORS := [Color(0.4, 0.2, 0.8), Color(0.1, 0.4, 0.8), Color(0.8, 0.2, 0.4)]
const NEBULA_RINGS := 6 # stacked circles that fake a soft edge

var scroll := Vector2.ZERO:
	set(v):
		scroll = v
		queue_redraw()

var _stars: Array[Dictionary] = []
var _nebulae: Array[Dictionary] = []
var _time := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345 # same sky every run
	for i in GameConfig.STAR_COUNT:
		var depth := rng.randf()
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"parallax": lerpf(GameConfig.STAR_PARALLAX_MIN, GameConfig.STAR_PARALLAX_MAX, depth * depth),
			"size": lerpf(STAR_SIZE.x, STAR_SIZE.y, depth),
			"phase": rng.randf() * TAU,
			"tint": Color(1, 1, 1).lerp(Color(0.7, 0.8, 1.0), rng.randf()),
		})
	for i in GameConfig.NEBULA_COUNT:
		_nebulae.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(NEBULA_SIZE.x, NEBULA_SIZE.y),
			"color": NEBULA_COLORS[i % NEBULA_COLORS.size()],
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _wrap(p: Vector2, size: Vector2, margin: float) -> Vector2:
	var full := size + Vector2.ONE * margin * 2.0
	return Vector2(fposmod(p.x + margin, full.x), fposmod(p.y + margin, full.y)) - Vector2.ONE * margin


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), GameConfig.COLOR_BG)
	for n in _nebulae:
		var r: float = n.size * size.y
		var p := _wrap(n.pos * size - scroll * NEBULA_PARALLAX, size, r)
		for ring in NEBULA_RINGS:
			var k := 1.0 - float(ring) / NEBULA_RINGS
			draw_circle(p, r * k, Color(n.color, NEBULA_ALPHA))
	for s in _stars:
		var p := _wrap(s.pos * size - scroll * s.parallax, size, s.size)
		var twinkle := 0.7 + 0.3 * sin(_time * GameConfig.STAR_TWINKLE_SPEED + s.phase)
		draw_circle(p, s.size, Color(s.tint, twinkle))
