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
  if r.depth<=60:continue
  var count:=0
  for p in g.route_platforms:
   if p.get_center().x>r.span.x and p.get_center().x<r.span.y:
    count+=1
  assert(count==0,"Dry ravines have no crossing platforms")
  var previous:float=g._floor_at(r.span.x-100)
  for i in range(1,300):
   var x:=lerpf(r.span.x-100,r.span.y+100,i/300.0)
   var current:float=g._floor_at(x)
   assert(absf(current-previous)<15,"Ravine banks are continuous")
   previous=current
 var anchored: Array = g.route_platforms.duplicate()
 g.hero=Vector2(2400,550)
 for i in range(60):g._tick(1.0/60.0)
 assert(g.route_platforms==anchored,"Crossings stay attached to their foundations")
 g.super_hits=g.SUPER_HITS_REQUIRED-1
 g._register_hit()
 g._attack(true)
 assert(g.super_timer>0 and g.super_hits==0,"Eleven hits enable the visible super strike")
 g.free()
 g=load("res://scenes/level_four.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g._restart(false)
 g.audio.enabled=false
 var sector: Dictionary = g.sectors[0]
 g.hero=Vector2(sector.home-150.0,550)
 g._deploy(sector)
 var enemy:Dictionary=g.guards[0]
 enemy.x=g.hero.x+120.0
 enemy.bow=false
 var enemy_x:float=enemy.x
 enemy.state="patrol"
 enemy.timer=0
 var hp:int=g.hp
 for i in range(60):g._guard_step(enemy,1.0/60)
 assert(absf(enemy.x-enemy_x)<1 and enemy.facing<0,"Enemy does not backpedal at melee range")
 assert(g.hp<hp,"Enemy actually attacks the player")
 print("Sand rules passed: locks, cached resources, rounded banks, fixed crossings, super strike, aggressive enemy. Ready ms ",ready_ms)
 g.free()
 quit()
