extends "res://scripts/game.gd"

# Each marker owns one battle sector with a limited active wave.
var guards: Array[Dictionary] = []
var sectors: Array[Dictionary] = []
var sector_index := 0
var arrows: Array[Dictionary] = []
var spikes: Array = []
var kills := 0
var duel := "approach"
var duel_mode := "approach"
var duel_cooldown := 0.0
var duel_previous_dx := 0.0
var jump_counted := false
var passes := 0
var shots_fired := 0
var arslan_dir := -1.0
var duel_shot := false
var duel_attack_timer := 0.0
var cover_time := 0.0
var retreat := false
var horse_waiting := false
var horse_x := 0.0
var objective_strip: Label
var riders: Texture2D
var armored_riders: Texture2D
var rider_collapse:Texture2D
var rider_bows: Texture2D
var armored_bows: Texture2D
var standing_riders: Texture2D
var standing_bows: Texture2D
var foot_archer: Texture2D
var foot_melee: Texture2D

func _ready() -> void:
 super._ready()
 if ResourceLoader.exists("res://art/animation/riders.png"):
  riders = load("res://art/animation/riders.png")
 rider_collapse=load("res://art/animation/rider-collapse.png")
 rider_bows = load("res://art/animation/riders-bow.png")
 if _is_mounted():
  armored_riders = load("res://art/animation/riders-armored.png")
  armored_bows = load("res://art/animation/riders-bow-armored.png")
  standing_riders = load("res://art/animation/riders-standing.png")
  standing_bows = load("res://art/animation/riders-bow-standing.png")
 foot_archer = load("res://art/animation/archer.png")
 foot_melee = load("res://art/animation/infantry.png")
 objective_strip = _label(17,Color("ffdf9c"))
 objective_strip.position = Vector2(30,20)
 objective_strip.size = Vector2(850,52)
 ui.add_child(objective_strip)

func _advance() -> void:
 if chapter_number==1:
  super._advance()
  return
 if paused:
  _toggle_pause()
 elif phase == Phase.ENCOUNTER:
  phase = Phase.EXPLORE
  panel.hide()
  _clear_input()
 elif phase == Phase.TITLE:
  _restart(false)
  phase = Phase.INTRO
  dialog_index = 0
  _show_dialog(stage.intro)
 elif phase in [Phase.INTRO,Phase.OUTRO]:
  var lines: Array = stage.intro if phase == Phase.INTRO else stage.outro
  dialog_index += 1
  if dialog_index < lines.size():
   _show_dialog(lines)
  elif phase == Phase.INTRO:
   phase = Phase.EXPLORE
   panel.hide()
   _clear_input()
  else:
   phase = Phase.WON
   _show_results()
 else:
  super._advance()
 _refresh_ui()

func _restart(at_checkpoint: bool) -> void:
 death_at=-1.0
 if at_checkpoint:
  wind_trial.reset(true)
  _reset_stamina()
  hp=MAX_HP
  exploration.inside=false
  exploration.bounce=0
  hero=Vector2(checkpoint_x,checkpoint_y)
  phase=Phase.EXPLORE
  if chapter_number==1 and checkpoint_x>=ARENA_START:
   phase=Phase.FIGHT
   boar=stage.boss_spawn
   boar_hp=boss_max_hp
   boar_state="approach"
   boar_timer=0
   horse_fled=true
   horse_event=5
  vertical_speed=0
  invulnerable=2
  attack_timer=0
  super_timer=0
  air_kick=false
  panel.hide()
  paused=false
  _clear_input()
  return
 super._restart(false)
 dummy_hp=3 if chapter_number==1 else 0
 kills=0
 retreat=false
 horse_waiting=false
 cover_time=0
 duel="approach"
 duel_mode="approach"
 duel_cooldown=0
 passes=0
 shots_fired=0
 arslan_dir=-1
 duel_shot=false
 duel_attack_timer=0
 guards.clear()
 sectors.clear()
 sector_index = 0
 arrows.clear()
 spikes=stage.spikes.duplicate()
 var specs:Array=stage.get("guard_specs",[]).duplicate()
 specs.sort_custom(func(a, b): return a.at < b.at)
 for i in range(specs.size()):
  var spec:Dictionary=specs[i]
  var z:=_zone(spec.at)
  sectors.append({"zone":z,"home":spec.at,"floor":_floor_at(spec.at),"left":spec.count,"sent":0,"id":i,"camp":spec.camp,"archer_first":spec.get("archer_first",false),"triggered":false,"deploy_after":0.0})

func _is_mounted() -> bool:
 return chapter_number in [2,3]

func _zone(x:float) -> Vector2:
 var zone:=Vector2(maxf(80,x-650),minf(WORLD_END-600,x+720))
 for r in route_depths:
  if x>r.span.x and x<r.span.y and r.depth>0:
   return Vector2(r.span.x+100,r.span.y-125)
 for obstacle in route_gaps+spikes:
  if obstacle.y<x:
   zone.x=maxf(zone.x,obstacle.y+150)
  elif obstacle.x>x:
   zone.y=minf(zone.y,obstacle.x-150)
 return zone

func _active(id: int) -> Array:
 return guards.filter(func(g): return g.hp>0 and g.id==id)

func _deploy(sector:Dictionary) -> void:
 if hero.x<sector.zone.x-650 or sector.left<=0 or elapsed<sector.deploy_after:
  return
 var active:=_active(sector.id)
 if not sector.triggered:
  sector.triggered=true
 elif sector.sent==1 and not active.is_empty():
  return
 if active.size()>=(1 if chapter_number==2 else 3):
  return
 var rank:int=sector.sent
 var spawn_x:float=sector.home-80 if rank==0 else sector.home+230 if sector.camp else sector.zone.y
 spawn_x = clampf(spawn_x, sector.zone.x, sector.zone.y)
 var bow: bool = rank % 2 == (0 if sector.archer_first else 1)
 var g:Dictionary={"id":sector.id,"zone":sector.zone,"x":spawn_x,"floor":_floor_at(spawn_x),"hp":int(stage.guard_hp),"bow":bow,"state":"patrol" if rank==0 else "arrive","timer":0.65,"facing":-1.0,"moving":false,"down":0.0,"hit":0.0,"age":0.0,"mounted":_is_mounted()}
 guards.append(g)
 sector.left-=1
 sector.sent+=1
 sector.deploy_after=elapsed+0.85
 if rank>0 and sector.camp:
  audio.play("enemy")

func _tick(delta: float) -> void:
 if chapter_number==1 and phase==Phase.FIGHT:
  super._tick(delta)
  return
 if paused or phase != Phase.EXPLORE:
  return
 super._tick(delta)
 if is_instance_valid(exploration) and (exploration.inside or exploration.bounce>0):return
 if phase != Phase.EXPLORE:
  return
 if chapter_number == 3 and duel in ["bows","spears"]:
  _duel_step(delta)
 else:
  _battle_step(delta)
 if phase == Phase.EXPLORE:
  _fly_arrows(delta)

func _battle_step(delta:float) -> void:
 while sector_index < sectors.size():
  var sector := sectors[sector_index]
  _deploy(sector)
  if sector.left>0 or not _active(sector.id).is_empty():
   hero.x=minf(hero.x,sector.zone.y+30)
   break
  sector_index += 1
 for g in guards:
  _guard_step(g,delta)
  if phase!=Phase.EXPLORE:
   return
 if sector_index < sectors.size():
  var sector := sectors[sector_index]
  var pair:=_active(sector.id).filter(func(g):return g.state!="arrive")
  if pair.size()>=2:
   pair.sort_custom(func(a,b):return a.x<b.x)
   var spacing:=minf(145,(sector.zone.y-sector.zone.x)/maxi(1,pair.size()-1))
   for i in range(1,pair.size()):
    pair[i].x=maxf(pair[i].x,pair[i-1].x+spacing)
   var shift:=maxf(0,pair.back().x-sector.zone.y)
   for member in pair:
    member.x-=shift
    member.floor=_floor_at(member.x)
 var all_clear := sector_index >= sectors.size()
 if chapter_number==3 and duel=="approach" and all_clear and hero.x>=ARENA_START+60:
  duel="bows"
  boar=Vector2(ARENA_START+1250,FLOOR_Y)
  boar_hp=boss_max_hp
  duel_previous_dx=boar.x-hero.x
  _notice("Перепрыгни Арслана верхом три раза")
 elif chapter_number>1 and all_clear and hero.x>=float(stage.exit_x) and (chapter_number!=3 or duel=="rally"):
  _win()

func _space_pair(a: Dictionary,b: Dictionary,z: Vector2) -> void:
 var left: Dictionary = a if a.x<=b.x else b
 var right: Dictionary = b if left==a else a
 var space := minf(145.0,z.y-z.x)
 if right.x-left.x<space:
  left.x=clampf((left.x+right.x-space)*0.5,z.x,z.y-space)
  right.x=left.x+space

func _guard_step(g: Dictionary,dt: float) -> void:
 g.age+=dt
 g.hit=maxf(0,g.hit-dt)
 if g.hp<=0:
  g.down+=dt
  return
 g.floor=_floor_at(g.x)
 if g.state=="arrive":
  var destination:float=clampf(hero.x+250,g.zone.x,g.zone.y)
  var old_x:float=g.x
  g.x=move_toward(g.x,destination,dt*(245 if g.mounted else 190))
  g.moving=absf(g.x-old_x)>0.05
  if g.moving:g.facing=signf(g.x-old_x)
  if g.x>=g.zone.x and g.x<=g.zone.y and (not sectors[g.id].camp or g.age>0.55):
   g.state="patrol"
  return
 var z: Vector2=g.zone
 var dx: float=hero.x-g.x
 var engage: bool = hero.x>=z.x-65 and hero.x<=z.y+70
 g.moving=false
 g.timer-=dt
 match g.state:
  "patrol":
   if not engage:
    return
   g.facing=1.0 if dx>=0 else -1.0
   var reach := 270.0 if g.bow else 116.0
   var dest := clampf(hero.x-g.facing*reach,z.x,z.y)
   var old: float=g.x
   if absf(dx)>reach+12:
    g.x=move_toward(g.x,dest,dt*(235 if g.mounted else 165))
   g.moving=absf(g.x-old)>0.05
   if absf(dx)<(510 if g.bow else 160) and g.timer<=0:
    g.state="aim"
    g.timer=0.56 if g.bow else 0.40
  "aim":
   g.facing=1.0 if dx>=0 else -1.0
   if g.timer<=0:
    g.state="strike"
    g.timer=0.24
    if g.bow:
     _arrow(Vector2(g.x,g.floor-(116 if g.mounted else 77)),g.facing,false)
    elif engage and dx*g.facing>=-12 and absf(dx)<161 and hero.y>g.floor-78 and invulnerable<=0:
     _hurt()
    if not g.bow:
     audio.play("spear")
  "strike":
   if g.timer<=0:
    g.state="patrol"
    g.timer=1.05 if g.bow else 0.65

func _arrow(p: Vector2,dir: float,ally: bool) -> void:
 arrows.append({"p":p,"v":dir*(600 if ally else 375),"ally":ally,"age":0.0})
 audio.play("bow")

func _fly_arrows(dt: float) -> void:
 for i in range(arrows.size()-1,-1,-1):
  var a: Dictionary=arrows[i]
  var before: float=a.p.x
  a.p.x+=a.v*dt
  a.age+=dt
  var body_height := 155.0 if _is_mounted() else 108.0
  var near: bool = hero.x+16>=minf(before,a.p.x) and hero.x-16<=maxf(before,a.p.x)
  if chapter_number==3 and duel=="bows" and near:
   if not a.ally:
    _burst(a.p,Color("dfbd78"),3)
   arrows.remove_at(i)
  elif not a.ally and near and a.p.y>hero.y-body_height and a.p.y<hero.y-5:
   arrows.remove_at(i)
   if invulnerable<=0:
    _hurt()
    if phase == Phase.LOST:
     return
  elif a.age>2.5:
   arrows.remove_at(i)

func _attack(power: bool = false) -> void:
 if attack_timer>0 or (power and super_hits<SUPER_HITS_REQUIRED):
  return
 if chapter_number==3 and duel=="bows":
  super._attack(false)
  shots_fired+=1
  _arrow(hero-Vector2(-28*facing,112),facing,true)
 else:
  super._attack(power)

func _duel_step(dt:float) -> void:
 var arena_end:=ARENA_START+1800
 hero.x=clampf(hero.x,ARENA_START+40,arena_end-60)
 duel_attack_timer=maxf(0,duel_attack_timer-dt)
 duel_cooldown-=dt
 var dx:float=hero.x-boar.x
 if duel=="bows":
  boar.x+=arslan_dir*235*dt
  if absf(dx)<600 and not duel_shot and dx*arslan_dir>0:
   duel_shot=true
   duel_attack_timer=0.30
   _arrow(boar-Vector2(0,112),arslan_dir,false)
  var new_dx:=boar.x-hero.x
  if grounded:
   jump_counted=false
  if new_dx*duel_previous_dx<=0 and absf(new_dx)<80:
   if hero.y<FLOOR_Y-115 and not jump_counted:
    passes+=1
    jump_counted=true
    audio.play("pickup")
   elif hero.y>FLOOR_Y-95 and invulnerable<=0:
    _hurt()
  duel_previous_dx=new_dx
  if boar.x<ARENA_START+90 or boar.x>arena_end-90:
   boar.x=clampf(boar.x,ARENA_START+90,arena_end-90)
   arslan_dir=-arslan_dir
   duel_shot=false
  if passes>=3:
   duel="spears"
   arrows.clear()
   duel_mode="approach"
   duel_cooldown=0.8
   _notice("Три прыжка! Теперь — поединок на копьях.")
 else:
  match duel_mode:
   "approach":
    arslan_dir=1 if dx>0 else -1
    boar.x=move_toward(boar.x,hero.x,dt*220)
    if absf(dx)<300 and duel_cooldown<=0:
     duel_mode="windup"
     duel_cooldown=0.70
   "windup":
    if duel_cooldown<=0:
     duel_mode="thrust"
     duel_cooldown=0.70
     duel_attack_timer=0.30
     audio.play("spear")
   "thrust":
    boar.x=clampf(boar.x+arslan_dir*370*dt,ARENA_START+60,arena_end-60)
    if absf(boar.x-hero.x)<125 and hero.y>FLOOR_Y-110 and invulnerable<=0:
     _hurt()
    if duel_cooldown<=0:
     duel_mode="recover"
     duel_cooldown=0.85
   "recover":
    if duel_cooldown<=0:
     duel_mode="approach"
 boar_facing=arslan_dir

func _resolve_attack() -> void:
 if chapter_number==1:
  super._resolve_attack()
 if attack_timer<=0 or phase!=Phase.EXPLORE:
  return
 if chapter_number==3 and duel=="spears" and _can_hit(Rect2(boar.x-40,FLOOR_Y-175,80,175),"arslan"):
  swing_hits.arslan=true
  _register_hit()
  boar_hp=maxi(0,boar_hp-_strike_damage())
  hit_flash=0.16
  audio.play("hit")
  if boar_hp==0:
   duel="rally"
   defeated_at=clock
   arrows.clear()
   _notice("Арслан повержен. Путь к отряду открыт.")
 for i in range(guards.size()):
  var g: Dictionary=guards[i]
  var key := "soldier_%d"%i
  if g.hp>0 and _can_hit(Rect2(g.x-35,g.floor-(170 if g.mounted else 125),70,170),key):
   swing_hits[key]=true
   _register_hit()
   g.hp=maxi(0,g.hp-_strike_damage())
   g.hit=0.20
   _burst(Vector2(g.x,g.floor-75),Color("eac28a"),7)
   audio.play("hit")
   if g.hp==0:
    kills+=1
    sectors[g.id].deploy_after=elapsed+0.9

func _toggle_pause() -> void:
 super._toggle_pause()
 if paused:
  body.text = "Шаг: A / D · Бег: K + направление · Прыжок: Пробел · Бег: удерживать K\nКопьё или лук: J / G · Суперудар: L\n\nСледи за тетивой лучника и уклоняйся до попадания."

func _hurt() -> void:
 if invulnerable>0:
  return
 hp-=1
 invulnerable=1.35
 heal_timer=0
 damage_taken+=1
 shake=7
 audio.play("hurt")
 if hp<=0:
  deaths+=1
  phase=Phase.LOST
  if exploration.inside:
   _show_panel("Пещера", "Отступай, когда соперник готовится к атаке. Затем отвечай копьём.", "К привалу")
  elif chapter_number == 1:
   _show_panel("Поднимись, Ерасыл", "Перепрыгни бросок кабана и отвечай копьём.", "К привалу")
  else:
   _show_panel("Отряд рассеян","Попробуй снова. Следи за замахом воина и тетивой лучника. Перепрыгни стрелу или отступи от замаха.","Повторить бой")

func _win() -> void:
 if chapter_number==1:
  super._win()
  return
 if victory_timer>=0:
  return
 victory_timer=0.0
 victory_line=["","Это была нелёгкая победа.","Я выдержал поединок. Теперь — к своим.","Путь свободен. Я иду дальше.","Я дал отряду время. Пора отступать."][chapter_number-1]
 phase=Phase.CINEMATIC
 _clear_input()
 audio.play("win")

func _tick_cinematic(dt:float) -> void:
 if chapter_number==1:
  super._tick_cinematic(dt)
  return
 if victory_timer>=0:
  victory_timer+=dt
  if victory_timer>=(11.0 if chapter_number==5 else 4.5):
   _finish_level()

func _refresh_ui() -> void:
 super._refresh_ui()
 if is_instance_valid(objective_strip):
  objective_strip.hide()

func _draw() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 if chapter_number==1:
  super._draw()
  if phase in [Phase.EXPLORE,Phase.FIGHT]:
   _draw_guard_sprites(get_viewport_rect().size.x)
   for arrow in arrows:
    art.arrow(self,arrow.p-Vector2(camera_x,0),signf(arrow.v))
  return
 if stage.is_empty():
  return
 if chapter_number==5 and phase==Phase.CINEMATIC and victory_timer>=4.5:
  chapter_screen.draw_story(self,5,victory_timer,false)
  draw_style_box(_style(Color("173b3bf2"),Color("edcf88")),Rect2(170,550,940,100))
  draw_multiline_string(ThemeDB.fallback_font,Vector2(195,582),"Жанибек: «В седло, батыр! Отряд уже за склоном».\nКабанбай принимает поводья и вместе с Жанибеком уходит в степь.",HORIZONTAL_ALIGNMENT_CENTER,890,22,-1,Color("fff0ca"))
  return
 if phase in [Phase.INTRO,Phase.OUTRO,Phase.ENCOUNTER]:
  var picture := [0,0,1,3,4][chapter_number-1] as int
  if chapter_number==5 and phase==Phase.ENCOUNTER:
   picture=5
  elif phase == Phase.ENCOUNTER or (chapter_number==3 and phase==Phase.OUTRO):
   picture=2
  elif phase==Phase.OUTRO:
   picture=[0,1,2,4,5][chapter_number-1]
  chapter_screen.draw_story(self,picture,clock,false)
  return
 var size := get_viewport_rect().size
 art.background(self,camera_x,size,chapter_number)
 art.lakeside(self,stage.get("scenic_lakes",[]),camera_x,clock)
 if chapter_number>=4:
  _distant_troops(size.x)
 art.ground(self,camera_x,size.x,FLOOR_Y,route_gaps,route_depths)
 for rect in route_platforms:
  art.platform(self,rect,camera_x,chapter_number,route_depths)
 _draw_scenic_rocks()
 _draw_layout_decor()
 for s in spikes:
  art.spikes(self,s,camera_x,FLOOR_Y)
 if chapter_number>=2:
  _draw_elder(Vector2(_elder_x()-camera_x,FLOOR_Y))
 for i in range(route_charms.size()):
  if not collected.has(i):
   art.asyk(self, route_charms[i] - Vector2(camera_x, 0), i)
 _draw_guard_sprites(size.x)
 if chapter_number==3 and duel in ["bows","spears"]:
  var moving := duel=="bows" or duel_mode in ["approach","thrust"]
  _rider(boar-Vector2(camera_x,0),arslan_dir,false,duel_attack_timer>0,duel=="bows",true,_army_color(),-1,false,moving,duel_attack_timer)
 elif chapter_number==3 and clock-defeated_at<1.3:
  _fallen_rider(boar-Vector2(camera_x,0),arslan_dir,clock-defeated_at)
 if _is_mounted():
  var ride_frame := _stride_frame() if grounded else _air_frame(vertical_speed,715.0)
  var pitch := 0.0 if grounded else clampf(vertical_speed / 715.0, -1.0, 1.0) * 0.14
  _rider(hero-Vector2(camera_x,0),facing,true,attack_timer>0,chapter_number==3 and duel=="bows",false,Color("ffe3c9") if invulnerable>1.05 else Color.WHITE,ride_frame,true,stride_moving or not grounded,attack_timer,pitch)
 else:
  _draw_hero(hero-Vector2(camera_x,0))
 _draw_super_strike(self, hero - Vector2(camera_x, 0), _is_mounted())
 for a in arrows:
  var p: Vector2=a.p-Vector2(camera_x,0)
  var dir:=signf(a.v)
  art.arrow(self,p,dir)
 for particle in particles:
  draw_rect(Rect2(particle.p-Vector2(camera_x,0),Vector2(4,4)),particle.color)
 _draw_victory_line()
 if chapter_number==3 and duel=="bows" and phase==Phase.EXPLORE:
  _draw_duel_counter()

func _draw_guard_sprites(width:float) -> void:
 for g in guards:
  if g.hp<=0 and g.down>2.8:
   continue
  var p:=Vector2(g.x-camera_x,g.floor)
  if p.x < -260 or p.x>width+260:
   continue
  var state := "down" if g.hp<=0 else "hurt" if g.hit>0 else str(g.state)
  if g.mounted and g.hp<=0:
   _fallen_rider(p,g.facing,g.down)
  elif g.mounted:
   _rider(p,g.facing,false,state=="strike",g.bow,false,_army_color(),-1,false,g.moving,g.timer * 1.25)
  elif foot_archer and foot_melee:
   _infantry(p,g)
  else:
   var clip := "down" if state=="down" else "hurt" if state=="hurt" else "attack" if state=="strike" else "windup" if state=="aim" else "run" if g.moving else "idle"
   var step := clampi(int(g.down*9),0,5) if clip=="down" else int(clock*(15 if state=="strike" else 7))%6
   character_frames.pose(self,"enemy",clip,step,p,g.facing,Color("aa927a"))
   if g.bow and g.hp>0:
    _bow(p-Vector2(0,75),g.facing,state=="aim")

func _infantry(p:Vector2,g:Dictionary) -> void:
 var atlas:Texture2D=foot_archer if g.bow else foot_melee
 var clip_row:=3 if g.state=="strike" else 2 if g.state=="aim" else 1 if g.moving else 0
 var step:=int(clock*(15 if g.moving else 6))%6
 if g.state=="aim":
  var windup:float=0.56 if g.bow else 0.40
  step=clampi(int((windup-g.timer)/windup*6),0,5)
 elif g.state=="strike":
  step=clampi(int((0.24-g.timer)/0.24*6),0,5)
 var fall:=clampf(g.down/0.65,0,1) if g.hp<=0 else 0.0
 var cell:=atlas.get_size()/Vector2(6,4)
 _shadow(p,26)
 draw_set_transform(p,fall*1.40*g.facing,Vector2(g.facing,1))
 draw_texture_rect_region(atlas,Rect2(-75,-144,150,150),Rect2(Vector2(step,clip_row)*cell,cell),Color("ffbdaa") if g.hit>0 else Color(_army_color(),1-fall*0.65))
 draw_set_transform(Vector2.ZERO)

func _bow(p: Vector2,dir: float,drawn: bool) -> void:
 var tip:=p+Vector2(36*dir,0)
 var a:=tip+Vector2(-12*dir,-24)
 var b:=tip+Vector2(-12*dir,24)
 draw_polyline(PackedVector2Array([a,tip+Vector2(2*dir,-10),tip+Vector2(2*dir,10),b]),Color("cfaa69"),4,true)
 draw_polyline(PackedVector2Array([a,tip-Vector2((34 if drawn else 12)*dir,0),b]),Color("f3ddb2"),1.5,true)

func _companion(p:Vector2,dir:float) -> void:
 _rider(p,dir,true,false,false,false,Color(0.78,0.76,0.60))
 draw_string(ThemeDB.fallback_font,p-Vector2(46,181),"ЖАНИБЕК",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffdb9b"))

func _rider(p: Vector2,dir: float,ally: bool,strike: bool,bow: bool,leader: bool,tint:=Color.WHITE,frame_step:int=-1,armored:=false,moving:=true,strike_left:=0.0,pitch:=0.0) -> void:
 var step:=int(clock*15)%6 if frame_step<0 else frame_step
 var factor:=1.10 if leader else 1.0
 _shadow(p,64)
 var atlas := rider_bows if bow and rider_bows else riders
 if armored:
  atlas = armored_bows if bow else armored_riders
 var standing := standing_bows if bow else standing_riders
 if not moving and standing:
  atlas = standing
  step = clampi(int((0.30-strike_left)*20.0),0,5) if strike else 0
 if atlas:
  var cell := atlas.get_size()/Vector2(6,4)
  var row := (0 if ally else 2) + int(strike)
  draw_set_transform(p,pitch*dir,Vector2(dir*factor,factor))
  draw_texture_rect_region(atlas,Rect2(-122,-183,244,200),Rect2(Vector2(step,row)*cell,cell),tint)
  draw_set_transform(Vector2.ZERO)
 else:
  character_frames.pose(self,"horse","gallop",step,p,dir,Color.WHITE if ally else Color("b6a89e"))
  character_frames.pose(self,"hero" if ally else "enemy","attack" if strike else "idle",step,p-Vector2(0,78),dir)
 if bow and not rider_bows:
  _bow(p-Vector2(0,119),dir,strike or duel=="bows")

func _distant_troops(width:float) -> void:
 if riders==null or chapter_number<3:
  return
 var count:=10 if chapter_number<5 else 14+mini(12,int(cover_time))
 var cell:=riders.get_size()/Vector2(6,4)
 for i in range(count):
  var ally:=i%3==0
  var dir:=1.0 if ally else -1.0
  var t:=clock*(22+i%4*4)*dir-camera_x*(0.22+i%3*0.035)
  var x:=fposmod(i*137.0+t,width+200)-100
  var y:=422.0+i%3*15
  var h:=29.0+i%3*8
  var strike := sin(clock*1.35+i*1.7)>0.55
  var row := (0 if ally else 2)+int(strike)
  draw_rect(Rect2(x-6*dir-5,y-3,10,3),Color(0.77,0.65,0.45,0.28))
  draw_set_transform(Vector2(x,y),0,Vector2(dir,1))
  draw_texture_rect_region(riders,Rect2(-h*0.66,-h,h*1.35,h),Rect2(Vector2((int(clock*8)+i)%6,row)*cell,cell),Color(0.63,0.58,0.52,0.8))
 draw_set_transform(Vector2.ZERO)

func _army_color() -> Color:
 return [Color.WHITE,Color("b5c5d4"),Color("e6b8b5"),Color("d8c09b"),Color("a9b9b0")][chapter_number-1]

func _fallen_rider(p:Vector2,dir:float,time:float) -> void:
 var cell:=rider_collapse.get_size()/Vector2(3,2)
 var frame:=clampi(int(time*6),0,5)
 var fade:=1.0-clampf((time-1.9)/0.9,0,1)
 _shadow(p,72)
 draw_set_transform(p,0,Vector2(dir,1))
 draw_texture_rect_region(rider_collapse,Rect2(-122,-176,244,200),Rect2(Vector2(frame%3,floori(frame/3.0))*cell,cell),Color(_army_color(),fade))
 draw_set_transform(Vector2.ZERO)
 if time<0.7:
  for i in range(6):
   draw_circle(p+Vector2((i-3)*13*(1+time),-7-sin(time*PI)*i),2+time*5,Color(0.67,0.53,0.34,(1-time/0.7)*0.45))

func _draw_duel_counter() -> void:
 var center:=Vector2(640,64)
 draw_style_box(_style(Color("173b3bf2"),Color("d8bd7f")),Rect2(center-Vector2(170,36),Vector2(340,76)))
 draw_string(ThemeDB.fallback_font,center-Vector2(127,10),"ПЕРЕПРЫГНИ АРСЛАНА",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f7dfae"))
 for i in range(3):
  var p:=center+Vector2((i-1)*48,15)
  draw_circle(p,13,Color("e1bf6c") if i<passes else Color("36534e"))
  draw_arc(p,13,0,TAU,24,Color("d2bd89"),1.5,true)
  draw_string(ThemeDB.fallback_font,p+Vector2(-5,6),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("173732") if i<passes else Color("b8c4b4"))
