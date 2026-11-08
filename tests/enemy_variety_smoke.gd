extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game=load("res://scenes/level_two.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.audio.enabled=false
 game._restart(false)
 var pair:Array=game._active(0)
 assert(pair.size()==2 and not pair[0].bow and pair[1].bow)
 game.hero.x=pair[0].zone.x
 var old:float=pair[0].x
 for frame in range(120):
  game._tick(1.0/60)
  assert(absf(pair[0].x-pair[1].x)>=144.9)
 assert(pair[0].x!=old)
 var hp:int=game.hp
 game.invulnerable=0
 game._arrow(game.hero-Vector2(40,90),1,false)
 game._fly_arrows(0.1)
 assert(game.hp==hp-1)
 print("Active cavalry, archer projectiles and melee spacing passed")
 game.free()
 quit()
