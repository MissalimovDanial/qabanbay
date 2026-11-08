@tool
extends Node2D
func _process(_dt:float)->void:
 if Engine.is_editor_hint():queue_redraw()
func _draw()->void:
 if not Engine.is_editor_hint():return
 draw_texture_rect(preload("res://art/animation/journey-map.png"),Rect2(38,129,872,533),false)
 var previous:Vector2=Vector2.ZERO
 for point in get_children():
  if previous!=Vector2.ZERO:draw_line(previous,point.position,Color("fff1b8"),4)
  draw_circle(point.position,32,Color("215452"))
  draw_arc(point.position,32,0,TAU,32,Color("e8c578"),3)
  draw_string(ThemeDB.fallback_font,point.position+Vector2(-25,7),point.name,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff1ce"))
  previous=point.position
