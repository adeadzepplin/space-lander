class_name GameConfig
extends RefCounted
## Central tuning values for the whole game. Change numbers here, not in scripts.

# --- Paths ---
const LEVELS_DIR := "res://levels" # every .tscn here appears in level select, sorted by file name
const MENU_SCENE := "res://scenes/main_menu.tscn"
const SAVE_PATH := "user://save.cfg" # best times
const GHOST_DIR := "user://ghosts" # best-run ghost recordings
const SAVE_SECTION := "best_times" # section name inside the save file

# --- Physics layers (bit values) ---
const LAYER_TERRAIN := 1 # asteroids and pads
const LAYER_LANDER := 2 # the player ship

# --- Lander handling ---
const LANDER_MASS := 1.0 # kg-ish, forces are scaled by this so it only matters for collisions
const LANDER_THRUST := 150.0 # engine acceleration, px/s^2
const LANDER_TURN_SPEED := 3.0 # max rotation rate, rad/s
const LANDER_TURN_ACCEL := 16.0 # how fast rotation reaches max rate, rad/s^2
const LANDER_FUEL_CAPACITY := 100.0 # default tank size, levels can override
const LANDER_FUEL_BURN := 10.0 # fuel used per second at full thrust
const LANDER_FRICTION := 0.9 # grip on surfaces
const LANDER_BOUNCE := 0.05 # springiness of contacts
const LANDER_ANGULAR_DAMP := 2.0 # stops endless tumbling after bumps
const LANDER_MAX_CONTACTS := 8 # contacts tracked for impact checks
const LANDER_THRUST_SMOOTHING := 18.0 # how fast flame/sound follow the throttle, 1/s

# --- Landing rules ---
const SAFE_LANDING_SPEED := 70.0 # max touchdown speed on a pad, px/s
const CRASH_SPEED := 120.0 # impact speed on rock that destroys the ship, px/s
const SAFE_LANDING_ANGLE_DEG := 20.0 # max tilt from pad's up direction to count as landed
const LANDING_REST_SPEED := 12.0 # ship counts as resting below this speed relative to the pad
const LANDING_SETTLE_TIME := 1.0 # seconds resting on the pad to finish the level
const TIP_OVER_ANGLE_DEG := 100.0 # touching ground this far from upright counts as a crash

# --- Asteroids ---
const ASTEROID_DEFAULT_POINTS := 72 # outline resolution
const ASTEROID_NOISE_OCTAVES := 4 # layered sine waves that make the lumpy shape
const ASTEROID_PAD_FLAT_MARGIN := 10.0 # extra flat ground each side of a pad, px
const ASTEROID_PAD_BLEND := 0.25 # radians over which flat ground blends back into rock
const ASTEROID_CRATER_COUNT := 7 # decorative craters per asteroid
const ASTEROID_GRAVITY_RING_DASHES := 64 # dashes in the gravity range indicator

# --- Landing pad ---
const PAD_THICKNESS := 8.0 # plate height above the ground, px
const PAD_LIGHT_BLINK_RATE := 2.0 # blinks per second of the edge lights

# --- Pickups and hazards ---
const PICKUP_RADIUS := 16.0 # touch radius of fuel canisters, px
const PICKUP_BOB_HEIGHT := 4.0 # idle bobbing distance, px
const PICKUP_BOB_SPEED := 2.5 # idle bobbing speed, rad/s
const MINE_RADIUS := 14.0 # touch radius of mines, px
const MINE_SPIKES := 8 # spikes drawn on a mine
const MINE_PULSE_SPEED := 4.0 # warning light pulse speed, rad/s

# --- Ghosts ---
const GHOST_RECORD_TICKS := 2 # record ghost every N physics ticks
const GHOST_ALPHA := 0.35 # ghost transparency

# --- Camera ---
const CAMERA_SMOOTHING := 5.0 # follow speed
const CAMERA_LOOKAHEAD := 0.4 # seconds of velocity the camera leads by
const CAMERA_LOOKAHEAD_MAX := 220.0 # cap on lead distance, px
const CAMERA_SHAKE_STRENGTH := 16.0 # crash shake size, px
const CAMERA_SHAKE_DECAY := 2.5 # how fast shake fades, 1/s

# --- Trajectory preview ---
const TRAJECTORY_STEPS := 90 # predicted points drawn ahead of the ship
const TRAJECTORY_STEP_TIME := 0.06 # seconds between predicted points
const TRAJECTORY_ALPHA := 0.45 # brightness of the nearest predicted dot

# --- Effects ---
const FLAME_LENGTH := 26.0 # full-throttle flame length, px
const EXPLOSION_PARTICLES := 90 # sparks in a crash
const EXPLOSION_SPEED := 260.0 # max spark speed, px/s
const EXPLOSION_LIFETIME := 1.6 # seconds sparks last
const EXPLOSION_DRAG := 0.3 # fraction of spark speed lost per second
const EXPLOSION_SIZE := Vector2(1.5, 4.0) # min/max spark size
const THRUST_PARTICLES := 40 # exhaust particles alive at once
const THRUST_PARTICLE_LIFETIME := 0.5 # seconds exhaust lasts
const THRUST_PARTICLE_SPEED := Vector2(120.0, 200.0) # min/max exhaust speed, px/s
const THRUST_PARTICLE_SPREAD := 12.0 # exhaust cone half-angle, degrees
const THRUST_PARTICLE_SIZE := Vector2(1.0, 3.0) # min/max exhaust size
const HDR_GLOW := 1.8 # brightness multiplier on glowing colors (>1 triggers bloom)

# --- Audio ---
const AUDIO_MIX_RATE := 22050.0 # synthesized sound sample rate
const AUDIO_BUFFER := 0.1 # seconds of audio buffered
const ENGINE_VOLUME := 0.35 # engine rumble loudness 0..1
const ENGINE_LOWPASS := 0.08 # rumble filter, lower = deeper
const BOOM_VOLUME := 0.9 # crash noise loudness 0..1
const BOOM_DECAY := 2.2 # crash noise fade speed, 1/s

# --- Starfield ---
const STAR_COUNT := 260 # background stars
const STAR_PARALLAX_MIN := 0.02 # far star scroll factor
const STAR_PARALLAX_MAX := 0.25 # near star scroll factor
const STAR_TWINKLE_SPEED := 1.5 # twinkle speed, rad/s
const NEBULA_COUNT := 6 # soft colored clouds behind the stars
const MENU_DRIFT_SPEED := Vector2(12.0, 4.0) # menu background scroll, px/s

# --- Colors ---
const COLOR_BG := Color(0.02, 0.02, 0.05)
const COLOR_HULL := Color(0.85, 0.87, 0.92)
const COLOR_HULL_ACCENT := Color(0.95, 0.55, 0.15)
const COLOR_WINDOW := Color(0.3, 0.8, 1.0)
const COLOR_FLAME_CORE := Color(1.0, 0.95, 0.7)
const COLOR_FLAME_OUTER := Color(1.0, 0.45, 0.1)
const COLOR_GHOST := Color(0.4, 0.9, 1.0)
const COLOR_ROCK := Color(0.32, 0.29, 0.27)
const COLOR_ROCK_EDGE := Color(0.55, 0.5, 0.45)
const COLOR_CRATER := Color(0.22, 0.2, 0.19)
const COLOR_GRAVITY_RING := Color(0.5, 0.6, 1.0, 0.12)
const COLOR_PAD := Color(0.6, 0.62, 0.66)
const COLOR_PAD_LIGHT := Color(0.2, 1.0, 0.4)
const COLOR_FUEL := Color(1.0, 0.8, 0.2)
const COLOR_MINE := Color(0.8, 0.15, 0.15)
const COLOR_UI := Color(0.85, 0.9, 1.0)
const COLOR_UI_DIM := Color(0.55, 0.6, 0.7)
const COLOR_GOOD := Color(0.3, 1.0, 0.5)
const COLOR_WARN := Color(1.0, 0.8, 0.2)
const COLOR_BAD := Color(1.0, 0.3, 0.3)
const COLOR_PANEL := Color(0.05, 0.07, 0.12, 0.75)

# --- UI ---
const FONT_SMALL := 16 # readouts
const FONT_MEDIUM := 22 # labels and buttons
const FONT_LARGE := 40 # result messages
const FONT_TITLE := 72 # menu title
const UI_MARGIN := 20 # screen-edge padding, px
const PAD_ARROW_MARGIN := 40 # off-screen pad arrow distance from edge, px
const PAD_ARROW_SIZE := 14.0 # off-screen pad arrow size, px

# --- Input (action -> physical keys). Added at startup unless already defined in the project. ---
const INPUT_BINDINGS := {
	"thrust": [KEY_W, KEY_UP, KEY_SPACE],
	"rotate_left": [KEY_A, KEY_LEFT],
	"rotate_right": [KEY_D, KEY_RIGHT],
	"restart": [KEY_R],
	"next_level": [KEY_ENTER, KEY_N],
	"pause": [KEY_ESCAPE, KEY_P],
}
