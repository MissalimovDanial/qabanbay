extends Control

var chapter_title := ""
var tip := ""
var ratio := 0.0
var clock := 0.0

func _process(delta: float) -> void:
 clock += delta
 queue_redraw()

func _draw() -> void:
 var viewport := get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO, viewport), Color("#102b34"))
 var scale_factor := minf(viewport.x / 1280.0, viewport.y / 720.0)
 draw_set_transform((viewport - Vector2(1280, 720) * scale_factor) * 0.5, 0.0, Vector2.ONE * scale_factor)
 draw_colored_polygon(PackedVector2Array([Vector2(0,495),Vector2(215,390),Vector2(366,460),Vector2(615,365),Vector2(818,459),Vector2(1004,379),Vector2(1280,486),Vector2(1280,720),Vector2(0,720)]), Color("#183d46"))
 draw_rect(Rect2(32, 32, 1216, 656), Color("#bd9c62"), false, 2)
 var font := ThemeDB.fallback_font
 draw_string(font, Vector2(0,245), "ПУТЬ БАТЫРА", HORIZONTAL_ALIGNMENT_CENTER, 1280, 22, Color("#e6bd76"))
 draw_string(font, Vector2(0,322), chapter_title, HORIZONTAL_ALIGNMENT_CENTER, 1280, 47, Color("#fff0cb"))
 var bar := Rect2(390,390,500,11)
 draw_rect(bar, Color("#081c23"))
 if ratio < 0.0:
  var travel := (sin(clock * 5.0) * 0.5 + 0.5) * 405.0
  draw_rect(Rect2(bar.position + Vector2(travel, 0), Vector2(95, bar.size.y)), Color("#71c5c1"))
 else:
  draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("#71c5c1"))
 for i in range(3):
  var p := Vector2(618 + i * 22, 443)
  var alpha := 0.4 + 0.6 * (sin(clock * 5.0 - i * 1.3) * 0.5 + 0.5)
  draw_colored_polygon(PackedVector2Array([p+Vector2(0,-5),p+Vector2(5,0),p+Vector2(0,5),p+Vector2(-5,0)]), Color(0.90,0.74,0.46,alpha))
 draw_string(font, Vector2(0,596), tip, HORIZONTAL_ALIGNMENT_CENTER, 1280, 22, Color("#dbebe4"))
 draw_set_transform(Vector2.ZERO)
