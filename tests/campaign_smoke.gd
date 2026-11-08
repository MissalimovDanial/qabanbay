extends SceneTree
const SCENES := ["main","level_two","level_three","level_four","level_five"]
const DT := 1.0/60.0
var route_goal_active := false
var route_goal := Vector2.ZERO
var route_goal_age := 0
var route_goal_platform := -1
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 for i in range(5):
  var game=load("res://scenes/%s.tscn"%SCENES[i]).instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game.audio.enabled=false
  game._advance()
  while game.phase==game.Phase.INTRO:
   game._advance()
  route_goal_active=false
  var frame:=0
  while frame<20000 and game.phase not in [game.Phase.OUTRO,game.Phase.LOST,game.Phase.WON]:
   game.touch_actions.clear()
   if game.lesson_open or game.phase==game.Phase.ENCOUNTER:
    game._advance()
   elif game.phase==game.Phase.FIGHT:
    game.touch_actions.attack=true
    game.touch_actions.power=true
    var dx:float=game.boar.x-game.hero.x
    if absf(dx)>116 or dx*game.facing<0:
     game.touch_actions["right" if dx>0 else "left"]=true
   else:
    controls(game,i+1)
   game._tick(DT)
   game.clock+=DT
   frame+=1
  var ok:bool=game.phase==game.Phase.OUTRO and game.completed
  if i==3:
   ok=ok and game.kills==20
  if i==2:
   ok=ok and game.passes>=3 and game.shots_fired>0 and game.duel=="rally" and game.kills==3
  if i==4:
   ok=ok and game.retreat and game.cover_time>=18
  print("Chapter ",i+1," clear=",ok," ticks=",frame," x=",game.hero.x," hp=",game.hp," phase=",game.phase," kills=",0 if i==0 else game.kills)
  if not ok:
   failures+=1
   if i>0:
    print("state=",game.duel," sectors=",game.sectors," survivors=",game.guards.filter(func(g):return g.hp>0))
  game.queue_free()
  await process_frame
 print("Ayagoz playthrough failures: ",failures)
 quit(1 if failures else 0)

func controls(game,chapter:int) -> void:
 if chapter==1 and game.training_stage==3 and game.dummy_hp>0:
  game.touch_actions.right=game.hero.x<1290
  game.touch_actions.attack=true
  return
 if chapter==1 and game.training_stage==4:
  game.touch_actions.dodge=true
 if chapter==1 and game.training_stage==5:
  game.touch_actions.power=true
 if chapter==5 and (game.retreat or game.horse_waiting):
  var dest:float=110.0 if game.retreat else game.horse_x
  game.touch_actions["left" if game.hero.x>dest else "right"]=true
  game.touch_actions.attack=true
  if game.retreat:
   for s in game.route_gaps:
    if game.grounded and game.hero.x>s.y and game.hero.x<s.y+65:
     game.touch_actions.jump=true
  return
 if chapter==3 and game.duel!="rally":
  var dx:float=game.boar.x-game.hero.x
  if dx*game.facing<=0:
   game.touch_actions["right" if dx>0 else "left"]=true
  game.touch_actions.attack=true
  if game.duel=="bows":
   for a in game.arrows:
    if not a.ally and absf(a.p.x-game.hero.x)<95:
     game.touch_actions.dodge=true
  return
 if move_toward_goal(game):
  return
 var x: float = game.hero.x
 # Build jumps between real support surfaces, stopping over a ledge until landing.
 if game.grounded:
  for gap in game.route_gaps:
   if x < gap.x-90 or x > gap.y-20:
    continue
   var edge: float = gap.x
   if x > gap.x:
    for platform_rect in game.route_platforms:
     if absf(game.hero.y-platform_rect.position.y)<2 and x+17>platform_rect.position.x and x-17<platform_rect.end.x:
      edge = platform_rect.end.x
   if x < edge-65:
    continue
   var target := Vector2(gap.y+55,game.FLOOR_Y)
   for platform_rect in game.route_platforms:
    if platform_rect.get_center().x > x+35 and platform_rect.position.x>=gap.x and platform_rect.position.x<gap.y and game.hero.y-platform_rect.position.y<=135:
     if platform_rect.get_center().x < target.x:
      target = Vector2(platform_rect.get_center().x,platform_rect.position.y)
   jump_to(game,target)
   return

 if chapter>1:
  var target: Dictionary={}
  for g in game.guards:
   if g.hp>0 and game.hero.x>=g.zone.x-65 and game.hero.x<=g.zone.y+74:
    if target.is_empty() or absf(g.x-x)<absf(target.x-x):
     target=g
  if not target.is_empty():
   var dx:float=target.x-x
   if absf(dx)>128 or dx*game.facing<=0:
    game.touch_actions["right" if dx>0 else "left"]=true
   game.touch_actions.power=true
   game.touch_actions.attack=true
   # A real player can read the telegraph and jump over the sword or arrow.
   if game.grounded:
    var danger: bool=target.state=="aim" and target.timer<0.26 and absf(dx)<190
    for a in game.arrows:
     if not a.ally and (x-a.p.x)*a.v>0 and absf(a.p.x-x)<180:
      danger=true
    if danger:
     game.touch_actions.jump=true
   return
  for s in game.spikes:
   if game.grounded and x>s.x-70 and x<s.y:
    jump_to(game,Vector2(s.y+45,game.FLOOR_Y))
    return
 game.touch_actions.right=true

func move_toward_goal(game) -> bool:
 if not route_goal_active:
  return false
 if route_goal_platform >= 0 and route_goal_platform < game.route_platforms.size():
  var moving_ledge: Rect2 = game.route_platforms[route_goal_platform]
  route_goal = Vector2(moving_ledge.get_center().x,moving_ledge.position.y)
 route_goal_age += 1
 if game.grounded and absf(game.hero.y-route_goal.y)<2 and absf(game.hero.x-route_goal.x)<22:
  route_goal_active = false
  return false
 var distance: float = route_goal.x-game.hero.x
 if absf(distance)>7:
  game.touch_actions["right" if distance>0 else "left"] = true

 if route_goal_age > 240:
  print("Jump goal stalled: ", game.hero, " -> ", route_goal, " grounded ", game.grounded)
  route_goal_active = false
 return true

func jump_to(game, target: Vector2) -> void:
 route_goal_active = true
 route_goal = target
 route_goal_age = 0
 route_goal_platform = -1
 for index in range(game.route_platforms.size()):
  var ledge: Rect2 = game.route_platforms[index]
  if absf(target.x-ledge.get_center().x)<1 and absf(target.y-ledge.position.y)<1:
   route_goal_platform = index
 game.touch_actions.jump = true
 game.touch_actions["right" if target.x>game.hero.x else "left"] = true


