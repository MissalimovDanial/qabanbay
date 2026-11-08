extends SceneTree
var game
func _initialize()->void:call_deferred("run")
func shot(name:String)->void:
 game._refresh_ui()
 game.queue_redraw()
 game.exploration.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://docs/screenshots/explore-"+name+".png")==OK)
func spawn(scene:String)->void:
 game=load("res://scenes/"+scene+".tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game._restart(false)
 game.training_stage=6
 game.lesson_open=false
 game.audio.enabled=false
 game.clock=2
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
 spawn("main")
 game.elder_started_at=0
 game.elapsed=2
 game.clock=3
 game.hero=Vector2(580,550)
 game.camera_x=0
 await shot("yurt-and-elder")
 game.hero=Vector2(1360,550)
 game.camera_x=900
 await shot("practice-dummy")
 game.hero=Vector2(1055,550)
 game._tick(0.016)
 game.camera_x=700
 await shot("checkpoint")
 var door:Dictionary=game.stage.doors.filter(func(d):return d.kind=="secret")[0]
 game.hero=door.at
 game.camera_x=25000
 game.camera_y=175
 game.position.y=-175
 await shot("secret-pit")
 game.exploration.enter(door)
 game.exploration.room_x=230
 game.exploration.door_open=0
 await shot("secret-interior")
 game.exploration.cave_guards[0].hp=0
 game.exploration.cave_guards[0].down=2.0
 game.exploration.room_x=1130
 game.exploration.room_camera_x=690
 game.exploration.message="Стражи 1 / 4 · кумыс в дальнем зале"
 await shot("cave-gallery")
 for guard in game.exploration.cave_guards:
  guard.hp=0
  guard.down=2.0
 game.exploration.room_x=2700
 game.exploration.room_camera_x=1960
 game.exploration.message="Все стражи повержены · разбей золотой сувенир"
 await shot("cave-amber-hall")
 game.exploration.leave(false)
 game.hero=Vector2(41950,490)
 game.camera_x=41500
 game.camera_y=0
 game.position.y=0
 await shot("lake")
 game.phase=game.Phase.INTRO
 game.dialog_index=0
 game._show_dialog(game.INTRO)
 await shot("opening")
 game.free()
 spawn("level_two")
 var yurt:Dictionary=game.stage.doors.filter(func(d):return d.kind=="passage")[0]
 game.hero=yurt.at-Vector2(100,0)
 game.camera_x=12200
 await shot("passage-yurt")
 game.exploration.enter(yurt)
 game.exploration.room_x=500
 await shot("yurt-interior")
 game.exploration.leave(true)
 game.hero=Vector2(2600,550)
 game.camera_x=2200
 game._deploy(game.sectors[0])
 game.guards[0].hp=0
 game.guards[0].down=0.75
 await shot("horse-collapse")
 game.free()
 for chapter in ["level_four","level_five"]:
  spawn(chapter)
  game.hero=Vector2(1100,550)
  game.camera_x=600
  await shot(chapter+"-hero")
  game.free()
 quit()
