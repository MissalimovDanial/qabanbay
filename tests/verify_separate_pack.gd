extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var current: String=ProjectSettings.get_setting_with_override("application/run/main_scene")
 var scene=load(current)
 assert(scene!=null)
 var game=scene.instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 assert(game._chapter_unlocked())
 assert(not ResourceLoader.exists("res://scenes/campaign_map.tscn"))
 for other in ["main","level_two","level_three","level_four","level_five"]:
  var path: String="res://scenes/"+other+".tscn"
  if path!=current:
   assert(not ResourceLoader.exists(path),"Other level must not be packed")
 var actors: Array=["hero","elder","boar","horse"] if game.chapter_number==1 else ["hero","elder","enemy"]
 for actor in actors:
  assert(game.character_frames.frame_count(actor)>0)
  assert(game.character_frames.bank_info(actor).baked)
 assert(game.art._asset("rock").texture.get_width()>20)
 assert(ResourceLoader.exists("res://art/animation/eagle-v2.png"))
 print("INDEPENDENT PACK OK level ",game.chapter_number," | actors ",actors," |6HP ",game.MAX_HP)
 game.queue_free()
 quit()
