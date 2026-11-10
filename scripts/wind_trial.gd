extends RefCounted

enum Result { NONE, EXPIRED, COMPLETE }
const DURATION := 12.0
const MARKS := 3

var approach := -1
var target := Vector2.ZERO
var ground_start := Vector2.ZERO
var ground_course := false
var progress := 0
var seconds_left := 0.0
var start_armed := true

func configure(data: Dictionary) -> void:
 approach = data.get("approach", -1)
 target = data.get("target", Vector2.ZERO)
 ground_course = data.has("ground_start")
 ground_start = data.get("ground_start",Vector2.ZERO)
 reset(false)

func reset(keep_completed: bool) -> void:
 if not keep_completed or progress < MARKS:
  progress = 0
 seconds_left = 0.0
 start_armed = true

func _mark(index: int, ledge: Rect2) -> Vector2:
 if index == 2:
  return target + Vector2(44, 0)
 return Vector2(ledge.position.x + ledge.size.x * (0.20 if index == 0 else 0.80), ledge.position.y)

func _route_ledge(platforms: Array) -> Rect2:
 if ground_course:
  return Rect2(ground_start,Vector2(1320,1))
 return platforms[approach] if approach>=0 and approach<platforms.size() else Rect2()

func step(hero: Vector2, platforms: Array, delta: float) -> Result:
 var ledge := _route_ledge(platforms)
 if not ledge.has_area() or progress == MARKS:
  return Result.NONE
 var start := _mark(0, ledge)
 var near_start := absf(hero.x - start.x) < 23.0 and absf(hero.y - start.y) < 23.0
 if not near_start:
  start_armed = true
 if progress > 0:
  seconds_left -= delta
  if seconds_left <= 0.0:
   seconds_left = 0.0
   progress = 0
   return Result.EXPIRED
 if progress == 0:
  if near_start and start_armed:
   progress = 1
   seconds_left = DURATION
   start_armed = false
  return Result.NONE
 var next := _mark(progress, ledge)
 if absf(hero.x - next.x) < 23.0 and absf(hero.y - next.y) < 23.0:
  progress += 1
  if progress == MARKS:
   seconds_left = 0.0
   return Result.COMPLETE
 return Result.NONE

func draw(node: Node2D, platforms: Array, camera: float, time: float) -> void:
 var ledge := _route_ledge(platforms)
 if not ledge.has_area() or progress == MARKS:
  return
 if maxf(ledge.end.x, target.x + 44.0) - camera < -360 or ledge.position.x - camera > node.get_viewport_rect().size.x + 360:
  return
 for index in range(progress, MARKS):
  var at := _mark(index, ledge) - Vector2(camera, 0)
  var center := at - Vector2(0, 35 + sin(time * 4.0 + index) * 4)
  var active := index == progress
  var accent := Color("#ffdb93") if active else Color("#76b1aa")
  var diamond := PackedVector2Array([center - Vector2(0, 13), center + Vector2(11, 0), center + Vector2(0, 13), center - Vector2(11, 0)])
  node.draw_circle(center, 17, Color(accent, 0.16) if active else Color(accent, 0.08))
  node.draw_colored_polygon(diamond, Color("#143f49"))
  diamond.append(diamond[0])
  node.draw_polyline(diamond, accent, 2.0, true)
  node.draw_string(ThemeDB.fallback_font, center + Vector2(-9, 5), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, 18, 13, accent)
 if progress == 0:
  var label_at := _mark(0, ledge) - Vector2(camera + 62, 72)
  node.draw_rect(Rect2(label_at - Vector2(8, 17), Vector2(140, 24)), Color("#17333d"))
  node.draw_string(ThemeDB.fallback_font, label_at, "ТРОПА ВЕТРА · 12 С", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffdb93"))
