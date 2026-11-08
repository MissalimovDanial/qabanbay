extends SceneTree
## Rebuild scene-authored starting layouts from the original, tested coordinates.
## This is a one-time migration tool. Do not rerun after hand-editing the scenes.

const Chapters = preload("res://scripts/chapter_data.gd")
const Layout = preload("res://scripts/editor/level_layout.gd")
const Item = preload("res://scripts/editor/level_item.gd")
const SCENES := ["main","level_two","level_three","level_four","level_five"]
const FLOOR_Y := 550.0
var scene_root: Node2D
var layout: Node2D

func _initialize() -> void:
 for chapter in range(1,6):
  var path := "res://scenes/%s.tscn" % SCENES[chapter-1]
  scene_root = load(path).instantiate()
  if scene_root.has_node("Layout"):
   var previous := scene_root.get_node("Layout")
   scene_root.remove_child(previous)
   previous.free()
  layout = Node2D.new()
  layout.name = "Layout"
  layout.set_script(Layout)
  layout.chapter_number = chapter
  scene_root.add_child(layout)
  layout.owner = scene_root
  _build(chapter)
  var packed := PackedScene.new()
  var error := packed.pack(scene_root)
  if error == OK:
   error = ResourceSaver.save(packed,path)
  scene_root.free()
  if error != OK:
   push_error("Cannot write editor scene %s: %s" % [path,error_string(error)])
   quit(1)
   return
  print("Editable scene: ",path)
 quit()

func _group(group_name: String) -> Node2D:
 var group := Node2D.new()
 group.name = group_name
 layout.add_child(group)
 group.owner = scene_root
 return group

func _item(parent: Node2D, item_name: String, kind: String, at: Vector2, dimensions: Vector2) -> Marker2D:
 var item := Marker2D.new()
 item.name = item_name
 item.set_script(Item)
 item.kind = kind
 item.dimensions = dimensions
 item.position = at
 item.ground_locked = kind not in ["platform","charm"]
 item.gizmo_extents = 12.0
 parent.add_child(item)
 item.owner = scene_root
 return item

func _build(chapter: int) -> void:
 var stage := Chapters.stage(chapter)
 var rocks := _group("Rocks")
 var source_rocks: Array = stage.get("rocks",[Rect2(980,505,90,45),Rect2(1930,490,100,60),Rect2(2760,500,110,50)])
 for i in range(source_rocks.size()):
  var rect: Rect2 = source_rocks[i]
  _item(rocks,"Rock%02d" % (i+1),"rock",Vector2(rect.get_center().x,FLOOR_Y),rect.size)
 var gaps := _group("Gaps")
 for i in range(stage.gaps.size()):
  var span: Vector2 = stage.gaps[i]
  _item(gaps,"Gap%02d" % (i+1),"gap",Vector2((span.x+span.y)/2,FLOOR_Y),Vector2(span.y-span.x,260))
 var platforms := _group("Platforms")
 for i in range(stage.platforms.size()):
  var rect: Rect2 = stage.platforms[i]
  _item(platforms,"Platform%02d" % (i+1),"platform",Vector2(rect.get_center().x,rect.position.y),rect.size)
 var spikes := _group("Spikes")
 var source_spikes: Array = stage.get("spikes",[])
 for i in range(source_spikes.size()):
  var span: Vector2 = source_spikes[i]
  _item(spikes,"Spikes%02d" % (i+1),"spikes",Vector2((span.x+span.y)/2,FLOOR_Y),Vector2(span.y-span.x,24))
 var guards := _group("Guards")
 var source_guards: Array = stage.get("guards",[])
 for i in range(source_guards.size()):
  _item(guards,"GuardGroup%02d" % (i+1),"guard",Vector2(source_guards[i],FLOOR_Y),Vector2(66,130))
 var charms := _group("Charms")
 var source_charms: Array = [Vector2(720,495),Vector2(1025,400),Vector2(1720,495),Vector2(1980,390),Vector2(2815,400),Vector2(3440,495)] if chapter == 1 else [Vector2(550,495),Vector2(850,380),Vector2(1650,495),Vector2(2300,380),Vector2(2850,380),Vector2(3650,495)]
 for i in range(source_charms.size()):
  var p: Vector2 = source_charms[i]
  for ledge in stage.platforms:
   if p.x>=ledge.position.x-10 and p.x<=ledge.end.x+10 and p.y>ledge.position.y-35:
    p.y=ledge.position.y-45
  _item(charms,"Charm%02d" % (i+1),"charm",p,Vector2(26,26))
 var scenery := _group("Scenery")
 if chapter == 1:
  _decor(scenery,"yurt",[160.0,480.0],Vector2(280,217),140,stage.gaps)
  _decor(scenery,"tree",[830.0,2200.0,3310.0,5070.0],Vector2(160,247),50,stage.gaps)
  _decor(scenery,"reeds",[610.0,1580.0,3040.0,3570.0],Vector2(65,96),32,stage.gaps)
 else:
  _decor(scenery,"crate",[120.0,380.0,4840.0,5100.0],Vector2(70,60),35,stage.gaps)
  _decor(scenery,"banner",[3820.0,4860.0],Vector2(60,150),30,stage.gaps)
  if chapter == 4:
   _decor(scenery,"yurt",[300.0,5000.0],Vector2(250,195),125,[])
  _decor(scenery,"reeds",[580.0,3700.0,5100.0],Vector2(50,75),25,stage.gaps)
 _decor(scenery,"grass_tuft",[760.0,1200.0,1700.0,2400.0,3100.0,3800.0,5200.0],Vector2(44,28),22,stage.gaps)
 _item(layout,"HeroSpawn","hero_spawn",Vector2(180,FLOOR_Y),Vector2(70,125))
 _item(layout,"Elder","elder",Vector2(480 if chapter == 1 else 380,FLOOR_Y),Vector2(70,115))
 _item(layout,"BossSpawn","boss_spawn",Vector2(4680,FLOOR_Y),Vector2(140,135))

func _decor(parent: Node2D, prop: String, positions: Array, dimensions: Vector2, clearance: float, gaps: Array) -> void:
 for x in positions:
  var clear := true
  for gap in gaps:
   if x+clearance>gap.x and x-clearance<gap.y:
    clear = false
    break
  if not clear:
   continue
  var item := _item(parent,"%s_%d" % [prop.capitalize().replace(" ",""),int(x)],"decor",Vector2(x,FLOOR_Y),dimensions)
  item.prop_name = prop
  item.clearance = clearance
