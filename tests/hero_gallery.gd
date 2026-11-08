extends SceneTree
class Gallery extends Node2D:
 var frames=preload("res://scripts/character_frames.gd").new()
 var art=preload("res://scripts/level_art.gd").new()
 func _draw()->void:
  art.background(self,0,Vector2(1280,720),1)
  art.ground(self,0,1280,550,[],[])
  draw_string(ThemeDB.fallback_font,Vector2(290,85),"КАБАНБАЙ · ПУТЬ БАТЫРА",HORIZONTAL_ALIGNMENT_LEFT,-1,38,Color("244746"))
  var names:=["Юный","Молодой батыр","Взрослый","Опытный","Зрелый батыр"]
  for i in range(5):
   var x:=155+i*243
   frames.hero_age=i+1
   frames.pose(self,"hero","idle",0,Vector2(x,550))
   draw_string(ThemeDB.fallback_font,Vector2(x-72,310),"УРОВЕНЬ "+str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("244746"))
   draw_string(ThemeDB.fallback_font,Vector2(x-80,345),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("6d5739"))
func _initialize()->void:call_deferred("run")
func run()->void:
 var gallery:=Gallery.new()
 root.add_child(gallery)
 await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://docs/screenshots/hero-ages.png")==OK)
 quit()
