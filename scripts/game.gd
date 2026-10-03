extends Node
## Autoload "Game": level list, scene switching, best times and ghost saving.

var save_path := GameConfig.SAVE_PATH
var ghost_dir := GameConfig.GHOST_DIR
var _best_times := {}


func _ready() -> void:
	_register_input()
	load_save()


func _register_input() -> void:
	for action: String in GameConfig.INPUT_BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in GameConfig.INPUT_BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


# --- Levels ---

func get_level_paths() -> PackedStringArray:
	var out := PackedStringArray()
	for file in DirAccess.get_files_at(GameConfig.LEVELS_DIR):
		file = file.trim_suffix(".remap") # exported builds rename scenes
		if file.get_extension() == "tscn":
			out.append(GameConfig.LEVELS_DIR.path_join(file))
	out.sort()
	return out


func level_id_from_path(path: String) -> String:
	return path.get_file().get_basename()


func play_level(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func next_level() -> void:
	var paths := get_level_paths()
	var current := get_tree().current_scene.scene_file_path
	var index := paths.find(current)
	if index == -1 or index + 1 >= paths.size():
		go_to_menu()
	else:
		play_level(paths[index + 1])


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(GameConfig.MENU_SCENE)


# --- Saving ---

func load_save() -> void:
	_best_times.clear()
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	if cfg.has_section(GameConfig.SAVE_SECTION):
		for key in cfg.get_section_keys(GameConfig.SAVE_SECTION):
			_best_times[key] = float(cfg.get_value(GameConfig.SAVE_SECTION, key))


func _write_save() -> void:
	var cfg := ConfigFile.new()
	for key: String in _best_times:
		cfg.set_value(GameConfig.SAVE_SECTION, key, _best_times[key])
	cfg.save(save_path)


## Returns -1 when the level has no recorded time.
func get_best_time(level_id: String) -> float:
	return _best_times.get(level_id, -1.0)


## Records a finished run. Returns true when it beats the previous best.
func submit_result(level_id: String, time: float, ghost: GhostData = null) -> bool:
	var best := get_best_time(level_id)
	if best >= 0.0 and time >= best:
		return false
	_best_times[level_id] = time
	_write_save()
	if ghost:
		ghost.total_time = time
		DirAccess.make_dir_recursive_absolute(ghost_dir)
		ResourceSaver.save(ghost, _ghost_path(level_id))
	return true


func load_ghost(level_id: String) -> GhostData:
	var path := _ghost_path(level_id)
	if not FileAccess.file_exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GhostData


func _ghost_path(level_id: String) -> String:
	return ghost_dir.path_join(level_id + ".tres")


static func format_time(t: float) -> String:
	if t < 0.0:
		return "--.--"
	var minutes := int(t) / 60
	var seconds := fmod(t, 60.0)
	if minutes > 0:
		return "%d:%05.2f" % [minutes, seconds]
	return "%.2f" % seconds
