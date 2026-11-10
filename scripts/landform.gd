@tool
extends RefCounted
static func surface(x:float,ravines:Array,base:float=550.0)->float:
 for r in ravines:
  var a:float=r.span.x
  var b:float=r.span.y
  if r.depth<=0:
   if x>a and x<b:return 100000.0
   continue
  var rim:=minf(210,(b-a)*0.43)
  if x>a and x<b:
   var t:=clampf(minf(x-a,b-x)/rim,0,1)
   return base+r.depth*(t*t*(3-2*t))+sin((x-a)*0.019)*4*t*t
  if x>=a-100 and x<=a:
   return base-12*sin((x-a+100)/100*PI)
  if x>=b and x<=b+100:
   return base-12*sin((x-b)/100*PI)
 return base

static func collectible_position(at: Vector2, terraces: Array, ravines: Array) -> Vector2:
 var support := surface(at.x, ravines)
 for terrace in terraces:
  if at.x >= terrace.position.x and at.x <= terrace.end.x and absf(at.y - terrace.position.y) < 80:
   support = minf(support, terrace.position.y)
 return Vector2(at.x, support - 8.0) if support < 10000.0 else at

static func yurt_clearance(decor: Array, doors: Array) -> Array[Vector2]:
 var spans: Array[Vector2] = []
 for entry in decor:
  if entry.name == "yurt":
   var width: float = entry.size.x * 0.5 + 64.0
   spans.append(Vector2(entry.at.x-width,entry.at.x+width))
 for door in doors:
  if door.kind == "passage":
   spans.append(Vector2(door.at.x-282.0,door.at.x+282.0))
 return spans

static func clear_of_yurts(x: float, half_width: float, spans: Array[Vector2]) -> bool:
 for span in spans:
  if x+half_width > span.x and x-half_width < span.y:
   return false
 return true
