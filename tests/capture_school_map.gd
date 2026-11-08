extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
 for mode in range(3):
  var save := ConfigFile.new()
  save.set_value("settings","muted",true)
  if mode > 0:
   for chapter in range(1,4 if mode == 1 else 6):
    save.set_value("level%d" % chapter,"completed",true)
  save.save("user://qabanbay_school.cfg")
  var hub = load("res://scenes/campaign_map.tscn").instantiate()
  root.add_child(hub)
  hub.set_process(false)
  hub.phase_clock = 2.0
  hub._select(4 if mode == 1 else 0 if mode == 0 else 4)
  hub.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/screenshots/school-map-%d.png" % mode)
  hub.queue_free()
  await process_frame
 quit()
