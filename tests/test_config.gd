class_name TestConfig
extends RefCounted
## Values used by tests/test_runner.gd.

# Separate save locations so tests never touch real best times. Deleted after the run.
const SAVE_PATH := "user://test_save.cfg"
const GHOST_DIR := "user://test_ghosts"

# Levels used by specific tests.
const LANDING_LEVEL := "res://levels/level_01.tscn" # static pad
const SPIN_LEVEL := "res://levels/level_03.tscn" # pad on a rotating asteroid
const MINE_LEVEL := "res://levels/level_04.tscn" # has mines
const MINE_NODE := "Mine1" # mine the ship is dropped onto
const PICKUP_NODE := "Fuel" # fuel canister in MINE_LEVEL
const PICKUP_WAIT_TICKS := 3 # physics ticks for the area overlap to register

# Landing tests.
const SOFT_DROP_HEIGHT := 15.0 # px above the pad for a gentle touchdown
const HARD_IMPACT_SPEED := 200.0 # px/s into the pad, above GameConfig.SAFE_LANDING_SPEED
const MAX_WAIT_TICKS := 600 # give up waiting for a landing/crash after this many physics ticks

# Rock crash test: ship fired at the asteroid's side, away from the pad.
const ROCK_TEST_ANGLE_DEG := 0.0 # direction from asteroid center (0 = right side)
const ROCK_TEST_ALTITUDE := 80.0 # px above the average surface radius
const ROCK_IMPACT_SPEED := 250.0 # px/s toward the rock, above GameConfig.CRASH_SPEED

# Gravity test: free fall measured against Asteroid.gravity_at.
const GRAVITY_TEST_DISTANCE := 500.0 # px from asteroid center
const GRAVITY_TEST_TICKS := 30 # physics ticks of free fall
const GRAVITY_TOLERANCE := 0.05 # allowed relative error

# Engine test: full thrust far from any gravity.
const THRUST_TEST_OFFSET := Vector2(0, -1500) # from Spawn, outside every gravity range
const THRUST_TEST_TICKS := 60 # physics ticks of full thrust
const THRUST_TOLERANCE := 0.05 # allowed relative error on speed and fuel use

# Best-time bookkeeping: submitted in order, expected "is new record" for each.
const BEST_TIME_LEVEL_ID := "test_level"
const BEST_TIMES := [10.0, 12.0, 8.0]
const BEST_TIMES_EXPECT_NEW := [true, false, true]

# Ghost interpolation: two samples, queried halfway between.
const GHOST_INTERVAL := 0.5 # seconds between the two samples
const GHOST_POINTS := [Vector2(0, 0), Vector2(10, 20)]
const GHOST_QUERY_FRACTION := 0.5 # query time as a fraction of GHOST_INTERVAL
