extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g.audio.enabled=false
 g._restart(false)
 g.training_stage=6
 g.lesson_open=false
 var costs:Array[float]=[]
 for i in range(180):
  g.hero=Vector2(2000+i*100,g._floor_at(2000+i*100))
  g.camera_x=g.hero.x-430
  g.clock+=1.0/60
  var begin:=Time.get_ticks_usec()
  g.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  costs.append((Time.get_ticks_usec()-begin)/1000.0)
 costs.sort()
 print("RENDER ms median=",costs[90]," p95=",costs[171]," max=",costs[179]," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
 g.free()
 quit()
