extends Node
## Headless test suite. Run from the project folder:
##   <godot_console.exe> --headless --fixed-fps 60 --path . res://tests/test_runner.tscn
## Exit code is the number of failed tests.

var _failures := 0
var _real_save := ""
var _real_ghosts := ""


func _ready() -> void:
	_real_save = Game.save_path
	_real_ghosts = Game.ghost_dir
	Game.save_path = TestConfig.SAVE_PATH
	Game.ghost_dir = TestConfig.GHOST_DIR
	_cleanup_files()
	Game.load_save()

	for test in [
		_test_ghost_sampling,
		_test_best_time_only_improves,
		_test_all_levels_valid,
		_test_gravity_matches_prediction,
		_test_thrust_and_fuel,
		_test_soft_landing,
		_test_hard_pad_impact,
		_test_rock_impact,
		_test_spinning_pad_landing,
		_test_mine_destroys_ship,
		_test_fuel_pickup,
	]:
		await test.call()

	_cleanup_files()
	Game.save_path = _real_save
	Game.ghost_dir = _real_ghosts
	print("\n%s: %d failure(s)" % ["FAILED" if _failures else "ALL PASSED", _failures])
	get_tree().quit(_failures)


func _check(ok: bool, name: String, detail: String = "") -> void:
	print("%s  %s  %s" % ["PASS" if ok else "FAIL", name, detail])
	if not ok:
		_failures += 1


func _cleanup_files() -> void:
	if FileAccess.file_exists(TestConfig.SAVE_PATH):
		DirAccess.remove_absolute(TestConfig.SAVE_PATH)
	if DirAccess.dir_exists_absolute(TestConfig.GHOST_DIR):
		for f in DirAccess.get_files_at(TestConfig.GHOST_DIR):
			DirAccess.remove_absolute(TestConfig.GHOST_DIR.path_join(f))
		DirAccess.remove_absolute(TestConfig.GHOST_DIR)


func _make_level(path: String) -> Level:
	var level: Level = load(path).instantiate()
	level.player_controlled = false
	add_child(level)
	await get_tree().physics_frame
	return level


func _free_level(level: Level) -> void:
	level.queue_free()
	await get_tree().process_frame


func _ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Waits until the level leaves FLYING or the tick budget runs out.
func _wait_for_result(level: Level) -> void:
	for i in TestConfig.MAX_WAIT_TICKS:
		if level.state != Level.State.FLYING:
			return
		await get_tree().physics_frame


func _place_on_pad(level: Level, pad: LandingPad, height: float) -> void:
	var lander := level.lander
	lander.global_rotation = pad.global_rotation
	lander.global_position = pad.get_top_center() + pad.get_up() * (lander.get_foot_offset() + height)


# --- Tests ---

func _test_ghost_sampling() -> void:
	var g := GhostData.new()
	g.interval = TestConfig.GHOST_INTERVAL
	for p in TestConfig.GHOST_POINTS:
		g.add_sample(p, 0.0, 0.0)
	var f := TestConfig.GHOST_QUERY_FRACTION
	var got: Vector2 = g.sample(TestConfig.GHOST_INTERVAL * f).position
	var want: Vector2 = TestConfig.GHOST_POINTS[0].lerp(TestConfig.GHOST_POINTS[1], f)
	_check(got.is_equal_approx(want), "ghost interpolation", "got %s want %s" % [got, want])
	var past_end: Vector2 = g.sample(TestConfig.GHOST_INTERVAL * 10.0).position
	_check(past_end.is_equal_approx(TestConfig.GHOST_POINTS[-1]), "ghost clamps after end", str(past_end))


func _test_best_time_only_improves() -> void:
	var id := TestConfig.BEST_TIME_LEVEL_ID
	var results := []
	for t in TestConfig.BEST_TIMES:
		results.append(Game.submit_result(id, t))
	_check(results == TestConfig.BEST_TIMES_EXPECT_NEW, "best time only improves", str(results))
	var best := Game.get_best_time(id)
	Game.load_save() # must survive a reload from disk
	_check(is_equal_approx(Game.get_best_time(id), best) and is_equal_approx(best, TestConfig.BEST_TIMES.min()),
		"best time saved to disk", "best %.2f" % best)


func _test_all_levels_valid() -> void:
	var paths := Game.get_level_paths()
	_check(paths.size() > 0, "levels found", str(paths.size()))
	for path in paths:
		var level := await _make_level(path)
		var problems := []
		if level.get_node_or_null("Spawn") == null:
			problems.append("no Spawn")
		if level.pads.is_empty():
			problems.append("no LandingPad")
		if level.is_point_in_rock(level.lander.global_position):
			problems.append("spawn inside rock")
		for pad in level.pads:
			if not pad.get_parent() is Asteroid:
				problems.append("pad %s not on an asteroid" % pad.name)
			elif level.is_point_in_rock(pad.get_top_center() + pad.get_up()):
				problems.append("rock covers pad %s" % pad.name)
			if level.get_gravity_at(pad.global_position) == Vector2.ZERO:
				problems.append("pad %s has no gravity" % pad.name)
		_check(problems.is_empty(), "level valid " + path.get_file(), ", ".join(problems))
		await _free_level(level)


func _test_gravity_matches_prediction() -> void:
	var level := await _make_level(TestConfig.LANDING_LEVEL)
	var rock: Asteroid = level.asteroids[0]
	var lander := level.lander
	lander.global_position = rock.global_position + Vector2.LEFT * TestConfig.GRAVITY_TEST_DISTANCE
	var expected := level.get_gravity_at(lander.global_position)
	level.start()
	await _ticks(TestConfig.GRAVITY_TEST_TICKS)
	var seconds := float(TestConfig.GRAVITY_TEST_TICKS) / Engine.physics_ticks_per_second
	var measured := lander.linear_velocity / seconds
	var err := (measured - expected).length() / expected.length()
	_check(err < TestConfig.GRAVITY_TOLERANCE, "gravity matches Asteroid.gravity_at",
		"measured %s expected %s err %.1f%%" % [measured, expected, err * 100.0])
	await _free_level(level)


func _test_thrust_and_fuel() -> void:
	var level := await _make_level(TestConfig.LANDING_LEVEL)
	var lander := level.lander
	lander.global_position += TestConfig.THRUST_TEST_OFFSET
	_check(level.get_gravity_at(lander.global_position) == Vector2.ZERO, "thrust test is outside gravity")
	level.start()
	lander.thrust_input = 1.0
	await _ticks(TestConfig.THRUST_TEST_TICKS)
	lander.thrust_input = 0.0
	var seconds := float(TestConfig.THRUST_TEST_TICKS) / Engine.physics_ticks_per_second
	var want_speed := GameConfig.LANDER_THRUST * seconds
	var got_speed := lander.linear_velocity.dot(lander.get_up())
	_check(absf(got_speed - want_speed) / want_speed < TestConfig.THRUST_TOLERANCE, "thrust acceleration",
		"speed %.1f want %.1f" % [got_speed, want_speed])
	var want_burn := GameConfig.LANDER_FUEL_BURN * seconds
	var got_burn := lander.fuel_capacity - lander.fuel
	_check(absf(got_burn - want_burn) / want_burn < TestConfig.THRUST_TOLERANCE, "fuel burn",
		"burned %.2f want %.2f" % [got_burn, want_burn])
	# Empty tank: engine must do nothing.
	lander.fuel = 0.0
	lander.thrust_input = 1.0
	await _ticks(1) # let the last fueled physics step finish
	var v_before := lander.linear_velocity
	await _ticks(TestConfig.THRUST_TEST_TICKS)
	_check(lander.linear_velocity.is_equal_approx(v_before), "no thrust without fuel", str(lander.linear_velocity))
	await _free_level(level)


func _test_soft_landing() -> void:
	var level := await _make_level(TestConfig.LANDING_LEVEL)
	_place_on_pad(level, level.pads[0], TestConfig.SOFT_DROP_HEIGHT)
	level.start()
	await _wait_for_result(level)
	_check(level.state == Level.State.LANDED, "soft landing completes level",
		"state %s %s" % [Level.State.keys()[level.state], level.hud.crash_reason])
	_check(Game.get_best_time(level.level_id) > 0.0, "landing records best time",
		Game.format_time(Game.get_best_time(level.level_id)))
	var ghost := Game.load_ghost(level.level_id)
	_check(ghost != null and ghost.sample_count() > 1 and is_equal_approx(ghost.total_time, level.elapsed),
		"landing saves ghost", "samples %d" % (ghost.sample_count() if ghost else 0))
	await _free_level(level)
	# A replay of the level should load that ghost.
	level = await _make_level(TestConfig.LANDING_LEVEL)
	_check(level.ghost != null, "ghost appears on retry")
	await _free_level(level)


func _test_hard_pad_impact() -> void:
	var level := await _make_level(TestConfig.LANDING_LEVEL)
	var pad := level.pads[0]
	_place_on_pad(level, pad, TestConfig.SOFT_DROP_HEIGHT)
	level.start()
	level.lander.linear_velocity = -pad.get_up() * TestConfig.HARD_IMPACT_SPEED
	await _wait_for_result(level)
	_check(level.state == Level.State.CRASHED, "hard pad impact crashes", level.hud.crash_reason)
	await _free_level(level)


func _test_rock_impact() -> void:
	var level := await _make_level(TestConfig.LANDING_LEVEL)
	var rock: Asteroid = level.asteroids[0]
	var dir := Vector2.from_angle(deg_to_rad(TestConfig.ROCK_TEST_ANGLE_DEG))
	var lander := level.lander
	lander.global_position = rock.global_position + dir * (rock.radius * (1.0 + rock.roughness) + TestConfig.ROCK_TEST_ALTITUDE)
	lander.global_rotation = dir.angle() + PI * 0.5 # feet toward the rock
	level.start()
	lander.linear_velocity = -dir * TestConfig.ROCK_IMPACT_SPEED
	await _wait_for_result(level)
	_check(level.state == Level.State.CRASHED, "fast rock impact crashes", level.hud.crash_reason)
	await _free_level(level)


func _test_spinning_pad_landing() -> void:
	var level := await _make_level(TestConfig.SPIN_LEVEL)
	var pad := level.pads[0]
	var rock := pad.get_parent() as Asteroid
	_place_on_pad(level, pad, TestConfig.SOFT_DROP_HEIGHT)
	level.start()
	# Match the pad's sideways motion like a player would.
	var arm := level.lander.global_position - rock.global_position
	level.lander.linear_velocity = arm.rotated(PI * 0.5) * deg_to_rad(rock.spin_speed)
	await _wait_for_result(level)
	_check(level.state == Level.State.LANDED, "landing on spinning asteroid",
		"state %s %s" % [Level.State.keys()[level.state], level.hud.crash_reason])
	await _free_level(level)


func _test_mine_destroys_ship() -> void:
	var level := await _make_level(TestConfig.MINE_LEVEL)
	level.lander.global_position = level.get_node(TestConfig.MINE_NODE).global_position
	level.start()
	await _wait_for_result(level)
	_check(level.state == Level.State.CRASHED, "mine destroys ship", level.hud.crash_reason)
	await _free_level(level)


func _test_fuel_pickup() -> void:
	var level := await _make_level(TestConfig.MINE_LEVEL)
	var pickup: FuelPickup = level.get_node(TestConfig.PICKUP_NODE)
	var lander := level.lander
	lander.fuel = 0.0
	var want := minf(pickup.amount, lander.fuel_capacity)
	lander.global_position = pickup.global_position
	level.start()
	await _ticks(TestConfig.PICKUP_WAIT_TICKS)
	_check(is_equal_approx(lander.fuel, want), "fuel pickup refuels", "fuel %.1f want %.1f" % [lander.fuel, want])
	await _free_level(level)
