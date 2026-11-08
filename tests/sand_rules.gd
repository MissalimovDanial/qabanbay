extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var start:=Time.get_ticks_msec()
 var map=load("res://scenes/campaign_map.tscn").instantiate()
 root.add_child(map)
 assert(map.unlocked_count==1,"Fresh sand campaign unlocks only chapter one")
 map.free()
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g._restart(false)
 g.training_stage=6
 g.audio.enabled=false
 var ready_ms:=Time.get_ticks_msec()-start
 assert(ResourceLoader.exists("res://art/audio/chapter1/hit.res"))
 assert(ResourceLoader.exists("res://art/props-baked/yurt.res"))
 for r in g.route_depths:
  if r.depth<=0 or r.span.y-r.span.x<400:continue
  var count:=0
  var horizontal:=0
  var vertical:=0
  for i in range(g.platform_origins.size()):
   var p:Rect2=g.platform_origins[i]
   if p.get_center().x>r.span.x and p.get_center().x<r.span.y:
    count+=1
    if g.stage.platform_motion[i].travel.x>0:horizontal+=1
    if g.stage.platform_motion[i].travel.y>0:vertical+=1
  assert(count==2 and horizontal==1 and vertical==1,"Each dry ravine has exactly two perpendicular moving supports")
  var previous:float=g._floor_at(r.span.x-100)
  for i in range(1,300):
   var x:=lerpf(r.span.x-100,r.span.y+100,i/300.0)
   var current:float=g._floor_at(x)
   assert(absf(current-previous)<15,"Ravine banks are continuous")
   previous=current
 g.hero=Vector2(2400,550)
 g._deploy(g.sectors[0])
 var enemy:Dictionary=g.guards[0]
 enemy.x=2520.0
 enemy.state="patrol"
 enemy.timer=0
 var hp:int=g.hp
 for i in range(60):g._guard_step(enemy,1.0/60)
 assert(enemy.x>=2520 and enemy.facing<0,"Enemy does not backpedal at melee range")
 assert(g.hp<hp,"Enemy actually attacks the player")
 print("Sand rules passed: fresh locks, cached resources, rounded banks, exactly two moving platforms, aggressive enemy. Ready ms ",ready_ms)
 g.free()
 quit()
