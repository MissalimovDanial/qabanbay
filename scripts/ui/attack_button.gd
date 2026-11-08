@tool
extends Button
@export var action := "attack"
## The super chamber fills from bottom to top. Normal attacks stay available.
@export var super_symbol := false
@export_range(0.0, 1.0) var charge_ratio := 1.0:
 set(value):
  var next:=clampf(value,0.0,1.0)
  if is_equal_approx(charge_ratio,next):return
  charge_ratio=next
  queue_redraw()

func _ready() -> void:
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 tooltip_text = "Копьё: J / G · Суперудар: L"

func charged_polygon() -> PackedVector2Array:
 var circle := PackedVector2Array()
 var center := size * 0.5
 var radius := minf(size.x, size.y) * 0.39
 var boundary := center.y + radius * (1.0 - 2.0 * charge_ratio)
 if charge_ratio <= 0.0:
  return circle
 for i in range(97):
  var angle := TAU * float(i) / 96.0
  circle.append(center + Vector2(cos(angle), sin(angle)) * radius)
 var result := PackedVector2Array()
 for i in range(circle.size() - 1):
  var a := circle[i]
  var b := circle[i + 1]
  var inside_a := a.y >= boundary
  var inside_b := b.y >= boundary
  if inside_a:
   result.append(a)
  if inside_a != inside_b:
   result.append(a.lerp(b, (boundary - a.y) / (b.y - a.y)))
 return result

func _draw() -> void:
 var center := size * 0.5
 var radius := minf(size.x, size.y) * 0.39
 draw_circle(center + Vector2(0, 3), radius + 10, Color(0.01, 0.025, 0.035, 0.6))
 draw_circle(center, radius + 8, Color("352e22"))
 draw_arc(center, radius + 7, 0, TAU, 80, Color("957747"), 2, true)
 draw_circle(center, radius + 3, Color("0b151b"))
 draw_arc(center, radius + 3, 0, TAU, 80, Color("d8b66a"), 2, true)
 draw_circle(center, radius, Color("060b11"))
 for side in [-1,1]:
  var p:Vector2=center+Vector2(side*(radius+5),0)
  draw_polyline(PackedVector2Array([p+Vector2(-side*3,-12),p+Vector2(-side*9,-15),p+Vector2(-side*13,-9),p+Vector2(-side*9,-4),p+Vector2(0,0),p+Vector2(-side*9,4),p+Vector2(-side*13,9),p+Vector2(-side*9,15),p+Vector2(-side*3,12)]),Color("d8b66a"),1.5,true)
 var fill := charged_polygon()
 if fill.size() >= 3:
  draw_colored_polygon(fill, Color("14535a") if charge_ratio < 1.0 else Color("226d72"))
  # A subtle reflected strip gives the blue chamber depth without hiding progress.
  var highlight := PackedVector2Array()
  for point in fill:
   highlight.append(Vector2(center.x + (point.x-center.x)*0.94, point.y))
  draw_colored_polygon(highlight, Color(0.45,0.72,0.68,0.12))
 if charge_ratio > 0.001 and charge_ratio < 0.999:
  var cut := radius * (1.0 - 2.0 * charge_ratio)
  var width := sqrt(maxf(0.0, radius * radius - cut * cut))
  var y := center.y + cut
  draw_line(Vector2(center.x-width, y), Vector2(center.x+width, y), Color("dbc17f"), 2, true)
 if super_symbol:
  draw_arc(center,radius-11,-PI*0.9,PI*0.35,28,Color("ffdc80"),2.5,true)
  for corner in [Vector2(-22,-19),Vector2(21,19)]:
   var p:Vector2=center+corner
   draw_colored_polygon(PackedVector2Array([p+Vector2(0,-5),p+Vector2(3,0),p+Vector2(0,5),p-Vector2(3,0)]),Color("ffdc80"))
 var ink:=Color("f8e7bf")
 match action:
  "left","right":
   var dir:=1 if action=="right" else -1
   draw_colored_polygon(PackedVector2Array([center+Vector2(-18*dir,-8),center+Vector2(0,-8),center+Vector2(0,-20),center+Vector2(23*dir,0),center+Vector2(0,20),center+Vector2(0,8),center+Vector2(-18*dir,8)]),ink)
  "jump":
   draw_colored_polygon(PackedVector2Array([center+Vector2(-8,21),center+Vector2(-8,0),center+Vector2(-20,0),center+Vector2(0,-23),center+Vector2(20,0),center+Vector2(8,0),center+Vector2(8,21)]),ink)
  "run":
   draw_circle(center+Vector2(6,-22),6,ink)
   draw_polyline(PackedVector2Array([center+Vector2(0,-12),center+Vector2(-7,1),center+Vector2(8,9),center+Vector2(16,22)]),ink,5,true)
   draw_polyline(PackedVector2Array([center+Vector2(-7,1),center+Vector2(-17,16),center+Vector2(-26,16)]),ink,5,true)
   draw_polyline(PackedVector2Array([center+Vector2(-17,-7),center+Vector2(-6,-12),center+Vector2(11,-3),center+Vector2(20,-9)]),ink,4,true)
  _:
   draw_line(center+Vector2(-16,18),center+Vector2(13,-15),ink,4,true)
   draw_colored_polygon(PackedVector2Array([center+Vector2(10,-12),center+Vector2(14,-27),center+Vector2(25,-29),center+Vector2(21,-14)]),ink)
   draw_line(center+Vector2(5,-10),center+Vector2(17,0),ink,3,true)
 if action=="power" and charge_ratio<1:
  draw_string(ThemeDB.fallback_font,center+Vector2(-17,32),str(roundi(charge_ratio*11))+"/11",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
 draw_arc(center, radius - 2, -PI*0.82, -PI*0.23, 24, Color(1,1,1,0.12), 2, true)
 if is_pressed():
  draw_arc(center, radius+5, 0, TAU, 80, Color("fff0ad"), 3, true)
