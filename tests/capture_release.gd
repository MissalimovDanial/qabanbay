extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func shot(game, name: String) -> void:
 game._refresh_ui()
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://build/animation-preview")
 var first = load("res://scenes/main.tscn").instantiate()
 root.add_child(first)
 first.set_physics_process(false)
 first.audio.enabled=false
 for i in range(4):
  first._advance()
 first._tick(1.0/60)
 await shot(first,"release-tutorial-move")
 first._advance()
 first.clock=1
 await shot(first,"release-level-1")
 first.hero.x=471
 first._tick(1.0/60)
 await shot(first,"release-tutorial-jump")
 first._advance()
 first.hero=Vector2(1250,550)
 first.camera_x=850
 first.training_stage=6
 first.lesson_open=false
 first.npc_passed=true
 first.panel.hide()
 first.touch_actions.right=true
 first.touch_actions.run=true
 for frame in range(16):
  first.clock=frame/10.0
  first.run_clock=frame/13.0
  first._refresh_ui()
  first.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/animation-preview/run-%02d.png" % frame)
 first.queue_free()
 await process_frame
 for n in range(2,6):
  var scene: String = ["level_two","level_three","level_four","level_five"][n-2]
  var game = load("res://scenes/"+scene+".tscn").instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game.audio.enabled=false
  game._restart(false)
  game.clock=1.5
  game.elapsed=1.5
  game.npc_passed=true
  if n<4:
   game.hero=Vector2(1280,550)
   game.camera_x=780
  else:
   var ledge: Rect2 = game.route_platforms[0]
   game.hero=Vector2(ledge.get_center().x,ledge.position.y)
   game.camera_x=2900
  await shot(game,"release-level-%d" % n)
  game.queue_free()
  await process_frame
 quit()

