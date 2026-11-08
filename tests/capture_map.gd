extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 for mode in range(3):
  var save := ConfigFile.new()
  save.set_value("settings", "muted", true)
  if mode == 2:
   for n in range(1,6):
    save.set_value("level%d" % n, "completed", true)
  save.save("user://level_one.cfg")
  var map = load("res://scenes/campaign_map.tscn").instantiate()
  root.add_child(map)
  if mode == 1:
   map._select(4)
  await process_frame
  await RenderingServer.frame_post_draw
  var name: String = ["campaign-map", "map-locked", "map-complete"][mode]
  root.get_texture().get_image().save_png("res://docs/screenshots/%s.png" % name)
  map.queue_free()
  await process_frame
 quit()
