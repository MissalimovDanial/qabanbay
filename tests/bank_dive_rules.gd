extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g._restart(false)
 g.training_stage=6
 g.audio.enabled=false
 for r in g.route_depths:
  if r.depth<=0:continue
  for direction in [-1.0,1.0]:
   var x:float=r.span.x+125 if direction<0 else r.span.y-125
   g.hero=Vector2(x,g._floor_at(x)-10)
   g.vertical_speed=140
   g.grounded=false
   for step in range(18):
    g._move_hero(1.0/30,direction*315)
    assert(g.hero.y<=g._floor_at(g.hero.x)+0.2,"Airborne hero cannot tunnel into either bank")
    assert(g.phase!=g.Phase.LOST,"Banks never eject the hero below the level")
 g.hero=Vector2(2000,400)
 g.grounded=false
 g.vertical_speed=-500
 g.attack_timer=0
 g._attack()
 assert(g.air_kick and g.vertical_speed>=2200,"Air attack immediately dives down")
 for i in range(8):
  g._move_hero(1.0/60,0)
  assert(g.hero.y<=g._floor_at(g.hero.x)+0.1)
 assert(g.grounded,"Fast dive lands within a fraction of a second")
 g._refresh_npc()
 assert(not g.npc_bubble.visible,"Elder never has a text bubble")
 print("Both banks of every dry ravine, fast swept dive landing and silent elder passed")
 g.free()
 quit()

