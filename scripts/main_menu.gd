extends Control
## Title screen with a level list built from every scene in GameConfig.LEVELS_DIR.

const LIST_MAX_HEIGHT := 360 # level list scrolls beyond this, px

var _starfield: Starfield
var _drift := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = -100 # behind the menu
	_starfield = Starfield.new()
	layer.add_child(_starfield)
	add_child(layer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", GameConfig.UI_MARGIN)
	center.add_child(box)

	var title := UiStyle.label("SPACE LANDER", GameConfig.FONT_TITLE, GameConfig.COLOR_HULL_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UiStyle.label("Land on the pad. Beat your ghost.", GameConfig.FONT_MEDIUM, GameConfig.COLOR_UI_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = LIST_MAX_HEIGHT
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", GameConfig.UI_MARGIN / 2)
	scroll.add_child(list)

	var first: Button
	var paths := Game.get_level_paths()
	for i in paths.size():
		var path := paths[i]
		var b := UiStyle.button("%d.  %s      best %s" % [i + 1, _level_name(path), Game.format_time(Game.get_best_time(Game.level_id_from_path(path)))])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(Game.play_level.bind(path))
		list.add_child(b)
		if first == null:
			first = b

	var help := UiStyle.label("W/Up/Space thrust    A/D rotate    R restart    Esc pause",
		GameConfig.FONT_SMALL, GameConfig.COLOR_UI_DIM)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)
	var quit := UiStyle.button("Quit")
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(get_tree().quit)
	box.add_child(quit)
	if first:
		first.grab_focus.call_deferred()


func _level_name(path: String) -> String:
	var scene := load(path) as PackedScene
	var level := scene.instantiate()
	var n: String = level.level_name if "level_name" in level else path.get_file().get_basename()
	level.free()
	return n


func _process(delta: float) -> void:
	_drift += GameConfig.MENU_DRIFT_SPEED * delta
	_starfield.scroll = _drift
