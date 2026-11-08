extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.audio.enabled = false
 for i in range(4):
  game._advance()
 game._tick(1.0/60)
 assert(game.lesson_open and game.training_stage==1)
 assert(game.action_buttons.right.visible and not game.action_buttons.jump.visible and not game.action_buttons.attack.visible)
 var still: Vector2 = game.hero
 game.touch_actions.right = true
 game._tick(1.0)
 assert(game.hero==still)
 game._advance()
 game.hero.x=471
 game._tick(1.0/60)
 assert(game.lesson_open and game.training_stage==2 and game.lesson_arrow.visible)
 game._advance()
 game.hero = Vector2(1195,550)
 game._tick(1.0/60)
 assert(game.lesson_open and game.training_stage==3)
 game._advance()
 game.hero.x=1520
 game._tick(1.0/60)
 assert(game.hero.x<=1460 and game.dummy_hp==3)
 game.hero.x=1280
 game.facing=1
 game.touch_actions.attack=true
 for frame in range(400):
  game._tick(1.0/60)
  if game.lesson_open:
   break
 assert(game.dummy_hp==0 and game.lesson_open and game.training_stage==4)
 assert(game.attack_cooldown==0)
 game._advance()
 game.hero.x=1540
 game.touch_actions.dodge=true
 game._tick(1.0/60)
 assert(game.lesson_open and game.training_stage==5)
 game._advance()
 game.touch_actions.right=true
 game.touch_actions.power=true
 for frame in range(40):
  game._tick(1.0/60)
 game._refresh_ui()
 assert(game.training_stage==6)
 assert(not game.hud.visible and not game.objective.visible and not game.hint.visible)
 assert(game.hp==6)
 print("Tutorial: staged controls, modal freeze, mandatory target,super strike,6HP,headerless HUD passed")
 game.queue_free()
 quit()

