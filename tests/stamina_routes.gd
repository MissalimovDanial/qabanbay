extends SceneTree

const DT := 1.0 / 60.0

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 for scene in ["main", "level_two", "level_three", "level_four", "level_five"]:
  var game = load("res://scenes/" + scene + ".tscn").instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game.audio.enabled = false
  game._restart(false)
  game.training_stage = 6
  game.stamina = 1.0
  game.touch_actions = {"run": true, "right": true}
  for frame in range(20):
   game._tick(DT)
  assert(game.exhausted and game.stamina < game.STAMINA_RESUME)
  var walk_start: float = game.hero.x
  game._tick(DT)
  var walk_speed: float = 235.0 if game._is_mounted() else game.SPEED
  assert(absf(game.hero.x - walk_start - walk_speed * DT) < 0.05)
  game.touch_actions = {"run": true}
  for frame in range(900):
   game._tick(DT)
  assert(is_equal_approx(game.stamina, game.MAX_STAMINA) and not game.exhausted)
  game._refresh_ui()
  assert(game.player_hud.visible and game.player_hud.stamina_percent == 100)
  game._step_stride(5.0, 100.0, true, true)
  assert(is_equal_approx(game.stamina, 80.0), "One lightning bolt lasts five running seconds")
  game._step_stride(3.0, 0.0, false, true)
  assert(is_equal_approx(game.stamina, 100.0), "One lightning bolt returns in three seconds")

  assert(game.route_supplies.size() == 2)
  var low: Vector2 = game.route_supplies[0]
  game.hero = Vector2(low.x, game.FLOOR_Y)
  game.hp = 4
  game.stamina = 20.0
  game._pickups()
  assert(game.collected_supplies.has(0) and game.hp == 5 and game.stamina == 100.0)
  game._pickups()
  assert(game.hp == 5, "Each flask is collected once")

  var high: Vector2 = game.route_supplies[1]
  var wind = game.wind_trial
  assert(wind.ground_course and game.route_platforms.is_empty())
  var track: Rect2 = wind._route_ledge(game.route_platforms)
  var start: Vector2 = wind._mark(0, track)
  wind.step(start, game.route_platforms, DT)
  assert(wind.progress == 1 and wind.seconds_left == 12.0)
  assert(wind.step(start, game.route_platforms, 12.0) == wind.Result.EXPIRED)
  wind.step(start, game.route_platforms, DT)
  assert(wind.progress == 0, "An expired trial waits for the player to leave the start marker")
  wind.step(start - Vector2(65, 0), game.route_platforms, DT)
  wind.step(start, game.route_platforms, DT)
  wind.step(wind._mark(1, track), game.route_platforms, DT)
  assert(wind.progress == 2)

  game.hero = Vector2(high.x - 80.0, game.FLOOR_Y)
  game.grounded = true
  game.vertical_speed = 0.0
  for frame in range(60):
   game._move_hero(DT, walk_speed if game.hero.x < high.x + 44.0 else 0.0)
   game._pickups()
   wind.step(game.hero, game.route_platforms, DT)
  assert(game.collected_supplies.has(1), "The second flask is reachable from the trail")
  assert(wind.progress == wind.MARKS and wind.seconds_left == 0.0)
  assert(wind.step(game.hero, game.route_platforms, DT) == wind.Result.NONE)
  game.free()
 print("Stamina, supplies and the complete wind trial passed in all five chapters")
 quit()
