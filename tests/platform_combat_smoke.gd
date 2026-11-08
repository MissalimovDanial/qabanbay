extends SceneTree
## Isolated setup exercises collision and combat boundaries, separate from input-only campaign.
const DT := 1.0 / 60.0
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func spawn_game(chapter := 1):
 var game = load("res://scenes/%s.tscn" % ("main" if chapter == 1 else "level_two")).instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.audio.enabled = false
 game._restart(false)
 game.training_stage = 6
 return game
func step(game, frames: int) -> void:
 for i in range(frames):
  game._tick(DT)
func run() -> void:
 var save := ConfigFile.new()
 save.set_value("level1", "completed", true)
 save.save("user://level_one.cfg")
 var game = spawn_game()
 game.route_gaps = []
 game.route_platforms = []
 game.route_rocks = [Rect2(600,490,110,60)]
 game.hero=Vector2(570,550)
 for i in range(60):
  game._move_hero(DT,390)
 check(game.hero.x>710 and game.hero.y==550,"Scenic rocks do not block running")
 game.route_rocks = []
 game.route_platforms = [Rect2(450,350,120,24)]
 game.hero = Vector2(510,280)
 game.vertical_speed = 0
 game.grounded = false
 for i in range(60):
  game._move_hero(DT,0)
 check(absf(game.hero.y - 350) < 0.01 and game.grounded, "Floating platform supports hero")
 game.hero = Vector2(510,550)
 game.vertical_speed = -690
 game.grounded = true
 var blocked_head := false
 for i in range(30):
  game._move_hero(DT,0)
  blocked_head = blocked_head or (absf(game.hero.y - 470) < 0.01 and game.vertical_speed == 0)
  check(game.hero.y - 96 >= 373.9, "Hero head cannot tunnel through platform underside")
 check(blocked_head, "Platform underside cancels upward jump")
 game._restart(false)
 game.training_stage = 6
 game.hero.x = 180
 game._refresh_ui()
 check(game.npc_bubble.visible and game.npc_text.text.contains("Старейшина"), "Elder starts talking before hero passes")
 var first_line: String = game.npc_text.text
 game.elapsed = 5
 game._refresh_ui()
 check(game.npc_bubble.visible and game.npc_text.text != first_line, "Elder cycles helpful lines while hero stays nearby")
 game.hero.x = game._elder_x() + 85
 step(game,1)
 game._refresh_ui()
 check(game.npc_passed and not game.npc_bubble.visible, "Elder finishes speaking after hero passes")
 game.hero.x = 180
 game._refresh_ui()
 check(not game.npc_bubble.visible, "Elder conversation does not restart when walking back")
 game._restart(false)
 game.training_stage = 6
 game.route_platforms = []
 game.route_rocks = []
 game.route_gaps = [Vector2(600,800)]
 game.hero = Vector2(700,550)
 game.vertical_speed = 0
 game.grounded = false
 for i in range(120):
  if game.phase != game.Phase.EXPLORE:
   break
  game._move_hero(DT,0)
 check(game.phase == game.Phase.LOST and game.deaths == 1, "Ravine has no invisible floor and falling causes retry")
 game._advance()
 check(game.phase == game.Phase.EXPLORE and game.hero.x == 180 and game.hp == game.MAX_HP, "Ravine retry restores route start")
 game.phase = game.Phase.FIGHT
 game.hero = Vector2(4300,550)
 game.facing = 1
 game.boar = Vector2(4650,550)
 game.boar_hp = 5
 game.boar_state = "windup"
 game.attack_timer = 0.0
 game._attack()
 game.attack_timer = 0.20
 game._resolve_attack()
 check(game.boar_hp == 5, "Out-of-reach swing does not hit")
 game.boar.x = 4420
 game._resolve_attack()
 check(game.boar_hp == 4 and game.swing_hits.has("boss"), "Target entering reach during active swing is hit even during windup")
 for i in range(20):
  game._resolve_attack()
 check(game.boar_hp == 4, "One swing cannot hit same boss repeatedly")
 game.attack_timer = 0.0
 game._attack()
 game.attack_timer = 0.20
 game._resolve_attack()
 check(game.boar_hp == 3, "Next connecting swing always counts")
 game.boar.x = 4180
 game.attack_timer = 0.0
 game._attack()
 game.attack_timer = 0.20
 game._resolve_attack()
 check(game.boar_hp == 3, "Spear misses enemy behind hero")
 game.queue_free()
 await process_frame
 var guards_game = spawn_game(2)
 var guard: Dictionary = guards_game.guards[0]
 guards_game.hero = Vector2(guard.x - 115,550)
 guards_game.facing = 1
 guard.state = "windup"
 var guard_hp: int = guard.hp
 guards_game._attack()
 guards_game.attack_timer = 0.20
 guards_game._resolve_attack()
 check(guard.hp == guard_hp-1, "Connecting swing counts against guard during preparation")
 guards_game._resolve_attack()
 check(guard.hp == guard_hp-1, "Guard receives one hit per swing")
 guards_game.queue_free()
 print("Platforms and combat: ", checks, " checks, ", failures, " failures")
 quit(1 if failures else 0)
