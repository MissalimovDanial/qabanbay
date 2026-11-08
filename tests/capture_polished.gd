extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var save := ConfigFile.new()
 save.set_value("settings", "muted", true)
 for n in range(1,6):
  save.set_value("level%d" % n, "completed", true)
 save.save("user://level_one.cfg")
 for n in range(1,6):
  var file: String = ["main","level_two","level_three","level_four","level_five"][n-1]
  var game = load("res://scenes/%s.tscn" % file).instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game._restart(false)
  game.clock = 0.25
  game.elapsed = 1.1
  if n == 1:
   game.hero = Vector2(250,game.FLOOR_Y)
   game.camera_x = 0
  elif n == 2:
   game.hero = Vector2(1110,game.FLOOR_Y)
   game.camera_x = 650
   game.touch_actions.right = true
   game.run_clock = 0.16
  elif n == 3:
   game.hero = Vector2(3710,465)
   game.camera_x = 3000
  elif n == 4:
   game.hero = Vector2(3690,455)
   game.camera_x = 3000
  else:
   game.hero = Vector2(3440,480)
   game.camera_x = 2850
  game._refresh_ui()
  game.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/screenshots/chapter-%d-polished.png" % n)
  game.queue_free()
  await process_frame
 quit()
