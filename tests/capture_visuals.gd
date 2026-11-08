extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var save := ConfigFile.new()
 for n in range(1, 6):
  save.set_value("level%d" % n, "completed", true)
 save.save("user://level_one.cfg")
 for chapter in ["main", "level_two", "level_three", "level_four", "level_five"]:
  var game = load("res://scenes/%s.tscn" % chapter).instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game._restart(false)
  game.audio.enabled = false
  game.hero.x = 1050
  game.camera_x = 650
  game._refresh_ui()
  game.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/screenshots/%s-fixed.png" % chapter)
  if chapter == "main" or chapter == "level_five":
   game.hero.x = 4400
   game.boar.x = 4700
   game.boar_facing = -1
   game.camera_x = 4000
   game.phase = game.Phase.FIGHT
   game.boar_state = "windup"
   game._refresh_ui()
   game.queue_redraw()
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://docs/screenshots/%s-boss-fixed.png" % chapter)
  game.queue_free()
  await process_frame
 quit()
