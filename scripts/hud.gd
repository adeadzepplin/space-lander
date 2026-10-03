class_name Hud
extends CanvasLayer
## In-level overlay: timer, fuel, flight readouts, result messages, pad arrow and pause menu.

const FUEL_BAR_WIDTH := 220 # px
const FUEL_LOW := 0.25 # fraction of tank that shows the low-fuel warning
const READOUT_WIDTH := 170 # fixed label width so numbers don't jiggle, px
const WARN_BLINK_RATE := 3.0 # low fuel blinks per second

var level: Level
var crash_reason := ""

var _time_label: Label
var _best_label: Label
var _fuel_bar: ProgressBar
var _fuel_label: Label
var _speed_label: Label
var _tilt_label: Label
var _land_bar: ProgressBar
var _title: Label
var _subtitle: Label
var _arrow: Control
var _pause: Control
var _clock := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_arrow(root)
	_build_top_left(root)
	_build_top_right(root)
	_build_bottom(root)
	_build_message(root)
	_build_pause(root)
	level.state_changed.connect(_on_state_changed)
	_on_state_changed(level.state)


func _build_top_left(root: Control) -> void:
	var p := UiStyle.panel()
	p.position = Vector2.ONE * GameConfig.UI_MARGIN
	var box := VBoxContainer.new()
	p.add_child(box)
	box.add_child(UiStyle.label(level.level_name.to_upper(), GameConfig.FONT_SMALL, GameConfig.COLOR_UI_DIM))
	_time_label = UiStyle.label("", GameConfig.FONT_LARGE)
	box.add_child(_time_label)
	_best_label = UiStyle.label("", GameConfig.FONT_SMALL, GameConfig.COLOR_UI_DIM)
	box.add_child(_best_label)
	root.add_child(p)


func _build_top_right(root: Control) -> void:
	var p := UiStyle.panel()
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var box := VBoxContainer.new()
	p.add_child(box)
	_fuel_label = UiStyle.label("FUEL", GameConfig.FONT_SMALL)
	box.add_child(_fuel_label)
	_fuel_bar = UiStyle.bar(GameConfig.COLOR_FUEL)
	_fuel_bar.custom_minimum_size.x = FUEL_BAR_WIDTH
	box.add_child(_fuel_bar)
	root.add_child(p)
	p.offset_left = -GameConfig.UI_MARGIN - FUEL_BAR_WIDTH - UiStyle.PANEL_PADDING * 2
	p.offset_right = -GameConfig.UI_MARGIN
	p.offset_top = GameConfig.UI_MARGIN


func _build_bottom(root: Control) -> void:
	var p := UiStyle.panel()
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_bottom = -GameConfig.UI_MARGIN
	var box := VBoxContainer.new()
	p.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	_speed_label = UiStyle.label("", GameConfig.FONT_SMALL)
	_speed_label.custom_minimum_size.x = READOUT_WIDTH
	row.add_child(_speed_label)
	_tilt_label = UiStyle.label("", GameConfig.FONT_SMALL)
	_tilt_label.custom_minimum_size.x = READOUT_WIDTH
	row.add_child(_tilt_label)
	_land_bar = UiStyle.bar(GameConfig.COLOR_GOOD)
	box.add_child(_land_bar)
	root.add_child(p)


func _build_message(root: Control) -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = UiStyle.label("", GameConfig.FONT_LARGE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_subtitle = UiStyle.label("", GameConfig.FONT_MEDIUM, GameConfig.COLOR_UI_DIM)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)
	root.add_child(box)
	box.position.y -= GameConfig.FONT_LARGE * 3 # sit above the ship


func _build_arrow(root: Control) -> void:
	_arrow = Control.new()
	_arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_draw_pad_arrow)
	root.add_child(_arrow)


func _build_pause(root: Control) -> void:
	_pause = ColorRect.new()
	(_pause as ColorRect).color = Color(0, 0, 0, 0.6)
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", GameConfig.UI_MARGIN / 2)
	center.add_child(box)
	var title := UiStyle.label("PAUSED", GameConfig.FONT_LARGE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var resume := UiStyle.button("Resume")
	resume.pressed.connect(toggle_pause)
	box.add_child(resume)
	var restart := UiStyle.button("Restart")
	restart.pressed.connect(Game.restart_level)
	box.add_child(restart)
	var menu := UiStyle.button("Main Menu")
	menu.pressed.connect(Game.go_to_menu)
	box.add_child(menu)
	_pause.visible = false
	root.add_child(_pause)


func _unhandled_input(event: InputEvent) -> void:
	# The level is frozen while paused, so the HUD handles unpausing.
	if get_tree().paused and event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_pause.visible = paused
	if paused:
		(_pause.find_children("*", "Button", true, false)[0] as Button).grab_focus()


func _on_state_changed(state: Level.State) -> void:
	match state:
		Level.State.READY:
			_title.text = "PRESS THRUST TO LAUNCH"
			_subtitle.text = level.briefing if level.briefing != "" else "W / Up / Space to thrust   A D to rotate"
		Level.State.FLYING:
			_title.text = ""
			_subtitle.text = ""
		Level.State.LANDED:
			_title.text = "LANDED  %s" % Game.format_time(level.elapsed)
			_title.add_theme_color_override("font_color", GameConfig.COLOR_GOOD)
			_subtitle.text = ("NEW RECORD!   " if level.new_record else "") + "Enter: next level    R: retry"
		Level.State.CRASHED:
			_title.text = crash_reason.to_upper()
			_title.add_theme_color_override("font_color", GameConfig.COLOR_BAD)
			_subtitle.text = "R: retry    Esc: pause menu"


func _process(delta: float) -> void:
	_clock += delta
	var lander := level.lander
	_time_label.text = Game.format_time(level.elapsed)
	_best_label.text = "BEST  " + Game.format_time(level.best_time) + ("   GHOST" if level.ghost else "")
	var fuel_frac := lander.fuel / lander.fuel_capacity if lander.fuel_capacity > 0.0 else 0.0
	_fuel_bar.value = fuel_frac
	var low := fuel_frac < FUEL_LOW
	var blink := fmod(_clock * WARN_BLINK_RATE, 1.0) < 0.5
	_fuel_label.text = ("FUEL LOW" if low else "FUEL") if lander.fuel > 0.0 else "OUT OF FUEL"
	_fuel_label.modulate = GameConfig.COLOR_BAD if low and blink else Color.WHITE

	var speed := lander.linear_velocity.length()
	_speed_label.text = "SPEED  %d" % speed
	_speed_label.modulate = _limit_color(speed, GameConfig.SAFE_LANDING_SPEED)
	var gravity := level.get_gravity_at(lander.global_position)
	if gravity.length() > 0.0:
		var tilt := absf(rad_to_deg(lander.get_up().angle_to(-gravity)))
		_tilt_label.text = "TILT  %d°" % tilt
		_tilt_label.modulate = _limit_color(tilt, GameConfig.SAFE_LANDING_ANGLE_DEG)
	else:
		_tilt_label.text = "TILT  --"
		_tilt_label.modulate = Color.WHITE
	_land_bar.value = lander.landing_progress
	_land_bar.modulate.a = 1.0 if lander.landing_progress > 0.0 else 0.25
	_arrow.queue_redraw()


func _limit_color(value: float, limit: float) -> Color:
	if value <= limit:
		return GameConfig.COLOR_GOOD
	return GameConfig.COLOR_WARN if value <= limit * 1.5 else GameConfig.COLOR_BAD


func _draw_pad_arrow() -> void:
	var pad := level.nearest_pad(level.lander.global_position)
	if pad == null or level.state == Level.State.LANDED:
		return
	var screen := _arrow.get_viewport_rect().size
	var pad_screen := _arrow.get_viewport().get_canvas_transform() * pad.global_position
	var m := float(GameConfig.PAD_ARROW_MARGIN)
	if Rect2(Vector2.ZERO, screen).grow(-m).has_point(pad_screen):
		return
	var center := screen * 0.5
	var dir := (pad_screen - center).normalized()
	var half := center - Vector2.ONE * m
	var scale_to_edge := minf(absf(half.x / dir.x) if dir.x != 0.0 else INF, absf(half.y / dir.y) if dir.y != 0.0 else INF)
	var tip := center + dir * scale_to_edge
	var s := GameConfig.PAD_ARROW_SIZE
	var side := dir.orthogonal()
	_arrow.draw_colored_polygon(PackedVector2Array([tip + dir * s, tip - dir * s + side * s, tip - dir * s - side * s]),
		GameConfig.COLOR_PAD_LIGHT)
	var dist := level.lander.global_position.distance_to(pad.global_position)
	_arrow.draw_string(ThemeDB.fallback_font, tip - dir * s * 3.0 - Vector2(s * 1.5, 0), "%d" % dist,
		HORIZONTAL_ALIGNMENT_LEFT, -1, GameConfig.FONT_SMALL, GameConfig.COLOR_PAD_LIGHT)
