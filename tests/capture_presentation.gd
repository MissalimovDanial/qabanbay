extends SceneTree
const Presentation = preload("res://scripts/chapter_presentation.gd")
const Chapters = preload("res://scripts/chapter_data.gd")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
 for chapter in range(1,6):
  var cover = Presentation.new()
  root.add_child(cover)
  cover.configure(chapter,Chapters.stage(chapter),false,"")
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/screenshots/school-title-%d.png" % chapter)
  cover.free()
  await process_frame
 quit()
