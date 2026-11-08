extends RefCounted
## Whole-body animation banks. Source sheets stay untouched; runtime connected
## components recover poses whose weapons extend beyond the nominal grid cells.
const FILES := {
 "hero": "res://art/animation/hero-v2.png",
 "elder": "res://art/animation/elder-v2.png",
 "enemy": "res://art/animation/enemy-v3.png",
 "boar": "res://art/animation/boar-v2.png",
 "horse": "res://art/animation/horse-v2.png"
}
const HEIGHTS := {"hero":125.0, "enemy":130.0, "elder":115.0, "boar":135.0, "horse":130.0}
const ALPHA_MIN := 96
const BAKED_ROOT := "res://art/animation/baked/"
static var _banks: Dictionary = {}

func available_frame_count(kind: String) -> int:
 return _bank(kind).frames.size()

func frame_count(kind: String) -> int:
 return available_frame_count(kind)

func bank_info(kind: String) -> Dictionary:
 var bank := _bank(kind)
 return {"kind":kind, "frame_count":bank.frames.size(), "component_count":bank.component_count, "significant_components":bank.significant_components, "scale":bank.scale, "median_reference_height":bank.median_reference_height, "sheet_size":bank.sheet_size, "fallback_count":bank.fallback_count, "baked":bank.get("baked",false)}

func frame_info(kind: String, index: int) -> Dictionary:
 var bank := _bank(kind)
 if bank.frames.is_empty():
  return {}
 var frame: Dictionary = bank.frames[posmod(index, bank.frames.size())]
 return {"bounds":frame.bounds, "cell":frame.cell, "anchor_x":frame.anchor_x, "component_id":frame.component_id, "fallback":frame.fallback, "texture_size":frame.texture.get_size(), "draw_height":frame.texture.get_height() * bank.scale}

func draw(node: Node2D, kind: String, index: int, p: Vector2, facing: float = 1.0, tint: Color = Color.WHITE, size_factor: float = 1.0) -> void:
 var bank := _bank(kind)
 if bank.frames.is_empty():
  return
 var frame: Dictionary = bank.frames[posmod(index, bank.frames.size())]
 var bounds: Rect2i = frame.bounds
 var scale_value: float = bank.scale * size_factor
 # The anchor follows the opaque torso, never the changing spear/tusk bounding box.
 # The visible bottom is always the exact support-plane point supplied by gameplay.
 var offset := Vector2(float(bounds.position.x) - float(frame.anchor_x), -float(bounds.size.y))
 node.draw_set_transform(p.round(), 0, Vector2((-1.0 if facing < 0 else 1.0) * scale_value, scale_value))
 node.draw_texture_rect(frame.texture, Rect2(offset, Vector2(bounds.size)), false, tint)
 node.draw_set_transform(Vector2.ZERO)

func _bank(kind: String) -> Dictionary:
 if not _banks.has(kind):
  var baked := _load_baked(kind)
  _banks[kind] = baked if not baked.is_empty() else _prepare(kind)
 return _banks[kind]

func _load_baked(kind: String) -> Dictionary:
 var path := BAKED_ROOT + kind + ".res"
 if not ResourceLoader.exists(path):
  return {}
 var resource: Resource = load(path)
 if not resource is SpriteFrames or not resource.has_animation("all") or resource.get_meta("source_file", "") != FILES.get(kind, ""):
  return {}
 var stored: Variant = resource.get_meta("frame_info", [])
 var info: Variant = resource.get_meta("bank_info", {})
 if not stored is Array or not info is Dictionary or stored.size() != resource.get_frame_count("all"):
  return {}
 var frames: Array[Dictionary] = []
 for index in range(stored.size()):
  var frame: Dictionary = stored[index].duplicate(true)
  frame.texture = resource.get_frame_texture("all", index)
  frames.append(frame)
 var bank: Dictionary = info.duplicate(true)
 bank.frames = frames
 bank.baked = true
 return bank

func bake(kind: String) -> Error:
 var bank := _prepare(kind)
 if bank.frames.is_empty():
  return ERR_INVALID_DATA
 var resource := SpriteFrames.new()
 resource.remove_animation("default")
 resource.add_animation("all")
 resource.set_animation_loop("all", true)
 resource.set_animation_speed("all", 10)
 var metadata: Array[Dictionary] = []
 for frame in bank.frames:
  resource.add_frame("all",frame.texture)
  var properties: Dictionary = frame.duplicate()
  properties.erase("texture")
  metadata.append(properties)
 var info := bank.duplicate()
 info.erase("frames")
 resource.set_meta("source_file", FILES[kind])
 resource.set_meta("frame_info",metadata)
 resource.set_meta("bank_info",info)
 DirAccess.make_dir_recursive_absolute(BAKED_ROOT)
 var error := ResourceSaver.save(resource,BAKED_ROOT + kind + ".res",ResourceSaver.FLAG_COMPRESS)
 if error == OK:
  _banks.erase(kind)
 return error

func _prepare(kind: String) -> Dictionary:
 if not FILES.has(kind):
  push_error("Unknown character frame bank: " + kind)
  return {"frames":[]}
 var texture: Texture2D = load(FILES[kind])
 if texture == null:
  push_error("Missing character frame sheet: " + str(FILES[kind]))
  return {"frames":[]}
 var source := texture.get_image()
 if source.is_compressed():
  source.decompress()
 source.convert(Image.FORMAT_RGBA8)
 var bytes := source.get_data()
 var width := source.get_width()
 var height := source.get_height()
 var labels := PackedInt32Array()
 labels.resize(width * height)
 labels.fill(-1)
 var components: Array[Dictionary] = []
 var queue := PackedInt32Array()
 # Assign 8-connected opaque regions; anti-aliased background haze is excluded.
 for origin in range(width * height):
  if labels[origin] >= 0 or bytes[origin * 4 + 3] < ALPHA_MIN:
   continue
  var component_id := components.size()
  queue.clear()
  queue.append(origin)
  labels[origin] = component_id
  var cursor := 0
  var min_x := width
  var min_y := height
  var max_x := 0
  var max_y := 0
  var sum_x := 0.0
  var sum_y := 0.0
  while cursor < queue.size():
   var pixel := queue[cursor]
   cursor += 1
   var y := pixel / width
   var x := pixel - y * width
   min_x = mini(min_x,x)
   max_x = maxi(max_x,x)
   min_y = mini(min_y,y)
   max_y = maxi(max_y,y)
   sum_x += x
   sum_y += y
   for ny in range(maxi(0,y - 1), mini(height - 1,y + 1) + 1):
    var row := ny * width
    for nx in range(maxi(0,x - 1), mini(width - 1,x + 1) + 1):
     var neighbor := row + nx
     if labels[neighbor] < 0 and bytes[neighbor * 4 + 3] >= ALPHA_MIN:
      labels[neighbor] = component_id
      queue.append(neighbor)
  components.append({"id":component_id, "count":queue.size(), "bounds":Rect2i(min_x,min_y,max_x - min_x + 1,max_y - min_y + 1), "center":Vector2(sum_x,sum_y) / queue.size()})
 var columns := 4 if kind in ["horse","enemy"] else 8
 var rows := 7 if kind == "enemy" else 4
 var cell_width := float(width) / columns
 var cell_height := float(height) / rows
 var candidates: Array[Dictionary] = []
 for component in components:
  var box: Rect2i = component.bounds
  if component.count > 200 and box.size.y >= cell_height * 0.15 and box.size.x >= cell_width * 0.10:
   candidates.append(component)
 var frames: Array[Dictionary] = []
 var fallback_count := 0
 var logical_count := 32 if kind == "enemy" else columns * rows
 # The enemy atlas contains 28 coherent poses; the final slots hold the down pose.
 for index in range(logical_count):
  var source_index := index
  if kind == "enemy" and index >= 24:
   source_index = [19,22,24,25,26,27,27,27][index-24]
  var col := source_index % columns
  var row := source_index / columns
  var cell := Rect2i(int(col * cell_width),int(row * cell_height),int(cell_width),int(cell_height))
  var target := Vector2((col + 0.5) * cell_width,(row + 0.70) * cell_height)
  var best: Dictionary = {}
  var best_score := INF
  for component in candidates:
   var center: Vector2 = component.center
   var dx := (center.x - target.x) / cell_width
   var dy := (center.y - target.y) / cell_height
   if absf(dx) > 0.85 or absf(dy) > 0.7:
    continue
   # Large connected bodies outrank small detached motion/impact particles.
   var significance: float = minf(1.0,float(component.count) / 6000.0)
   var score := dx * dx + dy * dy * 1.3 + (1.0 - significance) * 0.22
   if score < best_score:
    best_score = score
    best = component
  var fallback := best.is_empty()
  if not best.is_empty():
   var box: Rect2i = best.bounds
   fallback = box.size.x > cell_width * 1.75 or box.size.y > cell_height * 1.6
  var box: Rect2i = cell if fallback else best.bounds
  var component_id: int = -1 if fallback else best.id
  if fallback:
   fallback_count += 1
   box = _opaque_bounds(bytes, width, cell)
  if box.size.x == 0 or box.size.y == 0:
   box = Rect2i(cell.position,Vector2i.ONE)
  var data := PackedByteArray()
  data.resize(box.size.x * box.size.y * 4)
  data.fill(0)
  var middle_sum := 0.0
  var middle_count := 0
  var band_top := box.position.y + int(box.size.y * 0.30)
  var band_end := box.position.y + int(box.size.y * 0.76)
  for y in range(box.position.y,box.end.y):
   for x in range(box.position.x,box.end.x):
    var original := y * width + x
    if bytes[original * 4 + 3] < ALPHA_MIN or (component_id >= 0 and labels[original] != component_id):
     continue
    var local := ((y - box.position.y) * box.size.x + x - box.position.x) * 4
    var pixel := original * 4
    data[local] = bytes[pixel]
    data[local + 1] = bytes[pixel + 1]
    data[local + 2] = bytes[pixel + 2]
    data[local + 3] = bytes[pixel + 3]
    if y >= band_top and y <= band_end:
     middle_sum += x
     middle_count += 1
  var anchor := target.x
  if middle_count > 0:
   # Prevent frame drift caused by a long horizontal weapon entering the bounds.
   anchor = clampf(middle_sum / middle_count, target.x - cell_width * 0.35, target.x + cell_width * 0.35)
  var image := Image.create_from_data(box.size.x,box.size.y,false,Image.FORMAT_RGBA8,data)
  frames.append({"texture":ImageTexture.create_from_image(image), "bounds":box, "cell":cell, "anchor_x":anchor, "component_id":component_id, "fallback":fallback})
 # One scale for every pose in the bank, using standing/moving reference frames.
 var reference_heights: Array[int] = []
 for index in range(mini(columns,frames.size())):
  reference_heights.append(frames[index].bounds.size.y)
 reference_heights.sort()
 var reference := float(reference_heights[reference_heights.size() / 2])
 var scale_value: float = HEIGHTS[kind] / maxf(1.0,reference)
 return {"frames":frames, "component_count":components.size(), "significant_components":candidates.size(), "scale":scale_value, "median_reference_height":reference, "sheet_size":Vector2i(width,height), "fallback_count":fallback_count}

func _opaque_bounds(bytes: PackedByteArray, width: int, cell: Rect2i) -> Rect2i:
 var min_x := cell.end.x
 var min_y := cell.end.y
 var max_x := -1
 var max_y := -1
 for y in range(cell.position.y,cell.end.y):
  for x in range(cell.position.x,cell.end.x):
   if bytes[(y * width + x) * 4 + 3] >= ALPHA_MIN:
    min_x = mini(min_x,x)
    max_x = maxi(max_x,x)
    min_y = mini(min_y,y)
    max_y = maxi(max_y,y)
 return Rect2i(min_x,min_y,max_x - min_x + 1,max_y - min_y + 1) if max_x >= min_x else Rect2i()

static var action_banks: Dictionary = {}
var hero_age:=1
const CLIPS := {
 "hero":{"kick":[16,6],"idle":[8,4],"run":[0,8],"jump":[16,4],"dodge":[20,4],"attack":[24,8],"super":[24,8],"hurt":[12,2],"land":[14,2]},
 "elder":{"idle":[0,8],"talk":[8,8],"point":[16,8],"bless":[24,8]},
 "boar":{"idle":[0,8],"run":[8,8],"windup":[16,4],"recover":[20,4],"hurt":[24,4],"down":[28,4]},
 "enemy":{"idle":[0,4],"run":[4,4],"windup":[8,2],"attack":[10,4],"hurt":[16,4],"recover":[20,4],"down":[24,8]},
 "horse":{"idle":[0,4],"gallop":[8,8]}
}

func pose(node: CanvasItem,kind: String,clip: String,step: int,p: Vector2,dir: float=1.0,tint:=Color.WHITE,rotation:float=0.0) -> void:
 if kind=="hero":kind="hero" if hero_age==1 else "hero-adult" if hero_age<=3 else "hero-veteran"
 if not action_banks.has(kind):
  action_banks[kind]=load("res://art/animation/actions/"+kind+".res")
 var actions: SpriteFrames=action_banks[kind]
 if not actions:
  return
 var tex:=actions.get_frame_texture(clip,posmod(step,6))
 var age_scale:=body_scale() if kind.begins_with("hero") else 1.0
 node.draw_set_transform(p.round(),rotation,Vector2(dir*age_scale,age_scale))
 node.draw_texture(tex,Vector2(-195,-185),tint)
 node.draw_set_transform(Vector2.ZERO)

func body_scale()->float:
 return [1.0,0.97,1.01,1.0,1.04][clampi(hero_age,1,5)-1]

func heart_height()->float:
 return [138.0,180.0,185.0,190.0,196.0][clampi(hero_age,1,5)-1]
