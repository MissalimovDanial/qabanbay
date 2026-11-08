extends RefCounted
## Carry the small campaign save across separate local HTML documents.
static func snapshot(path: String) -> Dictionary:
 var save := ConfigFile.new()
 save.load(path)
 var count := 0
 var times: Array = []
 for n in range(1,6):
  if count == n - 1 and save.get_value("level%d" % n,"completed",false):
   count = n
  times.append(maxf(0,float(save.get_value("level%d" % n,"best_time",0.0))))
 return {"cleared":count,"times":times,"muted":bool(save.get_value("settings","muted",false))}

static func apply_payload(path: String, payload: Variant) -> bool:
 if not payload is Dictionary or not payload.get("cleared") is float and not payload.get("cleared") is int:
  return false
 var count := int(payload.cleared)
 if count < 0 or count > 5 or float(payload.cleared) != count:
  return false
 var save := ConfigFile.new()
 save.load(path)
 var times: Variant = payload.get("times",[])
 for n in range(1,count+1):
  save.set_value("level%d" % n,"completed",true)
  if times is Array and times.size() >= n and (times[n-1] is float or times[n-1] is int):
   var value := float(times[n-1])
   if is_finite(value) and value > 0:
    var previous := float(save.get_value("level%d" % n,"best_time",0.0))
    save.set_value("level%d" % n,"best_time",value if previous <= 0 else minf(previous,value))
 if payload.get("muted") is bool:
  save.set_value("settings","muted",payload.muted)
 return save.save(path) == OK

static func restore(path: String) -> void:
 if not OS.has_feature("web"):
  return
 var raw: Variant = JavaScriptBridge.eval("window.location.hash.indexOf('#qbb=')===0?window.location.hash.substring(5):''",true)
 if raw is String and not raw.is_empty() and raw.length() < 2048:
  apply_payload(path,JSON.parse_string(raw.uri_decode()))

static func fragment(path: String) -> String:
 return "#qbb=" + JSON.stringify(snapshot(path)).uri_encode()
