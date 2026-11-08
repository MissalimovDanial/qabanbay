extends SceneTree
func _initialize()->void:
 call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g.audio.enabled=false
 g._restart(false)
 g.training_stage=6
 g.hero=Vector2(2200,550)
 g.touch_actions={"right":true}
 g._tick(0.1)
 assert(is_equal_approx(g.hero.x,2217))
 g.touch_actions.run=true
 g._tick(0.1)
 assert(is_equal_approx(g.hero.x,2241.5) and g.invulnerable==0)
 g.touch_actions.clear()
 g.super_hits=0
 for i in range(10):g.empowered=false;g._register_hit()
 g._attack(true)
 assert(g.attack_timer==0)
 g._register_hit()
 g._attack(true)
 assert(g.super_hits==0 and g.empowered)
 g._tick(4.0)
 assert(g.super_hits==0)
 g.hero=Vector2(g.stage.spikes[0].x+20,550)
 var hp:int=g.hp
 g.invulnerable=0
 g._tick(0.01)
 assert(g.hp==hp-1,"Spikes damage standing hero")
 var frames:SpriteFrames=load("res://art/animation/actions/hero.res")
 var height:=-1
 for i in range(6):
  var h:int=frames.get_frame_texture("idle",i).get_image().get_used_rect().size.y
  if height<0:height=h
  assert(abs(h-height)<=1,"Idle height must stay fixed")
 assert(g.WORLD_END>=64000 and g.route_platforms.size()>10)
 g.free()
 var map=load("res://scenes/campaign_map.tscn").instantiate()
 root.add_child(map)
 assert(map.can_launch(0))
 assert(not map.can_launch(1),"Fresh user data only unlocks first chapter")
 map.free()
 print("Journey rules: walk/run, no invulnerability, 11-hit super, spikes, six stable idle frames and fresh unlocks passed")
 quit()
