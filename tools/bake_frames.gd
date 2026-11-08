extends SceneTree
func _initialize() -> void:
 var bank = load("res://scripts/character_frames.gd").new()
 var kinds := OS.get_cmdline_user_args()
 if kinds.is_empty():
  kinds = PackedStringArray(["hero","elder","enemy","boar","horse"])
 for kind in kinds:
  var error: Error = bank.bake(kind)
  if error != OK:
   push_error("Bake failed %s: %d" % [kind,error])
   quit(1)
   return
  print("Baked ", JSON.stringify(bank.bank_info(kind)))
 quit()
