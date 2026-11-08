extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error(label)
func key(game, physical: int, symbol: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = physical
 event.keycode = symbol
 event.pressed = pressed
 game._input(event)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var save := ConfigFile.new()
 save.set_value("level1", "completed", true)
 save.save("user://level_one.cfg")
 for scene in ["main", "level_two", "level_three", "level_four", "level_five"]:
  for n in range(1, 5):
   save.set_value("level%d" % n, "completed", true)
  save.save("user://level_one.cfg")
  var game = load("res://scenes/%s.tscn" % scene).instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game._restart(false)
  game.training_stage = 6
  game.audio.enabled = false
  key(game, KEY_D, 1060, true)
  var start: float = game.hero.x
  game._tick(0.1)
  check(game.hero.x > start, scene + " physical D works with Russian layout")
  key(game, KEY_D, 1060, false)
  key(game, KEY_A, 1060, true)
  game._tick(0.1)
  check(absf(game.hero.x - start) < 0.1, scene + " physical A moves left")
  key(game, KEY_A, 1060, false)
  key(game, KEY_G, 1055, true)
  game._tick(0.01)
  check(game.attack_timer > 0, scene + " G attacks")
  key(game, KEY_G, 1055, false)
  key(game, KEY_K, 1051, true)
  game._tick(0.01)
  check(game.dodge_timer > 0, scene + " K dashes")
  key(game, KEY_K, 1051, false)
  game._restart(false)
  game.training_stage = 6
  start = game.hero.x
  key(game, KEY_D, KEY_D, true)
  game._tick(0.1)
  check(game.hero.x - start > game.SPEED * 0.1, scene + " direction alone runs")
  for prop in ["rock", "tree", "yurt", "banner", "reeds"]:
   var asset: Dictionary = game.art._asset(prop)
   var img: Image = asset.texture.get_image()
   check(img.get_used_rect().end.y == img.get_height(), prop + " has no transparent bottom margin")
  game.queue_free()
  await process_frame
 print("Controls and art: ", failures, " failures")
 quit(1 if failures else 0)
