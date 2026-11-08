extends SceneTree
func _initialize()->void:
 var art=load("res://scripts/level_art.gd").new()
 art.use_baked=false
 art.prepared.clear()
 DirAccess.make_dir_recursive_absolute("res://art/props-baked")
 var names:Dictionary=art.PROP_REGIONS.duplicate()
 names.merge(art.TERRAIN_REGIONS,true)
 names.merge(art.NEW_PROPS,true)
 for name in names:
  var item:Dictionary=art._asset(name)
  var texture:Texture2D=item.texture
  texture.set_meta("bounds",item.bounds)
  texture.set_meta("region",item.region)
  assert(ResourceSaver.save(texture,"res://art/props-baked/"+name+".res",ResourceSaver.FLAG_COMPRESS)==OK)
 var sound=load("res://scripts/audio.gd").new()
 for chapter in range(1,6):
  sound.chapter=chapter
  var path:="res://art/audio/chapter%d/"%chapter
  DirAccess.make_dir_recursive_absolute(path)
  for cue in sound.CUES:
   assert(ResourceSaver.save(sound._make_sound(cue),path+cue+".res",ResourceSaver.FLAG_COMPRESS)==OK)
  assert(ResourceSaver.save(sound._make_sound("step",true),path+"step_alt.res",ResourceSaver.FLAG_COMPRESS)==OK)
 sound.free()
 print("Prepared props and 115 audio resources offline")
 quit()
