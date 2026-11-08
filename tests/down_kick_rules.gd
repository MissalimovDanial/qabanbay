extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g._restart(false)
 g.training_stage=6
 g.audio.enabled=false
 assert(g.route_depths.all(func(r):return r.depth<=0 or r.span.y-r.span.x>=400),"No small pits remain")
 assert(not g.stage.decor.any(func(d):return d.name=="tumbleweed"))
 g.hero=Vector2(2600,550)
 g._deploy(g.sectors[0])
 var enemy:Dictionary=g.guards[0]
 enemy.x=2600.0
 enemy.floor=550.0
 g.hero=Vector2(2600,440)
 g.grounded=false
 g._attack()
 assert(g.air_kick,"Air attack selects downward kick")
 assert(g._weapon_rect().position.y>=g.hero.y-6)
 assert(not g._weapon_rect().has_point(g.hero+Vector2(130,0)),"Kick does not use the spear's forward range")
 var hp:int=enemy.hp
 g.attack_timer=0.15
 g._resolve_attack()
 g._resolve_attack()
 assert(enemy.hp==hp-1,"Enemy underneath takes exactly one hit per kick")
 g.grounded=true
 g.attack_timer=0
 g._attack()
 assert(not g.air_kick,"Ground attack still uses spear")
 g.free()
 print("Downward kick, one-hit registration, ground spear, no small pits and no branch balls passed")
 quit()
