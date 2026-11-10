extends SceneTree
const DT:=1.0/60.0
var failures:=0
var air_target:=1e9
func _initialize()->void:
 call_deferred("run")
func run()->void:
 for chapter in range(1,6):
  var game=load("res://scenes/%s.tscn"%["main","level_two","level_three","level_four","level_five"][chapter-1]).instantiate()
  root.add_child(game)
  game.set_physics_process(false)
  game.audio.enabled=false
  game._restart(false)
  var frame:=0
  var last_x:float=game.hero.x
  var stalled:=0
  var simultaneous := 0
  while frame<42000 and game.phase not in [game.Phase.OUTRO,game.Phase.LOST]:
   game.touch_actions={"run":true}
   if game.lesson_open:
    game._advance()
   elif game.phase==game.Phase.CINEMATIC:
    game._tick_cinematic(DT)
   else:
    drive(game,chapter)
    game._tick(DT)
    if chapter==2:
     simultaneous=maxi(simultaneous,game.guards.filter(func(guard):return guard.hp>0).size())
   game.clock+=DT
   frame+=1
   var current_x: float = game.exploration.room_x if game.exploration.inside else game.hero.x
   if absf(current_x-last_x)<0.02:stalled+=1
   else:stalled=0
   last_x=current_x
   if stalled>1500:
    print("STALLED ",chapter," ",game.hero," phase ",game.phase," training ",game.training_stage)
    break
  var ok:bool=game.completed and game.phase==game.Phase.OUTRO and game.elapsed>=230 and game.elapsed<=500
  if chapter==2:
   ok=ok and simultaneous==1
  print("Journey ",chapter," passed=",ok," seconds=",snappedf(game.elapsed,0.1)," x=",game.hero.x," hp=",game.hp," frames=",frame)
  if not ok:
   failures+=1
   if chapter>1: print("duel ",game.duel," passes ",game.passes," kills ",game.kills," remaining ",game.guards.filter(func(g):return g.hp>0))
  game.free()
  await process_frame
 print("Journey failures ",failures)
 quit(failures)

func drive(g,c:int)->void:
 if g.exploration.inside:
  var cave = g.exploration
  if cave.room.kind=="secret":
   var destination: float = cave.CAVE_EXIT-30 if cave.drunk else cave.CAVE_REWARD-104 if cave.statue_hp>0 else cave.CAVE_REWARD
   for guard in cave.cave_guards:
    if guard.hp>0:
     destination=guard.x-104
     break
   g.touch_actions.right=cave.room_x<destination-3
   g.touch_actions.left=cave.room_x>destination+6
   g.touch_actions.attack=cave.room_grounded and absf(cave.room_x-destination)<18
   g.touch_actions.power=g.touch_actions.attack
   if cave.drunk and cave.room_x>cave.CAVE_EXIT-90:
    cave.leave(true)
   return
  var target:=580.0 if g.exploration.statue_hp>0 else 680.0 if g.exploration.drink else 1150.0
  g.touch_actions.right=g.exploration.room_x<target-6
  g.touch_actions.left=g.exploration.room_x>target+6
  g.touch_actions.attack=true
  if g.exploration.room_x>1100 and not g.exploration.drink and g.exploration.statue_hp==0:
   var event:=InputEventKey.new()
   event.physical_keycode=KEY_E
   event.pressed=true
   g.exploration._input(event)
  return
 for entry in g.stage.doors:
  if entry.kind=="passage" and absf(g.hero.x-entry.at.x)<160 and not g.exploration.cleared.has(str(entry.at.x)):
   var event:=InputEventKey.new()
   event.physical_keycode=KEY_E
   event.pressed=true
   g.exploration._input(event)
   if g.exploration.inside:return
 g.touch_actions.right=true
 g.touch_actions.attack=true
 g.touch_actions.power=true
 if c==1 and g.training_stage==3 and g.dummy_hp>0:
  g.touch_actions.right=g.hero.x<1300
  return
 if c==1 and g.phase==g.Phase.FIGHT:
  var dx:float=g.boar.x-g.hero.x
  g.touch_actions.right=dx>110
  g.touch_actions.left=dx< -110
  if dx*g.facing<0:g.touch_actions["right" if dx>0 else "left"]=true
  if g.grounded and g.boar_state=="windup" and g.boar_timer<0.20:g.touch_actions.jump=true
  return
 if c==3 and g.duel in ["bows","spears"]:
  var dx:float=g.boar.x-g.hero.x
  if g.duel=="bows":
   var dir:float=signf(dx)
   g.touch_actions.right=dir>0
   g.touch_actions.left=dir<0
   var speed:float=550 if g.hero.x>g.ARENA_START+60 and g.hero.x<g.ARENA_START+1730 else 235
   if g.grounded and absf(dx)<speed*0.40 and dx*g.arslan_dir<0:g.touch_actions.jump=true
  else:
   g.touch_actions.right=dx>110
   g.touch_actions.left=dx< -110
   if dx*g.facing<0:g.touch_actions["right" if dx>0 else "left"]=true
   if g.grounded and g.duel_mode=="windup" and g.duel_cooldown<0.20:g.touch_actions.jump=true
  return
 if c>=1:
  var target:Dictionary={}
  for enemy in g.guards:
   if enemy.hp>0 and absf(enemy.x-g.hero.x)<650 and absf(enemy.floor-g.hero.y)<220:
    if target.is_empty() or absf(enemy.x-g.hero.x)<absf(target.x-g.hero.x):target=enemy
  if not target.is_empty():
   if target.floor-g.hero.y>125:
    if g.hero.x<target.zone.x:
     g.touch_actions.right=true
     g.touch_actions.left=false
     return
    g.touch_actions.right=false
    g.touch_actions.left=true
    return
   var dx:float=target.x-g.hero.x
   g.touch_actions.right=dx>105
   g.touch_actions.left=dx< -105
   if dx*g.facing<0:g.touch_actions["right" if dx>0 else "left"]=true
   if g.grounded and target.state=="aim" and target.timer<0.26:g.touch_actions.jump=true
   for arrow in g.arrows:
    if not arrow.ally and (g.hero.x-arrow.p.x)*arrow.v>0 and absf(arrow.p.x-g.hero.x)<150 and g.grounded:g.touch_actions.jump=true
   return
 if not g.grounded:
  if air_target<1e8:
   g.touch_actions.right=g.hero.x<air_target-5
   g.touch_actions.left=g.hero.x>air_target+5
  return
 air_target=1e9
 for p in g.route_platforms:
  if p.position.x>g.hero.x and p.position.x<g.hero.x+95 and g.hero.y-p.position.y>4 and g.hero.y-p.position.y<=140:
   g.touch_actions.jump=true
   air_target=p.get_center().x
   return
 var edge:float=1e9
 var current=-1
 for i in range(g.route_platforms.size()):
  var p:Rect2=g.route_platforms[i]
  if absf(g.hero.y-p.position.y)<1 and g.hero.x>p.position.x-15 and g.hero.x<p.end.x+15:
   current=i
   edge=p.end.x
 for r in g.route_depths:
  if r.get("water",false):
   continue
  if r.depth>60 and r.span.y-r.span.x<240 and g.hero.x>=r.span.x-16 and g.hero.x<r.span.x+4:
   g.touch_actions.jump=true
   return
  if r.depth>0 and g.hero.x>r.span.x and g.hero.x<r.span.y and current<0:
   if g.hero.y>g.FLOOR_Y+145 and g.hero.x>r.span.y-300:
    var low:Rect2=Rect2()
    for p in g.route_platforms:
     if p.get_center().x<g.hero.x and p.position.y>g.FLOOR_Y+60 and p.position.y<g.hero.y and p.end.x>r.span.y-380:
      if low.size.x==0 or p.position.y>low.position.y:low=p
    if low.size.x>0:
     g.touch_actions.right=false
     g.touch_actions.left=true
     if g.hero.x<low.end.x+28:
      g.touch_actions.jump=true
      air_target=low.get_center().x
     return
   if g.hero.x>r.span.y-80:g.touch_actions.jump=true
   for p in g.route_platforms:
    if p.position.x>g.hero.x and p.position.x-g.hero.x<100 and g.hero.y-p.position.y<=140:
     g.touch_actions.jump=true
   return
  if r.depth==0 and g.hero.x<=r.span.y and g.hero.x>r.span.x-250:
   if current<0:edge=r.span.x
   if g.hero.x>edge-24:
    air_target=r.span.y+30
    for p in g.route_platforms:
     if p.get_center().x>g.hero.x+50 and p.position.x<r.span.y:
      air_target=minf(air_target,p.get_center().x)
    g.touch_actions.jump=true
   break
 if current>=0 and g.hero.x>edge-24:
  air_target=g.hero.x+170
  var next:=1e9
  for p in g.route_platforms:
   if p.get_center().x>edge+10 and g.hero.y-p.position.y<=140:next=minf(next,p.get_center().x)
  if next<1e8:air_target=next
  for r in g.route_depths:
   if r.span.y>edge and r.span.y<air_target:air_target=r.span.y+30
  g.touch_actions.jump=true
 for spike in g.stage.spikes:
  if g.hero.x>spike.x-42 and g.hero.x<spike.y:g.touch_actions.jump=true
