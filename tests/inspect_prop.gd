extends SceneTree
func _initialize()->void:
 var tex:Texture2D=load("res://art/props-baked/practice_dummy.res")
 print("Dummy texture ",tex.get_size()," bounds ",tex.get_meta("bounds"))
 tex.get_image().save_png("res://docs/screenshots/dummy-resource.png")
 quit()
