extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func snap(name: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
 var map = load("res://scenes/campaign_map.tscn").instantiate()
 root.add_child(map)
 map.set_process(false)
 await snap("school-map")
 map.queue_free()
 await process_frame
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.audio.enabled = false
 await snap("school-title-integrated")
 game._restart(false)
 game.training_stage = 6
 game.lesson_open = false
 game.npc_passed = true
 game.hero = Vector2(1250,550)
 game.camera_x = 850
 game._attack()
 for entry in [[2.0,"empty"],[1.5,"quarter"],[1.0,"half"],[0.5,"three-quarter"],[0.0,"ready"]]:
  game.attack_cooldown = entry[0]
  game._refresh_ui()
  game.queue_redraw()
  await snap("school-attack-"+entry[1])
 game.queue_free()
 await process_frame
 quit()
