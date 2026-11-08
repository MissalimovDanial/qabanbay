extends SceneTree
## Run with isolated APPDATA; verifies native campaign access and hub controls.
const Hub = preload("res://scripts/campaign_map.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func fixture(cleared: Array) -> void:
 var save := ConfigFile.new()
 save.set_value("settings","muted",true)
 for chapter in cleared:
  save.set_value("level%d" % chapter,"completed",true)
 check(save.save(Hub.SAVE_PATH) == OK,"Campaign fixture saved")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 fixture([])
 var hub = load("res://scenes/campaign_map.tscn").instantiate()
 root.add_child(hub)
 hub.set_process(false)
 check(Hub.SAVE_PATH == "user://ayagoz_campaign.cfg","School project has a separate progress file")
 check(hub.unlocked_count == 1 and hub.selected == 0,"Fresh journey starts at chapter one")
 for i in range(5):
  check(hub.can_launch(i) == (i==0),"Fresh chapter %d lock" % (i+1))
 check(not hub.can_launch(-1) and not hub.can_launch(5),"Out-of-range chapters are rejected")
 hub._select(4)
 check(hub.selected == 4 and hub.launch_button.disabled,"Locked chapter can be inspected but not started")
 check(hub.detail_status.text.contains("ЗАКРЫТО"),"Locked chapter explains its status")
 var old_scene := current_scene
 hub._launch()
 await process_frame
 check(current_scene == old_scene and is_instance_valid(hub),"Locked launch does not change native scene")
 fixture([1,3,4,5])
 hub.reload_progress()
 check(hub.unlocked_count == 2 and hub.selected == 1,"A missing second chapter prevents skipping the sequence")
 check(not hub.can_launch(2) and not hub.can_launch(4),"Out-of-order completion flags cannot open later chapters")
 for count in range(1,6):
  var cleared: Array = []
  for chapter in range(1,count+1):
   cleared.append(chapter)
  fixture(cleared)
  hub.reload_progress()
  check(hub.unlocked_count == mini(5,count+1),"Completing %d chapters opens only the next chapter" % count)
  for i in range(5):
   check(hub.can_launch(i) == (i<mini(5,count+1)),"Sequential access %d:%d" % [count,i])
  hub._select(0)
  check(not hub.launch_button.disabled and hub.launch_button.text.contains("ещё"),"Completed chapters remain replayable")
 check(hub.header.text == "ЛЕТОПИСЬ АЯГОЗА","All five chapters show completion greeting")
 check(hub.progress.text.begins_with("5 из 5"),"Progress shows five completed chapters")
 for i in range(5):
  check(ResourceLoader.exists("res://scenes/%s.tscn" % Hub.SCENES[i]),"Native scene exists for chapter %d" % (i+1))
 hub._select(0)
 var event := InputEventKey.new()
 event.pressed = true
 event.physical_keycode = KEY_D
 event.keycode = KEY_A
 hub._input(event)
 check(hub.selected == 1,"Map navigation uses physical key independently of layout")
 event.physical_keycode = KEY_LEFT
 hub._input(event)
 check(hub.selected == 0,"Left navigation returns to previous chapter")
 hub._select(-40)
 check(hub.selected == 0,"Selection clamps below the first chapter")
 hub._select(99)
 check(hub.selected == 4,"Selection clamps above the fifth chapter")
 check(hub.node_buttons.size() == 5,"Every chapter has a clickable map target")
 hub.queue_free()
 await process_frame
 print("Campaign hub: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
