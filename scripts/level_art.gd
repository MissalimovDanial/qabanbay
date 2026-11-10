@tool
extends RefCounted
## Runtime atlas regions preserve generated source images without destructive edits.
const CHARACTERS_PATH = "res://art/source/02-characters-poses.png"
const ENVIRONMENT = preload("res://art/source/03-environments.png")
const TERRAIN = preload("res://art/animation/terrain-v2.png")
const TERRAIN_REGIONS := {"rock":Rect2(0,280,400,210),"tree":Rect2(0,490,470,500),"reeds":Rect2(1155,100,375,390),"grass_tuft":Rect2(780,250,355,240),"flying":Rect2(1160,590,376,400)}
const NEW_PROPS:Dictionary={"yurt":Vector2i(0,0),"dead_tree":Vector2i(1,0),"tumbleweed":Vector2i(2,0),"golden_man":Vector2i(0,1),"kumys":Vector2i(1,1),"secret_door":Vector2i(2,1)}
var eagle_texture: Texture2D

const OBJECTS = preload("res://art/source/04-tiles-props-ui.png")

const REGIONS := {
	"idle": Rect2(16, 22, 216, 228),
 "enemy_idle": Rect2(8, 540, 222, 225),
 "enemy_attack": Rect2(990, 540, 302, 225),
	"run0": Rect2(254, 58, 226, 192),
	"run1": Rect2(495, 58, 223, 192),
	"jump": Rect2(737, 19, 218, 229),
	"attack": Rect2(942, 83, 403, 167),
	"dodge": Rect2(1317, 113, 210, 136),
	"horse": Rect2(1230, 288, 301, 230),
	"elder": Rect2(982, 309, 220, 210),
	"boar_idle": Rect2(7, 829, 244, 174),
	"boar_charge": Rect2(258, 850, 221, 153),
	"boar_hurt": Rect2(493, 809, 171, 194),
	"boar_down": Rect2(657, 887, 263, 117)
}
const PROP_REGIONS := {
 "practice_dummy":Rect2(0,0,1024,1024),
	"grass": Rect2(208, 74, 151, 160),
	"dirt": Rect2(559, 83, 136, 153),
	"rock": Rect2(838, 374, 153, 125),
	"yurt": Rect2(19, 304, 389, 302),
	"tree": Rect2(399, 247, 250, 386),
	"reeds": Rect2(650, 336, 194, 289),
	"fence": Rect2(994, 345, 221, 163),
	"crate": Rect2(1313, 525, 135, 113),
	"banner": Rect2(1215, 295, 141, 349),
	"left": Rect2(39, 661, 148, 151),
	"right": Rect2(193, 661, 150, 151),
	"attack": Rect2(351, 661, 148, 151),
	"jump": Rect2(505, 661, 150, 151),
	"dodge": Rect2(664, 661, 148, 151),
	"heart": Rect2(1185, 674, 117, 113),
	"empty_heart": Rect2(1311, 674, 118, 113),
	"portrait": Rect2(1287, 790, 211, 199)
}

# Clean alpha halos once, then cache tight, ground-anchored regions.
static var prepared: Dictionary = {}
var use_baked:=true
const Land=preload("res://scripts/landform.gd")
var landscape_chapter := 1
const DRY_PANORAMA := preload("res://art/animation/ayagoz-ridges.png")
const ZAYSAN_PANORAMA := preload("res://art/animation/zaysan-aul.png")
const ZAYSAN_TERRAIN := preload("res://art/animation/zaysan-trail-bank.png")
const ZAYSAN_WILLOW := preload("res://art/animation/zaysan-willow.png")
const LAKESIDE_REEDS := preload("res://art/animation/lakeside-reeds.png")
const CAVE_MOUTH := preload("res://art/animation/cave-sinkhole-mouth.png")
const MEADOW_PANORAMA := preload("res://art/animation/ayagoz-meadow.png")
const MEADOW_TERRAIN := preload("res://art/animation/ayagoz-terrain.png")

func _is_meadow(chapter: int) -> bool:
 return chapter <= 3

func _surface_texture(chapter: int) -> Texture2D:
 return ZAYSAN_TERRAIN if chapter == 1 else MEADOW_TERRAIN if _is_meadow(chapter) else SURFACE_TEXTURE

func _grass_color(chapter: int) -> Color:
 if chapter == 1:
  return Color("a4b26b")
 return Color("#8c9c58") if _is_meadow(chapter) else Color("#c7aa73")

func _asset(name: String, character: bool = false) -> Dictionary:
 var key := ("sprite/" if character else "prop/") + name
 if not prepared.has(key):
  var baked:="res://art/props-baked/"+("sprite-" if character else "")+name+".res"
  if use_baked and ResourceLoader.exists(baked):
   var texture:Texture2D=load(baked)
   prepared[key]={"texture":texture,"bounds":texture.get_meta("bounds",Rect2(0,0,texture.get_width(),texture.get_height())),"region":texture.get_meta("region",Rect2(0,0,texture.get_width(),texture.get_height()))}
   return prepared[key]
  var source: Texture2D = load(CHARACTERS_PATH) if character else OBJECTS
  var alias:String={"dead_tree":"tree","tumbleweed":"grass_tuft","secret_door":"crate","golden_man":"banner","kumys":"crate"}.get(name,name)
  var region: Rect2
  if name=="willow":
   source=ZAYSAN_WILLOW
   region=Rect2(Vector2.ZERO,source.get_size())
  else:
   region=REGIONS[name] if character else TERRAIN_REGIONS[alias] if TERRAIN_REGIONS.has(alias) else PROP_REGIONS[alias]
  if not character and NEW_PROPS.has(name) and ResourceLoader.exists("res://art/animation/steppe-objects.png"):
   source=load("res://art/animation/steppe-objects.png")
   var cell:=source.get_size()/Vector2(3,2)
   region=Rect2(Vector2(NEW_PROPS[name])*cell,cell)
  if not character and TERRAIN_REGIONS.has(name) and not NEW_PROPS.has(name):
   source = TERRAIN
   region = TERRAIN_REGIONS[name]
  if name=="practice_dummy":
   source=load("res://art/animation/practice-dummy.png")
   region=Rect2(Vector2.ZERO,source.get_size())
  var image := source.get_image().get_region(Rect2i(region))
  if not character and name in ["rock","tree","reeds","grass_tuft","flying","banner","crate"]:
   image = _main_shape(image)
  for y in range(image.get_height()):
   for x in range(image.get_width()):
    var pixel := image.get_pixel(x, y)
    if name in ["flying","rock"] and pixel.g>pixel.r*1.05 and pixel.g>pixel.b*1.25:
     var light:=maxf(pixel.r,pixel.g)
     pixel=Color(light*0.94,light*0.78,light*0.40,pixel.a)
     image.set_pixel(x,y,pixel)
    if pixel.a < (0.70 if name=="willow" else 0.30):
     image.set_pixel(x, y, Color.TRANSPARENT)
  var bounds := image.get_used_rect()
  if not character and name in ["practice_dummy","rock", "yurt", "tree", "willow","dead_tree","secret_door","golden_man","kumys","reeds", "fence", "banner", "crate"]:
   # Ignore translucent drop shadows and isolated atlas specks below the feet.
   var foot := bounds.end.y - 1
   for y in range(bounds.end.y - 1, bounds.position.y - 1, -1):
    var solid := 0
    for x in range(bounds.position.x, bounds.end.x):
     if image.get_pixel(x,y).a >= 0.82:
      solid += 1
    if solid >= maxi(3, int(bounds.size.x * 0.025)):
     foot = y
     break
   bounds.size.y = foot - bounds.position.y + 1
  prepared[key] = {"texture": ImageTexture.create_from_image(image.get_region(bounds)), "bounds": Rect2(bounds), "region": region}
 return prepared[key]

func icon(name: String) -> Texture2D:
 return _asset(name).texture

func sprite(node: Node2D, name: String, at: Vector2, scale_factor: float, direction: float = 1, tint := Color.WHITE) -> void:
 var asset := _asset(name, true)
 var region: Rect2 = asset.region
 var bounds: Rect2 = asset.bounds
 var pivot := region.size.x * 0.5
 if name == "attack":
  pivot = 102
 elif name == "idle":
  pivot = 85
 elif name == "dodge":
  pivot = 105
 node.draw_set_transform(at.round(), 0, Vector2(direction * scale_factor, scale_factor))
 node.draw_texture_rect(asset.texture, Rect2(Vector2(bounds.position.x - pivot, -bounds.size.y), bounds.size), false, tint)
 node.draw_set_transform(Vector2.ZERO)

func prop(node: CanvasItem, name: String, at: Vector2, size: Vector2, tint := Color.WHITE) -> void:
 if not Engine.is_editor_hint() and (at.x+size.x*0.6< -80 or at.x-size.x*0.6>node.get_viewport_rect().size.x+80):return
 if name == "steppe_bloom":
  _steppe_bloom(node, at, size)
  return
 if name in ["grass_tuft","reeds"]:
  for i in range(7):
   var x:=at.x+(i-3)*size.x/9
   var h:=size.y*(0.35+0.08*(i*3%5))
   var grass := _grass_color(landscape_chapter)
   node.draw_polyline(PackedVector2Array([Vector2(x,at.y+2),Vector2(x+(i%3-1)*3,at.y-h*.6),Vector2(x+(i%3-1)*7,at.y-h)]),grass.darkened(0.14) if i%2 else grass.lightened(0.14),1.5,true)
  return
 var asset := _asset("willow" if name=="tree" else name)
 var grounded := name in ["practice_dummy","rock", "yurt", "tree", "dead_tree","secret_door","golden_man","kumys","reeds", "grass_tuft", "fence", "banner"] or (name == "crate" and size.x >= 40)
 var embed := 7.0 if name in ["tree", "dead_tree","reeds"] else 4.0
 var surface := at.round()
 var base := surface + Vector2(0, embed if grounded else 0)
 var contact_width := size.x * (0.23 if name == "tree" else 0.38 if name == "reeds" else 0.42)
 if grounded:
  var points := PackedVector2Array()
  for i in range(24):
   var angle := TAU * i / 24
   points.append(surface + Vector2(cos(angle) * contact_width, sin(angle) * 3 + 2))
  node.draw_colored_polygon(points, Color(0.04, 0.07, 0.025, 0.40))
 if name=="yurt":
  var source_size:Vector2=asset.texture.get_size()
  node.draw_texture_rect_region(asset.texture,Rect2(surface-Vector2(size.x*.5,size.y-3),size),Rect2(Vector2.ZERO,source_size*Vector2(1,0.94)),tint)
 else:
  var extent := Vector2(size.x,maxf(size.y,size.x)) if name=="tree" else size*0.66 if name=="rock" else size
  node.draw_texture_rect(asset.texture, Rect2(base - Vector2(extent.x * 0.5, extent.y), extent), false, tint)
 if grounded:
  # Short scattered roots overlap the feet without a rectangular pedestal.
  for i in range(6):
   var px:=surface.x-contact_width+i*contact_width*0.4
   var length:=2+_grain(int(at.x),i)%4
   node.draw_line(Vector2(px-2,surface.y+2),Vector2(px+1,surface.y-length),Color("b99b69"),1,true)

func _steppe_bloom(node: CanvasItem, at: Vector2, size: Vector2) -> void:
 for index in range(7):
  var root := (at + Vector2((index - 3) * size.x / 8.0, 2)).round()
  var height := roundf(size.y * (0.49 + float(index * 3 % 7) * 0.07))
  var lean := float(index % 3 - 1) * 5.0
  var tip := root + Vector2(lean, -height)
  node.draw_line(root, root.lerp(tip, 0.5), Color("64663b"), 3)
  node.draw_line(root.lerp(tip, 0.5), tip, Color("8c8c4c"), 2)
  node.draw_rect(Rect2(root.lerp(tip, 0.53) - Vector2(5, 1), Vector2(8, 3)), Color("a09958"))
  node.draw_rect(Rect2(tip - Vector2(4, 4), Vector2(9, 6)), Color("795058"))
  node.draw_rect(Rect2(tip - Vector2(3, 6), Vector2(6, 5)), Color("c57a78"))
  node.draw_rect(Rect2(tip - Vector2(1, 6), Vector2(2, 3)), Color("f2ca9f"))

func supply(node: Node2D, at: Vector2, time: float) -> void:
 if not Engine.is_editor_hint() and (at.x < -50 or at.x > node.get_viewport_rect().size.x + 50):
  return
 prop(node, "kumys", at, Vector2(38, 53))
 var pin := at + Vector2(0, -65 + sin(time * 3.5) * 3)
 var shape := PackedVector2Array([pin + Vector2(0, -7), pin + Vector2(7, 0), pin + Vector2(0, 7), pin + Vector2(-7, 0)])
 node.draw_colored_polygon(shape, Color("#286f69"))
 shape.append(shape[0])
 node.draw_polyline(shape, Color("#ffe4a8"), 2, true)

func background(node:Node2D,camera:float,size:Vector2,chapter:int=1)->void:
 landscape_chapter=chapter
 var tex := ZAYSAN_PANORAMA if chapter == 1 else MEADOW_PANORAMA if _is_meadow(chapter) else DRY_PANORAMA
 var tint := _light_tint(chapter)
 var tile:=2400.0
 var scroll:=camera*0.12 + (660.0 if chapter==1 else 0.0)
 var painted_height := tex.get_height()*(0.93 if chapter==1 else 1.0)
 for i in range(floori(scroll/tile),ceili((size.x+scroll)/tile)):
  var x:=i*tile-scroll
  node.draw_set_transform(Vector2(x+(tile if i%2!=0 else 0),0),0,Vector2(-1 if i%2!=0 else 1,1))
  node.draw_texture_rect_region(tex,Rect2(0,-10,tile,570),Rect2(0,0,tex.get_width(),painted_height),tint)
  # Continue the same bottom edge behind water and the terrain cutaway.
  node.draw_texture_rect_region(tex,Rect2(0,560,tile,340),Rect2(0,painted_height-1,tex.get_width(),1),tint)
 node.draw_set_transform(Vector2.ZERO)
 for i in range(int(size.x/160)+2):
  var wx:float=floor(camera*0.45/160)*160+i*160
  var x:=wx-camera*0.45
  node.draw_line(Vector2(x,546),Vector2(x+8,539),_grass_color(chapter)*tint,1.5)

func lakeside(node: Node2D, lakes: Array, camera: float, time: float) -> void:
 if landscape_chapter==1:
  return # The Zaysan panorama already contains the full lake.
 for area in lakes:
  var lake: Rect2 = area
  if not Engine.is_editor_hint() and (lake.end.x<camera or lake.position.x>camera+node.get_viewport_rect().size.x):
   continue
  var p := lake.position-Vector2(camera,0)
  var width := lake.size.x
  var h := lake.size.y
  var tex_size := LAKESIDE_REEDS.get_size()
  node.draw_texture_rect_region(LAKESIDE_REEDS,Rect2(p,lake.size),Rect2(0,tex_size.y*.24,tex_size.x,tex_size.y*.70),_light_tint(landscape_chapter))
  for i in range(18):
   var fraction := 0.23+float(i*17%35)/65.0
   var x := p.x+width*fraction
   var y := p.y+h*(0.33+float(i*23%29)/100.0)+sin(time*1.7+i)*2
   node.draw_rect(Rect2(roundf(x),roundf(y),17+i%6*8,1),Color(0.76,0.91,0.90,0.12+0.09*sin(time+i)))

func _main_shape(image: Image) -> Image:
 image.convert(Image.FORMAT_RGBA8)
 var data := image.get_data()
 var width := image.get_width()
 var height := image.get_height()
 var seen := PackedByteArray()
 seen.resize(width*height)
 var best := PackedInt32Array()
 for start in range(width*height):
  if seen[start]!=0 or data[start*4+3]<96:
   continue
  var queue := PackedInt32Array([start])
  seen[start] = 1
  var cursor := 0
  while cursor<queue.size():
   var pixel := queue[cursor]
   cursor+=1
   var y := pixel/width
   var x := pixel-y*width
   for ny in range(maxi(0,y-1),mini(height-1,y+1)+1):
    for nx in range(maxi(0,x-1),mini(width-1,x+1)+1):
     var next := ny*width+nx
     if seen[next]==0 and data[next*4+3]>=96:
      seen[next]=1
      queue.append(next)
  if queue.size()>best.size():
   best=queue
 var output := PackedByteArray()
 output.resize(data.size())
 for pixel in best:
  for channel in range(4):
   output[pixel*4+channel]=data[pixel*4+channel]
 return Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,output)

func birds(node: Node2D, camera: float, size: Vector2, time: float) -> void:
 if eagle_texture==null and ResourceLoader.exists("res://art/animation/eagle-v2.png"):
  eagle_texture = load("res://art/animation/eagle-v2.png")
 if eagle_texture==null:
  return
 var cell := Vector2(eagle_texture.get_width()/4.0,eagle_texture.get_height()/2.0)
 for i in range(4):
  var distance := 0.08 if i<3 else 0.35
  var x := fposmod(i*383.0+time*(23 if i<3 else 52)-camera*distance,size.x+220)-110
  var y := 85+i*34+sin(time*0.35+i)*14
  var frame := int(time*(5 if i<3 else 7)+i*2)%8
  var source := Rect2(Vector2(frame%4,frame/4)*cell,cell)
  var width := 48.0 if i<3 else 98.0
  node.draw_texture_rect_region(eagle_texture,Rect2(Vector2(x,y),Vector2(width,width*cell.y/cell.x)),source,Color("b9b9b1") if i<3 else Color.WHITE)

func _grain(world_cell: int, salt: int) -> int:
 # Integer hash: the pattern stays attached to the world as the camera moves.
 var value := absi(world_cell * 374761 + salt * 6689 + 92821)
 value = (value ^ (value >> 7)) * 127
 return absi(value ^ (value >> 11))

func _terrain_palette()->Dictionary:
 return {"earth":Color("b9a074"),"deep":Color("7c6848"),"grass":Color("c7b184"),"light":Color("e5cea0"),"dry":Color("ab925f")}

func _inside_gap(x: float, gaps: Array, margin: float = 0.0) -> bool:
 for gap in gaps:
  if x > gap.x - margin and x < gap.y + margin:
   return true
 return false

func scenic_rock(node: Node2D, rect: Rect2, camera: float, floor_y: float) -> void:
 prop(node,"rock",Vector2(rect.get_center().x-camera,floor_y),rect.size*0.78,Color("bcaa90"))

var terrain_camera := 0.0

func ground(node:Node2D,camera:float,width:float,floor_y:float,gaps:Array=[],ravines:Array=[])->void:
 terrain_camera=camera
 var land:=ravines.duplicate()
 if land.is_empty():
  for gap in gaps:land.append({"span":gap,"depth":175.0})
 for r in land:
  if r.span.y>=camera-120 and r.span.x<=camera+width+120 and r.depth>0 and not r.get("water",false):
   ravine(node,r.span,camera,floor_y,r.depth)
 var points:=PackedVector2Array()
 var uvs:=PackedVector2Array()
 var bottom:=floor_y+700
 for offset in range(-12,int(width)+25,12):
  var wx:float=camera+offset
  var y:float=Land.surface(wx,land,floor_y)
  if y>10000:y=bottom
  points.append(Vector2(offset,y))
  uvs.append(Vector2(wx/512.0,y/512.0))
 points.append(Vector2(width+24,bottom));uvs.append(Vector2((camera+width+24)/512.0,bottom/512.0))
 points.append(Vector2(-12,bottom));uvs.append(Vector2((camera-12)/512.0,bottom/512.0))
 node.texture_repeat=CanvasItem.TEXTURE_REPEAT_MIRROR
 var tint := _light_tint(landscape_chapter)
 var soil_tint := Color("#967d66") if _is_meadow(landscape_chapter) else Color.WHITE
 node.draw_colored_polygon(points,soil_tint*tint,uvs,preload("res://art/animation/sand-ground.png"))
 _surface_strip(node,camera,width,floor_y,land)
 for r in land:
  if r.depth < 85 or r.span.y < camera or r.span.x > camera+width:
   continue
  for bank in [0.29, 0.71]:
   var x := lerpf(r.span.x,r.span.y,bank)
   _thorn_cluster(node,Vector2(x-camera,Land.surface(x,land,floor_y)),0.74,false)

# Cached world chunks keep UVs and cracks fixed while the camera moves.
# Every strip vertex follows the SAME support curve used by actor collisions.
var _surface_meshes:Dictionary={}
const SURFACE_TEXTURE=preload("res://art/animation/steppe-terrain-strip.png")
func _light_tint(chapter: int) -> Color:
 match chapter:
  3: return Color("#d4e2e4")
  4: return Color("#d5b79b")
  5: return Color("#c0bbad")
  _: return Color.WHITE

func _surface_strip(node:Node2D,camera:float,width:float,floor_y:float,land:Array)->void:
 var signature:=hash([land,landscape_chapter])
 var lip := 115.0 if landscape_chapter==1 else 85.0
 for chunk in range(floori(camera/1920),ceili((camera+width)/1920)):
  var key:=str(signature)+":"+str(chunk)
  if not _surface_meshes.has(key):
   var vertices:=PackedVector3Array()
   var uvs:=PackedVector2Array()
   var indices:=PackedInt32Array()
   for step in range(160):
    var x:=chunk*1920.0+step*12
    var left:=Land.surface(x,land,floor_y)
    var right:=Land.surface(x+12,land,floor_y)
    if left>10000 or right>10000:continue
    var index:=vertices.size()
    for corner in range(4):
     var wx:=x+(12 if corner%2==1 else 0)
     var surface_y:=right if corner%2==1 else left
     var below:=corner>=2
     vertices.append(Vector3(wx,surface_y+((320.0 if below else 0.0)-lip),0))
     var u:=fposmod(wx/960,2.0)
     if u>1:u=2-u
     uvs.append(Vector2(u,1 if below else 0))
    indices.append_array(PackedInt32Array([index,index+1,index+2,index+2,index+1,index+3]))
    var bed := vertices.size()
    for corner in range(4):
     var edge := index + 2 + corner % 2
     vertices.append(vertices[edge]+Vector3(0,410.0 if corner>=2 else 0.0,0))
     uvs.append(Vector2(uvs[edge].x,0.73 if corner>=2 else 1.0))
    indices.append_array(PackedInt32Array([bed,bed+1,bed+2,bed+2,bed+1,bed+3]))
   var arrays:=[]
   arrays.resize(Mesh.ARRAY_MAX)
   arrays[Mesh.ARRAY_VERTEX]=vertices
   arrays[Mesh.ARRAY_TEX_UV]=uvs
   arrays[Mesh.ARRAY_INDEX]=indices
   var mesh:=ArrayMesh.new()
   if not vertices.is_empty():mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   _surface_meshes[key]=mesh
  if node!=null:node.draw_mesh(_surface_meshes[key],_surface_texture(landscape_chapter),Transform2D(0,Vector2(-camera,0)),_light_tint(landscape_chapter))

func _ground_bed(node:Node2D,rect:Rect2,palette:Dictionary)->void:
 if rect.size.x>0:node.draw_rect(rect,palette.earth)

var _ravine_meshes:Dictionary={}
func ravine(node:Node2D,span:Vector2,camera:float,floor_y:float,depth:float=175)->void:
 if depth<=0:return
 var key:=str(span)+":"+str(depth)+":"+str(landscape_chapter)
 if not _ravine_meshes.has(key):
  var vertices:=PackedVector3Array()
  var uvs:=PackedVector2Array()
  var colors:=PackedColorArray()
  var indices:=PackedInt32Array()
  var count:=maxi(20,ceili((span.y-span.x)/24.0))
  var land:Array=[{"span":span,"depth":depth}]
  for step in range(count):
   var index:=vertices.size()
   for corner in range(4):
    var t:=float(step+(1 if corner%2==1 else 0))/count
    var x:=lerpf(span.x,span.y,t)
    var lower:=corner>=2
    var y:=Land.surface(x,land,floor_y)+7 if lower else floor_y+2+9*sin(t*PI)
    vertices.append(Vector3(x,y,0))
    var u:=fposmod(x/960,2.0)
    var top := 0.38 if landscape_chapter==1 else 0.30
    uvs.append(Vector2(u if u<=1 else 2-u,top+clampf((y-floor_y)/depth,0,1)*(0.98-top)))
    colors.append(Color("66513a") if lower else Color("a08c74"))
   indices.append_array(PackedInt32Array([index,index+1,index+2,index+2,index+1,index+3]))
  var arrays:=[]
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX]=vertices
  arrays[Mesh.ARRAY_TEX_UV]=uvs
  arrays[Mesh.ARRAY_COLOR]=colors
  arrays[Mesh.ARRAY_INDEX]=indices
  var mesh:=ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  _ravine_meshes[key]=mesh
 node.draw_mesh(_ravine_meshes[key],_surface_texture(landscape_chapter),Transform2D(0,Vector2(-camera,0)),_light_tint(landscape_chapter))

func platform(node:Node2D,world_rect:Rect2,camera:float,style_chapter:int=1,ravines:Array=[])->void:
 if not Engine.is_editor_hint() and (world_rect.end.x<camera-70 or world_rect.position.x>camera+node.get_viewport_rect().size.x+70):return
 var p:=world_rect.position-Vector2(camera,0)
 var w:=world_rect.size.x
 for basin in ravines:
  if basin.get("water",false) and basin.depth>0 and basin.span.x<world_rect.get_center().x and basin.span.y>world_rect.get_center().x:
   _shore_stone(node,p,w,int(world_rect.get_center().x))
   return
 var floor_y := Land.surface(world_rect.get_center().x, ravines)
 if floor_y >= 10000.0:
  _timber_crossing(node, p, w)
  return
 var depth := maxf(world_rect.size.y, floor_y - p.y + 15.0)
 var local:=PackedVector2Array([Vector2(0,0),Vector2(w,0),Vector2(w-5,13),Vector2(w*.89,depth*.36),Vector2(w*.93,depth*.71),Vector2(w+13,depth),Vector2(-12,depth),Vector2(w*.08,depth*.64),Vector2(w*.07,depth*.35),Vector2(8,16)])
 if floor_y > 555.0 and w >= 300.0:
  for leg in [0.22, 0.79]:
   var x: float = w * leg
   var support := PackedVector2Array([p+Vector2(x-48,20),p+Vector2(x+46,20),p+Vector2(x+26,depth*.58),p+Vector2(x+43,depth),p+Vector2(x-47,depth),p+Vector2(x-29,depth*.62)])
   node.draw_colored_polygon(support, Color("ac9479") * _light_tint(style_chapter), PackedVector2Array([Vector2(0.2,0.30),Vector2(0.58,0.30),Vector2(0.52,0.51),Vector2(0.60,0.80),Vector2(0.21,0.80),Vector2(0.25,0.54)]), _surface_texture(style_chapter))
  local = PackedVector2Array([Vector2(0,0),Vector2(w,0),Vector2(w-7,19),Vector2(w*.88,31),Vector2(w*.64,45),Vector2(w*.41,38),Vector2(w*.20,52),Vector2(10,27)])
 var points:=PackedVector2Array()
 var uvs:=PackedVector2Array()
 for v in local:
  points.append(p+v)
  var u:=0.10+v.x/maxf(w,1)*0.80
  uvs.append(Vector2(u,(0.36 if style_chapter==1 else 0.267)+v.y/maxf(320.0,depth*1.5)))
 var tint:=_light_tint(style_chapter)
 node.draw_colored_polygon(points,tint,uvs,_surface_texture(style_chapter))
 for i in range(3):
  var x:=p.x+w*(0.22+0.29*i)
  node.draw_polyline(PackedVector2Array([Vector2(x-4,p.y-5),Vector2(x,p.y+1),Vector2(x+2,p.y-9)]),_grass_color(style_chapter)*tint,1,true)

func _timber_crossing(node: Node2D, at: Vector2, width: float) -> void:
 var bottom := 660.0
 for x in [at.x + 16.0, at.x + width - 27.0]:
  node.draw_rect(Rect2(x, at.y + 8, 12, bottom - at.y), Color("563e30"))
  node.draw_rect(Rect2(x + 2, at.y + 8, 4, bottom - at.y), Color("a27b51"))
 node.draw_line(at + Vector2(21, 40), Vector2(at.x + width - 21, minf(bottom, at.y + 114)), Color("735036"), 8)
 node.draw_rect(Rect2(at, Vector2(width, 19)), Color("543828"))
 for index in range(ceili(width / 23.0)):
  var offset := float(index) * 23.0
  var plank_width := minf(22.0, width - offset)
  node.draw_rect(Rect2(at + Vector2(offset, 0), Vector2(plank_width, 12)), Color("b58c59") if index % 2 == 0 else Color("a77d4d"))
  node.draw_rect(Rect2(at + Vector2(offset, 0), Vector2(plank_width, 3)), Color("ddbc84"))

func _shore_stone(node: Node2D, p: Vector2, w: float, seed: int) -> void:
 var base := 598.0-p.y
 var left := 8+seed%11
 var right := 6+seed%13
 var outline := PackedVector2Array([p+Vector2(0,9+seed%8),p+Vector2(left,0),p+Vector2(w-right,0),p+Vector2(w,12+seed%7),p+Vector2(w-4,base*0.77),p+Vector2(w*.71,base),p+Vector2(w*.24,base),p+Vector2(4,base*.71)])
 node.draw_colored_polygon(outline,Color("515b53"))
 node.draw_colored_polygon(PackedVector2Array([outline[0],outline[1],outline[2],outline[3],p+Vector2(w*.76,15),p+Vector2(w*.22,14)]),Color("a4a68d") if seed%3 else Color("9d9d88"))
 node.draw_colored_polygon(PackedVector2Array([p+Vector2(4,16),p+Vector2(w*.25,15),p+Vector2(w*.42,31),p+Vector2(w*.31,base),outline[6],outline[7]]),Color("737a66"))
 node.draw_rect(Rect2(p+Vector2(w*.29,3),Vector2(w*.37,3)),Color("c4c3a6"))
 node.draw_rect(Rect2(p+Vector2(w*.63,9),Vector2(w*.20,3)),Color("909569"))

func embedded_door(node:Node2D,p:Vector2,camera:=Vector2.ZERO)->void:
 # A shallow niche lies in the rear wall; the door never grows a separate pedestal.
 var center:=p+Vector2(0,-71)
 for ring in range(7,0,-1):
  var radius:=float(ring)/7.0
  var outline:=PackedVector2Array()
  for i in range(32):
   var a:=i*TAU/32
   outline.append(center+Vector2(cos(a)*(55+28*radius),sin(a)*(72+19*radius)))
  node.draw_colored_polygon(outline,Color(0.14,0.105,0.06,0.035))
 var opening:=PackedVector2Array([p+Vector2(-46,3),p+Vector2(-49,-79),p+Vector2(-32,-128),p+Vector2(0,-144),p+Vector2(33,-125),p+Vector2(50,-77),p+Vector2(46,3)])
 node.draw_colored_polygon(opening,Color("51432e"))
 prop(node,"secret_door",p+Vector2(0,2),Vector2(88,136),Color("c3b49b"))
 node.draw_polyline(PackedVector2Array([p+Vector2(-55,3),p+Vector2(-20,5),p+Vector2(24,4),p+Vector2(54,2)]),Color("a48b60"),5,true)

func cave_mouth(node: CanvasItem, at: Vector2) -> void:
 var size := Vector2(318,212)
 var tint := Color("bdad93") if _is_meadow(landscape_chapter) else Color("e1cba9")
 node.draw_texture_rect(CAVE_MOUTH,Rect2(at-size*Vector2(0.5,0.78),size),false,tint*_light_tint(landscape_chapter))

func spikes(node:Node2D,span:Vector2,camera:float,floor_y:float)->void:
 if not Engine.is_editor_hint() and (span.y<camera-50 or span.x>camera+1330):return
 var count := maxi(1, ceili((span.y-span.x)/29.0))
 for index in range(count):
  var x := lerpf(span.x, span.y, (index+0.5)/count)
  _thorn_cluster(node,Vector2(x-camera,floor_y),0.82+0.11*(index%3),true)

func _thorn_cluster(node: Node2D, at: Vector2, size_factor: float, on_trail: bool) -> void:
 var p := at.round()+Vector2(0,3)
 var wood := Color("703f40") if on_trail else Color("72564b")
 var tip_color := Color("f1a177") if on_trail else Color("b89772")
 for index in range(6):
  var dx := float(index * 9 - 22)
  var branch := p + Vector2(dx,-18-index%3*8)*size_factor
  var bend := p + Vector2(dx*0.36,-11)*size_factor
  node.draw_polyline(PackedVector2Array([p+Vector2(dx*0.31,0),bend,branch]),wood,3)
  var thorn := branch.lerp(bend,0.38)
  node.draw_colored_polygon(PackedVector2Array([thorn,thorn+Vector2(signf(dx)*10,-6)*size_factor,thorn+Vector2(-2,3)*size_factor]),tip_color)
  node.draw_rect(Rect2(branch-Vector2(1,2),Vector2(3,4)),tip_color)

func asyk(node: CanvasItem, p: Vector2, variant: int) -> void:
 if not Engine.is_editor_hint() and (p.x < -30 or p.x > node.get_viewport_rect().size.x + 30):
  return
 var at := p.round()
 var colors := [Color("c79668"), Color("ca8066"), Color("87ad9d")]
 node.draw_colored_polygon(PackedVector2Array([at + Vector2(-15, -2), at + Vector2(-11, -11), at + Vector2(-4, -12), at + Vector2(2, -7), at + Vector2(10, -10), at + Vector2(15, -5), at + Vector2(13, 6), at + Vector2(6, 10), at + Vector2(-6, 7), at + Vector2(-13, 9)]), Color("534234"))
 node.draw_colored_polygon(PackedVector2Array([at + Vector2(-12, -2), at + Vector2(-8, -9), at + Vector2(-4, -9), at + Vector2(2, -4), at + Vector2(9, -7), at + Vector2(12, -4), at + Vector2(10, 5), at + Vector2(5, 7), at + Vector2(-5, 4), at + Vector2(-11, 6)]), colors[variant % colors.size()])
 node.draw_line(at + Vector2(-8, -7), at + Vector2(-3, -7), Color("f0dec2"), 2)
 node.draw_line(at + Vector2(4, -3), at + Vector2(9, -5), Color("f0dec2"), 2)
 node.draw_rect(Rect2(at + Vector2(-3, 1), Vector2(8, 3)), Color("846854"))

func arrow(node:Node2D,p:Vector2,dir:float) -> void:
 node.draw_set_transform(p,0,Vector2(dir,1))
 node.draw_line(Vector2(-40,1),Vector2(3,1),Color("4e3528"),3)
 node.draw_line(Vector2(-39,0),Vector2(3,0),Color("c8a271"),1)
 node.draw_colored_polygon(PackedVector2Array([Vector2(10,0),Vector2(0,-4),Vector2(2,0),Vector2(0,4)]),Color("b7c7c1"))
 for y in [-1,1]:
  node.draw_colored_polygon(PackedVector2Array([Vector2(-38,0),Vector2(-47,y*6),Vector2(-34,y*5),Vector2(-28,0)]),Color("e5d6a9"))
 node.draw_set_transform(Vector2.ZERO)
