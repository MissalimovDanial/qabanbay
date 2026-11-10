extends SceneTree
const SCENES := ["main","level_two","level_three","level_four","level_five"]
var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(description)

func _initialize() -> void:
 for chapter in range(1,6):
  var scene = load("res://scenes/%s.tscn" % SCENES[chapter-1]).instantiate()
  var layout = scene.get_node_or_null("Layout")
  check(layout != null,"Level %d has editable layout" % chapter)
  if layout == null:
   scene.free()
   continue
  var actual: Dictionary = layout.data()
  check(actual.platforms.is_empty(),"The route has no raised blocks")
  check(actual.gaps.size()>=10,"Editable dry ravines")
  check(actual.hero_spawn.x<500,"Each chapter starts on its approach")
  check(actual.supplies.size()==2 and actual.supplies.all(func(p):return p.y==550),"Supplies stand on the trail")
  check(actual.decor.all(func(entry):return entry.name!="dead_tree" and (chapter==1 or entry.name!="yurt")),"Only live trees and chapter-one decorative yurts")
  for decor in actual.decor:
   check(decor.at.y == 550,"Level %d scenery grounded" % chapter)
  var rock = layout.get_node("Rocks").get_child(0)
  rock.position += Vector2(71,-200)
  rock.dimensions += Vector2(10,5)
  var moved: Dictionary = layout.data()
  check(moved.rocks[0].get_center().x == actual.rocks[0].get_center().x+71,"Dragging rock updates its horizontal position")
  check(moved.rocks[0].end.y == 550,"Rock remains attached to ground despite Y edits")
  check(moved.rocks[0].size == actual.rocks[0].size+Vector2(10,5),"Inspector size changes the rock dimensions")
  var packed := PackedScene.new()
  check(packed.pack(scene) == OK,"Modified scene can be packed")
  var path := "user://editor-layout-roundtrip-%d.tscn" % chapter
  check(ResourceSaver.save(packed,path) == OK,"Modified scene can be saved")
  var roundtrip = ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate()
  check(roundtrip.get_node("Layout").data() == moved,"Saved edits survive scene reload")
  roundtrip.free()
  scene.free()
 print("Editor layout: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
