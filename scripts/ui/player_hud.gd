extends Control

const GOLD := Color("#d7b374")
const INK := Color("#102b34")
const BOLT := [Vector2(12,0),Vector2(26,0),Vector2(18,11),Vector2(26,11),Vector2(7,32),Vector2(12,18),Vector2(3,18)]

var portrait: Texture2D
var portrait_region: Rect2
var heart: Texture2D
var empty_heart: Texture2D
var health := 6
var stamina_percent := 100
var exhausted := false

func configure(frames: SpriteFrames, age: int, full_heart: Texture2D, lost_heart: Texture2D) -> void:
 portrait = frames.get_frame_texture("idle", 0)
 if age == 1:
  portrait_region = Rect2(166, 63, 63, 63)
 elif age <= 3:
  portrait_region = Rect2(156, 24, 65, 65)
 else:
  portrait_region = Rect2(154, 18, 82, 82)
 heart = full_heart
 empty_heart = lost_heart

func update_status(new_health: int, new_stamina: float, is_exhausted: bool) -> void:
 var percent := clampi(roundi(new_stamina), 0, 100)
 if health == new_health and stamina_percent == percent and exhausted == is_exhausted:
  return
 health = new_health
 stamina_percent = percent
 exhausted = is_exhausted
 queue_redraw()

func _draw() -> void:
 if portrait == null:
  return
 draw_rect(Rect2(3, 5, 285, 91), Color(0.03, 0.05, 0.06, 0.35))
 draw_rect(Rect2(0, 0, 285, 91), INK)
 draw_rect(Rect2(0, 0, 285, 91), GOLD, false, 2)
 draw_rect(Rect2(8, 8, 75, 75), Color("#3f6769"))
 draw_texture_rect_region(portrait, Rect2(9, 9, 73, 73), portrait_region)
 draw_rect(Rect2(8, 8, 75, 75), GOLD, false, 1)
 draw_line(Vector2(93, 39), Vector2(274, 39), Color("#628384"), 1)
 for index in range(6):
  var icon := heart if index < health else empty_heart
  draw_texture_rect(icon, Rect2(95 + index * 30, 11, 24, 22), false)
 for index in range(5):
  var fill := clampf((stamina_percent - index * 20) / 20.0, 0.0, 1.0)
  var origin := Vector2(96 + index * 35, 47)
  var points := PackedVector2Array()
  for point in BOLT:
   points.append(origin + point)
  draw_colored_polygon(points, Color("#183742").lerp(Color("#68ccff"), fill))
  points.append(points[0])
  draw_polyline(points, Color("#427184").lerp(Color("#b4e9ff"), fill), 1.5)
