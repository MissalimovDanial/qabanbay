@tool
extends Node2D
## Scene-authored level geometry. The same data drives preview and runtime.
## Terrain stays at Y=550; platforms and charms can move freely in both axes.

const Item = preload("res://scripts/editor/level_item.gd")
const Art = preload("res://scripts/level_art.gd")
const FLOOR_Y := 550.0
@export var world_length := 72000.0
@export var arena_start := 70000.0
@export var exit_x := 71400.0
const LABELS := {"rock":"КАМЕНЬ", "gap":"ПРОПАСТЬ", "platform":"ПЛАТФОРМА", "guard":"ДОЗОР", "charm":"ОБЕРЕГ", "decor":"", "hero_spawn":"ГЕРОЙ", "elder":"СТАРЕЙШИНА", "boss_spawn":"БОСС", "spikes":"ШИПЫ","camp":"ЮРТА · ПОДКРЕПЛЕНИЕ","checkpoint":"ПРИВАЛ"}

@export_range(1, 5) var chapter_number := 1:
 set(value):
  chapter_number = value
  refresh_preview()
@export var preview_visible := true:
 set(value):
  preview_visible = value
  refresh_preview()
@export var show_guides := true:
 set(value):
  show_guides = value
  refresh_preview()

var _art: RefCounted
var _actor_banks: Dictionary = {}

func _ready() -> void:
 if Engine.is_editor_hint():
  texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  refresh_preview()

func refresh_preview() -> void:
 if Engine.is_editor_hint() and is_inside_tree():
  queue_redraw()

func _items() -> Array:
 var result: Array = []
 _collect(self, result)
 return result

func _collect(node: Node, result: Array) -> void:
 for child in node.get_children():
  if child.get_script() == Item:
   result.append(child)
  _collect(child, result)

func _item_position(item: Node2D) -> Vector2:
 var relative: Transform2D = item.transform
 var ancestor := item.get_parent()
 while ancestor != null and ancestor != self:
  if ancestor is Node2D:
   relative = ancestor.transform * relative
  ancestor = ancestor.get_parent()
 var p := relative.origin
 if item.kind in ["rock", "gap", "spikes", "guard", "hero_spawn", "elder", "boss_spawn","camp","checkpoint"] or (item.kind == "decor" and item.ground_locked):
  p.y = FLOOR_Y
 return p

func data() -> Dictionary:
 var result := {"doors":[],"lakes":[],"world_end":world_length,"arena_start":arena_start,"exit_x":exit_x,"ravines":[],"platform_motion":[],"guard_specs":[],"checkpoints":[],"rocks":[], "gaps":[], "platforms":[], "guards":[], "spikes":[], "charms":[], "decor":[], "hero_spawn":Vector2(180,FLOOR_Y), "elder_x":480.0 if chapter_number == 1 else 380.0, "boss_spawn":Vector2(4680,FLOOR_Y)}
 result["supplies"] = []
 var items := _items()
 var platforms := items.filter(func(item): return item.kind == "platform")
 for item in items:
  var p := _item_position(item)
  var size: Vector2 = item.dimensions
  match item.kind:
   "secret","passage":
    result.doors.append({"kind":item.kind,"at":p,"exit_offset":item.exit_offset,"guard_start":item.cave_first_guard_x,"guard_spacing":item.cave_guard_spacing})
   "lake":
    var span:=Vector2(p.x-size.x/2,p.x+size.x/2)
    result.lakes.append(span)
    result.gaps.append(span)
    result.ravines.append({"span":span,"depth":0.0})
   "rock":
    result.rocks.append(Rect2(p-Vector2(size.x/2,size.y),size))
   "gap":
    result.gaps.append(Vector2(p.x-size.x/2,p.x+size.x/2))
    result.ravines.append({"span":result.gaps.back(),"depth":item.ravine_depth})
   "platform":
    result.platforms.append(Rect2(p-Vector2(size.x/2,0),size))
    result.platform_motion.append({"travel":item.travel,"period":item.period,"phase":item.motion_phase})
   "guard","camp":
    result.guards.append(p.x)
    result.guard_specs.append({"at":p.x,"count":item.enemy_count,"camp":item.kind=="camp","floor":p.y,"archer_first":item.archer_first})
    if item.kind=="camp":
     result.decor.append({"name":"yurt","at":p+Vector2(230,0),"size":Vector2(290,214),"clearance":110})
   "checkpoint":
    result.checkpoints.append(p.x)
   "spikes":
    result.spikes.append(Vector2(p.x-size.x/2,p.x+size.x/2))
   "charm":
    result.charms.append(p)
   "supply":
    result.supplies.append(p)
    if not item.trial_platform.is_empty():
     var approach := platforms.find(item.get_node_or_null(item.trial_platform))
     if approach >= 0:
      result["wind_trial"] = {"target": p, "approach": approach}
   "decor":
    result.decor.append({"name":item.prop_name,"at":p,"size":size,"clearance":item.clearance,"platform":item.platform_index,"offset":item.platform_offset})
   "hero_spawn":
    result.hero_spawn = p
   "elder":
    result.elder_x = p.x
   "boss_spawn":
    result.boss_spawn = p
 return result

func _draw() -> void:
 if not Engine.is_editor_hint() or not preview_visible:
  return
 if _art == null:
  _art = Art.new()
 var layout := data()
 _art.background(self,0,Vector2(world_length,720),chapter_number)
 _art.ground(self,0,world_length,FLOOR_Y,layout.gaps,layout.ravines)
 for lake in layout.lakes:
  draw_rect(Rect2(lake.x,FLOOR_Y+14,lake.y-lake.x,210),Color("287b9d"))
 for entrance in layout.doors:
  if entrance.kind=="secret":_art.embedded_door(self,entrance.at)
  else:_art.prop(self,"yurt",entrance.at,Vector2(420,295))
 for x in layout.checkpoints:
  draw_arc(Vector2(x,FLOOR_Y-7),15,PI,TAU,20,Color("df7960"),4)
 for decor in layout.decor:
  var at:Vector2=decor.at
  at.y=preload("res://scripts/landform.gd").surface(at.x,layout.ravines,FLOOR_Y)
  var support:int=int(decor.get("platform",-1))
  if support>=0 and support<layout.platforms.size():
   at=layout.platforms[support].position+Vector2(decor.get("offset",0.0),0)
  if decor.name!="banner" and (support>=0 or _clear(decor.at.x,decor.clearance,layout.gaps)):
   _art.prop(self,decor.name,at,decor.size)
 for rect in layout.rocks:
  _art.scenic_rock(self,rect,0,preload("res://scripts/landform.gd").surface(rect.get_center().x,layout.ravines,FLOOR_Y))
 for rect in layout.platforms:
  _art.platform(self,rect,0,chapter_number)
 for p in layout.supplies:
  _art.supply(self, p, 0.0)
 for span in layout.spikes:
  _art.spikes(self,span,0,FLOOR_Y)
 for p in layout.charms:
  draw_circle(p,10,Color("f2cf75"))
  draw_arc(p,13,0,TAU,16,Color("fff0b5"),2)
 for x in layout.guards:
  _preview_actor("enemy",Vector2(x,preload("res://scripts/landform.gd").surface(x,layout.ravines,FLOOR_Y)),-1)
 _preview_actor("hero",layout.hero_spawn,1)
 if chapter_number<=2:
  _draw_actor("elder",0,Vector2(layout.elder_x,FLOOR_Y),1)
 if chapter_number==1:
  _draw_actor("boar",0,layout.boss_spawn,-1)
 elif chapter_number==3:
  _preview_actor("enemy",layout.boss_spawn,-1)
 if chapter_number == 1:
  _art.prop(self,"practice_dummy",Vector2(1410,FLOOR_Y),Vector2(105,145))
  for i in range(3):
   _draw_actor("horse",0,Vector2(arena_start+780+i*175,FLOOR_Y),1)
 if show_guides:
  _draw_guides()

func _clear(x: float, half_width: float, gaps: Array) -> bool:
 for gap in gaps:
  if x+half_width>gap.x and x-half_width<gap.y:
   return false
 return true

func _draw_actor(kind: String, index: int, at: Vector2, facing: float) -> void:
 if not _actor_banks.has(kind):
  var path := "res://art/animation/baked/%s.res" % kind
  _actor_banks[kind] = load(path) if ResourceLoader.exists(path) else null
 var frames: SpriteFrames = _actor_banks[kind]
 if frames == null or not frames.has_animation("all"):
  return
 index = posmod(index,frames.get_frame_count("all"))
 var info: Array = frames.get_meta("frame_info",[])
 var bank: Dictionary = frames.get_meta("bank_info",{})
 if info.size() <= index:
  return
 var frame: Dictionary = info[index]
 var bounds: Rect2i = frame.bounds
 var factor: float = bank.get("scale",1.0)
 var offset := Vector2(float(bounds.position.x)-float(frame.anchor_x),-float(bounds.size.y))
 draw_set_transform(at.round(),0,Vector2(facing*factor,factor))
 draw_texture_rect(frames.get_frame_texture("all",index),Rect2(offset,Vector2(bounds.size)),false)
 draw_set_transform(Vector2.ZERO)

func _draw_guides() -> void:
 var font := ThemeDB.fallback_font
 draw_line(Vector2(0,FLOOR_Y),Vector2(world_length,FLOOR_Y),Color(0.7,1,0.7,0.35),1)
 draw_line(Vector2(arena_start,0),Vector2(3900,810),Color(1,0.6,0.3,0.55),2)
 draw_string(font,Vector2(arena_start+10,35),"АРЕНА",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f5d899"))
 for item in _items():
  var p := _item_position(item)
  var color := Color("8ae9df")
  var rect := Rect2(p-Vector2(item.dimensions.x/2,item.dimensions.y),item.dimensions)
  if item.kind in ["gap","spikes"]:
   color = Color("f5a380")
   rect = Rect2(p-Vector2(item.dimensions.x/2,0),Vector2(item.dimensions.x,100))
  elif item.kind == "platform":
   rect.position = p-Vector2(item.dimensions.x/2,0)
  if item.kind in ["rock","platform","gap","spikes"]:
   draw_rect(rect,Color(color,0.75),false,1)
  draw_line(p-Vector2(7,0),p+Vector2(7,0),color,2)
  draw_line(p-Vector2(0,7),p+Vector2(0,7),color,2)
  if item.kind != "decor":
   var text: String = LABELS.get(item.kind,item.kind)
   draw_string(font,p+Vector2(8,19),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
 for x in range(0,int(world_length)+1,1000):
  draw_line(Vector2(x,790),Vector2(x,800),Color("a2b9a8"),1)
  draw_string(font,Vector2(x+4,815),str(x),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("cedbcc"))

func _preview_actor(kind:String,at:Vector2,facing:int) -> void:
 if chapter_number in [2,3]:
  var tex:Texture2D=load("res://art/animation/riders.png")
  var cell:=tex.get_size()/Vector2(6,4)
  draw_set_transform(at,0,Vector2(facing,1))
  draw_texture_rect_region(tex,Rect2(-122,-183,244,200),Rect2(Vector2(0,0 if kind=="hero" else 2)*cell,cell))
  draw_set_transform(Vector2.ZERO)
 elif kind=="enemy":
  var tex:Texture2D=load("res://art/animation/infantry.png")
  var cell:=tex.get_size()/Vector2(6,4)
  draw_set_transform(at,0,Vector2(facing,1))
  draw_texture_rect_region(tex,Rect2(-75,-144,150,150),Rect2(Vector2.ZERO,cell))
  draw_set_transform(Vector2.ZERO)
 elif kind=="hero":
  var bank:="hero" if chapter_number==1 else "hero-veteran"
  var frames:SpriteFrames=load("res://art/animation/actions/"+bank+".res")
  var age_scale:float=1.04 if chapter_number==5 else 1.0
  draw_set_transform(at,0,Vector2(facing*age_scale,age_scale))
  draw_texture(frames.get_frame_texture("idle",0),Vector2(-195,-185))
  draw_set_transform(Vector2.ZERO)
 else:
  _draw_actor(kind,0,at,facing)
