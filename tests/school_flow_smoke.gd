extends SceneTree
const GAME = preload("res://scripts/game.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func settle() -> void:
 await process_frame
 await process_frame

func run() -> void:
 var save := ConfigFile.new()
 save.set_value("settings","muted",true)
 check(save.save(GAME.SAVE_PATH) == OK, "Fresh school save is isolated")
 change_scene_to_file("res://scenes/campaign_map.tscn")
 await settle()
 for chapter in range(1,6):
  var map = current_scene
  check(map.unlocked_count == chapter and map.selected == chapter-1, "Map selects newly available chapter %d" % chapter)
  if chapter < 5:
   map._select(chapter)
   map._launch()
   check(current_scene == map,"Later chapter remains locked before victory")
  map._select(chapter-1)
  map._launch()
  await settle()
  var game = current_scene
  game.set_physics_process(false)
  check(game.chapter_number == chapter and game.chapter_screen.visible, "Map opens chapter %d illustrated cover" % chapter)
  game.chapter_screen.start_requested.emit()
  check(game.phase == game.Phase.INTRO and not game.chapter_screen.visible, "Start cover enters story")
  game._restart(false)
  game._win()
  while game.phase == game.Phase.OUTRO:
   game._advance()
  check(game.phase == game.Phase.WON and game.completed, "Victory saved before map return")
  check(game.primary.text == "На карту пути", "Results offer map continuation")
  game._advance()
  await settle()
 var final_map = current_scene
 check(final_map.completed.count(true) == 5 and final_map.unlocked_count == 5, "All five victories persist on final map")
 check(final_map.header.text=="ЛЕТОПИСЬ АЯГОЗА", "Final map celebrates completion")
 print("School flow: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
