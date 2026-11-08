extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var started := Time.get_ticks_msec()
 var bank = load("res://scripts/character_frames.gd").new()
 for kind in ["hero","elder","enemy","boar","horse"]:
  var expected := 16 if kind == "horse" else 32
  assert(bank.available_frame_count(kind) == expected)
  var info_bank: Dictionary = bank.bank_info(kind)
  assert(info_bank.baked and info_bank.fallback_count == 0, "Every bank must load pre-baked whole poses")
  var actions:SpriteFrames=load("res://art/animation/actions/"+kind+".res")
  for clip in bank.CLIPS[kind]:
   assert(actions.has_animation(clip))
   assert(actions.get_frame_count(clip)==6,"Every playable action has six frames")
   for f in range(6):
    assert(actions.get_frame_texture(clip,f).get_image().get_used_rect().has_area())
  for index in range(expected):
   var info: Dictionary = bank.frame_info(kind,index)
   var frame: Dictionary = bank._bank(kind).frames[index]
   var image: Image = frame.texture.get_image()
   assert(image.get_used_rect().end.y == image.get_height(), "%s frame%d opaque support contact" % [kind,index])
   assert(image.get_height() > 20 and info.draw_height > 20 and info.draw_height < 280)

 print("Animation banks: six frames per action plus 144 source bounds and ground contacts verified; ms ", Time.get_ticks_msec() - started)
 quit()
