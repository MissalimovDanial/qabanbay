extends SceneTree
func _initialize()->void:
 call_deferred("run")
func make_scene(name:String):
 var g=load("res://scenes/"+name+".tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g.audio.enabled=false
 g._restart(false)
 return g
func run()->void:
 var g=make_scene("main")
 g.touch_actions.right=true
 var x:float=g.hero.x
 g._tick(0.02)
 assert(g.hero.x>x and not g.paused and not g.panel.visible,"Tutorial prompt must not pause movement")
 g.training_stage=6
 g.lesson_open=false
 g.touch_actions.clear()
 assert(g.sectors.is_empty(),"The first chapter contains no Dzungar troops")
 var secret:Dictionary=g.stage.doors.filter(func(d):return d.kind=="secret")[0]
 g.hero=secret.at
 assert(absf(g._floor_at(g.hero.x)-725)<5,"Secret pit has a walkable bottom")
 g.hp=1
 g.camera_x=secret.at.x-500
 g.camera_y=175
 var tap:=InputEventScreenTouch.new()
 tap.pressed=true
 g.exploration.after_motion()
 assert(g.exploration.inside and not g.exploration.room_grounded,"The sinkhole drops the player into the cave")
 assert(g.exploration.cave_guards.size()==4,"Three halls contain four guards")
 var guards:Array=g.exploration.cave_guards
 assert(guards.all(func(guard):return guard.wildlife and not guard.bow),"Only wildlife appears in the first chapter cave")
 g.exploration.room_x=350
 var world_position:Vector2=g.hero
 for i in range(100):g.exploration.step(1.0/60)
 assert(g.hp<1 or g.phase==g.Phase.LOST,"A cave guard has an active attack")
 g.phase=g.Phase.EXPLORE
 g.panel.hide()
 g.hp=2
 g.invulnerable=100
 assert(g.hero==world_position,"Cave combat does not move the outside hero")
 g.exploration.room_x=g.exploration.CAVE_REWARD
 g.facing=1
 g.touch_actions.attack=true
 for i in range(60):g.exploration.step(1.0/60)
 assert(g.exploration.statue_hp==4 and not g.exploration.drink and g.hp==2,"Kumys is locked before the four guards fall")
 g.exploration.enter(secret)
 g.hp=6
 g.invulnerable=0
 var reached_gallery := false
 for frame in range(2400):
  var cave = g.exploration
  var target: float = cave.CAVE_REWARD - 105 if cave.statue_hp > 0 else cave.CAVE_REWARD
  for guard in guards:
   if guard.hp>0:
    target = guard.x - 104
    break
  g.touch_actions = {"run": true}
  g.touch_actions.right = cave.room_x < target - 3
  g.touch_actions.left = cave.room_x > target + 6
  g.touch_actions.attack = cave.room_grounded and absf(cave.room_x - target) < 17 and cave.statue_hp > 0
  for gap in cave.CAVE_GAPS:
   if cave.room_grounded and cave.room_x < gap.x and cave.room_x >= gap.x - 27:
    g.touch_actions.jump = true
  cave.step(1.0/60)
  reached_gallery = reached_gallery or cave.room_camera_x > 500.0
  if cave.drunk:
   break
 assert(reached_gallery, "The actual cave route scrolls through the gallery")
 assert(guards.all(func(guard): return guard.hp==0), "All four guards must be defeated")
 assert(g.hp==6 and g.exploration.drunk,"Kumys instantly restores full health")
 g.exploration.room_x=g.exploration.CAVE_EXIT-10.0
 g.exploration.room_camera_x=g.exploration.CAVE_WIDTH-1280.0
 tap.position=Vector2(g.exploration.CAVE_EXIT-g.exploration.room_camera_x,500)
 g.exploration._input(tap)
 assert(not g.exploration.inside and absf(g.hero.y-g._floor_at(g.hero.x))<0.01)
 g.touch_actions.clear()
 g.hero=Vector2(1055,550)
 g._tick(0.01)
 assert(g.checkpoint and g.checkpoint_x==1050)
 g.hp=0
 g.phase=g.Phase.LOST
 g._retry()
 assert(g.hp==6 and g.hero.x==1050,"Death returns to activated checkpoint")
 var lake:Vector2=g.stage.lakes[0]
 var count:=0
 for p in g.route_platforms:
  if p.get_center().x>lake.x and p.get_center().x<lake.y:count+=1
 assert(count==10,"The lake uses separate stepping stones")
 for spike in g.stage.spikes:assert(not (spike.x<lake.y and spike.y>lake.x),"No spikes over water")
 var first_platform:=-1
 for i in range(g.route_platforms.size()):
  if g.route_platforms[i].get_center().x>lake.x and g.route_platforms[i].get_center().x<lake.y:
   first_platform=i
   break
 var support:Rect2=g.route_platforms[first_platform]
 g.hero=Vector2(support.get_center().x,support.position.y)
 g.grounded=true
 g.exploration.after_motion()
 assert(g.exploration.safe_platform==first_platform,"Water remembers the actual support, not another platform at the same height")
 g.exploration.safe_platform=-1
 g.exploration.safe=Vector2(lake.x-80,550)
 g.hero=Vector2(lake.x+120,580)
 g.grounded=false
 g.exploration.after_motion()
 assert(g.hp==6 and g.exploration.bounce==0,"The shallows can be crossed without taking damage")
 g.checkpoint_x=g.ARENA_START+80
 g.hp=0
 g.phase=g.Phase.LOST
 g._retry()
 assert(g.phase==g.Phase.FIGHT and g.boar_hp==g.boss_max_hp,"Boss checkpoint resumes the actual fight")
 g.free()
 var mounted=make_scene("level_two")
 var later_cave:Dictionary=mounted.stage.doors.filter(func(d):return d.kind=="secret")[0]
 mounted.exploration.enter(later_cave, true)
 assert(mounted.exploration.cave_guards[1].bow,"An archer guards a cave in the war chapters")
 mounted.exploration.leave(false)
 mounted.hero=Vector2(2000,550)
 mounted.touch_actions.jump=true
 mounted._tick(0.01)
 assert(absf(mounted.vertical_speed)<720,"Mounted jump has a limited impulse")
 var door:Dictionary=mounted.stage.doors.filter(func(d):return d.kind=="passage")[0]
 mounted.hero=door.at-Vector2(100,0)
 mounted.exploration.enter(door)
 mounted.exploration.cleared[str(door.at.x)]=true
 mounted.exploration.leave(true)
 assert(mounted.hero.x>door.at.x+200,"Pass-through yurt exits on the far side")
 mounted.free()
 print("Exploration passed: drop-in entry, wildlife, archer, cave crossings, kumys, checkpoints, shallow water and yurt passage")
 quit()
