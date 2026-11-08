extends SceneTree
var output:="res://docs/screenshots/journey-"
func _initialize()->void:
 call_deferred("run")
func shot(name:String)->void:
 await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(output+name+".png")==OK)
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
 var map=load("res://scenes/campaign_map.tscn").instantiate()
 root.add_child(map)
 await shot("map")
 map.free()
 for chapter in range(1,6):
  var g=load("res://scenes/%s.tscn"%["main","level_two","level_three","level_four","level_five"][chapter-1]).instantiate()
  root.add_child(g)
  g.set_physics_process(false)
  g._restart(false)
  g.training_stage=6
  g.dummy_hp=0
  g.audio.enabled=false
  g.hero=Vector2(2600,550)
  g.camera_x=2200
  g.clock=2
  if chapter>1:g._tick(0.016)
  g._refresh_ui()
  g.queue_redraw()
  await shot(str(chapter))
  if chapter == 2:
   g.camera_x = (2400.0 - 640.0) / 0.12
   g.hero = Vector2(g.camera_x + 500.0, 550)
   g.queue_redraw()
   await shot("meadow-join")
   g.camera_x = g.wind_trial.target.x - 660
   g.hero = Vector2(g.wind_trial.target.x - 220, 550)
   g.queue_redraw()
   await shot("wind-trail")
  if chapter==4:
   g.hero=Vector2(30500,725)
   g.camera_x=30000
   g.position.y=-175
   g.queue_redraw()
   await shot("gully")
  if chapter==1:
   g.hero=Vector2(g.ARENA_START-420,550)
   g.camera_x=g.ARENA_START-110
   g.boar.x=g.ARENA_START+660
   g.horse_event=1.1
   g.phase=g.Phase.CINEMATIC
   g.queue_redraw()
   await shot("horse-event")
  elif chapter==5:
   g.phase=g.Phase.CINEMATIC
   g.victory_timer=7
   g.queue_redraw()
   await shot("retreat-scene")
  g.free()
 quit()
