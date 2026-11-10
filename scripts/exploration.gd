extends Node2D
## Shared touch interactions, safe water recoil and optional healing rooms.
var game:Node2D
var interior:Texture2D=preload("res://art/animation/yurt-interior.png")
const CAVE_ART := preload("res://art/animation/cave-journey.png")
const CAVE_STONE := preload("res://art/animation/sand-ground.png")
const CAVE_WIDTH := 3240.0
const CAVE_EXIT := 3130.0
const CAVE_REWARD := 2950.0
const ROOM_FLOOR := 570.0
const CAVE_GAPS := [Vector2(920, 1032), Vector2(1785, 1920)]
const CAVE_LEDGE := Rect2(1830, 520, 72, 19)
var inside:=false
var room:Dictionary={}
var cleared:Dictionary={}
var room_x:=200.0
var room_y:=570.0
var room_vy:=0.0
var room_grounded := true
var room_camera_x := 0.0
var room_safe_x := 200.0
var room_jump:=false
var room_attack_held:=false
var cave_guards:Array[Dictionary]=[]
var cave_arrows: Array[Dictionary] = []
var guard_texture:Texture2D=preload("res://art/animation/infantry.png")
var cave_archer := preload("res://art/animation/archer.png")
var statue_hp:=4
var drink:=false
var drunk:=false
var bounce:=0.0
var bounce_from:=Vector2.ZERO
var safe:=Vector2(180,550)
var safe_platform:=-1
var water_flash:=0.0
var effect:=0.0
var door_open:=0.0
var message:=""

func setup(owner_game:Node2D)->void:
 game=owner_game
func reset()->void:
 inside=false
 bounce=0
 cleared.clear()
 safe=game.hero
 safe_platform=-1

func _input(event:InputEvent)->void:
 if not is_instance_valid(game) or game.paused or game.phase!=game.Phase.EXPLORE:return
 var tap:=false
 var at:=Vector2.ZERO
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  tap=true;at=event.position
 elif event is InputEventScreenTouch and event.pressed:
  tap=true;at=event.position
 elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_E:
  tap=true;at=Vector2(-1,-1)
 if not tap:return
 if inside:
  var world_x := at.x + room_camera_x
  var exit_x := CAVE_EXIT if room.kind == "secret" else 1180.0
  if room_x < 200 and (at.x < 0 or world_x < 210):
   leave(false)
  elif absf(room_x - exit_x) < 140.0 and (at.x < 0 or absf(world_x - exit_x) < 135.0):
   if room.kind != "secret" or drunk:
    leave(true)
   else:
    message = "Возьми кумыс из тайника, чтобы открыть выход"
 else:
  for entry in game.stage.get("doors",[]):
   if entry.kind == "passage" and absf(game.hero.x-entry.at.x)<170 and absf(game.hero.y-entry.at.y)<100:
    var box:=Rect2(entry.at-Vector2(game.camera_x+70,game.camera_y+130),Vector2(140,150))
    if at.x<0 or box.has_point(at):enter(entry);return

func enter(entry:Dictionary, falling := false)->void:
 inside=true
 room=entry
 room_x=200
 room_y=185.0 if falling else ROOM_FLOOR
 room_vy=300.0 if falling else 0.0
 room_grounded = not falling
 room_camera_x = 0.0
 room_safe_x = room_x
 room_jump=false
 room_attack_held=false
 cave_guards.clear()
 cave_arrows.clear()
 if entry.kind=="secret" and not cleared.has(str(entry.at.x)):
  var first_x:float=entry.get("guard_start",460.0)
  var second_x := clampf(first_x + float(entry.get("guard_spacing", 440.0)) + 480.0, 1210.0, 1540.0)
  var starts := [first_x, second_x, 2190.0, 2650.0]
  var zones := [Vector2(275, 730), Vector2(1130, 1580), Vector2(1995, 2325), Vector2(2480, 2725)]
  var gates := [835.0, 1675.0, 2410.0, 2800.0]
  for index in range(starts.size()):
   var wildlife: bool = game.chapter_number == 1
   cave_guards.append({"x": starts[index], "zone": zones[index], "gate": gates[index], "hp": (3 if wildlife else 4) if index < 2 else (4 if wildlife else 5), "bow": not wildlife and index == 1, "wildlife": wildlife, "state": "wait", "timer": 0.55, "hit": 0.0, "down": 0.0})
 statue_hp=0 if cleared.has(str(entry.at.x)) else 4
 drink=false
 drunk=cleared.has(str(entry.at.x))
 game.attack_timer=0
 game.super_timer=0
 game.air_kick=false
 game._clear_input()
 door_open=0.4
 game.audio.play("gate")
 message="Под землёй · победи соперников, чтобы найти кумыс" if not cave_guards.is_empty() else "Тайник уже открыт · выход справа" if entry.kind=="secret" else "Золотой человек · разбей сувенир копьём"

func leave(right:bool)->void:
 inside=false
 var exit_offset:float=room.get("exit_offset",0.0)
 var x:float=room.at.x+(220 if right and room.kind=="passage" else exit_offset if right and exit_offset>0 else -90)
 game.hero=Vector2(x,game._floor_at(x))
 game.vertical_speed=0
 game.air_kick=false
 game.invulnerable=1
 game._clear_input()
 game.audio.play("gate")

func _move_in_room(delta: float, movement: float, sprinting: bool) -> void:
 var cavern: bool = room.kind == "secret"
 var jumping: bool = game._held("jump")
 if jumping and not room_jump and room_grounded:
  room_vy = -650.0
  game.audio.play("jump")
 room_jump = jumping
 room_x = clampf(room_x + movement * (260.0 if sprinting else 185.0) * delta, 90.0, CAVE_EXIT if cavern else 1180.0)
 var floor_y := ROOM_FLOOR
 if cavern:
  for gap in CAVE_GAPS:
   if room_x > gap.x and room_x < gap.y:
    floor_y = INF
    break
  if room_x >= CAVE_LEDGE.position.x and room_x <= CAVE_LEDGE.end.x and room_y <= CAVE_LEDGE.position.y:
   floor_y = CAVE_LEDGE.position.y
 game.dive_previous_y = room_y
 room_vy += game.GRAVITY * delta
 var next_y := room_y + room_vy * delta
 room_grounded = room_vy >= 0.0 and room_y <= floor_y and next_y >= floor_y
 room_y = floor_y if room_grounded else next_y
 if room_grounded:
  room_vy = 0.0
  if floor_y == ROOM_FLOOR:
   room_safe_x = room_x
 if room_y > 735.0:
  game._hurt()
  room_x = room_safe_x
  room_y = ROOM_FLOOR
  room_vy = 0.0
  room_grounded = true
  game.air_kick = false
  game.attack_timer = 0.0

func step(dt:float)->bool:
 effect=maxf(0,effect-dt)
 water_flash=maxf(0,water_flash-dt)
 door_open=maxf(0,door_open-dt)
 queue_redraw()
 if inside:
  game.elapsed+=dt
  game.attack_timer=maxf(0,game.attack_timer-dt)
  game.super_timer=maxf(0,game.super_timer-dt)
  game.invulnerable=maxf(0,game.invulnerable-dt)
  var movement:=float(game._held("right"))-float(game._held("left"))
  var sprinting: bool = game._wants_to_sprint(movement)
  var old_x := room_x
  _move_in_room(dt, movement, sprinting)
  if game.phase == game.Phase.LOST:
   return true
  if movement!=0:
   game.facing=signf(movement)
  if game.attack_timer<=0:
   if game._held("power") and game.super_hits>=game.SUPER_HITS_REQUIRED:game._attack(true)
   elif game._held("attack") and (room_grounded or not room_attack_held):game._attack()
  room_attack_held=game._held("attack")
  _cave_fight(dt)
  _step_cave_arrows(dt)
  if room.kind == "secret":
   room_camera_x = lerpf(room_camera_x, clampf(room_x - 450.0, 0.0, CAVE_WIDTH - 1280.0), minf(1.0, 7.0 * dt))
  game._step_stride(dt, absf(room_x - old_x), sprinting, room_grounded)
  if game.phase==game.Phase.LOST:return true
  var reward_x := CAVE_REWARD if room.kind == "secret" else 680.0
  var guards_clear:=cave_guards.all(func(g):return g.hp<=0)
  if guards_clear and statue_hp>0 and absf(room_x-reward_x)<165 and (reward_x-room_x)*game.facing>0 and game.attack_timer<=0.24 and game.attack_timer>=0.06 and not game.swing_hits.has("souvenir"):
   game.swing_hits.souvenir=true
   statue_hp-=1
   effect=0.24
   game.audio.play("break" if statue_hp==0 else "hit")
   if statue_hp==0:drink=true;message="Торсык с кумысом · подойди, чтобы выпить"
  if guards_clear and drink and absf(room_x-reward_x)<55:
   drink=false;drunk=true
   game.hp=game.MAX_HP
   game.heal_timer=0
   cleared[str(room.at.x)]=true
   effect=1.2
   game.audio.play("heal")
   message="Здоровье полностью восстановлено · выход справа"
  if room_grounded and game.air_kick:
   game.air_kick=false
   game.attack_timer=0
  return true
 if bounce>0:
  bounce=maxf(0,bounce-dt)
  var t:=1.0-bounce/0.85
  var target:=safe
  if safe_platform>=0:target=Vector2(game.route_platforms[safe_platform].get_center().x,game.route_platforms[safe_platform].position.y)
  game.hero=bounce_from.lerp(target,t)-Vector2(0,sin(t*PI)*145)
  game.vertical_speed=0
  game.grounded=bounce<=0
  return true
 return false

func after_motion()->void:
 if inside:return
 for entry in game.stage.get("doors",[]):
  if entry.kind == "secret" and not cleared.has(str(entry.at.x)) and absf(game.hero.x - entry.at.x) < 42.0 and game.hero.y > maxf(game.FLOOR_Y + 75.0, entry.at.y - 92.0):
   enter(entry, true)
   return
 if game.grounded:
  safe=game.hero
  safe_platform=-1
  for i in range(game.route_platforms.size()):
   var platform:Rect2=game.route_platforms[i]
   if absf(platform.position.y-game.hero.y)<1 and game.hero.x+17>platform.position.x and game.hero.x-17<platform.end.x:safe_platform=i
 for lake in game.stage.get("lakes",[]):
  if game.hero.x>lake.x and game.hero.x<lake.y and game.hero.y>game.FLOOR_Y+18 and water_flash<=0 and not game._in_shallows(game.hero.x):
   bounce_from=game.hero
   bounce=0.85
   water_flash=1.5
   game.hp=maxi(0,game.hp-1)
   game.heal_timer=0
   game.invulnerable=1.5
   game.damage_taken+=1
   game.audio.play("water")
   if game.hp==0:
    game.phase=game.Phase.LOST
    game._show_panel("Отдохни у привала","Перепрыгивай между секциями мостков. Вода отнимает сердце.","К чекпойнту")
   break
 for entry in game.stage.get("doors",[]):
  if entry.kind=="passage" and not cleared.has(str(entry.at.x)) and game.hero.x>entry.at.x-95 and game.hero.x<entry.at.x+220:
   game.hero.x=entry.at.x-95

func _label(text:String,p:Vector2,size:int=20,color:=Color("ffe3a0"))->void:
 draw_string(ThemeDB.fallback_font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _prompt(at:Vector2,text:String)->void:
 var p:=Vector2(clampf(at.x,122,1125),at.y)
 var pulse:=sin(game.clock*6)*4
 draw_style_box(game._style(Color("193e40"),Color("dfbd73")),Rect2(p-Vector2(115,95),Vector2(260,47)))
 _label(text,p-Vector2(100,65),17)
 draw_style_box(game._style(Color("fff0cc"),Color("bd9c64")),Rect2(p+Vector2(-7,-25+pulse),Vector2(18,19)))
 draw_line(p+Vector2(-2,-24+pulse),p+Vector2(-2,-40+pulse),Color("fff0cc"),7,true)
 draw_circle(p+Vector2(-2,-40+pulse),3.5,Color("fff0cc"))
 draw_line(p+Vector2(0,-25+pulse),p+Vector2(0,-8+pulse),Color("fff0cc"),5,true)
 draw_arc(p+Vector2(0,-7),14+fposmod(game.clock*13,15),0,TAU,24,Color(1,0.9,0.65,0.5),2)

func _draw()->void:
 if not is_instance_valid(game):return
 if inside:
  _draw_room()
  return
 if game.phase not in [game.Phase.EXPLORE,game.Phase.FIGHT]:return
 var offset:=Vector2(game.camera_x,game.camera_y)
 for x in game.stage.get("checkpoints",[]):
  var p:=Vector2(x,game._floor_at(x))-offset
  if p.x< -80 or p.x>1360:continue
  var active:bool=x<=game.checkpoint_x
  draw_style_box(game._style(Color("464334"),Color("c2ab76")),Rect2(p-Vector2(23,7),Vector2(46,10)))
  draw_arc(p+Vector2(0,-7),15,PI,TAU,24,Color("76dc9b") if active else Color("db6d54"),5,true)
  draw_circle(p+Vector2(0,-8),5,Color("bdffd4") if active else Color("ffa38a"))
 for entry in game.stage.get("doors",[]):
  var p:Vector2=entry.at-offset
  if p.x< -400 or p.x>1600:continue
  if entry.kind == "passage" and absf(game.hero.x-entry.at.x)<230 and absf(game.hero.y-entry.at.y)<150:_prompt(p-Vector2(0,65),"Коснись двери · E")
 for lake in game.stage.get("lakes",[]):
  if lake.y<game.camera_x or lake.x>game.camera_x+1280:continue
  var left:float=maxf(-20,lake.x-game.camera_x)
  var right:float=minf(1300,lake.y-game.camera_x)
  var y:float=game.FLOOR_Y+1-game.camera_y
  var shallow: bool = game._in_shallows((lake.x+lake.y)*0.5)
  var depth:=44.0 if shallow else 180.0
  var bed:=PackedVector2Array()
  var bed_uv:=PackedVector2Array()
  for i in range(25):
   var px:float=lerpf(left,right,i/24.0)
   var world_t:float=clampf((px+game.camera_x-lake.x)/(lake.y-lake.x),0,1)
   var py:float=y+12+22*sin(world_t*PI) if shallow else y+52+44*sin(world_t*PI)
   bed.append(Vector2(px,py))
   bed_uv.append(Vector2((px+game.camera_x)/512,(py+game.camera_y)/512))
  var bed_bottom: float = y + depth + (19.0 if shallow else 90.0)
  bed.append(Vector2(right, bed_bottom))
  bed_uv.append(Vector2((right+game.camera_x)/512, (bed_bottom+game.camera_y)/512))
  bed.append(Vector2(left, bed_bottom))
  bed_uv.append(Vector2((left+game.camera_x)/512, (bed_bottom+game.camera_y)/512))
  texture_repeat=CanvasItem.TEXTURE_REPEAT_MIRROR
  var bed_tint := Color("#968772") if game.chapter_number <= 3 else Color("#b5a174")
  draw_colored_polygon(bed,bed_tint,bed_uv,preload("res://art/animation/sand-ground.png"))
  var surface:=PackedVector2Array()
  var shades:=PackedColorArray()
  for i in range(25):
   var px:float=lerpf(left,right,i/24.0)
   surface.append(Vector2(px,y+sin((px+game.camera_x)*.022+game.clock*1.4)*1.4))
   shades.append(Color("45a6b4b8"))
  surface.append(Vector2(right,y+depth));shades.append(Color("31798355"))
  surface.append(Vector2(left,y+depth));shades.append(Color("31798355"))
  draw_polygon(surface,shades)
  for i in range(int((right-left)/90)):
   var px:float=left+30+i*90
   var ripple:=sin(game.clock*1.4+i)*2
   draw_polyline(PackedVector2Array([Vector2(px,y+6+ripple),Vector2(px+15,y+5+ripple),Vector2(px+33,y+7+ripple)]),Color("c0e7df88"),1.5,true)
 if water_flash>0:
  var p:Vector2=bounce_from-offset
  for i in range(9):
   var t:=1.5-water_flash
   draw_circle(p+Vector2((i-4)*12*t,-sin(t*PI/1.5)*70),3,Color("9fe5ef"))
 # Light, sparse rolling tumbleweeds belong to the world, never to the collider.
 for i in range(0):
  var x:=fposmod(game.camera_x*0.18+game.clock*65+i*813,1550)-120
  var p:=Vector2(x,game.FLOOR_Y-game.camera_y-12)
  draw_set_transform(p,game.clock*2+i)
  game.art.prop(self,"tumbleweed",Vector2.ZERO,Vector2(32,32))
  draw_set_transform(Vector2.ZERO)

func _draw_room()->void:
 var camera := Vector2(room_camera_x, 0)
 var cavern: bool = room.kind == "secret"
 if room.kind=="passage":
  draw_texture_rect(interior,Rect2(0,0,1280,720),false)
 else:
  draw_texture_rect(CAVE_ART,Rect2(-room_camera_x,0,CAVE_WIDTH,720),false,Color("e9d8c4"))
  _draw_cave_passage()
  game.art.cave_mouth(self, Vector2(103.0, ROOM_FLOOR) - camera)
  game.art.embedded_door(self, Vector2(CAVE_EXIT, ROOM_FLOOR) - camera)
 var reward_x := (CAVE_REWARD if cavern else 680.0) - room_camera_x
 for guard in cave_guards:_draw_guard(guard)
 for arrow in cave_arrows:
  game.art.arrow(self, Vector2(arrow.x - room_camera_x, 491), signf(arrow.velocity))
 if statue_hp>0 and cave_guards.all(func(g):return g.hp<=0):
  game.art.prop(self,"golden_man",Vector2(reward_x+(sin(game.clock*70)*4 if effect>0 else 0),570),Vector2(75,130))
  for i in range(statue_hp):draw_circle(Vector2(reward_x-30+i*19,423),4,Color("edd080"))
 elif drink:game.art.prop(self,"kumys",Vector2(reward_x,570),Vector2(47,72))
 var clip:="hurt" if game.hp<=0 or game.invulnerable>1.1 and game.invulnerable<1.5 else "kick" if game.attack_timer>0 and game.air_kick else "jump" if not room_grounded else "hurt" if drunk and effect>0 else "super" if game.attack_timer>0 and game.empowered else "attack" if game.attack_timer>0 else "run" if game.stride_moving else "idle"
 var frame:=clampi(int((0.30-game.attack_timer)*20),0,5) if game.attack_timer>0 else int(game.clock*10)%6
 if clip == "run":
  frame = game._stride_frame()
 if game.hp<=0:
  if game.death_at<0:game.death_at=game.clock
  var fall:=clampf((game.clock-game.death_at)/0.8,0,1)
  game.character_frames.pose(self,"hero","hurt",clampi(int(fall*6),0,5),Vector2(room_x,room_y)-camera,game.facing,Color.WHITE,fall*1.35*game.facing)
 else:
  game.character_frames.pose(self,"hero",clip,frame,Vector2(room_x,room_y)-camera,game.facing)
 game._draw_super_strike(self, Vector2(room_x, room_y) - camera, false)
 if drunk and effect>0:
  game.art.prop(self,"kumys",Vector2(room_x+game.facing*24,478+sin(game.clock*9)*2)-camera,Vector2(22,34))
 draw_style_box(game._style(Color("173d3df2"),Color("dbbd78")),Rect2(326,35,674,68))
 var hall := "ВХОДНОЙ ЗАЛ" if room_x < CAVE_GAPS[0].x else "СИНЯЯ ГАЛЕРЕЯ" if room_x < CAVE_GAPS[1].x else "ЯНТАРНЫЙ ЗАЛ"
 _label(hall if cavern else "ГОСТЕПРИИМНЫЙ АУЛ",Vector2(350,61),16)
 _label(message,Vector2(350,88),18)
 if room_x<260:_prompt(Vector2(95,430),"Назад · E")
 elif cavern and drunk and room_x > CAVE_EXIT - 155.0:
  _prompt(Vector2(CAVE_EXIT - room_camera_x, 430), "Выход · E")
 elif not cavern and room_x>980:_prompt(Vector2(1180,430),"Выход · E")
 if door_open>0:
  draw_rect(Rect2(0,0,1280,720),Color(0.10,0.07,0.04,door_open/0.4))
 if effect>0 and drunk:
  for i in range(8):draw_circle(Vector2(room_x+sin(i)*35,540-fposmod(game.clock*60+i*17,120))-camera,3,Color("a4eac0"))

func _draw_cave_passage() -> void:
 for gap in CAVE_GAPS:
  var left: float = gap.x - room_camera_x
  var right: float = gap.y - room_camera_x
  if right < -40.0 or left > 1320.0:
   continue
  var cut := PackedVector2Array([Vector2(left, 570), Vector2(left + 13, 595), Vector2(left - 9, 659), Vector2(left - 18, 720), Vector2(right + 18, 720), Vector2(right + 4, 657), Vector2(right - 12, 600), Vector2(right, 570)])
  var shades := PackedColorArray([Color("#685047"), Color("#493841"), Color("#302632"), Color("#1b1825"), Color("#1b1825"), Color("#302632"), Color("#493841"), Color("#685047")])
  var uvs := PackedVector2Array()
  for point in cut:
   uvs.append(Vector2((point.x-left)/230.0+0.12, (point.y-570.0)/180.0))
  draw_polygon(cut, shades, uvs, CAVE_STONE)
  draw_polyline(PackedVector2Array([cut[0], cut[1], cut[2], cut[3]]), Color("#8f704d"), 4.0, true)
  draw_polyline(PackedVector2Array([cut[7], cut[6], cut[5], cut[4]]), Color("#75615f"), 3.0, true)
 var ledge := CAVE_LEDGE.position - Vector2(room_camera_x, 0)
 var rock := PackedVector2Array([ledge, ledge + Vector2(72, 0), ledge + Vector2(66, 48), ledge + Vector2(82, 160), ledge + Vector2(12, 180), ledge + Vector2(14, 71)])
 draw_colored_polygon(rock, Color("#686069"), PackedVector2Array([Vector2(0, 0.22), Vector2(1, 0.22), Vector2(0.90, 0.40), Vector2(1.1, 0.95), Vector2(0.1, 1), Vector2(0.16, 0.55)]), CAVE_STONE)
 draw_line(ledge, ledge + Vector2(72, 0), Color("#b1a19a"), 3.0)
 for guard in cave_guards:
  if guard.hp <= 0:
   continue
  var x: float = guard.gate - room_camera_x
  if x < -50 or x > 1330:
   continue
  for offset in [-18, -6, 6, 18]:
   draw_rect(Rect2(x + offset - 2, 421, 5, 149), Color("#3c2f2a"))
   draw_line(Vector2(x + offset, 425), Vector2(x + offset, 567), Color("#ad805a"), 1.5, true)
  for y in [432, 492, 548]:
   draw_rect(Rect2(x - 24, y, 48, 7), Color("#806044"))
   draw_line(Vector2(x - 23, y), Vector2(x + 23, y), Color("#b6906a"), 1.0, true)

func _cave_fight(dt:float)->void:
 var active := -1
 for i in range(cave_guards.size()):
  var guard:Dictionary=cave_guards[i]
  guard.hit=maxf(0,guard.hit-dt)
  if guard.hp<=0:
   guard.down+=dt
  elif active < 0:
   active = i
 if active < 0:
  return
 var guard := cave_guards[active]
 room_x = minf(room_x, guard.gate - 22.0)
 # A wall can stop the hero after the ground position was recorded.
 room_safe_x = minf(room_safe_x, guard.gate - 22.0)
 var dx: float = room_x - guard.x
 guard.moving = false
 if absf(dx) < 350.0:
  guard.timer -= dt
  match guard.state:
   "wait":
    var reach := 245.0 if guard.bow else 112.0
    if absf(dx) > reach + 10.0:
     var next_x := move_toward(guard.x, room_x - signf(dx) * reach, dt * (148.0 if guard.wildlife else 105.0))
     next_x = clampf(next_x, guard.zone.x, guard.zone.y)
     guard.moving = not is_equal_approx(guard.x, next_x)
     guard.x = next_x
    if absf(dx) < (325.0 if guard.bow else 155.0) and guard.timer <= 0.0:
     guard.state = "windup"
     guard.timer = 0.72 if guard.bow else 0.60
   "windup":
    if guard.timer <= 0.0:
     guard.state = "strike"
     guard.timer = 0.24
     if guard.bow:
      var direction := -1.0 if dx < 0.0 else 1.0
      cave_arrows.append({"x": guard.x + direction * 30.0, "velocity": direction * 360.0, "life": 1.5})
      game.audio.play("bow")
     elif absf(dx) < 160.0 and room_y > 500.0:
      game._hurt()
   "strike":
    if guard.timer <= 0.0:
     guard.state = "wait"
     guard.timer = 1.05 if guard.bow else 0.85
 if game.phase == game.Phase.LOST:
  return
 var key := "cave_guard_%d" % active
 var attack_active: bool = game.attack_timer > 0.0 if game.air_kick else game.attack_timer <= 0.24 and game.attack_timer >= 0.06
 if not attack_active or game.swing_hits.has(key):
  return
 var reach := 235.0 if game.empowered else 150.0
 var weapon := Rect2(room_x + (0.0 if game.facing > 0 else -reach), room_y - 110, reach, 110)
 if game.air_kick:
  var top := minf(room_y, game.dive_previous_y) - 5.0
  weapon = Rect2(room_x - 38, top, 76, room_y + 55.0 - top)
 var body := Rect2(guard.x - 39, 495, 78, 75) if guard.wildlife else Rect2(guard.x - 30, 450, 60, 120)
 if not weapon.intersects(body):
  return
 game.swing_hits[key] = true
 game._register_hit()
 guard.hp = maxi(0, guard.hp - game._strike_damage())
 guard.hit = 0.2
 game.audio.play("hit")
 if guard.hp == 0:
  var count := active + 1
  message = "Путь открыт · разбей Золотого человека в дальнем зале" if count == cave_guards.size() else "Соперники %d / %d · проход открыт" % [count, cave_guards.size()]

func _step_cave_arrows(delta: float) -> void:
 for index in range(cave_arrows.size() - 1, -1, -1):
  var arrow := cave_arrows[index]
  var before: float = arrow.x
  arrow.x += arrow.velocity * delta
  arrow.life -= delta
  var near := room_x + 16.0 >= minf(before, arrow.x) and room_x - 16.0 <= maxf(before, arrow.x)
  if near and room_y > 496.0 and room_y < 601.0:
   cave_arrows.remove_at(index)
   game._hurt()
  elif arrow.life <= 0.0:
   cave_arrows.remove_at(index)

func _draw_guard(guard:Dictionary)->void:
 if guard.hp<=0 and guard.down>1.6:return
 var row:=3 if guard.state=="strike" else 2 if guard.state=="windup" else 1 if guard.get("moving", false) else 0
 var step:=int(game.clock*10)%6
 var p:=Vector2(guard.x - room_camera_x, ROOM_FLOOR)
 if p.x < -120 or p.x > 1400:
  return
 var direction:=1.0 if room_x>=guard.x else -1.0
 if guard.wildlife:
  var clip := "down" if guard.hp <= 0 else "hurt" if guard.hit > 0 else "windup" if guard.state == "windup" else "run" if guard.get("moving", false) or guard.state == "strike" else "idle"
  var frame := clampi(int(guard.down * 9.0), 0, 5) if clip == "down" else step
  game.character_frames.pose(self, "boar", clip, frame, p, direction, Color("ffc2aa") if guard.hit > 0 else Color("bca88d"), 0.0, 0.62)
  return
 var atlas := cave_archer if guard.bow else guard_texture
 var cell:=atlas.get_size()/Vector2(6,4)
 var fall:float=clampf(guard.down/0.7,0,1) if guard.hp<=0 else 0.0
 draw_set_transform(p,fall*direction*1.4,Vector2(direction,1))
 draw_texture_rect_region(atlas,Rect2(-75,-144,150,150),Rect2(Vector2(step,row)*cell,cell),Color("ffb3a0") if guard.hit>0 else Color(1,1,1,1-fall*.7))
 draw_set_transform(Vector2.ZERO)
