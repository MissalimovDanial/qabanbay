extends SceneTree
const SCENES := ["main", "level_two", "level_three", "level_four", "level_five"]
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/campaign_map.tscn", "F5 starts the campaign map")
 for i in range(SCENES.size()):
  var game = load("res://scenes/%s.tscn" % SCENES[i]).instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game.audio.enabled = false
  check(game.phase == game.Phase.TITLE and game.chapter_screen.visible and not game.panel.visible, "Chapter %d uses illustrated title" % (i+1))
  check(game.chapter_screen.title_label.text == str(game.stage.title).to_upper(), "Title matches chapter data")
  game.chapter_screen.start_requested.emit()
  check(game.phase == game.Phase.INTRO and not game.chapter_screen.visible and game.panel.visible, "Title starts the correct introduction")
  await process_frame
  await process_frame
  check(game.panel.get_global_rect().end.y<=game.get_viewport_rect().end.y,"Story buttons remain inside the viewport")
  game._restart(false)
  game.training_stage = 6
  game.lesson_open = false
  check(not game.action_buttons.has("run"),"No speed modifier control")
  game._attack()
  for f in range(19):
   game._tick(1.0/60)
  game._attack()
  check(game.attack_count==2,"New normal strike starts at the end of the animation")
  for f in range(19):
   game._tick(1.0/60)
  game._attack(true)
  game._refresh_ui()
  if i!=2:
   check(game.super_timer>3.9 and game.empowered,"Power strike starts its own recharge")
   check(game.action_buttons.attack.charge_ratio==1.0,"Regular attack is available during power recovery")
  # A press and release between physics ticks must survive in the attack queue.
  for f in range(20):
   game._tick(1.0/60)
  var count_before:int=game.attack_count
  var tap:=InputEventKey.new()
  tap.physical_keycode=KEY_G
  tap.pressed=true
  game._input(tap)
  tap.pressed=false
  game._input(tap)
  game._tick(1.0/60)
  check(game.attack_count==count_before+1,"Sub-frame G tap performs one strike")
  game._attack()
  if i==2:
   check(game.shots_fired==game.attack_count,"One arrow per accepted bow animation")
  game.queue_free()
  await process_frame
 print("School UI: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
